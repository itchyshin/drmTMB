# After-task — Wave 3: optimizer escalation

Date: 2026-06-16
Branch: `codex/honesty-guards`

## Why this wave

The audit (and Hao Qin's artificial-convergence concern) found the optimizer
machinery had a reachability gap: `drm_optimize_with_preset_retry` accepted the
first preset that did not throw an R error, regardless of `opt$convergence`, so
the `careful`/`robust` presets only ever ran on a thrown error -- never on a
false convergence, the case they exist for. Wave 3 makes the ladder escalate on
non-convergence and adds two opt-in robustness tools.

## Slices (each its own commit)

- **C1 -- escalate on non-convergence** (`84fc213b`). A successful optimizer
  attempt is now returned early only if it cleanly converged (code 0, finite
  objective); otherwise it is kept as a candidate and the next preset is tried.
  If no preset converges, the best (lowest-objective) candidate is returned so
  the fit-time convergence warning flags it; an all-errored ladder still aborts.
  A clean first attempt is unchanged (no escalation). The
  escalation-to-converge notice replaces the old retry-after-error message
  (snapshot updated); the convergence-warning advice now points to
  `fit$optimizer_attempts` rather than a manual `robust` refit.
- **C2 -- opt-in multi-start** (`9f0eb043`). `drm_control(multi_start = K)` runs
  each preset from K starting points (principled + K-1 reproducibly perturbed,
  fixed internal seed with the caller's RNG stream saved/restored) and keeps the
  lowest-objective result. `multi_start = 1` (default) is the single-start fit,
  bit-identical to before.
- **C3 -- opt-in fallback optimizer** (`58c53782`).
  `drm_control(fallback_optimizer = "BFGS" | ...)` tries an `stats::optim`
  method as a final attempt when no `nlminb` preset converges. Off by default.

## Design decisions

- **C1 default-on; C2/C3 opt-in.** C1 is the core correctness fix (the ladder
  must be reachable). C2/C3 are robustness tools that add optimizer attempts, so
  they default off -- the default fit pays no extra cost. C1's escalation does
  make a genuinely non-converging fit slower (it tries the ladder), which is the
  intended trade (a converged or best-effort fit over a silent false
  convergence); sims must match production, so escalation is not disabled for
  them.
- **Injectable optimizers for testing.** `optimizer` (nlminb) and `fallback_fn`
  (optim) are injectable, so escalation, multi-start selection, and the fallback
  are all driven deterministically by fake optimizers -- no reliance on a
  platform-dependent real non-convergence.

## Verification

Per slice: deterministic fake-optimizer unit tests
(`test-optimizer-escalation.R`, `test-multi-start.R`) + `test-control.R`
regression + the `optimizer-contract` snapshot. C1 was additionally checked
against the full deliberately-hard test set (the combined Wave2+C1 suite:
FAIL=0, PASS=11132) to confirm escalation does not disturb the q4/q8/scale-phylo
tests. The wave-level suite (full minus the 4 render tests) then caught that C2
had dropped the `multistart` reserved-name typo guard
(`test-optimizer-contract.R`, 2 failures); restored in `34004cea`. With that fix
the optimizer-contract, control, escalation, and multi-start suites are FAIL=0,
and the consolidated Wave 3+4 wave-level suite is the final gate.

## Not done / deferred

- A "scaled gradient tolerance" beyond nlminb's own convergence criterion was
  considered but not added: `check_drm()` already reports a fixed-gradient check,
  and a stricter accept-criterion risks rejecting fits nlminb accepted.
- Multi-start uses a fixed perturbation scale (sd 0.5 on the unconstrained
  parameter scale) and a fixed seed; a user-tunable scale/seed can follow if
  needed.
