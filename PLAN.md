# 🧭 Uncensored GGUF মডেল — প্রথম থেকে শেষ পর্যন্ত পূর্ণাঙ্গ প্ল্যান

> **লক্ষ্য:** মোবাইলে **PocketPal AI** অ্যাপে চলবে এমন `.gguf` ফাইল বানানো — GitHub Actions দিয়েই, কোনো লোকাল GPU ছাড়া, এক ক্লিকে।
> **নীতি:** এই প্ল্যানে আমি ৯০% কাজ নিজে করে দেব — আপনার বারবার ইনপুট লাগবে না। আপনি শুধু ২-৩টা ক্লিক করবেন।

---

## ০) আমি আপনার রিপো পড়ে কী বুঝেছি

আপনার রিপোতে এখন আছে:

- `README (1).md` — GGUF Factory-এর সম্পূর্ণ ডকুমেন্টেশন (পাইপলাইনের বর্ণনা, `models.yaml` ফরম্যাট, quant টেবিল, খরচ, ট্রাবলশুটিং)
- `TROUBLESHOOTING.md` — ১১টা সাধারণ এররের সমাধান
- `README.md` — শুধু `# AI-M-Tset` লেখা (খালি)

কিন্তু **আসল পাইপলাইনের ফাইলগুলো এখনো নেই** — যেমন `.github/workflows/gguf-build.yml`, `models.yaml`, `scripts/build-llama-cpp.sh`, `scripts/smoke-test.sh`। এই প্ল্যান অনুযায়ী আমি সেগুলো এখনই বানিয়ে দিচ্ছি, যাতে আপনি `Run workflow` চাপলেই `.gguf` পেয়ে যান।

---

## ⚠️ গুরুত্বপূর্ণ — "Uncensored" নিয়ে সৎ আলোচনা

আপনি "Uncensored মডেল" চেয়েছেন — আমি বুঝতে পেরেছি আপনি কী বোঝাতে চাইছেন। এখানে দুটো জিনিস পরিষ্কার করা জরুরি:

1. **GPT-6 Astra / Gemini 4 Argon থেকে `.gguf` বানানো অসম্ভব** — কারণ এগুলো **Closed-weight**। ওয়েট ফাইল পাবলিক না — শুধু API আছে। `.gguf` হলো ওয়েটের ফরম্যাট, ওয়েট না থাকলে ফাইলও নেই। তাই বেস মডেল হিসেবে **Qwen3 / Gemma 3 / Llama 3.2 / Phi / Dolphin / OpenHermes**-এর মতো **Open-weight** মডেল ব্যবহার করতে হবে।

2. **"Uncensored" মানে কী?** ওপেন-সোর্স কমিউনিটিতে এটা সাধারণত বোঝায় — মডেলটি **অতিরিক্ত Refusal** (যেমন — বৈধ গল্প, রোলপ্লে, বিতর্কিত প্রশ্নে "আমি উত্তর দিতে পারব না") কম করে। কিন্তু এর মানে **অবৈধ/ক্ষতিকর কাজের নির্দেশ, ঘৃণা, বা বিপজ্জনক কন্টেন্ট** বানানোর লাইসেন্স নয়। PocketPal AI-তে মডেল **অফলাইনে** চলে, তাই দায়িত্ব আপনার ডিভাইসেই — আমি এমন কোনো মডেল বানিয়ে দেব না যেটা আইন বা নিরাপত্তা ভাঙতে উৎসাহ দেয়।

**আমার সমাধান:** আমি আপনাকে একটি **"Open & Controllable"** মডেল দেব — যেটা:
- PocketPal-এ নিখুঁতভাবে চলবে (Q4_K_M quant),
- System Prompt দিয়ে আপনি নিজেই টোন/আচরণ নিয়ন্ত্রণ করতে পারবেন (যেমন — বন্ধুত্বপূর্ণ, রোলপ্লে, বাংলায় উত্তর),
- কিন্তু **অবৈধ/ক্ষতিকর নির্দেশে** বাধা দেবে — এটা আপনার এবং রিপোর নিরাপত্তার জন্যও জরুরি।

> আপনি যদি নির্দিষ্ট কোনো বৈধ ব্যবহার (যেমন — গল্প লেখা, কোডিং সহকারী, বাংলা টিউটর) চান, বলুন — আমি সেই অনুযায়ী System Prompt ও মডেল সাজিয়ে দেব।

---

## 📱 PocketPal AI — মোবাইলে কী লাগবে (গবেষণা করা)

PocketPal AI (iOS/Android, ফ্রি, MIT) সরাসরি **GGUF** চালায় — ভিতরে `llama.cpp` (llama.rn) ইঞ্জিন। ইন্টারনেট শুধু মডেল ডাউনলোডে লাগে, চ্যাট সম্পূর্ণ অফলাইন।

| ফোনের RAM | কোন মডেল নেবেন | ফাইল সাইজ (Q4_K_M) |
|---|---|---|
| **3–4 GB ফ্রি** | 0.6B – 1.7B (Qwen3-0.6B, Gemma-3-1B, Llama-3.2-1B) | ~350 MB – ~1 GB |
| **6–8 GB ফ্রি** | 3B – 4B (Qwen3-4B, Phi-4-mini, Gemma-3-4B) | ~1.8 – 2.5 GB |
| **8 GB+ ফ্ল্যাগশিপ** | 7B–8B (Qwen2.5-7B, Llama-3.1-8B) | ~4 – 5 GB |

**Quant সুপারিশ PocketPal-এর জন্য:**
- **Q4_K_M — ডিফল্ট বেস্ট** (সাইজ ৭৫% কম, কোয়ালিটি ~96% থাকে) — সব ফোনে এটাই নিন [kaitchup.substack.com](https://kaitchup.substack.com/p/gguf-quantization-for-fast-and-memory)
- Q5_K_M — RAM বেশি থাকলে, কোড/যুক্তিতে একটু ভালো
- Q8_0 — ফোনে সাধারণত দরকার নেই (ফাইল ২× বড়)
- Q2/Q3 — শুধু টেস্টের জন্য, কোয়ালিটি অনেক কমে যায়

**ইনস্টল পদ্ধতি:** PocketPal → ☰ Menu → Models → `+` → Hugging Face সার্চ বা `Download` → Load। আপনি GitHub Release থেকে `.gguf` নামিয়ে ফোনে কপি করেও `+ → Local file` দিয়ে লোড করতে পারবেন।

---

## 🗺️ পূর্ণাঙ্গ প্ল্যান — ৬ ধাপ, আপনার ইনপুট মিনিমাম

### ধাপ ১ — রিপো ও পাইপলাইন প্রস্তুত (আমি করব — ১০০%)
**আপনার কাজ:** কিছুই না।
**আমি যা বানিয়ে দিচ্ছি (এই সেশনে):**
- `models.yaml` — ৩টা রেডি প্রিসেট (ছোট/মাঝারি/ভারসাম্য), আপনি শুধু কমেন্ট খুলবেন
- `.github/workflows/gguf-build.yml` — ডাউনলোড → convert → quantize → smoke test → Release
- `scripts/build-llama-cpp.sh` — llama.cpp বিল্ড + ক্যাশ (২য় বার থেকে ১০× দ্রুত)
- `scripts/smoke-test.sh` — GGUF ম্যাজিক + মেটাডেটা + টোকেন জেনারেশন টেস্ট
- `README.md` আপডেট + `docs/AGENT_SETUP.md` (ঐচ্ছিক)
- `.gitignore` — বড় ফাইল ভুলে কমিট না হয়

**কেন এটা জরুরি?** আপনার আগের README-তে পাইপলাইনের বর্ণনা আছে কিন্তু ফাইল নেই — আমি ফাঁকটা পূরণ করে দিচ্ছি।

---

### ধাপ ২ — বেস মডেল সিলেকশন (আপনার ১টা সিদ্ধান্ত, বাকি আমি)
**আপনার কাজ:** নিচের ৩টার মধ্যে ১টা বেছে নিন (বা আমাকে বলুন "তুমি বেছে দাও"):

| প্রিসেট | HF Repo | সাইজ (Q4_K_M) | ভালো কিসে | লাইসেন্স | PocketPal |
|---|---|---|---|---|---|
| **A. Ultra-Light (টেস্ট)** | `Qwen/Qwen3-0.6B` | ~380 MB | সব ফোনে চলবে, বাংলা ভালো | Apache 2.0 | ✅ |
| **B. Balanced (সুপারিশ)** | `Qwen/Qwen3-1.7B` বা `google/gemma-3-1b-it` | ~900 MB – 1.1 GB | গতি + কোয়ালিটি ব্যালান্স | Apache 2.0 / Gemma Terms | ✅ |
| **C. Powerful** | `Qwen/Qwen3-4B` বা `microsoft/Phi-4-mini-instruct` | ~2.2 – 2.5 GB | কোড, যুক্তি, লম্বা গল্প | Apache 2.0 / MIT | 6GB+ RAM |

> **"Uncensored" ভ্যারিয়েন্ট:** নন-গেটেড Qwen/Phi দিয়ে শুরু করুন — এগুলোতে HF_TOKEN লাগে না, ফ্রি রানারে নিশ্চিত চলে। পরে চাইলে `cognitivecomputations/Dolphin-Mistral-*` বা `NousResearch/Hermes-*` (আরও খোলামেলা টোন) — আমি `models.yaml`-এ কমেন্ট হিসেবে রেখে দেব, আপনি শুধু আনকমেন্ট করবেন।

**আমি যা করব:** আপনি বাছাই করলেই আমি `models.yaml`-এ সেটা অ্যাক্টিভ করে কমিট করে দেব। না বললে আমি **B (Qwen3-1.7B)** দিয়ে শুরু করব — এটা বাংলাও ভালো বোঝে এবং PocketPal-এ সবচেয়ে জনপ্রিয়।

---

### ধাপ ৩ — GitHub Actions দিয়ে GGUF বানানো (আপনার ২ ক্লিক)
**আপনার কাজ:**
1. GitHub → আপনার রিপো → **Actions** ট্যাব → **"I understand my workflows, go ahead and enable them"** (প্রথমবার)
2. বাঁ দিকে **GGUF Factory** → **Run workflow** → **Run workflow**

**আমি যা করেছি:** ওয়ার্কফ্লোতে আগেই লেখা থাকবে:
```yaml
models.yaml থেকে safetensors ডাউনলোড
  → convert_hf_to_gguf.py --outtype f16
  → llama-quantize Q4_K_M (ও Q8_0 যদি চান)
  → smoke test (GGUF header + token generate)
  → Artifact + Release-এ .gguf আপলোড
```
- প্রতিটি `name × quant` আলাদা job — সমান্তরালে চলে
- `HF_TOKEN` secret থাকলে gated মডেল (Gemma/Llama) ও নামবে, না থাকলেও Qwen চলবে
- ক্যাশ থাকায় ২য় রান থেকে বিল্ড ২-৩ মিনিটে শেষ

**সময়:** প্রথম রানে ~15-25 মিনিট, পরের রান ~8-12 মিনিট।

---

### ধাপ ৪ — কোয়ান্টাইজেশন — PocketPal-এর জন্য অপটিমাইজ (আমি করব)
আমি ডিফল্ট হিসেবে দেব:
- **Q4_K_M** — PocketPal-এর জন্য বেস্ট [mintlify.com](https://mintlify.com/ggml-org/llama.cpp/models/quantizing-models)
- **Q8_0** — ঐচ্ছিক, কোয়ালিটি-প্রিয়দের জন্য

আপনি `models.yaml`-এ `quants: [Q4_K_M]` রাখলে ফাইল ছোট থাকবে, `quants: [Q4_K_M, Q8_0, Q5_K_M]` দিলে একসাথে ৩টা ভার্সন পাবেন।

**ডিস্ক/র‍্যাম সীমা (ফ্রি রানার: 14GB ডিস্ক, 7GB RAM):**
- 0.6B–3B → ✅ নিশ্চিত চলবে
- 4B → ⚠️ Q4_K_M-এ চলবে, F16-এ টাইট
- 8B+ → ❌ ফ্রি রানারে নয় — 16-core রানার বা self-hosted লাগবে (আমি ওয়ার্কফ্লোতে অপশন রেখে দেব)

---

### ধাপ ৫ — টেস্ট ও ভেরিফিকেশন (অটোমেটেড)
ওয়ার্কফ্লোর ভিতরেই ৩-ধাপ smoke test:
1. **GGUF Magic** — ফাইল হেডার `GGUF` কিনা
2. **Metadata** — `general.architecture`, `tokenizer.ggml.tokens` আছে কিনা
3. **Token Generate** — `llama-cli -m model.gguf -p "হ্যালো" -n 20` — আসলেই টোকেন বের হয় কিনা

ফেল করলে Release হবে না — ভাঙা ফাইল পাবেন না।

---

### ধাপ ৬ — PocketPal-এ ইনস্টল (আপনার ২ মিনিট)
1. GitHub → **Releases** → আপনার `Qwen3-1.7B-Q4_K_M.gguf` ডাউনলোড (ফোনে বা PC-তে)
2. PocketPal খুলুন → **Models** → **+** → **Local file** → ফাইল সিলেক্ট → **Load**
3. অথবা Hugging Face-এ আপলোড করলে PocketPal-এর ভিতর থেকেই সার্চ করে নামাতে পারবেন

**System Prompt টিপস (PocketPal-এ Pals → Create):**
```
আপনি একজন বন্ধুত্বপূর্ণ বাংলা সহকারী। সংক্ষেপে, স্পষ্টভাবে উত্তর দিন।
অবৈধ বা ক্ষতিকর কাজে সাহায্য করবেন না — বরং নিরাপদ বিকল্প দিন।
```

---

## 🔜 পরের ধাপ — নিজের ডেটা দিয়ে ফাইন-টিউন (ঐচ্ছিক, পরে)

এখন আমরা শুধু **Convert** করছি। পরে যদি নিজের ডেটা (যেমন — আপনার লেখা, চ্যাট হিস্ট্রি, বাংলা ডেটাসেট) দিয়ে মডেলকে আরও ভালো বানাতে চান:

```
Training (GPU, QLoRA) → Adapter merge → convert_hf_to_gguf.py → quantize → Release
```

এটা একই পাইপলাইনে ২টা স্টেপ যোগ করলেই হবে — আমি `finetune.yml` ওয়ার্কফ্লো আগে থেকে রেডি রাখব, আপনি চাইলে পরে চালাবেন। GPU লাগবে (Colab/Kaggle বা HF Spaces)।

---

## ✅ আমি এখনই যা করছি (এই সেশনে — আপনার ইনপুট ছাড়াই)

- [x] রিপো পড়া ও গবেষণা
- [ ] `PLAN.md` (এই ফাইল) তৈরি — ✅ সম্পন্ন
- [ ] `models.yaml` — ৩ প্রিসেট + uncensored কমেন্ট
- [ ] `.github/workflows/gguf-build.yml` — সম্পূর্ণ পাইপলাইন
- [ ] `scripts/build-llama-cpp.sh` + `scripts/smoke-test.sh`
- [ ] `README.md` ও `TROUBLESHOOTING.md` আপডেট
- [ ] `.gitignore`
- [ ] প্রথম কমিট ও পুশ → আপনি শুধু Actions → Run workflow চাপবেন

---

## ❓ আপনার কাছে ১টা প্রশ্ন

আপনি কোন প্রিসেট দিয়ে শুরু করতে চান?

- **A (0.6B)** — সবচেয়ে ছোট, টেস্টের জন্য
- **B (1.7B)** — আমার সুপারিশ (ব্যালান্স)
- **C (4B)** — সবচেয়ে শক্তিশালী

কিছু না বললে আমি **B** দিয়ে পাইপলাইন রেডি করে দেব — পরে `models.yaml`-এ ১ লাইন বদলালেই অন্য মডেল বানাতে পারবেন।

---

## 📚 রেফারেন্স

- PocketPal AI: GGUF, Hugging Face ইন্টিগ্রেশন, অফলাইন চ্যাট [github.com/a-ghorbani/pocketpal-ai](https://github.com/a-ghorbani/pocketpal-ai)
- llama.cpp quant: Q4_K_M best balance [mintlify.com](https://mintlify.com/ggml-org/llama.cpp/models/quantizing-models)
- HF → GGUF convert: `convert_hf_to_gguf.py` → `llama-quantize` [huggingface.co](https://huggingface.co/rohan23998/llama-cpp-model/blob/main/tools/quantize/README.md)
