# Wazuh Operations Guide — Grey Team (Overseers)

**Competition: SCP Foundation Attack/Defend**
**Dashboard:** https://10.10.10.201:443
**Login:** admin / H?Q8mEN8OIXvPwfxXxxKB292?iL.L2Dj

---

## Quick Start (Do This First)

1. Open https://10.10.10.201:443 in your browser
2. Accept the self-signed certificate warning
3. Log in with the credentials above
4. Click the hamburger menu (three lines, top left)
5. Go to **Agents** — verify all enrolled agents show a green **Active** status

---

## Dashboard Navigation

| Where to click | What it shows |
|---|---|
| **Security Events** (under Modules) | All alerts in real time — this is your main view |
| **Integrity Monitoring** (under Modules) | File changes across all agents — flag tampering shows here |
| **Agents** (top menu) | Agent health — shows if a box goes offline |
| Click any **agent name** | Drills into that specific host's alerts, FIM, vulnerabilities |

---

## The Filters You Need

In **Security Events**, use the search bar at the top. Here are the exact filters for each competition rule:

### FILTER: Flag Tampering (SCP Modifications)
> **Rule:** Nine-Tailed Fox may not change/modify/move actual SCPs (Flags)

Search: `rule.groups: flag_compromise`

This fires when anyone reads, modifies, or deletes any flag file. The alert includes:
- **syscheck.path** — which flag file
- **syscheck.audit.user.name** — who did it
- **agent.name** — which host

If you see Nine-Tailed Fox touching flag files, that is a **penalty**.

### FILTER: User/Account Deletion
> **Rule:** Chaos Insurgency may not change any default user passwords already on any service

Search: `rule.groups: account_destruction`

Fires when any user or group is deleted on Linux (userdel) or Windows (net user /delete, Remove-ADUser). Default users being deleted is always a violation.

### FILTER: Firewall Changes
> **Rule:** Must seek approval for network changes in Site Golisano by Overseers

Search: `rule.groups: firewall_change`

Every iptables, ufw, nftables, netsh, or Windows Firewall rule change triggers this. **Both teams need Overseer approval before making network changes.** If you see firewall alerts without a corresponding approval request, that is a violation.

### FILTER: Scoring Engine Blocked
> **Rule:** No targeting, interference, utilizing, impersonation of Grey Team users, machines, and services

Search: `rule.groups: scoring_engine_block`

This is **level 15 (critical)** — fires if anyone creates a firewall rule, hosts entry, or route targeting the scoring engine at 10.10.10.210. This is always a violation from either team.

### FILTER: Service Disruption / Box Bricking
> **Rule:** Neither team may factory reset any machine without Grey Team approval
> **Rule:** Only reversible changes to configurations from Chaos Insurgency

Search: `rule.groups: service_disruption`

Fires when scored services are stopped, disabled, or uninstalled, or when critical config files are deleted. Check:
- If **Nine-Tailed Fox** broke their own box — ask them if they need help, document the downtime
- If **Chaos Insurgency** made irreversible changes — that is a penalty

### FILTER: Suspicious PowerShell / Privilege Escalation
Search: `rule.groups: privilege_escalation`

Shows Mimikatz, encoded commands, suspicious downloads. Useful for tracking Chaos Insurgency attack tools.

### FILTER: Persistence Mechanisms
Search: `rule.groups: persistence`

New cron jobs, systemd units, scheduled tasks. Chaos Insurgency creating backdoors shows up here.

### FILTER: SSH Brute Force
Search: `rule.groups: brute_force`

Rapid SSH login failures. Helps identify which Chaos Insurgency operator is attacking which box.

### FILTER: Agent Tampering
> **Rule:** No targeting Grey Team machines and services

Search: `rule.groups: agent_tamper`

Fires if anyone stops the Wazuh agent, modifies its config, or if an agent disconnects. The Wazuh agent is a Grey Team service — tampering is a violation from either team.

### FILTER: Windows Defender
> **Rule:** Nine-Tailed Fox may not turn on nor re-enable Windows Defender

Search: `Windows Defender` in Security Events

Watch for Nine-Tailed Fox re-enabling Defender on any Windows box.

---

## Alert Severity Levels

| Level | Color | Meaning |
|---|---|---|
| **15** | Red | CRITICAL — flag compromise or scoring engine blocked. Investigate immediately. |
| **13-14** | Orange | HIGH — user deletion, agent tamper, config destruction. Likely needs a penalty call. |
| **12** | Yellow | MEDIUM — firewall changes, service stops, suspicious PowerShell. Verify if approved. |
| **10-11** | Blue | LOW — brute force, new cron jobs, recon activity. Track for pattern. |

---

## Identifying WHO Did It

For file-related alerts (flag access, config changes):
- Look at the **syscheck.audit.user.name** field — this is the Linux/Windows user who performed the action
- The **agent.name** field tells you which host

For command-based alerts:
- The **srcuser** or **dstuser** fields show the account
- Cross-reference the source IP with the team IP ranges:

| IP Range | Team |
|---|---|
| 10.10.10.41-44 | Nine-Tailed Fox Windows workstations |
| 10.10.10.45-49 | Nine-Tailed Fox Linux workstations |
| 10.10.10.80-88 | Chaos Insurgency workstations |
| 10.10.10.89 | Chaos Insurgency Windows workstation |
| 10.10.10.210 | Grey Team scoring engine |
| 10.10.10.201 | Grey Team Wazuh manager |

---

## Common Scenarios and What to Do

### "A scored service went down"
1. Filter: `rule.groups: service_disruption`
2. Check which agent and what happened (stopped? config deleted? package removed?)
3. If Chaos Insurgency did it — verify the change is **reversible** (rule violation if not)
4. If Nine-Tailed Fox did it — they bricked their own box, document it

### "A flag was captured or moved"
1. Filter: `rule.groups: flag_compromise`
2. Check **syscheck.path** to see which flag
3. Check **syscheck.audit.user.name** to see who
4. If Nine-Tailed Fox moved/modified a flag — **penalty** (they may only create fakes)
5. If Chaos Insurgency read a flag — that is a legitimate capture, record it

### "Someone changed firewall rules"
1. Filter: `rule.groups: firewall_change`
2. Did either team request Overseer approval? If no — **penalty**
3. Check if rule 100400/100401 also fired (scoring engine targeted) — that is always a violation

### "An agent went offline"
1. Go to **Agents** tab — look for red/disconnected status
2. Filter: `rule.groups: agent_tamper`
3. If the Wazuh agent was intentionally stopped — this is targeting a Grey Team service, **penalty**
4. If the whole box went down — check with the team that owns it

### "Chaos Insurgency is impersonating Grey Team"
1. Filter: `rule.groups: account_destruction` or check for new account creation
2. They MAY create similar accounts — but NOT use actual Grey Team accounts
3. Check the username in alerts — if it matches an actual Grey Team account (GREYTEAM, cyberrange), **penalty**

---

## SSH Quick Reference (Manager CLI)

If the dashboard is slow or you need raw data, SSH into the manager:

```bash
ssh cyberrange@10.10.10.201
```

Useful commands:

```bash
# List all agents and status
sudo /var/ossec/bin/manage_agents -l

# Tail alerts in real time (most useful during competition)
sudo tail -f /var/ossec/logs/alerts/alerts.json | python3 -m json.tool

# Search recent alerts for flag compromise
sudo grep -i "flag_compromise" /var/ossec/logs/alerts/alerts.json | tail -20

# Search for a specific rule group
sudo grep "scoring_engine_block" /var/ossec/logs/alerts/alerts.json

# Check agent connection status
sudo /var/ossec/bin/agent_control -l
```

---

## Flag Locations Reference

| Flag | Service | Location |
|---|---|---|
| CONFIDENTIAL{VPN_7L4G_!Sn'7_h3r3} | OpenVPN | /etc/openvpn/server.conf |
| CONFIDENTIAL{7h!z_!z_n07_7h3_7l4G...} | OpenVPN | /home/cyberrange/scp-169/theLeviathan.txt |
| CONFIDENTIAL{Wh0mS!_D4r3_v13W_tH1$} | AD | Domain Wallpaper Policy GPO |
| CONFIDENTIAL{B4nAn4$_1s_4l$0...} | AD | C:\Users\Public\Documents\SCP013.txt |
| CONFIDENTIAL{SCP_096_1s_4l$0...} | AD | C:\Windows\System32\SCP096.txt |
| CONFIDENTIAL{B1nG_b0P_b0OM_B14m} | SMB | C:\Shares\IT_Backup\DEATH.txt |
| CONFIDENTIAL{1r15_ph0t0gr4phy} | SMB | C:\Shares\Confidential\SCP105.txt |
| CONFIDENTIAL{A1hH$_Sk1B3d4_SCP} | SMTP | C:\Windows\System32\inetsrv\smtp_config.txt |
| CONFIDENTIAL{S0m3_3m41l_c0nt3nt} | SMTP | C:\inetpub\mailroot\Drop\third_email.txt |
| CONFIDENTIAL{1n53cur3_5h3ll_d43m0n} | OpenSSH | /usr/lib/systemd/system/sshd.service.d/flag.conf |
| CONFIDENTIAL{b4n5_c4n7_570p_m3} | OpenSSH | /usr/lib/systemd/system-generators/systemd-network-generator |

---

## Rule Violation Quick Reference

| Violation | Who | What to look for in Wazuh |
|---|---|---|
| Comms between teams | Both | Not detectable in Wazuh — physical observation |
| Targeting Grey Team | Both | `rule.groups: agent_tamper` or `scoring_engine_block` |
| Physical interference | Both | Not detectable — physical observation |
| Refusing Overseer requests | Both | Not detectable — verbal |
| Irreversible changes | Chaos Insurgency | `rule.groups: service_disruption` — deleted configs, removed packages |
| Out-of-scope activity | Both | Alerts from IPs outside 10.10.10.0/24 |
| Unapproved network changes | Both | `rule.groups: firewall_change` without prior approval |
| Changing default passwords | Chaos Insurgency | Watch for password change events in Security Events |
| Using Grey Team accounts | Chaos Insurgency | Alerts with srcuser = GREYTEAM or cyberrange from Chaos IPs |
| Factory reset without approval | Both | `rule.groups: service_disruption` — mass package removal or reimaging |
| Re-enabling Defender | Nine-Tailed Fox | Search `Windows Defender` — look for enable events |
| Modifying/moving flags | Nine-Tailed Fox | `rule.groups: flag_compromise` from blue team user/IP |
