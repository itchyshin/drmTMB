# Overnight truth recovery — 31 "other" unchecked cells

Lane `claude/lane-overnight-0815`, read-only sweep of
`/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit`. Population: the 31 cell IDs listed
under `"other"` in `scratchpad/overnight-unchecked.json`. Goal: recover a numeric `true_parameter_scale`
value for each so its retained profile receipt can be location-checked with zero compute. No R was run;
no bracketing verdict was computed. All 31/31 cells were recovered.

## Headline

**31/31 RECOVERABLE_FROM_CODE. 0 PROSE_ONLY. 0 NOT_RECOVERED.**

Two mechanisms did almost all the work:
1. **5 cells** (`mc-0568/0576/0595/0596/0653`) are in the 2026-08-05 135-trace campaign's
   `all-receipts.tsv`, which carries an explicit numeric `true_value` column per row — no fixture lookup
   needed.
2. **26 cells** are covered by the `docs/dev-log/interval-campaign-bindings/*.tsv` contracts, most of
   which carry an explicit `target_truth` (or `truth`) column. For 18 of those 26 the number is also
   independently derivable from a fixture-builder `.R` constant (quoted below), giving a byte-level
   cross-check against the contract. For the remaining 8 (`mc-0102/0124/0146/0168/0187/0188/0203/0204`)
   the exact-matching source line lives only at an **off-mainline commit** reachable by `git show`, not in
   the current working tree — same pattern the prior recovery lane
   (`docs/dev-log/2026-08-15-runner-provenance-recovery.md`, commit `1dd6f7002`) documented for 96 other
   cells. That prior doc explicitly named `mc-0187/0188/0203/0204` as citing **no `tools/…` runner at
   all** — true for the *profile-execution* runner, but their truth constants are still recoverable from
   the **literal DGP-generating test functions** the contracts cite (`test-biv-gaussian.R`,
   `test-reml-ordinary-sigma.R`), which are present in the working tree now.

## One conflict found, not silently resolved: `mc-0282`

Two different DGPs claim to be `mc-0282`'s truth:
- `docs/dev-log/interval-campaign-bindings/2026-07-31-b2-e0-q2-reml-execution-authorization.tsv` (dgp_id
  `b2_gaussian_phylo_q2_reml_intercept_v1`) says `target_truth = 0.55`. **No receipt exists anywhere on
  disk for this dgp_id** — `grep -rl "b2_gaussian_phylo_q2_reml_intercept_v1" docs/dev-log/` matches only
  three authorization/registry contracts, never a receipt. This authorization was never executed.
- The receipt that **is actually retained on disk**
  (`docs/dev-log/interval-feasibility/results/75b212cf9db45aeb2fa3181049e663e772e01e7a/arc6-profile-feasibility/totoro/mc-0282/mc-0282-arc2_phylo_sigma_q2_fixture-tip60_each12-seed{101,202,303}-receipt.tsv`)
  carries dgp_id `arc2_gaussian_reml_phylo_mu_q2_sd`, `true_parameter_scale = "0.6 phylogenetic
  random-intercept SD on mu..."`, and estimates (0.549, 0.702, 0.593) that bracket **0.6**, not 0.55.
  The source constant is `tools/arc2-phylo-sigma-fixtures.R:138` — `true_sd_mu = 0.6` — in the current
  working tree.

**Use 0.6 for `mc-0282`**, sourced from the receipt that is actually on disk, not the unexecuted 0.55
authorization. Flagging this for the conductor rather than picking silently.

## Per-cell detail

### 135-trace campaign (`true_value` column, zero fixture lookup needed)

| cell | truth | target_id | receipt |
|---|---|---|---|
| mc-0568 | 0.45 | `mc-0568::sd:sigma:(1 \| id)` | `docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/totoro-receipts/mc-0568/` (5 seeds) |
| mc-0576 | 0.45 | `mc-0576::sd:sigma:(0 + x \| id)` | `.../totoro-receipts/mc-0576/` (5 seeds) |
| mc-0595 | 0.45 | `mc-0595::sd:sigma:relmat(1 \| species)` | `.../totoro-receipts/mc-0595/` (5 seeds) |
| mc-0596 | 0.45 | `mc-0596::sd:sigma:spatial(1 \| site)` | `.../totoro-receipts/mc-0596/` (5 seeds) |
| mc-0653 | 0.60 | `mc-0653::sd:sigma:phylo_interaction(1 \| plant:pollinator)` | `.../totoro-receipts/mc-0653/` (5 seeds) |

Source: `docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/all-receipts.tsv` column
`true_value`, joined on `cell_id` (all 5 have `verdict=PASS` in the companion `CELL-VERDICTS.tsv`).

### q6 all-component highinfo cohort (phylo/spatial/animal/relmat mu2)

`mc-0102`, `mc-0124`, `mc-0146`, `mc-0168` all resolve to **truth = 0.40** (the `mu2` component).

- Contract: `docs/dev-log/interval-campaign-bindings/2026-07-31-b2-q6-q12-admission-registry.tsv` and 8
  sibling files carry `truth_scale=latent_log_sd`, `target_truth=0.4`, and a full joint-DGP breakdown
  `joint_dgp_truth = "mu1=(0.45,0.30,0.25);mu2=(0.40,0.28,0.22);residual=(0.45,0.40);rho12=0"`.
- Code (off-mainline; not in current working tree — reachable only via
  `git show dc62878e6:tools/b2-q6-q12-admission-contracts.R`): line 66,
  `truth <- c(mu1 = .45, mu2 = .40, sigma1 = .30, sigma2 = .28)`, matched to each cell via
  `x$target_truth <- unname(truth[x$dpar])` where all four cells have `dpar = "mu2"`. This is the exact
  fixture (`b2_q6q12_fixture`) that `tools/run-b2-q6-proof-profile.R` (working tree, `af2454d95`) sources
  to produce the retained receipts below — byte-exact match confirmed against the retained receipt
  estimates (0.4546, 0.4800, …, all bracketing 0.40).
- Receipts: `docs/dev-log/interval-feasibility/results/a8d068e641105473b3f30723a92c909467a46fac/b2-q6-proof-profile/{mc-0102,mc-0124,mc-0146,mc-0168}/*-receipt.tsv`.

### Animal q2 slope high-information pair

| cell | truth | source |
|---|---|---|
| mc-0131 | 1.05 | `tools/lane-b-animal-q2-slope-highinfo-adapters.R:19` — `truth = c(1.05, 0.90)` (working tree) |
| mc-0132 | 0.90 | same line, second element |

Contract cross-check: `docs/dev-log/interval-campaign-bindings/2026-07-29-animal-q2-slope-high-information-canonical-contracts.tsv`
(`truth` column = 1.05 / 0.90). Receipts:
`docs/dev-log/interval-feasibility/results/2753715655866a064cd2b27ffb7eaf2226216c36/q2-animal-slope-highinfo/{mc-0131,mc-0132}/*-receipt.tsv`.

### Ordinary bivariate scale/sigma intercepts (the 4 cells the prior recovery flagged as "no runner")

| cell | truth (link/log scale) | source |
|---|---|---|
| mc-0187 | `log(0.38)` = -0.967584026261706 | `tests/testthat/test-biv-gaussian.R:802` — `alpha1 <- c(\`(Intercept)\` = log(0.38), w1 = 0.45)` |
| mc-0188 | `log(0.52)` = -0.653926467406664 | `tests/testthat/test-biv-gaussian.R:803` — `alpha2 <- c(\`(Intercept)\` = log(0.52), w2 = -0.35)` |
| mc-0203 | 0.40 | `tests/testthat/test-reml-ordinary-sigma.R:112` — `Ss <- chol(matrix(c(.4^2, .3*.4*.35, .3*.4*.35, .35^2), 2, 2))` |
| mc-0204 | 0.35 | same line, second diagonal entry |

Both source files are in the working tree now (confirmed by direct `Read`, no `git show` needed). The
numeric values are byte-exact against the campaign contracts'
`docs/dev-log/interval-campaign-bindings/2026-07-29-ordinary-biv-scale-intercept-source-contracts.tsv`
(`target_truth = -0.967584026261706` / `-0.653926467406664`) and
`2026-07-29-ordinary-biv-sigma-re-intercept-source-contracts.tsv` (`target_truth = 0.4` / `0.35`). The
prior recovery doc's "no runner" finding is about the *profile-execution* runner (none cited, so nothing
to re-run) — it does not mean the DGP truth is unrecoverable; the DGP is a literal fixture in an
existing, in-tree test file (`binding_source` column names it directly), not a simulation campaign
script. Receipts:
`docs/dev-log/interval-feasibility/results/0c1f39d86a37d029a404e31a0d05f7775575e683/ordinary-biv-scale-intercept/{mc-0187,mc-0188}/*-receipt.tsv`,
`docs/dev-log/interval-feasibility/results/9a13f79bcc1d1a1154e754fff7fa394fc3d62020/ordinary-biv-sigma-re-intercept/{mc-0203,mc-0204}/*-receipt.tsv`.

### Phylo dense q4 high-information cohort

| cell | truth | component |
|---|---|---|
| mc-0216 | 0.5 | mu1 |
| mc-0217 | 0.5 | mu2 |
| mc-0218 | 0.4 | sigma1 |
| mc-0219 | 0.4 | sigma2 |

Code (off-mainline; not in current working tree — reachable only via
`git show 5f4a72b74:tools/lane-b-phylo-q4-dense-highinfo-adapters.R`): line 20,
`truth = c(.5, .5, .4, .4)`. `tools/run-lane-b-phylo-dense-q4-highinfo-profile-gate.R` (working tree)
sources this adapter and writes `target_truth = row$truth` straight into the receipt. Contract
cross-check: `docs/dev-log/interval-campaign-bindings/2026-07-29-phylo-dense-q4-high-information-canonical-contracts.tsv`
(`truth` column = 0.5/0.5/0.4/0.4, exact match). Receipts:
`docs/dev-log/interval-feasibility/results/5f4a72b745fba24129633f549b3a410f9cbafd2f/phylo-dense-q4-highinfo/{mc-0216,mc-0217,mc-0218,mc-0219}/*-receipt.tsv`.

### B2 majority Gaussian q2 slope cohort (phylo/spatial/animal/relmat, mu+sigma pairs)

| cell | truth | provider · component |
|---|---|---|
| mc-0280 | 0.45 | phylo · mu slope |
| mc-0281 | 0.30 | phylo · sigma slope |
| mc-0293 | 0.45 | spatial · mu slope |
| mc-0294 | 0.30 | spatial · sigma slope |
| mc-0305 | 0.45 | animal · mu slope |
| mc-0306 | 0.30 | animal · sigma slope |
| mc-0317 | 0.45 | relmat · mu slope |
| mc-0318 | 0.30 | relmat · sigma slope |

Code (working tree): `tools/b2-majority-gaussian-q2-fixtures.R:51` —
`target_truth <- if ("target_truth" %in% names(row)) as.numeric(row$target_truth[[1L]]) else if
(grepl("^sd:mu", profile_parameter)) .45 else .30`. Contract row supplies `target_truth` explicitly (so
the `if` branch is taken, not the fallback), matching the fallback anyway: exact double confirmation.
Contract: `docs/dev-log/interval-campaign-bindings/2026-07-30-b2-majority-high-q2-slope-8-contract.tsv`
(all 8 rows, `target_truth` column). Receipts:
`docs/dev-log/interval-feasibility/results/fac36c37def62b6741e762da907a7694f1eb42d9/b2-e0-q2-high/{mc-0280,mc-0281,mc-0293,mc-0294,mc-0305,mc-0306,mc-0317,mc-0318}/*-receipt.tsv`.

### mc-0282 (see conflict section above)

**Use truth = 0.6**, source `tools/arc2-phylo-sigma-fixtures.R:138` — `true_sd_mu = 0.6` (working tree).
Do not use the 0.55 figure in `2026-07-31-b2-e0-q2-reml-execution-authorization.tsv`; that authorization
was never executed (no matching receipt exists anywhere under `docs/dev-log/`).

### Scalar animal/relmat q1 high-information cohort

| cell | truth | source |
|---|---|---|
| mc-0297 | 0.65 | contract `target_truth`; corroborated by `tests/testthat/test-animal-relmat-gaussian.R:12` — `sd_known <- 0.65` inside `new_known_relatedness_gaussian_data()`, the base fixture this campaign scales up (n=8→32) |
| mc-0300 | 0.30 | contract `target_truth` only — see caveat below |
| mc-0312 | 0.30 | contract `target_truth` only — see caveat below |

Contract: `docs/dev-log/interval-campaign-bindings/2026-07-29-scalar-animal-relmat-q1-highinfo-contracts.tsv`,
columns `target_truth` and `binding_source`. **Caveat for mc-0300/mc-0312:** the `binding_source` column
cites `tests/testthat/test-animal-relmat-gaussian.R:517-575`, but the sigma-scale constant actually
defined there (`new_known_location_scale_gaussian_data()`, `sd_known = c(mu = 0.35, sigma = 0.16)`) is
**0.16, not 0.30** — the citation names the right *class* of test but not an exact-matching constant. No
`.R` file anywhere in `git log --all` ever references the campaign's own dgp_id
(`gaussian_scalar_0300_highinfo_n32` / `gaussian_scalar_0312_highinfo_n32`); the "highinfo_n32" fixture
script that actually produced these receipts does not exist in this repo's history under a
grep-discoverable name. Classified `RECOVERABLE_FROM_CODE` on the strength of the frozen contract's
`target_truth` field alone, cross-checked only by the retained trace: estimate 0.2766, CI
`[0.1998, 0.3845]`, which brackets 0.30 (not 0.16) — supporting 0.30 as correct over the unrelated 0.16.
Receipts (trace only, no `receipt.tsv` summary on disk):
`docs/dev-log/interval-feasibility/results/48a16f5180907bc7c8b3e060537fcf09b4c97d1f/scalar-animal-relmat-q1-highinfo/{mc-0297,mc-0300,mc-0312}/*-trace.tsv`.

## Machine-readable summary

```tsv
cell_id	class	truth_value	source_file:line	receipt_path
mc-0568	RECOVERABLE_FROM_CODE	0.45	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/all-receipts.tsv:true_value_col	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/totoro-receipts/mc-0568/
mc-0576	RECOVERABLE_FROM_CODE	0.45	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/all-receipts.tsv:true_value_col	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/totoro-receipts/mc-0576/
mc-0595	RECOVERABLE_FROM_CODE	0.45	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/all-receipts.tsv:true_value_col	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/totoro-receipts/mc-0595/
mc-0596	RECOVERABLE_FROM_CODE	0.45	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/all-receipts.tsv:true_value_col	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/totoro-receipts/mc-0596/
mc-0653	RECOVERABLE_FROM_CODE	0.60	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/all-receipts.tsv:true_value_col	docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/totoro-receipts/mc-0653/
mc-0102	RECOVERABLE_FROM_CODE	0.40	tools/b2-q6-q12-admission-contracts.R:66 (git show dc62878e6, off-mainline)	docs/dev-log/interval-feasibility/results/a8d068e641105473b3f30723a92c909467a46fac/b2-q6-proof-profile/mc-0102/b2-q6-proof-mc-0102-high-seed-20260731-receipt.tsv
mc-0124	RECOVERABLE_FROM_CODE	0.40	tools/b2-q6-q12-admission-contracts.R:66 (git show dc62878e6, off-mainline)	docs/dev-log/interval-feasibility/results/a8d068e641105473b3f30723a92c909467a46fac/b2-q6-proof-profile/mc-0124/b2-q6-proof-mc-0124-high-seed-20260731-receipt.tsv
mc-0146	RECOVERABLE_FROM_CODE	0.40	tools/b2-q6-q12-admission-contracts.R:66 (git show dc62878e6, off-mainline)	docs/dev-log/interval-feasibility/results/a8d068e641105473b3f30723a92c909467a46fac/b2-q6-proof-profile/mc-0146/b2-q6-proof-mc-0146-high-seed-20260731-receipt.tsv
mc-0168	RECOVERABLE_FROM_CODE	0.40	tools/b2-q6-q12-admission-contracts.R:66 (git show dc62878e6, off-mainline)	docs/dev-log/interval-feasibility/results/a8d068e641105473b3f30723a92c909467a46fac/b2-q6-proof-profile/mc-0168/b2-q6-proof-mc-0168-high-seed-20260731-receipt.tsv
mc-0131	RECOVERABLE_FROM_CODE	1.05	tools/lane-b-animal-q2-slope-highinfo-adapters.R:19	docs/dev-log/interval-feasibility/results/2753715655866a064cd2b27ffb7eaf2226216c36/q2-animal-slope-highinfo/mc-0131/lane-b-animal-q2-slope-profile-mc-0131-sd-mu-mu1-animal-0-x-p-id--high-seed-2026072901-receipt.tsv
mc-0132	RECOVERABLE_FROM_CODE	0.90	tools/lane-b-animal-q2-slope-highinfo-adapters.R:19	docs/dev-log/interval-feasibility/results/2753715655866a064cd2b27ffb7eaf2226216c36/q2-animal-slope-highinfo/mc-0132/lane-b-animal-q2-slope-profile-mc-0132-sd-mu-mu2-animal-0-x-p-id--high-seed-2026072901-receipt.tsv
mc-0187	RECOVERABLE_FROM_CODE	-0.967584026261706	tests/testthat/test-biv-gaussian.R:802	docs/dev-log/interval-feasibility/results/0c1f39d86a37d029a404e31a0d05f7775575e683/ordinary-biv-scale-intercept/mc-0187/lane-b-ordinary-biv-scale-intercept-profile-mc-0187-high-n120-each12-seed-2026051306-receipt.tsv
mc-0188	RECOVERABLE_FROM_CODE	-0.653926467406664	tests/testthat/test-biv-gaussian.R:803	docs/dev-log/interval-feasibility/results/0c1f39d86a37d029a404e31a0d05f7775575e683/ordinary-biv-scale-intercept/mc-0188/lane-b-ordinary-biv-scale-intercept-profile-mc-0188-high-n120-each12-seed-2026051306-receipt.tsv
mc-0203	RECOVERABLE_FROM_CODE	0.40	tests/testthat/test-reml-ordinary-sigma.R:112	docs/dev-log/interval-feasibility/results/9a13f79bcc1d1a1154e754fff7fa394fc3d62020/ordinary-biv-sigma-re-intercept/mc-0203/lane-b-ordinary-biv-sigma-re-intercept-profile-mc-0203-source-n40-each8-seed-2-receipt.tsv
mc-0204	RECOVERABLE_FROM_CODE	0.35	tests/testthat/test-reml-ordinary-sigma.R:112	docs/dev-log/interval-feasibility/results/9a13f79bcc1d1a1154e754fff7fa394fc3d62020/ordinary-biv-sigma-re-intercept/mc-0204/lane-b-ordinary-biv-sigma-re-intercept-profile-mc-0204-source-n40-each8-seed-2-receipt.tsv
mc-0216	RECOVERABLE_FROM_CODE	0.5	tools/lane-b-phylo-q4-dense-highinfo-adapters.R:20 (git show 5f4a72b74, off-mainline)	docs/dev-log/interval-feasibility/results/5f4a72b745fba24129633f549b3a410f9cbafd2f/phylo-dense-q4-highinfo/mc-0216/lane-b-phylo-dense-q4-mc-0216-seed-202-receipt.tsv
mc-0217	RECOVERABLE_FROM_CODE	0.5	tools/lane-b-phylo-q4-dense-highinfo-adapters.R:20 (git show 5f4a72b74, off-mainline)	docs/dev-log/interval-feasibility/results/5f4a72b745fba24129633f549b3a410f9cbafd2f/phylo-dense-q4-highinfo/mc-0217/lane-b-phylo-dense-q4-mc-0217-seed-202-receipt.tsv
mc-0218	RECOVERABLE_FROM_CODE	0.4	tools/lane-b-phylo-q4-dense-highinfo-adapters.R:20 (git show 5f4a72b74, off-mainline)	docs/dev-log/interval-feasibility/results/5f4a72b745fba24129633f549b3a410f9cbafd2f/phylo-dense-q4-highinfo/mc-0218/lane-b-phylo-dense-q4-mc-0218-seed-202-receipt.tsv
mc-0219	RECOVERABLE_FROM_CODE	0.4	tools/lane-b-phylo-q4-dense-highinfo-adapters.R:20 (git show 5f4a72b74, off-mainline)	docs/dev-log/interval-feasibility/results/5f4a72b745fba24129633f549b3a410f9cbafd2f/phylo-dense-q4-highinfo/mc-0219/lane-b-phylo-dense-q4-mc-0219-seed-202-receipt.tsv
mc-0280	RECOVERABLE_FROM_CODE	0.45	tools/b2-majority-gaussian-q2-fixtures.R:51	docs/dev-log/interval-feasibility/results/fac36c37def62b6741e762da907a7694f1eb42d9/b2-e0-q2-high/mc-0280/b2-e0-q2-mc-0280-high-seed-2026072932-receipt.tsv
mc-0281	RECOVERABLE_FROM_CODE	0.30	tools/b2-majority-gaussian-q2-fixtures.R:51	docs/dev-log/interval-feasibility/results/fac36c37def62b6741e762da907a7694f1eb42d9/b2-e0-q2-high/mc-0281/b2-e0-q2-mc-0281-high-seed-2026072932-receipt.tsv
mc-0282	RECOVERABLE_FROM_CODE	0.60	tools/arc2-phylo-sigma-fixtures.R:138 (conflicts with unexecuted 0.55 authorization — see note)	docs/dev-log/interval-feasibility/results/75b212cf9db45aeb2fa3181049e663e772e01e7a/arc6-profile-feasibility/totoro/mc-0282/mc-0282-arc2_phylo_sigma_q2_fixture-tip60_each12-seed101-receipt.tsv
mc-0293	RECOVERABLE_FROM_CODE	0.45	tools/b2-majority-gaussian-q2-fixtures.R:51	docs/dev-log/interval-feasibility/results/fac36c37def62b6741e762da907a7694f1eb42d9/b2-e0-q2-high/mc-0293/b2-e0-q2-mc-0293-high-seed-2026072935-receipt.tsv
mc-0294	RECOVERABLE_FROM_CODE	0.30	tools/b2-majority-gaussian-q2-fixtures.R:51	docs/dev-log/interval-feasibility/results/fac36c37def62b6741e762da907a7694f1eb42d9/b2-e0-q2-high/mc-0294/b2-e0-q2-mc-0294-high-seed-2026072935-receipt.tsv
mc-0297	RECOVERABLE_FROM_CODE	0.65	docs/dev-log/interval-campaign-bindings/2026-07-29-scalar-animal-relmat-q1-highinfo-contracts.tsv:target_truth (corroborated tests/testthat/test-animal-relmat-gaussian.R:12)	docs/dev-log/interval-feasibility/results/48a16f5180907bc7c8b3e060537fcf09b4c97d1f/scalar-animal-relmat-q1-highinfo/mc-0297/lane-b-scalar-q1-highinfo-mc-0297-n32-each20-seed-2026072903-trace.tsv
mc-0300	RECOVERABLE_FROM_CODE	0.30	docs/dev-log/interval-campaign-bindings/2026-07-29-scalar-animal-relmat-q1-highinfo-contracts.tsv:target_truth (no exact-matching fixture .R found; see caveat)	docs/dev-log/interval-feasibility/results/48a16f5180907bc7c8b3e060537fcf09b4c97d1f/scalar-animal-relmat-q1-highinfo/mc-0300/lane-b-scalar-q1-highinfo-mc-0300-n32-each20-seed-2026072903-trace.tsv
mc-0305	RECOVERABLE_FROM_CODE	0.45	tools/b2-majority-gaussian-q2-fixtures.R:51	docs/dev-log/interval-feasibility/results/fac36c37def62b6741e762da907a7694f1eb42d9/b2-e0-q2-high/mc-0305/b2-e0-q2-mc-0305-high-seed-2026072937-receipt.tsv
mc-0306	RECOVERABLE_FROM_CODE	0.30	tools/b2-majority-gaussian-q2-fixtures.R:51	docs/dev-log/interval-feasibility/results/fac36c37def62b6741e762da907a7694f1eb42d9/b2-e0-q2-high/mc-0306/b2-e0-q2-mc-0306-high-seed-2026072937-receipt.tsv
mc-0312	RECOVERABLE_FROM_CODE	0.30	docs/dev-log/interval-campaign-bindings/2026-07-29-scalar-animal-relmat-q1-highinfo-contracts.tsv:target_truth (no exact-matching fixture .R found; see caveat)	docs/dev-log/interval-feasibility/results/48a16f5180907bc7c8b3e060537fcf09b4c97d1f/scalar-animal-relmat-q1-highinfo/mc-0312/lane-b-scalar-q1-highinfo-mc-0312-n32-each20-seed-2026072903-trace.tsv
mc-0317	RECOVERABLE_FROM_CODE	0.45	tools/b2-majority-gaussian-q2-fixtures.R:51	docs/dev-log/interval-feasibility/results/fac36c37def62b6741e762da907a7694f1eb42d9/b2-e0-q2-high/mc-0317/b2-e0-q2-mc-0317-high-seed-2026072939-receipt.tsv
mc-0318	RECOVERABLE_FROM_CODE	0.30	tools/b2-majority-gaussian-q2-fixtures.R:51	docs/dev-log/interval-feasibility/results/fac36c37def62b6741e762da907a7694f1eb42d9/b2-e0-q2-high/mc-0318/b2-e0-q2-mc-0318-high-seed-2026072939-receipt.tsv
```
