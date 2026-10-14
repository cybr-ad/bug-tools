#!/usr/bin/env bash
# install_tools.sh v3 - Self-healing bug bounty toolkit installer
# Auto-troubleshoots common Kali/Debian install failures
# Usage: sudo ./install_tools.sh

set -u
export GIT_TERMINAL_PROMPT=0
export DEBIAN_FRONTEND=noninteractive
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PIP_NO_CACHE_DIR=1

# ---------- Capture script directory BEFORE any cd ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ================= COLORS =================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# ================= LOG =================
LOG_FILE="/var/log/tool_install.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/tool_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log_ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
log_warn() { echo -e "  ${YELLOW}⚠${NC} $*"; }
log_err()  { echo -e "  ${RED}✗${NC} $*"; }
log_fix()  { echo -e "  ${CYAN}🔧${NC} $*"; }
log_info() { echo -e "  ${DIM}ℹ${NC} $*"; }

# ================= ROOT CHECK =================
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Run as root: sudo $0${NC}"
    exit 1
fi

clear
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║    Self-Healing Bug Bounty Toolkit Installer v3             ║
║    Auto-detects and fixes common install failures            ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo ""
log_info "Log file: $LOG_FILE"
log_info "Started : $(date)"

# ================= VENV WARNING =================
if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    echo ""
    log_warn "Running inside virtualenv: $VIRTUAL_ENV"
    log_warn "This can break pip3 and shadow system tools."
    log_warn "Recommended: run 'deactivate' first, then rerun this script."
    log_warn "Continuing in 8 seconds (Ctrl+C to abort)..."
    sleep 8
fi
echo ""

# ================= PREFLIGHT: AUTO-FIX =================
echo -e "${MAGENTA}━━━ [0/8] Preflight checks & auto-repair ━━━${NC}"

# --- Fix 1: apt lock held by another process ---
if fuser /var/lib/dpkg/lock-frontend &>/dev/null || fuser /var/lib/apt/lists/lock &>/dev/null; then
    log_fix "APT lock held — waiting up to 60s for it to release..."
    for i in {1..60}; do
        fuser /var/lib/dpkg/lock-frontend &>/dev/null || break
        sleep 1
    done
    if fuser /var/lib/dpkg/lock-frontend &>/dev/null; then
        log_warn "Still locked — killing stale apt/unattended-upgrade processes..."
        pkill -9 -f 'unattended-upgrade' 2>/dev/null || true
        pkill -9 -f 'apt-get' 2>/dev/null || true
        rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock \
              /var/cache/apt/archives/lock 2>/dev/null || true
        dpkg --configure -a >/dev/null 2>&1 || true
    fi
fi
log_ok "APT lock check done"

# --- Fix 2: interrupted dpkg ---
if ! dpkg --audit 2>/dev/null | grep -q .; then
    log_ok "dpkg state clean"
else
    log_fix "Repairing interrupted dpkg state..."
    dpkg --configure -a >/dev/null 2>&1 || true
    apt -f install -y >/dev/null 2>&1 || true
fi

# --- Fix 3: disk space ---
AVAIL_MB=$(df / --output=avail -BM 2>/dev/null | tail -1 | tr -dc '0-9')
if [[ -z "$AVAIL_MB" ]] || [[ "$AVAIL_MB" -lt 2048 ]]; then
    log_warn "Low disk space (${AVAIL_MB:-0} MB free) — cleaning apt cache"
    apt clean >/dev/null 2>&1 || true
    apt autoremove -y >/dev/null 2>&1 || true
    log_info "Cleaned. Free now: $(df -h / | tail -1 | awk '{print $4}')"
else
    log_ok "Disk space OK (${AVAIL_MB} MB free)"
fi

# --- Fix 4: DNS resolution ---
if ! getent hosts github.com >/dev/null 2>&1; then
    log_fix "DNS failing — resetting resolv.conf to public DNS"
    cp /etc/resolv.conf /etc/resolv.conf.bak.$$ 2>/dev/null || true
    cat > /etc/resolv.conf <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 9.9.9.9
EOF
    getent hosts github.com >/dev/null 2>&1 && log_ok "DNS restored" || log_err "DNS still broken"
else
    log_ok "DNS resolution OK"
fi

# --- Fix 5: Git global config ---
git config --global --add safe.directory '*' 2>/dev/null || true
git config --global http.postBuffer 524288000 2>/dev/null || true
git config --global http.lowSpeedLimit 1000 2>/dev/null || true
git config --global http.lowSpeedTime 60 2>/dev/null || true
git config --global core.compression 0 2>/dev/null || true
log_ok "Git config tuned"

# --- Fix 6: stale Go module cache ---
if [[ -d /root/go/pkg/mod/cache/download ]]; then
    CACHE_MB=$(du -sm /root/go/pkg/mod/cache/download 2>/dev/null | cut -f1)
    if [[ "${CACHE_MB:-0}" -gt 2000 ]]; then
        log_fix "Go cache is ${CACHE_MB}MB — clearing to avoid corruption"
        go clean -modcache >/dev/null 2>&1 || true
        log_ok "Go module cache cleared"
    fi
fi

# --- Fix 7: PATH baseline ---
export GOPATH="${GOPATH:-/root/go}"
export GOBIN="$GOPATH/bin"
export PATH="/usr/local/go/bin:$GOPATH/bin:/root/.local/bin:/usr/local/bin:$PATH"
log_ok "PATH prepared"

# ================= 1. BASE DEPS =================
echo ""
echo -e "${MAGENTA}━━━ [1/8] Base dependencies ━━━${NC}"
apt update -qq 2>/dev/null || {
    log_warn "apt update failed — retrying with --fix-missing"
    apt update --fix-missing -qq 2>/dev/null || true
}

BASE_PKGS=(
    git curl wget unzip jq
    python3 python3-pip python3-venv python3-dev
    pipx
    golang-go
    ruby ruby-full ruby-dev
    nodejs npm
    build-essential pkg-config
    libpcap-dev libssl-dev libffi-dev
    ca-certificates software-properties-common
    autoconf automake libtool
    cmake gcc g++ make python3-setuptools python3-wheel
)
for pkg in "${BASE_PKGS[@]}"; do
    dpkg -s "$pkg" &>/dev/null && { log_ok "$pkg"; continue; }
    apt install -y "$pkg" >/dev/null 2>&1 && log_ok "$pkg" || log_warn "$pkg (skipped)"
done

pipx ensurepath >/dev/null 2>&1 || true

# ================= 2. GO UPGRADE CHECK =================
echo ""
echo -e "${MAGENTA}━━━ [2/8] Go toolchain check ━━━${NC}"
NEED_GO_UPGRADE=0
if ! command -v go &>/dev/null; then
    NEED_GO_UPGRADE=1
    log_warn "Go not installed"
else
    GO_VER=$(go version | awk '{print $3}' | sed 's/go//')
    GO_MAJOR=$(echo "$GO_VER" | cut -d. -f1)
    GO_MINOR=$(echo "$GO_VER" | cut -d. -f2)
    if [[ "$GO_MAJOR" -lt 1 ]] || [[ "$GO_MAJOR" -eq 1 && "$GO_MINOR" -lt 21 ]]; then
        NEED_GO_UPGRADE=1
        log_warn "Go $GO_VER too old (need ≥ 1.21) — will upgrade"
    else
        log_ok "Go $GO_VER OK"
    fi
fi

if [[ $NEED_GO_UPGRADE -eq 1 ]]; then
    log_fix "Downloading latest Go from go.dev..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  GOARCH=amd64 ;;
        aarch64) GOARCH=arm64 ;;
        *)       GOARCH=amd64 ;;
    esac
    GO_LATEST=$(curl -sL 'https://go.dev/VERSION?m=text' | head -1)
    if [[ -n "$GO_LATEST" ]]; then
        GO_TAR="${GO_LATEST}.linux-${GOARCH}.tar.gz"
        log_info "Fetching $GO_TAR"
        if curl -sL --retry 3 -o "/tmp/$GO_TAR" "https://go.dev/dl/$GO_TAR"; then
            rm -rf /usr/local/go
            tar -C /usr/local -xzf "/tmp/$GO_TAR" && log_ok "Go upgraded to $GO_LATEST" || log_err "Go extract failed"
            rm -f "/tmp/$GO_TAR"
            export PATH="/usr/local/go/bin:$PATH"
        else
            log_err "Go download failed — using apt version"
        fi
    fi
fi

# Persist Go env to shells
for rc in /root/.bashrc /root/.profile /etc/profile.d/golang.sh; do
    [[ "$rc" == /etc/profile.d/* ]] && mkdir -p "$(dirname "$rc")"
    {
        grep -q 'export GOPATH=' "$rc" 2>/dev/null || echo 'export GOPATH=/root/go'
        grep -q 'export GOBIN=' "$rc" 2>/dev/null || echo 'export GOBIN=/root/go/bin'
        grep -q 'GOPATH/bin' "$rc" 2>/dev/null || echo 'export PATH=$PATH:/usr/local/go/bin:/root/go/bin:/root/.local/bin'
    } >> "$rc" 2>/dev/null || true
done
chmod +x /etc/profile.d/golang.sh 2>/dev/null || true

# ================= 3. APT SECURITY TOOLS =================
echo ""
echo -e "${MAGENTA}━━━ [3/8] APT security tools ━━━${NC}"
APT_PKGS=(
    sqlmap gobuster ffuf wfuzz nikto wafw00f
    massdns amass sublist3r wpscan dirb
    seclists awscli dnsutils whois
    impacket-scripts nmap dnsrecon fierce whatweb
    theharvester
)

APT_FAILED=()
for pkg in "${APT_PKGS[@]}"; do
    dpkg -s "$pkg" &>/dev/null && { log_ok "$pkg"; continue; }
    if apt install -y "$pkg" >/dev/null 2>&1; then
        log_ok "$pkg"
    else
        log_warn "$pkg (not in repo — will try alternative)"
        APT_FAILED+=("$pkg")
    fi
done

# Auto-fix: renamed packages
if [[ " ${APT_FAILED[*]} " =~ " impacket-scripts " ]]; then
    log_fix "impacket-scripts unavailable — trying python3-impacket"
    apt install -y python3-impacket >/dev/null 2>&1 && log_ok "python3-impacket" || true
fi

# ================= 4. GO TOOLS =================
echo ""
echo -e "${MAGENTA}━━━ [4/8] Go tools ━━━${NC}"

GO_TOOLS=(
    # --- ProjectDiscovery suite ---
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

    # --- DNS / subdomain ---
    "github.com/d3mondev/puredns/v2@latest|puredns"

    # --- Web fuzzing / content discovery ---
    "github.com/OJ/gobuster/v3@latest|gobuster"
    "github.com/ffuf/ffuf/v2@latest|ffuf"
    "github.com/feroxbuster/feroxbuster@latest|feroxbuster"

    # --- Recon / OSINT ---
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

    # --- Permutation / vhost ---
    "github.com/infosec-au/altdns@latest|altdns"
    "github.com/hakluke/hakcheckurl@latest|hakcheckurl"

    # --- Subdomain takeover ---
    "github.com/LukaSikic/subzy@latest|subzy"
)

install_go_tool() {
    local mod="$1" bin="$2"
    command -v "$bin" &>/dev/null && { log_ok "$bin"; return 0; }
    log_info "installing $bin ..."

    if go install "$mod" >/tmp/go_install_$$.log 2>&1; then
        log_ok "$bin"; return 0
    fi

    log_fix "$bin failed — retrying with CGO_ENABLED=1 + -mod=mod"
    if CGO_ENABLED=1 GOFLAGS=-mod=mod go install "$mod" >>/tmp/go_install_$$.log 2>&1; then
        log_ok "$bin (retry)"; return 0
    fi

    log_fix "$bin failed again — clearing module cache"
    go clean -modcache >/dev/null 2>&1 || true
    if go install "$mod" >>/tmp/go_install_$$.log 2>&1; then
        log_ok "$bin (after cache clear)"; return 0
    fi

    log_err "$bin (all retries failed — see /tmp/go_install_$$.log)"
    return 1
}

GO_FAILED=()
for entry in "${GO_TOOLS[@]}"; do
    mod="${entry%%|*}"; bin="${entry##*|}"
    install_go_tool "$mod" "$bin" || GO_FAILED+=("$bin")
done

# ================= 5. PYTHON TOOLS =================
echo ""
echo -e "${MAGENTA}━━━ [5/8] Python tools ━━━${NC}"

PEP668=$(python3 -c 'import sysconfig; print(sysconfig.get_path("stdlib"))' 2>/dev/null)/EXTERNALLY-MANAGED
[[ -f "$PEP668" ]] && { log_fix "PEP 668 detected — removing EXTERNALLY-MANAGED marker"; rm -f "$PEP668"; }

# Only tools that ARE on PyPI. theHarvester handled via apt; corsy/paramspider/ssrfmap/tplmap via git.
PY_TOOLS=(
    jsleak
    arjun
    droopescan
    wafw00f
    dirsearch
    waymore
    xsstrike
    commix
    git-dumper
    shodan
)

install_py_tool() {
    local tool="$1"
    pipx list 2>/dev/null | grep -q "package $tool " && { log_ok "$tool"; return 0; }
    log_info "installing $tool ..."

    if pipx install --pip-args="--no-cache-dir" "$tool" >/tmp/pipx_$$.log 2>&1; then
        log_ok "$tool"; return 0
    fi

    log_fix "$tool pipx failed — trying pip3 --break-system-packages"
    if pip3 install --break-system-packages -q "$tool" >/tmp/pip_$$.log 2>&1; then
        log_ok "$tool (pip3)"; return 0
    fi

    if command -v python3.11 &>/dev/null; then
        log_fix "$tool retrying pipx with python3.11"
        if pipx install --python python3.11 "$tool" >>/tmp/pipx_$$.log 2>&1; then
            log_ok "$tool (py3.11)"; return 0
        fi
    fi

    log_warn "$tool (all attempts failed)"
    return 1
}

PY_FAILED=()
for tool in "${PY_TOOLS[@]}"; do
    install_py_tool "$tool" || PY_FAILED+=("$tool")
done

pip3 install --break-system-packages -q \
    requests urllib3 beautifulsoup4 lxml dnspython \
    pyOpenSSL colorama termcolor tqdm \
    2>/dev/null && log_ok "python libs (requests, bs4, dnspython, …)" \
    || log_warn "some python libs failed"

# ================= 6. GITHUB CLONES =================
echo ""
echo -e "${MAGENTA}━━━ [6/8] GitHub repositories ━━━${NC}"

TOOLS_DIR=/opt/tools
mkdir -p "$TOOLS_DIR"
cd "$TOOLS_DIR" || exit 1

clone_repo() {
    local url="$1" name="${2:-$(basename "$url" .git)}"
    if [[ -d "$name/.git" ]]; then
        log_ok "$name (already cloned)"
        git -C "$name" pull --ff-only --quiet 2>/dev/null || true
        return 0
    fi

    log_info "cloning $name ..."
    if git clone --depth 1 --quiet "$url" "$name" 2>/tmp/git_$$.log; then
        log_ok "$name"; return 0
    fi

    log_fix "$name shallow failed — trying full clone"
    if git clone --quiet "$url" "$name" 2>>/tmp/git_$$.log; then
        log_ok "$name (full)"; return 0
    fi

    local repo_path="$(echo "$url" | sed -E 's|https://github.com/([^/]+)/([^/]+)\.git|\1/\2|')"
    local new_url
    new_url=$(curl -sL -o /dev/null -w '%{url_effective}' "https://github.com/$repo_path" 2>/dev/null)
    if [[ -n "$new_url" ]] && [[ "$new_url" != "https://github.com/$repo_path" ]] && [[ "$new_url" != *"404"* ]]; then
        log_fix "$name renamed → $new_url"
        if git clone --depth 1 --quiet "${new_url%.git}.git" "$name" 2>/dev/null; then
            log_ok "$name (renamed source)"; return 0
        fi
    fi

    log_warn "$name (clone failed — repo may be deleted/private)"
    rm -rf "$name" 2>/dev/null || true
    return 1
}

CLONE_TARGETS=(
    # --- Web / CMS ---
    "https://github.com/s0md3v/Corsy.git|corsy"
    "https://github.com/Tuhinshubhra/CMSeeK.git|CMSeeK"
    "https://github.com/droope/droopescan.git|droopescan"
    "https://github.com/rezasp/joomscan.git|joomscan"
    "https://github.com/0ang3el/aem-hacker.git|aem-hacker"
    "https://github.com/stevenvachon/broken-link-checker.git|broken-link-checker"

    # --- Cloud / S3 ---
    "https://github.com/gwen001/s3-buckets-finder.git|s3-buckets-finder"
    "https://github.com/chenjj/CORScanner.git|CORScanner"
    "https://github.com/greycatz/CloudUnflare.git|CloudUnflare"
    "https://github.com/securing/DumpsterDiver.git|dumpsterdiver"

    # --- Recon ---
    "https://github.com/cihanmehmet/sub.sh.git|sub.sh"
    "https://github.com/projectdiscovery/nuclei-templates.git|nuclei-templates"

    # --- Python tools that ONLY exist as git repos ---
    "https://github.com/devanshbatham/ParamSpider.git|ParamSpider"
    "https://github.com/swisskyrepo/SSRFmap.git|SSRFmap"
    "https://github.com/epinna/tplmap.git|tplmap"

    # --- Wordlists ---
    "https://github.com/danielmiessler/SecLists.git|SecLists"
    "https://github.com/swisskyrepo/PayloadsAllTheThings.git|PayloadsAllTheThings"
    "https://github.com/1N3/IntruderPayloads.git|IntruderPayloads"
    "https://github.com/fuzzdb-project/fuzzdb.git|fuzzdb"
    "https://github.com/assetnote/commonspeak2-wordlists.git|commonspeak2-wordlists"
)

for entry in "${CLONE_TARGETS[@]}"; do
    url="${entry%%|*}"; name="${entry##*|}"
    clone_repo "$url" "$name" || true
done

# --- Create wrapper commands for cloned Python tools ---
declare -A PY_CANDIDATES=(
    [corsy]="corsy.py"
    [ParamSpider]="paramspider/__main__.py paramspider/main.py paramspider.py"
    [SSRFmap]="ssrfmap.py"
    [tplmap]="tplmap.py"
)

for dir_name in "${!PY_CANDIDATES[@]}"; do
    found=""
    for cand in ${PY_CANDIDATES[$dir_name]}; do
        if [[ -f "$TOOLS_DIR/$dir_name/$cand" ]]; then
            found="$TOOLS_DIR/$dir_name/$cand"
            break
        fi
    done

    if [[ -n "$found" ]]; then
        chmod +x "$found" 2>/dev/null || true
        cmd=$(echo "$dir_name" | tr '[:upper:]' '[:lower:]')

        # If inside a real Python package (has __init__.py), run as module
        pkg_dir="$(dirname "$found")"
        if [[ -f "$pkg_dir/__init__.py" ]]; then
            parent_dir="$(dirname "$pkg_dir")"
            pkg_name="$(basename "$pkg_dir")"
            cat > "/usr/local/bin/$cmd" <<EOF
#!/bin/bash
cd "$parent_dir" && exec python3 -m $pkg_name "\$@"
EOF
        else
            cat > "/usr/local/bin/$cmd" <<EOF
#!/bin/bash
exec python3 "$found" "\$@"
EOF
        fi
        chmod +x "/usr/local/bin/$cmd"
        log_ok "$cmd → wrapper → $found"
    else
        log_warn "$dir_name — no entry script found (skipped wrapper)"
    fi
done

chmod -R a+rX "$TOOLS_DIR" 2>/dev/null || true

# ================= 7. API KEY DISTRIBUTION =================
if [[ -f "$SCRIPT_DIR/api_setup.sh" ]]; then
    source "$SCRIPT_DIR/api_setup.sh" "$SCRIPT_DIR/api_keys.txt"
else
    echo ""
    echo -e "${MAGENTA}━━━ [7/8] API key distribution ━━━${NC}"
    log_warn "api_setup.sh not found in $SCRIPT_DIR — skipping API configuration"
fi

# ================= 8. POST-INSTALL =================
echo ""
echo -e "${MAGENTA}━━━ [8/8] Post-install fixes ━━━${NC}"

install_requirements_smart() {
    local req_file="$1" tool="$2"
    local total=0 ok=0

    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^- ]] && continue
        [[ "$line" =~ ^git\+ ]] && continue
        [[ "$line" =~ ^https?:// ]] && continue

        total=$((total+1))
        if pip3 install --break-system-packages -q "$line" >/dev/null 2>&1; then
            ok=$((ok+1))
        fi
    done < "$req_file"

    if [[ $total -eq 0 ]]; then
        return
    elif [[ $ok -eq $total ]]; then
        log_ok "$tool requirements ($ok/$total)"
    elif [[ $ok -gt 0 ]]; then
        log_warn "$tool requirements ($ok/$total, $((total-ok)) unsupported)"
    else
        log_warn "$tool requirements (unsupported — tool still works)"
    fi
}

for dir in "$TOOLS_DIR"/*/; do
    [[ -f "$dir/requirements.txt" ]] || continue
    install_requirements_smart "$dir/requirements.txt" "$(basename "$dir")"
done

# Nuclei templates
if command -v nuclei &>/dev/null; then
    if nuclei -update-templates -silent >/dev/null 2>&1; then
        log_ok "nuclei templates updated"
    else
        log_fix "nuclei update failed — retrying with -duc"
        nuclei -update-templates -duc -silent >/dev/null 2>&1 && log_ok "nuclei templates (retry)" || log_warn "nuclei templates (failed)"
    fi
fi

# Massdns resolvers
RESOLVERS=/etc/massdns/resolvers.txt
mkdir -p /etc/massdns
if [[ ! -s "$RESOLVERS" ]]; then
    for url in \
        "https://raw.githubusercontent.com/blechschmidt/massdns/master/lists/resolvers.txt" \
        "https://public-dns.info/nameservers.txt" \
        "https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt"; do
        if curl -sL --retry 2 --max-time 30 "$url" -o "$RESOLVERS" 2>/dev/null && [[ -s "$RESOLVERS" ]]; then
            log_ok "massdns resolvers ($(wc -l < "$RESOLVERS") entries)"
            break
        fi
    done
fi
[[ -s "$RESOLVERS" ]] || log_warn "massdns resolvers (not fetched)"
chmod 644 "$RESOLVERS" 2>/dev/null || true

# Wordlist symlinks
for L in /usr/share/wordlists/seclists /opt/SecLists; do
    if [[ ! -e "$L" ]] && [[ -d "$TOOLS_DIR/SecLists" ]]; then
        ln -sfn "$TOOLS_DIR/SecLists" "$L" 2>/dev/null && log_ok "seclists symlink → $L"
    fi
done

# ================= FINAL VERIFICATION =================
echo ""
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  ✅  INSTALLATION COMPLETE${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

CRITICAL=(gobuster ffuf nikto sqlmap nmap httpx katana nuclei subfinder naabu)
MISSING=()
echo -e "${CYAN}Critical tool check:${NC}"
for bin in "${CRITICAL[@]}"; do
    if command -v "$bin" &>/dev/null; then
        printf "  %-18s ${GREEN}✓${NC}  %s\n" "$bin" "$(command -v "$bin")"
    else
        printf "  %-18s ${RED}✗${NC}  missing\n" "$bin"
        MISSING+=("$bin")
    fi
done

echo ""
echo -e "${CYAN}Optional tool check:${NC}"
OPTIONAL=(puredns shuffledns alterx dnsx jsleak arjun subzy feroxbuster dalfox gau hakrawler corsy paramspider ssrfmap tplmap theHarvester)
for bin in "${OPTIONAL[@]}"; do
    if command -v "$bin" &>/dev/null; then
        printf "  %-18s ${GREEN}✓${NC}\n" "$bin"
    else
        printf "  %-18s ${YELLOW}–${NC} (optional)\n" "$bin"
    fi
done

echo ""
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
REPOS_OK=$(find "$TOOLS_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)
echo -e "  Go binaries    : $GOPATH/bin"
echo -e "  GitHub repos   : $TOOLS_DIR  ($REPOS_OK folders)"
echo -e "  Wordlists      : /usr/share/seclists  +  $TOOLS_DIR/SecLists"
echo -e "  Log file       : $LOG_FILE"
echo ""

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo -e "${YELLOW}${BOLD}  Missing critical tools:${NC}"
    for m in "${MISSING[@]}"; do echo "    - $m"; done
    echo ""
    echo -e "${CYAN}  Auto-fix suggestions:${NC}"
    for m in "${MISSING[@]}"; do
        case "$m" in
            gobuster|ffuf|nikto|sqlmap|nmap)
                echo "    • apt install -y $m"
                ;;
            httpx|katana|nuclei|subfinder|naabu)
                echo "    • CGO_ENABLED=1 go install github.com/projectdiscovery/${m}/cmd/${m}@latest"
                ;;
        esac
    done
    echo ""
    echo -e "${YELLOW}  [i] Run the installer again after fixing — it will skip what's already installed.${NC}"
fi

echo ""
echo -e "${GREEN}  Finished at: $(date)${NC}"
echo -e "${CYAN}  →  Open a NEW terminal (or run: source ~/.bashrc) to load new PATH.${NC}"
echo ""

# ================= POST-SCRIPT: env hint =================
{
    echo "#!/bin/bash"
    echo "# Auto-generated by install_tools.sh — PATH for bug bounty tools"
    echo 'export GOPATH=/root/go'
    echo 'export GOBIN=/root/go/bin'
    echo 'export PATH=$PATH:/usr/local/go/bin:/root/go/bin:/root/.local/bin'
    echo '# Massdns resolver'
    echo 'export MASSDNS_RESOLVERS=/etc/massdns/resolvers.txt'
} > /etc/profile.d/bugbounty.sh
chmod +x /etc/profile.d/bugbounty.sh