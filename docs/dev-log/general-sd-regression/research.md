# General SD regression: primary-source research (P1a)

Date: 2026-10-17  
Scope: evidence relevant to fixed-predictor regressions for latent-effect standard deviations, structured latent covariance, integration accuracy, and uncertainty calibration. This combines preparatory primary-source curation with a bounded NotebookLM review. It makes no novelty or blanket capability claim.

## Research status

The initial CLI and MCP checks reached signed-out sessions. After Shinichi confirmed reconnection, the Chrome UI verified the personal account and created [the methods notebook](https://notebook.google.com/notebook/ba2c9230-8be5-48fe-bd50-823c68e27da6) on 17 October 2026. Notebook UUID: `ba2c9230-8be5-48fe-bd50-823c68e27da6`. Only public sources were imported. No collaborator data or examples were used.

Thirteen distinct URLs were submitted once, without automated research ingestion. Two imported pages were titled `Just a moment...`; both were excluded from the corrected review. Eleven sources were selected for the correction query and report. This count does not imply eleven full texts: several publisher imports expose abstracts or metadata. The full glmmTMB covariance guide was inspected in the notebook, and the Stringer preprint abstract, TMB density documentation and MIXREGLS publisher record were checked directly through primary/official pages. The independently curated 11-row ledger below is a separate corpus, not an assertion that every row was imported successfully.

The first notebook response overstated identifiability, quadrature precision and interval calibration. Those claims were challenged explicitly. The corrected response withdrew the blanket single-Bernoulli-observation rule, universal node counts, finite-order exactness, automatic calibrated intervals and mathematical failure of quadrature for crossed effects. The original response remains in notebook history as rejected research output. The corrected response remains triage: its statements about eliminating bias as node count increases are still too broad to adopt without regime-specific evidence. The document report and 1:53 short audio overview completed from the 11 selected sources. Direct readback of the report found invented numerical thresholds, a proposed forced five-node default, automatic formula rewriting and an unsupported claim to authority. The report was renamed `REJECTED DRAFT: SD regression methods audit (invented thresholds)`. None of those recommendations are accepted. The audio remains unreviewed and is not implementation evidence.

The review therefore supplies a useful list of checks and missing evidence. It does not supply a general identifiability theorem or a calibration certificate.

## Synthesis for the architecture contract

Let `W_g` be the fixed design row for group `g`, `alpha` the SD-regression coefficients, and `tau_g = exp(W_g alpha)`. If `u` has an admitted base covariance `C` and `b = D_tau u`, where `D_tau = diag(tau)`, then

\[
  \mathrm{Cov}(b) = D_\tau C D_\tau.
\]

For an existing structured provider represented by `C = K \otimes R`, the corresponding construction is `D_tau (K \otimes R) D_tau`. This is a diagonal congruence: positive `tau_g` preserves positive semidefiniteness of an admitted `C`. It does not prove that a given `K`, `R`, or provider is itself valid, normalized, or identifiable. Those remain provider-specific obligations. In particular, if the provider already contains a free global scale, the SD intercept can be confounded with that scale unless the decomposition is constrained. This is a mathematical design consequence, not a result established by the cited software papers.

The closest methodological precedents are mixed-effects location-scale models, where covariates enter log variance or scale models. Hedeker et al. (2008) demonstrate covariate effects on within-person variability and a random scale term in an intensive longitudinal Gaussian application; Hedeker and Nordgren (2013) describe log-linear predictors for between- and within-subject variance in `MIXREGLS`. These establish that covariate-dependent scale components are a studied model class. They do not establish identifiability, recovery, or inferential validity for every drmTMB response family or latent provider. For this package, the core source of information for `alpha` is replication across latent groups with variation in `W_g`; collinearity, a narrow covariate range, too few groups, near-zero latent variation, or separation/rare outcomes can weaken it. These are design-based expectations to be tested, not universal literature thresholds.

Structured covariance precedent in glmmTMB shows that multiple covariance families can share a common fitting framework, but it also demonstrates that factor coding and model-matrix construction can change the implied covariance dimension. The drmTMB contract should therefore bind each provider to an explicit base covariance `C`, its normalization and parameter map, the dimension of `D_tau`, and the exact group/latent ordering. Positive SD scaling must not silently alter the provider's existing correlation or normalization semantics.

TMB's marginal likelihood machinery uses automatic differentiation and a Laplace approximation over latent random effects. The discrete-response GLMM literature shows that Laplace accuracy depends on the data/model regime; adaptive Gauss-Hermite quadrature (AGQ) can improve accuracy for low-dimensional group-level effects but its cost grows rapidly with latent dimension. This supports an independent high-order integration oracle for scalar or otherwise tractable fixtures and explicit approximation-sensitivity reporting. It does not justify treating a single quadrature order, Laplace fit, or an external package's estimate as exact for all cells. Compare objective values and key parameter estimates across increasing quadrature orders, and state approximation tolerances before production.

Uncertainty for scale parameters needs boundary-aware evidence. Variance components have parameter-space boundaries, so standard regular likelihood-ratio reference distributions may fail; Sinha (2009) studies parametric bootstrap tests for zero variance in GLMMs. This supports checking type-I error near the null when such a test is exposed, but it does not validate confidence-interval coverage for `alpha`. Profile likelihood and parametric bootstrap should be evaluated as separate interval routes where drmTMB advertises them. Calibration should include ordinary and near-boundary SD regimes and report all fit attempts, failed fits, boundary flags, empirical coverage, interval width, and Monte Carlo uncertainty. Do not generalize one interval route's results to another.

## Evidence-to-claim map

| Design question | Evidence-supported conclusion | Limit or required package evidence |
| --- | --- | --- |
| Is predictor-dependent scale a coherent model class? | Location-scale mixed models explicitly put covariates in scale/variance submodels. | Existing precedents focus on particular Gaussian longitudinal settings; test each response/provider combination in drmTMB. |
| Can a scalar SD predictor coexist with structured base covariance? | Multiplying an admitted base covariance on both sides by positive diagonal SD matrices preserves positive semidefiniteness. | Provider normalization, scale confounding, dimensions, ordering, and parameter constraints require cell-specific proofs/tests. |
| Is Laplace an exact integration oracle? | No. It is an approximation; accuracy varies by model and information regime. | Use higher-order quadrature or another independent numerical reference where feasible; declare when a high-dimensional oracle is unavailable. |
| Is one quadrature order sufficient? | Not established. AGQ is a useful low-dimensional reference and is more costly as dimension grows. | Demonstrate stabilization over increasing orders on selected fixtures; do not extrapolate to high-dimensional providers without evidence. |
| Are Wald/profile/bootstrap intervals interchangeable? | No. Boundary behavior and small-sample calibration can differ. | Calibrate each public interval route and preserve flags; bootstrap test evidence does not equal interval evidence. |
| Does software precedent establish drmTMB support? | No. TMB, glmmTMB, and lme4 provide implementation precedents and useful oracle candidates. | Require drmTMB's own deterministic tests, recovery evidence, calibration, and explicit per-cell disposition. |

## Gates and next work

P1a source curation and a bounded NotebookLM query/challenge cycle have been performed. The account blocker is resolved for the Chrome UI; CLI/MCP authentication was not changed. Primary-source limits, rejected claims and pending generated-artifact readback remain explicit. G1 stays open until independent mathematical/interface review and the cell-specific validation contract are accepted.

The next evidence gate should bind each source claim to a named model decision: (1) exact SD design-matrix/coding and group-constant rules; (2) provider base-covariance normalization and scale-confounding constraints; (3) integration oracle and order-stability tolerances; (4) the inference claims that receive coverage/type-I calibration. No novelty or blanket capability claim follows from this research note.

## Sources

Full source metadata, relevance, and limitations are in [`research-sources.tsv`](research-sources.tsv). The list contains 11 independently checked primary or official sources. Publisher and official project pages were used where available; the arXiv preprint is clearly identified as such.


## Identifiability correction retained from the challenge

For one outcome per independent group, the marginal Bernoulli probability is
`E[h(X beta + s U)]`, with `U ~ N(0,1)`. Identifying shared scale coefficients
from this probability is different from recovering an individual group draw.
A one-bit description of the response does not prove a general impossibility.
For a probit link with constant `s`, the normal-convolution identity gives
`P(Y=1|X)=Phi(X beta/sqrt(1+s^2))`. With all fixed coefficients free, this
exhibits a specific scale confounding. It is our algebra, not a theorem
provided by the notebook for every logit or predictor-dependent-SD design.
Replication supplies within-group dependence information, but full-rank SD
predictors alone do not prove identifiability. The existing all-singleton
random-effect refusal requires a separate family/design audit in the breadth
phase; it must not be cited as mathematical evidence for exclusion.

## Directly verified primary/official support

- [Stringer, arXiv v2 (11 November 2024)](https://arxiv.org/abs/2310.01589):
  the abstract separates an exact gradient of an approximate likelihood from
  exact integration and reports simulation evidence for selected grouped
  Bernoulli designs. Its coverage findings are not a package-wide guarantee.
- [TMB density namespace](https://kaskr.github.io/adcomp/namespacedensity.html):
  provides vector scaling, separable distributions and Gaussian projection.
  This supports available implementation primitives, not identifiability.
- [glmmTMB covariance guide](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html):
  shows model-matrix coding and explicit examples of redundant covariance
  parameters. Existing provider scaling remains a drmTMB code obligation.
- [MIXREGLS](https://www.jstatsoft.org/article/view/v052i12): software/methods
  precedent for location-scale modelling; it does not validate generalized
  SD regression in this programme.
