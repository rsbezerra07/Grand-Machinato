# Compatibility Matrix

This is an implementation expectation, not a claim of completed browser certification.

| Area | Edge normal mode | Edge IE mode / IE11 document mode | Older enterprise modes | Fallback / note |
|---|---|---|---|---|
| Page layout | Expected | Targeted; requires managed Windows test | Best effort only | Floats, inline-block, explicit widths, normal flow |
| Header/navigation | Expected | Targeted | Best effort | Menu button exposes left navigation at narrow widths |
| Search/filter/sort | Expected | Targeted | Not certified | ES5, native events with `attachEvent` fallback |
| Service Desk validation | Expected | Targeted | Not certified | Native controls; summary plus field errors |
| Tables | Expected | Targeted | Best effort | Bounded horizontal scroll at narrow widths |
| Tabs | Expected | Targeted | Best effort | Content remains present in the document |
| Printing | Expected | Targeted | Requires printer/preview testing | Print stylesheet removes navigation and actions |
| PNG/JPEG/GIF/ICO | Expected | Targeted | Expected | No required SVG |
| Local JavaScript data | Expected | Targeted | IE8 not supported | No `fetch`, Promise, module, or JSON request required |
| CSS gradients | Enhanced | Enhanced if supported | Flat background | Solid color declared before gradient |
| Responsive adjustments | Expected | Targeted | Best effort | Simple media queries; primary target is desktop |
| Custom IIS errors | IIS dependent | IIS dependent | IIS dependent | Test through deployed URL, not `file://` |
| Windows Authentication | Future | Future | Future | Must be enforced and tested server-side |

## Explicit exclusions

No CSS Grid, required Flexbox, CSS variables, service workers, Web Components, ActiveX, VBScript, Silverlight, Java applets, browser plugins, local-storage-only workflow, or ES6 syntax is used.

## Display targets

Execute visual checks at 1024×768, 1280×720, 1366×768, and 1920×1080. At 1024 pixels, confirm the constrained layout remains readable and tables scroll within their container rather than hiding columns.
