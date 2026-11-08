# Grand-Machinato

![Hyper-V](https://img.shields.io/badge/Hyper--V-0078D7?style=for-the-badge&logo=windows&logoColor=white)
![pfSense](https://img.shields.io/badge/pfSense-212121?style=for-the-badge&logo=pfsense&logoColor=white)
![Windows Server](https://img.shields.io/badge/Windows%20Server-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Microsoft Intune](https://img.shields.io/badge/Intune-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)
![Microsoft Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonwebservices&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Datadog](https://img.shields.io/badge/Datadog-632CA6?style=for-the-badge&logo=datadog&logoColor=white)
![Zabbix](https://img.shields.io/badge/Zabbix-D40000?style=for-the-badge&logo=zabbix&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)

## Enterprise Infrastructure Modernization, Hybrid Management, and Multi-Cloud Architecture Lab

**Grand-Machinato** is an end-to-end enterprise infrastructure project that simulates the complete technological evolution of an organization. Starting from traditional on-premises legacy tools, the architecture scales through centralized endpoint lifecycle management into hybrid cloud governance, multi-cloud workloads, and full-stack observability.

## Network Architecture & Baseline

The perimeter and internal routing rely on a High Availability (HA) cluster of two **pfSense** virtual appliances running on Hyper-V. The cluster uses CARP for virtual IP failover and `pfsync` for state table replication across four dedicated virtual switches:

* **WAN (`GM_WAN_CORP` - External):** Bridges the pfSense cluster to the physical network adapter for outbound Internet connectivity.
* **ADMIN (`GM_ADMIN_CORP` - Internal):** Provides a dedicated management link between the Hyper-V host and the pfSense WebGUI.
* **LAN (`GM_LAN_CORP` - Private):** Operates as an 802.1Q VLAN trunk isolating corporate departments under the `10.77.0.0/16` address space.
* **SYNC (`GM_SYNC_CORP` - Private):** Dedicated point-to-point link for high-availability state synchronization between firewall nodes.

### 802.1Q VLAN Segmentation

| VLAN ID | Tag | Department / Role | Subnet | Gateway |
| :--- | :--- | :--- | :--- | :--- |
| 10 | SRV | Core Servers | 10.77.10.0/24 | 10.77.10.1 |
| 20 | IT | Information Technology | 10.77.20.0/24 | 10.77.20.1 |
| 30 | HR | Human Resources | 10.77.30.0/24 | 10.77.30.1 |
| 40 | SAL | Sales Department | 10.77.40.0/24 | 10.77.40.1 |
| 50 | MKT | Marketing Department | 10.77.50.0/24 | 10.77.50.1 |
| 60 | PXE | OS Provisioning | 10.77.60.0/24 | 10.77.60.1 |
| 70 | OSS | Open-Source Services | 10.77.70.0/24 | 10.77.70.1 |
| 80 | MON | Monitoring & Telemetry | 10.77.80.0/24 | 10.77.80.1 |

This table maps the internal 802.1Q trunk networks routed by the pfSense HA cluster.

## Evolutionary Roadmap

### Phase 1: Legacy On-Premises Infrastructure

Establishes the foundational directory, networking, and legacy deployment services for four corporate departments (IT, HR, Sales, and Marketing).

* **Identity & Core Network:** Windows Server Domain Controller (`AD DS`) managing identity, DNS resolution, DHCP scopes, and OU-based Group Policy Objects (GPOs).
* **Legacy OS Deployment:** Automated Windows 10 provisioning via Windows Deployment Services (WDS) and Microsoft Deployment Toolkit (MDT) over VLAN 60.
* **Baseline Software:** Automated installation of core utilities (Google Chrome and 7-Zip) alongside role-specific departmental applications.
* **Enterprise Storage:** Linux File Server integrated with Active Directory providing access-controlled network shares per department.

### Phase 2: Endpoint Management Modernization (MECM)

Retires legacy WDS imaging in favor of centralized lifecycle management using Microsoft Endpoint Configuration Manager (MECM / SCCM) backed by SQL Server 2022.

* **Content & Patching:** Centralizes OS deployment and patching through a dedicated Distribution Point (DP) and Software Update Point (SUP/WSUS).
* **Standardized Packaging:** Wraps enterprise applications using the PowerShell App Deployment Toolkit (PSADT) for standardized logging and installation prompts.
* **OS Upgrade Rings:** Automates in-place upgrades migrating legacy Windows 10 endpoints to Windows 11 25H2 using phased task sequences.

### Phase 3: Hybrid Cloud Operations & Governance

Extends the on-premises infrastructure into Microsoft Cloud for modern identity, zero-touch provisioning, and hybrid server governance.

* **Hybrid Identity:** Synchronizes local Active Directory objects to Microsoft Entra ID via the Entra Cloud Sync agent on the Domain Controller.
* **Co-Management & Autopilot:** Bridges MECM and Microsoft Intune for shared workload governance while provisioning cloud-native endpoints via Windows Autopilot.
* **Hybrid Server Governance:** Onboards local servers to Azure Arc for centralized policy enforcement and automated patching via Azure Update Manager.
* **Cloud Workloads:** Deploys two Azure VMs hosting the corporate e-commerce platform (WordPress) and ITSM system (GLPI), secured over HTTPS (Port 443) via an internal Root CA.

### Phase 4: Hybrid Observability & Multi-Platform Management

Completes architectural maturity by unifying on-premises and SaaS telemetry while expanding endpoint compliance across heterogeneous operating systems.

* **On-Premises Monitoring:** Deploys Zabbix and Grafana in VLAN 80 to collect local server metrics and pfSense SNMP network telemetry.
* **SaaS Observability & APM:** Integrates Datadog Pro to centralize cloud telemetry, security log aggregation, and Application Performance Monitoring (APM) for the Azure PHP workloads.
* **Multi-OS & Multi-Cloud Governance:** Enrolls a corporate Linux workstation and an AWS EC2 macOS instance into Microsoft Intune for cross-platform compliance and `.pkg` application deployment.
