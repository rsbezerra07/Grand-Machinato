# Content Update Guide

## General rules

1. Edit only fictional or formally approved content.
2. Keep data in the correct `window.GrandMachinato.Data` array.
3. Preserve ES5: use `var`, quoted strings, object literals, and traditional functions. Do not add modules, arrow functions, template literals, `let`, `const`, Promises, or `fetch`.
4. Escape quotation marks and backslashes correctly. Do not paste HTML into data fields.
5. Keep values within the existing field contract and avoid secrets, credentials, production host names, personal data, and internal URLs.
6. Test filters, detail links, print preview, keyboard use, and the browser console after every edit.
7. Change release notes/versioning through the approved deployment process.

## Data locations

| Content | File | Key fields |
|---|---|---|
| Announcements | `assets/data/announcements.js` | `id`, `title`, `category`, `department`, `date`, `priority`, `summary`, `body` |
| Applications | `assets/data/applications.js` | `name`, `description`, `category`, `owner`, `support`, `access`, `availability`, `route` |
| Directory | `assets/data/employees.js` | `name`, `title`, `department`, `office`, `extension`, `email`, `manager`, `skills` |
| Policies | `assets/data/policies.js` | `id`, `title`, `category`, `owner`, `version`, dates, `status`, `summary` |
| Knowledge | `assets/data/knowledge.js` | `id`, `title`, `category`, `updated`, `summary`, `steps`, `related` |
| Systems | `assets/data/systems.js` | `name`, `category`, `status`, `checked`, `maintenance`, `team`, `details` |
| Links/forms | `assets/data/links.js` | link and form catalog fields |

IDs referenced in query strings and `related` arrays must remain unique and stable. Internal `route` values must point to an existing file or anchor.

## Navigation and layout

Navigation is repeated in each static HTML page for direct hosting. When adding a page, update every left-navigation list and the search index if the page should be searchable. In the ASP.NET migration, move shared markup to a master/layout template.

## Announcement update

Add a new object with a unique `ann-###` ID and one of the documented categories/priorities. Use an ISO `YYYY-MM-DD` display value. Keep the summary concise and body plain text.

## Directory update

Only fictional records belong in this demonstration. A real directory must come from a server-side, authorized Active Directory service; never embed a real employee export in browser files.

## Status update

Use exactly `Operational`, `Degraded`, `Maintenance`, `Outage`, or `Unknown` so text, icon, and CSS agree. Static values are never live monitoring; retain the demonstration label until a controlled server feed exists.

## Validation checklist

Run the project quality-check script, inspect all changed pages through HTTP, test at 1024×768, run print preview, and complete the managed-Windows IE-mode cases relevant to the change.
