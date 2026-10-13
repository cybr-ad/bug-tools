#!/usr/bin/env bash
# install_tools.sh - Complete Bug Bounty Toolkit Installer
# Kali Linux / Debian-based
# Usage: sudo ./install_tools.sh
# Safe to re-run: skips already-installed tools

set -u
export GIT_TERMINAL_PROMPT=0
git config --global --add safe.directory '*' 2>/dev/null || true

# ================= COLORS =================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'

# ================= ROOT CHECK =================
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Run as root: sudo $0${NC}"
    exit 1
fi

# ================= LOG =================
LOG_FILE="/var/log/tool_install.log"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

clear
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║    Complete Bug Bounty Toolkit Installer                     ║
║    APT + Go + Python + GitHub repos                          ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo ""
echo -e "${CYAN}[i] Logging to: $LOG_FILE${NC}"
echo -e "${CYAN}[i] Started: $(date)${NC}"
echo ""

# ================= ENV =================
export GOPATH="${GOPATH:-/root/go}"
export PATH="$PATH:$GOPATH/bin:/usr/local/go/bin:$HOME/.local/bin:/root/.local/bin"
export GO111MODULE=on
export GOBIN="$GOPATH/bin"

# Make env persistent
for rc in /root/.bashrc /root/.profile; do
    grep -q 'export GOPATH=' "$rc" 2>/dev/null || echo 'export GOPATH=/root/go' >> "$rc"
    grep -q 'GOPATH/bin' "$rc" 2>/dev/null || echo 'export PATH=$PATH:/root/go/bin:/usr/local/go/bin:/root/.local/bin' >> "$rc"
done

# ================= 1. APT UPDATE + DEPS =================
echo -e "${MAGENTA}━━━ [1/6] Base dependencies ━━━${NC}"
apt update -qq
apt install -y \
    git curl wget unzip jq \
    python3 python3-pip python3-venv python3-dev \
    pipx \
    golang-go \
    ruby ruby-dev \
    nodejs npm \
    build-essential libpcap-dev libssl-dev libffi-dev \
    pkg-config ca-certificates \
    2>/dev/null || true

# Ensure pipx path
pipx ensurepath >/dev/null 2>&1 || true

# ================= 2. APT SECURITY TOOLS =================
echo ""
echo -e "${MAGENTA}━━━ [2/6] APT security tools ━━━${NC}"
APT_PKGS=(
    sqlmap gobuster ffuf wfuzz nikto wafw00f
    massdns amass sublist3r wpscan dirb
    seclists awscli dnsutils whois
    impacket-scripts
    nmap dnsrecon fierce
    whatweb
)

for pkg in "${APT_PKGS[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $pkg (already installed)"
    else
        if apt install -y "$pkg" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $pkg"
        else
            echo -e "  ${YELLOW}⚠${NC} $pkg (not in repo, skipped)"
        fi
    fi
done

# ================= 3. GO TOOLS =================
echo ""
echo -e "${MAGENTA}━━━ [3/6] Go tools (ProjectDiscovery + others) ━━━${NC}"

# Sanity check Go
if ! command -v go &>/dev/null; then
    echo -e "  ${RED}✗${NC} Go not found — skipping Go tools"
else
    GO_TOOLS=(
        # ProjectDiscovery suite
        "github.com/projectdiscovery/katana/cmd/katana@latest|katana"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest|httpx"
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest|naabu"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest|nuclei"
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest|subfinder"
        "github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest|shuffledns"
        "github.com/projectdiscovery/alterx/cmd/alterx@latest|alterx"
        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest|dnsx"
        "github.com/projectdiscovery/notify/cmd/notify@latest|notify"
        "github.com/projectdiscovery/chaos-client/cmd/chaos@latest|chaos"
        "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest|interactsh-client"

        # DNS / subdomain
        "github.com/d3mondev/puredns/v2@latest|puredns"

        # Web fuzzing / content discovery
        "github.com/OJ/gobuster/v3@latest|gobuster"
        "github.com/ffuf/ffuf/v2@latest|ffuf"
        "github.com/feroxbuster/feroxbuster@latest|feroxbuster"

        # Recon / OSINT
        "github.com/j3ssie/metabigor@latest|metabigor"
        "github.com/tomnomnom/assetfinder@latest|assetfinder"
        "github.com/tomnomnom/waybackurls@latest|waybackurls"
        "github.com/tomnomnom/gf@latest|gf"
        "github.com/tomnomnom/anew@latest|anew"
        "github.com/tomnomnom/qsreplace@latest|qsreplace"
        "github.com/tomnomnom/httprobe@latest|httprobe"
        "github.com/lc/gau/v2/cmd/gau@latest|gau"
        "github.com/hakluke/hakrawler@latest|hakrawler"
        "github.com/jaeles-project/gospider@latest|gospider"
        "github.com/003random/getJS@latest|getJS"
        "github.com/KathanP19/Gxss@latest|Gxss"
        "github.com/Emoe/kxss@latest|kxss"
        "github.com/hahwul/dalfox/v2@latest|dalfox"

        # Permutation / vhost
        "github.com/infosec-au/altdns@latest|altdns"
        "github.com/hakluke/hakcheckurl@latest|hakcheckurl"
    )

    for entry in "${GO_TOOLS[@]}"; do
        mod="${entry%%|*}"
        bin="${entry##*|}"
        if command -v "$bin" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $bin (already installed)"
            continue
        fi
        echo -e "  ${CYAN}↓${NC} installing $bin ..."
        if go install "$mod" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $bin"
        else
            echo -e "  ${YELLOW}⚠${NC} $bin (go install failed — check network / Go version)"
        fi
    done
fi

# ================= 4. PYTHON TOOLS =================
echo ""
echo -e "${MAGENTA}━━━ [4/6] Python tools (pipx) ━━━${NC}"

PY_TOOLS=(
    # From your workflow
    "jsleak"
    "arjun"
    "subzy"
    "droopescan"
    "wafw00f"

    # General-purpose
    "corsy"
    "dirsearch"
    "paramspider"
    "waymore"
    "xsstrike"
    "ssrfmap"
    "commix"
    "tplmap"
    "git-dumper"
    "shodan"
    "theHarvester"
)

for tool in "${PY_TOOLS[@]}"; do
    if pipx list 2>/dev/null | grep -q "package $tool "; then
        echo -e "  ${GREEN}✓${NC} $tool (already installed)"
        continue
    fi
    echo -e "  ${CYAN}↓${NC} installing $tool ..."
    if pipx install "$tool" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $tool"
    else
        # Fallback to pip
        if pip3 install --break-system-packages -q "$tool" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool (via pip3)"
        else
            echo -e "  ${YELLOW}⚠${NC} $tool (install failed)"
        fi
    fi
done

# Extra Python packages (used by CMSeeK, etc.)
pip3 install --break-system-packages -q \
    requests urllib3 beautifulsoup4 lxml dnspython \
    pyOpenSSL colorama termcolor tqdm \
    2>/dev/null || true

# ================= 5. GITHUB CLONES =================
echo ""
echo -e "${MAGENTA}━━━ [5/6] GitHub repositories ━━━${NC}"

TOOLS_DIR=/opt/tools
mkdir -p "$TOOLS_DIR"
cd "$TOOLS_DIR" || exit 1

clone_repo() {
    local url="$1"
    local name="${2:-$(basename "$url" .git)}"
    if [[ -d "$name/.git" ]]; then
        echo -e "  ${GREEN}✓${NC} $name (already cloned)"
        git -C "$name" pull --ff-only --quiet 2>/dev/null || true
        return
    fi
    echo -e "  ${CYAN}↓${NC} cloning $name ..."
    if git clone --depth 1 --quiet "$url" "$name" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $name"
    else
        echo -e "  ${YELLOW}⚠${NC} $name (clone failed — repo may be renamed/deleted)"
        rm -rf "$name" 2>/dev/null || true
    fi
}

# --- Web / CMS tools ---
clone_repo https://github.com/s0md3v/Corsy.git corsy
clone_repo https://github.com/Tuhinshubhra/CMSeeK.git CMSeeK
clone_repo https://github.com/droope/droopescan.git droopescan
clone_repo https://github.com/rezasp/joomscan.git joomscan
clone_repo https://github.com/gwen001/github-search.git github-search
clone_repo https://github.com/yassineaboukir/Asnlookup.git asnlookup
clone_repo https://github.com/0ang3el/aem-hacker.git aem-hacker
clone_repo https://github.com/stevenvachon/broken-link-checker.git broken-link-checker

# --- Cloud / S3 / CORS ---
clone_repo https://github.com/gwen001/s3-buckets-finder.git s3-buckets-finder
clone_repo https://github.com/chenjj/CORScanner.git CORScanner
clone_repo https://github.com/greycatz/CloudUnflare.git CloudUnflare
clone_repo https://github.com/securing/DumpsterDiver.git dumpsterdiver

# --- Subdomain / recon ---
clone_repo https://github.com/cihanmehmet/sub.sh.git sub.sh
clone_repo https://github.com/aboul3la/Sublist3r.git Sublist3r
clone_repo https://github.com/projectdiscovery/nuclei-templates.git nuclei-templates

# --- Wordlists & payloads ---
clone_repo https://github.com/danielmiessler/SecLists.git SecLists
clone_repo https://github.com/swisskyrepo/PayloadsAllTheThings.git PayloadsAllTheThings
clone_repo https://github.com/1N3/IntruderPayloads.git IntruderPayloads
clone_repo https://github.com/fuzzdb-project/fuzzdb.git fuzzdb
clone_repo https://github.com/assetnote/commonspeak2-wordlists.git commonspeak2-wordlists

# --- Fix permissions ---
chmod -R a+rX "$TOOLS_DIR" 2>/dev/null || true

# ================= 6. POST-INSTALL =================
echo ""
echo -e "${MAGENTA}━━━ [6/6] Post-install configuration ━━━${NC}"

# Install Python requirements for cloned tools
for dir in "$TOOLS_DIR"/*/; do
    if [[ -f "$dir/requirements.txt" ]]; then
        tool=$(basename "$dir")
        echo -e "  ${CYAN}↓${NC} $tool requirements ..."
        pip3 install --break-system-packages -q -r "$dir/requirements.txt" 2>/dev/null \
            && echo -e "  ${GREEN}✓${NC} $tool requirements" \
            || echo -e "  ${YELLOW}⚠${NC} $tool requirements (partial)"
    fi
done

# Update nuclei templates
if command -v nuclei &>/dev/null; then
    echo -e "  ${CYAN}↓${NC} updating nuclei templates ..."
    nuclei -update-templates -silent >/dev/null 2>&1 \
        && echo -e "  ${GREEN}✓${NC} nuclei templates" \
        || echo -e "  ${YELLOW}⚠${NC} nuclei templates (update failed)"
fi

# Massdns resolver list (public resolvers)
RESOLVERS=/etc/massdns/resolvers.txt
mkdir -p /etc/massdns 2>/dev/null || true
if [[ ! -f "$RESOLVERS" ]]; then
    curl -sL https://raw.githubusercontent.com/blechschmidt/massdns/master/lists/resolvers.txt \
        -o "$RESOLVERS" 2>/dev/null && echo -e "  ${GREEN}✓${NC} massdns resolvers" \
        || echo -e "  ${YELLOW}⚠${NC} massdns resolvers (download failed)"
fi

# ================= SUMMARY =================
echo ""
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  ✅ INSTALLATION COMPLETE${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Count installed tools
APT_OK=0; GO_OK=0; PY_OK=0; REPOS_OK=0
for pkg in "${APT_PKGS[@]}"; do dpkg -s "$pkg" &>/dev/null && APT_OK=$((APT_OK+1)); done
for entry in "${GO_TOOLS[@]:-}"; do bin="${entry##*|}"; command -v "$bin" &>/dev/null && GO_OK=$((GO_OK+1)); done
for tool in "${PY_TOOLS[@]}"; do pipx list 2>/dev/null | grep -q "package $tool " && PY_OK=$((PY_OK+1)); done
REPOS_OK=$(find "$TOOLS_DIR" -maxdepth 1 -type d -name '.git' 2>/dev/null | wc -l)
REPOS_OK=$(find "$TOOLS_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)

printf "  %-20s %s\n" "APT packages:"   "$APT_OK / ${#APT_PKGS[@]}"
printf "  %-20s %s\n" "Go tools:"        "$GO_OK / ${#GO_TOOLS[@]:-0}"
printf "  %-20s %s\n" "Python tools:"    "$PY_OK / ${#PY_TOOLS[@]}"
printf "  %-20s %s\n" "GitHub repos:"    "$REPOS_OK"
echo ""
echo -e "  ${CYAN}Go binaries:${NC}     $GOPATH/bin"
echo -e "  ${CYAN}GitHub repos:${NC}    $TOOLS_DIR"
echo -e "  ${CYAN}Wordlists:${NC}       /usr/share/seclists  +  $TOOLS_DIR/SecLists"
echo -e "  ${CYAN}Log file:${NC}        $LOG_FILE"
echo ""
echo -e "  ${YELLOW}[i] Open a new terminal (or run: source ~/.bashrc)${NC}"
echo -e "  ${YELLOW}[i] to pick up the updated PATH.${NC}"
echo ""
echo -e "  ${GREEN}Finished at: $(date)${NC}"
echo ""