# GGUF Factory 🏭

Hugging Face-এর ওপেন-ওয়েট মডেল থেকে **GitHub Actions দিয়েই** `.gguf` ফাইল বানানোর
সম্পূর্ণ অটোমেটেড পাইপলাইন। কোনো লোকাল GPU লাগবে না, কোনো টাকা লাগবে না
(পাবলিক রিপোতে)।

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
              smoke test (আসলেই টোকেন জেনারেট হয় কিনা)
                     │
                     ▼
              Actions artifact  +  GitHub Release
```

---

## ⚠️ শুরু করার আগে — একটা জরুরি কথা

**GPT-6 Astra আর Gemini 4 Argon থেকে `.gguf` বানানো অসম্ভব।**

কারণটা সহজ: দুটোই **ক্লোজড-ওয়েট** মডেল। ওগুলোর ওয়েট ফাইল পাবলিকলি ডাউনলোড
করার কোনো উপায় নেই — শুধু API অ্যাক্সেস আছে। `.gguf` হলো একটা *ওয়েট ফরম্যাট*,
তাই ওয়েট না থাকলে ফরম্যাটও নেই।

তাই এই প্রজেক্টে দুটো জিনিস আলাদা করে ভাবুন:

| | কী | কীভাবে পাবেন |
|---|---|---|
| **এজেন্টের ব্রেন** | Astra / Argon — যে কোড লিখে, কমিট করে, PR খোলে | API key দিয়ে (Codex CLI, Claude Code, Gemini CLI) |
| **আপনার মডেল** | Qwen3 / Gemma / Llama — যেটার `.gguf` বানাবেন | Hugging Face থেকে ফ্রি ডাউনলোড |

এই রিপোটা দ্বিতীয়টার জন্য। প্রথমটার সেটআপ গাইড আছে `docs/AGENT_SETUP.md`-তে।

---

## 🚀 দ্রুত শুরু

### ১. রিপো পুশ করা

```bash
cd gguf-factory
git add -A
git commit -m "GGUF factory pipeline"
git branch -M main
git remote add origin https://github.com/<আপনার-ইউজারনেম>/<রিপো-নাম>.git
git push -u origin main
```

> টিপ: GitHub-এ রিপো তৈরির সময় **README/license/gitignore টিক দেবেন না** —
> খালি রিপো হলে `git push` একদমে চলে যাবে, না হলে আগে `git pull --rebase` লাগবে।

### ২. ওয়ার্কফ্লো চালানো

GitHub → আপনার রিপো → **Actions** ট্যাব → বাঁ দিকে **GGUF Factory** →
ডান দিকে **Run workflow** → **Run workflow**।

ব্যস। ~১৫-২৫ মিনিট পরে Release ট্যাবে আপনার `.gguf` ফাইল চলে আসবে।

> প্রথমবার Actions ট্যাবে "Workflows aren't being run" লেখা দেখালে
> বাটনটা চেপে দিন — নতুন রিপোতে ফর্ক/কপি করা ওয়ার্কফ্লো একবার
> ম্যানুয়ালি এনাবল করতে হয়।

### ৩. কোন মডেল বানাবেন ঠিক করা

`models.yaml` এডিট করুন। এক একটা ব্লক = এক একটা মডেল:

```yaml
models:
  - name: Qwen3-0.6B          # ফাইলনেমে ব্যবহার হবে
    repo: Qwen/Qwen3-0.6B     # Hugging Face repo id
    quants: [Q4_K_M, Q8_0]    # কোন কোন সাইজে বানাবেন
    test_prompt: "The capital of France is"
```

প্রতিটা `name × quant` জোড়া একটা আলাদা job — সব সমান্তরালে চলে।

---

## 📦 কোয়ান্টাইজেশন লেভেল — কোনটা নেবেন?

| লেভেল | সাইজ (0.6B মডেলে) | কোয়ালিটি | কখন ব্যবহার করবেন |
|---|---|---|---|
| `F16` | ~1.2 GB | ১০০% (লসলেস) | আর্কাইভ / পরে আবার কোয়ান্টাইজ করার জন্য |
| `Q8_0` | ~650 MB | ~৯৯.৫% | কোয়ালিটি নিয়ে সিরিয়াস হলে |
| `Q6_K` | ~500 MB | ~৯৯% | ভালো ব্যালান্স |
| `Q5_K_M` | ~430 MB | ~৯৮% | মোবাইল/লো-র‍্যাম ডিভাইস |
| **`Q4_K_M`** | **~380 MB** | **~৯৬%** | **ডিফল্ট সুপারিশ — সবচেয়ে জনপ্রিয়** |
| `Q4_0` | ~360 MB | ~৯৩% | ছোট, কিন্তু কোয়ালিটি কিছুটা কম |
| `Q3_K_M` | ~310 MB | ~৮৮% | খুব কম র‍্যাম হলে |
| `Q2_K` | ~260 MB | ~৭৫% | শুধু পরীক্ষার জন্য |

সব লেভেলের লিস্ট: `llama-quantize --help`

---

## 🔑 Gated মডেল (Llama / Gemma) ব্যবহার করতে চাইলে

Meta-র Llama আর Google-এর Gemma ডাউনলোড করতে HF-এ অনুমতি নিতে হয়।

1. https://huggingface.co/settings/tokens → **New token** → টাইপ `Read` → কপি করুন
2. মডেল পেজে গিয়ে **Agree and access repository** চাপুন
   (যেমন: https://huggingface.co/google/gemma-3-1b-it)
3. আপনার রিপোতে → **Settings** → **Secrets and variables** → **Actions** →
   **New repository secret** → নাম `HF_TOKEN`, মান `hf_...` → Add
4. `models.yaml`-এ Gemma/Llama ব্লকটার কমেন্ট (`#`) সরিয়ে দিন

পাবলিক মডেলের (Qwen, Mistral, Phi) জন্য এটার কিছুই লাগবে না।

---

## 🧪 বানানো মডেল চালানো

### llama.cpp দিয়ে

```bash
# আপনার Release থেকে ফাইলটা নামান, তারপর
./llama-cli -m Qwen3-0.6B-Q4_K_M.gguf -p "হ্যালো, কেমন আছো?" -n 128

# অথবা লোকাল সার্ভার হিসেবে (OpenAI-compatible API)
./llama-server -m Qwen3-0.6B-Q4_K_M.gguf --port 8080 -ngl 99
```

### Ollama দিয়ে

```bash
# Modelfile নামে একটা ফাইল বানান
echo 'FROM ./Qwen3-0.6B-Q4_K_M.gguf' > Modelfile
ollama create amar-model -f Modelfile
ollama run amar-model
```

### LM Studio দিয়ে
শুধু `.gguf` ফাইলটা `~/.lmstudio/models/<publisher>/<name>/` ফোল্ডারে ফেলে দিন।

---

## 🎛️ ওয়ার্কফ্লো ইনপুট (Run workflow-এর সময়)

| ইনপুট | কাজ |
|---|---|
| `model_filter` | শুধু এই নাম মিলে এমন মডেল বানাবে। খালি = সব |
| `quant_override` | `models.yaml` উপেক্ষা করে এই quant-গুলো বানাবে, যেমন `Q4_K_M,Q6_K` |
| `llama_cpp_ref` | llama.cpp-র নির্দিষ্ট ভার্সন পিন করা, যেমন `b6500` |
| `create_release` | বন্ধ করলে শুধু artifact হবে, Release হবে না |

---

## 💰 খরচ

| সেটআপ | খরচ |
|---|---|
| **পাবলিক রিপো + স্ট্যান্ডার্ড রানার** | **৳০ — সম্পূর্ণ ফ্রি, মিনিটের কোনো ক্যাপ নেই** |
| প্রাইভেট রিপো (ফ্রি প্ল্যান) | মাসে ২,০০০ মিনিট ফ্রি, এরপর $0.006/মিনিট |
| GPU রানার (T4, ৪-কোর) | $0.052/মিনিট (~$3.12/ঘণ্টা) — পাবলিক রিপোতেও বিল হয় |

⚠️ **সীমা জানা জরুরি:** স্ট্যান্ডার্ড রানারে ~১৪ GB ডিস্ক আর ৭ GB র‍্যাম।
তাই 8B মডেলের F16 GGUF (~16 GB) এখানে আঁটবে না — বড় মডেলের জন্য
১৬-কোর রানার (পেইড) বা self-hosted রানার লাগবে। 0.6B–3B মডেল নির্ঝঞ্ঝাটে চলে।

---

## 📁 ফোল্ডার স্ট্রাকচার

```
gguf-factory/
├── .github/workflows/gguf-build.yml   # মূল পাইপলাইন
├── models.yaml                        # কোন মডেল বানাবেন ← এটা এডিট করুন
├── scripts/
│   ├── build-llama-cpp.sh             # llama.cpp কম্পাইল (ক্যাশ করা হয়)
│   └── smoke-test.sh                  # বিল্ডের পর ৩-ধাপ যাচাই
├── docs/
│   ├── AGENT_SETUP.md                 # AI এজেন্টকে রিপোর সাথে কানেক্ট করা
│   └── TROUBLESHOOTING.md             # সাধারণ এরর ও সমাধান
└── README.md
```

---

## 🔜 পরের ধাপ: নিজের ডেটা দিয়ে ফাইন-টিউন

এখন আপনি শুধু কনভার্ট করছেন। নিজের ডেটাসেট দিয়ে মডেলটাকে সত্যিই
কাজের বানাতে চাইলে QLoRA ফাইন-টিউনিং লাগবে — সেটার জন্য GPU দরকার,
কিন্তু **পুরো পাইপলাইনটা হুবহু একই থাকে**:

```
ট্রেইনিং (GPU)  →  adapter merge  →  convert_hf_to_gguf.py  →  quantize  →  Release
   ▲                    ▲
   এই দুটো স্টেপ যোগ হবে, বাকি সব একই
```

বললে এই রিপোতেই `finetune.yml` ওয়ার্কফ্লো যোগ করে দেব।

---

## 📄 লাইসেন্স

পাইপলাইনের কোড MIT। তবে **বানানো মডেলের লাইসেন্স আলাদা** — সেটা বেস মডেলের
লাইসেন্স অনুযায়ী হয় (Qwen3 = Apache 2.0, Gemma = Gemma Terms, Llama = Community License)।
রিডিস্ট্রিবিউট করার আগে বেস মডেলের লাইসেন্স একবার পড়ে নেবেন।
