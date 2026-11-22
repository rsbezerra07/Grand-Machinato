# Migration and Modernization Plan

IE mode is a compatibility bridge, not a permanent development target.

## Phase 1 — Static intranet

- Deploy HTML, conservative CSS, ES5 JavaScript, local assets, and fictional sample data to IIS.
- Validate HTTPS, headers, permissions, caching, logging, custom errors, accessibility, and all display targets.
- Pilot the versioned Enterprise Mode Site List and complete Edge normal/IE-mode tests.
- Establish content ownership and release/rollback procedures.

**Exit:** approved static release with recorded managed-Windows test evidence.

## Phase 2 — Windows Authentication

- Design IIS zone, identity, and authorization behavior.
- Enable Windows Authentication and disable Anonymous Authentication only where appropriate.
- Display authenticated identity from server code, never from client assumptions.
- Test group membership, access denied, session behavior, proxy/load-balancer paths, and support fallback.

**Exit:** server-enforced identity and a reviewed authorization matrix.

## Phase 3 — ASP.NET Framework

- Introduce shared layouts, configuration transforms, server-side forms, validation, anti-forgery controls, structured logging, and health checks.
- Replace static request confirmation with transactional server submission.
- Keep ES5 browser compatibility until IE-mode scope is reduced.

**Exit:** production-ready application services with security and operations approval.

## Phase 4 — Active Directory and SQL Server

- Add bounded, least-privilege directory lookup.
- Store content, policies, requests, approval history, publishing state, and audit events in SQL Server.
- Add administration workflows and recovery-tested backups.

**Exit:** governed data integrations, audited content management, and tested restore procedures.

## Phase 5 — Modernization

- Inventory every IE-mode requirement and remove unnecessary legacy constraints.
- Establish modern-browser routes and automated accessibility/security tests.
- Replace ES5/legacy CSS only after supported-client analysis; keep shared service contracts stable.
- Pilot modern mode, compare outcomes, migrate user groups gradually, and remove site-list entries when evidence supports it.

**Exit:** no IE-mode dependency for the modernized site and a retired legacy path with retained records.

## Cross-phase controls

Every phase requires threat review, privacy and records review, owner acceptance, performance testing, browser regression, operational documentation, monitoring, backup/rollback evidence, and a support handoff.
