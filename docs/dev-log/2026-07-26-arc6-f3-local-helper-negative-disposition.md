# Arc 6 F3 — negative disposition: local helper preflight

**Date:** 2026-07-26
**Disposition:** `F3_PRELAYOUT_FAILURE_NO_RETRY`

## Authorization and source

The owner approved exactly one local F3 provenance smoke at source SHA
`b1cf4d5dac50db43013e1c84c2911a3f6cb37855`. It ran from a clean detached
worktree using the repaired packet-shaped relative output path.

## Evidence

The exact invocation stopped before `f3r_layout()` with:

```text
Error: Required private helper(s) unavailable: drm_pair_general_eta_sandwich
Execution halted
```

The requested `attempt-001` directory is absent. No data, margin fit,
association fit, sandwich, status file, or provenance receipt exists.

## Root cause

`f3r_preflight()` checks helper availability in `asNamespace("drmTMB")`
before `f3r_load_local_namespace()` loads the approved local package source.
The installed namespace does not contain
`drm_pair_general_eta_sandwich`, although the checked-out source does.

This is a runner lifecycle-contract defect, not a likelihood or inference
result.

## Stop rule

The one authorized invocation is consumed. No retry, namespace workaround,
path substitution, runner repair, F4 work, remote compute, or public claim was
performed.

## Required next decision

A fresh owner-approved repair plan must decide how the runner validates private
helpers from the already pinned local source without allowing an installed
namespace substitution. It needs a regression test that proves the literal CLI
can reach the local-namespace loading boundary. A later replacement F3 attempt
requires a new source SHA and a separate one-shot approval.

## Scope

This covers only a negative private F3 pre-layout provenance disposition for
the fixed-effect complete-pair Bernoulli × ordinary-NB2 route. It does NOT
cover successful F3 provenance, uncertainty validity, F4, public inference,
other pairs, or Arc D/F5.
