# GM-G0-TEST-002 — Firewall VM creation

## Objective

Create GM-FW01 with the planned Hyper-V resources and network adapters.

## Expected result

- VM name: GM-FW01
- Generation: 2
- vCPU: 2
- RAM: 2 GB fixed
- Disk: 16 GB
- ISO mounted
- WAN connected to GM-WAN
- Internal adapters connected to their expected switches

## Actual result

Pending execution.

## Negative test

Re-running creation must not overwrite an existing VM.

## Evidence

Pending.

## Rollback

Remove the unconfigured test VM and its disk only after verifying the target paths.

## Commit

Pending.
