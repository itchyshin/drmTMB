# Arc 6 F3 — plan versus actual: output-layout preflight

## Plan

Run one approved F3 provenance smoke from a clean detached source SHA and
audit the immutable output; F4 remained excluded.

## Actual

The exact command ran once after SHA/blob/output-absence checks. It failed when
`f3r_layout()` attempted non-recursive creation of the absent canonical nested
path. No output directory, data, fits, or receipt was created.

## Reconciliation

**Adaptive:** the audit became a pre-layout negative disposition. **No drift:**
there was no retry, directory pre-creation, runner modification, F4 work, or
public inference. **Next decision owner:** Shinichi must approve a narrow
layout-contract repair and then separately approve any replacement F3 attempt.
