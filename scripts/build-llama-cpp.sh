#!/usr/bin/env bash
set -euo pipefail

# scripts/build-llama-cpp.sh
# llama.cpp ক্লোন + বিল্ড (ক্যাশ করা হয়, ২য় বার থেকে স্কিপ)
# ENV: LLAMA_CPP_REF (default: master)

REF="${LLAMA_CPP_REF:-master}"
ROOT="third_party/llama.cpp"

echo "=== Build llama.cpp (ref: $REF) ==="

if [ -d "$ROOT/.git" ]; then
  echo "Updating existing clone..."
  git -C "$ROOT" fetch --depth 1 origin "$REF" || git -C "$ROOT" fetch --depth 1 origin master
  git -C "$ROOT" checkout "$REF" 2>/dev/null || git -C "$ROOT" checkout master
  git -C "$ROOT" pull --ff-only 2>/dev/null || true
else
  echo "Cloning llama.cpp..."
  mkdir -p third_party
  # Shallow clone for speed
  git clone --depth 1 --branch "$REF" https://github.com/ggml-org/llama.cpp "$ROOT" 2>/dev/null || \
  git clone --depth 1 https://github.com/ggml-org/llama.cpp "$ROOT"
  git -C "$ROOT" checkout "$REF" 2>/dev/null || true
fi

echo "Building..."
cmake -S "$ROOT" -B "$ROOT/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_CURL=OFF \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=ON

cmake --build "$ROOT/build" --config Release -j$(nproc)

echo "Build done:"
ls -lh "$ROOT/build/bin/llama-quantize" "$ROOT/build/bin/llama-cli" 2>/dev/null || \
ls -lh "$ROOT/build/bin/" | head -20

# Also copy to expected path for workflow
mkdir -p "$ROOT/build/bin"
# Some versions output to build/bin, some to build — normalize
if [ ! -f "$ROOT/build/bin/llama-quantize" ] && [ -f "$ROOT/build/llama-quantize" ]; then
  cp "$ROOT/build/llama-quantize" "$ROOT/build/bin/llama-quantize"
fi
if [ ! -f "$ROOT/build/bin/llama-cli" ] && [ -f "$ROOT/build/llama-cli" ]; then
  cp "$ROOT/build/llama-cli" "$ROOT/build/bin/llama-cli"
fi

echo "Ready: $ROOT/build/bin/llama-quantize"
echo "Ready: $ROOT/build/bin/llama-cli"
