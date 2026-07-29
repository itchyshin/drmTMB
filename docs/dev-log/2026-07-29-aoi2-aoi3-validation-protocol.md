# AOI-2/AOI-3 prospective validation protocol

## Status

**PLAN ONLY — NOT AUTHORIZED FOR SMOKE, DRAC, OR PUBLIC INFERENCE.**

AOI-1 exposes full fixed-effect point estimation and point prediction only for
frozen-margin literal Bernoulli × ordinary-NB2 `associate_pairs()` fits. This
packet neither promotes a capability nor authorizes a compute job. It inherits
the Lane-A-only boundary and design-244's developer-only sandwich contract.

## AOI-2: point-recovery proposal

The preregistered grid must contain exactly these association designs before
any expansion:

1. additive numeric: `~ x1 + x2`;
2. mixed design: `~ x1 + habitat`;
3. interaction: `~ x1 + habitat + x1:habitat`.
4. numeric interaction: `~ x1 + x2 + x1:x2`;
5. transformation: `~ x1 + I(x2^2)`.

All cells use literal Bernoulli and ordinary-NB2 margins, complete paired rows,
fixed-effect ML margins, `kernel = latent_normal()`, and declared alpha. The
reverse margin order is a deterministic comparator, not a new family claim.

Retain every attempt: seed, design ID, formula/design fingerprint, status,
alpha, fitted-grid eta, and every unavailable reason. Point evidence reports
coefficient-wise and eta-grid bias/RMSE only; it reports no SE, interval, or
coverage result.

Before any run, freeze code SHA, DGP, encoding, fixture/oracle, seeds, controls,
failure taxonomy, and analysis script. Then obtain owner approval for one local,
non-empty smoke. Only after its receipt and separate owner approval may a DRAC
array run. Totoro and GitHub Actions are not substitutes for that decision.

## AOI-3: uncertainty-validation proposal

### Deterministic pre-gate

For every AOI-2 formula class independently verify association score and mixed
derivatives against stable finite-difference oracles; bread/meat/dimensions and
coefficient labels; response-order invariance; stored design provenance; and
delta gradients for prespecified `eta(newdata)` rows. Test unavailable boundary,
provenance, derivative, non-finite, and bread-conditioning states. This freezes
the private multi-column sandwich contract; it does not implement public
`vcov()`.

### Comparator and required outcomes

The comparator is **complete full-refit parametric resampling**. Each replicate
simulates a paired outcome, refits both margins, rebuilds its design, and refits
association. It must not condition on fitted margins, reuse stage-2 curvature,
drop an unsuccessful replicate, or substitute a failed interval.

| Target | Required all-attempt diagnostics |
| --- | --- |
| alpha | availability, bias, empirical versus private covariance, median and mean SE/SimSE, marginal coverage |
| covariance | empirical versus estimated covariance/correlation, PSD status, coefficient-order audit |
| `eta(newdata)` | link/response delta variance versus empirical variance and marginal coverage at fixed new-data rows |
| failure | unavailable/boundary/derivative/provenance causes retained in denominators; unavailable intervals are non-covering |

Marginal and simultaneous coverage are distinct targets; coefficient-wise
success never implies a simultaneous claim.

### Mandatory calibration hierarchy before AOI-3 authorization

An AOI-3 executable specification must freeze this hierarchy before any smoke:

- **outer datasets:** independent DGP draws with known alpha and fixed declared
  covariate/design regime; the outer all-attempt denominator is every generated
  dataset, including failed margin or association fits;
- **inner resamples:** for each eligible outer fit, complete full-refit
  parametric resamples with a separately retained all-attempt denominator;
- **interval construction:** exact link-scale and response-scale rules, plus
  handling of each unavailable covariance/interval state;
- **coverage:** calculated across outer datasets against the known DGP truth,
  never across inner resamples or a plug-in fitted truth.

The outer-cell domain must include interior and near-boundary association
strengths, factor balance, predictor correlation, margin effect/dispersion, and
sample-size regimes. It must also predeclare the number of outer datasets,
inner resamples, availability threshold, and finite calibration tolerances.
Until that owner-reviewed specification exists, AOI-3 is not executable.

## Grounded methods-review receipt

An external drmTMB-excluded NotebookLM corpus was created on 2026-07-29
(`e931c0f0-445d-4993-946d-bafc097f5313`; 10 sources). It supports a
conservative validation protocol, not a novelty claim:

- Small or information-unbalanced estimating-equation settings can give poorly
  calibrated sandwich Wald inference, motivating coefficient-wise finite-sample
  diagnostics ([Fay & Graubard, 2001](http://www.stat.yale.edu/~lc436/papers/Fay_Graubard2001.pdf);
  [two-stage sandwich guidance](https://pubmed.ncbi.nlm.nih.gov/38012109/)).
- Vector delta uncertainty requires the full covariance and a Jacobian, and a
  stable interior optimum is a precondition rather than calibration proof
  ([Implicit Delta Method](https://arxiv.org/pdf/2211.06457)).
- Repeated complete refits are the relevant expensive comparator for a two-stage
  estimator ([clarify methods review](https://journal.r-project.org/articles/RJ-2024-015/RJ-2024-015.pdf)).

The sources do not establish an AOI correction, universal pass band, or valid
interval for this estimator. Freeze numerical targets, resampling count, and
comparator details only in a later owner-reviewed AOI-3 specification.

Research query: “finite-sample validation of multi-parameter two-stage or
plug-in estimators using sandwich/Godambe covariance”, with requirements for
coefficient covariance, all-attempt coverage, delta predictions, and complete
full-refit comparison; drmTMB sources were explicitly excluded. Retrieved
2026-07-29; all automatically discovered material is **UNVERIFIED triage**
until primary-source review. Manifest: [two-stage sandwich](https://pubmed.ncbi.nlm.nih.gov/38012109/),
[bias-corrected GEE covariance](https://pubmed.ncbi.nlm.nih.gov/17825023/),
[Fay and Graubard](http://www.stat.yale.edu/~lc436/papers/Fay_Graubard2001.pdf),
[Implicit Delta Method](https://arxiv.org/pdf/2211.06457),
[clarify](https://journal.r-project.org/articles/RJ-2024-015/RJ-2024-015.pdf),
[pairwise composite likelihood](https://arxiv.org/html/2607.06142v1),
[finite-sample penalized GEE](https://arxiv.org/pdf/2604.18863),
[estimation notes](https://web.pdx.edu/~fountair/seminar/Estimation%20v%202.pdf),
[causal-model parameterization](https://ora.ox.ac.uk/objects/uuid:be112194-b9a5-466f-9529-34b93cbe7e73/files/rj098zc39j),
and [dadi uncertainty guidance](https://dadi.readthedocs.io/en/latest/user-guide/uncertainty-analysis/).

## Owner decisions required

1. Approve/revise the AOI-2 formula classes and a local non-empty smoke.
2. After its receipt, approve or decline the DRAC point-recovery campaign.
3. After AOI-2 plus deterministic sandwich gates, approve an AOI-3 calibration
   specification with finite targets and full-refit resource budget.
4. Only a successful AOI-3 claim review may propose public uncertainty; failure
   leaves AOI-1 intact and uncertainty unavailable.
