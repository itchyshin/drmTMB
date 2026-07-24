# Arc 7B local sentinel — known-`V` heterogeneity ladder

**Status:** LOCAL EVIDENCE ONLY — DRAC coverage campaign **NO-GO**.

This receipt records a deterministic, one-replicate-per-cell smoke run from
`codex/arc7b-meta-v-heterogeneity-ladder`. It does not estimate recovery,
interval calibration, coverage, or a capability tier.

## Frozen run

```r
phase18_run_meta_v_lss_smoke(
  n_rep = 1L,
  master_seed = 2026072407L,
  cores = 1L,
  backend = "none"
)
```

The runner retains every scheduled result, including an error, non-finite
profile endpoint, or failed Hessian. Its all-attempt reducer treats a failed
outer fit or incomplete endpoint as zero in the eligible
usable-and-covering denominator. Its six cells were run individually so the
dense-profile calculation could not hide a slow or failed cell behind a batch
timeout.

| Cell | Layer | Design role | Fit status | `pdHess` | Profile result |
| --- | --- | --- | --- | --- | --- |
| 1 | LS | one effect per study | `ok` | TRUE | 4/4 direct targets finite |
| 2 | LSS | weak 12-study boundary | `ok` | TRUE | 6/6 direct targets finite |
| 3 | LSS | interior control | `ok` | TRUE | 6/6 direct targets finite |
| 4 | LSSS | nested-effect control | `ok` | TRUE | 8/8 direct targets finite |
| 5 | LSS | dense known-`V` control | `ok` | TRUE | 4/6 finite; both `sd(study)` coefficients `incomplete`, `nonfinite_interval` |
| 6 | DH | sigma-side random-effect sensitivity | `ok` | TRUE | 4/4 fixed targets finite; random sigma SD intentionally has no pre-registered profile target |

The DH extractor returned a response-scale sigma-side random-effect SD of
0.1808 for a truth of 0.20. This is distinct from the direct-SD study
coefficients, which are log-SD regression coefficients. It is one smoke draw,
not a recovery result.

## Oracle and comparator gates

The focused test suite passed the following independent checks:

- diagonal LS: the `metafor::rma(..., scale = ~ z, method = "ML")` likelihood,
  location coefficients, and scale coefficients match `drmTMB`; the
  `metafor` log-variance coefficients are divided by two, not squared;
- dense LSS: the fitted ML log likelihood matches an R marginal Gaussian
  oracle using `V + diag(sigma^2) + Z_s diag(tau_s^2) Z_s'`;
- diagonal nested LSSS: the same oracle matches after adding the genuinely
  nested, replicated effect-level direct-SD covariance term.

`metafor` is not a dense predictor-dependent-scale comparator: `rma.mv()`
disregards its `scale` argument. The dense and multilevel checks above therefore
use the direct oracle rather than treating diagonal agreement as evidence.

## Decision

The dense LSS direct-SD profiles are incomplete in the local sentinel. The
campaign gate requires finite, method-complete endpoints before a full
all-attempt calibration denominator is meaningful. Fisher and Rose therefore
returned NO-GO: no DRAC job was submitted, no fallback procedure was
substituted, and no reader-facing capability statement was added. A future
compute request must first repair or explicitly narrow that profile target,
add the predeclared profile-engine cross-check and bootstrap-completion check,
re-run this sentinel, and obtain fresh Fisher and Rose approval.

No GitHub Actions simulation or artifact upload occurred. Draft PR #828 is a
separate B0 branch and remains unmerged.
