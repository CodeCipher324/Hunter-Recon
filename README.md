# ⚡ HUNTER

**HUNTER** is a signal-based, passive bug hunting framework designed to quickly discover low-hanging vulnerabilities using public and non-intrusive reconnaissance techniques.

It automates URL collection, normalization, vulnerability signal filtering, and low-impact scanning — giving you **actionable attack surfaces** to manually verify and report.

---

## ✨ Features

- Passive URL collection (GAU, Wayback, Hakrawler)
- URL normalization & deduplication
- Vulnerability signal filtering (XSS, SQLi, SSRF, LFI, SSTI, Open Redirect, RCE indicators)
- Low-hanging fruit detection using **Nuclei**
- Safe for bug bounty programs (unauthenticated & passive)
- Works on **Linux, Termux, and mobile setups**
- No heavy exploitation by default

---

## 🧠 How It Works (High Level)

1. Accepts a **domain** or a **single URL**
2. Collects URLs from passive sources
3. Cleans and deduplicates URLs
4. Filters URLs based on vulnerability patterns
5. Runs Nuclei for common misconfigurations & exposures
6. Saves everything for **manual validation**

> HUNTER focuses on **signals**, not blind exploitation.

---

## 📦 Requirements

Make sure these tools are installed and available in your `$PATH`:

- `bash`
- `curl`
- `httpx`
- `gau`
- `waybackurls`
- `hakrawler`
- `nuclei`

> Optional tools (manual use only):
> - Dalfox (XSS)
> - sqlmap (SQLi)
> - SSRFmap (SSRF)
> - tplmap (SSTI)

---

## 🚀 Installation

```bash
git clone https://github.com/yourusername/hunter.git
cd hunter
chmod +x hunter.sh

run:
./hunter.sh -d target.com
./hunter.sh -u https://target.com
