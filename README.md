# Grand Machinato

**Enterprise Infrastructure & Modernization Lab**

Grand Machinato is a hands-on lab that follows the evolution of a fictional company from traditional **on-premises infrastructure** to modern endpoint management, hybrid cloud, automation, and an open-source platform.

The project focuses on understanding **why technologies exist, what problems they solve, how they integrate, and how the environment can be recovered when failures occur.**

## 🗺️ Roadmap

| Phase | Focus |
|---|---|
| Foundation | Hyper-V, networking, backup and Git |
| **1. The Legacy** | AD, DNS, DHCP, GPO, Samba and traditional deployment |
| 2. Modernization | Configuration Manager, OSD, applications and updates |
| 3. Hybrid Cloud | Entra ID, Intune, Autopilot, Azure Arc and OpenTofu |
| 4. Open Platform | Linux, FreeIPA, Ansible, observability and GitOps |

## 🚧 Current Phase: The Legacy

The first phase recreates a traditional enterprise environment with four fictional departments:

- IT
- Human Resources
- Sales
- Marketing

### Stack

- Hyper-V
- Windows Server 2022
- Active Directory
- DNS / DHCP
- Group Policy
- pfSense CE
- Ubuntu Server
- Samba / Winbind
- PowerShell
- Git
- WDS / MDT *(historical study)*

### Goals

- [ ] Build segmented virtual networks
- [ ] Deploy AD, DNS and DHCP
- [ ] Create departmental identities and endpoints
- [ ] Implement and validate GPOs
- [ ] Configure departmental file shares
- [ ] Test permissions and network isolation
- [ ] Document legacy deployment
- [ ] Validate backup and restore
- [ ] Store scripts and evidence in Git

## Principles

> **Build → Test → Break → Recover → Document → Automate**

- Evidence before claims
- Automation over repetitive work
- Recovery as part of the architecture
- Positive and negative testing
- Secrets never committed to Git
- Every tool must solve a defined problem

## Status

🚧 **Foundation / Phase 1**

Architecture defined. Implementation and validation in progress.