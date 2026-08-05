# Smoke — mc-0568 × seed 21260806

**Result: PASS** (2026-08-05, worktree `cursor/135-trace-campaign` @ `56449fd64`).

```
SMOKE_PASS cell=mc-0568 seed=21260806 brackets=TRUE rel_err=0.1381
CI=[0.2991, 0.5179] clamp=FALSE boundary=FALSE engine=endpoint status=profile
```

- Truth 0.45 is inside the interval; relative error 0.138 ≤ 0.35.
- `clamp_limited` computed from `profile.message` (not hard-coded).
- **Engine note:** default `confint(fit, method="profile")` used
  `profile.engine=endpoint`. The campaign preregistration requires the
  **grid** engine for recorded endpoints (clause 6 / scoping §4). The full
  runner must pass `profile_engine = "grid"` (or equivalent) explicitly;
  endpoint remains the independent cross-check only.
