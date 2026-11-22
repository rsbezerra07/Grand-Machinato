# IE-mode Compatibility Test Plan

**Status:** not executed in this build environment. Edge IE mode requires a compatible managed Windows client. Record actual evidence; do not mark a case passed based only on source inspection.

## Test environments

Run each applicable case in:

1. Microsoft Edge normal mode.
2. Microsoft Edge IE mode.
3. IE11 document mode inside Edge IE mode, confirmed with the browser's diagnostics/developer tools.

Record Windows version, Edge version, device policy ring, site-list URL/version, test URL, display resolution, tester, and timestamp. Test at 1024×768, 1280×720, 1366×768, and 1920×1080.

## Execution record

| ID | Test case | Browser mode | Expected result | Actual result | Pass/Fail | Notes |
|---|---|---|---|---|---|---|
| LOAD-01 | Load every HTML page directly | Each mode | 200 response; correct title/header; no blank core content | Not run | Not run | |
| NAV-01 | Use utility, left, breadcrumb, and in-content links | Each mode | Correct existing destination; current item highlighted | Not run | Not run | |
| NAV-02 | Narrow viewport menu | Each mode | Menu toggles and remains keyboard accessible | Not run | Not run | |
| SEARCH-01 | Global and content search | Each mode | Matching title/type/description/destination; no server required | Not run | Not run | |
| FILTER-01 | News, applications, directory, policies, status, KB filters | Each mode | Counts and rows update without errors | Not run | Not run | |
| SORT-01 | Directory and policy sorting | Each mode | Stable expected order; keyboard operation works | Not run | Not run | |
| FORM-01 | Submit empty Service Desk form | Each mode | Focused error summary and field messages; no submission | Not run | Not run | |
| FORM-02 | Enter valid fictional request | Each mode | Review, edit, confirmation, and print controls work; no ticket claim | Not run | Not run | |
| TABLE-01 | Inspect tables at all target resolutions | Each mode | Headers align; bounded horizontal scroll where needed | Not run | Not run | |
| TABS-01 | Operate HR tabs by keyboard and mouse | Each mode | Selected panel appears; focus remains visible | Not run | Not run | |
| PRINT-01 | Print news, request, directory, policy, KB | Each mode | Navigation/actions hidden; content legible; no clipped critical text | Not run | Not run | |
| IMG-01 | Load logos, favicon, background, status icons | Each mode | Local assets load; alt text/status text preserves meaning | Not run | Not run | |
| CSS-01 | Inspect layout and colors | Each mode | Constrained enterprise layout; fallback backgrounds; visible focus | Not run | Not run | |
| ERR-01 | Request missing and forbidden resources through IIS | Each mode | Custom 404/403 pages render with working recovery links | Not run | Not run | |
| KEY-01 | Complete core tasks without mouse | Each mode | Skip link, navigation, filters, tables, form, buttons usable | Not run | Not run | |
| JS-01 | Inspect console while using every feature | Each mode | No script errors or unsupported API failures | Not run | Not run | |
| URL-01 | Open query-string details directly | Each mode | News, policy, KB detail opens correctly | Not run | Not run | |
| HTTPS-01 | Browse HTTPS URL and assets | Each mode | Trusted certificate; no mixed content; secure URL retained | Not run | Not run | |
| CACHE-01 | Change a data file and publish new release | Each mode | HTML/data refresh as configured; static assets use bounded cache | Not run | Not run | |
| AUTH-01 | Future Windows Authentication behavior | Each mode | Identity and denial enforced server-side | Deferred | Deferred | Phase 2 only |

## Additional checks

- Confirm Enterprise Mode Site List entry and version are active.
- Confirm IE11 document mode rather than legacy IE7/IE8 emulation.
- Confirm no `fetch`, Promise, ES6 syntax, ActiveX, plugin, or external request appears.
- Disable public internet access and repeat the smoke test; the site must remain usable.
- Review IIS logs for unexpected status/substatus codes and failed asset paths.
- Inspect focus visibility, labels, fieldsets/legends, captions, status text, and error announcements.

## Defect record

For each failure record ID, environment, exact URL, steps, expected/actual result, screenshot/log reference, severity, owner, workaround, target release, and retest outcome. Do not close an IE-mode defect using normal-Edge evidence alone.
