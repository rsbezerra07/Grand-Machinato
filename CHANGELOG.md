# Changelog

All notable changes, architectural milestones, and deployment evidence for the **Grand-Machinato** project are documented in this file.

## [Unreleased] - Planned Roadmap

### Baseline – Perimeter & Routing

* **HA & State Replication:** Configure CARP Virtual IPs and `pfsync` over `GM_SYNC_CORP`.
* **VLAN Trunking:** Configure 802.1Q VLANs (VLAN 10 through VLAN 80) under the `10.77.0.0/16` address space on `GM_LAN_CORP`.

---

## [0.2.0] - 11/09/2026 - Baseline: Virtual Network Machines Foundation

### Added (Features)

* **pfSense Virtual Machines:** Created two dedicated pfSense virtual machines:
  * `GM-FW-01`
  * `GM-FW-02`

* **Automated VM Deployment:** Created two dedicated PowerShell (`Create_pfSense_VM_01.ps1`, `Create_pfSense_VM_02.ps1` ) scripts, one for each pfSense VM, to automate and assist with the virtual machine creation process.

* **VM Lifecycle & Management Scripts:** Added modular PowerShell scripts to manage the pfSense virtual machines:
  * **Activate VM:** Checks and activates the VM selected by the user. (`Check_activate_VMs.ps1`)
  * **Deactivate VM:** Checks and deactivates the VM selected by the user. (`Check_deactivate_VMs.ps1`)
  * **Rename VM:** Renames the VM selected by the user. (`Rename_VMs.ps1`)

* **VM Configuration Files (`pfSense_VM_01.json`, `pfSense_VM_02.json`):** Created two JSON configuration files, one for each pfSense VM, describing their respective VM structure and configuration.

## [0.1.0] - 11/08/2026 — Baseline: Virtual Network Foundation

### Added (Features) - Previous

* **Environment-Driven Automation (`.env`):** Centralized vSwitch naming and physical NIC binding variables in a root `.env` configuration file for portability.

* **Hyper-V Virtual Switches:** Automated the deployment of the four core network switches via PowerShell (`Baseline/Scripts/`):
  * `GM_WAN_CORP` (**External**): Bridged to the host physical network adapter (`AllowManagementOS` enabled) for outbound Internet access.
  * `GM_ADMIN_CORP` (**Internal**): Dedicated management interface (`192.168.1.0/24`) isolating host-to-pfSense WebGUI traffic.
  * `GM_LAN_CORP` (**Private**): Isolated trunk switch designated for internal 802.1Q department and server VLANs.
  * `GM_SYNC_CORP` (**Private**): Dedicated point-to-point link for pfSense High Availability state synchronization.

* **Lifecycle & Validation Scripts:** Added modular PowerShell scripts to create, verify, rename, and remove virtual switches (`Create_*_VMSwitch.ps1`, `Check_VMSwitch.ps1`, `Rename_VMSwitch.ps1`, and `Delete_VMSwitch.ps1`).

### Evidence & Validation

#### vSwitches Created

![vSwitches Created](./Baseline/Evidences/VMSwitches%20created.png)

#### pfSense VMs Created

![Pfsense VMs Created](./Baseline/Evidences/PfSense%20VMs%20Created.png)
