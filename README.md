# 📘 README.md — SCP Infrastructure Automation (Grey Team)

## 🏗️ Overview
This repository contains the complete infrastructure automation for the SCP Echo environment, managed by Grey Team. All Windows, Linux, scoring engine, vulnerability deployment, and reset operations are handled through Ansible using a unified, organized structure. This repo replaces the previous split Linux/Windows repos and consolidates everything into one clean, maintainable codebase.

---

## 📂 Repository Structure

scpinfra/
│
├── inventory/
│   └── hosts.ini
│
├── playbooks/
│   ├── linux/
│   │   ├── setup-openssh.yml
│   │   ├── setup-openvpn.yml
│   │   ├── setup-apache.yml
│   │   ├── setup-mysql.yml
│   │   ├── setup-scoring.yml
│   │   └── linux-full.yml
│   │
│   ├── windows/
│   │   ├── setup-ad.yml
│   │   ├── setup-smb.yml
│   │   ├── setup-smtp.yml
│   │   └── windows-full.yml
│   │
│   ├── vuln/
│   │   ├── vuln-ad.yml
│   │   ├── vuln-smb.yml
│   │   ├── vuln-smtp.yml
│   │   ├── vuln-mysql.yml
│   │   ├── vuln-linux-full.yml
│   │   └── vuln-windows-full.yml
│   │
│   ├── reset/
│   │   ├── reset-ad.yml
│   │   ├── reset-smb.yml
│   │   ├── reset-smtp.yml
│   │   ├── reset-mysql.yml
│   │   ├── reset-linux-full.yml
│   │   └── reset-windows-full.yml
│   │
│   ├── deploy-all.yml
│   ├── vuln-all.yml
│   └── reset-all.yml
│
├── roles/
│   ├── ad/
│   ├── smb/
│   ├── smtp/
│   ├── apache/
│   ├── mysql/
│   ├── openssh/
│   ├── openvpn/
│   ├── scoring-engine/
│   ├── dc-vuln/
│   ├── smb-vuln/
│   ├── smtp-vuln/
│   └── mysql-vuln/
│
├── vars/
│   ├── ad-config.yml
│   ├── smb-config.yml
│   ├── smtp-config.yml
│   ├── apache-config.yml
│   ├── mysql-config.yml
│   ├── scoring-config.yml
│   ├── vuln-ad-config.yml
│   ├── vuln-smb-config.yml
│   ├── vuln-smtp-config.yml
│   └── vuln-mysql-config.yml
│
├── templates/
│   └── shared templates
│
├── ansible.cfg
└── README.md

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

---

Infrastructure Lead: William W
