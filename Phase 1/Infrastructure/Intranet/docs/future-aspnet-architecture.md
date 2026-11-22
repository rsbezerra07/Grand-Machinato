# Future ASP.NET Framework Architecture

## Goal

Preserve the static information architecture and conservative browser contract while replacing demonstration data and workflows with server-enforced services. The first release remains fully static; this document does not add ASP.NET code.

## Suggested layers

1. **Presentation** — ASP.NET MVC views, Web Forms master/content pages, or Razor templates supported by the selected .NET Framework release. Convert repeated header/navigation/footer into a shared layout.
2. **Application services** — announcements, policies, directory search, status publishing, service requests, approvals, and administration.
3. **Identity and authorization** — IIS Windows Authentication, server-resolved user profile, group/department claims, and explicit policy checks.
4. **Integration** — guarded Active Directory queries, service-management connector, email/notification service, and monitoring feeds.
5. **Persistence** — SQL Server repositories for content, requests, approvals, audit events, and publishing state.
6. **Operations** — structured logs, health checks, configuration management, backup, restore, monitoring, and release rollback.

## Authentication and authorization

Enable Windows Authentication only after testing the hosting zone, anonymous access, service accounts, SPNs/delegation needs, and support model. Resolve the authenticated identity server-side and map it to approved roles. Department-based rules should use governed directory attributes or application roles and default to deny.

Never trust browser-provided user names, department values, hidden fields, or JavaScript decisions. Authorization is repeated for every request and resource on the server.

## Directory

A trusted server component queries Active Directory with bounded filters, escaped search input, page limits, timeouts, and least privilege. Return only approved profile fields. Do not expose directory credentials, LDAP paths, or unrestricted query interfaces to the browser.

## SQL Server content

Use versioned schemas and parameterized commands or a reviewed data-access layer. Suggested stores: announcements, policy metadata/content, knowledge articles, system-status publications, application catalog, requests, approvals, comments, and audit events. Separate draft, approved, published, and retired states.

## Service requests and approvals

Use server-side validation, authorization, anti-forgery protection, transactional request creation, immutable identifiers, attachment controls, status history, notifications, and idempotency. Approvers must be resolved on the server; browser fields cannot select unauthorized approvers.

## Administration

Create protected editor roles for announcements and policies. Require review/publish workflow, effective/review dates, version history, preview, audit trail, and safe rollback. Encode editor output and use an approved HTML sanitization strategy only if rich text is necessary.

## Static-to-server mapping

- `.html` pages become views/content pages without changing public route intent.
- `assets/data/*.js` becomes read-only JSON/API or server-rendered view models.
- `assets/js` remains ES5 during IE-mode support; calls use `XMLHttpRequest` with timeout/error handling.
- Form names and table columns become explicit server contracts.
- `web.config` is environment-transformed and sensitive values move to protected configuration.

## Logging and audit

Separate operational logs from business audit. Record authenticated identity, action, resource identifier, outcome, correlation identifier, and timestamp; avoid sensitive payloads. Protect logs, synchronize time, define retention, and test investigation access.

## Deployment design

Use separate development, test, staging, and production configuration; least-privilege pool identities; TLS; documented dependencies; database migrations; health probes; backup/restore tests; and reversible releases. Run Edge normal and IE-mode regression suites on each release.
