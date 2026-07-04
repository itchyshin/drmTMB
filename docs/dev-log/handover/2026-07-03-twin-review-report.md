# drmTMB ↔ DRM.jl — consolidated code-review report (2026-07-03)

_Rebuilt from the filed GitHub issues (the authoritative record). Static multi-agent review; no code was built or run. 85 verified findings across both twin packages, filed as 50 issues (high+medium individual, low batched by theme). Each section below is one filed issue, verbatim._


---

# drmTMB — 24 review issues (itchyshin/drmTMB)

## [#690](https://github.com/itchyshin/drmTMB/issues/690) [review][high] Rank-deficient / ill-conditioned known sampling covariance V only downgraded to a note, never a warning/error
_labels: bug_

**Severity:** high · **Confidence:** CONFIRMED · **Category:** inference-validity
**Location:** `R/check.R:990`

### What's wrong
In check_known_v() the matrix path computes the symmetric eigen-decomposition, rank, and condition number of the supplied known V, but the returned status is fixed to "note" whenever the diagonal is finite and non-negative (status <- if (!ok) "error" else "note"). The rank-deficiency test (rank < length(eig)) and the conditioning test (condition > 1e8) only change the *message text*, not the status. A singular or numerically singular V makes the Gaussian/meta GLS likelihood degenerate (V^-1 does not exist / is astronomically amplified), so standard errors, weighted means, and heterogeneity estimates are not trustworthy. Because attr(x,"ok") is TRUE unless a row is warning/error, a fit with a rank-deficient known V still reports ok = TRUE.

### Failure scenario
A meta-analysis fit with family = gaussian() + meta_V(V = V) where V is a dense block matrix that is (near-)singular, e.g. a duplicated study row or a perfectly collinear covariance block gives eig with a near-zero smallest positive eigenvalue so rank < n or condition > 1e8. check_drm() reports known_sampling_covariance as status "note", attr(x, "ok") stays TRUE, and is_converged()/downstream code proceed to report Wald SEs from an effectively singular V^-1 as if trustworthy.

### Proposed fix
In check_known_v() (matrix branch, around lines 968-1006) split the status logic: keep "error" for a non-finite/negative diagonal, but set status to "warning" when rank < length(eig) (singular V) or condition > 1e8 (severely ill-conditioned V), and reserve "note" for the dense-storage-scalability message only. Update the message so the rank/conditioning branch explicitly states that a singular or near-singular known V makes the GLS likelihood and its standard errors unreliable. This keeps storage advice as a note while making the actual identifiability/conditioning failure a warning that flips attr(x,"ok").

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#691](https://github.com/itchyshin/drmTMB/issues/691) [review][high] emmeans response scale for truncated_nbinom2 disagrees with predict()/fitted()
_labels: bug_

**Severity:** high · **Confidence:** CONFIRMED · **Category:** inference-validity/api-consistency
**Location:** `R/emmeans-preflight.R:170`

### What's wrong
drm_validate_emmeans_mu_target lists truncated_nbinom2 as a supported emmeans model type (line 170), and emm_basis/drm_emmeans_misc back-transforms with the raw mu link, which for truncated_nbinom2 is "log" (R/methods.R:4955). So emmeans type="response" returns exp(eta) = the UNTRUNCATED NB2 mean mu. But the package's own fitted()/predict(type="response") for truncated_nbinom2 reports the truncated positive-count mean mu/(1-p0) (R/methods.R:3208, truncated_nbinom2_mean). The two response-scale quantities silently differ.

### Failure scenario
Fit drmTMB(bf(y ~ x), family = truncated_nbinom2()). Call emmeans(fit, ~ x, type = "response") and predict(fit, type = "response") on the same x grid. emmeans reports exp(eta) (untruncated mu, e.g. 2.0) while predict/fitted report the larger positive-conditional mean mu/(1-p0) (e.g. ~2.3). A user comparing the two, or reporting emmeans EMMs as 'the expected count', gets a mislabeled quantity for a zero-truncated model.

### Proposed fix
Either (a) drop truncated_nbinom2 from supported_model_types in drm_validate_emmeans_mu_target and direct users to prediction_grid()/predict_parameters() (matching how other unsupported cases are handled), or (b) document explicitly in drm_emmeans_misc/emm_basis that for truncated_nbinom2 the emmeans response scale is the untruncated latent NB2 mean mu, not the fitted positive-count mean, and mark misc$inv.lbl accordingly (e.g. inv.lbl = "nb2.mu"). Prefer (a) until the truncated back-transform is implemented and tested, since silently returning a different quantity than fitted() is the most surprising outcome.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#692](https://github.com/itchyshin/drmTMB/issues/692) [review][high] Bivariate q4 phylocov log-Cholesky entries leak into the fixed-effect coefficient table and Wald CIs
_labels: bug_

**Severity:** high · **Confidence:** CONFIRMED · **Category:** inference validity / API inconsistency
**Location:** `R/julia-bridge.R:1447`

### What's wrong
new_drmTMB_julia() classifies a coefficient as structured (excluded from the fixed-effect blocks) only when its name starts with `resd_` or `recov_` (lines 1447-1448). For a q4 biv_gaussian fit the among-axis covariance arrives as coefficients named `phylocov_Sigma_a:L11`, `phylocov_Sigma_a:L21`, ... (DRM.jl _bridge_coef_vector packs `$(param)_$(nm)`). These are NOT filtered, so the whole `phylocov` block is put into `coefficient_blocks`, `coef_vector`, and `V` (line 1451-1459, 1509). Downstream, drm_julia_wald_targets() (2097-2133) and drm_julia_summary_coefficients() (2479-2514) then iterate every block and report the log-Cholesky factor entries as if they were regression coefficients on the 'link scale', complete with std.error, z statistic, and a two-sided p value. An off-diagonal like `Sigma_a:L21` is an unbounded Cholesky element, not a linear-predictor coefficient, so the z/p and Wald interval are meaningless. The same entries are (correctly) re-read by drm_julia_phylocov_matrix() for Sigma_a reconstruction, so the fix must exclude them from the fixed table without dropping them from `object$coefficients[['phylocov']]`.

### Failure scenario
Fit a q4 bivariate phylogenetic Gaussian model via engine='julia' (phylo(1|sp) on mu1, mu2, sigma1, sigma2), then call summary(fit) or confint(fit, method='wald'). The coefficient table contains rows dpar='phylocov', term='Sigma_a:L11'..'Sigma_a:L44' with fabricated z values and p values, and confint reports Wald intervals for these Cholesky entries as if they were fixed effects. A user reading the table would mis-interpret the raw log-Cholesky factor L11 as a significant/non-significant regression coefficient.

### Proposed fix
In new_drmTMB_julia() extend the structured-coefficient mask to also drop the `phylocov` block from the fixed-effect table, e.g. `structured_coef <- startsWith(names(coefficients), 'resd_') | startsWith(names(coefficients), 'recov_') | startsWith(names(coefficients), 'phylocov_')`. Keep the phylocov entries available to drm_julia_phylocov_matrix() by reading them from the full `coefficients` vector (or a dedicated `object$phylocov` slot) rather than from `object$coefficients[['phylocov']]`, so Sigma_a reconstruction (lines 2836, 1671) still works while summary()/confint(method='wald') no longer surface Cholesky entries as fixed effects.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#693](https://github.com/itchyshin/drmTMB/issues/693) [review][high] Bivariate q4 axis SDs omit the tree-depth sd_scale factor that the univariate path applies
_labels: bug_

**Severity:** high · **Confidence:** CONFIRMED · **Category:** correctness / cross-twin scale divergence
**Location:** `R/julia-bridge.R:1675`

> **Cross-package (twin) finding.** The fix must stay in lockstep between drmTMB and DRM.jl; the primary change lands in **drmTMB**, but confirm the sibling **DRM.jl** matches.

### What's wrong
DRM.jl builds the phylogenetic precision Q directly from raw branch lengths (sparse_phy.jl augmented_phy uses inv_b = 1/b with no tree-height normalization), so a fitted phylo variance component is on the raw-Q scale where tip variance is proportional to root-to-tip depth. To match native drmTMB's unit-height SD convention, the univariate bridge multiplies the returned log-SD by sd_scale = sqrt(mean(depths)) (drm_julia_phylo_sd_scale, line 1162; applied in drm_julia_structured_parameters line 1800, and link_estimate uses log(estimate/scale) at 1639). The bivariate q4 path does NOT: drm_julia_profile_targets_biv() sets axis_sd <- sqrt(diag(Sigma_a)) (line 1675) and link_estimate <- log(axis_sd) (line 1731) with no sd_scale, even though the payload carries the same non-unit sd_scale in structured_sd_scales (lines 1108-1111). The among-axis correlations in drm_julia_phylo_corpairs() are scale-invariant and remain correct, but the reported axis SD point estimates (summary()$random, profile_targets()$estimate) are off by a factor of sqrt(mean(depths)) relative to the univariate convention whenever the tree is not scaled to unit height.

### Failure scenario
Fit the same phylo(1|species) intercept as (a) a univariate Gaussian and (b) one axis of a q4 bivariate Gaussian, using a tree whose mean root-to-tip depth is, say, 50 (not 1). The univariate reported SD is exp(resd)*sqrt(50); the bivariate axis SD is sqrt(Sigma_a[i,i]) with no sqrt(50) factor, so the two 'same' phylogenetic SDs disagree by ~7x, and the bivariate SD no longer matches the native drmTMB (unit-height) reporting convention the univariate bridge was aligned to.

### Proposed fix
Apply the stored sd_scale to the reconstructed bivariate axis SDs. In drm_julia_profile_targets_biv() multiply axis_sd by the per-axis scale from object$structured_sd_scales (all four axes share one tree, so one sd_scale), and set link_estimate <- log(axis_sd / scale) to mirror the univariate transform at line 1639. Confirm on the DRM.jl side whether drm_bridge_inference returns the q4 among-axis CI bounds on the raw-Q scale or a normalized scale; if raw, also rescale the bounds in drm_julia_inference_confint_multi() by the same factor so the estimate and its CI stay on one consistent (native-matching) scale. Add a q4-vs-univariate parity fixture that checks the two conventions agree on a non-ultrametric / non-unit-height tree.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#694](https://github.com/itchyshin/drmTMB/issues/694) [review][high] Default missing='drop' is admitted for non-Gaussian phylo and count routes but neither side drops NA response rows
_labels: bug_

**Severity:** high · **Confidence:** CONFIRMED · **Category:** NA/missing mishandling / silent divergence
**Location:** `R/julia-bridge.R:424`

> **Cross-package (twin) finding.** The fix must stay in lockstep between drmTMB and DRM.jl; the primary change lands in **drmTMB**, but confirm the sibling **DRM.jl** matches.

### What's wrong
drm_julia_missing_supported() (lines 424-431) always accepts response='drop' (the drmTMB default) for every family. But the R bridge never drops NA rows itself: drm_julia_bridge_data() (646-668) only column-subsets `data`, and the phylo payload only reorders rows, so all rows (including NA responses) are marshalled to DRM.jl. On the Julia side, only the univariate fixed-effect and sigma-phylo Gaussian routes drop missing responses (gaussian_core.jl _fit_fixed_gaussian_missing_response); the general univariate Gaussian route THROWS for structured/RE fits with missing responses (gaussian_core.jl:426-431), and the Poisson/NB2/Gamma/Beta/Binomial sparse-Laplace phylo paths (sparse_laplace_glmm.jl) have no ismissing/drop handling at all. So a count/gamma/beta/binomial phylo fit with an NA response and the DEFAULT missing control does not perform the drop-then-fit that native engine='tmb' does; it either errors or feeds NaN into the likelihood and returns a non-converged / NaN result. The gate advertises 'response = drop is always allowed' but the behaviour silently diverges from native TMB for exactly the non-Gaussian routes the bridge otherwise claims to support.

### Failure scenario
Fit family=poisson() with phylo(1|species) via engine='julia' on data where a few response values are NA, leaving missing at its default (response='drop', predictor='fail'). Native engine='tmb' drops the NA rows and fits on complete cases. The Julia bridge passes the NA rows through; DRM.jl's sparse count Laplace has no missing-row handling, so the fit returns NaN loglik / non-convergence (opt$convergence=1) or an opaque Julia error, instead of the dropped-row fit the user requested via the default control.

### Proposed fix
Make response='drop' actually drop rows on the R side before marshalling for the routes DRM.jl does not handle internally: after building the needed-column data in drm_julia_bridge_data() (or in drm_julia_bridge_payload / the phylo payload), when missing_control$response=='drop', compute complete.cases over the response and predictor columns and subset both `data` and (for the phylo path) recompute row_order/species on the dropped data. Alternatively, tighten drm_julia_missing_supported() so response='drop' with any NA present is only admitted for the families/routes where DRM.jl actually drops (univariate Gaussian), and error with a clear 'use engine="tmb" or pre-drop' message otherwise. Add a test that a count/beta phylo fit with an NA response either matches the native dropped-case fit or errors explicitly, never returns NaN silently.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#695](https://github.com/itchyshin/drmTMB/issues/695) [review][high] Derived repeatability / phylogenetic-signal ratio omits other variance components from the denominator
_labels: bug_

**Severity:** high · **Confidence:** CONFIRMED · **Category:** inference-validity
**Location:** `R/methods.R:3757`

### What's wrong
drm_derived_summary_rows() loops over every entry of object$sdpars$mu and, for each term, reports estimate = re_variance / (re_variance + residual_variance), using only that single term's variance plus the residual variance (lines 3757-3769). When a Gaussian model has more than one mu random-effect term (e.g. a phylo(1|species) block plus an ordinary (1|id) block, or two crossed grouping factors), the denominator for each derived ratio excludes the other terms' variance. Repeatability/ICC and phylogenetic signal (heritability) are defined against the TOTAL variance, so each reported ratio is systematically overstated whenever multiple mu random effects are present. These rows print by default in summary() (see L3625-3628), so users see biased signal/repeatability numbers with no warning.

### Failure scenario
Fit drmTMB(bf(y ~ x + phylo(1 | species, tree = tree) + (1 | id), sigma ~ 1), family = gaussian()) where var_phylo = 0.5, var_id = 0.5, var_resid = 1.0 (total = 2.0). summary(fit) reports phylogenetic_signal = 0.5/(0.5+1.0) = 0.33 and repeatability = 0.5/(0.5+1.0) = 0.33, whereas the correct proportions of total variance are 0.5/2.0 = 0.25 each. Both derived quantities are overstated because each denominator drops the other random-effect block.

### Proposed fix
In drm_derived_summary_rows(), compute the total random-effect variance once as sum(sd_values^2) over all valid mu terms and use denominator = re_variance_of_this_term + other_re_variance + residual_variance for each row (i.e. total variance), not just this term's variance + residual. Concretely: precompute total_re_var <- sum(sd_values[valid]^2); set denominator <- total_re_var + residual_variance for every derived row so the ratios are proportions of total variance. Alternatively, if only single-term models are intended to be reported (as the doc's 'when the ingredients are unambiguous' suggests), guard drm_derived_summary_rows() to return empty when length(sd_values) > 1L and emit a note, rather than emitting per-term ratios with an incomplete denominator.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#696](https://github.com/itchyshin/drmTMB/issues/696) [review][high] Unnamed formula whose response is a bare symbol matching a reserved dpar name is silently reinterpreted as a parameterless dpar formula
_labels: bug_

**Severity:** high · **Confidence:** CONFIRMED · **Category:** silent mis-parse / LHS ambiguity
**Location:** `R/parse-formula.R:48`

### What's wrong
In parse_drm_formula_entry, an unnamed formula with an LHS reaches the is_dpar_lhs(lhs) branch (line 48) BEFORE the plain response->mu branch (line 51). is_dpar_lhs returns TRUE whenever deparse1(lhs) is in drm_known_dpars() (mu, mu1, mu2, sigma, sigma1, sigma2, shape, skew, nu, zi, zoi, coi, hu, rho12). So bf(nu ~ x) where nu is intended as a response column is parsed as dpar='nu', response=NA (a distributional-parameter formula) rather than dpar='mu', response='nu'. The LHS symbol text alone decides; there is no data-frame check. Confirmed by reading lines 37-58 and 88-90.

### Failure scenario
A user has a Gaussian outcome column literally named nu, shape, skew, zi, or sigma and writes bf(sigma ~ x) intending a location model on the sigma column. The parser records it as the residual-scale formula with response=NA. Downstream the model silently fits the wrong thing or produces a confusing 'requires exactly one location formula' error far from the real cause. The reverse also bites: bf(mu ~ x) treats a response column mu as the location dpar with no response.

### Proposed fix
Only treat an unnamed LHS as a bare dpar name when it is not a legitimate response. Either drop the is_dpar_lhs branch (lines 48-50) so any bare-symbol LHS on an unnamed formula becomes a response for mu (matching the documented grammar in bf.R, which only ever shows sigma = ~ x, never unnamed sigma ~ x), or keep the branch but emit an informational cli message ('Interpreting sigma as a distributional parameter, not a response column; use mu = sigma ~ x if sigma is your outcome') so the reinterpretation is never silent.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#697](https://github.com/itchyshin/drmTMB/issues/697) [review][medium] Unavailable (NA) group-level correlation is treated as 'near the boundary' and raised to a warning
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference-validity
**Location:** `R/check.R:1361`

### What's wrong
random_effect_covariance_near_boundary() returns TRUE when rho_abs is non-finite (!is.finite(rho_abs) || rho_abs > rho_boundary). The same NA-as-boundary pattern is inlined in check_biv_phylo_mu_covariance (line 3002), check_biv_structured_q2_covariance (line 3080), and check_biv_structured_q4_covariance (line 3176). max_abs_finite_or_na()/registry_covariance_pair_rho_abs() return NA_real_ whenever the correlation parameter cannot be matched or extracted (mapped/fixed parameter, name mismatch, sdreport skipped). This conflates 'correlation is pinned near +/-1' with 'correlation could not be read,' and emits a boundary *warning* that flips attr(x,"ok") to FALSE for a fit whose correlation is simply unavailable, not extreme.

### Failure scenario
A bivariate Gaussian fit with a mu/sigma or mu1/mu2 covariance block where the correlation parameter is fixed via map (or where corpars uses a name that does not match info$pair$parameter) yields rho_abs = NA. check_drm() then reports the covariance row as a "warning" claiming the correlation is close to +/-1, even though no boundary value was observed; attr(x,"ok") becomes FALSE and the user is told to profile/simplify a correlation that was never estimated.

### Proposed fix
Separate the two cases. Make random_effect_covariance_near_boundary() return FALSE (or NA) when rho_abs is non-finite, and have the callers emit a distinct 'note' (message: correlation could not be extracted; inspect sdreport/parameter mapping) rather than a boundary 'warning'. Apply the same fix to the three inlined copies (lines 3002, 3080, 3176) so an unavailable correlation is never reported as evidence of a boundary problem. Only rho_abs > rho_boundary should produce the boundary warning.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#698](https://github.com/itchyshin/drmTMB/issues/698) [review][medium] Modelled mu correlation reported as a single mean across groups, hiding heterogeneity
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference-validity
**Location:** `R/drmTMB.R:16189`

### What's wrong
In split_tmb_corpars, when has_modelled_mu_correlation(spec) is TRUE the reported rho_mu is mean(modelled_corpair_values(par, spec)) (line 16189). modelled_corpair_values returns 0.999999*tanh(X %*% beta_cor_mu), one correlation per row of the corpair design. Collapsing to an arithmetic mean discards the point of modelling correlation as a function of covariates, and averaging back-transformed correlations is not a coherent summary.

### Failure scenario
A mu-correlation regression rho ~ x that splits groups into rho approx +0.8 and -0.8 yields modelled values c(0.8,-0.8,...); the reported summary is mean approx 0.0, which reads as 'no correlation' and masks strong opposite-sign group correlations for anyone consuming out$mu.

### Proposed fix
Do not collapse modelled correlations to a scalar mean. Report the full per-level vector with its level labels, or an explicitly named summary (rho_mu_range/rho_mu_median). If one representative value is needed, average on the Fisher-z scale (tanh(mean(atanh(rho)))) not on correlations directly, and document it.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#699](https://github.com/itchyshin/drmTMB/issues/699) [review][medium] emmeans returns log-scale means for lognormal with no back-transform label
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference-validity/api-consistency
**Location:** `R/emmeans-preflight.R:165`

### What's wrong
lognormal is in supported_model_types (line 165). drm_dpar_link maps lognormal mu to "identity" (R/methods.R:4939), so drm_emmeans_misc returns misc with no tran field (identity branch, line 64-66). emmeans therefore treats lognormal EMMs as an identity-response quantity, i.e. the mean of log(y), and offers no back-transform. The package's fitted()/predict(type="response") for lognormal reports exp(mu + 0.5*sigma^2), the natural-scale mean (R/methods.R:4726). Users get log-scale means with no signal that a back-transform is even relevant.

### Failure scenario
Fit drmTMB(bf(y ~ group), family = lognormal()). emmeans(fit, ~ group) returns EMMs on the log scale (e.g. 1.0, 1.5) labeled as ordinary means with df=Inf and no 'results are on the log scale' note, while fitted()/predict report exp(mu + 0.5 sigma^2). A user reads the emmeans table as group means on the original response scale and reports numbers off by exp(mu)*(exp(0.5 sigma^2)) and a log transform.

### Proposed fix
In drm_emmeans_misc, special-case lognormal (and any identity-link-on-log-response family) so misc$tran = "log" and misc$inv.lbl = "response", so emmeans labels the scale as log and can back-transform on demand; optionally set misc$sigma to the fitted residual sigma to enable bias.adjust for the exp(mu+0.5 sigma^2) mean. If that is out of scope for the current tranche, remove lognormal from supported_model_types and route to prediction_grid()/predict_parameters(), matching the transformed-response handling already present.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#700](https://github.com/itchyshin/drmTMB/issues/700) [review][medium] Student-t: sigma is the scale, not SD[y], contradicting the documented sigma=SD contract
_labels: documentation_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** spec/documentation vs implementation
**Location:** `R/family.R:42`

> **Cross-package (twin) finding.** The fix must stay in lockstep between drmTMB and DRM.jl; the primary change lands in **drmTMB**, but confirm the sibling **DRM.jl** matches.

### What's wrong
student()'s roxygen (family.R:42-47) states a 'sigma = SD[y] contract' and justifies the nu>2 floor by 'the Student-t variance is finite only for nu>2, so a public standard-deviation sigma is only defined there'. But both implementations use sigma as the raw t SCALE: drmTMB.cpp model_type==3 (lines 2131-2138) evaluates z=(y-mu)/sigma with density Gamma((nu+1)/2)/Gamma(nu/2)/sqrt(nu*pi)/sigma*(1+z^2/nu)^-((nu+1)/2), i.e. the location-scale t with scale sigma; DRM.jl student.jl:84 does the identical logpdf(TDist(nu),(y-mu)/sigma)-log sigma. For a location-scale t the standard deviation is sigma*sqrt(nu/(nu-2)) != sigma. The twins AGREE with each other, but both violate the stated public SD contract, so stats::sigma()/predict claims of SD[y] and the nu>2 rationale are wrong.

### Failure scenario
Fit student() to data with nu near 3 and true SD 2. Both drmTMB and DRM.jl return coef(:sigma) ~ log(2/sqrt(3)) ~ log(1.155), and sigma(fit) reports ~1.155, not the SD 2 (SD = 1.155*sqrt(3/1) = 2). A user who trusts the documented 'sigma = SD[y]' contract reads the scale as an SD and under-reports the dispersion by the factor sqrt(nu/(nu-2)) (~73% at nu=3), which also propagates into any downstream SD-based interval or R^2.

### Proposed fix
Decide the contract and make code+doc+both twins agree. Option A (smaller): keep sigma as the scale and correct R/family.R:42-47 (drop 'sigma = SD[y]'; state 'sigma is the t scale; SD[y] = sigma*sqrt(nu/(nu-2))') and mirror the wording in DRM.jl/src/student.jl:1-25; the nu>2 floor is then a design choice, not an SD requirement. Option B (honour SD): rescale internally, using omega = sigma*sqrt((nu-2)/nu) as the t scale in BOTH drmTMB.cpp model 3 (z=(y-mu)/omega and the log-scale Jacobian on omega) and DRM.jl student.jl (zt=(y-mu)/omega, -log omega). Whichever is chosen must land in both repos so the twins stay identical.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#701](https://github.com/itchyshin/drmTMB/issues/701) [review][medium] Aggregated Gaussian log-likelihood uses uncentered sum of squares (catastrophic cancellation)
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** numerical-hazard
**Location:** `R/gaussian-aggregation.R:260`

> **Cross-package (twin) finding.** The fix must stay in lockstep between drmTMB and DRM.jl; the primary change lands in **drmTMB**, but confirm the sibling **DRM.jl** matches.

### What's wrong
drm_gaussian_aggregated_loglik computes the per-cell residual sum of squares as `sum_y2 - 2*mu*sum_y + n*mu*mu` (R lines 259-262) and src/drmTMB.cpp mirrors it at lines 580-582 (`agg_sum_y2 - 2*mu*agg_sum_y + agg_n*mu*mu`). This expanded form subtracts large nearly-equal quantities instead of accumulating the centered `sum((y-mu)^2)`. When the response has a large mean/offset relative to its residual spread, sum_y2 and 2*mu*sum_y are both large and nearly cancel, so the computed quadratic loses most of its significant digits (and can go slightly negative), while the full-row dnorm path drm_gaussian_full_loglik (lines 239-242) computes (y-mu)^2 directly and stays accurate. The aggregation is advertised as an exact-parity fast path (drm_gaussian_aggregation_parity, lines 267-319).

### Failure scenario
Fit a Gaussian model with aggregate_gaussian=TRUE on data where y is centered far from zero, e.g. y ~ N(1e6, 1) with a few thousand identical-covariate rows per cell. sum_y2 ~ 1e12 * n and 2*mu*sum_y ~ 1e12 * n differ only in the O(n) residual part; in double precision the ~1e12 magnitude leaves only ~4-5 accurate digits, so the cell quadratic (true value ~ n*1) is computed with large relative error or as a small negative number. The aggregated NLL then disagrees with the full-row NLL (parity `difference` becomes non-negligible) and the optimizer converges to biased beta_mu/beta_sigma, silently, without any warning.

### Proposed fix
Accumulate a centered statistic instead of the raw second moment. Either (a) store per-cell `mean_y = sum_y/n` and `css = sum_y2 - sum_y^2/n` (corrected sum of squares) in drm_gaussian_aggregation, then compute the cell quadratic as `css + n*(mean_y - mu)^2`, which subtracts small centered quantities; or (b) at minimum center y once (subtract a global mean before building sufficient statistics) and re-add it in mu. Apply the identical change to R/gaussian-aggregation.R (drm_gaussian_aggregated_loglik) and src/drmTMB.cpp (lines 579-585) so the twin implementations stay bit-parity, and extend drm_gaussian_aggregation_parity's default betas to include a large-intercept case that would currently fail.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#702](https://github.com/itchyshin/drmTMB/issues/702) [review][medium] Parser never enforces one-formula-per-parameter; uniqueness left to each family route
_labels: bug_

**Severity:** medium · **Confidence:** PLAUSIBLE · **Category:** missing invariant / duplicate dpar
**Location:** `R/parse-formula.R:10`

### What's wrong
parse_drm_formula_entries/parse_drm_formula_entry build one entry per input formula but never check that dpar values are unique. Enforcement lives only in each family consumer (e.g. R/drmTMB.R:2496-2504 univariate Gaussian, :5848-5861 bivariate), each re-implementing sum(dpars == ...) > 1 guards, then indexing with entries[[which(dpars == 'sigma')]]. If a route forgets the guard (or a new family is added without it), which() returns length>1 and entries[[c(i,j)]] does R recursive indexing, silently selecting a nested element or erroring cryptically instead of reporting a duplicated parameter.

### Failure scenario
bf(y ~ x, sigma ~ a, sigma ~ b) routed through a family whose consumer lacks the duplicate guard: entries[[which(dpars=='sigma')]] becomes entries[[c(2,3)]] = entries[[2]][[3]], returning entries[[2]]$response (a string) as if it were an entry, causing a downstream type error with no mention of the duplicated sigma.

### Proposed fix
Add a single canonical uniqueness check in parse_drm_formula_entries after building entries: compute dpars via vapply, exclude multi-instance-legal families (sd*(), corpair() which are keyed by group), and cli_abort on any duplicated plain dpar naming the repeated parameter. This makes the invariant hold for every current and future route; per-family guards become redundant defense.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#703](https://github.com/itchyshin/drmTMB/issues/703) [review][medium] corpair(from=, to=) accepts 'mu'/'sigma' endpoints meaningless for a bivariate latent correlation
_labels: bug_

**Severity:** medium · **Confidence:** PLAUSIBLE · **Category:** term stability / API-rule violation
**Location:** `R/parse-formula.R:217`

### What's wrong
parse_corpair_lhs validates from/to against allowed_endpoints <- c('mu','sigma','mu1','mu2','sigma1','sigma2') (line 217). corpair() marks latent RE correlations between two distributional parameters; documented targets are pairs like from='mu1', to='mu2'. mu and sigma are the univariate names — a correlation needs two distinct parameters, and univariate models have only one mu/sigma. Allowing from='mu', to='sigma' admits a mean-scale pairing under corpair() grammar, which the docs treat as the separate univariate mean-scale correlation path via matching mu/sigma intercept terms, not via corpair(from/to). The xor/different-endpoint checks do not catch that mu/sigma are the wrong namespace.

### Failure scenario
corpair(id, from='mu', to='sigma') ~ x is accepted and stored as a rendered dpar string. Downstream it matches no q=2 route (documented targets are mu1/mu2) and errors late, or is silently mapped onto an unintended mean-scale block, blurring the documented boundary between corpair() (bivariate latent) and the univariate mean-scale correlation path.

### Proposed fix
Restrict allowed_endpoints for the from/to pair to the bivariate/dual names that can form a correlated pair: c('mu1','mu2','sigma1','sigma2') (line 217); drop 'mu'/'sigma'. If a univariate mean-scale corpair() target is planned, gate it behind an explicit class/level combination with its own message rather than overloading from/to.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#704](https://github.com/itchyshin/drmTMB/issues/704) [review][medium] cor_sd penalty silently ignored when there is a single phylogenetic SD (q_phylo == 1)
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference-validity
**Location:** `R/penalty.R:122`

### What's wrong
drm_phylo_penalty(cor_sd = ...) is accepted for any phylogenetic model and drm_apply_phylo_penalty_spec sets phylo_cor_penalty_sd to the scalar regardless of q_phylo. But the C++ penalty (src/drmTMB.cpp drm_phylo_penalty_value, lines 63-71) only applies the correlation penalty for q_phylo == 2 (eta_cor_phylo) or q_phylo > 2 (theta_phylo); for q_phylo == 1 there is no correlation parameter and the supplied cor_sd is a no-op. No warning is emitted anywhere. drm_phylo_penalty_sweep() defaults to sweeping cor_sd = c(0.25, 0.5, 1) and, applied to a single-SD phylo model, produces a summary table that looks like a prior-sensitivity sweep but in which the penalty is inert on every row.

### Failure scenario
User fits a location-only phylogenetic model, e.g. drmTMB(y ~ x + phylo(1 | sp), family = gaussian(), penalty = drm_phylo_penalty(cor_sd = 0.5)) so q_phylo == 1. The fit succeeds and is labeled MAP, but the correlation penalty is never added (no correlation parameter exists). Worse, drm_phylo_penalty_sweep(y ~ x + phylo(1 | sp), data, cor_sd = c(0.25, 0.5, 1)) returns three rows with identical logLik/couplings; the user reads this as evidence the coupling is 'data-informed and stable across the prior sweep' when in fact no coupling and no penalty were ever in play.

### Proposed fix
In drm_apply_phylo_penalty_spec() (R/penalty.R), after computing q_phylo, guard the correlation penalty: if !is.null(penalty$cor_sd) && q_phylo < 2, cli::cli_abort() (or at minimum cli_warn) that cor_sd requires a coupled/bivariate phylogenetic model with >= 2 phylogenetic SDs and no correlation parameter exists to penalize, pointing the user to set cor_sd = NULL. Correspondingly, in drm_phylo_penalty_sweep() detect q_phylo == 1 up front (or catch the new abort) and refuse to run a meaningless cor_sd sweep rather than returning a table of identical rows.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#705](https://github.com/itchyshin/drmTMB/issues/705) [review][medium] Endpoint profile accepts nlminb convergence code 1 without a gradient gate, narrowing CIs
_labels: bug_

**Severity:** medium · **Confidence:** PLAUSIBLE · **Category:** inference-validity
**Location:** `R/profile.R:3007`

### What's wrong
In profile_endpoint_evaluator's inner re-optimization at a fixed target value, convergence_tolerated <- opt$convergence %in% c(0L, 1L) accepts nlminb code 1 ('false convergence' / did-not-converge). The constrained profile objective opt$objective is then returned as the profiled negative log-likelihood and used directly in the likelihood-ratio equation out$nll - nll_hat - cutoff. The maximum absolute gradient (max_abs_gradient) IS computed (lines 3003-3006) but is used only in the error message, never as an acceptance criterion. So an inner solve that stopped short of the constrained minimum with a large gradient is silently accepted, over-estimating the profiled nll at that theta.

### Failure scenario
Profile a variance-component SD (transformation 'exp') on a hard/near-boundary structured-RE fit where the inner Laplace + nlminb solve at a trial log_sd value hits the iteration limit and returns opt$convergence == 1 while still ~1 gradient unit from the constrained minimum. The returned nll is too high, so out$nll - nll_hat - cutoff crosses zero at a theta closer to theta_hat than the true LR endpoint. uniroot returns a root with small root_error (the equation is satisfied for the inflated nll), so no failure is flagged: confint() reports a profile SD interval that is too narrow, under-covering exactly in the boundary regime where profile intervals were supposed to fix Wald under-coverage.

### Proposed fix
Do not treat nlminb code 1 as success on its own. Either (a) restrict convergence_tolerated to opt$convergence == 0L, or (b) when opt$convergence == 1L, additionally require max_abs_gradient to be below a tolerance (e.g. the optimizer's own convergence tolerance, default ~1e-3) before accepting; otherwise cli_abort as an inner failure so the row is returned with conf.status = 'profile_failed' rather than a spuriously tight interval. Also consider retrying the inner solve from a fresh start (start_free instead of the warm-started last_free) once before failing, since warm-starts from a distant bracket point can trigger premature code-1 stops.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#706](https://github.com/itchyshin/drmTMB/issues/706) [review][medium] profile_engine='endpoint' with an unsupported target aborts hard instead of returning a failed row
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** correctness
**Location:** `R/profile.R:2644`

### What's wrong
In drm_profile_target_confint, when profile_engine == 'endpoint' and profile_endpoint_target_supported(target) is FALSE, the code calls drm_profile_target_endpoint_confint (line 2646) OUTSIDE the tryCatch that wraps the supported branch (lines 2654-2663). drm_profile_endpoint_result then cli_abort()s at line 2857 for the unsupported target. Every other failure path in this function converts errors into a conf.status = 'profile_failed' row (lines 2664-2671, 2712-2718), so a batch confint() over a target set that mixes supported and unsupported targets is aborted entirely by one unsupported target under profile_engine='endpoint', rather than returning a partial table with a failed row.

### Failure scenario
confint(fit, parm = 'correlations', method = 'profile', profile_engine = 'endpoint') where the correlation set includes a derived unstructured-correlation target (transformation 'unstructured_corr', not in profile_endpoint_target_supported). The first supported correlation is intervalled fine, but when the worker reaches the derived target, drm_profile_target_endpoint_confint aborts, taking down the whole confint() call and losing the already-computed supported rows.

### Proposed fix
Wrap the unsupported-target branch in the same tryCatch-to-failed-row pattern used elsewhere, or (cleaner) pre-filter: if profile_engine == 'endpoint' and the target is unsupported, return drm_profile_failed_confint_row(..., message = 'endpoint engine unsupported for this target class') so a mixed target set degrades gracefully to per-row failures instead of aborting the batch.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#707](https://github.com/itchyshin/drmTMB/issues/707) [review][medium] Dense .inverse()/log(.determinant()) on q>2 phylo covariance has no PD/near-singular guard
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** numerical-hazard
**Location:** `src/drmTMB.cpp:3409`

### What's wrong
For q>2 phylogenetic (single-block) and probe model types the separable covariance is inverted and its log-determinant taken directly with matrix::inverse() and log(matrix::determinant()) (lines 324-325, 369-370, 3408-3409). The correlation comes from UNSTRUCTURED_CORR_t or the partial-correlation Cholesky, so it is PD for finite theta, but as any pairwise partial correlation approaches +/-1 (or two response dimensions become collinear) the correlation matrix becomes numerically near-singular; determinant -> 0 gives log(det) -> -Inf and inverse() amplifies, and there is no clamp/regularization.

### Failure scenario
A q=3 or q=4 phylogenetic-mu bivariate/multivariate fit where the optimizer pushes one theta_phylo partial correlation toward +/-1 (e.g. two highly correlated traits). phylo_q4_covariance becomes near-singular; covariance_inverse entries explode and log_det_covariance -> -Inf, so nll returns Inf/NaN and the outer optimizer / Laplace inner Newton step fails or reports a spurious optimum.

### Proposed fix
Replace the explicit phylo_q4_covariance.inverse() and log(phylo_q4_covariance.determinant()) with a Cholesky-based path: form the Cholesky L of phylo_q4_covariance (or better, build the density from the partial-correlation Cholesky already available in drm_partial_correlation_cholesky_corr so log-det = 2*sum(log(diag(L))) analytically and the quadratic form is solved by triangular back-substitution). This avoids forming an explicit inverse, keeps the log-det finite and cheap, and matches the numerically-stable construction used elsewhere. Alternatively add a small ridge (e.g. + eps*I) before inversion. Apply the same fix at the model_type 93/94 probe blocks.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#708](https://github.com/itchyshin/drmTMB/issues/708) [review][low] Docs, naming & API-consistency (2 findings)
_labels: documentation_

Batch of **low-severity** findings under the theme *Docs, naming & API-consistency* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. emm_basis ignores emmeans-supplied trms/xlev and rebuilds design from grid
- **Location:** `R/emmeans-preflight.R:41` · PLAUSIBLE
- **Issue:** emm_basis.drmTMB receives trms and xlev from emmeans but discards them, building X itself via drm_fixed_effect_basis(object, newdata = grid). Column alignment is enforced downstream (drm_fixed_effect_basis compares colnames(X) to names(beta), R/methods.R:4446), so a mismatch aborts rather than mis-estimates. The risk is that emmeans-side factor coding or reference-grid transforms that would normally flow through trms/xlev are silently re-derived from the fitted terms, which can produce a hard abort (not a wrong number) if a custom reference grid does not round-trip.
- **Failure scenario:** A user builds a reference grid with at = / nesting that emmeans encodes via trms, then calls emm_basis; drm_fixed_effect_basis rebuilds columns from grid and, if the rebuilt colnames differ from names(beta), aborts with 'Could not align the mu design matrix', instead of using the trms/xlev emmeans already prepared.
- **Proposed fix:** Document (in a comment and the emmeans design doc) that emm_basis.drmTMB intentionally rebuilds the design from the grid via drm_fixed_effect_basis and relies on the colname/beta-name equality check as the guardrail, and add a testthat case exercising a factor-with-contrasts reference grid to confirm round-tripping. This keeps the abort-on-mismatch behavior explicit rather than an implicit consequence of ignoring trms/xlev.

---

### 2. meta_known_V deprecation warning only fires when the marker is on the RHS, not the LHS
- **Location:** `R/parse-formula.R:19` · CONFIRMED
- **Issue:** parse_drm_formula_entry warns via warn_meta_known_v_deprecated() only when formula_contains_call(rhs, 'meta_known_V') is TRUE (line 19). formula_rhs is expr[[length(expr)]], so only the RHS is scanned. A meta_known_V(...) on the LHS would not trigger the deprecation notice at parse time. Silent non-warning is inconsistent with the alias contract (CLAUDE.md: meta_known_V is a deprecated alias only).
- **Failure scenario:** bf(meta_known_V(V = vi) ~ moderator): parsed with dpar='mu', response='meta_known_V(V = vi)' and no deprecation warning; the user never learns the alias is deprecated.
- **Proposed fix:** Scan both sides for the deprecated marker: change the guard to formula_contains_call(expr, 'meta_known_V') (whole formula) or add || (has_lhs && formula_contains_call(lhs, 'meta_known_V')). Keeps the deprecation notice firing wherever the alias appears.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#709](https://github.com/itchyshin/drmTMB/issues/709) [review][low] Missing-data & input-validation robustness (4 findings)
_labels: bug_

Batch of **low-severity** findings under the theme *Missing-data & input-validation robustness* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. sigma.drmTMB silently falls through to bivariate branch for any unlisted univariate family
- **Location:** `R/methods.R:3370` · CONFIRMED
- **Issue:** sigma.drmTMB() enumerates scale-bearing families in one if-block (L3345-3361) and unit-dispersion families in a second (L3362-3369); anything not matched falls through to new_biv_sigma(predict(dpar='sigma1'), predict(dpar='sigma2')) at L3370. The fall-through implicitly assumes 'not-in-either-list == bivariate Gaussian', with no check on model_type. A newly added univariate family (the review's planned-family criterion) that is not added to one of the two lists will not error cleanly; it will attempt predict(dpar='sigma1') and either abort deep inside match.arg with a confusing message or, worse, mis-dispatch. This is a design coupling where the default branch encodes a family identity rather than being an explicit biv_gaussian case with an else-error.
- **Failure scenario:** A future maintainer adds a univariate family (say 'gpoisson') with a fitted sigma but forgets to add it to the first if-block in sigma.drmTMB. Calling sigma(fit) on that fit executes the biv branch and calls predict(object, dpar='sigma1'); since 'sigma1' is not in names(object$coefficients), predict()'s match.arg aborts with 'arg should be one of ...', an internal-looking error unrelated to sigma() rather than a clear 'sigma() not defined for this family'.
- **Proposed fix:** Make the bivariate case explicit and add a terminal error: replace the trailing fall-through with `if (identical(object$model$model_type, "biv_gaussian")) { return(new_biv_sigma(...)) }` followed by `cli::cli_abort("Internal error: no sigma() rule for model type {.val {object$model$model_type}}.")`. This matches the defensive pattern already used in drm_fitted_response() (L4910) and drm_dpar_link() (L4967), and forces every new family to be registered deliberately.

---

### 2. Response-mask helper silently returns unmasked values on any length mismatch, leaking the 0 sentinel
- **Location:** `R/missing-data.R:484` · PLAUSIBLE
- **Issue:** drm_mask_missing_response_values() masks missing responses only when length(value) == length(observed_y); on any mismatch it returns value unchanged with no warning. Missing responses under response="include" are stored with the numeric sentinel (drm_missing_response_sentinel() defaults to 0, line 311). If the vector to be masked ever has a length that differs from the row mask, the masking is silently skipped and the sentinel 0 is emitted as if it were a genuine fitted value / residual for a row whose response was actually missing.
- **Failure scenario:** Fit a univariate Gaussian with miss_control(response="include") and some missing y. Downstream code (e.g. a residual or fitted-value assembly) passes a value vector whose length no longer equals the retained-row count (e.g. after an internal subset, or a partial-length prediction). The guard at line 484 is triggered, masking is skipped, and rows with missing responses report an exact 0 (the sentinel) as a real fitted value/residual, biasing any summary that consumes them.
- **Proposed fix:** Change the early-return on length mismatch (lines 484-486) from silent pass-through to an internal cli::cli_abort() (or at minimum cli::cli_warn) so a length disagreement is surfaced rather than silently emitting the sentinel. The same hardening should be applied to drm_mask_biv_missing_response_values() (lines 491-507), whose analogous nrow(value) != length(observed_y1) guard also returns the unmasked matrix silently. Masking is a correctness-critical step (it is the only thing that keeps the internal sentinel from being reported as data), so a size disagreement is a bug, not a no-op.

---

### 3. parse_structured_marker_call treats 'not animal/phylo/phylo_interaction/relmat' as spatial by fall-through
- **Location:** `R/parse-formula.R:585` · PLAUSIBLE
- **Issue:** parse_structured_marker_call handles animal, phylo, phylo_interaction, relmat in explicit if(identical(marker, ...)) blocks that each return(). The remaining code (lines 586-613) implicitly assumes marker=='spatial', validates coords/mesh, and returns type='spatial'. Safe today because structured_marker_call_name's name set matches, but the coupling is implicit: a new marker name added to structured_marker_names() without a matching if block silently falls through and is parsed as spatial, mislabeling the effect.
- **Failure scenario:** A contributor adds 'gp' to structured_marker_names() and its bf() marker but forgets an if(identical(marker,'gp')) block here. bf(y ~ x + gp(1 | site, coords = coords)) is parsed with type='spatial' and no error, silently misrouting the term.
- **Proposed fix:** Make the final branch explicit: wrap lines 586-613 in if(identical(marker,'spatial')){...} and add a terminal cli::cli_abort('Internal error: unhandled structured marker {.val {marker}}.') so any unregistered marker fails loudly at parse time.

---

### 4. drm_phylo_tip_covariance does not validate the `correlation` flag (sibling does)
- **Location:** `R/phylo-utils.R:223` · CONFIRMED
- **Issue:** drm_phylo_augmented_precision validates that `correlation` is a length-1 non-NA logical (lines 236-240), but the dense comparator drm_phylo_tip_covariance has no such guard. At line 223 `if (correlation)` will use only the first element of a vector (R >= 4.3 errors, older R warns and silently proceeds) and will error uninformatively on NA. Because this function is the ground-truth comparator used throughout the phylo test suite, a malformed value produces a misleading covariance rather than a clear abort.
- **Failure scenario:** A developer test or downstream helper calls drmTMB:::drm_phylo_tip_covariance(tree, correlation = c(TRUE, FALSE)) (e.g. from a vectorized sweep). On older R the first element is used silently, on newer R it errors deep inside the function with a generic 'condition has length > 1'; either way the failure is not attributable to a bad argument, and a silently-used first element could seed a wrong reference matrix in a comparison test.
- **Proposed fix:** Add the same guard used in the sibling at the top of drm_phylo_tip_covariance: `if (!is.logical(correlation) || length(correlation) != 1L || is.na(correlation)) cli::cli_abort('{.arg correlation} must be TRUE or FALSE.')`. This keeps the two twin comparators consistent and prevents a silently mis-scaled reference matrix.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#710](https://github.com/itchyshin/drmTMB/issues/710) [review][low] Numerical stability guards (6 findings)
_labels: bug_

Batch of **low-severity** findings under the theme *Numerical stability guards* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. Absolute (scale-dependent) eigenvalue/symmetry tolerances let a non-PSD known V pass, breaking the dense MVNORM likelihood
- **Location:** `R/drmTMB.R:12451` · PLAUSIBLE
- **Issue:** validate_known_v_matrix() checks PSD with min(eigenvalue) < -sqrt(.Machine$double.eps) (~ -1.5e-8, an ABSOLUTE threshold) and symmetry via all.equal with tolerance sqrt(.Machine$double.eps). These thresholds are not scaled by the matrix magnitude. For a V whose entries are large (e.g. variances ~ 1e6-1e8, common on unstandardized effect sizes), a genuinely indefinite matrix can have a negative eigenvalue of magnitude far larger than 1.5e-8 in relative terms yet still be a small relative perturbation; conversely a numerically fine matrix can fail. The dense meta path builds Omega = V_known_matrix + diag(sigma^2) and hands it to density::MVNORM_t (src/drmTMB.cpp lines 2017-2027, 3461-3485), which Choleskys Omega. When residual heterogeneity sigma is near zero (the known sampling variance dominates), the diag(sigma^2) correction does not restore positive-definiteness.
- **Failure scenario:** A user supplies a dense meta_V(V = V) where V is assembled from correlated effect-size estimates on a large scale (entries ~1e7) and, due to rounding in constructing off-diagonals, has a real smallest eigenvalue around -1e-3. Because -1e-3 is not compared relative to the ~1e7 scale in a robust way, the validator's absolute threshold logic still admits matrices whose relative negativity is invisible at that magnitude; the fit then optimizes sigma toward ~0, Omega loses positive-definiteness, and density::MVNORM_t's Cholesky yields NaN so the optimizer returns a non-finite / bogus objective instead of a clear 'V not positive semidefinite' error.
- **Proposed fix:** Make the PSD and symmetry tolerances scale-relative in validate_known_v_matrix(): compare min(ev) against -tol * max(abs(ev)) (or against -tol * max(abs(diag(value)))) rather than a bare sqrt(.Machine$double.eps), and scale the symmetry all.equal tolerance by max(abs(value)). This mirrors standard relative-eigenvalue PSD tests and gives a deterministic, scale-invariant rejection with a clear message before the matrix ever reaches the MVNORM Cholesky.

---

### 2. Scale start applies mean-of-|resid| correction to a log-of-|resid| quantity
- **Location:** `R/drmTMB.R:12833` · PLAUSIBLE
- **Issue:** gaussian_sigma_fixed_start() estimates the log-sigma slopes by regressing log(|resid|) + 0.5*log(pi/2) on X_sigma (lines 12833-12836). The additive constant 0.5*log(pi/2) is the correction that makes log(E|resid|) an unbiased estimate of log(sigma) (since E|resid| = sigma*sqrt(2/pi)). It is NOT the correction for E[log|resid|], which is log(sigma) + E[log|Z|] with E[log|Z|] = -0.5*(gamma + log 2) ~= -0.6352. The intended unbiased constant for the log-scale regression is therefore ~+0.6352, not +0.2258.
- **Failure scenario:** For a homoscedastic Gaussian the log-sigma intercept start is biased low by ~0.41 on the log scale (a starting sigma about 34% too small). This is only a starting value and nlminb normally recovers, but on stiff heteroscedastic scale models (sigma ~ several predictors) or small n it can seat the optimizer in a poorer basin and slow or fail convergence; because the intercept beta_sigma[1] is separately set to log(sigma0) at line 12826 and only the slopes are kept from this regression, the practical impact is confined to slope starts.
- **Proposed fix:** Replace 0.5*log(pi/2) at line 12834 with the correct Fisher log-|normal| bias constant 0.5*(-digamma(1) - log(2)) (i.e. approximately 0.6351814) so that log(|resid|) + c is an unbiased start for log(sigma), or drop the comment/rename to make clear this is a deliberately conservative slope-only heuristic. Add a comment stating which expectation (E|resid| vs E log|resid|) the constant corrects.

---

### 3. Meta-analysis start-value uses median(V) subtraction; can under/over-shoot with heterogeneous V
- **Location:** `R/drmTMB.R:14054` · PLAUSIBLE
- **Issue:** biv_gaussian_start sets sigma to sqrt(max(var(resid) - median(V), sigma_floor^2)) (lines 14054-14063), subtracting the median known sampling variance from the unweighted residual variance to recover between-study variance. Using median(V) against an unweighted residual variance is a rough moment approximation that can start far from the optimum when V_i are skewed, slowing or destabilising the Laplace fit for meta-analytic Gaussian models (family=gaussian()+meta_V). Start-value quality only, not a likelihood error.
- **Failure scenario:** With a few very-high-variance studies (right-skewed V) and modest true tau^2, var(resid) is inflated while median(V) is small, so sigma starts much too large; if most studies are high-V and true tau^2 near zero, var(resid)-median(V) is pushed to sigma_floor and the start is near-degenerate. Either way the optimizer can converge slowly or to a poorer local mode.
- **Proposed fix:** Use a variance-weighted (DerSimonian-Laird) moment start: pool the mean with weights 1/V_i, form Q = sum(w_i (resid_i - mu_hat)^2), set tau2_start = max((Q - (k-1)) / (sum w_i - sum w_i^2/sum w_i), sigma_floor^2), then sigma_start = sqrt(tau2_start). This matches the meta-analytic model the fit targets and is robust to heterogeneous V.

---

### 4. Per-block PSD check in meta_vcov_bivariate uses an absolute tolerance and admits singular (correlation = +/-1) blocks
- **Location:** `R/meta-vcov.R:70` · PLAUSIBLE
- **Issue:** meta_vcov_bivariate() rejects a 2x2 block only when abs(cov12) - sqrt(v1*v2) > sqrt(.Machine$double.eps), an absolute tolerance independent of block scale. For large sampling variances this permits blocks that are effectively indefinite at the working scale; for cov12 exactly equal to sqrt(v1*v2) it accepts a singular (rank-1) block (sampling correlation exactly +/-1), which is degenerate as a covariance and, if sigma is near zero, feeds a non-PD Omega to the downstream dense MVNORM likelihood.
- **Failure scenario:** User calls meta_vcov_bivariate(v1 = rep(1e6, n), v2 = rep(1e6, n), cor12 = rep(1, n)); every block is singular (correlation 1). The helper returns V without complaint; passed to meta_V it later combines with a small fitted sigma so the assembled bivariate covariance is non-PD and the MVNORM density returns NaN rather than a clear 'block not positive definite' error.
- **Proposed fix:** Scale the tolerance to the block magnitude, e.g. reject when abs(cov12) - sqrt(v1*v2) > tol * sqrt(v1*v2) (relative), and additionally warn (or optionally reject) when abs(cov12) is within tolerance of sqrt(v1*v2), i.e. a singular block with sampling correlation +/-1, since such blocks are degenerate covariance inputs for the bivariate meta likelihood.

---

### 5. Inner profile solves reuse the fitted optimizer control, whose iteration budget may be too small for constrained refits
- **Location:** `R/profile.R:2994` · PLAUSIBLE
- **Issue:** profile_endpoint_evaluator runs the constrained inner optimization with control <- object$control$optimizer (set in drm_profile_endpoint_result, lines 2884-2888), i.e. the same nlminb control used for the ORIGINAL free fit. A user who fit with a modest iter.max / eval.max (common for speed) will have that same, possibly tight, budget applied to every constrained endpoint refit. Constrained refits with one parameter pinned away from its optimum can need more iterations than the original fit, making premature code-1 stops (see the companion finding at line 3007) more likely and effectively coupling profile-CI reliability to an unrelated fitting-speed choice.
- **Failure scenario:** A user fits with drm_control(optimizer = list(iter.max = 50)) to speed up a large phylogenetic model, then calls confint(fit, parm = 'sd:mu:phylo(...)', method = 'profile', profile_engine = 'endpoint'). Each endpoint refit inherits iter.max = 50; a bracket point far from the optimum does not converge within 50 iterations, returns code 1, and (per the line-3007 issue) is accepted with an inflated nll, silently biasing the endpoint inward. The interval looks successful (conf.status = 'profile').
- **Proposed fix:** Use a dedicated, generous control for the constrained inner solves rather than blindly inheriting object$control$optimizer -- e.g. start from a copy but override iter.max/eval.max to a large default (or drop them so nlminb uses its defaults), keeping only the tolerances. Document that endpoint-engine inner solves do not reuse the caller's speed-tuned iteration budget. This makes profile-CI accuracy independent of the original fit's speed settings.

---

### 6. MI count/gamma marginalization can divide by a zero prior-normalizer (prior_mean/prior_norm) for extreme eta
- **Location:** `src/drmTMB.cpp:516` · CONFIRMED
- **Issue:** In the missing-covariate 'else' (no y, unobserved x) branches for Poisson (line 1573), gamma (1904), nbinom2/truncated (1653/1752) and beta families, the imputed covariate is set to prior_mean/prior_norm where prior_norm is a finite quadrature sum of exp(log_density). For extreme mi_eta the per-node densities can all underflow to 0 in double precision, giving prior_norm = 0 and a 0/0 = NaN imputed x that then feeds mu(i) += beta_mu(mi_col)*(NaN - ...).
- **Failure scenario:** A row with a missing covariate whose imputation-model linear predictor mi_eta is far in the tail (e.g. a Poisson x-model with mi_eta ~ 40 so exp(log_density) underflows at every fixed quadrature node). prior_norm underflows to exactly 0, mi_x_full becomes NaN, mu becomes NaN, and the whole nll is NaN, aborting the fit with an opaque error.
- **Proposed fix:** Compute the prior mean in log space using the same logspace_add pattern already used in the observed-y branches: accumulate log_terms = log(weight) + log_density, take log_denom via logspace_add, and form the posterior/prior mean as sum(x_q*exp(log_term - log_denom)). This is numerically stable and never divides by an underflowed normalizer. Apply consistently across the mi_family 4/5/7/8/10/11/12 prior-only branches.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#711](https://github.com/itchyshin/drmTMB/issues/711) [review][low] Other robustness & cleanup (3 findings)
_labels: bug_

Batch of **low-severity** findings under the theme *Other robustness & cleanup* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. Spatial SD-ratio weak check omits the has_scale_ratio guard used by the phylo twin
- **Location:** `R/check.R:2654` · PLAUSIBLE
- **Issue:** check_spatial_mu_diagnostics() computes weak_sd <- !finite_positive_sd || any(finite_sd_ratios < 0.05) (line 2654-2655), whereas the sibling check_phylo_mu_diagnostics() guards the ratio test with has_scale_ratio (weak_sd <- !finite_positive_sd || (has_scale_ratio && any(finite_sd_ratios < 0.05)), line 2524-2525). The two twins are meant to behave identically. When finite_sd_ratios is empty (residual scale unavailable, e.g. spatial_mu_residual_scale returns NA because sigma() failed), any(numeric(0) < 0.05) is FALSE so the two branches happen to agree today, but the divergent structure means a future change to how the residual scale is derived can make the spatial branch report a different weak_sd verdict than the phylo branch for the same evidence state.
- **Failure scenario:** If spatial_mu_residual_scale() is later extended to return a finite scale for a family where the phylo path still returns NA (or vice versa), the spatial diagnostic would fire (or suppress) weak_sd differently from the phylo diagnostic for identical SD evidence, silently diverging the two twins' notes; today the two paths already read differently for a reviewer auditing them.
- **Proposed fix:** Align check_spatial_mu_diagnostics() with check_phylo_mu_diagnostics(): introduce has_scale_ratio <- length(finite_sd_ratios) > 0L and set weak_sd <- !finite_positive_sd || (has_scale_ratio && any(finite_sd_ratios < 0.05)). This keeps the two structured-effect diagnostics logically identical and prevents future divergence, matching the message logic that already assumes a ratio may be absent.

---

### 2. names<- on scalar modelled rho_mu will error if cor_labels ever has length > 1
- **Location:** `R/drmTMB.R:16194` · PLAUSIBLE
- **Issue:** Line 16194 assigns names(rho_mu) <- spec$random$mu$cor_labels unconditionally, but in the modelled branch rho_mu is a length-1 mean (16189) while cor_labels is sized to n_cors. It is safe only because the corpair model is currently constrained to a single latent-correlation regression (abort at line 11254). Scalar-mean length and label-vector length are set by independent assumptions.
- **Failure scenario:** If the corpair parameterization is later extended so a modelled mu correlation spans n_cors > 1, split_tmb_corpars hits names(rho_mu) <- cor_labels with length(rho_mu)==1 and length(cor_labels)>1 and aborts during result assembly, breaking every fit using the feature.
- **Proposed fix:** Tie the reported vector length to the label length in the modelled branch (return one value per label, dropping the mean collapse), or guard with stopifnot(length(rho_mu) == length(spec$random$mu$cor_labels)) before assigning names, enforcing the coupling at the point of use rather than via a distant upstream abort.

---

### 3. Zero-one-inflated beta MI boundary test uses asDouble(x) so it is invisible to AD but relies on x being on-grid
- **Location:** `src/drmTMB.cpp:1319` · PLAUSIBLE
- **Issue:** In mi_family 10 (zero-one-inflated beta imputation) the observed and quadrature-node boundary tests use asDouble(x_i) <= 0.0 / >= 1.0 (lines 1319-1321, 1339-1341, 1381-1383) and similarly model_type 15 uses asDouble(y). Because the covariate mi_quad_nodes are fixed data this is safe for them, but for the observed value branch the density for an interior x uses log(x_i) and log(1-x_i); if a supplied observed proportion is exactly 0 or 1 it is routed to the boundary mass (correct), yet if it is a tiny epsilon inside (0,1) it takes the interior branch with log(x_i) fine. The concern is only that asDouble discards derivative information, which is acceptable here since x is data, but this pattern is fragile if x ever becomes a parameter (imputed continuous covariate on the boundary).
- **Failure scenario:** If the imputation model for a zero-one-inflated covariate is ever extended so the imputed x_miss (a PARAMETER) flows through this branch, asDouble(x) would make the boundary decision non-differentiable and independent of the parameter, silently detaching the boundary-mass term from the gradient and biasing the imputation.
- **Proposed fix:** Document that the asDouble(...) boundary dispatch is valid only because x here is observed data / fixed quadrature nodes, and add an assertion/comment that mi_family 10/15 boundary branches must not be reused for parameter-valued x. If a continuous imputed boundary covariate is added later, replace the asDouble branch with a smooth zero-one-inflated mixture evaluated with logspace_add so the gradient is preserved.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#712](https://github.com/itchyshin/drmTMB/issues/712) [review][low] Profile-CI, start-value & inference robustness (2 findings)
_labels: bug_

Batch of **low-severity** findings under the theme *Profile-CI, start-value & inference robustness* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. marginal_parameters averages sigma/correlation on the requested scale, which is not a moment-preserving marginal
- **Location:** `R/marginal-parameters.R:137` · PLAUSIBLE
- **Issue:** marginalise_parameter_predictions (lines 132-142) reports `mean(pred$estimate[idx])` for every distributional parameter, including sigma (an SD) and rho12 (a correlation), on whichever scale predict_parameters returned. For type="response", a plain arithmetic mean of per-row SDs is not the SD of any marginal distribution, and an arithmetic mean of correlations is not a valid pooled correlation. The docstring (lines 8-17) does disclaim this as an unweighted plug-in summary, so it is documented behavior, but the returned column is still named `estimate` with a per-parameter row, inviting users to read it as a marginal moment.
- **Failure scenario:** A user calls marginal_parameters(fit, newdata=grid, dpar=c("mu","sigma"), by="habitat", type="response") on a Gaussian model with a strong sigma ~ x formula so that per-row sigma spans, say, 0.1 to 10. The reported sigma `estimate` is the arithmetic mean (~5), which overstates the typical spread and does not equal the SD of the marginal mixture over the grid; a user comparing habitats on this number draws a misleading dispersion contrast.
- **Proposed fix:** Either (a) restrict averaging so that scale/correlation parameters are summarized on their unconstrained link scale by default (type="link") with an explicit note that response-scale averages of sigma/rho are not marginal moments; or (b) rename the output column for these parameters or add a `summary = "row_mean"` provenance column making explicit that the value is a row-wise mean of predicted parameters, not a marginal moment. Keep the current disclaimer but surface it in the returned table, not only the docstring.

---

### 2. Ultrametric requirement silently rejects valid non-ultrametric Brownian phylogenies
- **Location:** `R/phylo-utils.R:107` · PLAUSIBLE
- **Issue:** validate_phylo_tree aborts unless all root-to-tip distances are equal (line 107), and drm_phylo_augmented_precision calls it unconditionally (line 241). The branch-increment GMRF precision built at lines 259-289 is a valid Brownian-motion prior for NON-ultrametric trees as well; only the single-scalar `correlation` normalization by info$height (lines 224, 277-281, 303) actually assumes ultrametricity (tips then share one marginal variance). So a large class of biologically standard trees (fossil-calibrated, unequal-rate, non-clock trees) is rejected even though the underlying model is well defined.
- **Failure scenario:** A user with a time-calibrated mammal tree where extant and extinct tips have different root-to-tip path lengths (a common, valid phylo comparative dataset) passes it to a phylogenetic gaussian fit. validate_phylo_tree aborts with 'tree must be ultrametric' at line 107 even though a Brownian phylogenetic random effect is perfectly well specified for that tree; the user is forced to artificially force.ultrametric() the tree, distorting branch lengths and biasing the estimated phylogenetic signal / SD.
- **Proposed fix:** Split the check: keep the ultrametric assertion only when `correlation = TRUE` (where a single height-based normalization is meaningful), and allow non-ultrametric trees when `correlation = FALSE` (raw branch-length precision). For the correlation case with non-ultrametric trees, either (a) normalize each tip by its own root-to-tip depth via a diagonal rescaling of the tip block rather than a single scalar `height`, or (b) document explicitly that only ultrametric trees are supported on the correlation scale and expose the raw-scale path to users. Add a test with a non-ultrametric tree that succeeds under correlation=FALSE and recovers the correct tip covariance.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#713](https://github.com/itchyshin/drmTMB/issues/713) [review][low] Twin-divergence & duplicated logic (9 findings)
_labels: bug_

Batch of **low-severity** findings under the theme *Twin-divergence & duplicated logic* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. Gaussian start list carries duplicated eta_cor_sigma / eta_cor_mu_sigma names
- **Location:** `R/drmTMB.R:2944` · PLAUSIBLE
- **Issue:** gaussian_ls_start() already returns list entries eta_cor_mu_sigma (line 12807) and eta_cor_sigma (line 12808). At line 2944 the spec appends gaussian_ls_dummy_start(), which ALSO defines eta_cor_mu_sigma = 0 and eta_cor_sigma = 0 (lines 12887-12888). The resulting spec$start passed to TMB::MakeADFun (line 429) contains two entries with each of these names. R's `$` and `[[` resolve to the FIRST match, so for the common intercept-only case (both are scalar 0) there is no observed effect, which is why tests pass. But the trailing scalar-0 duplicates are silently carried into the parameter list and mask the real values from any code path that scans start by position or re-orders it.
- **Failure scenario:** Fit a univariate Gaussian with a correlated scale random slope, e.g. bf(y ~ x, sigma ~ x + (x | id)), so re_sigma$n_cors > 0 and gaussian_sigma_re_start() returns eta_cor_sigma as a length>=1 real vector (line 13983). spec$start then holds eta_cor_sigma = c(real vector) followed by eta_cor_sigma = 0. Any consumer that does not rely on TMB's first-match name lookup (a future map/override step that positionally splices start, or a stricter MakeADFun name-uniqueness check across TMB versions) will pick up the scalar 0, dropping the correlation starting value or triggering a length-mismatch abort.
- **Proposed fix:** Do not re-declare eta_cor_mu_sigma / eta_cor_sigma inside gaussian_ls_dummy_start(): remove those two entries (lines 12887-12888) since gaussian_ls_start() already supplies them, or de-duplicate after the c() at line 2944 with start <- start[!duplicated(names(start))]. Add a fit-spec invariant assert that any(duplicated(names(spec$start))) is FALSE right before TMB::MakeADFun so future duplicate-name regressions fail loudly rather than depending on R first-match semantics.

---

### 2. Family link tables are duplicated across three files with no single source of truth
- **Location:** `R/family.R:21` · PLAUSIBLE
- **Issue:** Each drm_family constructor in R/family.R declares its `links` vector (e.g. biv_gaussian at lines 21-27, student nu="logm2" at line 65, tweedie nu="logit12" at line 165). The response inverse-link resolver R/methods.R::drm_dpar_link (lines 4930-4977) re-declares the ENTIRE link table for every model_type independently, keyed by object$model$model_type rather than reading family$links. A third table of inverse-link derivatives lives in R/predict-parameters.R (lines 331-349). The three currently agree, but nothing enforces it: adding or editing a family in one place does not update the others.
- **Failure scenario:** A developer changes a family's link (e.g. switches tweedie `nu` from logit12 to a new bounded link, or adds a new family) in R/family.R and updates drm_inverse_link, but forgets drm_dpar_link's independent switch (or the predict-parameters.R derivative). Because drm_dpar_link is keyed by model_type and not by family$links, predict()/marginal_parameters()/profile then silently back-transform on the OLD link (e.g. still 1+plogis) while the C++ likelihood uses the NEW one, producing response-scale predictions and CIs that are internally inconsistent with the fitted model, with no error raised.
- **Proposed fix:** Make drm_dpar_link read the authoritative links from the family object (e.g. object$model$family$links, falling back to a single shared constant map keyed by family name) instead of re-listing them, and derive predict_parameters_inverse_link_derivative from that same map. If a full refactor is out of scope, add a unit test that asserts, for every exported family(), that family()$links == the drm_dpar_link table for that model_type and that every link has both an inverse and a derivative entry, so any future divergence fails fast.

---

### 3. Dead identical() clause in imputed() SE extraction obscures the intended x_miss match
- **Location:** `R/missing-data.R:4782` · CONFIRMED
- **Issue:** drm_imputed_missing_predictor_se() computes positions <- which(identical(random_names, "x_miss") | random_names == "x_miss"). identical(random_names, "x_miss") compares the whole par.random name vector to the scalar "x_miss"; for any fit with more than one random parameter (the normal case) it returns a single FALSE, which recycles harmlessly and contributes nothing. The clause is dead code that reads as if it were doing extra matching, and if a future edit ever relied on it the behaviour would be wrong.
- **Failure scenario:** A maintainer reading the predicate assumes the identical() term contributes to selecting x_miss positions and, e.g., changes the vectorized comparison believing the identical() branch covers a fallback. Because identical() on a length>1 vector is always FALSE, the fallback never fires; conditional SEs are silently dropped (returned as NA) with no diagnostic when the name vector layout differs from expectation.
- **Proposed fix:** Replace lines 4782-4784 with positions <- which(random_names == "x_miss"). The identical() disjunct is inert (always FALSE for the multi-parameter case it is meant to guard) and should be removed to make the intent explicit. If a diagnostic is desired when length(positions) != n_missing, keep the existing NA fallback but add a comment explaining that summed (finite-state) mi families legitimately have zero x_miss random parameters.

---

### 4. Count-support helpers name the observed-value argument "observed", colliding with the logical mask used everywhere else
- **Location:** `R/missing-data.R:2553` · CONFIRMED
- **Issue:** drm_poisson_mi_support(lambda, observed, ...) and drm_nbinom2_mi_support(mu, sigma, observed, ...) use max(observed, na.rm=TRUE) expecting the observed count *values*, and the call sites correctly pass x_raw[observed] (lines 2475, 2659, 2797). But everywhere else in this file the identifier "observed" is the logical NA mask (observed <- !is.na(x_raw)). drm_truncated_nbinom2_mi_support forwards the same arg to drm_nbinom2_mi_support at line 2931 as observed = observed, further blurring the two meanings. A future edit that passes the logical mask (as the name strongly suggests) would compute max(<logical>) = 1 and silently truncate the summation support to ~50, corrupting the marginalization.
- **Failure scenario:** A maintainer, trusting the parameter name, calls drm_poisson_mi_support(lambda, observed = !is.na(x_raw)); max(observed) becomes 1, so upper collapses to the floor of 50 (or qpois), truncating the count support. For a predictor with observed counts far above 50 the missing-value marginalization then omits most of the probability mass, biasing the conditional expected count without any error.
- **Proposed fix:** Rename the argument in drm_poisson_mi_support, drm_nbinom2_mi_support, and drm_truncated_nbinom2_mi_support from observed to observed_values (or observed_counts) and update the internal max(...) call and the forwarding at line 2931. Reserving the name "observed" for the logical NA mask (its meaning in the rest of the file) removes the copy-paste hazard between the value vector and the mask.

---

### 5. Interval-available filters silently drop bootstrap intervals
- **Location:** `R/plot-parameter-surface.R:353` · CONFIRMED
- **Issue:** plot_parameter_surface_interval_available() (R/plot-parameter-surface.R:352) and plot_corpairs_interval_available() (R/plot-corpairs.R:377) whitelist only conf.status/interval_source values of "wald" and "profile" (unavailable_status = setdiff(interval_status_levels(), c("wald", "profile"))). "bootstrap" is a legitimate interval_source per interval_source_levels() (R/profile.R:1211), so any finite bootstrap interval is treated as unavailable and its band/segment is dropped without warning.
- **Failure scenario:** A user assembles a compatible long table (the documented alternative input for plot_parameter_surface) whose intervals were produced by confint(fit, method = "bootstrap") and carry interval_source = "bootstrap". Passing it to plot_parameter_surface(..., interval = TRUE) silently renders point/line estimates with no bands, so the plot looks like intervals were unavailable when they were computed. Within the pure drmTMB predict path this cannot fire (predict_parameters only emits wald/not_requested), which is why severity is low, but the helper advertises acceptance of compatible tables.
- **Proposed fix:** Add "bootstrap" to the whitelist in both helpers, i.e. unavailable_status <- c("", setdiff(interval_status_levels(), c("wald", "profile", "bootstrap"))), matching interval_source_levels() which already treats bootstrap as a real source. This keeps the two twin filters in sync and prevents legitimate bootstrap bands from being silently discarded.

---

### 6. Correlation back-transform guard 0.999999 is duplicated as a literal across four call sites, risking twin/route divergence
- **Location:** `R/profile.R:3300` · PLAUSIBLE

> **Cross-package (twin) finding.** The fix must stay in lockstep between drmTMB and DRM.jl; the primary change lands in **drmTMB**, but confirm the sibling **DRM.jl** matches.
- **Issue:** The correlation guard 0.999999 appears as a bare literal in profile_transform_interval ('tanh' -> 0.999999 * tanh(interval), line 3300), profile_transform_values (line 976), rho_response default (methods.R line 4980-4981), and guarded_correlation_link calls (e.g. lines 3384, 3312). The 'tanh' branch multiplies tanh by 0.999999 directly while the 'rho12_tanh' branch routes through rho_response; the numeric guard must stay identical for the forward link and the inverse to round-trip. A future edit to one literal (or a mismatch with the DRM.jl port's guard) would make the profiled endpoints and the point estimate use different caps, silently shifting reported correlation CIs.
- **Failure scenario:** Someone tightens the guard in rho_response to 0.9999 for stability but misses the bare 0.999999 in profile_transform_interval's 'tanh' branch. A random-effect correlation profile (transformation 'tanh') would then back-transform its endpoints with 0.999999 while the fitted point estimate's link inverse uses 0.9999, so near |rho|~1 the reported interval no longer round-trips through the estimate and profile_interval_diagnostics could spuriously flag point_estimate_outside_interval, or report an interval inconsistent with the point estimate.
- **Proposed fix:** Define a single named constant (e.g. DRM_CORR_GUARD <- 0.999999) used by rho_response, guarded_correlation_link, profile_transform_interval, and profile_transform_values, and reference it everywhere instead of literals. Mirror the same named constant in the DRM.jl port so the twins cannot diverge on the correlation cap.

---

### 7. drm_sparse_fixed_parity reports same_names = FALSE spuriously because sparse.model.matrix dimnames differ from model.matrix
- **Location:** `R/sparse-fixed.R:33` · PLAUSIBLE
- **Issue:** The parity diagnostic compares identical(dimnames(dense), dimnames(sparse)). Matrix::sparse.model.matrix and stats::model.matrix routinely differ in their dimnames (notably row names and assign/contrasts attributes), so same_names can be FALSE even when the two design matrices are numerically identical (max_abs_matrix_diff == 0). A reviewer or test relying on same_names to certify dense/sparse parity would flag a false mismatch.
- **Failure scenario:** A parity test asserts isTRUE(drm_sparse_fixed_parity(terms, data)$same_names); with a factor predictor where sparse.model.matrix drops or reformats row names, the assertion fails despite the matrices being mathematically equal (max_abs_matrix_diff == 0, max_abs_eta_diff == 0), producing a misleading parity failure.
- **Proposed fix:** Compare only the load-bearing name that TMB depends on: colnames(dense) vs colnames(sparse) (identical(colnames(dense), colnames(sparse))) rather than full dimnames, since column names/order are what map beta coefficients; leave the numeric max_abs_matrix_diff / max_abs_eta_diff as the authoritative parity signals. Document that row-name divergence between the two builders is expected and not a parity failure.

---

### 8. Bivariate Gaussian analytic NLL duplicated verbatim between model_type 2 and model_type 95 (twin-divergence risk)
- **Location:** `src/drmTMB.cpp:472` · CONFIRMED
- **Issue:** The complete-row and partial-observation bivariate Gaussian negative-log-likelihood (z1,z2,one_minus_rho2, row_nll assembly) is written twice, essentially byte-for-byte: model_type 2 at lines 3488-3510 and the re_cov probe model_type 95 at lines 472-492. Both also independently recompute rho12 = 0.999999*tanh(eta_rho12). Any correction to the density (e.g. adding V_known to the analytic branch, changing the rho clamp, fixing a sign) must be made in both places or the two paths silently disagree; this is exactly the kind of duplication that lets one twin drift from the other.
- **Failure scenario:** A maintainer patches the bivariate density in model_type 2 (say tightens the rho clamp or adds a missing weights term) but forgets model_type 95. The probe/random-effect-covariance path then computes a different likelihood than the production path, so a covariance-block feature validated against model 95 gives wrong numbers once promoted, with no compiler error.
- **Proposed fix:** Factor the per-row bivariate Gaussian NLL (given mu1,mu2,log_sigma1,log_sigma2,rho12,y1,y2,observed flags,weight) and the rho12 = 0.999999*tanh(eta) transform into a single templated helper in drm_numeric.h (e.g. drm_bivariate_gaussian_row_nll and drm_bounded_corr), then call it from both model_type 2 and model_type 95. This removes the copy and guarantees the twins stay in lockstep.

---

### 9. Dead helper drm_log1p_pos and redundant small/direct branches in drm_log1p_exp_stable mask intent
- **Location:** `src/drm_numeric.h:5` · CONFIRMED
- **Issue:** drm_log1p_pos (lines 5-10) is never called anywhere in the C++ core. In drm_log1p_exp_stable (lines 15-22) the 'series' Taylor branch and the 'direct' log(1+x) branch are both computed and then discarded whenever eta>35 (stable=logspace_add(0,eta) is used) and are otherwise numerically equal to logspace_add(0,eta) for eta<=35; the whole small/series/direct machinery duplicates what logspace_add already does stably, and both CondExp branches are evaluated (and differentiated) by AD on every call.
- **Failure scenario:** Not a wrong-answer bug, but dead/redundant code raises maintenance risk: a future edit to 'fix' the series expansion could change behavior only in the unused branch, giving a false sense that log1p(exp(eta)) was patched, while the live path (logspace_add) is unchanged. It also adds needless AD tape work in a per-observation count-density inner loop.
- **Proposed fix:** Delete drm_log1p_pos (confirm no external caller). Replace the body of drm_log1p_exp_stable with a direct return of logspace_add(Type(0.0), eta), which is already the numerically-stable log1p(exp(eta)) used for eta>35; drop the unused series/direct/small intermediates. Keep the function name/signature so callers are unchanged.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>


---

# DRM.jl — 26 review issues (itchyshin/DRM.jl)

## [#301](https://github.com/itchyshin/DRM.jl/issues/301) [review][high] Independent-slope (:slope) start pins the identified slope axis tiny and leaves the unused axis free/unidentified
_labels: bug_

**Severity:** high · **Confidence:** CONFIRMED · **Category:** inference validity / identifiability
**Location:** `src/locscale_corr.jl:80`

### What's wrong
For `rk == :slope` the loadings are `Zη = [xᵢ 0]` (axis-1 carries the slope, axis-2 loads nothing), but `_corr_λ0(:slope) = [log(1e-3), 0.0, log(0.4)]` initializes L11=1e-3 (so Λ[1,1]≈1e-6 on the SLOPE axis) and L22=0.4 (so Λ[2,2]≈0.16 on the UNUSED axis). The comment claims 'the intercept axis is pinned to a tiny variance', but the tiny value lands on the identified slope axis while the genuinely unused axis is left at 0.16. Worse, `_fit_locscale` optimizes all three λ freely, so the unused axis-2 variance is a completely unidentified free parameter (nothing loads it), unlike `_fit_sigma_axis_re` which explicitly FIXES the unused axis at ε and only optimizes the identified one.

### Failure scenario
Fitting a `(0 + x | g)` independent random slope on any non-Gaussian family via `_fit_corr_locscale(...; rk=:slope)`: the optimizer starts the true slope-variance at ~1e-6 (mislabeled 'intercept') and treats the phantom axis-2 variance (init 0.16) as a free parameter it can move without changing the likelihood, producing a flat/near-singular outer problem, an unstable Λ̂, wrong `:recov` slope-variance estimate, and a rank-deficient observed-information Hessian → NaN/garbage SEs for the slope variance.

### Proposed fix
Mirror `_fit_sigma_axis_re`'s discipline: for `:slope`, either (a) hold the unused axis-2 variance FIXED at a tiny ε (optimize only over [βμ; βψ; logL11] with L21=logL22 pinned, extracting the logL11 gradient as in `_sigma_re_grad`), or (b) at minimum correct `_corr_λ0(:slope)` so the tiny variance pins the UNUSED axis and the slope axis starts at a sensible value, e.g. `[log(0.4), 0.0, log(1e-3)]`, and add a guard/test that the axis-2 variance stays pinned. Also fix the misleading comment (axis-1 is the slope, not the intercept). Add a simulation test that recovers a known independent-slope variance before wiring any family to this path.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#302](https://github.com/itchyshin/DRM.jl/issues/302) [review][high] Gamma quantile residuals use wrong shape for location-scale fits (sigma slot holds the shape, not sigma)
_labels: bug_

**Severity:** high · **Confidence:** CONFIRMED · **Category:** correctness
**Location:** `src/quantile_residuals.jl:48`

### What's wrong
_conditional_dist(fam::Gamma) computes the Gamma shape as alpha = 1/scales[:sigma]^2, which is correct only for the plain/ranef Gamma fits (gamma.jl stores scales[:sigma]=exp(psi)=sigma with alpha=exp(-2*psi)=1/sigma^2). But the coupled location-scale Gamma kernel uses a DIFFERENT convention: shape alpha = exp(psi) directly (locscale_kernels.jl line 91-96), and _build_locscale_drmfit stores scales[:sigma]=exp(Xpsi*beta_psi)=exp(psi)=alpha (locscale_frontend.jl line 112). So for a location-scale Gamma fit, scales[:sigma] IS the shape, and _conditional_dist then computes alpha_used = 1/alpha^2, producing a wildly wrong conditional distribution. residuals(fit; type=:quantile) dispatches to _quantile_residuals for any DrmFit including these, so the residuals are silently wrong. The header comment at locscale_kernels.jl line 15 even asserts coef(:sigma) is on the SAME scale as the fixed-only fit, but the Gamma line contradicts it (exp psi vs exp(-2 psi)).

### Failure scenario
Fit a Gamma location-scale model with a coupled RE, e.g. drm(bf(y ~ x + (1|g|grp), sigma ~ 1), Gamma(); data). The fit stores scales[:sigma]=alpha (say alpha=5). Call residuals(fit; type=:quantile). _conditional_dist builds Gamma(1/25, mu/(1/25)) = Gamma(0.04, 25*mu) instead of Gamma(5, mu/5). Every PIT value F(y) is computed from the wrong distribution, so the quantile residuals look grossly non-normal even for a perfectly-specified model, invalidating any goodness-of-fit diagnostic built on them.

### Proposed fix
Make the Gamma sigma-slot convention consistent across all fit routes, then key the residual mapping to it. Preferred: change _build_locscale_drmfit (or the Gamma locscale kernel) to store scales[:sigma] = exp(-0.5*psi) so that scales[:sigma]=sigma=1/sqrt(alpha) matches gamma.jl and the header claim, keeping _conditional_dist's alpha=1/sigma^2 correct everywhere. Alternatively, if the locscale coef(:sigma) is intended to be log-shape, dispatch _conditional_dist(::Gamma) on how the fit was built (store a scale-convention tag on the fit) and compute alpha accordingly. Add a regression test that fits both a plain and a location-scale Gamma with the same true CV and checks the quantile residuals are approximately N(0,1) in both.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#303](https://github.com/itchyshin/DRM.jl/issues/303) [review][medium] coevo_marginal computes logdetP with check=false, so a failed prior Cholesky silently poisons the marginal
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** numerical-hazard
**Location:** `src/coevolution_q.jl:209`

### What's wrong
In coevo_marginal, chP = cholesky(Symmetric(P) + 1e-10I; check = false) followed by logdetP = logdet(chP). With check=false, if the factorisation does not succeed (P badly conditioned when Λ is near-singular / an axis variance is tiny at large q), logdet(chP) reads an incomplete/garbage factor and returns a wrong or non-finite value with NO error. That logdetP feeds directly into ℓ = -jn - 0.5·logdetH + 0.5·logdetP, so the reported marginal log-likelihood is silently corrupted rather than rejected. fit_coevolution's negℓ only guards ℓ via isfinite, so a finite-but-wrong logdetP passes straight through and biases the optimiser.

### Failure scenario
At q=8 with an initial or trial Λ that is barely PD (one axis variance ~1e-6), P = kron(Q_cond, inv(Λ)) is very ill-conditioned; the ridged Cholesky with check=false returns issuccess=false but logdet still returns a finite wrong number. fit_coevolution accepts this evaluation as a valid marginal, and LBFGS with finite-difference gradients steps toward a spurious optimum, reporting a Λ that does not maximise the true marginal — an estimation error presented as a converged fit.

### Proposed fix
Use check=true (or test issuccess(chP) and return ℓ = -Inf on failure) so a non-PD prior factor makes the evaluation an explicit barrier rather than a silent garbage value. Concretely: replace the two lines with `chP = cholesky(Symmetric(P) + 1e-10I; check = false); issuccess(chP) || return (-Inf, û, chH, P); logdetP = logdet(chP)`. This matches the barrier discipline already used for the Schur complement in reml_q4.jl and for H in the fisherz path.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#304](https://github.com/itchyshin/DRM.jl/issues/304) [review][medium] lrtest chi-square reference is invalid when the extra parameter is a boundary variance component
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference-validity
**Location:** `src/comparison.jl:54`

### What's wrong
lrtest/anova computes pvalue = ccdf(Chisq(Delta_dof), statistic) with Delta_dof = dof(full) - dof(reduced) = difference in length(theta). dof counts random-effect SD parameters (:resd) and Cholesky covariance entries (:recov) as ordinary parameters. When the nested comparison drops a variance component (testing sigma_b = 0), the null value lies on the boundary of the parameter space, so 2*(loglik_full - loglik_reduced) is NOT asymptotically chi-square with Delta_dof df; the correct reference is a 50:50 mixture of chi-square_0 and chi-square_1 (single component). The naive chi-square_1 p-value is conservative (too large), so the test loses power and the reported p-value is not the stated chi-square tail probability. The docstring claims the statistic is asymptotically chi-square with Delta_dof df with no boundary caveat.

### Failure scenario
full = drm(bf(y ~ x + (1|g), sigma ~ 1), Gaussian(); data); reduced = drm(bf(y ~ x, sigma ~ 1), Gaussian(); data). lrtest(reduced, full) reports Delta_dof=1 and pvalue = ccdf(Chisq(1), stat). Under the null sigma_b=0 the true reference is 0.5*chi2_0 + 0.5*chi2_1, so the honest p-value is half the reported one; a user concludes the random effect is not needed (p=0.09) when the boundary-correct p is 0.045.

### Proposed fix
Detect when the dropped block(s) between reduced and full are variance components (:resd/:recov/:phylocov present in full but not reduced) and either (a) refuse the naive test with an informative error pointing to a bootstrap or a mixture-chi-square reference, or (b) apply the 50:50 chi-square mixture for a single boundary component (pvalue = 0.5*ccdf(Chisq(dofm1), stat) + 0.5*ccdf(Chisq(dof), stat)). At minimum, document the boundary caveat in the lrtest docstring and recommend bootstrap_ci / a parametric bootstrap LR reference for variance-component tests.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#305](https://github.com/itchyshin/DRM.jl/issues/305) [review][medium] LBFGS objective is exact but its gradient is a fresh 30-probe stochastic estimate each call
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference-validity
**Location:** `src/experimental/location_only.jl:294`

### What's wrong
In lbfgs_fit's fg!, the returned objective F (quad + logdetV) is computed exactly, but the variance-parameter gradient components G[k+1], G[k+2] depend on trVinv, which is a Hutchinson estimate of Tr(V^{-1}) drawn from a fresh randn(n) each fg! call (nprobe=30, no fixed seed). The beta gradient is exact; only the two variance gradients are noisy and non-reproducible. This is experimental code.

### Failure scenario
MoreThuente line search evaluates fg! at the same theta twice (or at nearby trial points); because trVinv is redrawn, G[k+1]/G[k+2] differ between calls and are inconsistent with the exact F. Near convergence, where the true variance gradients are ~1e-3, the 30-probe noise (relative error ~1/sqrt(30) ~ 0.18 on tr_SMS) can dominate, so the reported g_residual and 'converged' flag reflect noise, the line search can reject descent directions, and the EM-vs-LBFGS agreement gate (params < 0.05) can pass or fail depending only on the RNG state.

### Proposed fix
Make the variance gradient consistent with the exact objective. Since S'S is diagonal and M is already Cholesky-factored, Tr(S M^{-1} S') = sum_j STS_diag[j] * M^{-1}[j,j] can be computed EXACTLY and cheaply via the same Takahashi selected-inverse used by exact_traces (takahashi_selinv(chM) then sum STS_diag[j]*V_sel[j,j]); replace the nprobe Hutchinson loop with that exact diagonal. If a stochastic estimator must be kept, seed it once per fit (Random.seed! or a fixed probe matrix reused across all fg! calls) so the gradient is a deterministic function of theta, which is what LBFGS/MoreThuente assume.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#306](https://github.com/itchyshin/DRM.jl/issues/306) [review][medium] EM sigma^2 M-step mixes new beta with stale posterior mean and has no monotonicity guard
_labels: bug_

**Severity:** medium · **Confidence:** PLAUSIBLE · **Category:** correctness
**Location:** `src/experimental/location_only.jl:229`

### What's wrong
em_fit computes the posterior mean mu_post and the Takahashi traces at the OLD (beta, sigma2_phy, sigma2) (lines 214, 217), then updates beta via GLS to beta_new (line 222), and finally forms the sigma2 residual as e2 = y - X*beta_new - S*mu_post (line 229), i.e. new beta against the old-beta posterior mean. Unlike the q4_em_dense driver, em_fit has no marginal-loglik monotonicity safety net. Experimental code.

### Failure scenario
For a design where the GLS beta update moves substantially in one iteration (e.g. strong phylo signal with sigma2_phy0 far from truth at p=200), the cross term in ||y - X*beta_new - S*mu_post||^2 is evaluated at an inconsistent (beta_new, mu_post) pair, so sigma2_new is not the true conditional maximizer and marginal_loglik(beta,sigma2_phy,sigma2) can DECREASE across an EM iteration. The loop's only stopping rule is abs(ll - ll_prev) < reltol*(1+|ll_prev|) (line 240), which can trigger early on a non-increase and report a converged fit at a non-stationary point, silently failing the EM/LBFGS agreement gate's premise that EM reaches the MLE.

### Proposed fix
Recompute mu_post at beta_new before the sigma2 M-step (a second cheap chM\(S'(y-X*beta_new)/sigma2) solve), OR reorder to a standard ECM: update beta, refactor M is unchanged so reuse chM, recompute mu_post and e2 with beta_new consistently. Additionally, guard the loop by tracking marginal_loglik and only accepting an update that does not decrease it (mirror the guarded()/monotonicity assertion pattern already implemented in q4_em_dense.jl), so the timing/agreement gate cannot pass on a non-monotone run.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#307](https://github.com/itchyshin/DRM.jl/issues/307) [review][medium] Oracle E-step converges on step-size norm, the exact false-convergence bug the sibling e-step files were written to remove
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** correctness
**Location:** `src/experimental/q4_em_dense.jl:137`

### What's wrong
estep()'s inner Newton stops on norm(alpha*step) < tol (line 137), never on the true gradient norm. The sibling files (estep_armijoguard.jl, estep_lm.jl, estep_trustregion.jl, estep_initprior.jl) exist specifically because this exact test gives FALSE convergence once backtracking drives alpha tiny while ||grad|| is still large. Because q4_em_dense is described as the 'correctness-oracle', a false-converged E-step here contaminates the reference. Experimental code.

### Failure scenario
On an indefinite-far-from-mode instance (the log-sigma axes have vanishing observed curvature at small residual, as documented in estep_lm.jl), the backtracking line search shrinks alpha to ~1e-6 to keep joint_nll non-increasing; norm(alpha*step) then falls below tol=1e-9 and the loop breaks at a NON-mode u. estep returns that u plus Hinv = inv(H(u)); mstep_Lambda and laplace_loglik are then built on a non-stationary mode, so the 'oracle' logLik and Lambda used to validate the sparse fitters are themselves wrong, while the driver's monotonicity assert can still pass (it only checks the recorded sequence is non-decreasing, not that each E-step hit the mode).

### Proposed fix
Replace the stopping rule with a true first-order test: compute g at the new u and break on norm(g) < tol (as done in estep_armijoguard/estep_lm/estep_trustregion). Keep the backtracking for globalization but do not treat a tiny step as convergence; if the line search stalls with ||g|| still large, either escalate the ridge (Fisher/expected-information steering as in estep_lm) or flag non-convergence to the driver so the oracle never silently returns a non-mode.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#308](https://github.com/itchyshin/DRM.jl/issues/308) [review][medium] fz_init_from_Sigma has no PD/zero-variance guard and breaks at the exact SD-collapse boundary it must serve
_labels: bug_

**Severity:** medium · **Confidence:** PLAUSIBLE · **Category:** numerical-hazard/inference-validity
**Location:** `src/fisherz_q4.jl:119`

### What's wrong
fz_init_from_Sigma computes s = sqrt.(diag(Σ0)), d = log.(s), R = (Σ0 ./ s) ./ s', then C = cholesky(R).L with NO ridge and NO guard on a zero/near-zero axis variance. When an among-axis SD has collapsed to ~0 (diag(Σ0) ≈ 0), s→0 gives d = log(0) = -Inf and R gets 0/0 = NaN entries; even for a merely near-singular but strictly-PD correlation matrix, the bare cholesky(R) can throw PosDefException. This is precisely the boundary regime profile_sigma_a and the Fisher-z fit are designed to handle.

### Failure scenario
A user fits a q=4 phylogenetic location-scale model where sigma1 carries no phylogenetic signal, so the fitted Σ_a has diag ≈ [0.4, 0.5, 1e-9, 0.3]. Calling profile_sigma_a(fit) reaches profile_q4_phylo.jl:65 → fz_init_from_Sigma(Σa): the correlation matrix R = (Σa./s)./s' has a near-singular row 3, cholesky(R).L throws PosDefException (or NaN from the near-zero divide), and the entire profile-CI routine errors out on the one axis whose CI the user most needs — the collapsed one. The same crash seeds fit_q4_sparse_fisherz when Σa0 is near-singular.

### Proposed fix
Guard both the SD floor and the correlation Cholesky. (1) Replace s = sqrt.(diag(Σ0)) with s = sqrt.(max.(diag(Σ0), floor)) using a small positive floor (e.g. 1e-8) so d = log.(s) stays finite and R has no 0/0 entries. (2) Wrap the correlation Cholesky in a small ascending ridge loop mirroring _q4_re_prior_chol in bootstrap_q4_phylo.jl (try cholesky(Symmetric(R + ridge*I)) for ridge in (0, 1e-10, 1e-8, 1e-6)) so a near-singular R still yields a valid lower-triangular corr-Cholesky. Add a test that seeds fz_init_from_Sigma from a Σ0 with one axis variance = 1e-10 and asserts a finite φ_a is returned.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#309](https://github.com/itchyshin/DRM.jl/issues/309) [review][medium] Block-diagonal Σ_a start is inconsistent with non-default correlation tags
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** correctness
**Location:** `src/gaussian_bivariate.jl:394`

### What's wrong
In _fit_bivariate_q4_phylo the constrained warm start hard-codes zeroing of only the mu-vs-sigma cross block (Λ0[1:2,3:4] and [3:4,1:2]) whenever lc_zero is non-empty. But lc_zero is computed by _q4_block_lc_zero from ARBITRARY user correlation tags (phylo(1 | tag | group)), so the true block partition need not be {mu1,mu2} vs {sigma1,sigma2}. The inline comment even asserts 'the only pinned entries are mu↔sigma cross terms (axes 1,2 vs 3,4)', which is only true for the default tag layout. pack_theta(β0,Λ0) then runs Λ_to_lc on a Λ0 whose off-diagonals do not match the pinned pattern, and fit_q4_sparse_tmb force-zeros the pinned lc positions (line 326), producing a start whose kept cross-covariances are wrong and whose pinned entries are pruned from an inconsistent factor.

### Failure scenario
User writes phylo(1 | a | species) on mu1 and sigma1, and phylo(1 | b | species) on mu2 and sigma2 (blocks {mu1,sigma1}={1,3} and {mu2,sigma2}={2,4}). _q4_block_lc_zero pins the cross-tag Cholesky entries (e.g. L21, L41, L32, L43 depending on ordering), NOT the mu↔sigma block. The start code instead zeros Λ0[1,3]/Λ0[2,4]-type within-block covariances (which should be free) via the [1:2,3:4] mask and leaves Λ0[1,2] (which should be pinned to 0) nonzero until fit_q4_sparse_tmb clips it. The optimiser starts from a Λ whose intended block correlations are absent and whose pinned directions are inconsistently seeded, biasing the fitted 4x4 Σ_a toward the wrong block structure or converging slowly/incorrectly.

### Proposed fix
Replace the hard-coded Λ0[1:2,3:4] .= 0 mask with a start that is derived from the SAME lc_zero index set the fit will pin. Concretely: after building Λ0, compute lc0 = Λ_to_lc(Λ0), set lc0[lc_zero] .= 0.0, and rebuild Λ0 = lc_to_Λ(lc0) so the start factor is exactly block-consistent with the pinned pattern for ANY tag layout. Alternatively pass Λ0 through pack_theta and zero θ0[θ_zero] as the engine already does, and delete the now-redundant [1:2,3:4] block-mask and its incorrect comment. This guarantees the constrained start matches the constraint for general tags, not just the default {mu,sigma} split.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#310](https://github.com/itchyshin/DRM.jl/issues/310) [review][medium] REML reported Wald vcov omits the restricted-penalty curvature
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference validity
**Location:** `src/gaussian_locscale_phylo.jl:461`

### What's wrong
For the σ-phylo location-scale routes (asymmetric, separate, and the bivariate q=4 path in gaussian_bivariate.jl line 461), when method=:REML the fit re-estimates θ at the REML optimum but the reported vcov V is the finite-difference inverse of the ML marginal gradient's Jacobian (ML observed information), NOT the Hessian of the restricted objective nll_ML + 0.5·logdet S. The code comments acknowledge this ('the restricted-penalty curvature is omitted, as in drmTMB'). The consequence is that Wald SEs / CIs for variance components under REML use ML curvature evaluated at the REML point, which is not the correct REML information; it systematically mis-states variance-component uncertainty.

### Failure scenario
A user fits method=:REML on a phylo location-scale model with a moderate number of mean covariates (pμ large relative to G). REML shifts θ̂ and the restricted objective's curvature in the variance block differs materially from the ML curvature; the reported Wald SE for the σ-phylo SD (from V) is the ML observed information at θ̂_reml, so a reported 95% Wald interval will have incorrect width and nominal coverage will be off, while the point estimate is REML-corrected — an inference claim (interval/coverage) not matched by the vcov used.

### Proposed fix
Either (a) finite-difference the full restricted objective's Hessian (add the 0.5·logdet S penalty's second derivative to the score before differencing) so V is the true REML observed information, or (b) for variance components steer users to the already-implemented profile_ci (which re-optimises the correct route NLL per endpoint) and explicitly document/flag in the returned object that Wald V under REML is ML-curvature-only and should not be used for variance-component inference. At minimum, gate the claim: do not present Wald REML SEs for the resd/recov blocks without the caveat that they omit the restricted penalty curvature.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#311](https://github.com/itchyshin/DRM.jl/issues/311) [review][medium] Multi-RE vcov uses FD Hessian of an nll that returns a flat 1e18 penalty on Cholesky failure
_labels: bug_

**Severity:** medium · **Confidence:** PLAUSIBLE · **Category:** numerical hazard / penalty leaks into Hessian
**Location:** `src/gaussian_ranef.jl:387`

### What's wrong
`_fit_multi_ranef_gaussian` optimises with an analytic `grad!` but assembles the coefficient vcov as `inv(ForwardDiff.hessian(nll, θ̂))` (line 387). The `nll` (line 336) returns a constant `1e18` penalty when `cholesky(Symmetric(M + I); check=false)` fails, i.e. it has flat/discontinuous regions. If θ̂ lands where a small perturbation used by ForwardDiff's dual-number Hessian crosses into the penalty branch (near-singular capacitance at extreme σ ratios), the Hessian is polluted by the penalty constant, yielding a non-PD or garbage covariance and thus meaningless SEs — with no diagnostic to the user.

### Failure scenario
Two crossed random intercepts where one variance component is estimated very small (near boundary) so `M + I` is barely PD at θ̂. ForwardDiff evaluates `nll` at θ̂ (real branch) but its internal directional evaluations can straddle the `issuccess` boundary; the resulting Hessian mixes the true curvature with the 1e18 penalty, and `inv(...)` gives absurd variances that flow into `vcov(fit)` and any Wald inference / `predict(...; se=true)`.

### Proposed fix
Compute the vcov from the analytic information already available (the `grad!` machinery yields the pieces of the observed information), or use a Hessian of a smooth penalty-free objective evaluated in a neighbourhood guaranteed PD, and explicitly test `isposdef` on the assembled vcov, filling NaN with a documented warning (as the EM/sparse paths already do) when it is not PD. At minimum, guard `inv(ForwardDiff.hessian(...))` behind a PD check and warn instead of returning a silently corrupted matrix.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#312](https://github.com/itchyshin/DRM.jl/issues/312) [review][medium] Spatial correlation range: meandist divides by G^2-G and log(0) seed when coords coincide
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** numerical
**Location:** `src/gaussian_structured.jl:223`

### What's wrong
_fit_spatial_gaussian computes meandist = sum(Ddist)/(G^2 - G) and seeds the log-range at θ0[...] = log(meandist). With G=1 this divides by zero; with all site coordinates identical (or a single site) meandist=0 gives log(0) = -Inf as the range seed, poisoning the optimiser start. There is no guard on G>=2 or on distinct coordinates before this arithmetic.

### Failure scenario
A user calls drm with spatial(1 | site) where the data collapse to a single site level (G=1), or where coords accidentally repeat one location for all sites (e.g. a merge that dropped coordinate variation). meandist becomes NaN (0/0) or 0, and θ0 gets log(NaN)/-Inf; the LBFGS start is non-finite and the fit silently returns garbage (θ̂ with NaNs) or fails opaquely, with no diagnostic pointing at the coordinate/level problem.

### Proposed fix
Guard the spatial fitter: require G >= 2 with a clear error ('spatial(1 | site) needs at least 2 distinct sites; got G=…'), and require that at least one pairwise distance is positive (any(Ddist .> 0)) before computing meandist. Replace log(meandist) with log(max(meandist, eps())) or error if meandist is not finite/positive. This turns a silent non-finite start into an actionable message and prevents a NaN-seeded optimisation.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#313](https://github.com/itchyshin/DRM.jl/issues/313) [review][medium] Profile-likelihood ratio CI is a substitution profile that holds nuisance variances fixed at the MLE — not a true profile
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference-validity
**Location:** `src/heritability.jl:127`

### What's wrong
_ratio_profile enforces the ratio r=v by setting θ_focal = 0.5·log(v/(1-v)·S_others) with S_others frozen at the MLE (nll_with_focal_var only mutates θ[focal]); NO other parameter is re-optimised. A genuine profile-likelihood CI must re-maximise the likelihood over all nuisance parameters at each fixed v. Because the nuisance variances cannot adjust, the profiled deviance rises too steeply away from r̂, so the resulting interval is systematically too NARROW (anticonservative) whenever the focal and co-components/residual are correlated in the likelihood. The docstring markets method=:profile as 'a more honest (possibly one-sided) interval' at the boundary and as the safer path for the sparse all-node route (heritability.jl:218-220), but a substitution profile does not deliver profile-likelihood coverage.

### Failure scenario
A two-component fit phylo(1|species)+animal(1|id) where σ²_species and σ²_animal trade off against each other. heritability(fit; component=:species, method=:profile) fixes σ²_animal and σ²_resid at their joint-MLE values and only rescales σ²_species to hit each trial ratio v. The LR curve is steeper than the true profile (which would let σ²_animal absorb some variance), so the returned 95% CI is narrower than nominal and undercovers the true h² — while being presented to the user as the calibrated, boundary-safe alternative to the delta CI.

### Proposed fix
Either (a) implement a true profile: at each fixed v, re-optimise the stored NLL over all remaining free parameters subject to the ratio constraint (a constrained re-fit, as profile_sigma_a already does for the q4 SDs), or (b) if the cheap substitution profile is retained, downgrade the docstring claims: state explicitly that it is a substitution/conditional profile holding nuisance variances at the MLE, that it can undercover when components are correlated, and that it is NOT a coverage-calibrated profile-likelihood interval. A simulation that reports empirical coverage of the :profile CI for a 2-component model should accompany whichever choice is made.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#314](https://github.com/itchyshin/DRM.jl/issues/314) [review][medium] Exact outer gradient returns all-zeros on inner-mode failure, which reads as convergence
_labels: bug_

**Severity:** medium · **Confidence:** PLAUSIBLE · **Category:** optimizer misuse
**Location:** `src/locscale_grad.jl:54`

### What's wrong
When the inner Laplace mode fails to converge, `_ls_marginal_grad` returns a zero vector (`ok || return grad`). The paired `nll` returns the 1e18 sentinel, but a zero gradient at a finite-looking point signals stationarity to gradient-based optimizers. `_fit_locscale` has an explicit feasibility guard (locscale_fit.jl:136) that catches a final infeasible θ̂ and falls back to Nelder–Mead, so the top-level fit is protected — but the profiler's `_ls_profile_nll` LBFGS inner solve (locscale_profile.jl:53-69) relies on the same gradient and only screens the final `minval` against the sentinel, not intermediate zero-gradient stalls.

### Failure scenario
During a profile inner re-optimization near the variance boundary the inner mode fails at the LBFGS starting point: `g!` returns zeros, LBFGS immediately declares convergence at that infeasible start, `minval` may be a stale/partial value; if it happens to fall just below the 1e18/2 screen the endpoint search treats a non-optimized point as the constrained optimum, biasing the profile CI endpoint.

### Proposed fix
Have `_ls_marginal_grad` signal infeasibility distinctly rather than returning zeros — e.g. return `fill(NaN, length(θ))` on inner-mode failure so optimizers reject the step, and update callers to treat NaN gradients as infeasible (the `f`/`nll` sentinel already covers the value). Alternatively, in `_ls_profile_nll` verify the returned `xmin` produces a finite gradient with small norm before accepting `ok = true`.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#315](https://github.com/itchyshin/DRM.jl/issues/315) [review][medium] mixed_family NB2 treats the dispersion slot as log θ (θ=exp(slot)), but the univariate NB2 fitter treats it as log σ (θ=exp(-2·slot))
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** Twin-divergence / inconsistent parameterization across fitters
**Location:** `src/mixed_family.jl:45`

### What's wrong
In `_mf_obs_ll(::NegBinomial2, …)` (line 45) the size is `θ = clamp(d, …)` with `d = exp(slot)` (line 214), `_mf_disp_init(::NegBinomial2)` returns `log(θ_MoM)` (line 84-87), and `_mf_disp_v(::NegBinomial2, slot,…) = link_residual(…; dispersion = exp(slot))` (line 106). So the NB2 dispersion slot in the cross-family model is `log θ`. This is internally self-consistent, but it contradicts negbinomial.jl where the same conceptual `sigma` slot means `log σ` with θ=exp(-2·slot). The two DRM.jl NB2 fitters therefore assign different meanings to their reported dispersion coefficient, unlike Gamma/Beta which use `θ/φ = exp(-2·slot)` consistently in both places (mixed_family lines 53,59 use inv(d^2) for Beta/Gamma).

### Failure scenario
A user fits a univariate NB2 (slot=log σ, βσ e.g. -0.35 ⇒ θ=2) and a Gaussian×NB2 mixed model on the same data expecting the NB2 dispersion coefficient `βσ2` to be comparable. In mixed_family βσ2=log θ≈0.69 for the same θ=2. Comparing or transferring the two coefficients (or reusing a univariate σ start in the mixed fit) yields a size off by the exp(-2·)-vs-exp() transform, and any downstream code that assumes one convention silently mis-reports dispersion.

### Proposed fix
Align the NB2 dispersion slot across the twins: either (a) make mixed_family use `θ = exp(-2·slot)` for NB2 (so the slot is log σ everywhere), updating `_mf_obs_ll(::NegBinomial2)`, `_mf_disp_init(::NegBinomial2)` to return `-0.5·log(θ_MoM)`, `_mf_disp_v(::NegBinomial2)` to `dispersion=exp(-2·slot)`, and the bootstrap sampler mapping; or (b) explicitly document in both files that the NB2 dispersion coefficient uses different scales in the univariate vs cross-family fitters and why. Option (a) removes the divergence risk and keeps `βσ` comparable to the univariate fit.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#316](https://github.com/itchyshin/DRM.jl/issues/316) [review][medium] NB2 docstring claims coef(:sigma)=log θ and exp(coef) = size θ, but the code uses size = exp(-2·coef) = 1/σ²
_labels: documentation_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** API / documentation mismatch (wrong dispersion recovery)
**Location:** `src/negbinomial.jl:30`

### What's wrong
The NegBinomial2 docstring (lines 13-16 and the example at line 30) states that the sigma slot is `log θ` and that `exp(coef(fit, :sigma)[1])` is the estimated dispersion/size θ. But every NB2 fitter here computes `r = exp(-2 * ησ)` (e.g. lines 143, 197, 232, 273, 304, 364), i.e. size θ = exp(-2·coef(:sigma)) = 1/σ². This matches the canonical drmTMB (drm_count_kernels.h:33 alpha=exp(2·log_sigma), size=1/alpha; R/missing-data.R:2792,2903 size=1/sigma^2). So coef(:sigma) is log σ, not log θ, and the documented recovery is inverted-and-squared.

### Failure scenario
A user fits `drm(bf(y~x, sigma~1), NegBinomial2())`, reads the docstring, and computes `exp(coef(fit,:sigma)[1])` expecting the NB2 size θ. If the true size is θ=4 (σ=1/2), coef(:sigma)=log(0.5)=-0.693, so exp(coef)=0.5 — they report a dispersion of 0.5 instead of 4, an 8× error, and any variance μ+μ²/θ they derive is wildly wrong.

### Proposed fix
Fix the docstring to state the actual convention: `coef(fit, :sigma)` is `log σ`, and recover the NB2 size as `exp(-2 * coef(fit, :sigma)[1])` (i.e. θ = 1/σ²), matching the Gamma/Beta docstrings which already say `exp(-2 * coef(...))`. Change the line-30 example comment from `# estimated dispersion θ (size)` on `exp(coef(fit, :sigma)[1])` to `exp(-2 * coef(fit, :sigma)[1]) # estimated size θ = 1/σ²`, and correct the prose at lines 13-16 that describe the slot as `log θ`.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#317](https://github.com/itchyshin/DRM.jl/issues/317) [review][medium] estep fast path accepts a loosely-converged mode into the frozen-mode Laplace marginal
_labels: bug_

**Severity:** medium · **Confidence:** PLAUSIBLE · **Category:** inference-mode-accuracy
**Location:** `src/sparse_aug_plsm.jl:224`

### What's wrong
_estep_fast returns ok=true on a line-search stall whenever ng < stall_tol with stall_tol=1e-3 (lines 223-224, 230), and estep_mode then builds laplace_ll at that b-hat. The frozen-mode Laplace approximation assumes grad_b joint = 0 exactly; a residual gradient ~1e-3 leaves an O(grad) error in b-hat and biases 0.5*logdet(H) and the joint term because H is evaluated off the mode. The phylo/crossed FG paths elsewhere deliberately drive the inner mode to ~1e-8 because a 1e-6 mode already pollutes the marginal gradient; accepting 1e-3 here is three orders looser.

### Failure scenario
In the bivariate q4 PLSM EM (fit_em_aug), a warm E-step on a stiff leaf (small residual, near-flat/indefinite log-sigma curvature) stalls at ng about 1e-3 and is accepted. laplace_ll is computed off-mode; across EM iterations the marginal can move by amounts comparable to the mode error, which the assert all(diff(ll_hist) .>= -1e-7) monotonicity guard (sparse_em_fit.jl line 137) can trip and abort the fit; if it does not trip, reported logLik and Lambda are biased.

### Proposed fix
Tighten stall_tol to ~1e-6 for the acceptance branch, or fall back to _estep_robust whenever ng >= 1e-6 (it already handles the indefinite log-sigma curvature), so a stalled fast step is accepted only when genuinely at the mode. Add a test comparing laplace_ll at the accepted b-hat against a tightly re-converged b-hat to the marginal tolerance.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#318](https://github.com/itchyshin/DRM.jl/issues/318) [review][medium] NB2 crossed-RE dispersion start has wrong sign and factor
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** correctness-start-value
**Location:** `src/sparse_laplace_glmm.jl:2744`

### What's wrong
In _fit_nb2_crossed_laplace the sigma-axis start is theta_sigma0 = log(max(m^2/max(v-m,...),0.5)). But the crossed aux_from (lines 2737-2740) defines the NB2 size as r = exp(clamp(-2*logsigma,...)), i.e. size = exp(-2*theta_sigma) with theta_sigma = logsigma. The MoM size estimate is s_MoM = m^2/(v-m), so the correct start is theta_sigma0 = -0.5*log(s_MoM). Every other NB2 route does this: _nb2_laplace_setup (line 1109) uses -0.5*log(...), and the gamma/beta crossed fitters (lines 2771/2795) use -0.5*log(alpha0)/-0.5*log(phi0). Line 2744 is the lone outlier: it drops the -0.5 factor AND flips the sign, initializing at +log(s_MoM), which the aux turns into size = 1/s_MoM^2, the reciprocal-squared of the intended dispersion.

### Failure scenario
Fit an overdispersed count with two crossed random intercepts via _fit_nb2_crossed_laplace, mean m=5 var v=25 so s_MoM=1.25. Correct start size 1.25 vs buggy size 0.64. For s_MoM=10 the correct start gives size 10 but the buggy start gives size 0.01, a 1000x error placing the optimizer deep in an over-dispersed corner where the inner Newton mode and LBFGS/BackTracking step can stall or land in a poor region, yielding wrong dispersion/mean estimates or a non-converged flag.

### Proposed fix
Change line 2744 to theta_sigma0 = -0.5 * log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5)), matching _nb2_laplace_setup (line 1109) and the gamma/beta crossed fitters (lines 2771, 2795), so the NB2 crossed start uses the same logsigma scale (size = exp(-2*logsigma)) the aux consumes. Add a regression test asserting the crossed NB2 start size equals the MoM size.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#319](https://github.com/itchyshin/DRM.jl/issues/319) [review][medium] Fixed absolute step h=1e-3 in _finite_hessian gives scale-blind SEs and can silently fabricate identity covariance
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference-SE
**Location:** `src/sparse_laplace_glmm.jl:85`

### What's wrong
_finite_hessian uses a single absolute step h=1e-3 for every coordinate of theta when forming the Hessian that produces the reported covariance V for all se=true fits (inv(Symmetric(H_theta))). theta mixes link-scale beta with logsigma/log-dispersion and random-effect logsigma. A fixed absolute step is not scale-aware: too coarse for a sharply-curved dispersion axis, and near the clamps (clamp(theta[p+1], -8, 3)) the +/-h stencil can straddle the boundary and sample a flat region, understating curvature. When the Hessian is non-PD the catch block silently substitutes the identity (lines 468-470, 731-733, 926-928, 1079-1081, 1641-1643, 2530-2532), reporting unit-variance SEs with no warning.

### Failure scenario
A Gamma or NB2 phylo fit converges with dispersion near the clamp interior with steep curvature; the +/-1e-3 stencil on the logsigma axis crosses into a nearly-flat FD region so H[sigma,sigma] is underestimated and the dispersion SE inflated; or the FD Hessian is indefinite and the catch returns Matrix(I) so the user gets SEs of exactly 1.0 for every parameter, a silently wrong inference.

### Proposed fix
Make the step relative per coordinate, e.g. h_i = max(1e-4, 1e-4*(1+abs(x_i))), keep the stencil strictly inside the clamp bounds, optionally Richardson-extrapolate. When the FD Hessian is not PD do not silently return the identity: set V to NaN (or warn and set converged=false) so SEs are visibly missing rather than fabricated as 1.0.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#320](https://github.com/itchyshin/DRM.jl/issues/320) [review][medium] coeftable/show report z and two-sided p-values against meaningless nulls for log-sigma, atanh-rho12 and log-sigma_b blocks
_labels: bug_

**Severity:** medium · **Confidence:** CONFIRMED · **Category:** inference-validity
**Location:** `src/summary.jl:164`

### What's wrong
coeftable (line 164-167) and Base.show (line 117-118) compute z = estimate/se and pval = 2*ccdf(Normal, |z|) for EVERY block on its working scale. For the :sigma block (log sigma) the implicit null is log sigma = 0 i.e. sigma = 1; for :rho12 (atanh rho12) the null is rho12 = 0; for :resd (log sigma_b) the null is log sigma_b = 0 i.e. sigma_b = 1 (not the scientifically relevant sigma_b = 0 boundary, which is -Inf on the log scale and untestable by Wald anyway); for :recov the Cholesky entries have no interpretable individual null. Presenting a Pr(>|z|) column uniformly across these blocks invites users to read, e.g., the sigma-intercept p-value as a test of whether there is any dispersion, or the sigma_b p-value as a random-effect significance test, both of which are wrong.

### Failure scenario
A user fits drm(bf(y ~ x + (1|g), sigma ~ 1), Gaussian()) and reads the printed table. The :resd row shows Coef=0.7 (log sigma_b), z=3.5, Pr(>|z|)=0.0005 and the user reports 'the random effect is highly significant (p=0.0005)'. That p-value is a Wald test of sigma_b = 1 (an arbitrary scale reference), not of sigma_b = 0; it neither supports nor refutes the presence of the random effect.

### Proposed fix
Suppress or clearly annotate the z/p columns for blocks where the zero-on-working-scale null is not meaningful. Concretely: for :sigma/:sigma1/:sigma2/:resd/:resid/:recov/:phylocov print the estimate and SE but blank the z and Pr(>|z|) cells (or footnote them as 'null = working-scale zero; not a variance-presence test'). Keep z/p only for :mu/:mu1/:mu2 (and optionally :rho12 where rho12=0 is a real null). Document in the coeftable docstring which blocks carry an interpretable Wald test.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#321](https://github.com/itchyshin/DRM.jl/issues/321) [review][medium] VA inner Newton solve can diverge: undamped m-step and sign-flipped det guard
_labels: bug_

**Severity:** medium · **Confidence:** PLAUSIBLE · **Category:** numerical-hazard
**Location:** `src/variational.jl:90`

### What's wrong
All five inner solves (_poisson_va_inner and _binom/_nb2/_gamma/_beta_va_inner) run a FIXED count of raw 2x2 Newton steps toward the ELBO maximiser but only clamp Δr; Δm is unbounded, there is no ascent/line-search check, and the near-singular guard replaces a tiny determinant with ±eps(T) instead of regularising the Hessian. When the 2x2 Hessian is near-singular (small det), dividing the gradient by ±eps(T) produces an enormous Newton step; combined with an unbounded Δm this throws (m,s) far from the maximiser, and because the outer ForwardDiff differentiates THROUGH these unrolled iterates, the outer gradient/ELBO is then corrupted rather than merely inaccurate.

### Failure scenario
A group with a strong prior (large τ = 1/σ² because logσ is very negative during an early LBFGS step) and few members makes Hmm=-E-τ and Hrr both small in magnitude relative to Hmr, so det=Hmm*Hrr-Hmr² passes near zero; the guard sets det=±eps(T)≈2.2e-16, and Δm = -(Hrr*gm - Hmr*gr)/det becomes ~1e15. m jumps to a wild value, E=exp(m+s/2)*S overflows to Inf, and nll(θ) returns Inf/NaN for that θ. The outer optimiser then stalls or the reported ELBO/vcov (inv(ForwardDiff.hessian(nll,θ̂))) is garbage.

### Proposed fix
Regularise instead of sign-flipping: since the inner problem is concave (H≺0), Levenberg-damp the Newton step — e.g. add -λ·I to H with λ grown until det is safely negative, or fall back to a gradient-ascent step when |det|<tol. Clamp Δm the same way Δr is clamped (e.g. clamp(Δm,-4,4)) and add a simple Armijo backtracking check that the group ELBO F actually increased before accepting the step. Optionally break early once ||g|| is below a tolerance. This keeps the map smooth for ForwardDiff while preventing the eps(T)-division blow-up.

---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#322](https://github.com/itchyshin/DRM.jl/issues/322) [review][low] Docs & API-naming consistency (4 findings)
_labels: documentation_

Batch of **low-severity** findings under the theme *Docs & API-naming consistency* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. Docstring claims the q=2 Fisher-z case reduces to z = atanh(rho), but the spherical map gives rho = cos(pi*(tanh(z)+1)/2)
- **Location:** `src/fisherz_q4.jl:16` · CONFIRMED
- **Issue:** The header and comments (fisherz_q4.jl:16-17, 39-42) state that for 2×2 the construction 'reduces to z = atanh ρ, the verified q2 case'. But the actual angle map is α = π·(tanh(θ)+1)/2 and C[2,1] = cos(α), so ρ = R[2,1] = cos(π·(tanh(θ)+1)/2). That is NOT the Fisher-z bijection ρ = tanh(z); it is a different (still valid, still bijective onto (-1,1)) reparameterisation. Both keep R interior/PD, so this is not a correctness bug, but the stated equivalence to the 'verified q2 Fisher-z' path is false and could mislead a reviewer into assuming the q2 verification transfers verbatim.
- **Failure scenario:** A reviewer or maintainer, trusting the 'reduces to z = atanh ρ' claim, back-transforms a fitted θ_R via ρ = tanh(θ_R) (the Fisher-z inverse the docstring names) instead of ρ = cos(π·(tanh(θ_R)+1)/2), and reports a wrong among-axis correlation; or assumes the q2 Fisher-z coverage results certify this q4 angle parameterisation without re-checking.
- **Proposed fix:** Correct the comments to describe the map accurately: it is an LKJ/spherical correlation-Cholesky using an angle α = π·(tanh θ + 1)/2, giving ρ = cos(α) for the 2×2 case — a robust interior-PD parameterisation, but distinct from the atanh/Fisher-z link. Remove or qualify the claim that it 'reduces to z = atanh ρ'. If genuine continuity with the q2 Fisher-z verification is desired, state that only the PD/interior property carries over, not the specific link function.

---

### 2. Bivariate residual init: 'rho intercept starts at 0' comment sits on the sigma2 line
- **Location:** `src/gaussian_bivariate.jl:204` · PLAUSIBLE
- **Issue:** In _fit_bivariate_residual the warm start sets theta0[offs[3]+1] (sigma1 intercept) and theta0[offs[4]+1] (sigma2 intercept), and the trailing comment '# rho intercept starts at 0' is attached to the sigma2 assignment on line 204. The rho12 block (rng(5)) is in fact left at the zeros(...) default, which is correct, but the comment's placement suggests an assignment that is not there and could invite a maintainer to misread which block is being seeded. Purely cosmetic (the numbers are right), but the same idiom is duplicated across twin fitters, so a wrong copy could seed the wrong block.
- **Failure scenario:** A future edit that reorders the offs blocks or copies this init into another fitter follows the misleading comment and writes the sigma2-start value into the rho12 slot (or vice versa), silently changing the optimiser start for rho12 from 0 to a log-sd value; because tanh(large) saturates to +/-1 the fit then starts on a near-degenerate correlation and can stall or converge to a different local optimum than the drmTMB twin.
- **Proposed fix:** Move the comment onto its own line above the block-seeding section and make intent explicit, e.g. add '# rho12 block (rng(5)) intentionally left at 0 (atanh scale => rho=0)' after the sigma2 line, keeping the sigma2 comment on its own seed. No numeric change; optionally add an explicit theta0[rng(5)] .= 0.0 for self-documentation.

---

### 3. re_sd/vc do not surface the multi-component or scale-RE variances uniformly
- **Location:** `src/gaussian_core.jl:956` · CONFIRMED
- **Issue:** The random-effect variance accessors are inconsistent across the Gaussian RE fitters. `re_sd` (gaussian_core.jl line 1602) and `vc` (gaussian_ranef.jl line 275) read only `:resd` and `:recov` blocks. The scale-RE fitter `_fit_sigma_ranef_gaussian` stores its RE SD in a `:resd` block (so `re_sd` reports it) but the value is σ_b on log-σ scale, while `_fit_ranef_gaussian`'s `:resd` is σ_b on the response scale — the same accessor mixes two different scales under one name. This is a latent API-inconsistency hazard rather than a numeric bug: a user comparing `re_sd(fit)` across a mean-RE fit and a sigma-RE fit gets values on incomparable scales with no label distinguishing them.
- **Failure scenario:** User fits `bf(y ~ x, sigma ~ 1 + (1|g))` and `bf(y ~ x + (1|g), sigma ~ 1)` and reads `re_sd(fit)[:g]` from each expecting comparable random-intercept SDs; the first is the SD of a random intercept on log σ, the second on the mean, but both are surfaced identically, inviting a wrong side-by-side interpretation.
- **Proposed fix:** Tag the scale-axis random-effect SD distinctly (e.g. key it `Symbol(grp, "_logsigma")` or add an axis field to the `:resd` coefnames) so `re_sd`/`vc` make clear the sigma-RE variance lives on the log-σ scale, and document in the `re_sd` docstring which axis each reported SD belongs to.

---

### 4. meta_V docstring and comments name the residual scale 'tau' instead of the mandated 'sigma'
- **Location:** `src/gaussian_meta.jl:13` · CONFIRMED
- **Issue:** The public API rule (CLAUDE.md) requires 'sigma', not 'tau', in user-facing text. gaussian_meta.jl's header comment (line 4, 'a single between-study tau') and the exported meta_V docstring (line 13, 'The residual heterogeneity (tau) is the sigma parameter'), plus inline comments at lines 24/27/36/44 (log tau, tau below the total residual sd, sqrt(v + tau^2)), all present tau as the residual-scale name. This is doc-only (the code uses the sigma formula correctly), but it is exactly the naming the API rule forbids and it is the drmTMB twin's user-facing documentation.
- **Failure scenario:** A drmTMB/DRM.jl user reading ?meta_V in DRM.jl sees the residual heterogeneity called 'tau' and, following the shown convention, searches for a tau argument or reports results as 'tau', diverging from the sigma-only public vocabulary enforced in the R twin and elsewhere in the package.
- **Proposed fix:** Rewrite the header comment, docstring, and inline comments in gaussian_meta.jl to use 'sigma' (the residual/between-study heterogeneity SD) throughout, e.g. 'sigma ~ 1 gives a single between-study heterogeneity SD sigma', 'log sigma_i', and 'sqrt(v + sigma^2)'. Keep a single parenthetical '(the between-study tau of classical meta-analysis)' at most, to match the drmTMB convention of mentioning tau only as an explanatory aside.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#323](https://github.com/itchyshin/DRM.jl/issues/323) [review][low] Inference reporting & SE/covariance robustness (3 findings)
_labels: bug_

Batch of **low-severity** findings under the theme *Inference reporting & SE/covariance robustness* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. Missing-response fixed-effect guard admits a saturated (residual dof 0) fit without warning
- **Location:** `src/gaussian_core.jl:591` · PLAUSIBLE
- **Issue:** `_fit_fixed_gaussian_missing_response` requires `n_observed >= size(Xμ,2) + size(Xσ,2)` (line 591), i.e. it accepts the case `n_observed == pμ + pσ`. For a Gaussian location–scale model that is a saturated fit: the mean interpolates the data, residuals are ~0, and `log σ` is driven to −∞ (or the ML fit is degenerate). The σ-phylo route just below (lines 344–346) explicitly warns when `n_obs == total_dof` (residual dof 0), but this fixed-effect missing-response path uses `>=` and emits no residual-dof-0 warning, unlike its structured sibling — an inconsistency between the two code paths.
- **Failure scenario:** A dataset with exactly `pμ + pσ` observed responses (rest missing) and `bf(y ~ x, sigma ~ 1)`: the fit passes the guard, the mean block interpolates so residuals collapse, `log σ` heads to −∞, and the returned logLik/SEs are meaningless while the user gets no signal that the model is saturated.
- **Proposed fix:** Mirror the σ-phylo guard: keep the hard error for `n_observed < pμ + pσ`, but add a `@warn` (or require strict `>`) when `n_observed == pμ + pσ` stating the fit is saturated (residual dof 0) and inference is unreliable, so the fixed-effect missing-response path is consistent with the σ-phylo path at lines 344–346.

---

### 2. Boundary standard errors coerced to Inf produce (-Inf, Inf) Wald intervals and NaN z/p downstream
- **Location:** `src/inference.jl:29` · CONFIRMED
- **Issue:** stderror maps any non-finite or non-positive stored variance to Inf via _boundary_se. This is a deliberate, documented choice (avoid poisoning the whole SE vector with NaN), but the Inf then flows into _wald_ci as est +/- z*Inf = (-Inf, Inf) and into summary.jl as z = est/Inf = 0 with pval = 2*ccdf(Normal,0) = 1.0. The (-Inf, Inf) interval is defensible as 'undefined/unbounded', but the z=0, p=1 cell in the coefficient table is misleading: it reads as a decisive non-significant result for a coefficient whose information matrix was actually singular (unidentified), not as 'no information'. There is no flag in the row distinguishing a genuine z=0 from a boundary-Inf-SE z=0.
- **Failure scenario:** A model sits on a variance boundary so vcov has a non-PD direction; stderror returns Inf for that coefficient. coeftable prints that row as z=0.0000, Pr(>|z|)=1, Lower=-Inf, Upper=Inf. A user scanning the p-value column reads 'p=1, clearly not significant' rather than 'this direction is unidentified and the SE is undefined'.
- **Proposed fix:** When se is Inf (boundary/singular direction), emit z and Pr(>|z|) as NaN (not 0 and 1) in coeftable/show, matching drmTMB's all-NaN sdreport behaviour and making the unidentified direction visible rather than looking like a confident null. Keep the (-Inf, Inf) interval but consider printing 'unident.' in the SE cell. Cross-reference check_drm's vcov_posdef flag in the docstring so users know to inspect it.

---

### 3. Sigma-axis Wald covariance uses unsymmetrized FD Hessian and inv without PD check
- **Location:** `src/locscale_sigma.jl:187` · PLAUSIBLE
- **Issue:** `_fit_sigma_axis_re` builds the SE covariance as `Matrix(inv(Symmetric(H)))` where `H[:,j]` is a one-sided-column central-difference Jacobian of `_sigma_re_grad`. Unlike `_ls_obs_information` (locscale_infer.jl:28) which symmetrizes with `(H+H')/2` before inverting, this path wraps the raw asymmetric H in `Symmetric` (which just reads the upper triangle, discarding the lower half rather than averaging) and inverts without checking positive-definiteness. Near a variance boundary the FD Hessian can be indefinite/asymmetric, so `Symmetric(H)` silently keeps only one triangle and `inv` can return a non-PD covariance with negative diagonal (→ NaN SEs downstream) or an unstable estimate.
- **Failure scenario:** Standalone `sigma ~ 1 + (1|g)` fit with τ̂ near 0: the FD Hessian's off-diagonal logL11 entries are asymmetric and the matrix is near-indefinite; `inv(Symmetric(H))` yields a covariance whose logL11 variance is negative, so the reported `re_sd` SE is NaN with no diagnostic.
- **Proposed fix:** Symmetrize before inverting (`Hs = Symmetric((H+H')/2)`) to match `_ls_obs_information`, and reuse `_ls_vcov`/`_ls_se` (which already fall back to NaN on `SingularException`) instead of the bespoke `inv` here, so the sigma-axis and coupled paths produce SEs by the same guarded route.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#324](https://github.com/itchyshin/DRM.jl/issues/324) [review][low] Numerical stability guards (7 findings)
_labels: bug_

Batch of **low-severity** findings under the theme *Numerical stability guards* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. Univariate bridge inference silently returns the first result row when no SD row exists
- **Location:** `src/bridge.jl:78` · PLAUSIBLE

> **Cross-package (twin) finding.** The fix must stay in lockstep between drmTMB and DRM.jl; the primary change lands in **DRM.jl**, but confirm the sibling **drmTMB** matches.
- **Issue:** drm_bridge_inference (profile path) calls profile_result with parm=[:resd_sigma,:resd,:resd_mu] and then _bridge_pick_sd_row scans for those params, but if none is present it falls back to `first(rows)` (line 159). The R side (drm_julia_call_inference in julia-bridge.R) surfaces the returned estimate/lower/upper as the confint for the model's SD/variance component. If the profiled result ever comes back with only fixed-effect or differently-named rows, the bridge hands back a fixed-effect coefficient's interval labelled as the variance-component CI, with no error.
- **Failure scenario:** A future DRM.jl fit whose profile_result labels the phylo SD row as e.g. :sd or :sigma_phylo (renamed) rather than one of {:resd_sigma,:resd,:resd_mu}: _bridge_pick_sd_row's loops all miss, `first(rows)` returns the μ-intercept row, and confint(fit) on the R side reports the intercept's profile interval as the phylogenetic SD confidence interval — a wrong, un-flagged inference result.
- **Proposed fix:** Remove the silent `return first(rows)` fallback for the SD picker. If none of the expected SD params is found, throw an ArgumentError naming the params that WERE returned (the empty-rows case already throws). Alternatively pass the expected SD param set in and assert row.param is in it before returning. This converts a silent mislabelled-inference bug into a clear failure that the parity tests will catch.

---

### 2. Trust-region step cap uses inf-norm scaling that does not bound the L2 step, weakening the anti-collapse guard on large p
- **Location:** `src/experimental/estep_lm.jl:166` · PLAUSIBLE
- **Issue:** estep_lm caps the step by sc = min(1, trust/max(maximum(abs,step),eps())) (default trust=5.0), i.e. it bounds the inf-norm of the scaled step to 5. The stated purpose (header, lines 62-67) is to prevent a single catastrophic step into the sigma->0 collapse region. For a 4*n_total-dimensional u the inf-norm cap does not bound how far the whole log-sigma field moves collectively along the soft constant-shift tree direction. Experimental code, and the header already concedes p>=500 does not converge.
- **Failure scenario:** At p=1000 the softest prior direction is a near-uniform downward shift of all log-sigma axes (documented cause (2) in the header). A step whose entries are each ~4 in that coordinated direction has inf-norm ~4 < trust=5 so it passes the cap uncapped, yet moves the entire scale field down by a large amount in one accepted iteration, exactly the collapse the trust region was meant to prevent; the backtracking-on-joint_nll then still accepts it because the overfit lowers joint_nll. Result: the 'bounded' guarantee is weaker than advertised at large p.
- **Proposed fix:** Bound the L2 (or scaled) norm of the step against a radius Delta rather than the inf-norm (as estep_trustregion.jl already does with norm(s) > Delta), or add an explicit per-iteration cap on the mean log-sigma shift. Since estep_lm's own header admits p>=500 degeneracy, at minimum align the docstring with the actual inf-norm behavior so callers do not over-trust the anti-cascade claim.

---

### 3. Bivariate residual σ seed can be log(eps) when the mean design is saturated
- **Location:** `src/gaussian_bivariate.jl:203` · PLAUSIBLE
- **Issue:** The residual bivariate identifiability checks (lines 158-161) accept count(obs1) >= size(X1,2) with equality allowed (zero residual degrees of freedom). The σ1/σ2 start values at lines 203-204 use log(sqrt(mean(residual^2)) + eps()). When the observed count equals the number of mean coefficients (saturated fit), the fitted residuals are exactly zero, so the seed collapses to log(eps()) ≈ -36, an extreme starting log-σ that can stall LBFGS or drive exp(-ls) to overflow in the first evaluation.
- **Failure scenario:** A small dataset where response y1 has exactly p1 observed rows equal to the number of mu1 columns (e.g. 3 observed points, 3-parameter mean including intercept and two covariates). β1 fits the points exactly, residual variance is 0, and θ0[offs[3]+1] = log(eps()) ≈ -36. exp(-ls1[i]) ≈ e^36 overflows the standardised residual on the first nll evaluation, giving a huge or Inf objective and a failed/degenerate fit rather than a clean 'too few residual df' message.
- **Proposed fix:** Tighten the residual-df guard to strict inequality where a scale is estimated (count(obs1) > size(X1,2) for an estimable σ1 intercept), OR floor the seed variance: use log(sqrt(max(mean(residual^2), v_floor)) ) with a data-scale-based v_floor (e.g. a small fraction of var(y1_obs)). Emit an explicit error when a response is saturated so the user knows σ is not identified rather than silently starting at log(eps()).

---

### 4. Profile endpoint bracketing can terminate prematurely when the profiled NLL is non-monotone in t due to inner-solver noise
- **Location:** `src/inference.jl:690` · PLAUSIBLE
- **Issue:** _profile_endpoint_result assumes h(t)=profiled_nll(theta_k + dir*t) - target is monotonically increasing in t>=0 (comment lines 600-607), brackets by 1.6x expansion until h>0, then runs guarded Newton/bisection. For fits whose inner nuisance optimisation is only approximately solved (the :finite autodiff path with NelderMead/BackTracking fallbacks, or warm-started LBFGS capped at 40 iterations), the profiled NLL can be slightly non-monotone or noisy, so the first t where h>=0 found by expansion may not be the true LR crossing, and the guarded-Newton root-find converges to whatever crossing lies in the bracket. Because correctness is only 'bracket-guaranteed' under monotonicity, a noisy profile can yield an endpoint that is too tight (understating the interval) with no diagnostic that this happened.
- **Failure scenario:** Profile a coefficient in a sparse-Laplace fit where the nuisance solve returns via the finite-difference / NelderMead fallback (line 575). Inner-solve jitter makes profiled_nll(t) dip below target at t1, rise above at t2>t1, then the true LR endpoint is at t3>t2. Expansion stops at the first h>0 near t2 and Newton converges there, reporting a confidence limit inside the true one; the interval is anticonservative and no stat in _ProfileStatsRow reveals the non-monotonicity.
- **Proposed fix:** Record and expose a monotonicity/quality flag: during expansion and root-find, track whether h ever decreased between successive accepted evaluations, and add a boolean (e.g. profile_nonmonotone) to _ProfileStatsRow so callers can see when the bracket assumption was violated. When detected, either tighten the inner-solve tolerance/iteration cap for that coefficient or fall back to a denser grid scan of the profile before root-finding. At minimum, document in the confint(:profile) docstring that endpoint validity depends on an accurate inner nuisance solve and that the :finite path can be noisy.

---

### 5. DRM.jl hard-clamps eta_mu/eta_sigma to [-20,20] for NB2/Gamma/Beta while drmTMB does not
- **Location:** `src/negbinomial.jl:300` · PLAUSIBLE

> **Cross-package (twin) finding.** The fix must stay in lockstep between drmTMB and DRM.jl; the primary change lands in **DRM.jl**, but confirm the sibling **drmTMB** matches.
- **Issue:** The DRM.jl count/positive families apply an UNCONDITIONAL hard clamp clamp.(X*beta, -20.0, 20.0) inside the objective: negbinomial.jl:300-301, 228-229, 265-266, 143, 187, 197; gamma.jl:202-203 ([-30,30] on mu, [-15,15] on sigma), 117, 125, 164, 174, 206. drmTMB does NOT hard-clamp the linear predictor; it only optionally applies a SMOOTH softclamp to log_sigma when use_logsigma_clamp==1 (drmTMB.cpp:572-574, 2124-2126) and never touches eta_mu. Inside the band the two agree, but once any fitted or trial eta exceeds the band the Julia objective is flat (zero gradient) there whereas TMB keeps the true curved likelihood, so the two twins optimise DIFFERENT surfaces and can converge to different MLEs / SEs.
- **Failure scenario:** A NB2 or Gamma fit with a large-mean cell (an offset or a rare high-count group pushing eta_mu>20, or a near-Poisson dispersion pushing eta_sigma past the band) has its Julia gradient zeroed above the clamp: Optim stalls at a boundary eta of exactly 20 with a spuriously flat objective and wrong inv(Hessian) SEs, while drmTMB's TMB fit walks to the real optimum. The two packages then report materially different beta_mu / dispersion for the same data, breaking twin parity.
- **Proposed fix:** Make the guarding strategy identical across twins. Preferred: replace the unconditional hard clamps in DRM.jl (negbinomial.jl:300-301,228-229,265-266,143,187,197 and gamma.jl:202-203,117,125,164,174,206) with the same optional SMOOTH softclamp drmTMB uses (a tanh-based identity-in-band map like drm_softclamp_log_sigma), applied only to log_sigma and off by default, so the objective is C^1 and identical to TMB in range. If a mean-side guard is genuinely needed for ForwardDiff, add the same smooth transform to the C++ behind the same use_logsigma_clamp flag so both sides share one definition. At minimum, widen/remove the eta_mu clamp so the mean predictor is never silently flattened. drmTMB (unguarded) is the reference.

---

### 6. laplace_ll adds an unnecessary 1e-10 ridge to an already-PD prior precision and mislabels it PSD
- **Location:** `src/sparse_aug_plsm.jl:301` · CONFIRMED
- **Issue:** laplace_ll computes logdetP from cholesky(Symmetric(P) + 1e-10I) and the comment calls P PSD with a root null space. But P = kron(Q_cond, Lambda_inv) is built from the ROOT-CONDITIONED precision Q_cond (make_problem drops the root row/col, lines 22-34) and a PD Lambda_inv, so P is positive definite; the root null space was already removed. The ridge biases logdetP by ~q*log(1 + 1e-10/lambda_min) on every marginal evaluation and, always succeeding, prevents detection of a genuinely non-PD P.
- **Failure scenario:** For a large tree (q = 4*(2p-2)) with long branches (small 1/b entries, small smallest eigenvalue of P), the additive 1e-10 ridge shifts logdetP summed over ~8p dimensions into a small nonzero offset in the reported Laplace logLik; and if Lambda drifts non-PD between PD-floor updates the ridge masks the failure.
- **Proposed fix:** Take chP = cholesky(Symmetric(P); check=false) without the ridge and issuccess(chP) || error(...) (P is PD by construction after root conditioning); if a guard is wanted use a scaled ridge eps()*maximum(diag(P)) only when the plain factorization fails. Fix the comment to state P is PD (root-conditioned).

---

### 7. KL term log(s·τ) unguarded when the inner variational variance s collapses to ~0
- **Location:** `src/variational.jl:131` · PLAUSIBLE
- **Issue:** Every group KL uses 0.5*(s*τ + m*m*τ - 1 - log(s*τ)) (Poisson line 131, and the _*_va_group_elbo helpers at lines 205, 344, 488, 628). s=exp(r) with r clamped only per-step (Δr∈[-2,2]) but with no absolute lower bound, so after several steps r can reach large negative values and s underflows toward 0. log(s*τ) then diverges to -Inf, making KL→+Inf and the group ELBO→-Inf; the outer nll returns +Inf and inv(ForwardDiff.hessian(...)) at the optimum can pick up NaNs.
- **Failure scenario:** A tightly-informed group (many members, sharp likelihood) drives the inner optimum toward a very small posterior variance; the unrolled Newton pushes r below ~ -700/τ-scale so s*τ underflows to 0.0, log(0.0)=-Inf, KL=+Inf, F=-Inf. nll(θ)=Inf propagates to LBFGS, which either stalls or returns a θ̂ whose Hessian inversion yields a non-finite vcov reported back through the bridge as the ELBO fit's covariance.
- **Proposed fix:** Floor s inside the KL/ELBO evaluation, e.g. use `log(max(s*τ, floatmin(T)))` or clamp r to an absolute range (e.g. r ≥ log(1e-8/τ)) in the inner unroll in addition to the per-step Δr clamp. Since the KL is only a lower-bound regulariser, a small floor does not change the fit at any reasonable variance but removes the -Inf/NaN path.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#325](https://github.com/itchyshin/DRM.jl/issues/325) [review][low] Optimizer / profiler / experimental robustness (5 findings)
_labels: bug_

Batch of **low-severity** findings under the theme *Optimizer / profiler / experimental robustness* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. guarded() backtracking can accept a worse point than the incumbent when the proposal overshoots
- **Location:** `src/experimental/q4_em_dense.jl:340` · CONFIRMED
- **Issue:** guarded() sets best_ll = ll_prop (the un-backtracked proposal) and only enters the while loop when best_ll < ll_cur. Inside, it interpolates toward par_cur and keeps par_try only if ll_try > best_ll. If the initial proposal already satisfies ll_prop >= ll_cur, no backtracking is attempted even when an interior alpha would give a much larger increase; and the returned best_ll >= ll_cur test at the end (line 348) is the only floor. Experimental code.
- **Failure scenario:** A joint beta update that increases the marginal only marginally (ll_prop just above ll_cur) is accepted whole even though the ECM step overshot and a partial step (alpha~0.5) would have increased the marginal far more; over many iterations this yields slow, zig-zag convergence and can hit max_em=200 without reaching tol, reporting converged=false on a model that is in fact identifiable. Not a wrong-answer bug (monotonicity is preserved) but a convergence-quality defect that undermines the oracle's role as a gold standard.
- **Proposed fix:** Always evaluate at least one interior alpha (e.g. try alpha in {1.0, 0.5}) and keep the argmax, rather than short-circuiting whenever the full step already beats ll_cur; or accept the full step only when it also beats the best interior trial. This is a minor robustness change; document that guarded() guarantees non-decrease but not the maximal conditional increase.

---

### 2. Multi-RE fitter clamps log-sigma inside the likelihood but not in the reported scale/means
- **Location:** `src/gaussian_ranef.jl:391` · PLAUSIBLE
- **Issue:** In `_fit_multi_ranef_gaussian` the objective `nll` (line 328) and gradient (line 346) evaluate the linear predictor for log-sigma as `clamp.(Xσ * βσ, -30.0, 30.0)`, so the fit maximises a likelihood whose per-observation residual scale is capped at exp(30). But the fitted scale stored at line 391 (`scales[:sigma] = exp.(Xσ * θ̂[...])`) and the reported logLik path use the UNCLAMPED predictor. When any fitted ησ exceeds ±30 the estimated coefficients no longer correspond to the σ vector the accessor reports, and the vcov via `ForwardDiff.hessian(nll, θ̂)` (line 387) differentiates through the flat clamp region, collapsing the σ-coefficient Hessian block and producing spuriously small/large SEs. The single-component fitters (`_fit_ranef_gaussian`, `_fit_correlated_ranef_gaussian`) do NOT clamp, so the twins of this code diverge in behaviour.
- **Failure scenario:** A multi-component fit `bf(y ~ x, sigma ~ x) + (1|g) + (1|h)` on data where `sigma ~ x` yields a large intercept/slope (e.g. y on a scale of 1e14, so log σ ≈ 32). The optimiser sees a clamped, gradient-flat objective for those rows: it converges to a βσ whose implied `exp(Xσβσ)` (reported by `sigma(fit)`) exceeds the value the likelihood actually used, and `vcov(fit)` returns near-zero variance for the σ intercept (Hessian block ≈ 0 through the clamp), so Wald SEs/CIs for the scale coefficients are invalid.
- **Proposed fix:** Remove the `clamp.(Xσ * βσ, -30, 30)` guards from the multi-RE `nll`/`grad!` (lines 328, 346, 396) OR, if overflow protection is genuinely needed, apply the SAME transformation consistently: compute `scales[:sigma]` from the clamped predictor and reject/emit a warning when any fitted `Xσ*βσ` hits the clamp boundary so SEs are not silently invalidated. Match the single-component fitters, which use the raw `exp.(-2 .* ησ)` without clamping, to keep the RE fitters consistent.

---

### 3. Bootstrap summary assumes contiguous, theta-order block ranges via a sequential col counter
- **Location:** `src/inference.jl:1216` · CONFIRMED
- **Issue:** _bootstrap_summary_rows walks fit0.blocks and uses a running col counter (col += 1) to index est[col] and draws[:, col], ignoring the actual UnitRange r stored on each block. This is correct only when the block ranges partition 1:p contiguously and in the same order as coef(fit)=theta. It silently discards r. For all current univariate fits the blocks are contiguous (1:pmu, (pmu+1):..., etc.), so it works today, but it is a latent divergence: any future fit whose blocks are reordered or non-contiguous relative to theta (or a bivariate path routed here) would misalign coefficient names, estimates, SEs and CIs without error.
- **Failure scenario:** If a future fit stores blocks = [:mu => 1:2, :sigma => 4:5, :resd => 3:3] (non-contiguous), _bootstrap_summary_rows would label draws[:,1..2] as mu (ok), draws[:,3..4] as sigma (should be cols 4,5), and draws[:,5] as resd (should be col 3): every reported bootstrap SE/CI after the first block is attached to the wrong coefficient name.
- **Proposed fix:** Index by the stored range instead of a private counter: iterate for (col, _) in zip(r, nms) using the actual UnitRange r from the block, i.e. for (j, col) in enumerate(r): v = @view draws[:, col]; estimate = est[col]. This makes the summary robust to any block layout and keeps it in lockstep with coef/vcov indexing. Add a test with a deliberately non-contiguous block layout.

---

### 4. Profiler and its slope evaluator silently assume canonical loadings; LocScaleObjective carries no Zη/Zψ
- **Location:** `src/locscale_profile.jl:49` · CONFIRMED
- **Issue:** `_ls_profile_nll` calls `_ls_marginal_nll(...)` (line 49) and `_ls_marginal_grad(...)` (line 54) with NO `Zη/Zψ`, so they default to canonical mean/scale loadings. `LocScaleObjective` (locscale_fit.jl:44-52) stores no loadings either, and `_ls_profile_ci` never receives any. Today only the coupled-intercept frontend (canonical loadings) attaches a `LocScaleObjective`, so live profile CIs are correct — but locscale_corr.jl:5 advertises 'profile/Wald CIs' for the correlated/independent-slope fits, whose loadings are non-canonical (`Zη=[1 xᵢ]` or `[xᵢ 0]`). If a slope/sigma-axis fit is ever wrapped in a LocScaleObjective for `confint(:profile)`, the profiler would silently re-solve with the WRONG (canonical) loadings.
- **Failure scenario:** A future/parallel wiring attaches `_withnll(fit, LocScaleObjective(kind, y, Xμ, Xψ, gidx, G, Q))` to a correlated-slope fit and the user calls `confint(fit, method=:profile)`: the profiler reconstructs the marginal with canonical `Zη=[1 0],Zψ=[0 1]` instead of `Zη=[1 xᵢ],Zψ=[0 0]`, so it profiles a DIFFERENT model, returning silently-wrong CIs that look plausible.
- **Proposed fix:** Add `Zη`/`Zψ` fields to `LocScaleObjective` (defaulting to the canonical loadings) and thread them through `_ls_profile_ci`, `_ls_profile_nll` (both the `f` marginal call and the `g!`/`evalh` gradient calls), so the profiler always reconstructs the exact model that was fit. Until that is done, either drop the 'profile CIs' claim from locscale_corr.jl:5 or add an assertion in `_ls_profile_ci` that the stored objective uses canonical loadings.

---

### 5. NB2/Gamma/Beta VA use only the first observation's dispersion per group with no sigma~1 guard
- **Location:** `src/variational.jl:403` · PLAUSIBLE
- **Issue:** _fit_nb2_ranef_va (line 403), _fit_gamma_ranef_va (line 547), and _fit_beta_ranef_va (line 685) compute the per-group dispersion/shape/precision as exp(-2*ησ[idx[1]]) — i.e. only the FIRST group member's linear predictor — with an inline comment 'With sigma~1 (the only case routed here) ησ is constant'. But Xσ is a full design matrix and nll() computes ησ=clamp.(Xσ*βσ,...) for all rows; there is no assertion that Xσ is intercept-only. If a caller reaches these fitters with sigma~x, every observation in a group silently gets the first member's dispersion, so the likelihood is wrong for all other members.
- **Failure scenario:** Any pathway (current or future refactor of the VA dispatcher) that calls _fit_nb2_ranef_va with a non-intercept Xσ, e.g. sigma ~ treatment where a group mixes treatments: rsize=exp(-2*ησ[idx[1]]) fixes θ_size to the first row's value, so members with a different treatment are scored under the wrong dispersion, biasing β_σ and the ELBO with no warning.
- **Proposed fix:** Add an explicit guard at the top of each of the three VA fitters: `size(Xσ,2)==1 || error("_fit_*_ranef_va supports only sigma ~ 1 (intercept-only dispersion); got pσ=$(size(Xσ,2))")`. This documents and enforces the assumption the code already relies on, matching the 'only case routed here' comment, and prevents a silent wrong-likelihood if the routing ever changes.


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>

## [#326](https://github.com/itchyshin/DRM.jl/issues/326) [review][low] Performance & scaling (1 findings)
_labels: bug_

Batch of **low-severity** findings under the theme *Performance & scaling* from the twin code-review pass. Each item is minor (hardening, cleanup, or twin-divergence risk) and is grouped here for triage rather than filed separately.

---

### 1. K>=3 Poisson crossed path forms a dense H-inverse, defeating the sparse selected-inverse spine
- **Location:** `src/sparse_laplace_glmm.jl:1720` · CONFIRMED
- **Issue:** The general K-component Poisson crossed fitter computes Hinv = ch \ Matrix{Float64}(I, size(Z,2), size(Z,2)) (line 1720) with dense ZH = Z*Hinv, and _poisson_laplace_mode builds a dense H = Matrix(Z'(diag mu)Z) (line 59). This is O(q^3) in q = sum(G_k), whereas the two-block path (_crossed_selected_inverse_entries / takahashi_selinv) and the phylo path deliberately use the O(nnz) Takahashi selected inverse. For three-plus crossed factors with many levels the code silently reverts to dense algebra, contradicting the stated O(nnz) sparse-Laplace claim and diverging in scaling from the two-block path and any TMB twin.
- **Failure scenario:** A Poisson GLMM with three crossed random intercepts each ~2000 levels (q about 6000) fit through _fit_poisson_crossed_laplace (K=3 branch) materializes a 6000x6000 dense Hinv (~288 MB) and does an O(q^3) solve on every outer gradient evaluation, so the fit is orders of magnitude slower/heavier than the two-factor case and can OOM.
- **Proposed fix:** Generalize _crossed_selected_inverse_entries to K components: build the crossed Hessian sparsely (as _crossed_sparse_hessian already does past CROSSED_SPARSE_Q_THRESHOLD) and obtain hd plus the per-observation cross entries S[level(i,k), level(i,l)] from takahashi_selinv(ch) instead of the full dense inverse; route the K>=3 branch through that so z_i' H^-1 z_i is assembled from selected-inverse entries in O(nnz).


---
<sub>Filed from a static code-review pass of the drmTMB ↔ DRM.jl twin packages (2026-07-02). Findings come from reading the source; no code was built or run — please verify against the live toolchain before acting. Confidence: CONFIRMED = reproduced from the code; PLAUSIBLE = reachable defect not fully confirmable statically.</sub>
