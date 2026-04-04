# 📘 README.md — SCP Infrastructure Automation (Grey Team)

## 🏗️ Overview
This repository contains the complete infrastructure automation for the SCP Echo environment, managed by Grey Team. All Windows, Linux, scoring engine, vulnerability deployment, and reset operations are handled through Ansible using a unified, organized structure. This repo replaces the previous split Linux/Windows repos and consolidates everything into one clean, maintainable codebase.

---
## 📂 Repository Structure

```
scpinfra/
├── 1-ServiceDocumentation&Notes
│   └── ...
├── inventory
│   └── hosts.ini
├── playbooks
│   ├── linux
│   │   ├── reset
│   │   │   └── ...
│   │   ├── setup
│   │   │   └── ...
│   │   ├── vulns
│   │   │   └── ...
│   │   ├── reset.yml
│   │   ├── setup.yml
│   │   └── vulns.yml
│   ├── unscored
│   │   ├── reset
│   │   │   └── ...
│   │   ├── setup
│   │   │   └── ...
│   │   ├── reset.yml
│   │   └── setup.yml
│   ├── windows
│   │   ├── reset
│   │   │   └── ...
│   │   ├── setup
│   │   │   └── ...
│   │   ├── vulns
│   │   │   └── ...
│   │   ├── reset.yml
│   │   ├── setup.yml
│   │   └── vulns.yml
├── roles
│   ├── linux
│   │   └── ...
│   ├── unscored
│   │   └── ...
│   └── windows
│       └── ...
├── vars
│   ├── linux
│   │   ├── vulns
│   │   │   └── ...
│   │   └── ...
│   ├── unscored
│   │   └── ...
│   └── windows
│       ├── vulns
│       │   └── ...
│       └── ...
├── ansible.cfg
└── README.md
```


---

## 🖥️ Inventory Layout (inventory/hosts.ini)

Hosts are grouped by OS and service:

Windows:
- Domain Controller
- SMB Server
- SMTP Server

Linux:
- Apache Web Server
- MySQL Database
- OpenSSH Server
- OpenVPN Server
- Scoring Engine

The all_systems group includes everything for full deployments.

---

## 🚀 Deployment Instructions

### Deploy ALL services (Windows + Linux)
ansible-playbook playbooks/deploy-all.yml

### Deploy only Linux services
ansible-playbook playbooks/linux/linux-full.yml

### Deploy only Windows services
ansible-playbook playbooks/windows/windows-full.yml

---

## ⚠️ Vulnerability Deployment

### Deploy ALL vulns
ansible-playbook playbooks/vuln/vuln-all.yml

### Linux-only vulns
ansible-playbook playbooks/vuln/vuln-linux-full.yml

### Windows-only vulns
ansible-playbook playbooks/vuln/vuln-windows-full.yml

---

## 🔄 Reset / Rollback

### Reset everything
ansible-playbook playbooks/reset/reset-all.yml

### Reset Linux
ansible-playbook playbooks/reset/reset-linux-full.yml

### Reset Windows
ansible-playbook playbooks/reset/reset-windows-full.yml

---

## 🧩 Adding a New Service

1. Create a new role under roles/<service>/
2. Add a config file under vars/<service>-config.yml
3. Add a setup playbook under playbooks/linux/ or playbooks/windows/
4. Add a vuln playbook under playbooks/vuln/
5. Add a reset playbook under playbooks/reset/
6. Update:
   - linux-full.yml or windows-full.yml
   - vuln-linux-full.yml or vuln-windows-full.yml
   - reset-linux-full.yml or reset-windows-full.yml
   - deploy-all.yml, vuln-all.yml, reset-all.yml

---

## 🛠️ Requirements

- Ansible 2.9+
- Python 3.8+
- WinRM enabled on Windows hosts
- SSH + ProxyJump access to Linux hosts
- Proper credentials in hosts.ini
