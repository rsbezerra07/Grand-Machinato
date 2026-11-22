# IIS 8.5 Setup — Windows Server 2012 R2

## 1. Install required role services

Use Server Manager to enable Web Server (IIS), Static Content, Default Document, HTTP Errors, HTTP Logging, Request Filtering, and the IIS Management Console. These are built-in features; this project does not require URL Rewrite or another optional module.

## 2. Prepare the physical path

Example: `C:\inetpub\wwwroot\grand-machinato`. Copy the package; it already includes `web.config` at the deployment root and retains a reference copy at `config\web.config`.

Use a release folder and a separate staging folder. Preserve the previous approved release for rollback.

## 3. Application pool

Create or select a dedicated pool such as `GrandMachinato-Static`. Use **No Managed Code**, Integrated pipeline, and the default application-pool identity. The static release needs no ASP.NET registration.

## 4. NTFS permissions

Grant the pool identity read/execute, list, and read on the web root. Deployment administrators receive controlled write access. Do not give the web worker process Modify, Write, or Full Control. Keep browser-management XML in a separately governed HTTPS location if possible.

## 5. Website or application

For a dedicated site, select the physical path, pool, host name, and HTTPS binding. For an application/virtual directory, convert it to an application when independent configuration or pool assignment is needed.

The supplied custom-error paths are root-relative (`/not-found.html` and `/access-denied.html`). If the intranet is mounted at `/legacy/` beneath a larger site, update them to `/legacy/not-found.html` and `/legacy/access-denied.html`, or use an approved equivalent after testing.

## 6. Bindings and HTTPS

Create an HTTPS binding with an approved certificate and the intended internal DNS host name. Check certificate chain, expiry, name match, and client trust. If HTTP must redirect to HTTPS, configure that at a load balancer, reverse proxy, HTTP Redirect role service, or approved rewrite mechanism; do not assume URL Rewrite is installed.

## 7. Default document and static assets

Confirm `index.html` is enabled. Browse these examples through IIS:

- `/index.html`
- `/assets/css/layout.css`
- `/assets/js/common.js`
- `/assets/data/announcements.js`
- `/assets/images/logo/logo-dark-bg.png`
- `/assets/images/logo/favicon.ico`

IIS 8.5 normally knows the required MIME types. Add a mapping only if direct testing shows one is missing; avoid duplicate MIME-map entries.

## 8. Configuration behavior

The supplied configuration:

- disables directory browsing;
- defines `index.html` as the only default document;
- disables caching by default and assigns bounded caching to images, CSS, and JavaScript while disabling it for changing data files;
- maps 403 and 404 to static pages;
- hides `config` and `docs`, and blocks `.config` and `.md` delivery;
- removes `X-Powered-By` and adds conservative response headers.

Verify every directive on the target IIS 8.5 instance. If inherited server configuration locks a section, coordinate with the IIS administrator instead of weakening global policy.

## 9. Authentication

Leave the static demonstration aligned with the hosting site's approved policy. Do not claim authentication merely because the site is on an intranet. Windows Authentication belongs to migration Phase 2 and must be tested with Anonymous Authentication settings, SPNs/delegation needs, authorization rules, and fallback behavior.

## 10. Logging and validation

Enable W3C logging with date, time, method, URI stem/query, status/substatus, Win32 status, user agent, host, and time taken. Review the log after smoke testing for unexpected 404, 403, 500, or asset failures. Protect logs according to retention and privacy requirements.

## 11. Rollback

1. Retain the previous release and configuration.
2. Stop new deployment activity.
3. Restore the former physical path or approved backup.
4. Recycle the pool only if needed.
5. Verify home, assets, custom errors, and HTTPS.
6. Record the cause and preserve logs.

Never test rollback for the first time during an incident.
