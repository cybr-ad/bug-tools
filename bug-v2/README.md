# 🎯 Bug Bounty Toolkit

> A self-healing, automated installer for a complete bug bounty & offensive security toolkit on Kali Linux.
> One script installs 70+ tools, distributes your API keys to every tool's native config, and gets you scanning in minutes.

![Kali Linux](https://img.shields.io/badge/Kali-Linux-557C94?logo=kalilinux&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Platform](https://img.shields.io/badge/Platform-Debian%20%7C%20Kali-red)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Repository Structure](#-repository-structure)
- [Tools Included](#-tools-included)
- [API Keys Setup](#-api-keys-setup)
- [Usage](#-usage)
- [Troubleshooting](#-troubleshooting)
- [Uninstall](#-uninstall)
- [Contributing](#-contributing)
- [Legal Disclaimer](#%EF%B8%8F-legal-disclaimer)
- [License](#-license)

---

## 🎯 Overview

This repository automates the tedious setup of a professional bug bounty environment. Instead of installing 70+ tools by hand, copying configs, and hunting down API key paths for each tool, you run **one script** and it handles everything:

- ✅ **APT packages** — sqlmap, nmap, nikto, gobuster, ffuf, theHarvester, and more
- ✅ **Go tools** — all ProjectDiscovery tools (subfinder, httpx, nuclei, katana, naabu, etc.)
- ✅ **Python tools** — pipx-isolated for jsleak, arjun, dirsearch, droopescan, and more
- ✅ **GitHub clones** — tools that only exist as git repos (Corsy, ParamSpider, SSRFmap, tplmap)
- ✅ **API key distribution** — writes your keys to each tool's native config location automatically
- ✅ **Wordlists** — SecLists, PayloadsAllTheThings, fuzzdb, and more
- ✅ **Auto-repair** — fixes broken apt locks, DNS, disk space, Go version, and more before installing

---

## ✨ Features

| Feature | Description |
| :--- | :--- |
| 🩺 **Self-Healing** | 17+ preflight checks auto-repair apt locks, DNS failures, disk space, broken dpkg, stale caches |
| 🔁 **Idempotent** | Safe to re-run — skips already-installed tools, retries only failures |
| 🔧 **Retry Logic** | Go installs retry with `CGO_ENABLED=1`, `-mod=mod`, and cache clears |
| 🔑 **API Key Distribution** | One `api_keys.txt` → writes correct config for subfinder, amass, theHarvester, shodan CLI, metabigor |
| 🐍 **Pipx Isolation** | Python tools live in isolated venvs — no system Python conflicts |
| 📦 **72+ Repos Cloned** | All git-only tools land in `/opt/tools/` with auto-generated wrappers |
| 🎯 **Smart Wrappers** | Python tools exposed as global commands (`corsy`, `paramspider`, `ssrfmap`, `tplmap`) |
| 🚦 **Auto-Verification** | Live tests: subfinder, chaos, shodan API keys validated after install |
| 📊 **Color-Coded Logs** | Clear ✓ / ⚠ / ✗ indicators for every step |
| 📝 **Full Logging** | Every action logged to `/var/log/tool_install.log` |

---

## 🚀 Quick Start

### Prerequisites

- **Kali Linux** (2023.4 or newer recommended)
- **Root access** (`sudo`)
- **~5 GB free disk space**
- **Internet connection** for downloads

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/bug-bounty-toolkit.git
cd bug-bounty-toolkit

# 2. (Optional) Fill in your API keys
nano api_keys.txt

# 3. Make the installer executable
chmod +x install_tools.sh api_setup.sh

# 4. Run the installer as root
sudo ./install_tools.sh

# 5. Reload your shell environment
source /etc/profile.d/bugbounty.sh
source /etc/profile.d/golang.sh