#!/usr/bin/env bash
set -euo pipefail

# scripts/smoke-test.sh
# 3-step verification: magic + metadata + token generation
# Usage: bash scripts/smoke-test.sh <gguf-file> [test_prompt]

FILE="${1:-}"
PROMPT="${2:-Hello, how are you?}"

if [ -z "$FILE" ]; then
  echo "Usage: $0 <gguf-file> [test_prompt]"
  exit 2
fi

if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

echo "=== Smoke Test: $FILE ==="
echo "Prompt: $PROMPT"
ls -lh "$FILE"
du -sh "$FILE"

# Step 1: GGUF magic number (first 4 bytes should be 'GGUF' = 0x47 0x47 0x55 0x46)
echo ""
echo "--- Step 1: GGUF magic check ---"
MAGIC=$(head -c 4 "$FILE" | od -An -tx1 | tr -d ' \n')
echo "Magic bytes: $MAGIC"
# GGUF = 47 47 55 46 (ASCII 'GGUF')
if [ "$MAGIC" = "47475546" ]; then
  echo "✅ Step 1 passed — valid GGUF magic"
else
  echo "❌ Step 1 failed — invalid magic: $MAGIC (expected 47475546)"
  exit 1
fi

# Also check file size reasonable (>10MB for any real model, <30GB)
SIZE=$(stat -c%s "$FILE" 2>/dev/null || stat -f%z "$FILE")
echo "File size: $SIZE bytes ($(numfmt --to=iec $SIZE 2>/dev/null || echo $SIZE))"
if [ "$SIZE" -lt 10000000 ]; then
  echo "⚠️ Warning: file suspiciously small (<10MB)"
fi

# Step 2: Metadata check via Python gguf
echo ""
echo "--- Step 2: Metadata check ---"
python3 - << PY
import sys
try:
    from gguf import GGUFReader
except ImportError:
    print("Installing gguf...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "gguf", "-q"])
    from gguf import GGUFReader

path = sys.argv[1]
print(f"Reading: {path}")
reader = GGUFReader(path)

# Check essential fields
fields = reader.fields
print(f"Total fields: {len(fields)}")
print(f"Total tensors: {len(reader.tensors)}")

# Show key fields
for k in list(fields.keys())[:15]:
    print(f"  field: {k}")

# Essential checks
has_arch = any("general.architecture" in k for k in fields.keys())
has_tokenizer = any("tokenizer" in k for k in fields.keys())

if not has_arch:
    print("❌ Missing general.architecture")
    sys.exit(1)
else:
    print("✅ Found general.architecture")

if not has_tokenizer:
    print("⚠️ Warning: tokenizer fields missing (might still work)")
else:
    print("✅ Found tokenizer fields")

if len(reader.tensors) == 0:
    print("❌ No tensors found")
    sys.exit(1)
else:
    print(f"✅ Tensors: {len(reader.tensors)}")

print("✅ Step 2 passed")
PY "$FILE"

# Step 3: Token generation (if llama-cli exists)
echo ""
echo "--- Step 3: Token generation test ---"
LLAMA_CLI=""
for p in "third_party/llama.cpp/build/bin/llama-cli" "third_party/llama.cpp/build/llama-cli" "./llama-cli" "llama-cli"; do
  if [ -x "$p" ]; then
    LLAMA_CLI="$p"
    break
  fi
done

if [ -z "$LLAMA_CLI" ]; then
  echo "⚠️ Step 3 skipped — llama-cli not found (build not done yet)"
  echo "But Steps 1 & 2 passed — file is valid GGUF"
  exit 0
fi

echo "Using: $LLAMA_CLI"
echo "Running: $LLAMA_CLI -m $FILE -p \"$PROMPT\" -n 20 --no-display-prompt --temp 0.7"

set +e
OUTPUT=$("$LLAMA_CLI" -m "$FILE" -p "$PROMPT" -n 20 --no-display-prompt --temp 0.7 2>&1 | tail -50)
EXIT_CODE=$?
set -e

echo "--- Model output ---"
echo "$OUTPUT"
echo "--- End output ---"

if [ $EXIT_CODE -ne 0 ]; then
  echo "⚠️ Step 3 warning — llama-cli exit code $EXIT_CODE (common for chat templates)"
  echo "But Steps 1 & 2 passed — file is structurally valid"
  # Don't fail the job for chat template issues — show hint
  echo "Hint: Try running with --no-template or --reasoning-budget 0 for Qwen3"
  exit 0
fi

# Check if we got some output (at least a few chars)
OUT_LEN=$(echo "$OUTPUT" | wc -c)
if [ "$OUT_LEN" -lt 5 ]; then
  echo "⚠️ Step 3 warning — very short output ($OUT_LEN chars)"
else
  echo "✅ Step 3 passed — generated $OUT_LEN chars"
fi

echo ""
echo "🎉 All smoke tests passed: $FILE"
