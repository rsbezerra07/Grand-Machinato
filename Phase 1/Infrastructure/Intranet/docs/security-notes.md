# Security Notes

## Static-release controls

- Use HTTPS with a trusted internal certificate; an intranet is not automatically trusted.
- Grant the IIS worker read-only access and keep deployment write access separate.
- Keep directory browsing disabled and prevent delivery of configuration/documentation files.
- Store no secrets, credentials, real employee/customer data, production hosts, addresses, firewall rules, vulnerability details, or internal URLs in browser files.
- Treat every browser-delivered data file as readable by every authorized site user.
- Use output encoding. Current renderers create text nodes for sample values rather than injecting data as HTML.
- Apply input length limits and client validation for usability; neither is a security boundary.
- Review headers and inherited IIS policy on the target server. Add HSTS only after HTTPS-only operation and ownership are established.
- Keep the Enterprise Mode Site List at a governed HTTPS location and restrict changes.
- Do not introduce ActiveX, Browser Helper Objects, Java applets, Silverlight, VBScript, unsigned executables, shell commands, or deprecated plugins.

## Future backend requirements

- Enforce authentication and authorization on the server. JavaScript visibility is not access control.
- Use Windows Authentication only with approved IIS/Active Directory configuration and explicit authorization rules.
- Perform Active Directory access from trusted server-side code with a least-privilege service identity or delegated user context as designed.
- Validate, normalize, and encode all submitted fields server-side. Apply allow-lists where practical.
- Use anti-forgery protections for state-changing requests, secure cookies, request-size limits, malware scanning for uploads, and approved file storage.
- Use parameterized SQL and a least-privilege database identity. Never construct SQL from browser values.
- Protect audit logs from alteration; record who changed announcements, policies, requests, and approvals.
- Define retention, privacy, records-management, backup, recovery, and incident-response responsibilities before storing data.
- Keep connection strings and secrets outside browser code and out of source-controlled public configuration; protect them using approved server secret management.

## Input and output review

Client-side fields have `maxlength` values and the service request provides an accessible error summary. A production handler must repeat every check, reject overlong or invalid values, encode displayed text, and log validation failures without logging secrets.

## Data classification

The delivered package contains only fictional public-safe demonstration content. Before adding organizational content, classify it and confirm audience, authentication, authorization, search exposure, cache behavior, logging, backup, and retention.
