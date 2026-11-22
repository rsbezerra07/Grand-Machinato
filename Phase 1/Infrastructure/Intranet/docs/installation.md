# Installation and Preview Guide

## Prerequisites

- Windows Server 2012 R2 with IIS 8.5 and the Static Content feature.
- A dedicated or approved application pool; no managed runtime is required for the static release.
- A DNS name and HTTPS certificate approved by the organization.
- Read access for the application-pool identity and write access only for deployment administrators.
- A managed Windows client with supported Microsoft Edge for IE-mode validation.

No Node.js, npm, framework runtime, database, URL Rewrite module, or public internet connection is required.

## Package preparation

1. Scan the package according to organizational release procedures.
2. Review all fictional content and placeholders.
3. Confirm the deployable root `web.config` matches the reference copy at `config/web.config`. Do not expose the `config` or `docs` folders as downloadable content; the supplied configuration hides them.
4. Keep `config/sample-enterprise-mode-site-list.xml` in browser-management storage, not in the application route, unless an approved HTTPS management endpoint is deliberately selected.

## Local HTTP preview

For a developer-only preview on a trusted workstation, use any approved static HTTP server and browse `index.html`. A `file://` preview does not exercise HTTP headers, custom errors, caching, authentication, or IIS behavior.

Do not represent a local preview as IIS or Edge IE-mode validation.

## IIS deployment summary

1. Install the IIS **Static Content**, **Default Document**, **HTTP Errors**, and **HTTP Logging** role services.
2. Create `C:\inetpub\wwwroot\grand-machinato` or another approved path.
3. Copy all project files to that path; `web.config` is already in the deployment root.
4. Grant `Read & execute`, `List folder contents`, and `Read` to the selected application-pool identity. Do not grant Modify or Write to the web process for this release.
5. In IIS Manager, create a website or an application beneath an existing site.
6. Assign an application pool. For a static site, `.NET CLR version: No Managed Code` is suitable.
7. Configure an HTTPS binding with the intended host name and certificate. Redirect policy, if required, must use an installed and approved mechanism; this project does not assume URL Rewrite.
8. Confirm `index.html` is the default document and directory browsing is disabled.
9. Browse the HTTPS URL and test one CSS, JavaScript, PNG, ICO, and data-JavaScript path directly.
10. Request a missing route to confirm the 404 page. Confirm the 403 behavior in the actual hosting arrangement.

See `../config/iis-setup.md` for full steps, logging, cache checks, virtual-directory caveats, and rollback.

## Post-deployment verification

- Browser address and certificate are correct.
- Home, all navigation items, global search, filters, tabs, validation, print preview, and error pages work.
- Developer tools show no failed local asset requests or script errors.
- Responses for HTML/data do not retain stale values; images/CSS/JS use the documented cache period.
- `docs/`, `config/`, Markdown files, and `.config` files are not downloadable.
- No directory listing is available.
- IIS logs contain expected 200/304 responses and no unexpected 404/500 responses.

## Rollback

Keep the previous approved release in a sibling folder. Stop or quiesce the site, switch the physical path back to that folder (or restore the previous files atomically), start the site, browse the health-check pages, and record the rollback. Never overwrite the only known-good copy.
