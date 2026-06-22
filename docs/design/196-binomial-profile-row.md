# Binomial Profile Row

Slice S043 records profile feasibility for the fixed-effect binomial first
slice. It separates three facts:

- `profile_targets()` exposes fixed-effect `mu` targets as direct and
  profile-ready;
- `confint(method = "profile")` still requires explicit `parm` names, so the
  default call does not guess profile targets;
- an explicit low-budget target can return a structured `profile_failed` row
  with `profile.message = "nonfinite_interval"`.

This is target-scope and failure-status evidence, not profile interval
promotion. A broader grid with non-boundary examples and operating-characteristic
checks is needed before binomial profile intervals become a public claim.
