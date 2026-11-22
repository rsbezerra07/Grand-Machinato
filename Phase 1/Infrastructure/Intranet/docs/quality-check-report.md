# Build Quality Check Report

**Run date:** 2026-11-11  
**Scope:** source-level and local HTTP checks in the Linux build environment  
**Important:** This is not an IIS 8.5, Microsoft Edge, or Edge IE-mode certification.

## Passed automated checks

- 16 HTML pages inspected for standards doctype, `X-UA-Compatible: IE=edge`, skip link/target, image alternatives, form-label associations, table captions/headers, local assets, internal links, and in-page anchors.
- 65 project files inventoried; all required pages, documentation, configuration, scripts, data, and assets were present at check time.
- 17 JavaScript/data files parsed successfully by Node's syntax checker.
- ES5/legacy scan found no arrow functions, template literals, `let`/`const` declarations, classes, async/await, optional chaining, nullish coalescing, spread/rest, `fetch`, Promise, Map/Set, `eval`, `document.write`, `localStorage`, or ActiveX use in project JavaScript.
- All seven static data files loaded into `window.GrandMachinato.Data`; expected arrays and record counts were present: 6 announcements, 9 applications, 12 employees, 8 policies, 7 knowledge articles, 8 systems, 12 links, and 10 forms.
- Internal IDs checked across announcements, policies, and knowledge records were unique.
- 10 PNG/ICO assets decoded successfully.
- CSS `url(...)` references resolved to local files.
- Runtime HTML/CSS/JavaScript contained no external HTTP/HTTPS dependency.
- Secret-shaped assignment scan found no API key, password, secret, or token literal.
- Root and reference `web.config` plus the Enterprise Mode Site List sample were well-formed XML.
- Local HTTP smoke test returned HTTP 200 for all 50 deployable HTML, CSS, JavaScript, PNG, and ICO files.
- Query routes for search, announcement detail, knowledge detail, and policy detail returned their HTML page successfully.

The reusable checker is `tools/quality_check.py`.

## Source-reviewed compatibility provisions

- Constrained 1120-pixel desktop shell scales to 98% below 1150 pixels.
- Left navigation changes to a keyboard-operable menu below 800 pixels.
- Every table is inside a bounded horizontal-scroll container.
- Core layout uses floats, inline-block, normal flow, explicit widths, and simple media queries.
- Solid colors precede the one optional linear-gradient enhancement.
- Status is represented with text, icon, and color.
- Print CSS removes navigation/actions and retains content tables and details.
- Data rendering creates text nodes; `innerHTML` is used only to clear controlled DOM containers.

## Not performed in this environment

- Microsoft Edge normal-mode rendering or interaction testing.
- Microsoft Edge IE-mode or IE11 document-mode testing.
- Visual checks at 1024×768, 1280×720, 1366×768, and 1920×1080 in a real Windows browser.
- Print preview with an actual Windows printer driver.
- IIS 8.5 configuration loading, custom error execution, header/caching behavior, HTTPS binding, or IIS log review.
- Enterprise Mode Site List policy retrieval, refresh/cache behavior, and centralized administration.
- Windows Authentication, Active Directory, SQL Server, or future-backend behavior.

No supported browser executable was installed in the build container. These cases remain explicitly **Not run** in `ie-mode-testing.md` and must be executed on a managed Windows client and Windows Server 2012 R2/IIS test environment before release.
