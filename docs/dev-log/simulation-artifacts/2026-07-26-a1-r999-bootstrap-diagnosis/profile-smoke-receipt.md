# Profile-versus-bootstrap smoke receipt

Date: 2026-07-26
Host: Totoro
Purpose: validate scalar-A1 target extraction and all-attempt output plumbing.

`launch_profile_smoke.sh` ran exactly three outer attempts, one for each
pre-registered group-count cell, with `R = 19` marginal bootstrap refits. All
three fits had convergence code zero and `pdHess = TRUE`. The scalar target was
found once for each method; bootstrap, profile, and Wald rows were all finite
and valid. `profile_engine = "endpoint"` and `profile_boundary = FALSE` for
each smoke fit.

Authenticated Totoro files:

```text
a1_profile_common.R       083949bf1868d32a771b7124443f05f44a354b70598cd1703b2c2007a7731435
profile_vs_bootstrap.R    7dc63ca348c5df42519aa30e58066a8387b3bdfa9f62b2a8d2d4fd69aaf45cfc
launch_profile_smoke.sh   8575649f3f9d3da5624314e6f334df9abe3cd6a6af512676dc072dd99fbfbb4f
```

The output lives at `~/drm_work/a1_profile_smoke_20260726/` on Totoro. This
receipt authorizes no full coverage work. It only removes runner and target
extraction as blockers to the separate compute-approval decision.

The smoke used Totoro's installed `drmTMB` 0.6.0 build
(`R 4.5.3; x86_64-pc-linux-gnu; built 2026-07-26 02:00:46 UTC`). It verifies
that this build accepts the frozen `refit_control` argument. It does not
authenticate a package commit; the held full campaign must set and record
`DRMTMB_COMMIT` before launch.
