#!/bin/bash
set -e

# ===================== COLORS =====================
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
NC="\033[0m"

# ===================== INPUT ======================
if [[ "$1" == "-d" && -n "$2" ]]; then
  MODE="DOMAIN"
  TARGET="$2"
elif [[ "$1" == "-u" && -n "$2" ]]; then
  MODE="URL"
  TARGET="$2"
else
  echo "Usage:"
  echo "  $0 -d target.com"
  echo "  $0 -u https://target.com"
  exit 1
fi

# ===================== DIRS =======================
BASE="hunter_work"
OUT="output"
FILTER="$BASE/filters"

mkdir -p "$BASE" "$OUT" "$FILTER"

# ===================== BANNER =====================
echo -e "\033[0;31m"
echo "██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ "
echo "██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗"
echo "███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝"
echo "██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗"
echo "██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║"
echo "╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
echo -e "\033[0m"
echo "⚡ HUNTER — Signal-Based Passive Bug Hunting"
echo "-------------------------------------------"

# ===================== SUBDOMAINS =================
if [[ "$MODE" == "DOMAIN" ]]; then
  echo "[+] Subdomain enumeration"
  subfinder -d "$TARGET" -silent > "$BASE/subs1.txt"
  assetfinder --subs-only "$TARGET" > "$BASE/subs2.txt"
  cat "$BASE"/subs*.txt | sort -u > "$BASE/subdomains.txt"
else
  echo "$TARGET" > "$BASE/subdomains.txt"
fi

# ===================== LIVE =======================
echo "[+] Checking live hosts"
httpx -l "$BASE/subdomains.txt" -silent > "$BASE/live.txt"

# ===================== URL SOURCES =================
echo "[+] Fetching URLs (gau + wayback)"
gau < "$BASE/live.txt" > "$BASE/gau.txt"
waybackurls < "$BASE/live.txt" > "$BASE/wayback.txt"

cat "$BASE/gau.txt" "$BASE/wayback.txt" | sort -u > "$BASE/history.txt"

# ===================== HAKRAWLER ==================
echo "[+] Hakrawler"
cat "$BASE/live.txt" | hakrawler -depth 2 -plain > "$BASE/hakrawler.txt"

# ===================== KATANA =====================
echo "[+] Katana (depth 10)"
katana -list "$BASE/history.txt" -depth 10 -silent > "$BASE/katana.txt"

# ===================== URL MERGE ==================
cat "$BASE/history.txt" "$BASE/hakrawler.txt" "$BASE/katana.txt" \
  | grep -ivE "\.(js|css|png|jpg|jpeg|svg|woff|woff2|pdf|ico|mp4|zip|tar|gz)$" \
  | sort -u > "$BASE/urls.txt"

echo "[+] Total URLs collected: $(wc -l < $BASE/urls.txt)"

# ===================== GREP FILTERING =============
echo "[+] Running GREP-based vulnerability filtering"

# XSS
grep -Ei "\?|&.*=" "$BASE/urls.txt" \
 | grep -Ei "(q=|search=|s=|input=|query=|keyword=)" > "$FILTER/xss.txt" || true

# SQLi
grep -Ei "(id=|uid=|user_id=|item=|pid=|product_id=)" "$BASE/urls.txt" \
 | grep -Ei "\?|&" > "$FILTER/sqli.txt" || true

# LFI
grep -Ei "(file=|path=|page=|include=|template=|view=)" "$BASE/urls.txt" > "$FILTER/lfi.txt" || true

# SSRF
grep -Ei "(url=|uri=|dest=|redirect=|next=|callback=|return=)" "$BASE/urls.txt" > "$FILTER/ssrf.txt" || true

# Open Redirect
grep -Ei "(redirect=|return=|next=|url=|continue=)" "$BASE/urls.txt" > "$FILTER/open_redirect.txt" || true

# SSTI
grep -Ei "(template=|view=|render=)" "$BASE/urls.txt" > "$FILTER/ssti.txt" || true

# RCE / Command Injection
grep -Ei "(cmd=|exec=|command=|run=|process=|ping=)" "$BASE/urls.txt" > "$FILTER/rce.txt" || true

# IDOR
grep -Ei "/[0-9]{1,6}(\?|$)" "$BASE/urls.txt" > "$FILTER/idor.txt" || true

# File Upload
grep -Ei "(upload|file|attachment)" "$BASE/urls.txt" > "$FILTER/upload.txt" || true

# Debug / Test
grep -Ei "(debug|test|dev|staging|internal)" "$BASE/urls.txt" > "$FILTER/debug.txt" || true

echo "[+] Filter results:"
ls -lh "$FILTER"

# ===================== NUCLEI =====================
echo "[+] Running Nuclei (low-hanging fruits only)"
nuclei -l "$BASE/urls.txt" \
  -tags open-redirect,misconfiguration,exposure,default-logins \
  -rl 5 -c 5 | tee "$OUT/nuclei.txt"

echo ""
echo -e "${GREEN}✔ Recon + filtering + nuclei done.${NC}"
echo -e "${CYAN}👉 Manual hunting starts from: $FILTER${NC}"
echo "Bye hunter 👋"
