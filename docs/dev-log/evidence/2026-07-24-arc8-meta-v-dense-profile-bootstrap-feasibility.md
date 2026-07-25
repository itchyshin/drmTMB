# Arc 8 local dense direct-SD profile/bootstrap feasibility

**Status:** local engineering evidence only. This receipt does not establish
recovery, interval calibration, coverage, a capability tier, or authorization
for Totoro/DRAC work.

## Frozen source and session

- source SHA: `b067e982ed1c4f4b8a7e2919aa4cda044e0fe506`
- host: macOS 26.5.2; R 4.6.0; drmTMB 0.6.0.9000; TMB 1.9.21
- model: Gaussian ML `bf(yi ~ x + (1 | study) + meta_V(V = V), sigma ~ z,
  sd(study) ~ z_study)`
- known sampling covariance: dense, `sampling_rho = 0.20`
- targets: `fixef:sd(study):(Intercept)` and `fixef:sd(study):z_study`
- profile procedure: `confint(..., method = "profile",
  profile_engine = "tmbprofile", profile_precision = "fast")`

## Deterministic K ladder

One retained fit was run per cell with two effects per study, two observations
per effect, and seeds `2026072520`, `2026072544`, and `2026072580` for K = 12,
36, and 72 respectively. Both profile endpoints were finite and ordered in
each row.

| K | Target | 95% profile-LR interval | Profile status |
| ---: | --- | --- | --- |
| 12 | intercept | [-1.1834, -0.2852] | profile |
| 12 | `z_study` | [-0.3442, 0.4699] | profile |
| 36 | intercept | [-1.1244, -0.5617] | profile |
| 36 | `z_study` | [-0.0079, 0.4634] | profile |
| 72 | intercept | [-1.2729, -0.8666] | profile |
| 72 | `z_study` | [-0.0967, 0.3615] | profile |

## Bootstrap completion sidecar

The K = 36 fixture (`seed = 2026072544`) used a joint `R = 199` parametric
bootstrap with `seed = 2026072601` and serial refits. Each target had 199/199
finite successful draws (`conf.status = "bootstrap"`), so each met the Arc 8
95% completion threshold. The diagnostic table contained 398 target-refit rows,
all with `refit_status = "ok"`.

## Interpretation and retained failure control

This ladder proves only that a predeclared dense fixture can complete both
full-profile targets and the bootstrap refit accounting. It does **not** erase
Arc 7B's source-pinned K = 12 dense control, where both targets had
`nonfinite_interval` endpoints. The fixtures use different seeds and are not
replicates of the Arc 7B sentinel. The original failure remains in the next
Arc 8 sentinel and its all-attempt denominator.

No recovery or coverage campaign has run. Before any separate compute request,
Arc 8 still needs committed runner integration, a source-pinned sentinel that
retains the historical failure cell alongside the interior ladder, and fresh
Fisher/Rose review.
