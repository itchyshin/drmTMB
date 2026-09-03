# Decision map — true R<->Julia parity (drmTMB half), 2026-09-02

A map, not a build plan: it holds what is decided, what is still fog, and what is out. When
nothing is left to decide it collapses into the slice table of the true-parity ultra-plan.
Owner: Ada (Claude lane). Twin counterpart: DRM.jl `docs/dev-log/plans/2026-08-28-v1.0-roadmap.md`.

## Destination

When this effort is done: every capability row admissible under D-179/D-181 is `covered` on
`inst/extdata/julia-capabilities.tsv` with same-target point AND SE receipts on both engines;
`engine = "julia"` shows a user exactly the coefficient names `engine = "tmb"` shows, verified by
DRM.jl#467's construct suite at 7/7; a cross-engine dispute is settled by committed functions on
both sides (`objective_at()` in R, `reml_objective_at` in Julia, bridged); the promotion bar
(experimental → partial on the bridge axis) has been applied with owner sign-off to every row
that has receipts; and drmTMB states in one visible place what it does not cover (intervals:
capability parity, not coverage; `mi()`: R-only for v1.0; cross-family: permanent boundary).
Releases and registration are separate owner ceremonies (D-164, D-183).

## Decisions so far

- D-179 (2026-08-27): gradient criterion 1e-6; `gaussian_response_mask` experiment → promoted;
  `cross_family_latent` permanent boundary; interval fences permanent; #471 deferred; v0.1.0 tag rule.
- D-181 (2026-08-28): `mi()` fenced for v1.0; intervals permanent-permanent; #471 Student-only out;
  Julia General registration OPEN.
- D-183 (2026-08-28): twin versioning, v0.7.0 tagged unregistered.
- 2026-09-02 (this lane, D-202): push all 18; #1112 first; `cov.fixed` conditioning and the
  unpenalized `objective_at()` convention confirmed; base-R naming authority.
- DRM.jl#575 mechanism: finite-difference gradient noise at `g_tol`; fixed by an exact REML
  gradient (DRM.jl PR #579, owned by the DRM.jl lane).
- **Relayed 2026-09-02 (Shinichi via session DRM.jl3, recorded there as vault D-203; treated here as
  decided, cross-checked against D-202):** (1) true parity is **one-directional** for this arc
  (R → Julia); the reverse gap becomes a drmTMB *issue list*, not work. (2) Promotion sign-off =
  a Rose-scanned DRAFT PR plus Shinichi's merge; no per-row sentence. (3) The remaining DRM.jl-side
  slices, including the Julia half of the label contract, belong to the **Codex #563 lane**; the
  Claude DRM.jl lane writes that Codex handover and points it at design 258 §7. (4) `src/` edits in
  DRM.jl are approved PR-gated (RED test first, Noether + Rose review, owner merges).
- **Measured 2026-09-02 (cells.tsv read for the board-row ticket):** DRM.jl's `Non-Gaussian
  phylogenetic location-scale (μ + log σ)` row is implemented there (DRM.jl #202). drmTMB's native
  ledger has `dpar = sigma`, `structure_provider = phylo` **implemented** for exactly two non-Gaussian
  families — `nbinom2` (interval_feasible) and `zero_one_beta` (point_fit_recovery) — and
  `rejected_by_design` for beta, beta_binomial, gamma, hurdle_nbinom2, lognormal, skew_normal,
  student, truncated_nbinom2, tweedie, zi_nbinom2. So on drmTMB's board the row is **scope-limited**
  (unprojected today, not rejected). No TSV or board row is edited by this map; projecting it is a
  D1-style board landing for a later slice.
- Measured 2026-09-02: `parity_ledger.py --ref origin/main` = CLOSURE PASS (10 covered, 1 partial
  by design, 1 unsupported = the engine-control row #1112 supplies).

## Not yet specified (the fog)

| ticket | kind | default if "use your judgment" |
|---|---|---|
| ~~Is true parity one- or two-directional?~~ **CLOSED (D-204, Shinichi direct, 2026-09-02): BOTH WAYS for user-facing capabilities as the standing rule; D-203's one-directional scope was one arc.** Reverse-gap issues FILED: #1115 heritability/icc/repeatability · #1116 chibar_pvalue/lrt_boundary · #1117 aicc + model comparison · #1118 coevolution accessors. Engine-internal exports (bias_correct, bootstrap_sigma_a, profile_sigma_a, sd/sd_phylo, fit_coevolution*, simulate_coevolution) stay accounted for in writing. | — | — |
| ~~Non-Gaussian phylo location-scale board row~~ **CLOSED by measurement (above): scope-limited on drmTMB (nbinom2, zero_one_beta implemented; ten families rejected by design).** Remaining task: project it onto `docs/design/capability-status.md` with that status. | task | a D1-style board landing |
| ~~Promotion authority~~ **CLOSED (D-203): Rose-scanned draft PR + owner merge.** | — | — |
| Student-t `nu` start labels; `vcov()` abort when `sdreport` fails; and (found 2026-09-02 by A5) `objective_at()`/`start=` labels do not reach `biv_gaussian`'s `rho12` or the q4 phylo covariance block: widen or record as limitations? | decide-with-Shinichi (not blocking) | record; widen in an A2/A3 follow-up slice |
| ~~Legacy predict-time `gsub()` rewrite~~ **CLOSED (D-204): KEEP it**, scoped to the structured/joint/xfam routes until their payload builders adopt `coef_labels` (design 258 §7.4). | — | — |
| ~~Echo or reconstruct?~~ **CLOSED (D-203): echo.** DRM.jl already emits `coef_label_contract = "bridge_formula_labels_v1"` (`src/bridge.jl:1276`); the Codex #563 lane changes its content to payload-supplied names, PR-gated. | — | — |
| The DRM.jl fixture's `rtol_coef = 10%` is flagged unjustified pending a drmTMB Wald-SE refit on biv-q4-phylo-reml (DRM.jl lane, 2026-09-02). | task = slice S4 here | receipt path sent to the DRM.jl lane |


**Tension to settle (recorded, not resolved; both answers are RELAYED by sibling sessions on
2026-09-02):** for drmTMB, Shinichi told the DRM.jl session *"one-directional for this arc"*
(D-203). For gllvmTMB he told that session *"both ways, for user-facing capabilities"* — R ports
the models a user would miss that the Julia twin added first; engine-internal Julia-only features
are accounted for in writing; the bridge stays one-way (R calls Julia). The gllvmTMB session marks
its rule inherited-by-analogy, not a drmTMB decision. The two are consistent if read as
*scope-of-arc* vs *standing principle*: this arc stays one-directional, and the reverse-gap issue
list should split into **user-facing** (candidates: `heritability`/`icc`/`repeatability`,
`chibar_pvalue`/`lrt_boundary`, `aicc`) versus **engine-internal** (`coevolution_*` solvers,
`bias_correct`, `profile_sigma_a`) so a later arc can port the first group without re-deciding.
**Resolved 2026-09-02 (D-204):** Shinichi confirmed the reading — both ways for user-facing capabilities is the standing rule; one-way was the scope of the DRM.jl arc.

## Out of scope (with the reason)

- Native mixed-family bivariate in TMB — ARC E scout: a new integration path (Gauss–Hermite or a
  new random-effect axis), and D-179 #3 made the row a permanent boundary.
- Interval coverage campaigns — D-181 #2.
- `mi()` in Julia — D-181 #1.
- `biv_student` structured markers — D-181 #3.
- CRAN submission and Julia General registration — D-164, D-181 #4.
- Any edit under `/Users/z3437171/Dropbox/Github Local/DRM.jl` — a live foreign lane.
