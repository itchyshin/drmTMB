# Arc 6 F3R — plan versus actual: output-layout preflight repair

## Plan

Repair the output-layout contract only, retain the canonical-path and
no-overwrite guards, test the literal approved CLI with absent parents, then
stop before F3.

## Actual

The layout creator now uses recursive creation after the existing preflight;
the regression validates the literal relative CLI path, starts with no parents,
and verifies the canonical attempt path plus its five subdirectories. No runner
was invoked.

## Reconciliation

**No scope drift:** no data, fits, receipts, retry, F4, public inference, or
API work occurred. **Next decision owner:** Shinichi must separately approve
exactly one F3 attempt at the newly committed source SHA.
