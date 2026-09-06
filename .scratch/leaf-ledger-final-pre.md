# Gates: FAM-BIV-STUDENT — admit `biv_student()` through `engine = "julia"`

WORKTREE: /Users/z3437171/local-scratch/parity-joint/wt-fam-biv-student (branch claude/parity-fam-biv-student, cut from origin/main and re-merged with origin/main at 4c1f5a63a during the run). DRM.jl pin: /Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc (430ef64cc, Manifest present). Bridge runs LOCAL only, with OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<pin> DRM_JL_PHYLO_PATH=<pin>, loaded via devtools::load_all(<worktree>).

OWNS (anything else is a STOP and a reported blocker):
- R/drmTMB.R — EXACTLY the `engine == "julia"` + `family$name == "biv_student"` early-refusal block (the "implemented only for engine = \"tmb\"; the Julia route is deferred" abort). Nothing else in this file.
- R/julia-family-registry.R — ONE `spec("biv_student", ...)` row plus its comment.
- R/julia-bridge.R — EXACTLY (i) `drm_julia_bridge_default_dpar_labels()` (a `biv_student` branch: sigma1/sigma2/nu/rho12 defaults), (ii) the NEW `drm_julia_refuse_biv_student_beyond_native()` + `drm_julia_rhs_is_intercept_only()` + `drm_julia_biv_student_constant_dpars()` and their single call site, (iii) a `biv_student` guard at the head of `confint.drmTMB_julia()`, (iv) `drm_julia_capability_comparison()` (ONE `fe_biv_student` row across its ten parallel columns). No other function. (ii) and (iii) were added mid-run in response to measured defects the admission itself created — see G12.
- tests/testthat/test-julia-family-registry.R — the two pinned vectors this one row moves. No pin deleted.
- tests/testthat/test-biv-student.R — EXACTLY the one `expect_error(drmTMB(..., engine = "julia"), "engine")` block that pinned the retired abort. Nothing else.
- tests/testthat/test-julia-family-biv_student.R — NEW, the focused-test limb (design 168).
- inst/extdata/julia-capabilities.tsv + docs/dev-log/dashboard/julia-capabilities.tsv — REGENERATED only, via `Rscript tools/write-julia-capability-comparison.R`. Never hand-edited.
- docs/design/258-coefficient-naming-contract.md — ONE numbered family addendum under the existing section 8 header (no new header).
- docs/dev-log/after-task/2026-09-05-fam-biv-student.md — NEW.
- NEWS.md — the leaf's entry.
- In the DRM.jl PIN CLONE working tree only: docs/dev-log/evidence/parity-fixtures.tsv and parity-se.tsv — ONE appended row each (two for parity-se.tsv, counting the negative control). No commit in DRM.jl by this leaf; none proved necessary (G2).

Scope: `biv_student` is drmTMB's exact shared-nu bivariate Student-t (dpars mu1, mu2, sigma1, sigma2, nu, rho12). It was refused by engine="julia" TWICE: a family-specific early abort in `drmTMB()` itself, and the absent registry row. THE QUESTION THIS LEAF ANSWERS BY MEASUREMENT: does the tag actually ROUTE end to end with that vocabulary, and does it land on the same target as native TMB? ANSWER: yes, and DRM.jl needed no change.

- [x] G0: SCOPE — every changed file is in OWNS
  CHECK: git diff --name-only origin/main | grep -vE '^(NEWS\.md|R/drmTMB\.R|R/julia-bridge\.R|R/julia-family-registry\.R|docs/design/258-coefficient-naming-contract\.md|docs/dev-log/after-task/2026-09-05-fam-biv-student\.md|docs/dev-log/dashboard/julia-capabilities\.tsv|inst/extdata/julia-capabilities\.tsv|tests/testthat/test-biv-student\.R|tests/testthat/test-julia-family-biv_student\.R|tests/testthat/test-julia-family-registry\.R)$' | wc -l | tr -d ' ' | grep -qx 0 && echo SCOPE_OK
  EXPECT: SCOPE_OK
  EVIDENCE: 11 files changed vs origin/main, all in OWNS: NEWS.md, R/drmTMB.R, R/julia-bridge.R, R/julia-family-registry.R, docs/design/258-coefficient-naming-contract.md, docs/dev-log/after-task/2026-09-05-fam-biv-student.md, docs/dev-log/dashboard/julia-capabilities.tsv, inst/extdata/julia-capabilities.tsv, tests/testthat/test-biv-student.R, tests/testthat/test-julia-family-biv_student.R, tests/testthat/test-julia-family-registry.R. `git status --porcelain` afterwards shows only `?? .scratch/` (untracked measurement scripts, not committed).

- [x] G1: RED — BEFORE the change, a WORKING native biv_student call is REFUSED through engine = "julia"; refusal quoted verbatim, and the same call FITS on engine = "tmb" in the same session
  CHECK: git show origin/main:R/drmTMB.R | grep -c 'the Julia route is deferred' | grep -qx 1 && grep -c 'the Julia route is deferred' R/drmTMB.R | grep -qx 0 && echo RED_BASELINE_RETIRED
  EXPECT: RED_BASELINE_RETIRED
  EVIDENCE: Measured on origin/main source restored into the worktree (R/drmTMB.R, R/julia-bridge.R, R/julia-family-registry.R all `git show origin/main:<path>`), one Rscript session, the exact call shape of tests/testthat/test-biv-student.R (`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, nu = ~1, rho12 = ~1)`, `simulate_biv_student_truth(n = 120, beta1 = c(0.2, 0.45), beta2 = c(-0.3, -0.25), sigma1 = 0.55, sigma2 = 0.85, nu = 7, rho12 = 0.35)`, seed 6401):
    CONTROL, engine = "tmb": `TMB_FIT_OK logLik = -273.1043807510`, coef mu1 (Intercept) 0.2793690 x 0.4136151; mu2 (Intercept) -0.2614600 x -0.1457054; sigma1 -0.6276066; sigma2 -0.1198864; nu 1.934852; rho12 0.2798366. The call is well formed.
    engine = "julia", VERBATIM: "`biv_student()` is implemented only for `engine = \"tmb\"`; the Julia route is deferred."
    Second, independent refusal (registry), VERBATIM: `drm_julia_family_tag("biv_student")` -> "`engine = \"julia\"` currently supports Workflow G fixed-effect families (Gaussian, bivariate Gaussian, Student-t, lognormal, Poisson, NB2, Gamma, Beta, Binomial) and large-p phylogenetic Poisson, NB2, Gamma, Beta, or Binomial models. i Use `engine = \"tmb\"` for other non-Gaussian drmTMB fits until the R bridge has coefficient-scale parity tests."
    Pre-change fe list (14 families, no biv_student): gaussian, biv_gaussian, student, lognormal, poisson, nbinom2, gamma, beta, binomial, truncated_nbinom2, zero_one_beta, tweedie, beta_binomial, cumulative_logit.
    The three files were then restored from HEAD and `git diff --quiet HEAD -- R/` confirmed R_TREE_MATCHES_HEAD_MERGE.

- [x] G2: DRM.jl AT THE PIN — probe DRM.drm_bridge directly with family tag "biv_student"; record whether it routes, and whether any DRM.jl source change is needed
  CHECK: test -f /Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc/src/bivariate_student.jl && grep -q '"biv_student", "student_bivariate", "bivariate_student"' /Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc/src/bridge.jl && test "$(git -C /Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc status --porcelain -- src/ | wc -l | tr -d ' ')" = 0 && echo PIN_ROUTES_UNMODIFIED
  EXPECT: PIN_ROUTES_UNMODIFIED
  EVIDENCE: NO DRM.jl CHANGE NEEDED. Probed at the pin BEFORE any R change, `julia --project=<pin>`:
    `DRM._bridge_family("biv_student")` -> `Student()`  (src/bridge.jl:622 accepts "biv_student", "student_bivariate", "bivariate_student"; bivariate-ness is a FORMULA property in DRM.jl, so the keyed mu1/mu2 parts select src/bivariate_student.jl).
    `DRM.drm_bridge(formula = Dict("mu1"=>"y1 ~ x","mu2"=>"y2 ~ x","sigma1"=>"sigma1 ~ 1","sigma2"=>"sigma2 ~ 1","nu"=>"nu ~ 1","rho12"=>"rho12 ~ 1"), family = "biv_student", data = dat)` -> ROUTED_OK, `converged => true`, 8 coefficients, `loglik => -336.5381977591065` (a Julia-side shape-only draw, not the parity fixture), `dpars => ["mu1","mu2","nu","rho12","sigma1","sigma2"]`.
    The pin clone's `src/` is unmodified; its only dirty files are the two evidence TSVs this leaf appended (G3/G4). No DRM.jl PR was opened and none is needed: pr_number_jl = none.

- [x] G3: SAME-TARGET receipt — engine = "julia" and engine = "tmb" fit the SAME target: coefficients matched BY NAME <= 1e-4 and |dlogLik| <= 1e-4, comparator code from the pin's tools/parity_fixture.R (parity_numeric, tol 1e-4)
  CHECK: awk -F'\t' '$1=="fe_biv_student"{print $3}' /Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc/docs/dev-log/evidence/parity-fixtures.tsv
  EXPECT: PARITY_PASS
  EVIDENCE: Row appended to pin clone docs/dev-log/evidence/parity-fixtures.tsv. Draw = tests/testthat/test-biv-student.R's own `simulate_biv_student_truth`, n = 400, seed 6401, beta1 = c(0.2, 0.45), beta2 = c(-0.3, -0.25), sigma1 = 0.55, sigma2 = 0.85, nu = 7, rho12 = 0.35; formula `bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, nu = ~1, rho12 = ~1)`.
    fe_biv_student | Bivariate Student-t (shared nu), fixed effects | PARITY_PASS | max_abs_coef_diff 3.77097286063943e-07 | loglik_tmb -928.707976349488 | loglik_julia -928.707976349514 | loglik_diff 2.56932253250852e-11 | tolerance 1e-04 | "R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0; all named coefficients compared" (8/8 name-matched).
    coef_tmb   : mu1.(Intercept)=0.254145929 mu1.x=0.4678863951 mu2.(Intercept)=-0.2201389284 mu2.x=-0.2250867294 sigma1.(Intercept)=-0.5896703447 sigma2.(Intercept)=-0.1463055916 nu.(Intercept)=1.635919703 rho12.(Intercept)=0.3512853594
    coef_julia : mu1.(Intercept)=0.254145929 mu1.x=0.4678863951 mu2.(Intercept)=-0.2201389284 mu2.x=-0.2250867294 nu.(Intercept)=1.635919703 rho12.(Intercept)=0.3512849823 sigma1.(Intercept)=-0.5896703447 sigma2.(Intercept)=-0.1463055916
    Note the differing BLOCK ORDER between engines — the comparison is by name, never by position.

- [x] G4: SE receipt — per-coefficient Wald SE agreement at rtol 1e-3 via the pin's tools/parity_se.R comparator, WITH its negative control (one Julia SE inflated 10% must read SE_FAIL)
  CHECK: awk -F'\t' '$2=="se_biv_student"{a=$4} $2=="negative_control_perturbed_biv_student"{b=$4} END{print a" "b}' /Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc/docs/dev-log/evidence/parity-se.tsv
  EXPECT: /^SE_PASS NEGATIVE_CONTROL_OK$/
  EVIDENCE: Rows appended to pin clone docs/dev-log/evidence/parity-se.tsv. Comparator lifted from tools/parity_se.R by evaluating ONLY the assignments of `rtol_se`, `atol_se`, `se_of`, `fmt_vec`, `compare_cell` (the script is not run), so these are that file's comparator numbers; rtol_se = 0.001, atol_se = 1e-08.
    fe_biv_student | se_biv_student | SE_PASS | max_abs_se_diff 2.04553020577425e-07 | max_rel_se_diff 9.01334041867385e-07 | "8 SE(s) compared"
      se_tmb   : mu1_(Intercept)=0.0306736;mu1_x=0.0525244;mu2_(Intercept)=0.0476987;mu2_x=0.0827555;sigma1_(Intercept)=0.0479034;sigma2_(Intercept)=0.0494978;nu_(Intercept)=0.324176;rho12_(Intercept)=0.0561602
      se_julia : mu1_(Intercept)=0.0306736;mu1_x=0.0525244;mu2_(Intercept)=0.0476987;mu2_x=0.0827555;sigma1_(Intercept)=0.0479034;sigma2_(Intercept)=0.0494977;nu_(Intercept)=0.324176;rho12_(Intercept)=0.0561601
    fe_biv_student | negative_control_perturbed_biv_student | NEGATIVE_CONTROL_OK | max_abs_se_diff 0.00306735793919044 | max_rel_se_diff 0.0909089730666066 | "8 SE(s) compared; NEGATIVE CONTROL: se_julia[1] perturbed by +10%" — the comparator returned SE_FAIL, so it can fail.
    drmtmb_code_hash 49985ec0eb413191a86c40a9c74d3a4d0c245c095bf58a91e749c1763aa5c8d6.
    SE agreement between two engines is NOT interval coverage and no coverage claim is made.

- [x] G5: the focused test file is GREEN with NOT_CRAN=true and the live engine, and its live block FAILS (never skips) on a refusal or a DRM.jl abort
  CHECK: NOT_CRAN=true OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc DRM_JL_PHYLO_PATH=/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc Rscript -e 'suppressMessages(devtools::load_all(".", quiet=TRUE)); df <- as.data.frame(testthat::test_file("tests/testthat/test-julia-family-biv_student.R", reporter="silent")); cat(sprintf("FAIL %d SKIP %d PASS %d\n", sum(df$failed), sum(df$skipped), sum(df$passed)))' 2>&1 | grep -E '^FAIL'
  EXPECT: /FAIL 0 SKIP 0 PASS [1-9]/
  EVIDENCE: `FAIL 0 SKIP 0 PASS 54 ERROR 0`, with the reporter line "Julia bridge: 1 live test ran; bridge glue was exercised in this configuration." SKIP 0 is the point: the live round trip actually ran. The live test asserts class drmTMB_julia, model_type "biv_student", engine "julia", converged, nobs 400L, label contract bridge_formula_labels_v1, public labels mu1_(Intercept) mu1_x mu2_(Intercept) mu2_x sigma1_(Intercept) sigma2_(Intercept) nu_(Intercept) rho12_(Intercept), coef-by-name < 1e-4, |dlogLik| < 1e-4, SE rtol < 1e-3, response-scale rho12 and nu agreement < 1e-4, the SHORT bf(mu1, mu2) form reaching the same logLik, confint() deferred, and estimator == DRM.jl estim_method == ML.

- [x] G6: the registry pins move by exactly one family and nothing else; test-julia-family-registry.R green
  CHECK: NOT_CRAN=true Rscript -e 'suppressMessages(devtools::load_all(".", quiet=TRUE)); df <- as.data.frame(testthat::test_file("tests/testthat/test-julia-family-registry.R", reporter="silent")); cat(sprintf("FAIL %d SKIP %d PASS %d\n", sum(df$failed), sum(df$skipped), sum(df$passed)))' 2>&1 | grep -E '^FAIL'
  EXPECT: /FAIL 0 SKIP 0 PASS [1-9]/
  EVIDENCE: `FAIL 0 SKIP 0 PASS 23`. Exactly two pins moved, both by appending "biv_student": drm_julia_registry_families("fe") (14 -> 15 families) and the drm_julia_family_tag() admission loop (13 -> 14 families). No pin deleted. The other five derived lists (phylo_only, locscale_phylo, slope_phylo, dispersionless, structured) are UNCHANGED — verified by the pins themselves and separately asserted in the focused test file, which requires biv_student to be absent from every one of them (in particular NOT dispersionless: this family has sigma1, sigma2 and nu).

- [x] G7: the capability TSV is GENERATED, not hand-edited; regeneration is idempotent and the ledger checker is green
  CHECK: Rscript tools/write-julia-capability-comparison.R >/dev/null 2>&1 && A=$(shasum -a 256 inst/extdata/julia-capabilities.tsv | cut -d' ' -f1) && Rscript tools/write-julia-capability-comparison.R >/dev/null 2>&1 && B=$(shasum -a 256 inst/extdata/julia-capabilities.tsv | cut -d' ' -f1) && [ "$A" = "$B" ] && python3 tools/capability_ledger.py --check
  EXPECT: /capability-ledger: OK/
  EVIDENCE: `wrote 26 Julia capability rows to docs/dev-log/dashboard/julia-capabilities.tsv` / `wrote 26 Julia capability rows to inst/extdata/julia-capabilities.tsv` (25 -> 26 rows: the new `fe_biv_student`). `python3 tools/capability_ledger.py --check` -> `capability-ledger: OK (31 generated outputs)`. The row was added by editing `drm_julia_capability_comparison()` in R/julia-bridge.R across all ten parallel columns; neither TSV was hand-edited. Row: fe_biv_student | base | partial (r_bridge_status) | partial (claim_status) | drmTMB#544.

- [x] G8: RED CONTROLS on the new admission — each planted defect makes the focused test go red, and each file is restored BYTE-IDENTICALLY
  CHECK: git diff --quiet HEAD -- R/ && git status --porcelain | grep -v '^?? \.scratch/' | wc -l | tr -d ' ' | grep -qx 0 && echo TREE_MATCHES_COMMIT
  EXPECT: TREE_MATCHES_COMMIT
  EVIDENCE: Baseline `FAIL 0 SKIP 0 PASS 54 ERROR 0`. Four defects planted one at a time, each restored with `git show HEAD:<path> > <path>`:
    RC1 registry row `spec("biv_student", fe = TRUE)` deleted -> `FAIL 1 SKIP 0 PASS 11 ERROR 4`. sha256 R/julia-family-registry.R before AND after restore = eca20e9ca429510caebdac43be1a6794b664aec3ad27a990fd82d2f89c67b930; RESTORED_BYTE_IDENTICAL.
    RC2 `"nu"` dropped from the biv_student default-label branch -> `FAIL 1 SKIP 0 PASS 34 ERROR 1`. sha256 R/julia-bridge.R before AND after restore = 67f62890bf9b13587e21b3305b6280dbe85f0ba2a5bd1f6e9af66d58f7336ed7; RESTORED_BYTE_IDENTICAL. This is the measurement behind the claim that the `nu` default is genuinely required, not decorative.
    RC3 `drm_julia_refuse_biv_student_beyond_native()` call site removed -> `FAIL 0 SKIP 0 PASS 46 ERROR 1`; RESTORED_BYTE_IDENTICAL.
    RC4 `confint.drmTMB_julia()` biv_student guard removed -> `FAIL 1 SKIP 0 PASS 53 ERROR 0`; RESTORED_BYTE_IDENTICAL.
    Final state re-measured after all restores: `FAIL 0 SKIP 0 PASS 54 ERROR 0`, `git status --porcelain` = `?? .scratch/` only.

- [x] G9: no non-ASCII byte on any ADDED line of the R diff (R CMD check WARNING; CI is error-on=warning)
  CHECK: git diff origin/main -- '*.R' | grep '^+' | LC_ALL=C grep -c '[^\x00-\x7F]' | grep -qx 0 && echo ASCII_CLEAN
  EXPECT: ASCII_CLEAN
  EVIDENCE: Zero non-ASCII bytes on added lines of the R diff (R/drmTMB.R, R/julia-bridge.R, R/julia-family-registry.R, tests/testthat/*.R).

- [x] G10: the neighbouring bridge suites this row can move are green
  CHECK: NOT_CRAN=true OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc DRM_JL_PHYLO_PATH=/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc Rscript -e 'suppressMessages(devtools::load_all(".", quiet=TRUE)); fs <- c("tests/testthat/test-julia-gate-vs-engine.R","tests/testthat/test-julia-fe-only-fence.R","tests/testthat/test-biv-student.R","tests/testthat/test-julia-family-registry.R","tests/testthat/test-julia-family-biv_student.R"); tot <- c(0,0,0); for (f in fs) { df <- as.data.frame(testthat::test_file(f, reporter="silent")); tot <- tot + c(sum(df$failed) + sum(df$error), sum(df$skipped), sum(df$passed)) }; cat(sprintf("FAILERR %d SKIP %d PASS %d\n", tot[1], tot[2], tot[3]))' 2>&1 | grep -E '^FAILERR'
  EXPECT: /FAILERR 0 SKIP [0-9]+ PASS [1-9]/
  EVIDENCE: test-julia-gate-vs-engine.R FAIL 0 SKIP 0 PASS 144; test-julia-fe-only-fence.R FAIL 0 SKIP 1 PASS 182 (its one skip is pre-existing and unrelated); test-biv-student.R FAIL 0 SKIP 0 PASS 67 (68 before, minus the one retired expectation); test-julia-family-registry.R FAIL 0 SKIP 0 PASS 23; test-julia-family-biv_student.R FAIL 0 SKIP 0 PASS 54.
    test-parity-matrix.R is deliberately NOT in this gate: it errors at this pin with "citation anchor not found in docs/design/capability-status.md: Gaussian phylogenetic random intercept + slope, two SDs (mean)". That anchor is a hardcoded `st(...)` line in tools/write-parity-matrix.R (untouched by this leaf) pointing at a DRM.jl document that does not contain the string at 430ef64cc — `grep -c "two SDs" <pin>/docs/design/capability-status.md` returns 0. PRE-EXISTING and unrelated; reported, not fixed here. Its other route-coverage test still skips with the same four pending families as before this leaf (truncated_nbinom2, zero_one_beta, tweedie, cumulative_logit) — biv_student is NOT among them, i.e. its capability row is present.

- [x] G12: the admission did NOT silently widen the family — every shape native engine = "tmb" refuses is refused on the Julia route too
  CHECK: NOT_CRAN=true OPENBLAS_NUM_THREADS=1 Rscript -e 'suppressMessages(devtools::load_all(".", quiet=TRUE)); d <- data.frame(x=rnorm(30), z=rnorm(30), y1=rnorm(30), y2=rnorm(30), g=factor(rep(1:5,6))); bad <- 0; for (f in list(bf(mu1=y1~x+(1|g), mu2=y2~x, sigma1=~1, sigma2=~1, nu=~1, rho12=~1), bf(mu1=y1~x, mu2=y2~x, sigma1=~z, sigma2=~1, nu=~1, rho12=~1), bf(mu1=y1~x, mu2=y2~x, sigma1=~1, sigma2=~1, nu=~z, rho12=~1), bf(mu1=y1~x, mu2=y2~x, sigma1=~1, sigma2=~1, nu=~1, rho12=~z), bf(mu1=y1~x, mu2=y2~x, sigma1=~0+z, sigma2=~1, nu=~1, rho12=~1))) { r <- tryCatch(drmTMB(f, family=biv_student(), data=d, engine="julia"), error=function(e) e); if (!inherits(r, "condition")) bad <- bad + 1 }; cat(if (bad == 0) "FENCE_HOLDS\n" else sprintf("FENCE_LEAKS %d\n", bad))' 2>&1 | grep -E '^FENCE'
  EXPECT: FENCE_HOLDS
  EVIDENCE: THIS GATE EXISTS BECAUSE THE ADMISSION CREATED THE DEFECT. Measured on this branch after the registry row and BEFORE the fence, all through `drmTMB(..., family = biv_student(), engine = "julia")` on an n=200 draw:
    `sigma1 = ~ z`   tmb REFUSED / julia FITTED logLik=-466.43141436
    `rho12 = ~ z`    tmb REFUSED / julia FITTED logLik=-466.39654038
    `nu = ~ z`       tmb REFUSED / julia FITTED logLik=-466.44065444
    `sigma1 = ~ 0+z` tmb REFUSED / julia FITTED logLik=-499.64729260
    `(1 | g)` on mu1 tmb REFUSED with drmTMB's own message / julia REFUSED but only by a raw Julia stack trace from `_split_bivariate_q4_rhs` ("bivariate q=4 structured fits support only `phylo`/`relmat`/`animal`/`spatial(1 | group)` markers, not ordinary random effects") — the wrong route named.
    `confint()`      tmb REFUSED ("interval and profile claims are deferred") / julia RETURNED a 10-row Wald data.frame.
    Cause: the A4.G17 fe-only fence EXEMPTS every `biv_*` tag by prefix, so `fe = TRUE` alone left the family unnarrowed. Native's own message text is the reference, since a shape engine="tmb" refuses has no same-target comparator and can carry no parity receipt.
    After `drm_julia_refuse_biv_student_beyond_native()` + the confint guard, re-measured: all five formula shapes REFUSED on both engines with the native wording, and `confint()` refused identically on both ("`confint()` is not implemented for model type \"biv_student\"; interval and profile claims are deferred"). The fence fires BEFORE Julia is started (proved by running with DRM_JL_PATH unset). It does NOT over-fire: `sigma1 = ~ (1)` is still intercept-only and fits identically on both engines (logLik -466.44449865), and the fence is a no-op for every other family_type.
    NOT shadowed, deliberately: `phylo()` and `relmat()`/`animal()`/`spatial()` were already refused upstream by existing gates whose messages siblings pin by name.

- [x] G11: PR opened against main, NOT merged
  CHECK: gh pr view --json state,baseRefName -q '.state + " " + .baseRefName' 2>/dev/null
  EXPECT: /OPEN main/
  EVIDENCE: PR #1217 opened against main, https://github.com/itchyshin/drmTMB/pull/1217, from branch claude/parity-fam-biv-student at commit e752b3a4c (one squashed commit on top of origin/main eccb10299). NOT MERGED, no --auto, no --admin; the integrator merges in dependency order. No DRM.jl PR was opened -- G2 measured that none is needed at pin 430ef64cc.
