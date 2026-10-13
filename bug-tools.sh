#!/usr/bin/env bash
# install_tools.sh
# Kali Linux tool installer - robust version
# Usage: sudo ./install_tools.sh

set -u

# --- Prevent Git from ever prompting for credentials ---
export GIT_TERMINAL_PROMPT=0
git config --global --add safe.directory '*' 2>/dev/null || true

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

LOG_FILE="/var/log/tool_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[+] Installation started at $(date)"
echo "[+] Logging to $LOG_FILE"

# --- Update apt ---
echo "[+] Updating apt..."
apt update -qq

# --- Base dependencies ---
echo "[+] Installing base dependencies..."
apt install -y git curl wget unzip jq python3 python3-pip python3-venv \
  pipx golang-go ruby ruby-dev nodejs npm build-essential libpcap-dev \
  libssl-dev libffi-dev python3-dev 2>/dev/null || true

# --- APT packages ---
echo "[+] Installing APT packages..."
APT_PKGS=(
  sqlmap gobuster ffuf wfuzz nikto wafw00f massdns amass sublist3r
  wpscan dirb seclists awscli dnsutils whois impacket-scripts
)

for pkg in "${APT_PKGS[@]}"; do
  if dpkg -s "$pkg" &>/dev/null; then
    echo "[*] $pkg already installed"
  else
    apt install -y "$pkg" 2>/dev/null && echo "[+] Installed $pkg" || echo "[-] Skipped $pkg (not in repo)"
  fi
done

# --- Go tools ---
echo "[+] Installing Go-based tools..."
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin:/usr/local/go/bin"

if command -v go &>/dev/null; then
  go install github.com/OJ/gobuster/v3@latest 2>/dev/null && echo "[+] gobuster (go)" || echo "[-] gobuster go install failed"
  go install github.com/ffuf/ffuf/v2@latest 2>/dev/null && echo "[+] ffuf (go)" || echo "[-] ffuf go install failed"
  go install github.com/j3ssie/metabigor@latest 2>/dev/null && echo "[+] metabigor" || echo "[-] metabigor go install failed"
else
  echo "[-] Go not found, skipping Go-based tools"
fi

# --- Python tools via pipx ---
echo "[+] Installing Python tools via pipx..."
pipx install wfuzz 2>/dev/null && echo "[+] wfuzz (pipx)" || echo "[-] wfuzz pipx skipped"
pipx install droopescan 2>/dev/null && echo "[+] droopescan (pipx)" || echo "[-] droopescan pipx skipped"

# --- GitHub clones ---
TOOLS_DIR=/opt/tools
mkdir -p "$TOOLS_DIR"
cd "$TOOLS_DIR" || exit 1

clone_repo() {
  local url="$1"
  local name="${2:-$(basename "$url" .git)}"
  if [[ -d "$name/.git" ]]; then
    echo "[*] Updating $name"
    git -C "$name" pull --ff-only --quiet 2>/dev/null || true
  else
    echo "[+] Cloning $name from $url"
    if git clone --depth 1 --quiet "$url" "$name" 2>/dev/null; then
      echo "[+] Cloned $name"
    else
      echo "[-] Failed to clone $url (may be renamed, archived, or deleted)"
      rm -rf "$name" 2>/dev/null || true
    fi
  fi
}

echo "[+] Cloning GitHub tools and wordlists..."

# Web / CMS / recon tools
clone_repo https://github.com/s0md3v/Corsy.git corsy
clone_repo https://github.com/Tuhinshubhra/CMSeeK.git CMSeeK
clone_repo https://github.com/droope/droopescan.git droopescan
clone_repo https://github.com/rezasp/joomscan.git joomscan
clone_repo https://github.com/gwen001/github-search.git github-search
clone_repo https://github.com/yassineaboukir/Asnlookup.git asnlookup
clone_repo https://github.com/0ang3el/aem-hacker.git aem-hacker
clone_repo https://github.com/stevenvachon/broken-link-checker.git broken-link-checker

# Cloud / S3 / CORS
clone_repo https://github.com/gwen001/s3-buckets-finder.git s3-buckets-finder
clone_repo https://github.com/chenjj/CORScanner.git CORS-Scanner
clone_repo https://github.com/greycatz/CloudUnflare.git CloudUnflare
clone_repo https://github.com/securing/DumpsterDiver.git dumpsterdiver

# Subdomain / recon scripts
clone_repo https://github.com/cihanmehmet/sub.sh.git sub.sh
clone_repo https://github.com/aboul3la/Sublist3r.git Sublist3r

# Wordlists and payload collections
clone_repo https://github.com/danielmiessler/SecLists.git SecLists
clone_repo https://github.com/swisskyrepo/PayloadsAllTheThings.git PayloadsAllTheThings
clone_repo https://github.com/1N3/IntruderPayloads.git IntruderPayloads
clone_repo https://github.com/fuzzdb-project/fuzzdb.git fuzzdb
clone_repo https://github.com/assetnote/commonspeak2-wordlists.git commonspeak2-wordlists

# --- Fix permissions ---
echo "[+] Setting permissions..."
chmod -R a+rX "$TOOLS_DIR" 2>/dev/null || true

# --- Post-install: Python requirements ---
echo "[+] Installing Python requirements for cloned tools..."
for dir in "$TOOLS_DIR"/*/; do
  if [[ -f "$dir/requirements.txt" ]]; then
    echo "[*] Installing requirements for $(basename "$dir")"
    pip3 install --break-system-packages -q -r "$dir/requirements.txt" 2>/dev/null || \
      echo "[-] Some requirements failed for $(basename "$dir")"
  fi
done

# --- Summary ---
echo ""
echo "=============================================="
echo " Installation Summary"
echo "=============================================="
echo " APT packages:  ${#APT_PKGS[@]} attempted"
echo " GitHub clones: $(find "$TOOLS_DIR" -maxdepth 1 -type d | wc -l) directories in $TOOLS_DIR"
echo " Log file:      $LOG_FILE"
echo ""
echo " Tools installed in: $TOOLS_DIR"
echo " Go binaries in:     $GOPATH/bin"
echo "=============================================="
echo "[+] Installation finished at $(date)"