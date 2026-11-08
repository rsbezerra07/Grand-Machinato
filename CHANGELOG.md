# Changelog

All notable changes, architectural milestones, and deployment evidence for the **Grand-Machinato** project are documented in this file.

## [Unreleased] - Planned Roadmap

### Baseline – Perimeter & Routing
* **pfSense High Availability Cluster:** Provision two virtual appliances (`GM-FW01-A` and `GM-FW01-B`) on Hyper-V.
* **HA & State Replication:** Configure CARP Virtual IPs and `pfsync` over `GM_SYNC_CORP`.
* **VLAN Trunking:** Configure 802.1Q VLANs (VLAN 10 through VLAN 80) under the `10.77.0.0/16` address space on `GM_LAN_CORP`.

---

## [0.1.0] - 2026-11-08 — Baseline: Virtual Network Foundation

### Added (Features)
* **Environment-Driven Automation (`.env`):** Centralized vSwitch naming and physical NIC binding variables in a root `.env` configuration file for portability.
* **Hyper-V Virtual Switches:** Automated the deployment of the four core network switches via PowerShell (`Baseline/Scripts/`):
  * `GM_WAN_CORP` (**External**): Bridged to the host physical network adapter (`AllowManagementOS` enabled) for outbound Internet access.
  * `GM_ADMIN_CORP` (**Internal**): Dedicated management interface (`192.168.1.0/24`) isolating host-to-pfSense WebGUI traffic.
  * `GM_LAN_CORP` (**Private**): Isolated trunk switch designated for internal 802.1Q department and server VLANs.
  * `GM_SYNC_CORP` (**Private**): Dedicated point-to-point link for pfSense High Availability state synchronization.
* **Lifecycle & Validation Scripts:** Added modular PowerShell scripts to create, verify, rename, and remove virtual switches (`Create_*_VMSwitch.ps1`, `Check_VMSwitch.ps1`, `Rename_VMSwitch.ps1`, and `Delete_VMSwitch.ps1`).


### Evidence & Validation

![vSwitches Created](./Baseline/Evidences/VMSwitches%20created.png)