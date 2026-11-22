# Grand Machinato Legacy Corporate Intranet

A complete, fictional, static corporate intranet for Windows Server 2012 R2 IIS and Microsoft Edge IE mode. It uses standards-mode HTML, conservative CSS, ES5 JavaScript, local PNG/ICO assets, and local JavaScript data files. It has no package manager, build step, external library, CDN, or internet dependency.

> **Demonstration only.** All people, applications, systems, policies, contacts, dates, and workflows are fictional. No request is submitted and no status is live.

## What is included

- Dashboard, announcements, Service Desk demonstration, systems status, applications, employee directory, HR, policies, forms, infrastructure, Knowledge Base, useful links, support, search, and custom error pages.
- Keyboard-accessible native controls, error summary and field errors, status text plus color/icons, responsive desktop fallbacks, and print styles.
- Grand Machinato PNG logo variants, ICO favicon, and PNG status icons.
- Static sample data under `assets/data/`, separate from rendering logic.
- IIS configuration, deployment guidance, Enterprise Mode Site List sample, compatibility plan, security notes, and future ASP.NET architecture.

## Browser target

Primary target: Microsoft Edge IE mode using IE11 document mode. The pages include `X-UA-Compatible: IE=edge`, a valid HTML5 doctype, ES5-only scripts, and no required modern browser APIs. Edge normal mode is also expected to render the site.

IE-mode validation was **not performed in this Linux build environment**. Complete the managed-Windows tests in `docs/ie-mode-testing.md` before release.

## Preview and deployment

Opening HTML files directly can display most content, but an HTTP preview is preferred because IIS behavior, custom errors, MIME handling, headers, and caching cannot be validated from `file://`.

1. Copy the folder to an IIS content path, for example `C:\inetpub\wwwroot\grand-machinato`; the deployable root `web.config` is already included, with a reference copy under `config\`.
2. Create an IIS site or application and grant the application-pool identity read/execute permission.
3. Configure an HTTPS binding and approved certificate.
4. Browse the IIS URL, for example `https://intranet.grandmachinato.example/legacy/`.

Full instructions: `docs/installation.md` and `config/iis-setup.md`.

## Content maintenance

- Announcements: `assets/data/announcements.js`
- Applications: `assets/data/applications.js`
- Directory records: `assets/data/employees.js`
- Policies: `assets/data/policies.js`
- Knowledge articles: `assets/data/knowledge.js`
- Systems status: `assets/data/systems.js`
- Useful links and request catalog: `assets/data/links.js`
- Navigation: the repeated navigation markup in each HTML file; future ASP.NET should centralize it in a master/layout view.

Data files assign arrays beneath `window.GrandMachinato.Data`. Preserve ES5 syntax and encode any future server-originated values on output. See `docs/content-update-guide.md`.

## Demonstration versus future backend

Client-side filtering, searching, sorting, tabs, service-request validation, review, confirmation, print controls, and feedback notices work locally. The static site does **not** provide authentication, authorization, Active Directory access, persistence, ticket creation, file upload, live monitoring, email, approvals, auditing, or content administration. Those require a secured server-side implementation.

## Enterprise Mode Site List

`config/sample-enterprise-mode-site-list.xml` is an administrator artifact, not application logic. Replace placeholders, validate it with applicable Microsoft tooling, increment the version after every published change, host it over approved HTTPS, deploy to a limited device group, and verify active IE11 document mode. See `docs/ie-mode-configuration.md`.

## Documentation index

- `docs/installation.md` — installation and local preview
- `config/iis-setup.md` — detailed IIS setup and rollback
- `docs/ie-mode-configuration.md` — Edge IE-mode policy and XML lifecycle
- `docs/ie-mode-testing.md` — compatibility test plan and test record
- `docs/compatibility-matrix.md` — feature/browser expectations
- `docs/security-notes.md` — static and future-backend controls
- `docs/future-aspnet-architecture.md` — target server architecture
- `docs/migration-plan.md` — phased migration and modernization
- `docs/content-update-guide.md` — safe sample-content maintenance
- `docs/quality-check-report.md` — completed automated checks and explicit test gaps

## Known limitations

- IE mode requires administrator-managed Edge policy; HTML and JavaScript cannot enable it.
- The environment used to create this project cannot run Edge IE mode, IIS 8.5, Windows Authentication, or Active Directory, so those require managed Windows testing.
- Static data can become stale and is visible to every user who can read the site.
- `web.config` uses root-relative custom-error paths. If deployed beneath a virtual directory, update those paths as described in `config/iis-setup.md`.
- `toLocaleDateString` formatting varies by Windows regional settings; a conservative `toDateString` fallback is included.

## Recommended next step

Deploy to an isolated IIS 8.5 test site, validate the Enterprise Mode Site List on a limited managed-device group, execute the full IE-mode test plan, and then prototype a shared ASP.NET Framework layout with server-enforced Windows Authentication while preserving the static page contracts.
