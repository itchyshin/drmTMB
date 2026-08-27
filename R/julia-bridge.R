julia_bridge_supported_dpars <- function() {
  c(
    "mu",
    "sigma",
    "nu",
    "zi",
    "hu",
    "zoi",
    "coi",
    "mu1",
    "mu2",
    "sigma1",
    "sigma2",
    "rho12"
  )
}

drm_julia_intentional_gates <- function() {
  data.frame(
    gate_id = c(
      "base_weights",
      "base_impute",
      "base_control",
      "base_missing_predictor_model",
      "base_missing_response_nongaussian",
      "base_unsupported_family",
      "biv_invalid_partial_phylo",
      "biv_rho12_phylo",
      "structured_unsupported_family",
      "structured_sigma_predictor",
      "structured_precision_slot",
      "xfam_missing_route",
      "xfam_rho12_formula",
      "xfam_dispersionless_sigma"
    ),
    route = c(
      rep("base", 6),
      rep("bivariate_phylo", 2),
      rep("structured", 3),
      rep("cross_family", 3)
    ),
    guard = c(
      "weights",
      "impute",
      "control",
      "missing predictor",
      "missing response",
      "family",
      "invalid partial bivariate phylo",
      "rho12 phylo",
      "structured family",
      "structured sigma",
      "structured matrix slot",
      "cross-family missing",
      "cross-family rho12",
      "cross-family dispersion"
    ),
    family_type = c(
      "gaussian",
      "gaussian",
      "gaussian",
      "gaussian",
      "poisson",
      "beta_binomial",
      "biv_gaussian",
      "biv_gaussian",
      "beta",
      "gaussian",
      "gaussian",
      "gaussian+poisson",
      "gaussian+poisson",
      "gaussian+poisson"
    ),
    syntax = c(
      "weights = ...",
      "impute = list(...)",
      "control = list(...)",
      "missing = miss_control(predictor = \"model\")",
      "missing = miss_control(response = \"include\") with poisson()",
      "family = beta_binomial() through engine = \"julia\"",
      "bivariate phylo on only one axis or on three axes",
      "phylo() term in rho12",
      "relmat() with beta()",
      "structured relmat() with sigma ~ x",
      "relmat(..., Q = Q)",
      "cross-family response missingness",
      "cross-family rho12 formula",
      "cross-family sigma formula on dispersionless axis"
    ),
    r_bridge_status = "intentional_error",
    drmjl_status = c(
      "unsupported payload",
      "unsupported payload",
      "no R engine-control surface",
      "unsupported payload",
      "not audited for non-Gaussian masks",
      "no BetaBinomial tree/FE R bridge claim",
      "bivariate phylo route admits q2 mu1/mu2 or q4 all four axes only",
      "unsupported q4 PLSM axis",
      "general-covariance route is narrower than R grammar",
      "general-covariance route is narrower than R grammar",
      "covariance matrix route only",
      "cross-family route requires complete axes",
      "latent rho route only",
      "dispersionless axis"
    ),
    message_pattern = c(
      "weights",
      "impute",
      "default .*control",
      "missing.*route|impute",
      "missing.*route",
      "Gaussian one-/two-response|Workflow G fixed-effect",
      "requires either q2.*mu1/mu2|q4 all-four-axis|Missing phylogenetic axis",
      "Unsupported phylogenetic axis",
      "only for univariate Gaussian, Poisson, NB2, or Gamma",
      "requires .*sigma ~ 1",
      "only with a covariance matrix supplied as .*K",
      "missing.*routes",
      "rho12.*not wired",
      "cannot fit .*sigma2.*dispersion"
    ),
    review_due = "before 0.2.0 bridge promotion",
    evidence_url = c(
      rep("https://github.com/itchyshin/drmTMB/issues/544", 11),
      rep("https://github.com/itchyshin/gllvmTMB/issues/488", 3)
    ),
    action = "error",
    evidence = c(
      "DRM.jl bridge payload has no weights slot.",
      "DRM.jl bridge payload has no imputation contract.",
      "Julia optimizer controls need an explicit engine_control surface.",
      "DRM.jl bridge receives complete predictor columns only.",
      "Observed-response masks are admitted only for Gaussian bridge cells.",
      "BetaBinomial has no Workflow G R bridge admission; use native TMB.",
      "DRM.jl bivariate phylo bridge expects either q2 terms on mu1/mu2 or q4 terms on mu1, mu2, sigma1, and sigma2.",
      "DRM.jl q4 PLSM does not take a phylogenetic residual-correlation axis.",
      "DRM.jl general-covariance bridge is limited to Gaussian, Poisson, NB2, and Gamma.",
      "DRM.jl general-covariance bridge currently requires sigma ~ 1.",
      "DRM.jl bridge consumes covariance/relatedness matrices, not precision slots.",
      "Cross-family bridge currently drops missing rows and requires complete axes.",
      "Cross-family dependence is latent rho from the engine, not an R rho12 formula.",
      "Poisson and Binomial cross-family axes have no dispersion sub-model."
    ),
    issue = "drmTMB#544",
    stringsAsFactors = FALSE
  )
}

drm_julia_capability_comparison <- function() {
  data.frame(
    capability_id = c(
      "base_gaussian_location_scale",
      "biv_gaussian_residual",
      "gaussian_phylo_mean",
      "gaussian_response_mask",
      "biv_q4_phylo_reml",
      "phylo_count_large_p",
      "phylo_gamma_beta_binomial",
      "general_covariance_structured",
      "cross_family_latent",
      "engine_control_surface",
      "plain_binomial_nonphylo"
    ),
    route = c(
      "base",
      "base",
      "phylo",
      "base",
      "bivariate_phylo",
      "phylo",
      "phylo",
      "structured",
      "cross_family",
      "base",
      "base"
    ),
    syntax = c(
      "bf(y ~ x, sigma ~ z), family = gaussian(), engine = \"julia\"",
      "bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1), family = biv_gaussian(), engine = \"julia\"",
      "bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1), family = gaussian(), engine = \"julia\"",
      "missing = miss_control(response = \"include\") for Gaussian cells",
      "biv_gaussian() q4 phylo on mu1, mu2, sigma1, sigma2 with REML = TRUE",
      "poisson()/nbinom2() with phylo(1 | group, tree = tree)",
      "Gamma()/beta()/stats::binomial() with phylo(1 | group, tree = tree)",
      "relmat(1 | group, K = K) for supported one-response families",
      "c(gaussian(), poisson()) cross-family latent-rho route",
      "engine_control = ... or non-default Julia optimizer controls",
      "stats::binomial() without phylo() through engine = \"julia\""
    ),
    r_bridge_status = c(
      "experimental",
      "experimental",
      "experimental",
      "experimental",
      "experimental",
      "experimental",
      "experimental",
      "experimental",
      "experimental",
      "unsupported",
      "experimental"
    ),
    drmjl_status = c(
      "default DRM.jl Gaussian location-scale path",
      "DRM.jl biv_gaussian residual rho12 path (Hopper Phase 1.5 #5)",
      "DRM.jl first Gaussian phylo-mean path (Hopper Phase 1.5 #5)",
      "Gaussian observed-response mask path",
      "q4 PLSM REML path when installed DRM.jl supports it",
      "large-p sparse phylo path",
      "guarded non-Gaussian phylo path",
      "general-covariance path for Gaussian, Poisson, NB2, and Gamma",
      "latent-rho mixed-family path; API drift is tracked in tests",
      "no R surface by design",
      "Workflow G FE bridge cell (binomial-trials) via drm_bridge"
    ),
    claim_status = c(
      # Phase 1.5 cap LIFTED 2026-08-25 by owner decision (Shinichi). These three
      # rows carried covered-grade evidence on the design/168 four-limb bar and were
      # held at `partial` only by tests/testthat/test-julia-gate-vs-engine.R -- a
      # CRAN-facing governance choice, not an evidence one. D-164 still holds the
      # RELEASE; it never held the ledger. Each row's claim_boundary records what the
      # promotion does and does not claim: the interval_status fences are UNCHANGED,
      # and `covered` here is a CAPABILITY claim, never a coverage claim.
      "covered",
      "covered",
      "covered",
      # Phase 2 promotions 2026-08-27 (owner instruction "do the last two
      # promotions"; the completion roadmap, D-179 arc). Each row's blocker was
      # FIXED AND MEASURED first — DRM.jl PR #517 — details in the boundaries.
      "covered",
      "covered",
      "covered",
      # Phase 1 promotions 2026-08-27 (owner instruction; the promotion arc,
      # DRM.jl docs/dev-log/plans/2026-08-26-promotion-arc.md). Both rows meet the
      # design/168 four-limb bar with SE-grade evidence on ONE stamped comparator
      # build (f3e754a4); details in each row's claim_boundary. The interval_status
      # fences are UNCHANGED -- `covered` is a capability claim, never coverage.
      "covered",
      "covered",
      "partial",
      "unsupported",
      "covered"
    ),
    evidence_url = c(
      rep("https://github.com/itchyshin/drmTMB/issues/544", 8),
      "https://github.com/itchyshin/gllvmTMB/issues/488",
      "https://github.com/itchyshin/drmTMB/issues/544",
      "https://github.com/itchyshin/drmTMB/issues/569"
    ),
    claim_boundary = c(
      "Route C Gaussian location-scale. All four design/168 limbs met: implementation; focused tests (test/parity/runparity_bridge.jl gaussian-locscale); public docs (docs/src/r-julia-bridge.md); and interval evidence (parity-se.tsv se_gaussian_location_scale, 1.499e-07 abs / 2.169e-06 rel, with a negative control in the same table). The live TMB parity remains OPT-IN by design -- its gate is CRAN-safety motivated (an unguarded live-Julia test once hung win-builder ~10,448s) -- but it is no longer an unverified assumption: measured 2026-08-24, |d_loglik| = 6.257e-09, max|d_coef| = 5.456e-06. NOT interval COVERAGE. PHASE 1.5 CAP LIFTED 2026-08-25 (owner decision, Shinichi). The evidence recorded above already met the design/168 four-limb bar; the cap was a CRAN-facing governance choice, not an evidence one, and the owner has now made that call. D-164 continues to hold the RELEASE -- no CRAN submission is authorised -- but it never held the ledger. WHAT THIS PROMOTION CLAIMS: implemented, tested, publicly documented, and carrying interval/diagnostic evidence. WHAT IT DOES NOT CLAIM: interval COVERAGE -- the interval_status fence on this row is UNCHANGED and every 'NOT interval coverage' qualifier above still stands.",
      "Route B residual rho12. Same-target live tmb-vs-julia parity, name-matched: coefficients 9.861e-07 (7/7), SE 9.176e-08 abs / 1.835e-06 rel (cross-confirmed independently by tools/parity_se.R on the same draw, with a negative control in the same table), logLik 1.307e-11; comparator build recorded via drmtmb_code_hash. Evidence is ONE fixed-effects draw (n=400, one seed) -- this is result-shape and point/SE parity, NOT interval COVERAGE and NOT a phylo or cross-family claim. PHASE 1.5 CAP LIFTED 2026-08-25 (owner decision, Shinichi). The evidence recorded above already met the design/168 four-limb bar; the cap was a CRAN-facing governance choice, not an evidence one, and the owner has now made that call. D-164 continues to hold the RELEASE -- no CRAN submission is authorised -- but it never held the ledger. WHAT THIS PROMOTION CLAIMS: implemented, tested, publicly documented, and carrying interval/diagnostic evidence. WHAT IT DOES NOT CLAIM: interval COVERAGE -- the interval_status fence on this row is UNCHANGED and every 'NOT interval coverage' qualifier above still stands.",
      "Route A Gaussian phylo-mean (sigma ~ 1). All four design/168 limbs met, and the row's DEFINING parameter -- the phylogenetic SD -- is now actually compared: drmTMB 0.916577447 (correlation scale) vs DRM.jl raw re_sd x sqrt(tree height), agreeing to 1.50e-08, plus a three-height round-trip (9.37e-08 / 1.44e-08 / 3.31e-08). Its test runs in the DEFAULT suite, not behind DRM_PARITY_TESTS. NOTE the scale convention: drmTMB standardises via ape::vcv(tree, corr=TRUE) and is height-invariant; DRM.jl reports on the RAW branch-length scale -- they agree only after x sqrt(height), and the difference is invisible on a height-1 tree. Fixture reseeded 2026-08-25 (seed 404) because the previous seed-111 cell's phylo SD was UNIDENTIFIABLE (profiled nll flat over 20 orders of magnitude), so its comparison passed inside tolerance while meaning nothing (DRM.jl#483). atol_re_sd re-derived a priori from drmTMB's Wald SE. NOT interval coverage; not loc-scale phylo; not non-Gaussian phylo. INTERVAL COVERAGE NOW MEASURED (2026-08-25, Totoro, DRM.jl#468), and it does NOT promote this row. n=1000 per rung on bf(y ~ x + phylo(1|species), sigma ~ 1), MCSE ~0.007. The MEAN block is nominal at N>=128: mu:x Wald 0.950/0.950 and profile 0.953/0.952 at ntip 32/64 against nominal 0.95. At ntip=16 (N=64) everything under-covers (mu intercept Wald 0.905) -- ordinary small-sample behaviour. The sigma axis reads 0.810/0.914/0.947 marginally, but that is a SOLVER defect, not calibration: the upper profile endpoint collapses to the point estimate in 24.3%/10.6%/1.9% of fits, and split on that condition clean-arm coverage is 0.951 and 0.950 -- exactly nominal -- while collapsed-arm coverage is 0.477, the signature of a one-sided interval (DRM.jl#493). Zero non-converged fits and zero interval failures across all 3000 reps. The interval_status fence is UNCHANGED: the approved design (pre-run section 2) makes fence removal a separate PR with a Rose audit between, and #493 should be fixed first. Evidence: docs/dev-log/evidence/2026-08-25-coverage-campaign-results.md. PHASE 1.5 CAP LIFTED 2026-08-25 (owner decision, Shinichi). The evidence recorded above already met the design/168 four-limb bar; the cap was a CRAN-facing governance choice, not an evidence one, and the owner has now made that call. D-164 continues to hold the RELEASE -- no CRAN submission is authorised -- but it never held the ledger. WHAT THIS PROMOTION CLAIMS: implemented, tested, publicly documented, and carrying interval/diagnostic evidence. WHAT IT DOES NOT CLAIM: interval COVERAGE -- the interval_status fence on this row is UNCHANGED and every 'NOT interval coverage' qualifier above still stands. RE-MEASURED 2026-08-25 on the COMPLETE grid after DRM.jl#493/#494 were fixed, and the earlier coverage note on this row is superseded. Splitting calibration from solver reliability changes the reading: CONDITIONAL on the solver returning an interval, coverage is within ~2 MCSE of nominal at every rung (mu 0.938/0.956/0.947, sigma 0.936/0.954/0.950, resd 0.944/0.938/0.944 at ntip 16/32/64, n=1000 each). The intervals this route PRODUCES are calibrated. But the solver fails to produce one at a material rate -- 313/1000 on sigma at ntip=16, 132 at 32, 24 at 64, and 44 on resd at ntip=16 (the degenerate-endpoint bug was NOT confined to the sigma axis). Marginal coverage is therefore 0.643/0.828/0.927, LOWER than the pre-fix 0.810/0.914/0.947 because a degenerate arm used to return a bogus finite bound that contained the truth about half the time and is now scored covered=0. Lower and true. THE FAILURE RATE, NOT THE CALIBRATION, IS WHAT WOULD BLOCK A COVERAGE CLAIM HERE.",
      "PROMOTED partial -> covered 2026-08-27 (Phase 2, owner instruction). The named hole is CLOSED BY MEASUREMENT, not derivation: native drmTMB's own mean-phylo fits under response='include' and response='drop' are BYTE-IDENTICAL (logLik and coefficients exactly equal, same rows used) -- with rows conditionally independent given the latent field, a missing Gaussian response integrates out of its own likelihood factor entirely, so include IS drop + prediction and no missing-response likelihood exists to derive. DRM.jl (PR #517) now fits include on the phylo-MEAN cell as observed rows + FULL tree via the subset-tolerant #482 leaf matching (a fully-masked species stays in the phylo prior with no likelihood term, the sigma-phylo route's long-standing convention). EVIDENCE: include == drop asserted EXACTLY (same bytes after the row filter) in DRM.jl's default suite (test_gaussian_phylo_mean_missing_response.jl, 44 assertions incl. leak guards), to 1e-10 through the LIVE bridge with a fully-masked species (tests/testthat/test-julia-missing.R, this PR), and cross-engine drop parity measured at |d logLik| = 4e-10. BOUNDARY STILL VISIBLE: missing PREDICTORS remain gated (predictor must be 'fail'); non-Gaussian response masks remain gated; and the wrapper deliberately does NOT extend to relmat/animal/spatial mean terms, ordinary random effects, meta_V, or a phylo mean with a non-constant sigma design -- their positional row-to-level matching is not subset-safe (#482's trap) and they refuse loudly. NOT interval coverage.",
      "Four-axis phylogenetic location-scale REML. All four design/168 limbs met: implementation (src/reml_q4.jl, in the module); focused tests (test_reml_q4_allaxes.jl AND test_parity_biv_q4_phylo_reml.jl, BOTH in the default suite); public documentation (docs/src/capabilities.md:189); and same-target evidence on a fixture where BOTH engines now converge -- max |d_coef| 0.002889, inside a re-derived a-priori atol by ~15x. IMPORTANT, and previously misdiagnosed: native TMB and DRM.jl maximise the SAME restricted likelihood (both marginalise all four fixed-effect axes; drmTMB adds beta_sigma1/2 to tmb_random_names when a sigma variance component exists, R/drmTMB.R:1122-1152). They differ only by the integration constant (n_beta/2)*log(2*pi) = 5.513631; measured 5.515569, residual 0.001938. An earlier fixture note asserted a structural difference -- that was false and is retained in the fixture for traceability. Julia-side convergence on this cell required DRM.jl#484 (automatic warm restart); before it, drm()'s public kwargs could not converge here at all. STILL NOT CLAIMED: same-target BRIDGE parity (the engine='julia' path for this cell is halted by design), interval COVERAGE, and HSquared AI-REML. UPDATE 2026-08-25 (DRM.jl#477): DRM.jl's bivariate REML routes now report the NORMALISED restricted log-likelihood, matching drmTMB/TMB/lme4/glmmTMB and DRM.jl's own univariate REML routes, which had always added the constant. This row's parity tolerance was atol_loglik = 5.5436, of which 5.513631 was exactly that integration constant -- a gate that existed almost entirely to absorb an offset. It is now 0.03, the cross-optimum spread alone, passing 33/33: a 185x tightening of the evidence behind this row, not a new claim on top of it. INTERVAL COVERAGE NOW MEASURED (2026-08-25, Totoro, DRM.jl#468), and it ARGUES AGAINST promotion. n=917 of 1000 reps, MCSE 0.006-0.013, convergence 885/917 = 96.5% (much better than the pre-run feared -- #484's warm restart). A clean structural split: phylocov DIAGONAL entries are at or above nominal (L11 0.947, L22 0.943, L33 0.963, L44 0.985 i.e. conservative) while every OFF-DIAGONAL under-covers -- L21 0.874, L31 0.891, L32 0.846, L41 0.883, L42 0.877, L43 0.810, i.e. 5-11 MCSE below nominal. Consistent with Wald on a nonlinear log-Cholesky reparameterisation; the campaign establishes THAT, not WHY. rho12 is fine (profile 0.965, Wald 0.937). sigma1/sigma2 under-cover (0.895/0.881). CRITICAL LIMIT: the missing 83 reps are NOT a random subsample -- they are exactly the seeds on which the rho12 profile RUNS AWAY (99.9% CPU, zero output, stopped under D-139's overrun rule; DRM.jl#494, 22 seeds listed). Every figure here is conditioned on 'not runaway-prone' and that cannot be checked from inside the dataset. The interval_status fence is UNCHANGED and the off-diagonal numbers are why it should stay. Evidence: docs/dev-log/evidence/2026-08-25-coverage-campaign-results.md. RE-MEASURED 2026-08-25 on the COMPLETE 1000/1000 grid (the earlier 917-rep figure and its selection caveat are RETIRED -- DRM.jl#494 is fixed and all 22 previously-runaway seeds now terminate, so no figure here is conditioned on 'not runaway-prone' any more). Convergence 965/1000. The structural finding is now beyond doubt: phylocov DIAGONAL entries cover 0.974 (n=3936) while OFF-DIAGONALS cover 0.876 (n=5910), MCSE 0.003-0.004, about 25 MCSE apart. BOTH directions are calibration failures -- L43 covers 0.827 (understates uncertainty) and L44 covers 1.000 with MCSE 0.000, i.e. it covered every single time, which is not a 95 percent interval but an uninformatively wide one. rho12 is the sharpest case and the reason marginal numbers alone mislead: 0.756 marginal with 223/1000 interval failures but 0.973 conditional -- its calibration was real AND its reliability was not. These are Wald intervals on a nonlinear log-Cholesky reparameterisation; the campaign establishes THAT the split exists and its size, not WHY. Still NOT a coverage claim, and the phylocov numbers in both directions are why. SHARPENED (DRM.jl#495): the phylocov miscalibration is a SCALE-AXIS GRADIENT, not simply diagonal-vs-off-diagonal. With axes (mu1, mu2, sigma1, sigma2): diagonal MEAN entries cover 0.951 (n=1989, MCSE 0.005) -- CORRECTLY CALIBRATED, and the control proving the machinery can hit nominal on this fit; diagonal SCALE entries cover 0.997 (L44 covered 986/986, MCSE 0.000) -- uninformatively wide; and every covariance under-covers, worst at scale x scale (L43 = 0.827, 10 MCSE low). Two defects in opposite directions, and BOTH are reasons this row must not move. The discriminating test (profile vs Wald on the same fits) is proposed in #495 and needs its own D-139 estimate.",
      "PROMOTED partial -> covered 2026-08-27 (Phase 2, owner instruction). BOTH blockers this row named are fixed at source and re-measured (DRM.jl PR #517, evidence re-banked on one stamped comparator build 19ecb005): (a) THE CONVERGENCE FLAG (#491) now answers a fixed, scale-invariant question -- mean per-observation gradient <= 1e-6 -- with the Optim short-circuit removed; the old flag was anti-correlated with care (g_tol=10 reported converged at rel-gradient 1.18e-03) and the new standing gate reproduces exactly that and asserts it refused. (b) THE LARGE-P SE GAP was the finite-difference NOISE FLOOR, not a convention difference: the outer vcov Hessian used a fixed h=1e-4 on a summed, inner-solved objective whose evaluation noise grows with n; the step is now n-aware (h ~ 2.5e-7*n, clamped [1e-4, 1e-2]), diagnosed by a step-size x inner-start sweep against native TMB on identical data that ruled out solver hysteresis. RE-MEASURED: poisson_phylo_p1000 SE parity 1.178e-03 -> 3.99e-06 relative (295x), p3000 9.01e-04 -> 4.53e-06 (199x); the BEFORE numbers are the Phase 1 bank, preserved in git at DRM.jl commit c664c4b0:docs/dev-log/evidence/parity-classc.tsv (the current TSV holds only the after-fix values — audit 2026-08-27 flagged the uncited baseline); coefficients 5e-8..1.3e-06, logLik ~1e-09; parity at p = 20, 300, 1000, 3000 all PARITY_PASS. Four limbs: implementation; tests (test_phylo_count_largep_gate.jl, 31 assertions: recovery, the raw-vs-normalised re_sd height round-trip, the converged-is-not-for-sale gate, and the FD-step shape lock); public docs (DRM.jl docs/src/capabilities.md); the SE evidence above. BOUNDARY STILL VISIBLE: p=3000 is two orders of magnitude below DRM.jl's own p=10,000 O(p) single-engine claim and NO native comparator has been attempted near that scale; native TMB scaled O(p^1.27) over the measured range (#486), so this is genuine parity on shared ground, not a DRM.jl-only regime. NOT interval coverage.",
      "PROMOTED experimental -> covered 2026-08-27 (Phase 1 of the promotion arc, owner instruction). All four design/168 limbs: implementation (DRM.jl non-Gaussian sparse-Laplace phylo route, src/sparse_laplace_glmm.jl); focused tests in DRM.jl's DEFAULT suite (test/test_gamma_beta_phylo_laplace.jl, test/test_binomial_phylo_laplace.jl); public docs (DRM.jl docs/src/capabilities.md non-Gaussian phylo table); and native-vs-native parity WITH SEs in DRM.jl docs/dev-log/evidence/parity-phylo-nongaussian.tsv, all THREE members on one stamped comparator build (f3e754a4): coefficients Gamma 6.26e-08 / Binomial 2.18e-08 / Beta 5.02e-07, logLik <= 2.9e-05, mu-block relative SE 1.49e-05 / 2.17e-07 / 1.87e-04 -- inside the 1e-3 SE bar tools/parity_se.R argues from measured headroom. HISTORY THAT MATTERS: the Binomial member was NO_NATIVE_COMPARATOR until drmTMB gained native binomial phylo() on 2026-08-17 (d30841491); re-measured 2026-08-26 it is the TIGHTEST of the three. The comparator moving made this row MORE evidenced invisibly -- caught by the #473 provenance stamping on its first real run -- and it removes the per-member evidence boundary the promotion plan expected to need. BOUNDARY: one fixture (12 tips x 6 obs, one seed); the tree is normalised to unit height because the engines' scale conventions differ by sqrt(height); the Binomial cell's phylo-SD coordinate sits at a variance boundary (DRM.jl vcov_guard flags it and uses a pseudo-inverse -- the mu-block SEs compared are unaffected, and the boundary is why the mu-only comparison is the honest one there); the evidence route is native-engine-vs-native-engine via JuliaCall, NOT the R bridge, which is why r_bridge_status stays experimental. NOT interval COVERAGE -- no interval_status fence moves here.",
      "PROMOTED partial -> covered 2026-08-27 (Phase 1 of the promotion arc, owner instruction). Supplied covariance/relatedness K with sigma ~ 1. All FOUR claimed families measured against native drmTMB and re-banked twice on stamped comparator builds (f3e754a4 on 2026-08-26, re-measured to identical values on 19ecb005 in the 2026-08-27 Phase 2 re-bank, which is the build the current parity-classc.tsv stamps): relative SE Gaussian 3.38e-07, Poisson 2.17e-06, NB2 4.79e-06, Gamma 2.17e-07; coefficients 1.6e-08..1.6e-06. THE EARLIER SE NUMBERS ON THIS ROW (Poisson 4.65e-03, NB2 6.79e-03, Gamma 4.08e-02) WERE SOLVE NOISE, NOT A CONVENTION DIFFERENCE: the promotion plan's SE-divergence diagnostic showed the Julia SE converging toward native as the inner Newton tolerance tightened, and DRM.jl#513 (newton_tol 1e-8 -> 1e-10; vcov-guard rtol recalibrated 1e-12 -> 3e-8 on 1,970 instrumented calls per arm) closed the gap -- Gamma improved 188,216x. Four limbs: implementation; focused tests in DRM.jl's default suite (test/test_relmat_counts.jl, test_relmat_counts_nb2.jl, test_relmat_counts_beta.jl); public docs (DRM.jl docs/src/capabilities.md structured-effects table); and the SE evidence above, with a negative control in parity-se.tsv from the same program. BOUNDARY UNCHANGED AND STILL VISIBLE: ONE seed/fixture per family; beta has NO_NATIVE_COMPARATOR (drmTMB refuses relmat on plain beta()) and is an excluded NEIGHBOUR -- the row claims exactly the four families measured; precision Q and sigma predictors remain GATED and unmeasured. NOT interval coverage.",
      "PERMANENT CLAIM_BOUNDARY (owner decision D-179 #3, 2026-08-27): this row stays `partial` by DESIGN, on the engine_control_surface pattern -- an owner-signed boundary, not a pending promotion. WHY IT CANNOT REACH `covered` ON THE PARITY BAR: drmTMB's native TMB engine accepts only c(gaussian(), gaussian()), so no native comparator for a mixed pair can exist; the only evidence route is multi-seed simulation recovery, which is deliberately NOT being spent here (one family pair, one fixture is what exists). RETRACTION OF THE PREVIOUS TEXT'S CLAIM (1): the route IS reachable from R. drmTMB(bf(...), c(gaussian(), poisson()), engine = \"julia\") dispatches through drmTMB_julia_xfam_bridge -> drm_julia_call_xfam -> DRM.fit_mixed_family, exercised by tests/testthat/test-xfam-bridge.R (54 passing assertions incl. a live Gaussian x Poisson round-trip). The earlier \"NOT reachable through the R bridge at all\" verdict inspected DRM.jl's src/bridge.jl -- the wrong LAYER: drmTMB's own marshalling reaches the engine without it. Consequently r_bridge_status = experimental is FAIR, not generous, and stands. WHAT THE ROUTE REFUSES, as excluded NEIGHBOURS (a rho12 formula would be a different model -- the correlation here is a latent scalar): rho12 formulas, random effects, structured markers, meta_V, weights, impute, non-drop missing routes. Smoke evidence: rho_latent 0.5336 on n=300 shared-latent fixture, DRM.jl formula-route == matrix-route equivalence tested (test_cross_family_formula.jl, 18 assertions (a 24 was recorded earlier and corrected by the 2026-08-27 audit)). NOT interval coverage. Revisiting this boundary is an owner decision; simulation-recovery evidence would be the price of `covered`.",
      "Do not document user-selectable Julia optimizer controls until a real R API is designed.",
      "Live R Workflow G binomial-trials cell (cbind(successes, failures) ~ x) vs DRM.jl: logLik/coefficient agreement 2.48e-13, and SE agreement 1.268e-09 abs / 2.482e-08 rel (parity-se.tsv cell se_binomial_trials, measured 2026-08-24, comparator build recorded via drmtmb_code_hash) -- tighter than any of the three Gaussian SE cells. Evidence is result-shape and point/SE parity on a fixed-effect cell: NOT interval COVERAGE, no phylo, no random effects."
    ),
    next_action = c(
      "Keep coefficient and likelihood parity tests tied to exact bridge payloads. Coefficient/logLik parity re-measured 2026-08-15 against DRM.jl (coef 4.564e-06, logLik 4.584e-09, tol 1e-4); see DRM.jl docs/dev-log/evidence/parity-fixtures.tsv.",
      "Keep residual rho12 result-shape and Route B parity tests; do not promote beyond experimental.",
      "Keep first phylo-mean result-shape and Route A parity tests; do not widen to sigma-phylo here.",
      "Keep the include==drop equality tests green on both sides (DRM.jl default suite + tests/testthat/test-julia-missing.R). Non-Gaussian observed-data likelihoods stay gated until audited; missing predictors stay predictor='fail'.",
      "Bank fit-specific CI/status parity before release language.",
      "Keep the standing gate (test_phylo_count_largep_gate.jl) and the large-p SE cells green against future comparator builds. The p=10,000 single-engine claim stays single-engine unless a native comparator is attempted at that scale (a deliberate non-goal). Interval_status does not move without a coverage campaign.",
      "Keep the three-member parity harness (tools/parity_phylo_nongaussian.R, SE columns included since 2026-08-27) green against future comparator builds; widen beyond one fixture/seed only if a claim needs it. Interval_status does not move without a coverage campaign.",
      "Compare current DRM.jl accepted families with the R gate before widening. DRM.jl-vs-gate comparison now exists and is re-runnable: DRM.jl tools/parity_ledger.py against a pinned drmTMB ref, with docs/dev-log/evidence/2026-08-14-drmtmb-parity-ledger.md. PROMOTION 2026-08-27: keep the four family cells green in DRM.jl tools/parity_classc.R; beta stays an excluded neighbour until drmTMB itself admits relmat on beta().",
      "BOUNDARY IS PERMANENT (D-179 #3). Keep tests/testthat/test-xfam-bridge.R and DRM.jl's cross-family tests green; do not spend simulation-recovery compute here unless the owner reopens the boundary. The r_bridge_status re-examination named earlier is CLOSED: the route is reachable from R (drmTMB_julia_xfam_bridge) and `experimental` is fair.",
      "Design engine_control explicitly before relaxing the gate.",
      "Keep Workflow G live R gate green; do not claim CRAN-default Julia. Independent coefficient/logLik parity for FE Poisson/NB2/Gamma(log) measured through engine='julia' on 0.7.0 (1.03e-12 / 6.89e-08 / 5.32e-06); see DRM.jl docs/dev-log/evidence/parity-fixtures.tsv."
    ),
    issue = c(
      rep("drmTMB#544", 10),
      "drmTMB#499"
    ),
    stringsAsFactors = FALSE
  )
}

# Hopper Phase 1.5 (#5 / DRM.jl twin) admitted cells only  -  not a family expansion list.
drm_julia_phase15_admitted_cells <- function() {
  caps <- drm_julia_capability_comparison()
  caps[
    caps$capability_id %in%
      c(
        "base_gaussian_location_scale",
        "biv_gaussian_residual",
        "gaussian_phylo_mean"
      ),
    ,
    drop = FALSE
  ]
}

drm_julia_setup_state <- new.env(parent = emptyenv())
drm_julia_phylo_payload_cache <- new.env(parent = emptyenv())

drmTMB_julia_bridge <- function(
  formula,
  family,
  data,
  env,
  weights_missing,
  control,
  impute,
  missing,
  REML = FALSE,
  call
) {
  REML <- drm_control_flag(REML, "REML")
  if (drm_julia_is_cross_family(family)) {
    drm_julia_warn_reml_unsupported(REML, "cross-family")
    return(drmTMB_julia_xfam_bridge(
      formula = formula,
      family = family,
      data = data,
      env = env,
      weights_missing = weights_missing,
      control = control,
      impute = impute,
      missing = missing,
      REML = REML,
      call = call
    ))
  }
  family_type <- drm_julia_bridge_family_type(family)
  if (
    identical(family_type, "biv_gaussian") &&
      drm_julia_has_structured_term(formula)
  ) {
    drm_julia_warn_reml_unsupported(
      REML,
      "bivariate q2 known-covariance structured-effect"
    )
    return(drmTMB_julia_biv_known_structured_bridge(
      formula = formula,
      family = family,
      data = data,
      env = env,
      weights_missing = weights_missing,
      control = control,
      impute = impute,
      missing = missing,
      REML = REML,
      call = call
    ))
  }
  if (drm_julia_has_structured_term(formula)) {
    drm_julia_warn_reml_unsupported(REML, "structured-effect")
    return(drmTMB_julia_structured_bridge(
      formula = formula,
      family = family,
      data = data,
      env = env,
      weights_missing = weights_missing,
      control = control,
      impute = impute,
      missing = missing,
      REML = REML,
      call = call
    ))
  }
  if (!isTRUE(weights_missing)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} does not support {.arg weights} yet.",
      i = "Use native {.code engine = \"tmb\"} for weighted fits until the bridge has a weights payload."
    ))
  }
  if (!is.null(impute)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} does not support {.arg impute} yet.",
      i = "Use native {.code engine = \"tmb\"} for imputation workflows until the bridge has an imputation payload."
    ))
  }
  missing_control <- drm_parse_missing_control(missing)
  if (!drm_julia_missing_supported(missing_control, family_type)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} does not support this {.arg missing} route yet.",
      i = "Supported: {.code response = \"drop\"}, or {.code response = \"include\"} for Gaussian (observed-data fit, tree kept whole). Use {.code engine = \"tmb\"} for other missing-data models."
    ))
  }
  if (!drm_julia_default_control(control)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} currently accepts only default {.arg control}.",
      i = "Use the native {.code engine = \"tmb\"} path for TMB optimizer, storage, sparse, or aggregation controls."
    ))
  }

  has_phylo <- drm_julia_has_phylo_term(formula)
  family_tag <- drm_julia_family_tag(family_type, has_phylo = has_phylo)
  # REML forwards to DRM.jl's `drm(...; method = :REML)` for two univariate
  # Gaussian cells: the fixed-effect location-scale model, and Gaussian
  # location-scale models with a phylo term on sigma (with or without a matching
  # mean-side phylo term), which DRM.jl now fits by restricted maximum
  # likelihood (Ayumi #2). The mean-only phylo Gaussian route (sigma ~ 1) and
  # the phylo-only families still return ML on the DRM.jl side, so warn and fit
  # ML rather than silently mislead. Bivariate q4 phylo
  # (`biv_gaussian` with phylo on all four axes) IS now supported  -  DRM.jl's
  # `drm(biv; method = :REML)` fits the q4 PLSM by Patterson-Thompson restricted
  # likelihood, and the bridge forwards `method = "REML"` to it via the payload.
  reml_supported <- drm_julia_reml_supported(
    formula = formula,
    family_type = family_type
  )
  if (isTRUE(REML) && !reml_supported) {
    drm_julia_warn_reml_unsupported(
      REML,
      drm_julia_reml_cell_label(
        formula = formula,
        family_type = family_type
      )
    )
  }
  # #694: when the missing control requests response = "drop" (the drmTMB
  # default), drop NA rows on the R side BEFORE marshalling. DRM.jl's non-Gaussian
  # phylo/count Laplace routes have no internal missing handling, so passing NA
  # rows through returns NaN / non-convergence instead of the dropped-case fit
  # native TMB gives. Dropping here also keeps the fit's stored data, nobs, and
  # phylo row_order / species consistent on the complete-case data.
  if (identical(missing_control$response, "drop")) {
    data <- drm_julia_drop_missing_rows(data, formula)
  }
  bridge_payload <- drm_julia_bridge_payload(
    formula = formula,
    family_type = family_type,
    data = data,
    env = env,
    method = if (isTRUE(REML) && reml_supported) "REML" else "ML"
  )

  result <- drm_julia_call_bridge(
    formula = bridge_payload$formula,
    family = family_tag,
    data = bridge_payload$data,
    tree = bridge_payload$tree,
    options = bridge_payload$options
  )
  result <- drm_julia_restore_row_order(result, bridge_payload$row_order)
  new_drmTMB_julia(
    result = result,
    call = call,
    formula = formula,
    family = family,
    data = data,
    family_type = family_type,
    structured_sd_scales = bridge_payload$structured_sd_scales,
    bridge_payload = bridge_payload,
    requested_REML = isTRUE(REML),
    effective_REML = isTRUE(REML) && isTRUE(reml_supported)
  )
}

drm_julia_default_control <- function(control) {
  if (inherits(control, "drm_control")) {
    default <- drm_control()
    return(identical(control, default))
  }
  is.null(control) || (is.list(control) && length(control) == 0L)
}

# Missing-data routes the Julia engine supports. `response = "drop"` is always
# allowed. `response = "include"` is allowed for Gaussian responses: DRM.jl fits
# the OBSERVED responses while keeping the full tree / design, i.e. the Gaussian
# observed-data likelihood (the missing rows leave the likelihood but their
# phylogenetic positions still inform the covariance). This mirrors native TMB's
# Gaussian-only `response = "include"` scope. `predictor` must be "fail".
drm_julia_missing_supported <- function(missing_control, family_type) {
  identical(missing_control$predictor, "fail") &&
    (identical(missing_control$response, "drop") ||
      (identical(missing_control$response, "include") &&
        # response="include" works for univariate Gaussian AND the bivariate q=4
        # phylo engine (per-cell observed mask threaded through the exact gradient).
        family_type %in% c("gaussian", "biv_gaussian")))
}

# Bridge-local family classifier. drmTMB's native `drm_family_type()` is the
# source of truth for every family the TMB engine fits, but it has no branch for
# a plain base-R `binomial()` (native binomial support is via `beta_binomial()`).
# DRM.jl DOES fit a univariate Binomial phylo model, so the bridge recognizes a
# `binomial(link = "logit")` object here and maps it to the "binomial" tag;
# every other family defers to `drm_family_type()`. The logit-link guard mirrors
# DRM.jl's Binomial likelihood, which is logit-mean ONLY.
#
# DO NOT go back to relying on `drm_family_type()` to reject a non-logit
# binomial. It used to do so, and this function leaned on that: the previous
# comment here read "other links fall through to `drm_family_type()`, which
# rejects them with the standard message". That held only while drmTMB was
# logit-only, which made a NATIVE-engine admissibility check double as this
# bridge's safety net by accident.
#
# drmTMB now admits `probit` and `cloglog` natively. Were this function still
# deferring, such a fit would fall through and reach DRM.jl tagged plainly as
# "binomial" -- and DRM.jl would fit it as LOGIT. That is a silently wrong model
# that runs and returns plausible numbers, which is far worse than a loud
# failure. The rejection is therefore explicit and local, and must stay that way
# whatever the native guard admits in future.
# (Emmy, Arc D review; docs/design/252-binomial-link-generalisation.md sec 5.)
drm_julia_bridge_family_type <- function(family) {
  if (inherits(family, "family") && identical(family$family, "binomial")) {
    if (identical(family$link, "logit")) {
      return("binomial")
    }
    cli::cli_abort(c(
      "The {.pkg DRM.jl} bridge supports {.code binomial(link = \"logit\")} only.",
      "x" = "Received binomial link {.val {family$link}}.",
      "i" = "{.pkg drmTMB} fits this link natively; use {.code engine = \"tmb\"}.",
      "i" = "DRM.jl's Binomial likelihood is logit-mean only, so routing this model to the bridge would silently fit a different model."
    ))
  }
  drm_family_type(family)
}

# Families that route through the Julia engine ONLY with a phylo(1 | group)
# random intercept. DRM.jl's sparse all-node Laplace is the large-p
# phylogenetic speed edge for these; a plain GLM without a phylo term stays on
# the native TMB path. Each tag string must match a `_bridge_family` case in
# DRM.jl's src/bridge.jl AND a family whose `drm(...)` method accepts `tree =`.
#   poisson / nbinom2 -> count phylo Laplace (verified large-p lane)
#   gamma / beta      -> non-Gaussian location-scale phylo Laplace (sigma ~ 1)
#   binomial          -> mean-only phylo Laplace
# beta_binomial is deliberately excluded: DRM.jl's BetaBinomial `drm()` has no
# `tree` kwarg, so a beta-binomial phylo fit has no Julia route yet.
drm_julia_phylo_only_families <- function() {
  c("poisson", "nbinom2", "gamma", "beta", "binomial")
}

# Families that support the coupled location-scale phylo route (cluster 4):
# a phylo(1|g) on the mean AND sigma, routed as a 2x2 group-level covariance
# via DRM.jl's coupled `(1|tag|phylo(g))` syntax. NB2 and Gamma both support
# this; Beta uses logit-scale sigma, which also works with _fit_locscale.
# Gaussian routes the both-phylo SHAPE (phylo on mean AND sigma) to DRM.jl's
# Gaussian location-scale phylo Laplace engine (separate-block) -- the capability
# the native TMB engine lacks (Ayumi #2).
drm_julia_locscale_phylo_families <- function() {
  c("gaussian", "nbinom2", "gamma", "beta")
}

# Families that support the structured slope phylo route (cluster 3):
# phylo(1+x|g) on the mean, routed to DRM.jl's _fit_corr_locscale via the
# `_parse_structured_slope` path. NB2, Gamma, Beta, and Poisson support this.
drm_julia_slope_phylo_families <- function() {
  c("nbinom2", "gamma", "beta", "poisson")
}

# Map drmTMB family_type -> DRM.jl bridge family tag, gating which families the
# Julia engine may route. Workflow G fixed-effect cohort families (Gaussian,
# bivariate Gaussian, Student-t, lognormal, Poisson, NB2, Gamma, Beta, Binomial)
# route unconditionally once live coefficient-scale parity exists (#499). The
# phylo-only helpers above still document the large-p phylogenetic speed edge
# for those same tags when a phylo() term is present. Everything else stays
# native TMB until a separate bridge admission lands.
drm_julia_family_tag <- function(family_type, has_phylo = FALSE) {
  wfg_fe <- c(
    "gaussian",
    "biv_gaussian",
    "student",
    "lognormal",
    "poisson",
    "nbinom2",
    "gamma",
    "beta",
    "binomial"
  )
  if (family_type %in% wfg_fe) {
    return(family_type)
  }
  phylo_only <- drm_julia_phylo_only_families()
  if (isTRUE(has_phylo) && family_type %in% phylo_only) {
    return(family_type)
  }
  if (family_type %in% phylo_only) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} routes {.val {family_type}} models only with a {.fn phylo} random intercept.",
      i = "DRM.jl's sparse all-node engine is the large-p phylogenetic speed edge; use {.code engine = \"tmb\"} for non-phylogenetic {.val {family_type}} models."
    ))
  }
  cli::cli_abort(c(
    "{.code engine = \"julia\"} currently supports Workflow G fixed-effect families (Gaussian, bivariate Gaussian, Student-t, lognormal, Poisson, NB2, Gamma, Beta, Binomial) and large-p phylogenetic Poisson, NB2, Gamma, Beta, or Binomial models.",
    i = "Use {.code engine = \"tmb\"} for other non-Gaussian drmTMB fits until the R bridge has coefficient-scale parity tests."
  ))
}

# TRUE when any formula entry carries a phylo() structured term.
drm_julia_has_phylo_term <- function(formula) {
  phylo_terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) identical(term$type, "phylo"),
        entry$structured
      )
    }),
    recursive = FALSE
  )
  length(phylo_terms) > 0L
}

# TRUE when any formula entry carries a phylo() term on the `sigma` axis. This
# marks the Gaussian sigma-phylo location-scale cells, with or without a
# matching mean-side phylo term, that DRM.jl now fits by restricted maximum
# likelihood (`drm(...; method = :REML)`) -- the sigma-phylo capability the
# native TMB engine lacks (Ayumi #2). Mean-only phylo Gaussian (sigma ~ 1) and
# the phylo-only families have no `sigma` phylo term, so REML stays gated for
# them.
drm_julia_has_sigma_phylo_term <- function(formula) {
  sigma_phylo_terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) {
          identical(term$type, "phylo") &&
            identical(term$dpar, "sigma")
        },
        entry$structured
      )
    }),
    recursive = FALSE
  )
  length(sigma_phylo_terms) > 0L
}

drm_julia_biv_phylo_dpars <- function(formula) {
  phylo_terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) identical(term$type, "phylo"),
        entry$structured
      )
    }),
    recursive = FALSE
  )
  if (length(phylo_terms) == 0L) {
    return(character())
  }
  vapply(phylo_terms, `[[`, character(1L), "dpar")
}

drm_julia_biv_phylo_dimension <- function(formula) {
  dpars <- drm_julia_biv_phylo_dpars(formula)
  if (setequal(dpars, c("mu1", "mu2"))) {
    return("q2")
  }
  if (setequal(dpars, c("mu1", "mu2", "sigma1", "sigma2"))) {
    return("q4")
  }
  NA_character_
}

drm_julia_reml_supported <- function(formula, family_type) {
  has_phylo <- drm_julia_has_phylo_term(formula)
  sigma_phylo <- drm_julia_has_sigma_phylo_term(formula)
  (identical(family_type, "gaussian") &&
    (!isTRUE(has_phylo) || isTRUE(sigma_phylo))) ||
    (identical(family_type, "biv_gaussian") &&
      identical(drm_julia_biv_phylo_dimension(formula), "q4"))
}

drm_julia_reml_cell_label <- function(formula, family_type) {
  if (!family_type %in% c("gaussian", "biv_gaussian")) {
    return(paste0("non-Gaussian (", family_type, ")"))
  }
  if (identical(family_type, "biv_gaussian")) {
    return("bivariate Gaussian")
  }
  if (drm_julia_has_phylo_term(formula)) {
    return("mean-only phylogenetic Gaussian")
  }
  "Gaussian"
}

drm_julia_bridge_payload <- function(
  formula,
  family_type,
  data,
  env,
  method = "ML"
) {
  formula_spec <- drm_julia_formula_spec(formula)
  phylo_payload <- drm_julia_phylo_payload(
    formula = formula,
    family_type = family_type,
    data = data,
    env = env
  )
  data_out <- drm_julia_bridge_data(
    data = data,
    formula = formula,
    phylo_payload = phylo_payload
  )
  if (!is.null(phylo_payload)) {
    data_out <- data_out[phylo_payload$row_order, , drop = FALSE]
    data_out[[phylo_payload$group]] <- as.character(
      data_out[[phylo_payload$group]]
    )
  }
  list(
    formula = formula_spec,
    data = data_out,
    tree = if (is.null(phylo_payload)) NULL else phylo_payload$newick,
    options = drm_julia_bridge_options(phylo_payload, method = method),
    row_order = if (is.null(phylo_payload)) NULL else phylo_payload$row_order,
    structured_sd_scales = if (is.null(phylo_payload)) {
      NULL
    } else {
      phylo_payload$structured_sd_scales
    },
    bivariate = if (is.null(phylo_payload)) {
      FALSE
    } else {
      isTRUE(phylo_payload$bivariate)
    },
    bivariate_dimension = if (is.null(phylo_payload)) {
      NA_character_
    } else {
      phylo_payload$bivariate_dimension
    }
  )
}

# Modelled columns the bridge needs from `data`: every response plus every
# fixed-effect / structured predictor variable (phylo trees stripped first so a
# tree object symbol is not looked for in `data`). Used both to column-subset the
# marshalled data and to define the complete-case set for response = "drop".
drm_julia_needed_columns <- function(formula, phylo_payload = NULL) {
  needed <- unique(unlist(
    lapply(formula$entries, function(entry) {
      response_cols <- character()
      if (!is.na(entry$response)) {
        response_cols <- drm_julia_expand_response_columns(entry$response)
      }
      c(
        response_cols,
        all.vars(
          drm_julia_collapse_phylo_block(drm_julia_strip_phylo_tree(entry$rhs))
        )
      )
    }),
    use.names = FALSE
  ))
  if (!is.null(phylo_payload)) {
    needed <- unique(c(needed, phylo_payload$group))
  }
  needed
}

# Expand response labels that encode cbind(successes, failures) into the two
# underlying data columns the Julia bridge must marshal.
drm_julia_expand_response_columns <- function(response) {
  response <- as.character(response)
  if (grepl("^cbind\\(", response)) {
    inside <- sub("^cbind\\((.*)\\)$", "\\1", response)
    parts <- trimws(strsplit(inside, ",", fixed = TRUE)[[1L]])
    if (length(parts) >= 2L) {
      return(parts[seq_len(2L)])
    }
  }
  response
}

# Drop rows with any NA in a modelled column when the caller requested
# response = "drop" (#694). Mirrors native TMB's complete.cases(data[, vars])
# so the Julia bridge fits the same complete-case data native drm() would, rather
# than passing NA rows into DRM.jl's non-Gaussian phylo Laplace (which has no
# missing handling and returns NaN / non-convergence).
drm_julia_drop_missing_rows <- function(data, formula, phylo_payload = NULL) {
  needed <- drm_julia_needed_columns(formula, phylo_payload = phylo_payload)
  present <- intersect(needed, names(data))
  if (length(present) == 0L) {
    return(data)
  }
  keep <- stats::complete.cases(data[, present, drop = FALSE])
  if (all(keep)) {
    return(data)
  }
  data[keep, , drop = FALSE]
}

drm_julia_bridge_data <- function(data, formula, phylo_payload = NULL) {
  needed <- drm_julia_needed_columns(formula, phylo_payload = phylo_payload)
  missing <- setdiff(needed, names(data))
  if (length(missing) > 0L) {
    cli::cli_abort(
      "{.code engine = \"julia\"} could not find model variable{?s} {.val {missing}} in {.arg data}."
    )
  }
  data[, needed, drop = FALSE]
}

drm_julia_bridge_options <- function(phylo_payload, method = "ML") {
  # `method = "REML"` reaches DRM.jl's `drm(...; method = :REML)` via
  # bridge.jl's `options[:method]` hook (src/bridge.jl:118-120). It is forwarded
  # on the non-phylo Gaussian path and on the Gaussian sigma-phylo location-scale
  # path and on the bivariate q4 phylogenetic route (the caller gates both);
  # the default "ML" leaves the non-REML payload byte-identical to the
  # parity-tested baseline.
  reml <- identical(method, "REML")
  if (is.null(phylo_payload)) {
    if (reml) {
      return(list(method = "REML"))
    }
    return(list())
  }
  if (isTRUE(phylo_payload$bivariate)) {
    if (identical(phylo_payload$bivariate_dimension, "q2")) {
      return(list(g_tol = 1e-4))
    }
    # The q=4 PLSM route uses DRM.jl's own optimizer defaults (no g_tol
    # override): the direct-fit parity check matched the bridge to 0 with
    # defaults. REML still has to be forwarded explicitly.
    if (reml) {
      return(list(method = "REML"))
    }
    return(list())
  }

  # The sparse all-node Gaussian mean-only route needs a tighter tolerance to
  # meet the R-vs-Julia parity gate on the Route A fixture. The non-Gaussian
  # univariate phylo routes used to retain a 1e-4 smoke-range tolerance "until
  # their own parity fixtures justify a route-specific change" — they now do
  # (2026-08-27): SE parity is banked at 1e-7..5e-6 relative on those routes,
  # and DRM.jl's converged flag (#491) now answers a fixed relative criterion
  # instead of "did the optimiser meet the tolerance you asked for", so a
  # bridge that asks for 1e-4 gets fits truthfully reported as NOT at that
  # standard. 1e-8 matches DRM.jl's own drm() default; the estimates barely
  # move (that was #491's finding), the flag stops lying, and the live
  # phylo-count / nongaussian / Workflow G tests assert converged again.
  g_tol <- if (
    identical(phylo_payload$family_type, "gaussian") &&
      identical(phylo_payload$locscale_mode, "mean_only")
  ) {
    # The sparse all-node Gaussian mean-only route: 1e-8, parity-gate
    # motivated (Route A fixture). This branch was accidentally dropped in the
    # first rewrite of this ladder and test-julia-bridge.R:119 caught it on CI
    # — it stays FIRST so no later arm can shadow it.
    1e-8
  } else if (
    identical(phylo_payload$family_type, "gaussian") &&
      identical(phylo_payload$locscale_mode, "phylo_locscale") &&
      !reml
  ) {
    1e-6
  } else if (!identical(phylo_payload$family_type, "gaussian")) {
    # The non-Gaussian sparse-Laplace routes: their optimiser reaches 1e-8
    # (measured relative gradients 1e-7..1e-8) and their converged flag (#491)
    # honestly reports a 1e-4 request as not-at-standard.
    1e-8
  } else {
    # Gaussian sigma-phylo / locscale-REML routes keep their verified 1e-4:
    # their fitter has its OWN convergence criterion (not the #491 flag), its
    # optimiser stalls short of 1e-8 on the restricted objective, and the
    # first cut of this change swallowed these routes into 1e-8 and flipped a
    # previously-green REML fit to non-converged. Scope regained, behaviour
    # restored, and the route's own unit tests pin exactly this mapping.
    1e-4
  }
  if (reml) {
    return(list(g_tol = g_tol, method = "REML"))
  }
  if (identical(phylo_payload$locscale_mode, "phylo_locscale")) {
    return(list(g_tol = g_tol, phylo_coupled = TRUE))
  }
  list(g_tol = g_tol)
}

# Emit a single warning (and fall back to ML) when REML is requested for a
# Julia-engine cell that DRM.jl does not yet fit by restricted maximum
# likelihood. The Julia bridge remains a Gaussian-only REML claim: unsupported cells fall back to
# ML instead of implying that a nearby TMB or Julia path is a full REML fallback.
drm_julia_warn_reml_unsupported <- function(REML, cell) {
  if (!isTRUE(REML)) {
    return(invisible(FALSE))
  }
  cli::cli_warn(c(
    "{.code engine = \"julia\"} does not support {.code REML = TRUE} for {cell} models yet; fitting by maximum likelihood (ML) instead.",
    i = "The DRM.jl bridge currently supports REML only for documented Gaussian cells. Use {.code REML = FALSE} for this bridge cell or simplify to a documented Gaussian REML cell; native {.code engine = \"tmb\"} also has a separate diagnostic-only binomial REML route for an ordinary unlabelled {.code mu} random intercept or independent slope."
  ))
  invisible(TRUE)
}

drm_julia_formula_spec <- function(formula) {
  dpars <- vapply(formula$entries, `[[`, character(1L), "dpar")
  bad <- setdiff(dpars, julia_bridge_supported_dpars())
  if (length(bad) > 0L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cannot marshal formula parameter{?s}: {.val {bad}}.",
      i = "Use the native {.code engine = \"tmb\"} path for random-effect scale formulas, corpair formulas, or unsupported syntax."
    ))
  }

  out <- stats::setNames(
    vector("list", length(formula$entries)),
    dpars
  )
  for (i in seq_along(formula$entries)) {
    entry <- formula$entries[[i]]
    out[[i]] <- drm_julia_formula_entry(entry)
  }
  out
}

drm_julia_formula_entry <- function(entry) {
  rhs <- deparse1(
    drm_julia_rewrite_meta_V(
      drm_julia_collapse_phylo_block(drm_julia_strip_phylo_tree(entry$rhs))
    )
  )
  if (!is.na(entry$response)) {
    return(paste(entry$response, "~", rhs))
  }
  paste(entry$dpar, "~", rhs)
}

# DRM.jl's StatsModels parser accepts positional `meta_V(v)` (Workflow G
# fixture spelling) but rejects R's named-kwarg deparse `meta_V(V = v)` and
# namespaced `drmTMB::meta_V(...)`.
drm_julia_rewrite_meta_V <- function(expr) {
  if (!is.call(expr)) {
    return(expr)
  }
  parts <- as.list(expr)
  head <- parts[[1L]]
  is_meta <- FALSE
  if (is.name(head) && identical(as.character(head), "meta_V")) {
    is_meta <- TRUE
  } else if (
    is.call(head) &&
      identical(head[[1L]], as.name("::")) &&
      length(head) >= 3L &&
      identical(as.character(head[[3L]]), "meta_V")
  ) {
    is_meta <- TRUE
  }
  if (is_meta) {
    nm <- names(parts)
    if (!is.null(nm) && any(nm == "V", na.rm = TRUE)) {
      v_idx <- which(nm == "V")[[1L]]
      return(call("meta_V", parts[[v_idx]]))
    }
    if (length(parts) >= 2L) {
      return(call("meta_V", parts[[2L]]))
    }
  }
  parts[-1L] <- lapply(parts[-1L], drm_julia_rewrite_meta_V)
  as.call(parts)
}

drm_julia_call_bridge <- function(
  formula,
  family,
  data,
  tree = NULL,
  options = list()
) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} requires the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }

  drm_julia_setup()
  JuliaCall::julia_call(
    "drmTMB_drm_bridge",
    formula,
    family,
    as.list(data),
    tree,
    if (length(options) == 0L) NULL else options
  )
}

drm_julia_call_q2_phylo_point_export <- function(
  Y,
  X,
  species,
  tree,
  options = list()
) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} q2 phylo diagnostics require the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }
  Y <- drm_julia_as_matrix(Y)
  X <- drm_julia_as_matrix(X)
  if (ncol(Y) != 2L) {
    cli::cli_abort(
      "{.fn drm_julia_call_q2_phylo_point_export} requires {.arg Y} to have exactly two columns."
    )
  }
  if (nrow(X) != nrow(Y)) {
    cli::cli_abort(
      "{.fn drm_julia_call_q2_phylo_point_export} requires {.arg X} and {.arg Y} to have the same number of rows."
    )
  }
  species <- as.character(species)
  if (length(species) != nrow(Y)) {
    cli::cli_abort(
      "{.fn drm_julia_call_q2_phylo_point_export} requires {.arg species} to have one value per row of {.arg Y}."
    )
  }
  info <- validate_phylo_tree(tree, species = species)
  tree_payload <- drm_julia_phylo_tree_payload(tree, info = info)
  species_index <- match(species, tree_payload$tip_order)
  if (anyNA(species_index)) {
    cli::cli_abort(
      "{.fn drm_julia_call_q2_phylo_point_export} could not map every species to the phylogenetic tree tips."
    )
  }

  drm_julia_setup()
  JuliaCall::julia_call(
    "drmTMB_drm_bridge_q2_phylo",
    Y,
    X,
    as.integer(species_index),
    tree_payload$newick,
    if (length(options) == 0L) NULL else options
  )
}

drm_julia_call_inference <- function(
  object,
  method,
  level,
  R,
  seed,
  threads
) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} inference requires the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }
  payload <- object$bridge_payload
  if (is.null(payload) || is.null(payload$tree)) {
    cli::cli_abort(c(
      "Julia-engine profile and bootstrap intervals require a stored bridge payload.",
      i = "Refit the Gaussian phylogenetic model with {.code engine = \"julia\"} before calling {.fn confint}."
    ))
  }

  drm_julia_setup()
  JuliaCall::julia_call(
    "drmTMB_drm_bridge_inference",
    payload$formula,
    object$model$model_type,
    as.list(payload$data),
    payload$tree,
    if (length(payload$options) == 0L) NULL else payload$options,
    method,
    level,
    as.integer(R),
    seed,
    threads
  )
}

# Ordinary fixed-effect profile / bootstrap intervals (#460). A different
# Julia entry point (`drmTMB_drm_bridge_fixef_inference`, registered in
# drm_julia_setup()) than the phylogenetic SD target's
# `drmTMB_drm_bridge_inference` -- that one is scoped to the SD row and its
# picker explicitly refuses fixed-effect rows. `target` is the single
# `target_class == "fixed-effect"` row selected in confint.drmTMB_julia().
# Unlike the SD target, the tree is optional here: refitting from
# `payload$formula` / `payload$data` only needs `payload$tree` when the
# formula itself carries a `phylo()` term.
drm_julia_call_fixef_inference <- function(
  object,
  target,
  method,
  level,
  R,
  seed,
  threads
) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} inference requires the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }
  payload <- object$bridge_payload
  if (is.null(payload)) {
    cli::cli_abort(c(
      "Julia-engine profile and bootstrap intervals require a stored bridge payload.",
      i = "Refit the model with {.code engine = \"julia\"} before calling {.fn confint}."
    ))
  }
  # DRM.jl's non-Gaussian bootstrap_result() cannot thread a tree through its
  # internal refit closure -- only the Gaussian-specific method accepts
  # tree/algorithm/g_tol kwargs (DRM.jl src/inference.jl: the DrmFit{<:Gaussian}
  # method vs. the generic DrmFit fallback, which rejects any non-nothing K/A/
  # tree kwarg and, even when tree is omitted, never re-attaches the tree on
  # refit). Every simulated refit of a phylogenetic non-Gaussian fit would
  # therefore fail identically, so refuse up front with a clear message
  # instead of surfacing DRM.jl's "all N bootstrap replicates failed".
  is_gaussian_family <- object$model$model_type %in% c("gaussian", "biv_gaussian")
  if (
    identical(method, "bootstrap") &&
      !is_gaussian_family &&
      !is.null(payload$tree)
  ) {
    cli::cli_abort(c(
      "Julia-engine bootstrap intervals for fixed effects are not available on a phylogenetic non-Gaussian fit.",
      i = "DRM.jl's bootstrap refit cannot re-attach the phylogenetic tree for non-Gaussian families yet.",
      i = "Use {.code method = \"profile\"} or {.code method = \"wald\"} instead, or {.code engine = \"tmb\"} for a native bootstrap."
    ))
  }

  drm_julia_setup()
  JuliaCall::julia_call(
    "drmTMB_drm_bridge_fixef_inference",
    payload$formula,
    object$model$model_type,
    as.list(payload$data),
    payload$tree,
    if (length(payload$options) == 0L) NULL else payload$options,
    method,
    level,
    as.integer(R),
    seed,
    threads,
    target$dpar[[1L]],
    target$term[[1L]]
  )
}

drm_julia_phylo_payload <- function(formula, family_type, data, env) {
  phylo_terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) identical(term$type, "phylo"),
        entry$structured
      )
    }),
    recursive = FALSE
  )
  if (length(phylo_terms) == 0L) {
    return(NULL)
  }
  bivariate <- FALSE
  bivariate_dimension <- NA_character_
  locscale_mode <- NA_character_
  # Univariate Gaussian keeps the verified sparse all-node route. Poisson, NB2,
  # Gamma, Beta, and Binomial add the non-Gaussian phylo (count / location-scale /
  # mean-only) routes; bivariate Gaussian (q=4 PLSM) admits intercept phylo on
  # mu1/mu2/sigma1/sigma2 sharing ONE tree + grouping factor. All marshal the same
  # tree + group payload. The phylo-only set is shared with `drm_julia_family_tag`.
  phylo_families <- c("gaussian", drm_julia_phylo_only_families())
  if (family_type %in% phylo_families) {
    mu_phylo_terms <- Filter(
      function(term) {
        identical(term$type, "phylo") && identical(term$dpar, "mu")
      },
      phylo_terms
    )
    sigma_phylo_terms <- Filter(
      function(term) {
        identical(term$type, "phylo") && identical(term$dpar, "sigma")
      },
      phylo_terms
    )

    # Cluster 4: location-scale phylo. Gaussian admits the sigma-only REML path
    # (`sigma ~ phylo(1 | g)`) and the balanced mu+sigma path. The latter routes
    # to DRM.jl's coupled `(1|tag|phylo(g))` engine for the location-scale family
    # set. These branches are validated BEFORE the intercept-only guard below so
    # the check on sigma phylo terms is bypassed for these sub-paths.
    if (
      length(mu_phylo_terms) == 0L &&
        length(sigma_phylo_terms) == 1L &&
        identical(family_type, "gaussian")
    ) {
      sigma_term <- sigma_phylo_terms[[1L]]
      if (!identical(sigma_term$coef_names, "(Intercept)")) {
        cli::cli_abort(c(
          "{.code engine = \"julia\"} sigma-only phylo REML supports only an intercept phylo term on sigma.",
          i = "Use {.code sigma ~ phylo(1 | group, tree = tree)}."
        ))
      }
      rep_term <- sigma_term
      labels <- sigma_term$label
      locscale_mode <- "sigma_only"
    } else if (
      length(mu_phylo_terms) == 1L &&
        length(sigma_phylo_terms) == 1L &&
        family_type %in% drm_julia_locscale_phylo_families()
    ) {
      mu_term <- mu_phylo_terms[[1L]]
      sigma_term <- sigma_phylo_terms[[1L]]
      if (
        !identical(mu_term$coef_names, "(Intercept)") ||
          !identical(sigma_term$coef_names, "(Intercept)")
      ) {
        cli::cli_abort(c(
          "{.code engine = \"julia\"} location-scale phylo (cluster 4) supports only intercept phylo terms on mu and sigma.",
          i = "Use {.code phylo(1 | group, tree = tree)} on both {.code mu} and {.code sigma}."
        ))
      }
      if (
        !identical(mu_term$group, sigma_term$group) ||
          !identical(mu_term$tree, sigma_term$tree)
      ) {
        cli::cli_abort(c(
          "{.code engine = \"julia\"} location-scale phylo (cluster 4) requires the mu and sigma {.fn phylo} terms to share the same group and tree.",
          i = "Use the same {.fn phylo} call in both {.code mu} and {.code sigma} formulas."
        ))
      }
      rep_term <- mu_term
      labels <- c(mu_term$label, sigma_term$label)
      locscale_mode <- "phylo_locscale"
    } else {
      # Standard intercept-only phylo on mu (mean-only or simple sigma ~ 1).
      if (length(phylo_terms) != 1L) {
        cli::cli_abort(c(
          "{.code engine = \"julia\"} currently supports one {.fn phylo} term.",
          i = "Use native {.code engine = \"tmb\"} for multiple phylogenetic terms."
        ))
      }
      term <- phylo_terms[[1L]]

      # Cluster 3: structured slope phylo(1+x|g) on mu for NB2/Gamma/Beta/Poisson.
      # Allow multi-entry coef_names (intercept + slope) for the slope families.
      slope_families <- drm_julia_slope_phylo_families()
      is_slope <- identical(term$dpar, "mu") &&
        length(term$coef_names) == 2L &&
        identical(term$coef_names[[1L]], "(Intercept)") &&
        family_type %in% slope_families
      if (
        !identical(term$dpar, "mu") ||
          (!identical(term$coef_names, "(Intercept)") && !is_slope)
      ) {
        cli::cli_abort(c(
          "{.code engine = \"julia\"} currently supports {.code phylo(1 | group, tree = tree)} or {.code phylo(1+x | group, tree = tree)} in the {.code mu} formula.",
          i = "Use native {.code engine = \"tmb\"} for residual-scale phylogenetic effects or direct-SD formulas."
        ))
      }
      if (!is_slope) {
        sigma_entries <- Filter(
          function(entry) identical(entry$dpar, "sigma"),
          formula$entries
        )
        if (
          length(sigma_entries) > 0L &&
            !all(vapply(
              sigma_entries,
              function(entry) drm_julia_is_intercept_rhs(entry$rhs),
              logical(1L)
            ))
        ) {
          cli::cli_abort(c(
            "{.code engine = \"julia\"} uses DRM.jl's sparse all-node route for phylogenetic bridge fits, which currently requires {.code sigma ~ 1}.",
            i = "Use native {.code engine = \"tmb\"} for phylogenetic models with predictor-dependent residual scale until the sparse Julia route has parity tests."
          ))
        }
        locscale_mode <- "mean_only"
      } else {
        locscale_mode <- "phylo_slope"
      }
      rep_term <- term
      labels <- term$label
    }
  } else if (identical(family_type, "biv_gaussian")) {
    allowed <- c("mu1", "mu2", "sigma1", "sigma2")
    dpars <- vapply(phylo_terms, `[[`, character(1L), "dpar")
    if (!all(dpars %in% allowed)) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} routes bivariate {.fn phylo} only on {.val {allowed}}.",
        x = "Unsupported phylogenetic axis: {.val {setdiff(dpars, allowed)}}.",
        i = "Use native {.code engine = \"tmb\"} for phylogenetic {.code rho12} or other axes."
      ))
    }
    bivariate_dimension <- if (setequal(dpars, c("mu1", "mu2"))) {
      "q2"
    } else if (setequal(dpars, allowed)) {
      "q4"
    } else {
      NA_character_
    }
    if (is.na(bivariate_dimension)) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} requires either q2 {.code mu1/mu2} or q4 all-four-axis bivariate {.fn phylo} cells.",
        x = "Phylogenetic axes supplied: {.val {dpars}}.",
        i = "Use native {.code engine = \"tmb\"} for one-axis or three-axis partial bivariate phylogenetic structure."
      ))
    }
    if (
      !all(vapply(
        phylo_terms,
        function(t) identical(t$coef_names, "(Intercept)"),
        logical(1L)
      ))
    ) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} currently supports only intercept {.code phylo(1 | group, tree = tree)} terms in bivariate q2/q4 routes.",
        i = "Use native {.code engine = \"tmb\"} for phylogenetic slopes in the location-scale model."
      ))
    }
    groups <- vapply(phylo_terms, `[[`, character(1L), "group")
    trees <- vapply(phylo_terms, `[[`, character(1L), "tree")
    if (length(unique(groups)) != 1L || length(unique(trees)) != 1L) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} requires all bivariate {.fn phylo} terms to share one tree and grouping factor.",
        i = "Use native {.code engine = \"tmb\"} for heterogeneous phylogenetic structure across axes."
      ))
    }
    rep_term <- phylo_terms[[1L]]
    labels <- vapply(phylo_terms, `[[`, character(1L), "label")
    bivariate <- TRUE
  } else {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} can marshal {.fn phylo} only for univariate Gaussian, Poisson, NB2, Gamma, Beta, Binomial, or bivariate Gaussian (q=4) fits.",
      i = "Use native {.code engine = \"tmb\"} for other phylogenetic fits until the bridge has parity tests."
    ))
  }

  if (!rep_term$group %in% names(data)) {
    cli::cli_abort(
      "Phylogenetic grouping variable {.field {rep_term$group}} was not found in {.arg data}."
    )
  }

  tree <- get(rep_term$tree, envir = env, inherits = TRUE)
  species <- as.character(data[[rep_term$group]])
  cache <- drm_julia_phylo_payload_cache
  if (
    !is.null(cache$full_tree) &&
      identical(cache$full_tree, tree) &&
      identical(cache$full_group, rep_term$group) &&
      identical(cache$full_label, labels) &&
      identical(cache$full_bivariate_dimension, bivariate_dimension) &&
      identical(cache$full_species, species)
  ) {
    return(cache$full_payload)
  }

  info <- validate_phylo_tree(tree, species = species)
  tree_payload <- drm_julia_phylo_tree_payload(tree, info = info)
  row_order <- order(
    match(species, tree_payload$tip_order),
    seq_len(nrow(data))
  )

  payload <- list(
    newick = tree_payload$newick,
    group = rep_term$group,
    row_order = row_order,
    bivariate = bivariate,
    bivariate_dimension = bivariate_dimension,
    family_type = family_type,
    locscale_mode = locscale_mode,
    structured_sd_scales = stats::setNames(
      rep(tree_payload$sd_scale, length(labels)),
      labels
    )
  )
  cache$full_tree <- tree
  cache$full_group <- rep_term$group
  cache$full_label <- labels
  cache$full_bivariate_dimension <- bivariate_dimension
  cache$full_species <- species
  cache$full_payload <- payload
  payload
}

drm_julia_phylo_tree_payload <- function(tree, info = NULL) {
  cache <- drm_julia_phylo_payload_cache
  if (!is.null(cache$tree) && identical(cache$tree, tree)) {
    return(cache$payload)
  }
  if (is.null(info)) {
    info <- validate_phylo_tree(tree)
  }
  payload <- drm_julia_phylo_newick(tree, info = info)
  payload$sd_scale <- drm_julia_phylo_sd_scale(tree, info = info)
  cache$tree <- tree
  cache$payload <- payload
  payload
}

drm_julia_phylo_sd_scale <- function(tree, info = NULL) {
  if (is.null(info)) {
    info <- validate_phylo_tree(tree)
  }
  edge <- matrix(as.integer(tree$edge), ncol = 2L)
  edge_length <- as.numeric(tree$edge.length)
  children <- split(seq_len(nrow(edge)), edge[, 1L])
  depths <- rep(NA_real_, max(edge))
  depths[[info$root]] <- 0

  walk <- function(node) {
    child_edges <- children[[as.character(node)]]
    if (is.null(child_edges)) {
      return(invisible(NULL))
    }
    for (edge_index in child_edges) {
      child <- edge[[edge_index, 2L]]
      depths[[child]] <<- depths[[node]] + edge_length[[edge_index]]
      walk(child)
    }
    invisible(NULL)
  }

  walk(info$root)
  depths <- depths[seq_len(info$n_tip)]
  sqrt(mean(depths))
}

drm_julia_is_intercept_rhs <- function(rhs) {
  identical(rhs, 1) || identical(rhs, quote(1))
}

# Structured markers that carry an auxiliary object (tree / matrix / coords) as a
# named kwarg that DRM.jl receives separately, NOT in the formula. Each marker's
# entry lists the kwarg names to strip before deparsing the formula for the Julia
# bridge: `phylo(1 | g, tree = t)` -> `phylo(1 | g)`,
# `relmat(1 | g, K = K)` -> `relmat(1 | g)`, etc. Stripping also removes the
# object symbol from `all.vars`, so the bridge does not look for the matrix in
# `data`.
drm_julia_structured_marker_kwargs <- function() {
  list(
    phylo = "tree",
    relmat = c("K", "Q"),
    animal = c("A", "Ainv", "pedigree"),
    spatial = c("coords", "mesh")
  )
}

# Back-compat name kept for the phylo route; now strips the auxiliary-object
# kwarg from any structured marker (phylo / relmat / animal / spatial).
drm_julia_strip_phylo_tree <- function(expr) {
  drm_julia_strip_structured_kwargs(expr)
}

drm_julia_strip_structured_kwargs <- function(expr) {
  if (!is.call(expr)) {
    return(expr)
  }
  call <- as.list(expr)
  marker_kwargs <- drm_julia_structured_marker_kwargs()
  head <- call[[1L]]
  marker <- if (is.name(head)) as.character(head) else NULL
  if (!is.null(marker) && marker %in% names(marker_kwargs)) {
    drop <- marker_kwargs[[marker]]
    names_call <- names(call)
    if (is.null(names_call)) {
      keep <- rep(TRUE, length(call))
    } else {
      keep <- !(names_call %in% drop)
      keep[is.na(keep)] <- TRUE
    }
    call <- call[keep]
  } else {
    call[-1L] <- lapply(call[-1L], drm_julia_strip_structured_kwargs)
  }
  as.call(call)
}

# Collapse drmTMB's labelled covariance-block grammar `re | label | group` to
# DRM.jl's `re | group` inside structured-marker calls. DRM.jl implies the q2 or
# q4 Sigma_a from the axes sharing one structured marker + grouping factor, so
# the block label is dropped on the way across the bridge. The original R
# formula is still retained on the fitted object for extractor labels.
drm_julia_collapse_phylo_block <- function(expr) {
  if (!is.call(expr)) {
    return(expr)
  }
  parts <- as.list(expr)
  marker <- if (is.name(parts[[1L]])) as.character(parts[[1L]]) else NULL
  if (!is.null(marker) && marker %in% names(drm_julia_structured_marker_kwargs())) {
    nm <- names(parts)
    for (i in seq_along(parts)) {
      if (i == 1L) {
        next
      }
      if (!is.null(nm) && !is.na(nm[[i]]) && nzchar(nm[[i]])) {
        next
      }
      bar <- parts[[i]]
      if (
        is.call(bar) &&
          identical(bar[[1L]], as.name("|")) &&
          length(bar) == 3L &&
          is.call(bar[[2L]]) &&
          identical(bar[[2L]][[1L]], as.name("|")) &&
          length(bar[[2L]]) == 3L
      ) {
        parts[[i]] <- call("|", bar[[2L]][[2L]], bar[[3L]])
      }
      break
    }
    return(as.call(parts))
  }
  parts[-1L] <- lapply(parts[-1L], drm_julia_collapse_phylo_block)
  as.call(parts)
}

drm_julia_phylo_newick <- function(tree, info = NULL) {
  if (is.null(info)) {
    info <- validate_phylo_tree(tree)
  }
  if (any(tree$edge.length <= 0)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} requires positive phylogenetic branch lengths."
    )
  }
  bad_label <- grep("^[A-Za-z0-9_.-]+$", tree$tip.label, invert = TRUE)
  if (length(bad_label) > 0L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} can serialize only simple phylogenetic tip labels in this slice.",
      x = "Unsupported tip label: {.val {tree$tip.label[[bad_label[[1L]]]]}}."
    ))
  }

  edge <- matrix(as.integer(tree$edge), ncol = 2L)
  children <- split(seq_len(nrow(edge)), edge[, 1L])
  child_counts <- lengths(children)
  if (any(child_counts != 2L)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} currently serializes binary phylogenies only."
    )
  }
  edge_length_by_child <- stats::setNames(
    tree$edge.length,
    as.character(edge[, 2L])
  )
  tip_order <- character()
  node_newick <- function(node) {
    if (node <= info$n_tip) {
      label <- tree$tip.label[[node]]
      tip_order <<- c(tip_order, label)
    } else {
      child_edges <- children[[as.character(node)]]
      child_nodes <- edge[child_edges, 2L]
      label <- paste0(
        "(",
        paste(vapply(child_nodes, node_newick, character(1L)), collapse = ","),
        ")"
      )
    }
    if (identical(node, info$root)) {
      return(label)
    }
    paste0(
      label,
      ":",
      format(
        edge_length_by_child[[as.character(node)]],
        scientific = FALSE,
        digits = 17L,
        trim = TRUE
      )
    )
  }

  newick <- paste0(node_newick(info$root), ";")
  list(newick = newick, tip_order = tip_order)
}

drm_julia_restore_row_order <- function(result, row_order) {
  if (is.null(row_order)) {
    return(result)
  }
  result <- as.list(result)
  restore <- order(row_order)
  for (field in c("fitted", "residuals", "sigma")) {
    result[[field]] <- drm_julia_restore_value_order(result[[field]], restore)
  }
  result
}

drm_julia_restore_value_order <- function(x, restore) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.matrix(x) && nrow(x) == length(restore)) {
    return(x[restore, , drop = FALSE])
  }
  if (is.atomic(x) && length(x) == length(restore)) {
    return(x[restore])
  }
  if (is.list(x)) {
    return(lapply(x, drm_julia_restore_value_order, restore = restore))
  }
  x
}

drm_julia_cran_lane_blocked <- function(is_interactive = interactive()) {
  # Shared CRAN-lane predicate for live Julia. Matches tests/testthat.R
  # `not_cran` and only blocks non-interactive checks (R CMD check / win-builder).
  !identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true") &&
    !isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false"))) &&
    !isTRUE(is_interactive)
}

drm_julia_setup <- function(path = drm_julia_path()) {
  # Hard stop on the CRAN / win-builder lane. Suggests JuliaCall + host Julia is
  # not enough to justify entering julia_setup(): Ligges R-release hung for
  # ~10448s after #1061 because CRAN-lane expect_error(engine = "julia") still
  # reached this function (Workflow G admits fixed-effect binomial). Opt in with
  # DRMTMB_JULIA_TESTS=true; repository CI sets NOT_CRAN=true.
  if (drm_julia_cran_lane_blocked()) {
    cli::cli_abort(c(
      "Live Julia setup is disabled on the CRAN check lane.",
      i = "Set {.envvar NOT_CRAN=true} for the full suite, or {.envvar DRMTMB_JULIA_TESTS=true} to opt in."
    ))
  }
  normalized_path <- if (nzchar(path)) {
    normalizePath(path, winslash = "/", mustWork = TRUE)
  } else {
    ""
  }
  if (
    isTRUE(drm_julia_setup_state$ready) &&
      identical(drm_julia_setup_state$path, normalized_path)
  ) {
    return(invisible(TRUE))
  }
  JuliaCall::julia_setup(installJulia = FALSE)
  if (nzchar(normalized_path)) {
    JuliaCall::julia_command(paste0(
      "import Pkg; Pkg.activate(",
      drm_julia_quote(normalized_path),
      "); using DRM"
    ))
  } else {
    JuliaCall::julia_command("using DRM")
  }
  # Random is Julia's own stdlib (not a DRM.jl addition); the fixed-effect
  # inference wrapper below seeds `bootstrap_result()`'s RNG with it.
  JuliaCall::julia_command("using Random")
  JuliaCall::julia_command(
    paste(
      "drmTMB_drm_bridge(formula, family, data, tree, options) =",
      "DRM.drm_bridge(formula = formula, family = family, data = data, tree = tree, options = options)"
    )
  )
  JuliaCall::julia_command(
    paste(
      "drmTMB_drm_bridge_q2_phylo(Y, X, species, tree, options) =",
      "DRM.drm_bridge_q2_phylo(Y = Y, X = X, species = species, tree = tree, options = options)"
    )
  )
  JuliaCall::julia_command(
    paste(
      "drmTMB_drm_bridge_inference(formula, family, data, tree, options, method, level, B, seed, threads) =",
      "DRM.drm_bridge_inference(formula = formula, family = family, data = data, tree = tree, options = options, method = method, level = level, B = B, seed = seed, threads = threads)"
    )
  )
  # Ordinary fixed-effect profile / bootstrap intervals (#460). DRM.jl has no
  # dedicated bridge entry point for this -- `drm_bridge_inference` is scoped
  # to the phylogenetic SD row and its picker explicitly refuses fixed-effect
  # rows (`_bridge_pick_sd_row`) -- so this refits via the SAME private
  # marshalling helpers `drm_bridge_inference` itself uses internally
  # (`DRM._bridge_data` / `_bridge_formula` / `_bridge_family` / `_bridge_fit`,
  # reached by qualified name since Julia does not restrict access to
  # underscore-prefixed functions) and then calls the exported
  # `DRM.profile_result` / `DRM.bootstrap_result` on the requested coefficient
  # block, picking out the one (dpar, coef) row asked for. No DRM.jl source
  # changes; every number is produced by DRM.jl's own existing, tested
  # profile_result / bootstrap_result.
  JuliaCall::julia_command(
    paste(
      sep = "\n",
      "function drmTMB_drm_bridge_fixef_inference(formula, family, data, tree, options, method, level, B, seed, threads, dpar, coefname)",
      "    dat = DRM._bridge_data(data)",
      "    bundle, dat = DRM._bridge_formula(formula, family, dat)",
      "    fam = DRM._bridge_family(family)",
      "    opts = DRM._bridge_options(options)",
      "    tree_obj = tree === nothing ? nothing : DRM._bridge_tree(tree)",
      "    fit = DRM._bridge_fit(bundle, fam, dat; tree = tree_obj, K = nothing, A = nothing, coords = nothing, options = opts)",
      "    blockparm = Symbol(dpar)",
      "    function drmTMB_pick_fixef_row(rows)",
      "        hit = filter(r -> r.param === blockparm && r.coef == coefname, rows)",
      "        isempty(hit) && throw(ArgumentError(\"drmTMB_drm_bridge_fixef_inference: no row for $(dpar):$(coefname)\"))",
      "        first(hit)",
      "    end",
      "    if method == \"profile\"",
      "        result = DRM.profile_result(fit; level = level, threads = threads, parm = blockparm)",
      "        row = drmTMB_pick_fixef_row(result.ci)",
      "        return DRM._bridge_inference_flatten(row; method = \"profile\", status = \"profile\",",
      "            attempted = result.attempted, used = result.used, failed = result.failed,",
      "            elapsed = result.elapsed, threaded = result.threaded, worker_threads = result.worker_threads,",
      "            julia_threads = result.julia_threads, blas_threads = result.blas_threads,",
      "            message = \"profile_result completed\")",
      "    elseif method == \"bootstrap\"",
      "        rng = seed === nothing ? Random.default_rng() : Random.MersenneTwister(Int(seed))",
      "        result = if fit isa DRM.DrmFit{<:DRM.Gaussian}",
      "            DRM.bootstrap_result(fit; data = dat, B = Int(B), level = level, rng = rng,",
      "                tree = tree_obj, threads = threads, failures = :skip, check_converged = true,",
      "                algorithm = Symbol(get(opts, :algorithm, :auto)), g_tol = Float64(get(opts, :g_tol, 1e-8)))",
      "        else",
      "            DRM.bootstrap_result(fit; data = dat, B = Int(B), level = level, rng = rng,",
      "                threads = threads, failures = :skip, check_converged = true)",
      "        end",
      "        row = drmTMB_pick_fixef_row(result.summary)",
      "        return DRM._bridge_inference_flatten(row; method = \"bootstrap\",",
      "            status = result.used >= 2 ? \"bootstrap\" : \"bootstrap_unavailable\",",
      "            attempted = result.attempted, used = result.used, failed = result.failed,",
      "            elapsed = result.elapsed, threaded = result.threaded, worker_threads = result.worker_threads,",
      "            julia_threads = result.julia_threads, blas_threads = result.blas_threads,",
      "            message = \"$(result.used)/$(result.attempted) successful refits\")",
      "    end",
      "    throw(ArgumentError(\"drmTMB_drm_bridge_fixef_inference: unsupported method `$method`\"))",
      "end"
    )
  )
  # General-covariance structured route: the user-supplied K / A / coords matrix
  # crosses as a Julia array (or `nothing`) and is forwarded to DRM.drm_bridge.
  # Gaussian spatial coords are converted to native drmTMB's fixed-range K target
  # before crossing, then reconstructed under the user's spatial() label.
  JuliaCall::julia_command(
    paste(
      "drmTMB_drm_bridge_structured(formula, family, data, K, A, coords, options) =",
      "DRM.drm_bridge(formula = formula, family = family, data = data, K = K, A = A, coords = coords, options = options)"
    )
  )
  JuliaCall::julia_command(drm_julia_xfam_helper_source())
  drm_julia_setup_state$ready <- TRUE
  drm_julia_setup_state$path <- normalized_path
  invisible(TRUE)
}

drm_julia_path <- function() {
  explicit <- getOption("drmTMB.DRM.jl.path", "")
  if (is.character(explicit) && length(explicit) == 1L && nzchar(explicit)) {
    return(explicit)
  }
  env_path <- Sys.getenv("DRM_JL_PATH", "")
  if (nzchar(env_path)) {
    return(env_path)
  }
  sibling <- normalizePath(
    file.path(getwd(), "..", "DRM.jl"),
    winslash = "/",
    mustWork = FALSE
  )
  if (dir.exists(sibling)) {
    return(sibling)
  }
  ""
}

drm_julia_quote <- function(x) {
  paste0("\"", gsub("\\\\", "/", gsub("\"", "\\\\\"", x)), "\"")
}

new_drmTMB_julia <- function(
  result,
  call,
  formula,
  family,
  data,
  family_type,
  structured_sd_scales = NULL,
  bridge_payload = NULL,
  requested_REML = NULL,
  effective_REML = NULL
) {
  result <- as.list(result)
  coef_names <- as.character(result$coef_names)
  coefficients <- stats::setNames(
    as.numeric(unlist(result$coefficients, use.names = FALSE)),
    coef_names
  )
  structured_parameters <- drm_julia_structured_parameters(
    coefficients = coefficients,
    formula = formula,
    sd_scales = structured_sd_scales
  )
  # Structured (non-fixed-effect) coefficients that must NOT appear in the
  # fixed-effect coefficient table / Wald CIs: `resd_`/`recov_` SD & residual
  # correlation working parameters, and the q2/q4 bivariate among-axis
  # `phylocov_Sigma_a:Lij` log-Cholesky entries. The latter are unbounded
  # Cholesky factors, not linear-predictor coefficients, so reporting z/p/Wald
  # intervals for them is meaningless (#692). They are kept in a dedicated
  # `phylocov` slot below so drm_julia_phylocov_matrix() can still reconstruct
  # Sigma_a.
  structured_coef <- startsWith(names(coefficients), "resd_") |
    startsWith(names(coefficients), "recov_") |
    startsWith(names(coefficients), "phylocov_")
  fixed <- !structured_coef
  fixed_coefficients <- coefficients[fixed]
  # Dedicated phylocov slot: the among-axis log-Cholesky entries with the
  # `phylocov_` prefix stripped (so keys are "Sigma_a:L11", ...), read straight
  # off the full coefficient vector. NULL when the fit has no phylocov block.
  phylocov_coef <- coefficients[startsWith(names(coefficients), "phylocov_")]
  phylocov_slot <- if (length(phylocov_coef) > 0L) {
    stats::setNames(
      as.numeric(phylocov_coef),
      sub("^phylocov_", "", names(phylocov_coef))
    )
  } else {
    NULL
  }
  coefficient_blocks <- split(
    fixed_coefficients,
    sub("_.*$", "", names(fixed_coefficients))
  )
  coefficient_blocks <- lapply(coefficient_blocks, function(x) {
    stats::setNames(x, sub("^[^_]+_", "", names(x)))
  })
  V_full <- drm_julia_vcov(result$vcov, coef_names)
  V <- V_full[fixed, fixed, drop = FALSE]
  finite_vcov <- length(V) > 0L && all(is.finite(V))
  finite_diag <- if (length(V) > 0L) {
    is.finite(diag(V))
  } else {
    logical()
  }
  partial_vcov <- any(finite_diag) && !finite_vcov
  finite_vcov_dpars <- unique(sub("_.*$", "", names(finite_diag)[finite_diag]))
  uncertainty_status <- if (finite_vcov) {
    "ok"
  } else if (partial_vcov) {
    "partial"
  } else {
    "unavailable"
  }
  payload_method <- if (
    is.list(bridge_payload) &&
      is.list(bridge_payload$options) &&
      identical(bridge_payload$options$method, "REML")
  ) {
    "REML"
  } else {
    "ML"
  }
  if (is.null(effective_REML)) {
    effective_REML <- identical(payload_method, "REML")
  }
  if (is.null(requested_REML)) {
    requested_REML <- isTRUE(effective_REML)
  }
  estimator <- if (isTRUE(effective_REML)) "REML" else "ML"
  out <- list(
    call = call,
    formula = formula,
    family = family,
    data = data,
    engine = "julia",
    estimator = estimator,
    REML = isTRUE(effective_REML),
    requested_REML = isTRUE(requested_REML),
    effective_REML = isTRUE(effective_REML),
    model = list(
      model_type = family_type,
      dpars = names(coefficient_blocks),
      data = data
    ),
    bridge = result,
    bridge_payload = bridge_payload,
    coefficients = coefficient_blocks,
    coef_vector = fixed_coefficients,
    phylocov = phylocov_slot,
    sdpars = structured_parameters$sdpars,
    structured_sd_scales = structured_sd_scales,
    corpars = structured_parameters$corpars,
    vcov = V,
    logLik = as.numeric(result$loglik),
    aic = as.numeric(result$aic),
    bic = as.numeric(result$bic),
    df = as.integer(result$df),
    nobs = as.integer(result$nobs),
    fitted = drm_julia_plain(result$fitted),
    residuals = drm_julia_plain(result$residuals),
    sigma = drm_julia_plain(result$sigma),
    corpairs = drm_julia_plain(result$corpairs),
    opt = list(convergence = if (isTRUE(result$converged)) 0L else 1L),
    uncertainty = list(
      status = uncertainty_status,
      se = finite_vcov,
      finite_dpars = finite_vcov_dpars,
      message = if (finite_vcov) {
        "DRM.jl bridge returned fixed-effect covariance."
      } else if (partial_vcov) {
        paste(
          "DRM.jl bridge returned a partial covariance matrix for",
          paste(finite_vcov_dpars, collapse = ", "),
          "coefficients; other fixed-effect or variance-component covariance",
          "entries are unavailable for this route."
        )
      } else {
        "DRM.jl bridge did not return finite fixed-effect covariance for this route."
      }
    )
  )
  class(out) <- "drmTMB_julia"
  out
}

drm_julia_reconstruction_status <- function(object) {
  if (!inherits(object, "drmTMB_julia")) {
    cli::cli_abort(
      "{.fn drm_julia_reconstruction_status} requires a {.cls drmTMB_julia} object."
    )
  }
  scalar_chr <- function(x, default = NA_character_) {
    if (is.null(x) || length(x) == 0L) {
      return(default)
    }
    as.character(x[[1L]])
  }
  profile_targets <- tryCatch(
    drm_julia_profile_targets(object),
    error = function(cnd) empty_profile_targets()
  )
  corpairs <- object$corpairs
  has_corpairs <- is.data.frame(corpairs) && nrow(corpairs) > 0L
  if (!has_corpairs && is.list(corpairs)) {
    has_corpairs <- length(corpairs) > 0L
  }
  out <- data.frame(
    model_type = scalar_chr(object$model$model_type),
    estimator = scalar_chr(object$estimator),
    requested_estimator = if (isTRUE(object$requested_REML)) {
      "REML"
    } else {
      "ML"
    },
    effective_estimator = if (isTRUE(object$effective_REML)) {
      "REML"
    } else {
      "ML"
    },
    payload_status = if (is.list(object$bridge_payload)) {
      "present"
    } else {
      "missing"
    },
    coefficient_status = if (length(object$coef_vector) > 0L) {
      "present"
    } else {
      "missing"
    },
    vcov_status = scalar_chr(object$uncertainty$status, "unavailable"),
    profile_target_status = if (nrow(profile_targets) > 0L) {
      "present"
    } else {
      "absent"
    },
    corpairs_status = if (has_corpairs) "present" else "absent",
    bridge_status = "diagnostic_only",
    inference_promotion = "none",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  class(out) <- c("drmTMB_julia_reconstruction_status", class(out))
  out
}

drm_julia_profile_targets <- function(object) {
  # Bivariate biv_gaussian q=4 path: four axes mu1/mu2/sigma1/sigma2, each with
  # a phylo SD stored in sdpars[[dpar]]. A biv_gaussian fit IS the bivariate case;
  # drm_julia_profile_targets_biv returns empty targets if no phylo SD is present
  # (e.g. a residual-only bivariate fit), so the gate is just model_type.
  is_biv <- identical(object$model$model_type, "biv_gaussian")
  if (is_biv) {
    return(drm_julia_profile_targets_biv(object))
  }

  # Univariate path (original behaviour): single phylo SD on dpar == "mu".
  values <- object$sdpars$mu
  if (is.null(values) || length(values) == 0L) {
    return(empty_profile_targets())
  }
  keep <- startsWith(names(values), "phylo(")
  if (!any(keep)) {
    return(empty_profile_targets())
  }

  values <- values[keep]
  term <- names(values)[[1L]]
  scale <- drm_julia_structured_sd_scale(object, term)
  profile_ready <- !is.null(object$bridge_payload) &&
    !is.null(object$bridge_payload$tree)
  out <- new_profile_target_row(
    parm = paste0("sd:mu:", term),
    target_class = "random-effect-sd",
    dpar = "mu",
    term = term,
    tmb_parameter = "resd",
    index = 1L,
    estimate = unname(values[[1L]]),
    link_estimate = log(unname(values[[1L]]) / scale),
    scale = "response",
    transformation = "exp",
    target_type = "direct",
    profile_ready = profile_ready,
    profile_note = if (profile_ready) {
      "ready"
    } else {
      "julia_bridge_payload_required"
    }
  )
  row.names(out) <- NULL
  validate_profile_targets(out)
}

# Bivariate profile targets: one row per axis (mu1, mu2, sigma1, sigma2).
# Each axis has its phylo SD in sdpars[[dpar]], keyed by the axis's phylo term
# label. The Julia `param` names are "sd_<dpar>" (e.g. "sd_mu1") and are used
# later in drm_julia_inference_confint_row to join rows to the Julia result.
drm_julia_profile_targets_biv <- function(object) {
  biv_dpars <- c("mu1", "mu2", "sigma1", "sigma2")
  bp <- object$bridge_payload
  # No phylo tree -> no among-axis SDs to profile (e.g. a residual-only bivariate fit);
  # fall back so confint() reports the supported-targets message.
  if (is.null(bp) || is.null(bp$tree)) {
    return(empty_profile_targets())
  }
  # The bivariate q4 julia fit does NOT populate sdpars (the among-axis Sigma_a
  # lives in the phylocov block). Reconstruct the fitted axis SDs from that
  # stored covariance so profile_targets() remains a truthful target inventory;
  # DRM.jl's drm_bridge_inference later re-derives the interval bounds from the
  # formula + data + tree.
  Sigma_a <- drm_julia_phylocov_matrix(object)
  if (is.null(Sigma_a)) {
    return(empty_profile_targets())
  }
  # Raw-Q-scale axis SDs from the log-Cholesky Sigma_a. DRM.jl builds the
  # phylogenetic precision Q from raw branch lengths (no unit-height
  # normalization), so these SDs are on the raw-Q scale where tip variance is
  # proportional to root-to-tip depth. To match native drmTMB's unit-height SD
  # convention -- and the univariate bridge, which multiplies its returned
  # log-SD by sd_scale = sqrt(mean(depths)) -- multiply each axis SD by the
  # shared tree's sd_scale (#693). All four axes share one tree, so one scale.
  axis_sd <- sqrt(diag(Sigma_a))
  if (
    length(axis_sd) != length(biv_dpars) ||
      any(!is.finite(axis_sd)) ||
      any(axis_sd <= 0)
  ) {
    return(empty_profile_targets())
  }
  names(axis_sd) <- biv_dpars

  # Term label for the four axis rows. The phylo term shares ONE group across the
  # four axes; its rendered label ("phylo(1 | <group>)") is carried on the fit's
  # structured_sd_scales names, which the bridge populates on BOTH the live fit and
  # the synthetic fixtures  -  so use that as the primary source. Fall back to the
  # parsed formula's phylo group, then bp$group, then a literal. This labels the
  # confint() parm rows with the real grouping variable instead of "group".
  scales <- object$structured_sd_scales
  if (is.null(scales)) {
    scales <- bp$structured_sd_scales
  }
  # The shared per-axis sd_scale (sqrt(mean(depths))). structured_sd_scales
  # carries one entry per axis label, all equal for a single tree; take the first
  # finite positive value, defaulting to 1 (unit-height / absent scale).
  sd_scale <- 1
  if (!is.null(scales) && length(scales)) {
    finite_scale <- unname(scales[is.finite(scales) & scales > 0])
    if (length(finite_scale)) {
      sd_scale <- finite_scale[[1L]]
    }
  }
  # Report the axis SDs on the native (unit-height) scale.
  axis_sd <- axis_sd * sd_scale
  scale_label <- if (
    !is.null(scales) && length(scales) && !is.null(names(scales))
  ) {
    names(scales)[[1]]
  } else {
    NULL
  }
  term <- if (!is.null(scale_label) && nzchar(scale_label)) {
    scale_label
  } else {
    phylo_terms <- unlist(
      lapply(bp$formula$entries, function(entry) {
        Filter(function(term) identical(term$type, "phylo"), entry$structured)
      }),
      recursive = FALSE
    )
    group <- if (length(phylo_terms) && !is.null(phylo_terms[[1]]$group)) {
      phylo_terms[[1]]$group
    } else if (!is.null(bp$group)) {
      bp$group
    } else {
      "group"
    }
    paste0("phylo(1 | ", group, ")")
  }
  rows <- vector("list", length(biv_dpars))
  for (i in seq_along(biv_dpars)) {
    dpar <- biv_dpars[[i]]
    rows[[i]] <- new_profile_target_row(
      parm = paste0("sd:", dpar, ":", term),
      target_class = "random-effect-sd",
      dpar = dpar,
      term = term,
      tmb_parameter = paste0("resd_", dpar),
      index = i,
      estimate = unname(axis_sd[[dpar]]),
      # Mirror the univariate transform: link_estimate = log(estimate / scale)
      # recovers the raw-Q-scale log-SD (see drm_julia_profile_targets_row,
      # line ~1639). drm_julia_inference_confint_multi later re-derives the
      # per-axis scale from estimate / exp(link_estimate).
      link_estimate = log(unname(axis_sd[[dpar]]) / sd_scale),
      scale = "response",
      transformation = "exp",
      target_type = "direct",
      profile_ready = TRUE,
      profile_note = "ready"
    )
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  validate_profile_targets(out)
}

drm_julia_structured_sd_scale <- function(object, term) {
  scales <- object$structured_sd_scales
  if (is.null(scales) && !is.null(object$bridge_payload)) {
    scales <- object$bridge_payload$structured_sd_scales
  }
  if (!is.null(scales) && term %in% names(scales)) {
    return(unname(scales[[term]]))
  }
  1
}

drm_julia_structured_parameters <- function(
  coefficients,
  formula,
  sd_scales = NULL
) {
  empty_sdpars <- list(mu = numeric(), sigma = numeric())
  empty_corpars <- list()
  structured <- coefficients[startsWith(names(coefficients), "resd_")]
  recov <- coefficients[startsWith(names(coefficients), "recov_")]
  if (length(structured) == 0L && length(recov) == 0L) {
    return(list(sdpars = empty_sdpars, corpars = empty_corpars))
  }

  # Structured terms that yield a `resd_<group>` SD block on the Julia side:
  # the phylo route plus the general-covariance relmat / animal / spatial route.
  # Keying the SD by each term's formula label (e.g. "relmat(1 | id)") matches
  # the native drmTMB extractor naming.
  structured_types <- c("phylo", drm_julia_structured_marker_types())
  terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) term$type %in% structured_types,
        entry$structured
      )
    }),
    recursive = FALSE
  )
  labels <- sub("^resd_", "", names(structured))
  dpars <- rep("mu", length(structured))
  if (length(terms) == length(structured)) {
    labels <- vapply(terms, `[[`, character(1L), "label")
    dpars <- vapply(terms, `[[`, character(1L), "dpar")
  }

  sdpars <- empty_sdpars
  for (i in seq_along(structured)) {
    dpar <- dpars[[i]]
    if (is.null(sdpars[[dpar]])) {
      sdpars[[dpar]] <- numeric()
    }
    scale <- if (!is.null(sd_scales) && labels[[i]] %in% names(sd_scales)) {
      unname(sd_scales[[labels[[i]]]])
    } else {
      1
    }
    sdpars[[dpar]][[labels[[i]]]] <- exp(unname(structured[[i]])) * scale
  }

  corpars <- empty_corpars
  if (length(recov) == 3L) {
    recov_labels <- sub("^recov_", "", names(recov))
    recov <- stats::setNames(as.numeric(unname(recov)), recov_labels)
    recov_value <- function(suffix) {
      hit <- grep(paste0(":", suffix, "$"), names(recov))
      if (length(hit) != 1L) {
        return(NA_real_)
      }
      unname(recov[[hit]])
    }
    log_l11 <- recov_value("L11")
    log_l22 <- recov_value("L22")
    l21 <- recov_value("L21")
    phylo_terms <- Filter(
      function(term) identical(term$type, "phylo"),
      terms
    )
    mu_terms <- Filter(
      function(term) identical(term$dpar, "mu"),
      phylo_terms
    )
    sigma_terms <- Filter(
      function(term) identical(term$dpar, "sigma"),
      phylo_terms
    )
    if (
      length(mu_terms) == 1L &&
        length(sigma_terms) == 1L &&
        all(is.finite(c(log_l11, log_l22, l21)))
    ) {
      scale_for <- function(label) {
        if (!is.null(sd_scales) && length(sd_scales) > 0L) {
          hits <- which(names(sd_scales) == label)
          if (length(hits) > 0L) {
            return(unname(sd_scales[[hits[[1L]]]]))
          }
        }
        1
      }
      l11 <- exp(log_l11)
      l22 <- exp(log_l22)
      sd_mu <- l11 * scale_for(mu_terms[[1L]]$label)
      sd_sigma <- sqrt(l21^2 + l22^2) * scale_for(sigma_terms[[1L]]$label)
      rho <- l21 / sqrt(l21^2 + l22^2)
      mu_label <- paste0("mu:", mu_terms[[1L]]$label)
      sigma_label <- paste0("sigma:", sigma_terms[[1L]]$label)
      sdpars$mu[[mu_label]] <- sd_mu
      sdpars$sigma[[sigma_label]] <- sd_sigma
      cor_name <- paste0(
        "cor(mu:(Intercept),sigma:(Intercept) | phylo | ",
        mu_terms[[1L]]$group,
        ")"
      )
      corpars$phylo <- stats::setNames(rho, cor_name)
    }
  }

  list(sdpars = sdpars, corpars = corpars)
}

drm_julia_vcov <- function(x, coef_names) {
  if (is.matrix(x)) {
    out <- matrix(as.numeric(x), nrow = nrow(x), ncol = ncol(x))
  } else if (is.list(x) && length(x) == length(coef_names)) {
    rows <- lapply(x, function(row) as.numeric(unlist(row, use.names = FALSE)))
    out <- do.call(rbind, rows)
  } else {
    out <- matrix(
      as.numeric(unlist(x, use.names = FALSE)),
      nrow = length(coef_names),
      ncol = length(coef_names)
    )
  }
  dimnames(out) <- list(coef_names, coef_names)
  out
}

drm_julia_plain <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.matrix(x)) {
    return(x)
  }
  if (is.list(x)) {
    if (length(x) == 0L) {
      return(list())
    }
    if (!is.null(names(x)) && all(nzchar(names(x)))) {
      return(lapply(x, function(value) {
        as.numeric(unlist(value, use.names = FALSE))
      }))
    }
    return(as.numeric(unlist(x, use.names = FALSE)))
  }
  if (is.numeric(x) || is.logical(x)) {
    return(x)
  }
  x
}

#' @export
print.drmTMB_julia <- function(x, ...) {
  cli::cli_text("<drmTMB Julia-engine fit>")
  cli::cli_text("  observations: {x$nobs}")
  if (!is.null(x$estimator)) {
    cli::cli_text("  estimator: {x$estimator}")
  }
  cli::cli_text("  logLik: {format(x$logLik, digits = 4)}")
  cli::cli_text("  convergence: {x$opt$convergence}")
  invisible(x)
}

#' @export
coef.drmTMB_julia <- function(object, dpar = NULL, ...) {
  if (is.null(dpar)) {
    return(object$coefficients)
  }
  dpar <- match.arg(dpar, names(object$coefficients))
  object$coefficients[[dpar]]
}

#' @export
fixef.drmTMB_julia <- function(object, ...) {
  coef.drmTMB_julia(object, ...)
}

#' @export
vcov.drmTMB_julia <- function(object, ...) {
  object$vcov
}

#' Inspect legacy interval output from a halted Julia bridge
#'
#' The Julia bridge is halted/deferred future work and is not a current fitting
#' or inference route. This method is retained only for inspecting existing
#' `drmTMB_julia` objects; use native TMB fits for new analyses.
#'
#' For a legacy `engine = "julia"` fit, `confint()` exposes two interval families:
#'
#' * `method = "wald"` (the default) builds symmetric Wald intervals for the
#'   fixed-effect coefficients (mu, sigma, ...) on the linear-predictor (link)
#'   scale, using the fixed-effect covariance DRM.jl marshals back through the
#'   bridge (`vcov(object)`). This mirrors the native drmTMB Wald path, whose
#'   fixed-effect rows are also reported on the link scale.
#' * `method = "profile"` / `method = "bootstrap"` re-enter DRM.jl's inference
#'   primitive. Two target families are supported:
#'   - the phylogenetic SD targets, transformed back to the positive response
#'     scale: the univariate Gaussian `sd:mu:phylo(1 | species)` target, and
#'     the four bivariate q = 4 targets `sd:mu1:*`, `sd:mu2:*`, `sd:sigma1:*`,
#'     and `sd:sigma2:*`;
#'   - ordinary fixed-effect coefficients (`fixef:<dpar>:<coef>`, e.g.
#'     `"fixef:mu:x"`), reported on the same link scale as the Wald rows. Not
#'     available for the bivariate q = 4 route (`biv_gaussian`), whose fixed
#'     effects are not individually profiled here.
#'
#' @param object A `drmTMB_julia` fit.
#' @param parm Optional target selection. For `"wald"`, compact coefficient
#'   labels (`"mu:x"`) or full names (`"fixef:mu:x"`); for `"profile"` /
#'   `"bootstrap"`, either a fixed-effect target such as `"fixef:mu:x"` (or
#'   the compact `"mu:x"` alias) or a supported SD target name such as
#'   `"sd:mu:phylo(1 | species)"` or, for q = 4 bivariate fits,
#'   `"sd:sigma1:phylo(1 | species)"`.
#' @param level Confidence level.
#' @param method `"wald"` (default), `"profile"`, or `"bootstrap"`.
#' @param R Bootstrap replicate count (used only when `method = "bootstrap"`).
#' @param seed Optional bootstrap seed.
#' @param threads Logical; request Julia-side threaded inference for the
#'   profile / bootstrap path.
#' @param ... Unused.
#'
#' @return A confidence-interval data frame with the shared `parm`, `level`,
#'   `lower`, `upper`, `scale`, `transformation`, `tmb_parameter`, `index`,
#'   `method`, and `conf.status` columns.
#' @export
confint.drmTMB_julia <- function(
  object,
  parm = NULL,
  level = 0.95,
  method = c("wald", "profile", "bootstrap"),
  R = 199L,
  seed = NULL,
  threads = FALSE,
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort(
      "Additional arguments in {.arg ...} are not used by Julia-engine confidence intervals yet."
    )
  }
  method <- validate_interval_method(
    method,
    c("wald", "profile", "bootstrap"),
    "confint()"
  )
  validate_profile_level(level)

  if (identical(method, "wald")) {
    return(drm_julia_wald_confint(object, parm = parm, level = level))
  }

  threads <- drm_julia_validate_threads(threads)
  seed <- drm_julia_validate_seed(seed)
  if (identical(method, "bootstrap")) {
    R <- validate_bootstrap_replicates(R)
  } else {
    R <- 1L
  }

  full_targets <- rbind(
    drm_julia_profile_targets(object),
    drm_julia_wald_targets(object)
  )
  # rbind()ing the SD inventory with the fixed-effect inventory means a
  # no-parm call now sees every row at once; profile_match_confint_targets()
  # returns them all unfiltered when parm is NULL, and
  # drm_julia_validate_inference_targets() correctly rejects that mixed set --
  # but its message is written for a WRONG target, not a MISSING one, so
  # catch the missing-parm case here with a message that says so plainly and
  # points at a real, fit-specific target.
  if (is.null(parm)) {
    cli::cli_abort(c(
      "Julia-engine {.code method = \"{method}\"} confidence intervals require an explicit {.arg parm} naming exactly one target.",
      i = drm_julia_inference_parm_hint(full_targets)
    ))
  }
  targets <- profile_match_confint_targets(full_targets, parm, fixed_only = FALSE)
  drm_julia_validate_inference_targets(targets)

  # Ordinary fixed-effect target (#460): a different Julia entry point than the
  # phylogenetic SD row, so it is dispatched separately here rather than inside
  # drm_julia_call_inference() / drm_julia_inference_confint_row(), which stay
  # exactly as they were for the SD target (no change to already-verified
  # numerics).
  if (identical(targets$target_class[[1L]], "fixed-effect")) {
    target <- targets[1L, , drop = FALSE]
    result <- drm_julia_call_fixef_inference(
      object = object,
      target = target,
      method = method,
      level = level,
      R = R,
      seed = seed,
      threads = threads
    )
    return(drm_julia_fixef_inference_confint_row(
      target = target,
      result = result,
      level = level,
      method = method
    ))
  }

  result <- drm_julia_call_inference(
    object = object,
    method = method,
    level = level,
    R = R,
    seed = seed,
    threads = threads
  )
  # Multi-row (bivariate) path: DRM.jl returns result$multi == TRUE with
  # equal-length vectors for param/estimate/lower/upper/etc. Map each Julia
  # param name ("sd_mu1", …) to the matching target row by dpar, then build
  # one confint row per axis and rbind them.
  if (isTRUE(as.logical(result$multi))) {
    return(drm_julia_inference_confint_multi(
      targets = targets,
      result = result,
      level = level,
      method = method
    ))
  }
  # Univariate path: single target row, scalar lower/upper.
  drm_julia_inference_confint_row(
    target = targets[1L, , drop = FALSE],
    result = result,
    level = level,
    method = method
  )
}

# Wald confidence intervals for the fixed-effect coefficients of a Julia-engine
# fit. The DRM.jl bridge already marshals the fixed-effect coefficient vector
# (`object$coef_vector`, on the link / linear-predictor scale) and the matching
# fixed-effect covariance block (`object$vcov`). This builds the same confint
# table the native Wald path returns, on the link scale, so a routed Poisson /
# NB2 / Gamma / Beta / Binomial / Gaussian phylo fit reports finite coefficient
# intervals wherever DRM.jl returned a finite covariance.
drm_julia_wald_confint <- function(object, parm = NULL, level = 0.95) {
  validate_profile_level(level)
  targets <- rbind(
    drm_julia_wald_targets(object),
    drm_julia_wald_scale_targets(object)
  )
  targets <- profile_match_confint_targets(targets, parm, fixed_only = FALSE)
  if (nrow(targets) == 0L) {
    return(empty_confint_table(method = "wald"))
  }

  V <- object$vcov
  z <- stats::qnorm((1 + level) / 2)
  variances <- rep(NA_real_, nrow(targets))
  if (is.matrix(V) && length(V) > 0L) {
    pos <- match(targets$tmb_parameter, rownames(V))
    in_cov <- !is.na(pos)
    variances[in_cov] <- V[cbind(pos[in_cov], pos[in_cov])]
  }
  se <- profile_wald_standard_errors(variances)
  interval_ready <- is.finite(targets$link_estimate) & is.finite(se)
  lower <- rep(NA_real_, nrow(targets))
  upper <- rep(NA_real_, nrow(targets))
  if (any(interval_ready)) {
    # profile_transform_interval() is the identity for every previously-
    # existing row here (transformation == "linear_predictor"); it only does
    # work (exp()) for the new distributional-scale row (#460 item 3), so this
    # generalization changes no existing Wald number.
    link_lower <- targets$link_estimate[interval_ready] - z * se[interval_ready]
    link_upper <- targets$link_estimate[interval_ready] + z * se[interval_ready]
    transformed <- mapply(
      function(lo, hi, row) {
        profile_transform_interval(c(lo, hi), targets[row, , drop = FALSE])
      },
      link_lower,
      link_upper,
      which(interval_ready),
      SIMPLIFY = FALSE
    )
    lower[interval_ready] <- vapply(transformed, `[[`, numeric(1L), 1L)
    upper[interval_ready] <- vapply(transformed, `[[`, numeric(1L), 2L)
  }

  out <- data.frame(
    parm = targets$parm,
    level = level,
    lower = lower,
    upper = upper,
    scale = targets$scale,
    transformation = targets$transformation,
    tmb_parameter = targets$tmb_parameter,
    index = targets$index,
    method = "wald",
    profile.engine = NA_character_,
    conf.status = ifelse(interval_ready, "wald", "wald_unavailable"),
    profile.boundary = NA,
    profile.message = NA_character_,
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

# Fixed-effect Wald targets for a Julia-engine fit. One row per fixed-effect
# coefficient, keyed by the bridge covariance name (`"<dpar>_<term>"`) so the
# variance can be read straight off `object$vcov`. `scale` / `transformation`
# match the native fixed-effect rows (link scale, identity transform).
#
# These rows also double as the profile / bootstrap inference targets (#460):
# `profile_ready` is TRUE whenever the fit carries a bridge payload (formula +
# data to refit from) -- the same precondition the phylogenetic SD target
# uses. The bivariate q=4 route is out of scope here (its inference target is
# the four among-axis SDs, not individual fixed-effect coefficients), so its
# fixed-effect rows stay not-ready.
drm_julia_wald_targets <- function(object) {
  blocks <- object$coefficients
  if (is.null(blocks) || length(blocks) == 0L) {
    return(empty_profile_targets())
  }
  is_biv <- identical(object$model$model_type, "biv_gaussian")
  fixef_profile_ready <- !is_biv && !is.null(object$bridge_payload)
  fixef_profile_note <- if (fixef_profile_ready) {
    "ready"
  } else if (is_biv) {
    "missing_tmb_parameter"
  } else {
    "julia_bridge_payload_required"
  }
  rows <- list()
  for (dpar in names(blocks)) {
    beta <- blocks[[dpar]]
    if (length(beta) == 0L) {
      next
    }
    terms <- names(beta)
    for (i in seq_along(beta)) {
      rows[[length(rows) + 1L]] <- new_profile_target_row(
        parm = paste0("fixef:", dpar, ":", terms[[i]]),
        target_class = "fixed-effect",
        dpar = dpar,
        term = terms[[i]],
        tmb_parameter = paste0(dpar, "_", terms[[i]]),
        index = i,
        estimate = unname(beta[[i]]),
        link_estimate = unname(beta[[i]]),
        scale = "link",
        transformation = "linear_predictor",
        target_type = "direct",
        profile_ready = fixef_profile_ready,
        profile_note = fixef_profile_note
      )
    }
  }
  if (length(rows) == 0L) {
    return(empty_profile_targets())
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  validate_profile_targets(out)
}

# Response-scale distributional-scale alias rows for the Wald table (#460
# item 3). Native drmTMB's confint() reports an extra `parm = "sigma"` /
# `"sigma1"` / `"sigma2"` response-scale row for any log-link dpar that has a
# single `(Intercept)` coefficient -- alongside the link-scale
# `fixef:sigma:(Intercept)` row -- the same underlying coefficient/covariance
# entry, reported on two scales (mirrors the `scale_dpars` block in
# `drm_profile_targets()`, R/profile.R). The Julia bridge's fixed-effect
# targets never included this alias, so the two engines' confint() tables
# differed in row count even for the shared Wald default on a Gaussian
# mean-only fit. Wald-only: not wired into the profile / bootstrap inventory,
# since it is a display alias of the fixef row rather than a distinct DRM.jl
# inference target.
drm_julia_wald_scale_targets <- function(object) {
  blocks <- object$coefficients
  scale_dpars <- intersect(names(blocks), c("sigma", "sigma1", "sigma2"))
  rows <- list()
  for (dpar in scale_dpars) {
    beta <- blocks[[dpar]]
    if (
      length(beta) == 1L &&
        identical(names(beta), "(Intercept)") &&
        identical(drm_dpar_link(object, dpar), "log")
    ) {
      rows[[length(rows) + 1L]] <- new_profile_target_row(
        parm = dpar,
        target_class = "distributional-scale",
        dpar = dpar,
        term = "(constant)",
        tmb_parameter = paste0(dpar, "_(Intercept)"),
        index = 1L,
        estimate = exp(unname(beta[[1L]])),
        link_estimate = unname(beta[[1L]]),
        scale = "response",
        transformation = "exp",
        target_type = "direct",
        profile_ready = FALSE,
        profile_note = "missing_tmb_parameter"
      )
    }
  }
  if (length(rows) == 0L) {
    return(empty_profile_targets())
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  validate_profile_targets(out)
}

drm_julia_validate_threads <- function(threads) {
  if (
    !is.logical(threads) ||
      length(threads) != 1L ||
      is.na(threads)
  ) {
    cli::cli_abort(
      "{.arg threads} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  isTRUE(threads)
}

drm_julia_validate_seed <- function(seed) {
  if (is.null(seed)) {
    return(NULL)
  }
  if (
    !is.numeric(seed) ||
      length(seed) != 1L ||
      is.na(seed) ||
      !is.finite(seed) ||
      seed != as.integer(seed)
  ) {
    cli::cli_abort("{.arg seed} must be {.code NULL} or one finite integer.")
  }
  as.integer(seed)
}

drm_julia_validate_inference_targets <- function(targets) {
  biv_dpars <- c("mu1", "mu2", "sigma1", "sigma2")

  # Bivariate case: exactly 4 rows, one per axis, all phylo RE-SDs.
  is_biv_targets <- nrow(targets) == 4L &&
    all(targets$target_class == "random-effect-sd") &&
    identical(sort(targets$dpar), sort(biv_dpars)) &&
    all(startsWith(targets$term, "phylo(")) &&
    all(startsWith(targets$tmb_parameter, "resd_"))
  if (is_biv_targets) {
    not_ready <- !targets$profile_ready
    if (any(not_ready)) {
      first_bad <- which(not_ready)[[1L]]
      cli::cli_abort(c(
        "Julia-engine bivariate target {.val {targets$parm[[first_bad]]}} is not ready for profile or bootstrap intervals.",
        i = "Inventory note: {.val {targets$profile_note[[first_bad]]}}."
      ))
    }
    return(invisible(NULL))
  }

  # Ordinary fixed-effect coefficient target (#460): one row, any dpar/term
  # (not the bivariate q = 4 route, which is out of scope for this target).
  is_fixef_target <- nrow(targets) == 1L &&
    identical(targets$target_class[[1L]], "fixed-effect")
  if (is_fixef_target) {
    if (!isTRUE(targets$profile_ready[[1L]])) {
      cli::cli_abort(c(
        "Julia-engine target {.val {targets$parm[[1L]]}} is not ready for profile or bootstrap intervals.",
        i = "Inventory note: {.val {targets$profile_note[[1L]]}}."
      ))
    }
    return(invisible(NULL))
  }

  # Univariate SD case: exactly 1 row, dpar == "mu", tmb_parameter == "resd".
  if (
    nrow(targets) != 1L ||
      !identical(targets$target_class[[1L]], "random-effect-sd") ||
      !identical(targets$dpar[[1L]], "mu") ||
      !startsWith(targets$term[[1L]], "phylo(") ||
      !identical(targets$tmb_parameter[[1L]], "resd")
  ) {
    cli::cli_abort(c(
      "Julia-engine profile and bootstrap intervals currently support one fixed-effect coefficient ({.code fixef:<dpar>:<coef>}), one Gaussian phylogenetic SD target (univariate), or all four axes (bivariate biv_gaussian).",
      i = "Use {.code parm = \"fixef:mu:x\"} for an ordinary fixed-effect coefficient, {.code parm = \"sd:mu:phylo(1 | species)\"} for the admitted univariate SD bridge slice, or one of {.code sd:mu1:*}, {.code sd:mu2:*}, {.code sd:sigma1:*}, or {.code sd:sigma2:*} for a bivariate q = 4 bridge fit."
    ))
  }
  if (!isTRUE(targets$profile_ready[[1L]])) {
    cli::cli_abort(c(
      "Julia-engine target {.val {targets$parm[[1L]]}} is not ready for profile or bootstrap intervals.",
      i = "Inventory note: {.val {targets$profile_note[[1L]]}}."
    ))
  }
}

# Build a fit-specific "here is a target you can actually use" hint for the
# no-parm profile/bootstrap error (#460 defect A). `targets` is the FULL,
# unfiltered inventory (SD rows rbind()ed with fixed-effect rows).
drm_julia_inference_parm_hint <- function(targets) {
  ready <- targets[targets$profile_ready, , drop = FALSE]
  biv_dpars <- c("mu1", "mu2", "sigma1", "sigma2")
  is_biv_targets <- nrow(ready) == 4L &&
    all(ready$target_class == "random-effect-sd") &&
    identical(sort(ready$dpar), sort(biv_dpars))
  if (is_biv_targets) {
    ordered <- ready[match(biv_dpars, ready$dpar), , drop = FALSE]
    quoted <- paste0("\"", ordered$parm, "\"", collapse = ", ")
    return(paste0(
      "This bivariate q = 4 fit needs all four axis names at once, e.g. ",
      "{.code parm = c(", quoted, ")}."
    ))
  }
  if (nrow(ready) == 0L) {
    return(
      "No target on this fit is currently profile/bootstrap-ready; see the fixed-effect and SD rows in the inventory for why."
    )
  }
  # Prefer an ordinary fixed effect as the example -- it is available on
  # every non-bivariate Julia fit with a stored bridge payload -- else fall
  # back to whichever SD target is ready.
  fixef_rows <- ready[ready$target_class == "fixed-effect", , drop = FALSE]
  example <- if (nrow(fixef_rows) > 0L) {
    fixef_rows$parm[[1L]]
  } else {
    ready$parm[[1L]]
  }
  paste0("Use {.code parm = \"", example, "\"}, for example.")
}

drm_julia_inference_confint_row <- function(target, result, level, method) {
  result <- as.list(result)
  scale <- target$estimate[[1L]] / exp(target$link_estimate[[1L]])
  interval <- exp(c(
    as.numeric(result$lower),
    as.numeric(result$upper)
  )) *
    scale
  diagnostics <- profile_interval_diagnostics(
    interval,
    transformation = target$transformation[[1L]]
  )
  out <- data.frame(
    parm = target$parm,
    level = level,
    lower = interval[[1L]],
    upper = interval[[2L]],
    scale = target$scale,
    transformation = target$transformation,
    tmb_parameter = target$tmb_parameter,
    index = target$index,
    method = method,
    profile.engine = if (identical(method, "profile")) {
      "julia_profile_result"
    } else {
      NA_character_
    },
    conf.status = as.character(result$status),
    profile.boundary = diagnostics$boundary,
    profile.message = if (nzchar(as.character(result$message))) {
      as.character(result$message)
    } else {
      diagnostics$message
    },
    julia.threaded = isTRUE(result$threaded),
    julia.workers = as.integer(result$worker_threads),
    julia.threads = as.integer(result$julia_threads),
    julia.blas_threads = as.integer(result$blas_threads),
    julia.elapsed = as.numeric(result$elapsed),
    stringsAsFactors = FALSE
  )
  if (identical(method, "bootstrap")) {
    out$bootstrap.n <- as.integer(result$used)
    out$bootstrap.failed <- as.integer(result$failed)
    out$bootstrap.parallel <- if (isTRUE(result$threaded)) {
      "julia_threads"
    } else {
      "none"
    }
    out$bootstrap.workers <- as.integer(result$worker_threads)
  }
  row.names(out) <- NULL
  out
}

# Confidence-interval row for an ordinary fixed-effect profile / bootstrap
# target (#460). Unlike the phylogenetic SD target, DRM.jl's fixed-effect
# profile_result() / bootstrap_result() rows are already on the coefficient's
# own linear-predictor (link) scale -- no exp() transform, no tree-height
# rescale -- so this mirrors drm_julia_inference_confint_row() but drops that
# SD-specific step.
drm_julia_fixef_inference_confint_row <- function(target, result, level, method) {
  result <- as.list(result)
  interval <- c(as.numeric(result$lower), as.numeric(result$upper))
  diagnostics <- profile_interval_diagnostics(
    interval,
    transformation = target$transformation[[1L]]
  )
  out <- data.frame(
    parm = target$parm,
    level = level,
    lower = interval[[1L]],
    upper = interval[[2L]],
    scale = target$scale,
    transformation = target$transformation,
    tmb_parameter = target$tmb_parameter,
    index = target$index,
    method = method,
    profile.engine = if (identical(method, "profile")) {
      "julia_profile_result"
    } else {
      NA_character_
    },
    conf.status = as.character(result$status),
    profile.boundary = diagnostics$boundary,
    profile.message = if (nzchar(as.character(result$message))) {
      as.character(result$message)
    } else {
      diagnostics$message
    },
    julia.threaded = isTRUE(result$threaded),
    julia.workers = as.integer(result$worker_threads),
    julia.threads = as.integer(result$julia_threads),
    julia.blas_threads = as.integer(result$blas_threads),
    julia.elapsed = as.numeric(result$elapsed),
    stringsAsFactors = FALSE
  )
  if (identical(method, "bootstrap")) {
    out$bootstrap.n <- as.integer(result$used)
    out$bootstrap.failed <- as.integer(result$failed)
    out$bootstrap.parallel <- if (isTRUE(result$threaded)) {
      "julia_threads"
    } else {
      "none"
    }
    out$bootstrap.workers <- as.integer(result$worker_threads)
  }
  row.names(out) <- NULL
  out
}

# Bivariate multi-row confint builder.
#
# DRM.jl returns a multi-row payload (result$multi == TRUE) with equal-length
# vectors: param ("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2"), lower, upper,
# estimate, std_error (NaN for profile), bounded (profile only), status,
# message, elapsed (scalar). We join by dpar: "sd_mu1" -> dpar "mu1", etc.
# `upper` may be Inf on a flat/collapsed axis  -  left as-is, never coerced to NA.
# `std_error` may be NaN for profile  -  ignored (only lower/upper matter).
drm_julia_inference_confint_multi <- function(targets, result, level, method) {
  result <- as.list(result)

  # Julia returns param names like "sd_mu1"; strip leading "sd_" to get dpar.
  julia_params <- as.character(unlist(result$param, use.names = FALSE))
  julia_dpar <- sub("^sd_", "", julia_params)
  julia_lower <- as.numeric(unlist(result$lower, use.names = FALSE))
  julia_upper <- as.numeric(unlist(result$upper, use.names = FALSE))
  julia_estimate <- as.numeric(unlist(result$estimate, use.names = FALSE))
  julia_status <- as.character(unlist(result$status, use.names = FALSE))
  julia_message <- as.character(unlist(result$message, use.names = FALSE))
  # bounded is profile-only; may be absent for bootstrap.
  julia_bounded <- if (!is.null(result$bounded)) {
    as.logical(unlist(result$bounded, use.names = FALSE))
  } else {
    rep(TRUE, length(julia_params))
  }

  # Scalar diagnostics (elapsed, thread counts) come from the top-level result.
  # NULL-safe scalars: the profile payload omits the bootstrap/threading fields, so
  # as.integer(NULL) would give a length-0 column and break data.frame() ("1, 0 rows").
  .int1 <- function(v) {
    if (is.null(v) || length(v) == 0L) NA_integer_ else as.integer(v)[[1L]]
  }
  .num1 <- function(v) {
    if (is.null(v) || length(v) == 0L) NA_real_ else as.numeric(v)[[1L]]
  }
  elapsed <- .num1(result$elapsed)
  threaded <- isTRUE(result$threaded)
  worker_threads <- .int1(result$worker_threads)
  julia_threads <- .int1(result$julia_threads)
  blas_threads <- .int1(result$blas_threads)
  bootstrap_used <- .int1(result$used)
  bootstrap_failed <- .int1(result$failed)

  rows <- vector("list", nrow(targets))
  for (i in seq_len(nrow(targets))) {
    target <- targets[i, , drop = FALSE]
    dpar_i <- target$dpar[[1L]]
    # Match target dpar to Julia param ("mu1" -> "sd_mu1").
    ji <- match(dpar_i, julia_dpar)
    if (is.na(ji)) {
      cli::cli_abort(c(
        "Bivariate confint: DRM.jl result has no entry for axis {.val {dpar_i}}.",
        i = "Julia returned params: {.val {julia_params}}."
      ))
    }
    # DRM.jl returns the among-axis SD bounds ALREADY on the SD scale (no exp()  - 
    # that is the univariate log-SD convention), but on the RAW-Q scale (Q built
    # from raw branch lengths). To keep the CI on the same native (unit-height)
    # scale as the rescaled point estimate, multiply the bounds by the per-axis
    # sd_scale, recovered as estimate / exp(link_estimate) exactly as the
    # univariate drm_julia_inference_confint_row does (#693). `upper` may be Inf
    # on a flat/collapsed axis; Inf * scale stays Inf (never coerced to NA).
    axis_scale <- target$estimate[[1L]] / exp(target$link_estimate[[1L]])
    if (!is.finite(axis_scale) || axis_scale <= 0) {
      axis_scale <- 1
    }
    lo <- julia_lower[[ji]] * axis_scale
    hi <- julia_upper[[ji]] * axis_scale
    is_bounded <- isTRUE(julia_bounded[[ji]])
    # status/message are SCALAR for the whole call (one profile/bootstrap run), so
    # recycle them across axes rather than indexing per-axis.
    status_i <- if (length(julia_status) >= ji) {
      julia_status[[ji]]
    } else if (length(julia_status) >= 1L) {
      julia_status[[1L]]
    } else {
      NA_character_
    }
    message_i <- if (length(julia_message) >= ji) {
      julia_message[[ji]]
    } else if (length(julia_message) >= 1L) {
      julia_message[[1L]]
    } else {
      ""
    }
    diagnostics <- if (all(is.finite(c(lo, hi)))) {
      profile_interval_diagnostics(
        c(lo, hi),
        transformation = target$transformation[[1L]]
      )
    } else {
      list(
        boundary = TRUE,
        message = "upper bound unbounded (flat / collapsed axis)"
      )
    }
    row_i <- data.frame(
      parm = target$parm,
      level = level,
      lower = lo,
      upper = hi,
      scale = target$scale,
      transformation = target$transformation,
      tmb_parameter = target$tmb_parameter,
      index = target$index,
      method = method,
      profile.engine = if (identical(method, "profile")) {
        "julia_profile_result"
      } else {
        NA_character_
      },
      conf.status = status_i,
      profile.boundary = if (identical(method, "profile")) {
        !is_bounded
      } else {
        diagnostics$boundary
      },
      profile.message = if (nzchar(message_i)) {
        message_i
      } else {
        diagnostics$message
      },
      julia.threaded = threaded,
      julia.workers = worker_threads,
      julia.threads = julia_threads,
      julia.blas_threads = blas_threads,
      julia.elapsed = elapsed,
      stringsAsFactors = FALSE
    )
    if (identical(method, "bootstrap")) {
      row_i$bootstrap.n <- bootstrap_used
      row_i$bootstrap.failed <- bootstrap_failed
      row_i$bootstrap.parallel <- if (threaded) "julia_threads" else "none"
      row_i$bootstrap.workers <- worker_threads
    }
    rows[[i]] <- row_i
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

#' Summarise a legacy Julia-bridge `drmTMB` fit
#'
#' The Julia bridge is halted/deferred future work. This compatibility method
#' inspects an existing `drmTMB_julia` object; it does not make Julia a current
#' fitting or inference option. For new analyses, use native TMB fits.
#'
#' Builds a fixed-effect coefficient table (estimate, standard error, z value,
#' and two-sided p value, all on the linear-predictor / link scale) from the
#' coefficients and fixed-effect covariance DRM.jl marshals back through the
#' bridge. Standard errors are the square roots of the diagonal of
#' `vcov(object)`; when DRM.jl did not return a finite covariance for a route
#' the SE / z / p columns are `NA` and `uncertainty$status` records why. The
#' random-effect SD block (e.g. a phylogenetic SD) is reported on its positive
#' response scale.
#'
#' Set `conf.int = TRUE` to append Wald (default) or profile confidence-interval
#' columns. Profile / bootstrap intervals are available only for the Gaussian
#' phylogenetic SD target; see [confint.drmTMB_julia()].
#'
#' @param object A `drmTMB_julia` fit.
#' @param conf.int Logical; append confidence-interval columns.
#' @param level Confidence level for the interval columns.
#' @param method `"wald"` (default) or `"profile"`; only used when
#'   `conf.int = TRUE`.
#' @param ... Unused.
#'
#' @return An object of class `summary.drmTMB_julia` with `coefficients`,
#'   `random` (random-effect SDs), and fit-summary scalars.
#' @export
summary.drmTMB_julia <- function(
  object,
  conf.int = FALSE,
  level = 0.95,
  method = c("wald", "profile"),
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort(
      "Additional arguments in {.arg ...} are not used by the Julia-engine summary yet."
    )
  }
  if (!is.logical(conf.int) || length(conf.int) != 1L || is.na(conf.int)) {
    cli::cli_abort(
      "{.arg conf.int} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  validate_profile_level(level)
  method <- validate_interval_method(method, c("wald", "profile"), "summary()")

  coefficients <- drm_julia_summary_coefficients(object)
  if (conf.int && nrow(coefficients) > 0L) {
    ci <- if (identical(method, "wald")) {
      drm_julia_wald_confint(object, parm = NULL, level = level)
    } else {
      tryCatch(
        confint.drmTMB_julia(
          object,
          parm = NULL,
          level = level,
          method = method
        ),
        error = function(e) NULL
      )
    }
    coefficients <- drm_julia_summary_attach_ci(coefficients, ci, level)
  }

  out <- list(
    call = object$call,
    family = object$family,
    engine = "julia",
    coefficients = coefficients,
    random = drm_julia_summary_random(object),
    sigma = object$sigma,
    logLik = object$logLik,
    aic = object$aic,
    bic = object$bic,
    df = object$df,
    nobs = object$nobs,
    converged = isTRUE(object$opt$convergence == 0L),
    uncertainty = object$uncertainty
  )
  class(out) <- "summary.drmTMB_julia"
  out
}

# Fixed-effect coefficient table (link scale) for the Julia-engine summary.
drm_julia_summary_coefficients <- function(object) {
  beta <- object$coef_vector
  if (is.null(beta) || length(beta) == 0L) {
    return(data.frame(
      dpar = character(),
      term = character(),
      estimate = numeric(),
      std.error = numeric(),
      statistic = numeric(),
      p.value = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  nm <- names(beta)
  V <- object$vcov
  se <- rep(NA_real_, length(beta))
  if (is.matrix(V) && length(V) > 0L) {
    pos <- match(nm, rownames(V))
    in_cov <- !is.na(pos)
    variances <- rep(NA_real_, length(beta))
    variances[in_cov] <- V[cbind(pos[in_cov], pos[in_cov])]
    se <- profile_wald_standard_errors(variances)
  }
  estimate <- unname(beta)
  statistic <- estimate / se
  p.value <- 2 * stats::pnorm(-abs(statistic))
  data.frame(
    dpar = sub("_.*$", "", nm),
    term = sub("^[^_]+_", "", nm),
    estimate = estimate,
    std.error = se,
    statistic = statistic,
    p.value = p.value,
    stringsAsFactors = FALSE
  )
}

# Append lower / upper interval columns from a confint table onto the
# coefficient table, matching on the `fixef:<dpar>:<term>` key.
drm_julia_summary_attach_ci <- function(coefficients, ci, level) {
  coefficients$conf.low <- NA_real_
  coefficients$conf.high <- NA_real_
  coefficients$conf.level <- level
  if (is.null(ci) || nrow(ci) == 0L) {
    return(coefficients)
  }
  key <- paste0("fixef:", coefficients$dpar, ":", coefficients$term)
  idx <- match(key, ci$parm)
  found <- !is.na(idx)
  coefficients$conf.low[found] <- ci$lower[idx[found]]
  coefficients$conf.high[found] <- ci$upper[idx[found]]
  coefficients
}

# Random-effect SD block (response scale) for the Julia-engine summary.
drm_julia_summary_random <- function(object) {
  sdpars <- object$sdpars
  if (is.null(sdpars)) {
    return(data.frame(
      dpar = character(),
      term = character(),
      sd = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  rows <- list()
  for (dpar in names(sdpars)) {
    values <- sdpars[[dpar]]
    if (is.null(values) || length(values) == 0L) {
      next
    }
    rows[[length(rows) + 1L]] <- data.frame(
      dpar = dpar,
      term = names(values),
      sd = unname(values),
      stringsAsFactors = FALSE
    )
  }
  if (length(rows) == 0L) {
    return(data.frame(
      dpar = character(),
      term = character(),
      sd = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

#' @export
print.summary.drmTMB_julia <- function(x, ...) {
  cli::cli_text("<drmTMB Julia-engine fit summary>")
  cli::cli_text("  observations: {x$nobs}")
  cli::cli_text("  logLik: {format(x$logLik, digits = 4)}")
  cli::cli_text(
    "  convergence: {if (isTRUE(x$converged)) 'converged' else 'not converged'}"
  )
  if (!is.null(x$uncertainty) && !is.null(x$uncertainty$status)) {
    cli::cli_text("  uncertainty: {x$uncertainty$status}")
  }
  cli::cli_text("")
  cli::cli_text("Fixed effects (link scale):")
  print(x$coefficients, row.names = FALSE)
  if (!is.null(x$random) && nrow(x$random) > 0L) {
    cli::cli_text("")
    cli::cli_text("Random effects (SD, response scale):")
    print(x$random, row.names = FALSE)
  }
  invisible(x)
}

#' @export
logLik.drmTMB_julia <- function(object, ...) {
  out <- object$logLik
  attr(out, "df") <- object$df
  attr(out, "nobs") <- object$nobs
  class(out) <- "logLik"
  out
}

#' @export
nobs.drmTMB_julia <- function(object, ...) {
  object$nobs
}

#' @export
df.residual.drmTMB_julia <- function(object, ...) {
  object$nobs - object$df
}

#' @export
deviance.drmTMB_julia <- function(object, ...) {
  -2 * as.numeric(stats::logLik(object))
}

#' @export
fitted.drmTMB_julia <- function(object, ...) {
  object$fitted
}

#' @export
residuals.drmTMB_julia <- function(object, type = c("response"), ...) {
  match.arg(type)
  object$residuals
}

#' @export
sigma.drmTMB_julia <- function(object, ...) {
  object$sigma
}

# Raw residual rho12 vector as returned by the bridge (per-observation
# `tanh(Xrho . beta_rho)`; constant when `rho12 ~ 1`). This backs `rho12()` and
# `predict(dpar = "rho12")`; it is NOT the public `corpairs()` table. Returns a
# zero-length numeric for fits with no residual correlation block.
drm_julia_rho12_values <- function(object) {
  rho <- object$corpairs
  if (is.null(rho) || (is.list(rho) && length(rho) == 0L)) {
    return(numeric())
  }
  as.numeric(rho)
}

#' @export
corpairs.drmTMB_julia <- function(
  object,
  level = NULL,
  group = NULL,
  block = NULL,
  class = NULL,
  ...
) {
  rows <- list()

  rho <- drm_julia_rho12_values(object)
  if (length(rho) > 0L) {
    rows[[length(rows) + 1L]] <- drm_julia_residual_rho12_corpair(object, rho)
  }

  phylo_rows <- drm_julia_phylo_corpairs(object)
  if (length(phylo_rows) > 0L) {
    rows <- c(rows, phylo_rows)
  }

  out <- if (length(rows) == 0L) {
    empty_corpairs()
  } else {
    do.call(rbind, rows)
  }

  if (!is.null(level)) {
    out <- out[out$level %in% level, , drop = FALSE]
  }
  if (!is.null(group)) {
    out <- out[out$group %in% group, , drop = FALSE]
  }
  if (!is.null(block)) {
    out <- out[out$block %in% block, , drop = FALSE]
  }
  if (!is.null(class)) {
    class <- normalize_corpairs_class_filter(class)
    out <- out[out$class %in% class, , drop = FALSE]
  }
  row.names(out) <- NULL
  corpairs_add_default_interval_provenance(out)
}

# Response names (e.g. "y1" / "y2") carried by the bridge formula entries, used
# to label corpairs rows. Falls back to "y1" / "y2" if an entry is missing.
drm_julia_response_names <- function(object) {
  responses <- stats::setNames(rep(NA_character_, 2L), c("mu1", "mu2"))
  entries <- object$formula$entries
  if (!is.null(entries)) {
    for (entry in entries) {
      if (
        !is.null(entry$dpar) &&
          entry$dpar %in% names(responses) &&
          is.character(entry$response) &&
          length(entry$response) == 1L &&
          !is.na(entry$response)
      ) {
        responses[[entry$dpar]] <- entry$response
      }
    }
  }
  if (is.na(responses[["mu1"]])) {
    responses[["mu1"]] <- "y1"
  }
  if (is.na(responses[["mu2"]])) {
    responses[["mu2"]] <- "y2"
  }
  responses
}

drm_julia_response_for_dpar <- function(responses, dpar) {
  if (dpar %in% c("mu1", "sigma1")) {
    return(unname(responses[["mu1"]]))
  }
  if (dpar %in% c("mu2", "sigma2")) {
    return(unname(responses[["mu2"]]))
  }
  NA_character_
}

# Residual between-response correlation as a one-row corpairs table, mirroring
# `residual_rho12_corpair()` on the native path but reading the raw per-row rho12
# vector the bridge already returns.
drm_julia_residual_rho12_corpair <- function(object, rho) {
  responses <- drm_julia_response_names(object)
  n_coef <- length(object$coefficients[["rho12"]])
  eta <- atanh(pmax(pmin(rho, 1 - 1e-12), -1 + 1e-12))
  new_corpair_row(
    level = "residual",
    group = NA_character_,
    block = NA_character_,
    from_dpar = "residual",
    to_dpar = "residual",
    from_coef = NA_character_,
    to_coef = NA_character_,
    from_response = unname(responses[["mu1"]]),
    to_response = unname(responses[["mu2"]]),
    class = "residual",
    parameter = "rho12",
    estimate = mean(rho),
    min = min(rho),
    max = max(rho),
    n_values = length(rho),
    link_estimate = mean(eta),
    link_min = min(eta),
    link_max = max(eta),
    modelled = n_coef > 1L
  )
}

# Among-axis structured correlations for q2/q4 bivariate bridge fits. The
# shared structured axes carry a 2x2 or 4x4 group-level covariance Sigma_a,
# stored on the fit by the bridge as the 3 or 10
# log-Cholesky entries `phylocov$"Sigma_a:Lij"` (diagonal on the log scale,
# off-diagonals raw; Sigma_a = L L'). This reconstructs Sigma_a, converts it to
# the among-axis correlation matrix, and emits one corpairs row per cross-axis
# pair -- the interpretable coevolution correlations (mean1-mean2 etc.) that the
# native `corpairs.drmTMB` surfaces for phylo / relmat / animal q2 and q4
# blocks. The bridge never populates `object$corpars`, so this rebuilds the rows
# directly from Sigma_a. Returns an empty list for any non-q2/q4 fit.
drm_julia_phylo_corpairs <- function(object) {
  Sigma_a <- drm_julia_phylocov_matrix(object)
  if (is.null(Sigma_a)) {
    return(list())
  }
  info <- drm_julia_phylo_block_info(object)
  if (is.null(info)) {
    return(list())
  }
  axes <- if (nrow(Sigma_a) == 2L) {
    c("mu1", "mu2")
  } else {
    c("mu1", "mu2", "sigma1", "sigma2")
  }
  responses <- drm_julia_response_names(object)

  d <- sqrt(diag(Sigma_a))
  if (any(!is.finite(d)) || any(d <= 0)) {
    return(list())
  }
  R <- Sigma_a / outer(d, d)

  pair_index <- utils::combn(seq_along(axes), 2L)
  lapply(seq_len(ncol(pair_index)), function(k) {
    i <- pair_index[1L, k]
    j <- pair_index[2L, k]
    from_dpar <- axes[[i]]
    to_dpar <- axes[[j]]
    estimate <- R[i, j]
    new_corpair_row(
      level = info$level,
      group = info$group,
      block = info$block,
      from_dpar = from_dpar,
      to_dpar = to_dpar,
      from_coef = "(Intercept)",
      to_coef = "(Intercept)",
      from_response = drm_julia_response_for_dpar(responses, from_dpar),
      to_response = drm_julia_response_for_dpar(responses, to_dpar),
      class = random_correlation_class(
        from_dpar,
        "(Intercept)",
        "(Intercept)",
        to_dpar = to_dpar
      ),
      parameter = format_cross_dpar_cor_label(
        from_dpar,
        to_dpar,
        group = info$group,
        covariance_label = info$block
      ),
      estimate = estimate,
      min = estimate,
      max = estimate,
      n_values = 1L,
      link_estimate = guarded_correlation_link(estimate, guard = 0.999999),
      link_min = guarded_correlation_link(estimate, guard = 0.999999),
      link_max = guarded_correlation_link(estimate, guard = 0.999999),
      modelled = FALSE
    )
  })
}

# Reconstruct the q2/q4 among-axis covariance Sigma_a from the bridge's stored
# log-Cholesky factor, or NULL if this fit has no supported `phylocov` block. The
# entries are named "Sigma_a:L11", "Sigma_a:L21", ...; the diagonal is
# exponentiated (working scale), off-diagonals are taken as-is.
drm_julia_phylocov_matrix <- function(object) {
  if (!identical(object$model$model_type, "biv_gaussian")) {
    return(NULL)
  }
  # Read from the dedicated `phylocov` slot (live fits, #692); fall back to the
  # legacy `coefficients[["phylocov"]]` block for synthetic fixtures that still
  # construct fits that way.
  phylocov <- object$phylocov
  if (is.null(phylocov)) {
    phylocov <- object$coefficients[["phylocov"]]
  }
  if (is.null(phylocov)) {
    return(NULL)
  }
  q <- if (length(phylocov) == 3L) {
    2L
  } else if (length(phylocov) == 10L) {
    4L
  } else {
    return(NULL)
  }
  L <- matrix(0, q, q)
  for (col in seq_len(q)) {
    for (rw in col:q) {
      nm <- sprintf("Sigma_a:L%d%d", rw, col)
      value <- phylocov[[nm]]
      if (is.null(value) || !is.finite(value)) {
        return(NULL)
      }
      L[rw, col] <- if (rw == col) exp(value) else value
    }
  }
  L %*% t(L)
}

# Shared level, group, and covariance-block labels for q2/q4 structured
# bivariate blocks, read off the fit's formula terms. The bridge guards
# guarantee that all axes share one grouping factor and block, so the first term
# is representative. `block` is the explicit covariance label (e.g. "p"); NA
# when the term was written without one. Returns NULL if no supported structured
# term is present.
drm_julia_phylo_block_info <- function(object) {
  entries <- object$formula$entries
  if (is.null(entries)) {
    return(NULL)
  }
  for (entry in entries) {
    for (term in entry$structured) {
      if (term$type %in% c("phylo", "relmat", "animal", "spatial")) {
        block <- term$covariance_label
        if (is.null(block) || !nzchar(block)) {
          block <- NA_character_
        }
        level <- if (identical(term$type, "phylo")) {
          "phylogenetic"
        } else {
          term$type
        }
        return(list(level = level, group = term$group, block = block))
      }
    }
  }
  NULL
}

#' @export
rho12.drmTMB_julia <- function(object, ...) {
  rho <- drm_julia_rho12_values(object)
  if (length(rho) == 0L) {
    cli::cli_abort("This Julia-engine fit has no residual {.code rho12}.")
  }
  rho
}

#' @export
is_converged.drmTMB_julia <- function(object, include_hessian = FALSE, ...) {
  isTRUE(object$opt$convergence == 0L)
}

# Locate the formula entry that supplies a distributional parameter's mean
# sub-model (`mu` / `mu1` / `mu2`). The fixed-effect coefficient vector and the
# entry's right-hand side together describe the linear predictor, so this is the
# anchor for a newdata prediction. Errors if the parameter has no entry.
drm_julia_predict_entry <- function(object, dpar) {
  entries <- object$formula$entries
  for (entry in entries) {
    if (identical(entry$dpar, dpar)) {
      return(entry)
    }
  }
  cli::cli_abort(
    "{.fn predict} could not find a {.code {dpar}} formula entry on this Julia-engine fit."
  )
}

# Build the mean-model design matrix for `newdata`, reconstructing the model
# terms from the fit's TRAINING data so factor contrasts and column ordering
# match the fitted coefficients. Structured (phylo / spatial) terms are
# group-level and contribute nothing to the population-level linear predictor;
# they are dropped from the right-hand side before the design is built, so the
# returned columns are exactly the fixed-effect regressors named in
# `object$coefficients[[dpar]]`. Random effects are held at zero (population
# level) -- a newdata row need not belong to any fitted group.
drm_julia_predict_design <- function(object, entry, newdata) {
  rhs <- drm_strip_structured_terms(entry$rhs)
  train <- object$data
  if (is.null(train)) {
    cli::cli_abort(
      "{.fn predict} with {.arg newdata} needs the original {.arg data}; this Julia-engine fit did not store it."
    )
  }
  fixed_formula <- stats::reformulate(deparse1(rhs))
  train_terms <- stats::terms(
    stats::model.frame(fixed_formula, data = train)
  )
  xlev <- stats::.getXlevels(
    train_terms,
    stats::model.frame(train_terms, train)
  )
  newdata_frame <- stats::model.frame(
    train_terms,
    data = newdata,
    na.action = stats::na.pass,
    xlev = xlev
  )
  stats::model.matrix(train_terms, newdata_frame, xlev = xlev)
}

# Drop phylo() / spatial() / relmat() / animal() structured markers from a
# right-hand side, leaving only the population-level fixed-effect terms. Returns
# the intercept (`1`) when nothing else remains.
drm_strip_structured_terms <- function(rhs) {
  labels <- attr(stats::terms(stats::reformulate(deparse1(rhs))), "term.labels")
  markers <- c("phylo", "spatial", "relmat", "animal")
  is_structured <- vapply(
    labels,
    function(lab) {
      parsed <- tryCatch(str2lang(lab), error = function(e) NULL)
      is.call(parsed) &&
        is.name(parsed[[1L]]) &&
        as.character(parsed[[1L]]) %in% markers
    },
    logical(1L)
  )
  kept <- labels[!is_structured]
  if (length(kept) == 0L) {
    return(quote(1))
  }
  stats::reformulate(kept)[[2L]]
}

# Inverse-link for the mean of a location parameter, used by `type = "response"`.
# A univariate fit carries the link the linear predictor lives on directly in
# `object$family$linkinv`. A cross-family fit stores a per-axis family TAG in
# `object$families`, so the mu1 / mu2 inverse link is looked up from that tag.
drm_julia_predict_linkinv <- function(object, dpar) {
  if (dpar %in% c("mu1", "mu2") && !is.null(object$families)) {
    tag <- object$families[[if (identical(dpar, "mu1")) 1L else 2L]]
    return(drm_julia_tag_linkinv(tag))
  }
  fam <- object$family
  if (is.list(fam) && is.function(fam$linkinv)) {
    return(fam$linkinv)
  }
  cli::cli_abort(
    "{.fn predict} could not resolve an inverse link for {.code {dpar}} on this Julia-engine fit; use {.code type = \"link\"}."
  )
}

# Mean inverse-link for a DRM.jl cross-family axis tag. Mirrors the links the
# bridge enforces for each family (see `drm_julia_xfam_family_tag`).
drm_julia_tag_linkinv <- function(tag) {
  switch(
    tag,
    gaussian = stats::gaussian()$linkinv,
    poisson = stats::poisson()$linkinv,
    nbinom2 = stats::poisson()$linkinv,
    gamma = stats::poisson()$linkinv,
    binomial = stats::binomial()$linkinv,
    beta = stats::binomial()$linkinv,
    cli::cli_abort(
      "{.fn predict} has no response-scale inverse link for cross-family axis {.val {tag}} yet; use {.code type = \"link\"}."
    )
  )
}

#' Predict from a legacy Julia-bridge `drmTMB` fit
#'
#' The Julia bridge is halted/deferred future work. This compatibility method
#' is for inspecting an existing `drmTMB_julia` object, not for a new Julia
#' analysis. Use native TMB fits for new prediction work.
#'
#' With `newdata = NULL`, `predict()` returns the stored fitted values for the
#' requested distributional parameter. With `newdata` supplied, it returns a
#' **population-level, fixed-effect** prediction for the location parameter
#' (`mu` / `mu1` / `mu2`): the linear predictor `X %*% beta` built from the
#' fit's fixed-effect coefficients and a design matrix constructed from
#' `newdata` using the training-data model terms. Group-level random effects
#' (phylogenetic / spatial / study) are held at **zero** -- a `newdata` row need
#' not belong to any fitted group -- so the result is the marginal mean at the
#' population level, matching the native [predict.drmTMB()] contract for
#' `newdata`. `type = "link"` returns the linear predictor; `type = "response"`
#' applies the model's inverse link.
#'
#' Predicting `sigma` / `rho12` for fresh `newdata` is not implemented; refit
#' with `engine = "tmb"` for those.
#'
#' A legacy cross-family object (`drmTMB_julia_xfam`) is narrower still: only
#' `mu1` and `mu2` are available. Stored and new-data predictions are response
#' means with the shared latent effect fixed at `u = 0`; they are not marginal
#' means. Cross-family covariance, fixed-effect Wald inference, and scale-axis
#' prediction are unavailable because that legacy bridge did not retain the
#' required payload.
#'
#' @param object A `drmTMB_julia` fit.
#' @param newdata Optional data frame. When supplied, predictions are
#'   population-level (random effects set to zero).
#' @param dpar Distributional parameter to predict. Defaults to the first
#'   (`mu`). With `newdata`, must be a location parameter (`mu` / `mu1` /
#'   `mu2`).
#' @param type `"response"` (default) or `"link"`.
#' @param ... Reserved.
#'
#' @return A numeric vector of predictions, length `nrow(newdata)` when
#'   `newdata` is supplied.
#' @export
predict.drmTMB_julia <- function(
  object,
  newdata = NULL,
  dpar = NULL,
  type = c("response", "link"),
  ...
) {
  type <- match.arg(type)
  if (is.null(dpar)) {
    dpar <- names(object$coefficients)[[1L]]
  }
  dpar <- match.arg(dpar, names(object$coefficients))

  if (!is.null(newdata)) {
    if (!dpar %in% c("mu", "mu1", "mu2")) {
      cli::cli_abort(c(
        "{.fn predict} with {.arg newdata} for {.code engine = \"julia\"} supports only the location parameter ({.code mu} / {.code mu1} / {.code mu2}).",
        i = "Refit with {.code engine = \"tmb\"} to predict {.code {dpar}} on fresh {.arg newdata}."
      ))
    }
    entry <- drm_julia_predict_entry(object, dpar)
    X <- drm_julia_predict_design(object, entry, newdata)
    beta <- object$coefficients[[dpar]]
    common <- intersect(colnames(X), names(beta))
    if (length(common) != length(beta) || length(common) != ncol(X)) {
      cli::cli_abort(c(
        "{.fn predict} could not align the {.arg newdata} design with the fitted {.code {dpar}} coefficients.",
        i = "{.arg newdata} must use the same predictors as the fitted model."
      ))
    }
    eta <- as.numeric(X[, common, drop = FALSE] %*% beta[common])
    if (identical(type, "link")) {
      return(eta)
    }
    linkinv <- drm_julia_predict_linkinv(object, dpar)
    return(linkinv(eta))
  }

  if (dpar %in% c("mu", "mu1", "mu2")) {
    if (is.list(object$fitted)) {
      return(object$fitted[[dpar]])
    }
    return(object$fitted)
  }
  if (dpar %in% c("sigma", "sigma1", "sigma2")) {
    if (is.list(object$sigma)) {
      return(object$sigma[[dpar]])
    }
    return(object$sigma)
  }
  if (identical(dpar, "rho12")) {
    return(rho12.drmTMB_julia(object))
  }
  cli::cli_abort(
    "{.fn predict} for {.code engine = \"julia\"} has no stored response-scale values for {.arg dpar = \"{dpar}\"} yet."
  )
}

# ---------------------------------------------------------------------------
# Univariate structured (general-covariance) route via engine = "julia".
#
# Routes a univariate `relmat(1 | g)` / `animal(1 | g)` / `spatial(1 | g)` mean
# random intercept to DRM.jl's general-covariance sparse Laplace. Unlike the
# phylo route -- which serializes a tree and lets DRM.jl rebuild the precision --
# these markers carry a USER-SUPPLIED covariance matrix that crosses JuliaCall as
# a plain numeric matrix and is handed to `drm(...)` through the matching keyword:
#
#   relmat(1 | g, K = K)   -> drm(...; K = K)        (relatedness / GRM / kernel)
#   animal(1 | g, A = A)   -> drm(...; A = A)        (additive relationship matrix)
#   spatial(1 | g, coords) -> native fixed-range K -> drm(...; K = K)
#   spatial(1 | g, K = K)  -> drm(...; K = K)        (counts/Gamma: precomputed cov)
#
# DRM.jl rescales the covariance to a unit-diagonal correlation, so the recovered
# `resd_<group>` block is the random-effect SD directly on the response scale (no
# tree-depth SD rescaling -- structured SD scale is 1). The matrix's rows must be
# ordered as the grouping levels first appear in `data` (DRM.jl's convention); the
# bridge passes `data` unreordered, so no row permutation is applied.
#
# Supported families are exactly DRM.jl's general-covariance set: Gaussian,
# Poisson, NB2, and Gamma. Beta / Binomial support only `phylo()` in DRM.jl and
# are rejected here. `Q` (precision), `Ainv`, `pedigree`, and `mesh` marker forms
# are rejected because `drm()` consumes only K / A / coords for these routes.
# ---------------------------------------------------------------------------

# Families that route through the Julia engine with a general-covariance
# structured term (relmat / animal / spatial). This is DRM.jl's user-supplied
# covariance set and is DISTINCT from the phylo-only set: Beta and Binomial fit
# phylo but have no relmat/animal/spatial `drm()` route, so they are excluded.
drm_julia_structured_families <- function() {
  c("gaussian", "poisson", "nbinom2", "gamma")
}

# Structured-marker types this route marshals. Excludes "phylo" (its own
# tree-serializing route) and "phylo_interaction" (Kronecker pair precision, no
# single-matrix bridge form yet).
drm_julia_structured_marker_types <- function() {
  c("relmat", "animal", "spatial")
}

# TRUE when any formula entry carries a relmat / animal / spatial structured term.
drm_julia_has_structured_term <- function(formula) {
  length(drm_julia_collect_structured_terms(formula)) > 0L
}

drm_julia_collect_structured_terms <- function(formula) {
  marker_types <- drm_julia_structured_marker_types()
  unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) term$type %in% marker_types,
        entry$structured
      )
    }),
    recursive = FALSE
  )
}

drmTMB_julia_biv_known_structured_bridge <- function(
  formula,
  family,
  data,
  env,
  weights_missing,
  control,
  impute,
  missing,
  REML = FALSE,
  call
) {
  if (!isTRUE(weights_missing)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} bivariate q2 structured models do not support {.arg weights} yet.",
      i = "Use native {.code engine = \"tmb\"} for weighted structured fits until the bridge has a weights payload."
    ))
  }
  if (!is.null(impute)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} bivariate q2 structured models do not support {.arg impute} yet.",
      i = "Use native {.code engine = \"tmb\"} for structured imputation workflows until the bridge has an imputation payload."
    ))
  }
  family_type <- drm_julia_bridge_family_type(family)
  missing_control <- drm_parse_missing_control(missing)
  if (
    !identical(missing_control$predictor, "fail") ||
      !identical(missing_control$response, "drop")
  ) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} bivariate q2 structured models require complete responses and predictors.",
      i = "Use {.code missing = miss_control(response = \"drop\", predictor = \"fail\")}, or use native {.code engine = \"tmb\"} for missing-data routes."
    ))
  }
  if (!drm_julia_default_control(control)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} bivariate q2 structured models currently accept only default {.arg control}.",
      i = "Use the native {.code engine = \"tmb\"} path for TMB optimizer, storage, sparse, or aggregation controls."
    ))
  }

  payload <- drm_julia_biv_known_structured_payload(
    formula = formula,
    family_type = family_type,
    data = data,
    env = env
  )
  result <- drm_julia_call_structured(
    formula = payload$formula,
    family = "biv_gaussian",
    data = payload$data,
    matrix = payload$matrix,
    kwarg = payload$kwarg,
    options = payload$options
  )
  new_drmTMB_julia(
    result = result,
    call = call,
    formula = formula,
    family = family,
    data = data,
    family_type = family_type,
    structured_sd_scales = payload$structured_sd_scales,
    bridge_payload = payload,
    requested_REML = isTRUE(REML),
    effective_REML = FALSE
  )
}

drm_julia_biv_known_structured_payload <- function(
  formula,
  family_type,
  data,
  env
) {
  if (!identical(family_type, "biv_gaussian")) {
    cli::cli_abort(
      "{.code engine = \"julia\"} bivariate q2 structured payloads require {.fn biv_gaussian}."
    )
  }
  terms <- drm_julia_collect_structured_terms(formula)
  if (length(terms) != 2L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} bivariate q2 structured models require matching structured terms in {.code mu1} and {.code mu2}.",
      i = "Use matching {.code relmat(1 | p | group, K = K)} or {.code animal(1 | p | group, A = A)} terms in both location formulas, or use native {.code engine = \"tmb\"}."
    ))
  }
  dpars <- vapply(terms, `[[`, character(1L), "dpar")
  if (!setequal(dpars, c("mu1", "mu2"))) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} bivariate q2 structured models route only {.code mu1}/{.code mu2} terms.",
      x = "Structured axes supplied: {.val {dpars}}.",
      i = "Use native {.code engine = \"tmb\"} for q4, scale-side, or partial structured layouts."
    ))
  }
  type <- unique(vapply(terms, `[[`, character(1L), "type"))
  if (length(type) != 1L) {
    cli::cli_abort(
      "{.code engine = \"julia\"} requires the q2 structured terms on {.code mu1} and {.code mu2} to use the same marker type."
    )
  }
  if (!type %in% c("relmat", "animal", "spatial")) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} bivariate q2 structured models route only {.fn relmat}, {.fn animal}, or fixed-covariance {.fn spatial}.",
      i = "Use the existing {.fn phylo} bivariate bridge route for q2 phylogenetic fits."
    ))
  }
  if (
    !all(vapply(
      terms,
      function(term) identical(term$coef_names, "(Intercept)"),
      logical(1L)
    ))
  ) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} bivariate q2 structured models support only intercept markers.",
      i = "Use syntax such as {.code relmat(1 | p | group, K = K)} in both location formulas."
    ))
  }
  groups <- vapply(terms, `[[`, character(1L), "group")
  objects <- vapply(terms, `[[`, character(1L), "object")
  structures <- vapply(terms, `[[`, character(1L), "structure")
  blocks <- vapply(
    terms,
    function(term) {
      block <- term$covariance_label
      if (is.null(block) || !nzchar(block)) {
        return(NA_character_)
      }
      block
    },
    character(1L)
  )
  if (length(unique(groups)) != 1L) {
    cli::cli_abort(
      "{.code engine = \"julia\"} requires q2 structured terms on {.code mu1} and {.code mu2} to share one grouping variable."
    )
  }
  if (length(unique(objects)) != 1L || length(unique(structures)) != 1L) {
    cli::cli_abort(
      "{.code engine = \"julia\"} requires q2 structured terms on {.code mu1} and {.code mu2} to share one matrix object and matrix slot."
    )
  }
  if (!(all(is.na(blocks)) || length(unique(blocks)) == 1L)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} requires q2 structured terms on {.code mu1} and {.code mu2} to share one covariance-block label."
    )
  }
  if (!groups[[1L]] %in% names(data)) {
    cli::cli_abort(
      "Structured grouping variable {.field {groups[[1L]]}} was not found in {.arg data}."
    )
  }
  scale_entries <- Filter(
    function(entry) entry$dpar %in% c("sigma1", "sigma2", "rho12"),
    formula$entries
  )
  if (
    length(scale_entries) > 0L &&
      !all(vapply(
        scale_entries,
        function(entry) drm_julia_is_intercept_rhs(entry$rhs),
        logical(1L)
      ))
  ) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} bivariate q2 structured models require {.code sigma1 ~ 1}, {.code sigma2 ~ 1}, and {.code rho12 ~ 1}.",
      i = "Use native {.code engine = \"tmb\"} for predictor-dependent residual scale or residual correlation."
    ))
  }

  term <- terms[[1L]]
  resolved <- drm_julia_structured_matrix(
    term = term,
    family_type = family_type,
    env = env,
    data = data
  )
  formula_spec <- drm_julia_formula_spec(formula)
  matrix <- resolved$matrix
  kwarg <- resolved$kwarg
  if (identical(type, "spatial")) {
    native_spatial <- drm_spatial_coords_precision(
      matrix,
      site = data[[groups[[1L]]]],
      group = groups[[1L]]
    )
    matrix <- solve(as.matrix(native_spatial$precision))
    kwarg <- "K"
    formula_spec$mu1 <- sub(
      "spatial(",
      "relmat(",
      formula_spec$mu1,
      fixed = TRUE
    )
    formula_spec$mu2 <- sub(
      "spatial(",
      "relmat(",
      formula_spec$mu2,
      fixed = TRUE
    )
  }
  labels <- vapply(terms, `[[`, character(1L), "label")
  list(
    formula = formula_spec,
    data = drm_julia_bridge_data(data, formula),
    matrix = matrix,
    kwarg = kwarg,
    options = list(g_tol = 1e-4),
    row_order = NULL,
    structured_sd_scales = stats::setNames(rep(1, length(labels)), labels),
    bivariate = TRUE,
    bivariate_dimension = "q2",
    structured_type = type,
    covariance_label = if (all(is.na(blocks))) NA_character_ else blocks[[1L]]
  )
}

drmTMB_julia_structured_bridge <- function(
  formula,
  family,
  data,
  env,
  weights_missing,
  control,
  impute,
  missing,
  REML = FALSE,
  call
) {
  if (!isTRUE(weights_missing)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} structured models do not support {.arg weights} yet.",
      i = "Use native {.code engine = \"tmb\"} for weighted structured fits until the bridge has a weights payload."
    ))
  }
  if (!is.null(impute)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} structured models do not support {.arg impute} yet.",
      i = "Use native {.code engine = \"tmb\"} for structured imputation workflows until the bridge has an imputation payload."
    ))
  }
  family_type <- drm_julia_bridge_family_type(family)
  missing_control <- drm_parse_missing_control(missing)
  if (!drm_julia_missing_supported(missing_control, family_type)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} structured models do not support this {.arg missing} route yet.",
      i = "Supported: {.code response = \"drop\"}, or {.code response = \"include\"} for Gaussian (observed-data fit, tree kept whole). Use {.code engine = \"tmb\"} otherwise."
    ))
  }
  if (!drm_julia_default_control(control)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} structured models currently accept only default {.arg control}.",
      i = "Use the native {.code engine = \"tmb\"} path for TMB optimizer, storage, sparse, or aggregation controls."
    ))
  }

  family_tag <- drm_julia_structured_family_tag(family_type)
  payload <- drm_julia_structured_payload(
    formula = formula,
    family_type = family_type,
    data = data,
    env = env
  )

  result <- drm_julia_call_structured(
    formula = payload$formula,
    family = family_tag,
    data = payload$data,
    matrix = payload$matrix,
    kwarg = payload$kwarg,
    options = payload$options
  )
  new_drmTMB_julia(
    result = result,
    call = call,
    formula = formula,
    family = family,
    data = data,
    family_type = family_type,
    structured_sd_scales = payload$structured_sd_scales,
    bridge_payload = NULL,
    requested_REML = isTRUE(REML),
    effective_REML = FALSE
  )
}

# Gate which families route with a general-covariance structured term. Mirrors
# `drm_julia_family_tag` but for the relmat/animal/spatial set; structured terms
# never appear in a bivariate bridge fit, so only the univariate tags pass.
drm_julia_structured_family_tag <- function(family_type) {
  structured_families <- drm_julia_structured_families()
  if (family_type %in% structured_families) {
    return(family_type)
  }
  cli::cli_abort(c(
    "{.code engine = \"julia\"} routes {.fn relmat} / {.fn animal} / {.fn spatial} structured terms only for univariate Gaussian, Poisson, NB2, or Gamma fits.",
    i = "DRM.jl fits these general-covariance random intercepts for those families; use {.code engine = \"tmb\"} for {.val {family_type}} structured models."
  ))
}

# Validate the single structured term and marshal its user-supplied matrix.
# Returns the DRM.jl formula spec (marker matrix kwarg stripped), the column
# table, the numeric matrix, the `drm()` keyword it maps to ("K" / "A" /
# "coords"), the structured SD scale (always 1 here), and the options list.
drm_julia_structured_payload <- function(formula, family_type, data, env) {
  terms <- drm_julia_collect_structured_terms(formula)
  if (length(terms) != 1L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} currently supports one {.fn relmat} / {.fn animal} / {.fn spatial} structured term.",
      i = "Use native {.code engine = \"tmb\"} for multiple structured terms."
    ))
  }
  term <- terms[[1L]]

  if (
    !identical(term$dpar, "mu") ||
      !identical(term$coef_names, "(Intercept)")
  ) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} currently supports only {.code {term$type}(1 | group, ...)} in the {.code mu} formula.",
      i = "Use native {.code engine = \"tmb\"} for structured slopes, residual-scale structured effects, or direct-SD formulas."
    ))
  }
  sigma_entries <- Filter(
    function(entry) identical(entry$dpar, "sigma"),
    formula$entries
  )
  if (
    length(sigma_entries) > 0L &&
      !all(vapply(
        sigma_entries,
        function(entry) drm_julia_is_intercept_rhs(entry$rhs),
        logical(1L)
      ))
  ) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} uses DRM.jl's general-covariance sparse route, which currently requires {.code sigma ~ 1}.",
      i = "Use native {.code engine = \"tmb\"} for structured models with predictor-dependent residual scale."
    ))
  }
  if (!term$group %in% names(data)) {
    cli::cli_abort(
      "Structured grouping variable {.field {term$group}} was not found in {.arg data}."
    )
  }

  resolved <- drm_julia_structured_matrix(
    term = term,
    family_type = family_type,
    env = env,
    data = data
  )
  formula_spec <- drm_julia_formula_spec(formula)
  matrix <- resolved$matrix
  kwarg <- resolved$kwarg
  if (identical(term$type, "spatial") && identical(family_type, "gaussian")) {
    native_spatial <- drm_spatial_coords_precision(
      matrix,
      site = data[[term$group]],
      group = term$group
    )
    matrix <- solve(as.matrix(native_spatial$precision))
    kwarg <- "K"
    formula_spec[[term$dpar]] <- sub(
      "spatial(",
      "relmat(",
      formula_spec[[term$dpar]],
      fixed = TRUE
    )
  }

  list(
    formula = formula_spec,
    data = drm_julia_bridge_data(data, formula),
    matrix = matrix,
    kwarg = kwarg,
    options = list(),
    structured_sd_scales = stats::setNames(1, term$label)
  )
}

# Resolve a structured term's user-supplied matrix to the (numeric matrix,
# `drm()` keyword) pair the Julia bridge needs. The parser stores the marker's
# matrix slot as `structure` (the keyword the USER wrote: "K"/"Q"/"A"/"Ainv"/
# "coords"/"mesh") and `object` (the symbol to look up in `env`). Only the slots
# DRM.jl's `drm()` consumes for these routes are accepted; precision ("Q",
# "Ainv"), pedigree, and mesh forms are rejected with a pointer to `engine="tmb"`.
drm_julia_structured_matrix <- function(term, family_type, env, data) {
  type <- term$type
  slot <- term$structure
  obj_name <- term$object

  if (identical(type, "relmat")) {
    if (!identical(slot, "K")) {
      drm_julia_structured_reject_slot(type, slot, "K", "covariance")
    }
    kwarg <- "K"
  } else if (identical(type, "animal")) {
    if (!identical(slot, "A")) {
      drm_julia_structured_reject_slot(type, slot, "A", "relatedness")
    }
    kwarg <- "A"
  } else {
    # spatial: native drmTMB fixes the coordinate-spatial range at the median
    # positive distance. The bridge preserves that target by converting Gaussian
    # spatial coords to a fixed covariance K in `drm_julia_structured_payload`.
    # Non-Gaussian spatial has no native-compatible bridge form here; pass a
    # precomputed spatial covariance through `relmat(1 | g, K = K)` instead.
    if (!family_type %in% c("gaussian", "biv_gaussian")) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} routes {.fn spatial} only for Gaussian fits (coordinate-based range estimation is Gaussian-only in DRM.jl).",
        i = "For a {.val {family_type}} spatial random intercept, pass a precomputed spatial covariance as {.code relmat(1 | {term$group}, K = K)}, or use {.code engine = \"tmb\"}."
      ))
    }
    if (!identical(slot, "coords")) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} Gaussian {.fn spatial} models require {.arg coords}.",
        x = "Got {.code spatial(1 | {term$group}, {slot} = ...)}.",
        i = "Use {.code spatial(1 | {term$group}, coords = coords)}; {.arg mesh} is not wired into the bridge yet."
      ))
    }
    kwarg <- "coords"
  }

  value <- get(obj_name, envir = env, inherits = TRUE)
  if (!is.matrix(value) && !is.data.frame(value)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} could not marshal {.fn {type}} {.arg {slot}} object {.val {obj_name}}.",
      x = "Expected a numeric matrix or data frame, got {.cls {class(value)}}.",
      i = "Sparse precision objects, pedigrees, and meshes are not marshalled by this route yet."
    ))
  }
  matrix <- drm_julia_as_matrix(value)
  if (!all(is.finite(matrix))) {
    cli::cli_abort(
      "{.code engine = \"julia\"} requires finite values in the {.fn {type}} {.arg {slot}} matrix."
    )
  }
  if (identical(kwarg, "coords")) {
    if (ncol(matrix) < 1L) {
      cli::cli_abort(
        "{.code engine = \"julia\"} {.fn spatial} {.arg coords} must have at least one coordinate column."
      )
    }
  } else if (nrow(matrix) != ncol(matrix)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} {.fn {type}} {.arg {slot}} must be a square covariance/relatedness matrix.",
      x = "Got a {nrow(matrix)} x {ncol(matrix)} matrix."
    ))
  }
  list(matrix = matrix, kwarg = kwarg)
}

drm_julia_structured_reject_slot <- function(type, slot, expected, kind) {
  cli::cli_abort(c(
    "{.code engine = \"julia\"} routes {.fn {type}} only with a {kind} matrix supplied as {.arg {expected}}.",
    x = "Got {.code {type}(1 | group, {slot} = ...)}.",
    i = "Precision / inverse forms ({.arg Q}, {.arg Ainv}) and pedigrees are not marshalled by the bridge; supply the {kind} matrix as {.arg {expected}}, or use {.code engine = \"tmb\"}."
  ))
}

drm_julia_call_structured <- function(
  formula,
  family,
  data,
  matrix,
  kwarg,
  options = list()
) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} requires the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }

  drm_julia_setup()
  K <- if (identical(kwarg, "K")) matrix else NULL
  A <- if (identical(kwarg, "A")) matrix else NULL
  coords <- if (identical(kwarg, "coords")) matrix else NULL
  JuliaCall::julia_call(
    "drmTMB_drm_bridge_structured",
    formula,
    family,
    as.list(data),
    K,
    A,
    coords,
    if (length(options) == 0L) NULL else options
  )
}

# ---------------------------------------------------------------------------
# Cross-family bivariate route (engine = "julia").
#
# Routes `family = c(faA, faB)` with faA / faB possibly DIFFERENT (e.g.
# c(poisson(), gaussian())) to DRM.fit_mixed_family, which fits
#   y1 ~ famA(eta1), y2 ~ famB(eta2),  eta_k = X_k beta_k + lambda_k u,  u ~ N(0, 1)
# and reports the dependence on the latent / link scale (Nakagawa & Schielzeth
# 2010). The Gaussian x Gaussian pair keeps the verified residual-rho12
# biv_gaussian route; this cross-family path is taken only when at least one
# axis is non-Gaussian. The TMB path never reaches here.
# ---------------------------------------------------------------------------

# R family -> DRM family tag. NULL means "not a cross-family-supported axis".
#
# Tier-1 axes (Gaussian / Poisson / Binomial) and Tier-2 axes (NB2 / Beta /
# Gamma) are both keyed off base-R `family` objects (class "family"), because
# the cross-family route is composed via `drm_composed_families()` /
# `is_r_family_object()`. The link guard for each axis matches the link the
# DRM.jl `_mf_obs_ll` likelihood assumes: log mean for Poisson / NB2 / Gamma,
# logit mean for Binomial / Beta, identity for Gaussian. DRM.jl fits each
# axis's dispersion internally (log sigma for Gaussian/Beta/Gamma, log size
# for NB2) and returns it, so there is no R-side dispersion to pass in.
#
# Constructors that produce the required base-R `family` objects:
#   gaussian()  poisson()  binomial()                       (Tier 1, stats)
#   glmmTMB::nbinom2()                  -> family "nbinom2"  (Tier 2, NB2)
#   MASS::negative.binomial(theta)      -> family "Negative Binomial(theta)"
#   glmmTMB::beta_family()              -> family "beta"     (Tier 2, Beta)
#   Gamma(link = "log")                 -> family "Gamma"    (Tier 2, Gamma)
drm_julia_xfam_family_tag <- function(family) {
  if (!is_r_family_object(family)) {
    return(NULL)
  }
  if (identical(family$family, "gaussian")) {
    return("gaussian")
  }
  if (identical(family$family, "poisson")) {
    if (!identical(family$link, "log")) {
      return(NULL)
    }
    return("poisson")
  }
  if (identical(family$family, "binomial")) {
    if (!identical(family$link, "logit")) {
      return(NULL)
    }
    return("binomial")
  }
  if (identical(family$family, "nbinom2") || drm_is_nbinom_family(family)) {
    if (!identical(family$link, "log")) {
      return(NULL)
    }
    return("nbinom2")
  }
  if (identical(family$family, "beta")) {
    if (!identical(family$link, "logit")) {
      return(NULL)
    }
    return("beta")
  }
  if (identical(family$family, "Gamma")) {
    # DRM.jl's Gamma axis uses a log mean link; base R Gamma() defaults to
    # "inverse", so only the log-link Gamma composes here.
    if (!identical(family$link, "log")) {
      return(NULL)
    }
    return("gamma")
  }
  NULL
}

# MASS::negative.binomial(theta) tags its family as "Negative Binomial(<theta>)"
# rather than "nbinom2". Treat any such object as an NB2 axis; DRM.jl re-fits the
# size parameter, so the embedded theta is not used.
drm_is_nbinom_family <- function(family) {
  is.character(family$family) &&
    length(family$family) == 1L &&
    grepl("^Negative Binomial", family$family)
}

# TRUE when `family` is a two-element composed family that the cross-family
# Julia route should handle, i.e. both axes map to DRM families and the pair is
# NOT gaussian x gaussian (which keeps the verified biv_gaussian route).
drm_julia_is_cross_family <- function(family) {
  composed <- drm_composed_families(family)
  if (is.null(composed) || length(composed) != 2L) {
    return(FALSE)
  }
  tags <- lapply(composed, drm_julia_xfam_family_tag)
  if (any(vapply(tags, is.null, logical(1L)))) {
    return(FALSE)
  }
  tags <- vapply(tags, identity, character(1L))
  !identical(tags, c("gaussian", "gaussian"))
}

drmTMB_julia_xfam_bridge <- function(
  formula,
  family,
  data,
  env,
  weights_missing,
  control,
  impute,
  missing,
  REML = FALSE,
  call
) {
  if (!isTRUE(weights_missing)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models do not support {.arg weights} yet.",
      i = "Use native {.code engine = \"tmb\"} for weighted fits until the cross-family bridge has a weights payload."
    ))
  }
  if (!is.null(impute)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models do not support {.arg impute} yet.",
      i = "Use native {.code engine = \"tmb\"} for imputation workflows until the cross-family bridge has an imputation payload."
    ))
  }
  missing_control <- drm_parse_missing_control(missing)
  if (
    !identical(missing_control$response, "drop") ||
      !identical(missing_control$predictor, "fail")
  ) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models do not support {.arg missing} routes yet.",
      i = "Cross-family bivariate fits currently require complete responses and predictors."
    ))
  }
  if (!drm_julia_default_control(control)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models currently accept only default {.arg control}.",
      i = "TMB optimizer / storage / sparse controls do not apply to the cross-family latent engine."
    ))
  }

  composed <- drm_composed_families(family)
  tags <- vapply(composed, drm_julia_xfam_family_tag, character(1L))
  axes <- drm_julia_xfam_axes(
    formula = formula,
    data = data,
    env = env,
    tags = tags
  )

  result <- drm_julia_call_xfam(
    y1 = axes$mu1$y,
    X1 = axes$mu1$X,
    fam1 = tags[[1L]],
    y2 = axes$mu2$y,
    X2 = axes$mu2$X,
    fam2 = tags[[2L]],
    Xsigma1 = axes$sigma1$X,
    Xsigma2 = axes$sigma2$X
  )

  new_drmTMB_julia_xfam(
    result = result,
    call = call,
    formula = formula,
    family = family,
    families = tags,
    axes = axes,
    data = data,
    requested_REML = isTRUE(REML)
  )
}

# Build the (y, X) design for the mu1 / mu2 location formulas and the optional
# Xsigma1 / Xsigma2 dispersion (log-sigma sub-model) designs. Mirrors the native
# biv_gaussian extraction: each location entry carries a response and an RHS,
# which we turn into `response ~ rhs` and pass through model.frame / model.matrix
# on complete cases.
#
# A `sigma_k` entry carries only an RHS (no response), so we pair it with its
# axis's mu response to build `mu_response ~ sigma_rhs`; na.omit then drops the
# SAME rows the mu axis dropped, keeping the dispersion design row-aligned with
# its location design. An absent `sigma_k` formula yields an intercept-only
# Xsigma (the current scalar-dispersion behaviour). `tags` is the per-axis DRM
# family tag (e.g. "gaussian", "poisson"); a `sigma_k` formula on a
# dispersionless axis (Poisson / Binomial) is rejected, since DRM.jl carries no
# dispersion sub-model there.
drm_julia_xfam_axes <- function(formula, data, env, tags) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1L), "dpar")

  unsupported <- setdiff(
    unique(dpars),
    c("mu1", "mu2", "sigma1", "sigma2")
  )
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models currently support only {.code mu1} / {.code mu2} location and {.code sigma1} / {.code sigma2} dispersion formulas.",
      x = "Unsupported parameter{?s}: {.val {unsupported}}.",
      i = "Correlation ({.code rho12}) formulas are not wired into the cross-family latent engine yet."
    ))
  }
  for (required in c("mu1", "mu2")) {
    if (sum(dpars == required) != 1L) {
      cli::cli_abort(
        "{.code engine = \"julia\"} cross-family models require exactly one {.code {required}} formula."
      )
    }
  }
  for (optional in c("sigma1", "sigma2")) {
    if (sum(dpars == optional) > 1L) {
      cli::cli_abort(
        "{.code engine = \"julia\"} cross-family models accept at most one {.code {optional}} formula."
      )
    }
  }

  mu1 <- drm_julia_xfam_axis(entries[[which(dpars == "mu1")]], data, env, "mu1")
  mu2 <- drm_julia_xfam_axis(entries[[which(dpars == "mu2")]], data, env, "mu2")
  if (length(mu1$y) != length(mu2$y)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family responses must have equal length after dropping missing rows.",
      x = "{.code mu1} has {length(mu1$y)} complete row{?s}; {.code mu2} has {length(mu2$y)}.",
      i = "Cross-family fits do not yet support per-axis missingness."
    ))
  }

  sigma1 <- drm_julia_xfam_sigma(
    entry = if (any(dpars == "sigma1")) {
      entries[[which(dpars == "sigma1")]]
    } else {
      NULL
    },
    mu = mu1,
    tag = tags[[1L]],
    data = data,
    env = env,
    dpar = "sigma1"
  )
  sigma2 <- drm_julia_xfam_sigma(
    entry = if (any(dpars == "sigma2")) {
      entries[[which(dpars == "sigma2")]]
    } else {
      NULL
    },
    mu = mu2,
    tag = tags[[2L]],
    data = data,
    env = env,
    dpar = "sigma2"
  )

  list(mu1 = mu1, mu2 = mu2, sigma1 = sigma1, sigma2 = sigma2)
}

# Build one axis's Xsigma design (the log-sigma sub-model regressors). An absent
# `entry` (no sigma_k formula) returns an intercept-only design over the mu
# axis's rows, reproducing the scalar-dispersion default. A present entry must
# land on a dispersion-carrying axis (Gaussian / NB2 / Beta / Gamma); on a
# dispersionless axis (Poisson / Binomial) it is rejected. The design is built
# from `mu_response ~ sigma_rhs` so na.omit drops the same rows the mu axis did,
# keeping Xsigma row-aligned with X.
drm_julia_xfam_sigma <- function(entry, mu, tag, data, env, dpar) {
  dispersionless <- c("poisson", "binomial")
  if (is.null(entry)) {
    return(list(
      X = matrix(1, nrow = length(mu$y), ncol = 1L),
      coef_names = "(Intercept)"
    ))
  }
  if (tag %in% dispersionless) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models cannot fit a {.code {dpar}} dispersion sub-model on a {.val {tag}} axis.",
      i = "{.val {tag}} has no dispersion parameter; drop the {.code {dpar}} formula."
    ))
  }
  if (!is.na(entry$response)) {
    cli::cli_abort(
      "The {.code {dpar}} formula must be one-sided (no response on the left-hand side)."
    )
  }
  rhs <- deparse1(entry$rhs)
  f <- stats::as.formula(
    paste(mu$response, "~", rhs),
    env = env
  )
  mf <- stats::model.frame(f, data = data, na.action = stats::na.omit)
  X <- stats::model.matrix(
    stats::delete.response(stats::terms(mf)),
    mf
  )
  if (nrow(X) != length(mu$y)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family {.code {dpar}} design must align row-for-row with its {.code mu} axis.",
      x = "{.code {dpar}} has {nrow(X)} complete row{?s}; its {.code mu} axis has {length(mu$y)}.",
      i = "Cross-family fits do not yet support per-axis missingness."
    ))
  }
  list(X = X, coef_names = colnames(X))
}

drm_julia_xfam_axis <- function(entry, data, env, dpar) {
  if (is.na(entry$response)) {
    cli::cli_abort(
      "The {.code {dpar}} formula must include a response on the left-hand side."
    )
  }
  rhs <- deparse1(entry$rhs)
  f <- stats::as.formula(
    paste(entry$response, "~", rhs),
    env = env
  )
  mf <- stats::model.frame(f, data = data, na.action = stats::na.omit)
  y <- as.numeric(stats::model.response(mf))
  X <- stats::model.matrix(
    stats::delete.response(stats::terms(mf)),
    mf
  )
  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain for {.code {dpar}} after dropping missing rows."
    )
  }
  list(
    response = entry$response,
    y = y,
    X = X,
    coef_names = colnames(X)
  )
}

drm_julia_call_xfam <- function(
  y1,
  X1,
  fam1,
  y2,
  X2,
  fam2,
  Xsigma1 = matrix(1, nrow = length(y1), ncol = 1L),
  Xsigma2 = matrix(1, nrow = length(y2), ncol = 1L)
) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models require the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }
  drm_julia_setup()
  JuliaCall::julia_call(
    "drmTMB_mixed_family",
    as.double(y1),
    drm_julia_as_matrix(X1),
    fam1,
    as.double(y2),
    drm_julia_as_matrix(X2),
    fam2,
    drm_julia_as_matrix(Xsigma1),
    drm_julia_as_matrix(Xsigma2)
  )
}

drm_julia_as_matrix <- function(x) {
  out <- as.matrix(x)
  storage.mode(out) <- "double"
  dimnames(out) <- NULL
  out
}

# Julia-side helper, registered once in drm_julia_setup(). Maps family tag
# strings to DRM family instances and calls DRM.fit_mixed_family with the
# profile-likelihood CI on the latent-scale correlation.
drm_julia_xfam_helper_source <- function() {
  paste(
    "function drmTMB_mixed_family(y1, X1, fam1::AbstractString, y2, X2, fam2::AbstractString, Xsigma1, Xsigma2)",
    "    _fam(s) = s == \"gaussian\" ? DRM.Gaussian() :",
    "             s == \"poisson\"  ? DRM.Poisson() :",
    "             s == \"binomial\" ? DRM.Binomial() :",
    "             s == \"nbinom2\"  ? DRM.NegBinomial2() :",
    "             s == \"beta\"     ? DRM.Beta() :",
    "             s == \"gamma\"    ? DRM.Gamma() :",
    "             error(\"unsupported cross-family tag: \" * s)",
    "    r = DRM.fit_mixed_family(; y1 = Float64.(vec(y1)), X1 = Float64.(X1), fam1 = _fam(fam1),",
    "                               y2 = Float64.(vec(y2)), X2 = Float64.(X2), fam2 = _fam(fam2),",
    "                               Xsigma1 = Float64.(Xsigma1), Xsigma2 = Float64.(Xsigma2),",
    "                               profile = true, B = 0)",
    "    return Dict{String,Any}(",
    "        \"rho_latent\"        => r.rho_latent,",
    "        \"rho_ci_wald_lower\" => r.rho_ci_wald[1],",
    "        \"rho_ci_wald_upper\" => r.rho_ci_wald[2],",
    "        \"rho_ci_prof_lower\" => r.rho_ci_profile[1],",
    "        \"rho_ci_prof_upper\" => r.rho_ci_profile[2],",
    "        \"beta1\"             => collect(r.\u{03b2}1),",
    "        \"beta2\"             => collect(r.\u{03b2}2),",
    "        \"sigma_coef1\"       => collect(r.\u{03b2}\u{03c3}1),",
    "        \"sigma_coef2\"       => collect(r.\u{03b2}\u{03c3}2),",
    "        \"lambda1\"           => r.\u{03bb}1,",
    "        \"lambda2\"           => r.\u{03bb}2,",
    "        \"sigma1\"            => r.\u{03c3}1,",
    "        \"sigma2\"            => r.\u{03c3}2,",
    "        \"loglik\"            => r.loglik,",
    "        \"converged\"         => r.converged,",
    "        \"iterations\"        => r.iterations)",
    "end",
    sep = "\n"
  )
}

new_drmTMB_julia_xfam <- function(
  result,
  call,
  formula,
  family,
  families,
  axes,
  data,
  requested_REML = FALSE
) {
  result <- as.list(result)
  scalar <- function(x) as.numeric(x)[[1L]]
  rho_latent <- scalar(result$rho_latent)
  rho_ci_wald <- c(
    lower = scalar(result$rho_ci_wald_lower),
    upper = scalar(result$rho_ci_wald_upper)
  )
  rho_ci_profile <- c(
    lower = scalar(result$rho_ci_prof_lower),
    upper = scalar(result$rho_ci_prof_upper)
  )

  coefficients <- list(
    mu1 = stats::setNames(
      as.numeric(unlist(result$beta1, use.names = FALSE)),
      axes$mu1$coef_names
    ),
    mu2 = stats::setNames(
      as.numeric(unlist(result$beta2, use.names = FALSE)),
      axes$mu2$coef_names
    )
  )

  # Dispersion (log-sigma) sub-model coefficients, one block per axis. The engine
  # returns an empty vector for a dispersionless axis (Poisson / Binomial), in
  # which case the block is a zero-length named numeric. Otherwise the names are
  # the Xsigma design columns ("(Intercept)" + any sigma_k covariates).
  sigma_coef_axis <- function(raw, coef_names) {
    vals <- as.numeric(unlist(raw, use.names = FALSE))
    if (length(vals) == length(coef_names)) {
      stats::setNames(vals, coef_names)
    } else {
      vals
    }
  }
  sigma_coef <- list(
    sigma1 = sigma_coef_axis(result$sigma_coef1, axes$sigma1$coef_names),
    sigma2 = sigma_coef_axis(result$sigma_coef2, axes$sigma2$coef_names)
  )
  fitted_link <- list(
    mu1 = as.numeric(axes$mu1$X %*% coefficients$mu1),
    mu2 = as.numeric(axes$mu2$X %*% coefficients$mu2)
  )
  fitted <- list(
    mu1 = drm_julia_tag_linkinv(families[[1L]])(fitted_link$mu1),
    mu2 = drm_julia_tag_linkinv(families[[2L]])(fitted_link$mu2)
  )
  residuals <- list(
    mu1 = as.numeric(axes$mu1$y) - fitted$mu1,
    mu2 = as.numeric(axes$mu2$y) - fitted$mu2
  )
  coefficient_blocks <- c(coefficients, sigma_coef)
  coefficient_blocks <- coefficient_blocks[vapply(
    coefficient_blocks,
    length,
    integer(1L)
  ) > 0L]
  coef_vector <- unlist(
    unname(Map(
      function(dpar, values) {
        stats::setNames(values, paste(dpar, names(values), sep = "_"))
      },
      names(coefficient_blocks),
      coefficient_blocks
    )),
    use.names = TRUE
  )
  # `fit_mixed_family()` estimates two latent loadings in addition to the
  # linear-predictor coefficients. rho_latent is derived from those loadings
  # and the fitted dispersion, so it is not an additional free parameter.
  df <- length(coef_vector) + 2L
  logLik <- scalar(result$loglik)
  aic <- -2 * logLik + 2 * df
  bic <- -2 * logLik + log(length(axes$mu1$y)) * df

  out <- list(
    call = call,
    formula = formula,
    family = family,
    families = families,
    data = data,
    engine = "julia",
    estimator = "ML",
    REML = FALSE,
    requested_REML = isTRUE(requested_REML),
    effective_REML = FALSE,
    model = list(
      model_type = "cross_family",
      families = families,
      responses = c(axes$mu1$response, axes$mu2$response),
      dpars = c("mu1", "mu2")
    ),
    axes = axes,
    bridge = result,
    coefficients = coefficients,
    sigma_coef = sigma_coef,
    coef_vector = coef_vector,
    fitted_link = fitted_link,
    fitted = fitted,
    residuals = residuals,
    loadings = c(
      lambda1 = scalar(result$lambda1),
      lambda2 = scalar(result$lambda2)
    ),
    sigma = c(
      sigma1 = scalar(result$sigma1),
      sigma2 = scalar(result$sigma2)
    ),
    rho_latent = rho_latent,
    rho_ci_wald = rho_ci_wald,
    rho_ci_profile = rho_ci_profile,
    logLik = logLik,
    aic = aic,
    bic = bic,
    df = df,
    nobs = length(axes$mu1$y),
    opt = list(convergence = if (isTRUE(result$converged)) 0L else 1L),
    uncertainty = list(
      status = "unavailable",
      se = FALSE,
      message = paste(
        "The legacy cross-family Julia bridge does not return a named",
        "coefficient covariance matrix; fixed-effect standard errors and",
        "Wald intervals are unavailable."
      )
    )
  )
  class(out) <- c("drmTMB_julia_xfam", "drmTMB_julia")
  out
}

#' @export
print.drmTMB_julia_xfam <- function(x, ...) {
  cli::cli_text("<drmTMB Julia-engine cross-family fit>")
  cli::cli_text(
    "  families: {x$families[[1]]} \u{00d7} {x$families[[2]]}"
  )
  cli::cli_text("  observations: {x$nobs}")
  cli::cli_text("  logLik: {format(x$logLik, digits = 4)}")
  cli::cli_text(
    "  latent rho: {format(x$rho_latent, digits = 4)}"
  )
  cli::cli_text("  convergence: {x$opt$convergence}")
  invisible(x)
}

#' @export
coef.drmTMB_julia_xfam <- function(object, dpar = NULL, ...) {
  if (is.null(dpar)) {
    return(object$coefficients)
  }
  # Location blocks (mu1 / mu2) plus, when present, the log-sigma dispersion
  # sub-model blocks (sigma1 / sigma2). The latter are zero-length for a
  # dispersionless axis (Poisson / Binomial).
  blocks <- c(object$coefficients, object$sigma_coef)
  dpar <- match.arg(dpar, names(blocks))
  blocks[[dpar]]
}

#' @export
fixef.drmTMB_julia_xfam <- function(object, ...) {
  coef.drmTMB_julia_xfam(object, ...)
}

#' Extractor unavailable for a legacy cross-family Julia fit
#'
#' The cross-family Julia bridge is retained only to inspect legacy fitted
#' objects. It does not marshal a named coefficient covariance matrix, so
#' covariance-based fixed-effect inference cannot be reconstructed safely.
#'
#' @param object A `drmTMB_julia_xfam` cross-family fit.
#' @param ... Unused.
#' @return This method always errors with an explanation.
#' @export
vcov.drmTMB_julia_xfam <- function(object, ...) {
  cli::cli_abort(c(
    "{.fn vcov} is unavailable for a legacy Julia cross-family fit.",
    i = "The bridge did not retain a named coefficient covariance matrix.",
    i = "Use a native {.code engine = \"tmb\"} fit for covariance-based inference."
  ))
}

#' @export
logLik.drmTMB_julia_xfam <- function(object, ...) {
  out <- object$logLik
  attr(out, "nobs") <- object$nobs
  attr(out, "df") <- object$df
  class(out) <- "logLik"
  out
}

#' @export
nobs.drmTMB_julia_xfam <- function(object, ...) {
  object$nobs
}

#' @export
df.residual.drmTMB_julia_xfam <- function(object, ...) {
  object$nobs - object$df
}

#' Summary for a legacy Julia cross-family fit
#'
#' The cross-family Julia bridge is halted/deferred future work. This
#' compatibility summary reports point estimates only: the bridge does not
#' retain a named covariance matrix, so standard errors and Wald intervals are
#' deliberately unavailable.
#'
#' @param object A `drmTMB_julia_xfam` cross-family fit.
#' @param conf.int Logical; requesting intervals errors because the bridge did
#'   not return fixed-effect covariance.
#' @param ... Unused.
#' @return An object of class `summary.drmTMB_julia` containing point estimates
#'   and an explicit unavailable-uncertainty status.
#' @export
summary.drmTMB_julia_xfam <- function(object, conf.int = FALSE, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("Additional arguments in {.arg ...} are not used by this legacy summary.")
  }
  if (!is.logical(conf.int) || length(conf.int) != 1L || is.na(conf.int)) {
    cli::cli_abort("{.arg conf.int} must be a single {.code TRUE} or {.code FALSE}.")
  }
  if (isTRUE(conf.int)) {
    vcov.drmTMB_julia_xfam(object)
  }
  beta <- object$coef_vector
  coefficients <- data.frame(
    dpar = sub("_.*$", "", names(beta)),
    term = sub("^[^_]+_", "", names(beta)),
    estimate = unname(beta),
    std.error = NA_real_,
    statistic = NA_real_,
    p.value = NA_real_,
    stringsAsFactors = FALSE
  )
  out <- list(
    call = object$call,
    family = object$family,
    engine = "julia",
    coefficients = coefficients,
    random = data.frame(
      dpar = character(), term = character(), sd = numeric(),
      stringsAsFactors = FALSE
    ),
    sigma = object$sigma,
    logLik = object$logLik,
    aic = object$aic,
    bic = object$bic,
    df = object$df,
    nobs = object$nobs,
    converged = isTRUE(object$opt$convergence == 0L),
    uncertainty = object$uncertainty
  )
  class(out) <- "summary.drmTMB_julia"
  out
}

#' @export
fitted.drmTMB_julia_xfam <- function(object, ...) {
  object$fitted
}

#' @export
residuals.drmTMB_julia_xfam <- function(object, type = c("response"), ...) {
  match.arg(type)
  object$residuals
}

#' @rdname predict.drmTMB_julia
#' @export
predict.drmTMB_julia_xfam <- function(
  object,
  newdata = NULL,
  dpar = NULL,
  type = c("response", "link"),
  ...
) {
  type <- match.arg(type)
  if (is.null(dpar)) {
    dpar <- "mu1"
  }
  dpar <- match.arg(dpar, c("mu1", "mu2"))
  if (is.null(newdata)) {
    if (identical(type, "link")) {
      return(object$fitted_link[[dpar]])
    }
    return(object$fitted[[dpar]])
  }
  predict.drmTMB_julia(
    object = object,
    newdata = newdata,
    dpar = dpar,
    type = type,
    ...
  )
}

#' @export
is_converged.drmTMB_julia_xfam <- function(
  object,
  include_hessian = FALSE,
  ...
) {
  isTRUE(object$opt$convergence == 0L)
}

#' Extract a latent-scale correlation from a legacy Julia-bridge fit
#'
#' The cross-family Julia bridge is halted/deferred future work. This
#' compatibility extractor is retained only for an existing
#' `drmTMB_julia_xfam` object; it does not establish a current cross-family
#' fitting or inference capability.
#'
#' @param object A legacy `drmTMB_julia_xfam` cross-family fit.
#' @param ... Unused.
#' @return The latent / link-scale correlation between the two responses.
#' @export
#'
rho_latent <- function(object, ...) {
  UseMethod("rho_latent")
}

#' @export
rho_latent.drmTMB_julia_xfam <- function(object, ...) {
  object$rho_latent
}

#' @export
confint.drmTMB_julia_xfam <- function(
  object,
  parm = "rho_latent",
  level = 0.95,
  method = c("profile", "wald"),
  ...
) {
  method <- match.arg(method)
  if (!identical(level, 0.95)) {
    cli::cli_abort(c(
      "Cross-family Julia fits currently return a fixed 95% interval for {.code rho_latent}.",
      i = "The latent-correlation CIs are computed at {.code level = 0.95} inside DRM.fit_mixed_family."
    ))
  }
  if (!is.null(parm) && !identical(parm, "rho_latent")) {
    cli::cli_abort(c(
      "Cross-family Julia fits currently expose a confidence interval only for {.code rho_latent}.",
      i = "Use {.code parm = \"rho_latent\"} (the latent-scale residual correlation)."
    ))
  }
  interval <- if (identical(method, "profile")) {
    object$rho_ci_profile
  } else {
    object$rho_ci_wald
  }
  data.frame(
    parm = "rho_latent",
    level = level,
    lower = unname(interval[["lower"]]),
    upper = unname(interval[["upper"]]),
    scale = "latent",
    method = method,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}
