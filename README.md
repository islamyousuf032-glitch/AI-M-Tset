# GGUF Factory 🏭 — PocketPal AI Ready

> Hugging Face-এর ওপেন-ওয়েট মডেল থেকে **GitHub Actions দিয়েই** `.gguf` বানিয়ে **PocketPal AI (iOS/Android)** অ্যাপে চালান — কোনো লোকাল GPU লাগবে না, সম্পূর্ণ ফ্রি (পাবলিক রিপো)।

```
models.yaml  ──▶  HF থেকে safetensors ডাউনলোড
                     │
                     ▼
              convert_hf_to_gguf.py  ──▶  model-f16.gguf
                     │
                     ▼
              llama-quantize (Q4_K_M / Q8_0 / ...)
                     │
                     ▼
              smoke test (GGUF magic + token generate)
                     │
                     ▼
              Actions artifact  +  GitHub Release  ──▶  PocketPal AI
```

**পূর্ণাঙ্গ প্ল্যান দেখুন:** [`PLAN.md`](./PLAN.md)

---

## ⚠️ শুরু করার আগে — জরুরি কথা

**GPT-6 Astra / Gemini 4 Argon থেকে `.gguf` বানানো অসম্ভব** — এগুলো **Closed-weight** (শুধু API, ওয়েট পাবলিক না)। `.gguf` হলো ওয়েট ফরম্যাট, ওয়েট না থাকলে ফাইলও নেই।

তাই এই প্রজেক্টে:
| কী | উদাহরণ | কীভাবে |
|---|---|---|
| **এজেন্টের ব্রেন** | Astra/Argon | API key দিয়ে |
| **আপনার মডেল** | Qwen3 / Gemma 3 / Llama 3.2 / Phi | Hugging Face থেকে ফ্রি |

এই রিপো দ্বিতীয়টার জন্য। "Uncensored" মানে অতিরিক্ত Refusal কম — অবৈধ/ক্ষতিকর কাজ নয়। বিস্তারিত [`PLAN.md`](./PLAN.md)-এ।

---

## 🚀 দ্রুত শুরু (২ ক্লিক)

### ১. Actions এনাবল করুন
GitHub → আপনার রিপো → **Actions** ট্যাব → **"I understand my workflows, go ahead and enable them"** (প্রথমবার একবার)

### ২. Workflow চালান
**Actions** → বাঁ দিকে **GGUF Factory** → ডান দিকে **Run workflow** → **Run workflow** → ~15-25 মিনিট পর **Releases**-এ `.gguf` পাবেন।

### ৩. কোন মডেল বানাবেন ঠিক করুন
`models.yaml` এডিট করুন — একটা ব্লক = একটা মডেল:
```yaml
models:
  - name: Qwen3-1.7B
    repo: Qwen/Qwen3-1.7B
    quants: [Q4_K_M]   # PocketPal-এর জন্য বেস্ট
    test_prompt: "হ্যালো, কেমন আছো?"
```
প্রতিটি `name × quant` আলাদা job — সমান্তরালে চলে।

---

## 📱 PocketPal AI-তে চালানো

1. GitHub **Releases** থেকে `.gguf` ডাউনলোড করুন (ফোনে বা PC → ফোনে কপি)
2. PocketPal খুলুন → **☰ Menu → Models → + → Local file** → ফাইল সিলেক্ট → **Load**
3. অথবা Hugging Face-এ আপলোড করলে অ্যাপের ভিতর থেকেই সার্চ করে নামাতে পারবেন

**System Prompt উদাহরণ (Pals → Create):**
```
তুমি একজন বন্ধুত্বপূর্ণ বাংলা সহকারী। সংক্ষেপে ও স্পষ্টভাবে উত্তর দাও।
অবৈধ বা ক্ষতিকর কাজে সাহায্য করো না — বরং নিরাপদ বিকল্প দাও।
```

| ফোনের RAM | মডেল সাইজ | Q4_K_M ফাইল |
|---|---|---|
| 3–4 GB ফ্রি | 0.6B – 1.7B | ~380 MB – 1 GB |
| 6–8 GB ফ্রি | 3B – 4B | ~1.8 – 2.5 GB |

---

## 📦 কোয়ান্টাইজেশন — কোনটা নেবেন?

| লেভেল | সাইজ (1.7B মডেলে) | কোয়ালিটি | কখন |
|---|---|---|---|
| `F16` | ~3.4 GB | 100% | আর্কাইভ |
| `Q8_0` | ~1.8 GB | ~99.5% | কোয়ালিটি প্রায়োরিটি |
| **`Q4_K_M`** | **~1 GB** | **~96%** | **PocketPal ডিফল্ট ⭐** |
| `Q5_K_M` | ~1.15 GB | ~98% | RAM বেশি থাকলে |
| `Q3_K_M` | ~800 MB | ~88% | খুব কম RAM |

`Q4_K_M` হলো llama.cpp-এর **Best Balance** — 75% ছোট, কোয়ালিটি প্রায় অক্ষুণ্ণ।

---

## 🔑 Gated মডেল (Llama/Gemma) — HF_TOKEN লাগবে

1. https://huggingface.co/settings/tokens → **New token (Read)** → কপি
2. মডেল পেজে **Agree and access repository**
3. রিপো → **Settings → Secrets and variables → Actions → New repository secret** → `HF_TOKEN` = `hf_...`
4. `models.yaml`-এ Gemma/Llama ব্লকের `#` সরিয়ে দিন

**Qwen/Phi/Mistral** — gated নয়, টোকেন লাগে না। প্রথম টেস্ট এগুলো দিয়ে করুন।

---

## 🎛️ Workflow ইনপুট

| ইনপুট | কাজ |
|---|---|
| `model_filter` | শুধু নাম মিলে এমন মডেল বানাবে (খালি = সব) |
| `quant_override` | `models.yaml` উপেক্ষা করে এই quant বানাবে, যেমন `Q4_K_M,Q6_K` |
| `llama_cpp_ref` | llama.cpp ভার্সন পিন, যেমন `b6500` |
| `create_release` | বন্ধ করলে শুধু artifact, Release নয় |

---

## 💰 খরচ

| সেটআপ | খরচ |
|---|---|
| **পাবলিক রিপো + স্ট্যান্ডার্ড রানার** | **৳০ — ফ্রি, আনলিমিটেড** |
| প্রাইভেট রিপো (ফ্রি প্ল্যান) | মাসে 2,000 মিনিট ফ্রি |
| GPU রানার | $0.052/মিনিট — পাবলিকেও বিল হয় |

⚠️ স্ট্যান্ডার্ড রানার: **14GB ডিস্ক, 7GB RAM** — 8B F16 (~16GB) আঁটবে না। 0.6B–4B নির্ঝঞ্ঝাটে চলে। বড় মডেলের জন্য `ubuntu-24.04-16-core` বা self-hosted।

---

## 📁 ফোল্ডার স্ট্রাকচার

```
.
├── .github/workflows/gguf-build.yml   # মূল পাইপলাইন
├── models.yaml                        # কোন মডেল বানাবেন ← এটা এডিট করুন
├── scripts/
│   ├── build-llama-cpp.sh             # llama.cpp বিল্ড (ক্যাশ)
│   └── smoke-test.sh                  # 3-ধাপ যাচাই
├── PLAN.md                            # পূর্ণাঙ্গ প্ল্যান (বাংলা)
├── TROUBLESHOOTING.md                 # সাধারণ এরর ও সমাধান
└── README.md
```

---

## 🆘 সমস্যা হলে

`TROUBLESHOOTING.md` দেখুন — 11টা সাধারণ এরর + সমাধান। তবুও না হলে Actions লগ কপি করে Issue খুলুন।

## 📄 লাইসেন্স

পাইপলাইন কোড **MIT**। বানানো মডেলের লাইসেন্স বেস মডেল অনুযায়ী (Qwen = Apache 2.0, Gemma = Gemma Terms, Llama = Community License)।

---

## 🔜 পরের ধাপ: ফাইন-টিউন

এখন শুধু Convert — নিজের ডেটা দিয়ে ট্রেইন করতে চাইলে QLoRA পাইপলাইন একই থাকবে, শুধু ২টা স্টেপ যোগ হবে। বললে `finetune.yml` যোগ করে দেব।
