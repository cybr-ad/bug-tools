# 🐛 Bug Hunting Toolkit

A curated collection of tools for bug bounty hunting, penetration testing, and web application security assessments.  
This repository provides an automated installation script and a categorized reference for all included tools.

> **⚠️ Disclaimer**  
> These tools are intended for **authorized security testing and educational purposes only**.  
> Do not use them against systems you do not own or have explicit permission to test.  
> The authors and contributors are not responsible for any misuse or damage caused by these tools.

---

## 📦 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/bug-hunting-toolkit.git
cd bug-hunting-toolkit
```

### 2. Make the Script Executable & Run Installer
Run with `sudo` (root privileges required):

```bash
chmod +x bug-tools.sh
sudo ./bug-tools.sh
```

> **Note:** The script logs the entire installation process to `/var/log/tool_install.log`. Cloned repositories are saved to `/opt/tools`, and Go binaries are stored in `~/go/bin`.

---

## 🧭 Toolkit Directory Structure

| Location | Contents |
| :--- | :--- |
| **System Binaries** (`/usr/bin`, `/usr/local/bin`) | APT and system-wide packages |
| **Go Binaries** (`$HOME/go/bin`) | Go tools (`ffuf`, `gobuster`, `metabigor`) |
| **Cloned Tools & Wordlists** (`/opt/tools/`) | Python scripts, Git repositories, and wordlist collections |
| **Log File** (`/var/log/tool_install.log`) | Complete installer execution log |

---

## 🛠️ Included Tools & Categorized Reference

### 1. 🔍 Subdomain Enumeration & Asset Discovery

| Tool | Source / Install | Description | Location / Command |
| :--- | :--- | :--- | :--- |
| **[Amass](https://github.com/owasp-amass/amass)** | APT | In-depth attack surface mapping, asset discovery, and active/passive DNS scraping. | `amass` |
| **[Sublist3r](https://github.com/aboul3la/Sublist3r)** | APT / GitHub | Fast subdomain enumeration utilizing OSINT search engines (Google, Yahoo, Bing, Baidu). | `sublist3r` / `/opt/tools/Sublist3r` |
| **[MassDNS](https://github.com/blechschmidt/massdns)** | APT | Ultra high-performance DNS stub resolver capable of resolving millions of domains bulk. | `massdns` |
| **[Metabigor](https://github.com/j3ssie/metabigor)** | Go | Intelligence gathering tool performing OSINT (IP/ASN/CIDR/org discovery) without API keys. | `~/go/bin/metabigor` |
| **[Asnlookup](https://github.com/yassineaboukir/Asnlookup)** | GitHub | ASN information lookup tool to enumerate IP ranges and organization CIDR blocks. | `/opt/tools/asnlookup` |
| **[sub.sh](https://github.com/cihanmehmet/sub.sh)** | GitHub | Automated reconnaissance wrapper script for subdomain enumeration and takeover checking. | `/opt/tools/sub.sh` |
| **[dnsutils](https://packages.debian.org/sid/dnsutils)** | APT | Standard DNS lookup utilities including `dig`, `nslookup`, and `host`. | `dig`, `nslookup` |
| **[whois](https://packages.debian.org/sid/whois)** | APT | Client for querying RFC 3912 domain registration and WHOIS directory databases. | `whois` |

---

### 2. ⚡ Web Fuzzing & Content Discovery

| Tool | Source / Install | Description | Location / Command |
| :--- | :--- | :--- | :--- |
| **[ffuf](https://github.com/ffuf/ffuf)** | APT / Go | Fast web fuzzer written in Go for discovering hidden directories, files, parameters, and virtual hosts. | `ffuf` / `~/go/bin/ffuf` |
| **[Gobuster](https://github.com/OJ/gobuster)** | APT / Go | High-speed directory, DNS subdomain, vhost, and S3 bucket brute-forcer written in Go. | `gobuster` / `~/go/bin/gobuster` |
| **[Wfuzz](https://github.com/xmendez/wfuzz)** | APT / pipx | Versatile web application fuzzer and bruteforcer for HTTP parameters, paths, and headers. | `wfuzz` |
| **[DIRB](https://dirb.sourceforge.net/)** | APT | Classic web content scanner using dictionary-based lookups against web servers. | `dirb` |

---

### 3. 🎯 Vulnerability Assessment & Exploitation

| Tool | Source / Install | Description | Location / Command |
| :--- | :--- | :--- | :--- |
| **[SQLmap](https://github.com/sqlmapproject/sqlmap)** | APT | Automatic SQL injection detection, extraction, and database takeover engine. | `sqlmap` |
| **[Nikto](https://github.com/sullo/nikto)** | APT | Comprehensive web server assessment scanner for dangerous files, outdated versions, and misconfigurations. | `nikto` |
| **[aem-hacker](https://github.com/0ang3el/aem-hacker)** | GitHub | Reconnaissance and exploit toolkit for vulnerable Adobe Experience Manager (AEM) web applications. | `/opt/tools/aem-hacker` |
| **[broken-link-checker](https://github.com/stevenvachon/broken-link-checker)** | GitHub | High-speed crawler to identify dead links, broken endpoints, and second-order takeover risks. | `/opt/tools/broken-link-checker` |
| **[Impacket](https://github.com/fortra/impacket)** | APT | Suite of Python scripts and network protocol libraries for network auditing and exploitation. | `impacket-*` |

---

### 4. 🧩 CMS Scanners & Security Auditing

| Tool | Source / Install | Description | Location / Command |
| :--- | :--- | :--- | :--- |
| **[WPScan](https://github.com/wpscanteam/wpscan)** | APT | Black-box WordPress security scanner for core vulnerabilities, themes, and plugins. | `wpscan` |
| **[CMSeeK](https://github.com/Tuhinshubhra/CMSeeK)** | GitHub | Intelligent CMS detection and vulnerability scanner supporting 170+ Content Management Systems. | `/opt/tools/CMSeeK` |
| **[droopescan](https://github.com/droope/droopescan)** | pipx / GitHub | Plugin-based CMS scanner targeting Drupal, SilverStripe, WordPress, Joomla, and Moodle. | `droopescan` / `/opt/tools/droopescan` |
| **[JoomScan](https://github.com/rezasp/joomscan)** | GitHub | OWASP Joomla security scanner for finding known vulnerabilities, component flaws, and misconfigurations. | `/opt/tools/joomscan` |

---

### 5. ☁️ Cloud, Reconnaissance & Bypass Tools

| Tool | Source / Install | Description | Location / Command |
| :--- | :--- | :--- | :--- |
| **[s3-buckets-finder](https://github.com/gwen001/s3-buckets-finder)** | GitHub | Discovers and inspects publicly accessible and misconfigured Amazon AWS S3 buckets. | `/opt/tools/s3-buckets-finder` |
| **[CloudUnflare](https://github.com/greycatz/CloudUnflare)** | GitHub | Reconnaissance script designed to bypass Cloudflare reverse-proxy and discover origin IP addresses. | `/opt/tools/CloudUnflare` |
| **[DumpsterDiver](https://github.com/securing/DumpsterDiver)** | GitHub | Analyzes files and directories to uncover hardcoded API keys, secrets, passwords, and tokens. | `/opt/tools/dumpsterdiver` |
| **[AWS CLI](https://aws.amazon.com/cli/)** | APT | Official Amazon Web Services command line utility for interacting with cloud infrastructure. | `aws` |

---

### 6. 🌐 CORS (Cross-Origin Resource Sharing) Scanners

| Tool | Source / Install | Description | Location / Command |
| :--- | :--- | :--- | :--- |
| **[Corsy](https://github.com/s0md3v/Corsy)** | GitHub | Lightweight CORS misconfiguration scanner capable of detecting exploitable origin headers. | `/opt/tools/corsy` |
| **[CORScanner](https://github.com/chenjj/CORScanner)** | GitHub | Fast Python-based CORS misconfiguration scanner with multi-origin vulnerability heuristics. | `/opt/tools/CORS-Scanner` |

---

### 7. 🕵️ OSINT & Secret Discovery

| Tool | Source / Install | Description | Location / Command |
| :--- | :--- | :--- | :--- |
| **[github-search](https://github.com/gwen001/github-search)** | GitHub | Suite of Python scripts to search GitHub repositories for leaked credentials and sensitive company data. | `/opt/tools/github-search` |
| **[DumpsterDiver](https://github.com/securing/DumpsterDiver)** | GitHub | Deep file inspection with Shannon entropy analysis to discover secrets in source code. | `/opt/tools/dumpsterdiver` |

---

### 8. 🛡️ WAF & Defense Fingerprinting

| Tool | Source / Install | Description | Location / Command |
| :--- | :--- | :--- | :--- |
| **[wafw00f](https://github.com/EnableSecurity/wafw00f)** | APT | Fingerprints and identifies Web Application Firewalls (WAF) protecting target web servers. | `wafw00f` |

---

### 9. 📚 Wordlists & Payload Dictionaries

All collections are cloned directly into `/opt/tools/` for easy referencing with tools like `ffuf`, `gobuster`, and `wfuzz`:

| Repository | Description | Path |
| :--- | :--- | :--- |
| **[SecLists](https://github.com/danielmiessler/SecLists)** | The security tester's companion — comprehensive collection of usernames, passwords, URLs, sensitive files, fuzz payloads, and shells. | `/opt/tools/SecLists` (and `seclists` APT package) |
| **[PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)** | Essential guide and collection of payloads for XSS, SQLi, SSRF, SSTI, XXE, CSRF, and web bypasses. | `/opt/tools/PayloadsAllTheThings` |
| **[IntruderPayloads](https://github.com/1N3/IntruderPayloads)** | Curated wordlists, fuzzing lists, and attack patterns designed for Burp Suite Intruder and automated fuzzers. | `/opt/tools/IntruderPayloads` |
| **[FuzzDB](https://github.com/fuzzdb-project/fuzzdb)** | Dictionary of attack patterns, fault injection primitives, and predictable resource discovery files. | `/opt/tools/fuzzdb` |
| **[Commonspeak2](https://github.com/assetnote/commonspeak2-wordlists)** | Context-specific, high-accuracy wordlists generated from internet-scale dataset analysis by Assetnote. | `/opt/tools/commonspeak2-wordlists` |

---

## ⚙️ Post-Installation & PATH Setup

To ensure you can run all installed Go binaries from any directory, add `$HOME/go/bin` to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
echo 'export GOPATH="$HOME/go"' >> ~/.bashrc
echo 'export PATH="$PATH:$GOPATH/bin:/usr/local/go/bin"' >> ~/.bashrc
source ~/.bashrc
```

For tools cloned into `/opt/tools`, navigate to the respective directory or add aliases as needed:

```bash
# Example: Running Corsy
python3 /opt/tools/corsy/corsy.py -u https://target.com

# Example: Running CMSeeK
python3 /opt/tools/CMSeeK/cmseek.py -u https://target.com
```

---

## 📋 System Requirements & Dependencies

The installer prepares your environment by automatically installing the following base runtimes and developer libraries:
- **Languages & Runtimes:** Python 3 (`python3`, `python3-pip`, `python3-venv`, `pipx`), Go (`golang-go`), Ruby (`ruby`, `ruby-dev`), Node.js & npm.
- **System Utilities:** `git`, `curl`, `wget`, `unzip`, `jq`, `build-essential`.
- **Development Headers:** `libpcap-dev`, `libssl-dev`, `libffi-dev`, `python3-dev`.

---

## 🤝 Contributing

Contributions, bug reports, and suggestions are welcome!
1. Fork this repository.
2. Create your feature branch (`git checkout -b feature/NewTool`).
3. Commit your changes (`git commit -m 'Add NewTool'`).
4. Push to the branch (`git push origin feature/NewTool`).
5. Open a Pull Request.

---

## 📄 License

This repository is distributed under the MIT License. Individual tools and wordlists retain their respective licenses and terms of use.
