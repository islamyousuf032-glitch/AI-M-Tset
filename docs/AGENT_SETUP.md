# AGENT_SETUP.md — AI এজেন্টকে রিপোর সাথে কানেক্ট করা

এই ডকুমেন্ট আপনার "এজেন্টের ব্রেন" (GPT-6 Astra / Gemini 4 Argon / Claude) কে এই রিপোতে কাজ করানোর জন্য।

## ধারণা

- **এজেন্টের ব্রেন** = API দিয়ে কোড লেখে, কমিট করে, PR খোলে (Astra/Argon)
- **আপনার মডেল** = Hugging Face থেকে GGUF বানানো (এই রিপো)

দুটো আলাদা — একটার জন্য API key, আরেকটার জন্য HF download।

## সেটআপ

### Option 1: Codex CLI (Astra)
```bash
npm i -g @openai/codex
codex login  # API key দিন
codex --repo ~/AI-M-Tset
```

### Option 2: Claude Code
```bash
npm i -g @anthropic-ai/claude-code
claude login
claude --repo ~/AI-M-Tset
```

### Option 3: Gemini CLI
```bash
npm i -g @google/gemini-cli
gemini login
```

## এই রিপোতে এজেন্ট কী করবে

- `models.yaml` এডিট করে মডেল পরিবর্তন
- Workflow চালানো ও লগ পড়া
- Release থেকে GGUF ভেরিফাই
- প্রয়োজনে `finetune.yml` যোগ করা

## টিপস

- পাবলিক রিপো হলে Actions ফ্রি — প্রাইভেটে মাসে 2000 মিনিট
- প্রথমবার Actions ট্যাবে "Enable workflows" চাপতে হয়
- Gated মডেলের জন্য `HF_TOKEN` secret যোগ করুন
