# Microsoft Edge IE-mode Configuration Guide

## Responsibility boundary

The Enterprise Mode Site List is a browser-management artifact. The intranet does not read it and cannot force IE mode through HTML, JavaScript, response headers, or user-agent logic. Edge policy administrators decide which URL opens in IE mode.

The project targets standards-based IE11 document mode inside Edge IE mode. Do not select IE7/IE8 emulation unless a separately assessed legacy dependency genuinely requires it.

## Sample XML

`../config/sample-enterprise-mode-site-list.xml` uses the Enterprise Mode Site List schema v2 shape with:

- a numeric `site-list` version;
- `created-by` metadata;
- placeholder host `intranet.grandmachinato.example/legacy/`;
- `compat-mode` set to `Default`;
- `open-in` set to `IE11`.

It is a sample, not a production policy. Create or validate the final list with the applicable Microsoft Enterprise Mode Site List tooling and current organizational browser standards.

## Controlled rollout

1. Copy the sample to the browser-management repository, not the application logic.
2. Replace the placeholder host and path with the approved HTTPS intranet URL.
3. Validate XML syntax and schema/tool acceptance.
4. Publish from a secure HTTPS location accessible to managed clients. Restrict modification to browser administrators and monitor integrity.
5. Configure the approved Edge policy for the Enterprise Mode Site List location.
6. Deploy to a limited test device group.
7. Confirm the active list and site entry in Edge's enterprise site-list diagnostic experience available to administrators.
8. Browse the site and confirm it opens in IE mode and uses IE11 document mode.
9. Execute `ie-mode-testing.md`, capture actual results, and resolve failures.
10. Expand deployment only after browser, security, application, and support owners approve.

## Versioning and refresh

Increment the root `version` value whenever a published list changes. Do not reuse a version for different content. Managed clients cache the list and refresh behavior is not instantaneous; allow for policy retrieval and site-list caching during testing.

When a test client appears stale:

- confirm policy application and the configured HTTPS list URL;
- confirm the server returns the new XML and version;
- use the supported Edge enterprise site-list diagnostic/refresh experience for the managed Edge version;
- if the organization permits, clear the relevant browser/site-list cache through documented administrative procedures;
- restart Edge or the test session when required by current policy guidance;
- record which action caused the new version to appear.

Do not instruct users to delete arbitrary profile files or registry data.

## Later central administration

When moving to the Microsoft Edge site-list administration experience, preserve ownership, change approval, version discipline, pilot rings, expiry/review dates, and rollback. Export or reconcile centrally managed entries so duplicate or conflicting policy sources do not create ambiguous behavior.

## Evidence to record

For each test device record Edge version, Windows version, policy source, XML version, resolved site entry, displayed IE-mode indicator, active document mode, test URL, time, tester, and result. A passing normal-Edge test does not prove IE-mode compatibility.
