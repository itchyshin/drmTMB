# General SD regression: primary-source research (P1a)

Date: 2026-10-17  
Scope: evidence relevant to fixed-predictor regressions for latent-effect standard deviations, structured latent covariance, integration accuracy, and uncertainty calibration. This combines preparatory primary-source curation with a bounded NotebookLM review. It makes no novelty or blanket capability claim.

## Research status

The initial CLI and MCP checks reached signed-out sessions. After Shinichi confirmed reconnection, the Chrome UI verified the personal account and created [the methods notebook](https://notebook.google.com/notebook/ba2c9230-8be5-48fe-bd50-823c68e27da6) on 17 October 2026. Notebook UUID: `ba2c9230-8be5-48fe-bd50-823c68e27da6`. Only public sources were imported. No collaborator data or examples were used.

Thirteen distinct URLs were submitted once, without automated research ingestion. Two imported pages were titled `Just a moment...`; both were excluded from the corrected review. Eleven sources were selected for the correction query and report. This count does not imply eleven full texts: several publisher imports expose abstracts or metadata. The full glmmTMB covariance guide was inspected in the notebook, and the Stringer preprint abstract, TMB density documentation and MIXREGLS publisher record were checked directly through primary/official pages. The independently curated 11-row ledger below is a separate corpus, not an assertion that every row was imported successfully.

The first notebook response overstated identifiability, quadrature precision and interval calibration. Those claims were challenged explicitly. The corrected response withdrew the blanket single-Bernoulli-observation rule, universal node counts, finite-order exactness, automatic calibrated intervals and mathematical failure of quadrature for crossed effects. The original response remains in notebook history as rejected research output. The corrected response remains triage: its statements about eliminating bias as node count increases are still too broad to adopt without regime-specific evidence. The document report and 1:53 short audio overview completed from the 11 selected sources. Direct readback of the report found invented numerical thresholds, a proposed forced five-node default, automatic formula rewriting and an unsupported claim to authority. The report was renamed `REJECTED DRAFT: SD regression methods audit (invented thresholds)`. None of those recommendations are accepted. The audio remains unreviewed and is not implementation evidence. The independent source ledger initially contained 11 entries and now records 13 sources after the DHGLM follow-up below.

The review therefore supplies a useful list of checks and missing evidence. It does not supply a general identifiability theorem or a calibration certificate.

## NotebookLM follow-up and primary-source check

The NotebookLM MCP connection now lists the personal account's methods notebook and completed two targeted queries against its 13 submitted sources. The first new synthesis again overstated the evidence, so a challenge query asked it to distinguish the source designs from this package's SD-regression target. I checked the central claims against the primary publisher page for Joe (2008) and Stringer's arXiv preprint.

The corrected reading is conditional. Joe's study calculates asymptotic bias patterns for selected two-level discrete mixed models; its abstract says that Laplace bias depends on response discreteness, decreases with larger cluster size when present, and is often adequate even for small clusters. It does not establish a universal binary-cluster-size cutoff or report confidence-interval coverage. Stringer studies grouped Bernoulli models with constant random-effect covariance and finds that more quadrature points can improve inference in selected high-heterogeneity, small-group designs. Those results are not a calibration result for regression coefficients in `log(tau_g) = W_g alpha`, which neither paper studies. The studies address different designs and estimands, so neither cancels the other.

The exact probit-normal convolution identity remains a specific algebraic confounding example for constant random-intercept scale with one observation per independent group and freely scaled fixed coefficients. The source set does not establish the corresponding general result for logit, nor necessary and sufficient identifiability conditions for predictor-dependent SD coefficients under either link. These questions remain empirical and mathematical obligations for the Bernoulli design; one-bit intuition is not an exclusion argument.

Sources checked directly: [Joe (2008), *Accuracy of Laplace approximation for discrete response mixed models*](https://www.sciencedirect.com/science/article/abs/pii/S0167947308002533) and [Stringer, *Exact Gradient Evaluation for Adaptive Quadrature Approximate Marginal Likelihood in Mixed Models for Grouped Data*](https://arxiv.org/abs/2310.01589). NotebookLM citations are treated as navigation aids; primary-source wording controls these conclusions.

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

## NotebookLM session recheck (2026-10-18 UTC)

After Shinichi signed into the browser, the NotebookLM connector reported an
authenticated session for `itchyshin@gmail.com`. The installed CLI's separate
`auth check --test` still returned `token_fetch: false`; the connector, rather
than the CLI, was used for this review. The 13-source notebook was listed and
queried. Two `Just a moment...` pages and the suspicious DOI portal were
excluded. NotebookLM's generated answer was treated as a triage aid, not as a
source of evidence: it mixed unrelated covariance and factor-loading results
into the identifiability discussion and stated stronger conclusions than the
relevant papers support.

Direct checks of the primary sources support only bounded conclusions:

- [Joe (2008)](https://www.sciencedirect.com/science/article/abs/pii/S0167947308002533)
  evaluates asymptotic bias for selected discrete-response mixed models. Its
  abstract says the amount of response discreteness and cluster size affect
  Laplace bias, and that Laplace is often adequate even for small clusters.
  This is not an interval-coverage result and does not evaluate a regression
  for latent-effect SDs.
- [Stringer (2024)](https://arxiv.org/abs/2310.01589) studies adaptive
  quadrature for grouped mixed models, including selected difficult Bernoulli
  random-intercept/random-slope simulations. Its simulation results motivate
  checking quadrature stability and show that Laplace can be inadequate in
  some small-group, high-heterogeneity settings. They do not give a universal
  node count or calibrate coefficients in `log(tau_g) = W_g alpha`.
- [Lee and Noh (2012)](https://doi.org/10.1177/1471082X12460132) describe a
  DHGLM class that models variances of random effects as well as residual
  variance. The notebook had abstract-level access only, so this is a model
  class precedent, not verified evidence for a particular likelihood,
  identifiability condition, or inferential guarantee.

The notebook did not establish necessary and sufficient identifiability
conditions for predictor-dependent latent SDs, nor calibrated uncertainty for
their regression coefficients or SD contrasts. Those remain package-specific
mathematical and simulation obligations. No arbitrary quadrature threshold,
blanket exclusion, or interval-coverage claim is accepted from this query.

## NotebookLM calibration-design follow-up (2026-10-19)

The authenticated in-app browser showed the personal account
`itchyshin@gmail.com` and the existing 14-source methods notebook. I asked
whether its sources justified acceptance margins, replicate counts, or a
two-look rule for 97.5% profile intervals on Bernoulli predictor-dependent
log-SD slopes. The response said no: the sources do not study this SD-regression
target or prescribe those design choices. This is consistent with the direct
source audit above; NotebookLM does not supply a threshold recommendation.

The response distinguished the nominal coverage of a 97.5% fitted interval
from Monte Carlo uncertainty in its empirical coverage and warned against
choosing margins after observing look-one results. It also raised the
marginal-per-cell versus joint-grid distinction. Its proposed Pocock/O'Brien-
Fleming wording and numerical claims were not adopted; they are not justified
by the cited source corpus and require a separate statistical derivation.
Independent inference reviewers recommended treating the completed 3,000-fit
first look as exploratory if the contract changes. A candidate prospective
contract is recorded in `prospective-bernoulli-calibration-proposal.md`; the
existing frozen rule remains unchanged pending review and approval.

### Methods-review readback and Stringer source audit (2026-10-19)

The existing browser notebook is `General latent-SD regression: identifiability
and inference`, with 14 sources. Its methods-review response is useful as a
source map, but several of its broad claims need qualification. I checked the
relevant simulation description against Stringer's v2 arXiv manuscript,
Sections 4.3.1 and C.1 (Eqs. 7 and 14; Figures 1 and 15–21):
[arXiv:2310.01589](https://arxiv.org/html/2310.01589).

Stringer's Bernoulli simulation uses a random intercept and slope with a single
group-invariant covariance matrix, `Sigma = [[2, 1], [1, 1]]`. The logit
predictor has fixed coefficients `(-2.5, -0.15, 0.1, 0.2)`, a binary
group-level covariate split evenly across groups, and a within-group covariate
on an equally spaced grid from -3 to 3. The grid crosses 100, 200, 500, or 1,000
groups; 3, 5, 7, or 9 observations per group; and 1, 3, ..., 25 adaptive
quadrature points, with 1,000 datasets per cell. The study reports bias and
Wald-interval coverage for fixed and covariance parameters. In this selected
high-heterogeneity design, Laplace (`k = 1`) can be poor, and sufficiently
large quadrature orders improve bias and coverage; the paper does not supply a
universal order threshold. Its intervals target constant covariance
parameters, not coefficients in a predictor-dependent SD model. The paper
also states that one quadrature point is the Laplace approximation (Section
2.2), while its Bernoulli experiment is a specialization of the broader
grouped mixed-model method (Section 4).

The notebook's implication that Stringer's coverage findings can validate
heteroscedastic SD regression is therefore unsupported. Joe's published
abstract supports a narrower claim about asymptotic Laplace bias for selected
discrete mixed models, including its dependence on response discreteness and
cluster size; it does not study predictor-dependent latent SDs or interval
coverage. The notebook sources provide useful integration and variance-model
context, but no general identifiability result or calibration evidence for
`log(tau_g) = W_g alpha`. Our Bernoulli recovery and uncertainty claims still
require package-specific independent-oracle and simulation evidence.

### One Bernoulli observation per group: follow-up (2026-10-20)

A follow-up query asked the notebook to separate estimation of an individual
group effect from identification of population parameters. Its corrected
answer makes that distinction: one binary outcome does not recover that
group's realized random effect, but the notebook's 14 sources do not prove a
universal non-identifiability result for the population random-intercept
variance across many groups. This correction supersedes the notebook's earlier
overstatement; both outputs remain visible in its history.

The source boundary is narrower still. Joe (2008, Abstract and Sections 1 and
4) studies bias in Laplace-based estimation for selected discrete mixed
models. Stringer (v2, Sections 2.1–2.2 and 4.3.1) studies marginal-likelihood
integration and intervals for Bernoulli models with a group-invariant
covariance matrix. Neither paper studies the identifiability of
`log(tau_g) = W_g alpha`. In the intercept-only, one-observation-per-group
logit model, the observed distribution is determined by one marginal success
probability, so it cannot identify both the fixed intercept and the random
intercept SD. Adding varied group-level predictors changes that marginal
design; the sources do not establish general necessary and sufficient
conditions for that case. The analogous probit intercept-only model has an
exact scale-confounding identity, but that special result does not transfer
to logit or predictor-dependent SD regression. See Joe's
[publisher page](https://www.sciencedirect.com/science/article/abs/pii/S0167947308002533)
and Stringer's [v2 manuscript](https://arxiv.org/html/2310.01589).

The implementation consequence is to retain one-observation-per-group cases
in the capability universe and assess them by design, likelihood, and
calibration evidence. Do not label the entire Bernoulli family or all
predictor-dependent SD regressions non-identifiable from this source review.

## NotebookLM account and citation recheck, 2026-10-20

`notebooklm auth check --test --json` now passes for `itchyshin@gmail.com`; the
methods notebook then listed 14 sources. A follow-up question asked
about Bernoulli latent-SD identifiability, kernel scaling, discrete-response
integration, and uncertainty for SD slopes and ratios. NotebookLM returned an
answer with an empty `references` array. It is useful as a gap map only. I have
not promoted its claims, equations, or intervals into the synthesis. The
primary-source checks and numerical validation requirements in this note remain
open where listed. No notebook sources were added or removed during that
recheck.

## DHGLM prior-art correction and cited NotebookLM review (2026-10-20)

The earlier source map missed a close precedent. The official `dhglm` 2.0
manual documents binomial responses and fixed predictors in the linear
predictor for random-effect variances. For a random-effect variance
`lambda_g = tau_g^2`, its default log link gives
`log(lambda_g) = W_g gamma`. The requested SD parameterization
`log(tau_g) = W_g alpha` is the same predictor design under
`alpha = gamma / 2`. This is a direct model-class precedent for Bernoulli or
binomial random-effect scale regression, not a claim of novelty for the model
idea. The manual describes `LinPredRandVariance` as accepting fixed covariates
and allows `RespDist = "binomial"` in `dhglmfit` ([official CRAN manual](https://cran.r-project.org/web/packages/dhglm/refman/dhglm.html),
sections `DHGLMMODELING` and `dhglmfit`).

The estimator and inference contract differ. The `dhglm` manual documents
h-likelihood or a first-order Laplace approximation for fixed effects and
first-order adjusted profile likelihood for dispersion parameters. Those
method descriptions do not establish identifiability conditions or empirical
coverage for its random-effect variance predictors, and do not calibrate
drmTMB's profile or bootstrap intervals. Treat `dhglm` as prior art and a
possible workflow comparator. Do not use it as an independent likelihood
oracle without reconciling its objective, target scaling, and approximation.

NotebookLM's 20 October follow-up used the official CRAN manual and the Lee and
Noh DHGLM article record. It returned non-empty references to the manual's
binomial-family and `LinPredRandVariance` passages. I checked those passages
against the live [CRAN reference manual](https://cran.r-project.org/web/packages/dhglm/refman/dhglm.html),
including the log/inverse link options, fixed variance predictors, allowed
response distributions, and documented fitting methods. The publisher page
for [Lee and Noh (2012)](https://journals.sagepub.com/doi/10.1177/1471082X12460132)
supports the broader DHGLM model-class description; NotebookLM had only the
abstract/metadata for that article in this review. The algebraic factor of two
above is a direct parameter conversion, not a literature claim.

This review corrects the prior-art map only. It supplies no fit, recovery,
identifiability theorem, interval calibration, or cross-engine evidence for
drmTMB or DRM.jl. The Bernoulli gates and the broader family/effect/backend
ledger remain open.
