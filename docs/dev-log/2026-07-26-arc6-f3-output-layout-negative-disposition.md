# Arc 6 F3 — output-layout preflight negative disposition

## Event

On 2026-07-26, the one approved F3 Bernoulli x ordinary-NB2 provenance smoke
was invoked exactly once from a clean detached worktree at
`af2fb9ead5fc9a48d68af8965e34db79e71bf551` with the approved literal CLI and
immutable relative output path.

## Result

The invocation failed before data generation, fitting, or receipt creation.
`f3r_layout()` calls `dir.create()` without `recursive = TRUE`; the approved
nested `docs/dev-log/smoke/.../attempt-001` parent path did not exist, so the
layout and subsequent log-file opening failed. The attempted directory,
`input/dataset.rds`, and `status.csv` are absent.

## Consequence

This authorization is consumed. There is no retry, no alternate output path,
no manual parent-directory creation, no F4 work, and no public inference or
API exposure.

## Required Next Decision

A separately approved documentation-and-test-backed repair may make the
immutable layout creator establish the canonical parent path consistently while
preserving the SHA-pinned, one-attempt, no-overwrite contract. A later F3 run
would require another fresh written approval naming its new source SHA.
