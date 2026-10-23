# 🔧 Troubleshooting — সাধারণ এরর ও সমাধান

---

## 1. `Error: 403 Resource not accessible by integration`

**কারণ:** ওয়ার্কফ্লোর কাছে Release তৈরির পারমিশন নেই।

**সমাধান:**
- রিপো → Settings → Actions → General → **Workflow permissions**
- **Read and write permissions** সিলেক্ট করুন → Save
- তারপর ওয়ার্কফ্লো আবার চালান

(এই রিপোর ওয়ার্কফ্লোতে `permissions: contents: write` আগে থেকেই লেখা আছে,
তাই org-level পলিসি ব্লক না করলে এটা নিয়ে সমস্যা হওয়ার কথা না।)

---

## 2. `Workflows aren't being run on this fork` / Actions ট্যাব খালি

**কারণ:** নতুন রিপোতে কপি করা ওয়ার্কফ্লো একবার ম্যানুয়ালি এনাবল করতে হয়।

**সমাধান:** Actions ট্যাবে বড় সবুজ বাটন **"I understand my workflows, go ahead and enable them"** চাপুন।

---

## 3. `OSError: ... is not a gated repo but you are not authenticated` বা `401 Unauthorized`

**কারণ:** gated মডেল (Llama, Gemma) ডাউনলোডে HF token লাগে।

**সমাধান:**
1. https://huggingface.co/settings/tokens → Read token বানান
2. মডেলের পেজে গিয়ে লাইসেন্স **Agree** করুন (Meta/Google দুটোতেই আলাদা করে করতে হয়)
3. রিপো → Settings → Secrets and variables → Actions → `HF_TOKEN` যোগ করুন

অথবা সহজ পথ: প্রথমে **Qwen** দিয়ে টেস্ট করুন — Qwen gated নয়, টোকেন লাগে না।

---

## 4. `No space left on device`

**কারণ:** স্ট্যান্ডার্ড রানারে ~১৪ GB ডিস্ক। বড় মডেলের F16 GGUF এতে আঁটবে না।

| মডেল সাইজ | F16 GGUF | ফ্রি রানারে চলবে? |
|---|---|---|
| 0.6B | ~1.2 GB | ✅ হ্যাঁ |
| 1.7B | ~3.4 GB | ✅ হ্যাঁ |
| 4B | ~8 GB | ⚠️ টাইট, Q4_K_M হলে চলবে |
| 8B | ~16 GB | ❌ না |
| 14B+ | ~28 GB+ | ❌ না |

**সমাধান:**
- ছোট মডেল ব্যবহার করুন, অথবা
- ওয়ার্কফ্লোতে `runs-on: ubuntu-latest` বদলে `ubuntu-24.04-16-core` দিন (পেইড, ~$0.042/মিনিট), অথবা
- self-hosted রানার বসান

**ডিস্ক বাঁচানোর ট্রিক:** কনভার্টের পর `--outtype q8_0` সরাসরি ব্যবহার করলে
মাঝখানের বিশাল f16 ফাইলটা তৈরিই হয় না:

```yaml
python third_party/llama.cpp/convert_hf_to_gguf.py "$MODEL_DIR" \
  --outfile "out/${BASE}-q8_0.gguf" --outtype q8_0
```

---

## 5. `Killed` বা `exit code 137`

**কারণ:** র‍্যাম শেষ। স্ট্যান্ডার্ড রানারে ~৭ GB RAM। কনভার্টার পুরো মডেল
মেমরিতে লোড করে।

**সমাধান:**
- 3B-র বড় মডেল এড়িয়ে চলুন ফ্রি রানারে
- সোয়াপ ফাইল যোগ করুন (ওয়ার্কফ্লোতে এই স্টেপ বসান):

```yaml
      - name: Add swap (র‍্যাম কম পড়লে)
        run: |
          sudo fallocate -l 8G /swapfile
          sudo chmod 600 /swapfile
          sudo mkswap /swapfile
          sudo swapon /swapfile
          free -h
```

---

## 6. `unknown model architecture: 'xyz'`

**কারণ:** মডেলের আর্কিটেকচার আপনার llama.cpp ভার্সনে সাপোর্টেড নয়।
llama.cpp-তে ১০০+ আর্কিটেকচার আছে, কিন্তু নতুন মডেল প্রায়ই কয়েক সপ্তাহ
আগে বের হয়, সাপোর্ট পরে আসে।

**সমাধান:**
- `llama_cpp_ref` ইনপুটে `master` দিন (লেটেস্ট কোড)
- Actions ক্যাশ মুছুন: রিপো → Settings → Actions → Caches → Delete
- llama.cpp-র GitHub Issues-তে আর্কিটেকচারের নাম লিখে সার্চ দিন —
  সাপোর্ট কবে আসছে জানা যাবে
- আপাতত সেই মডেলটার বদলে সমমানের আরেকটা মডেল ব্যবহার করুন

---

## 7. ক্যাশ থেকে পুরনো/ভাঙা বাইনারি আসছে

**লক্ষণ:** `Prepare tools` স্টেপে এরর, অথবা অদ্ভুত ক্র্যাশ।

**সমাধান:**
1. রিপো → Settings → Actions → Caches → সব `llama-bin-*` ক্যাশ Delete করুন
2. অথবা `scripts/build-llama-cpp.sh`-তে একটা তুচ্ছ পরিবর্তন করুন
   (ক্যাশ key ওই ফাইলের hash থেকে তৈরি, তাই hash বদলালেই ক্যাশ মিস হবে)
3. আবার রান দিন

---

## 8. smoke test-এ warning, কিন্তু ফাইল ঠিক আছে?

সাধারণ ব্যাপার। `llama-cli` কখনো কখনো chat template নিয়ে ঝামেলা করে,
বিশেষ করে reasoning মডেলে (Qwen3-এর `enable_thinking` ট্যাগ, Gemma-র
নিজস্ব টেমপ্লেট ইত্যাদি)।

**আসল টেস্ট হলো ধাপ ১ আর ২** — GGUF ম্যাজিক নম্বর আর মেটাডেটা। ওগুলো
পাস করলে ফাইলটা ঠিক আছে। ধাপ ৩ ফেল করলে চালানোর সময় এই ফ্ল্যাগগুলো
দেখুন:

```bash
# Qwen3-এর thinking বন্ধ করে
./llama-cli -m model.gguf -p "হ্যালো" -n 64 --reasoning-budget 0

# chat template বাদ দিয়ে সরাসরি কন্টিনিউয়েশন
./llama-cli -m model.gguf -p "হ্যালো" -n 64 --no-template
```

---

## 9. Actions চালালাম, কিন্তু কিছুই হচ্ছে না

**চেকলিস্ট:**
- [ ] `.github/workflows/gguf-build.yml` ঠিক এই পাথে আছে? (বানান ভুল হলে চলবে না)
- [ ] Actions ট্যাব এনাবল করা?
- [ ] ডিফল্ট ব্রাঞ্চের নাম `main`? ওয়ার্কফ্লোতে `branches: [main]` লেখা আছে
- [ ] org/account-এ Actions ব্লক করা নেই? (Settings → Actions → General → Allow all actions)

---

## 10. বিল্ড খুব ধীর

স্ট্যান্ডার্ড রানার ২ কোর। llama.cpp বিল্ডেই ১০-১৫ মিনিট যায়।

**দ্রুত করার উপায়:**
- **ক্যাশ ঠিকভাবে কাজ করছে কিনা দেখুন** — দ্বিতীয় রান থেকে বিল্ড স্টেপ
  `skipped` দেখানোর কথা। না দেখালে ক্যাশ key মিলছে না।
- একসাথে অনেক মডেল বানাবেন না — matrix job সমান্তরালে চলে, কিন্তু
  ফ্রি অ্যাকাউন্টে একসাথে সীমিত সংখ্যক job চলে, বাকিগুলো লাইনে দাঁড়ায়
- প্রয়োজনে `runs-on: ubuntu-24.04-8-core` ($0.022/মিনিট) — বিল্ড ৩-৪ গুণ দ্রুত হবে

---

## 11. Release-এ ফাইল আপলোড হচ্ছে না / `asset already exists`

**সমাধান:** ওয়ার্কফ্লোতে আগে থেকেই `--clobber` ফ্ল্যাগ দেওয়া আছে, তাই
একই ট্যাগে আবার আপলোড হলে পুরনোটা রিপ্লেস হবে।

তবুও আটকে গেলে:
```bash
gh release delete <ট্যাগ-নাম> --yes
gh workflow run gguf-build.yml
```

---

## 🆘 কিছুতেই সমাধান না হলে

Actions রানের ফেইল হওয়া স্টেপের পুরো লগ কপি করে আমাকে দিন।
লগ পেলে সাধারণত এক নজরেই বলে দেওয়া যায় সমস্যাটা কোথায়।

```bash
# লগ নামানোর সহজ উপায়
gh run view <run-id> --log-failed > fail.log
```
