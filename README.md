# 🔍 IDOR Checker — Bash-based IDOR Discovery Tool

![Shell](https://img.shields.io/badge/Language-Bash-green?logo=gnu-bash&style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Stage](https://img.shields.io/badge/Stage-Active--Development-orange?style=for-the-badge)

A simple **IDOR (Insecure Direct Object Reference)** scanner written in pure **Bash**.  
It’s designed for Capture-The-Flag (CTF) machines like **HTB Cap**, but can be adapted to any web app exposing sequential IDs.

This script:
- Iterates through numeric resource IDs (`/data/0`, `/data/1`, …).
- Detects whether **packet captures (PCAPs)** or other sensitive data exist.
- Optionally **auto-downloads** discovered artifacts.
- Stores HTML evidence for inspection.

---

## ✨ Features

- 🚀 **Fast scanning** with `curl`
- 📂 **HTML saving** for every found page (`./found_html/`)
- 📡 **Auto PCAP download** mode (`./pcaps/`)
- 🕵️ **Debug mode** to see skipped pages
- ⚡ Works on **Linux & MacOS** with only `curl`, `grep`, and `perl`
## Preview
<p align="center">
  <img src="https://i.imgur.com/iLXIpNE.png" alt="idor-pcap-scanner" width="600">
</p>

---

## 📦 Installation

Clone this repository and make the script executable:

```bash
git clone https://github.com/x0dayy/PacketsIDOR-Checker.git
cd PacketsIDOR-Checker
chmod +x number_checker1.sh
bash number_checker1.sh -s 1 -e 200 -b "http://[IP]/data" -t 3 -D
