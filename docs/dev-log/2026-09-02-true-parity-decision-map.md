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
- Measured 2026-09-02: `parity_ledger.py --ref origin/main` = CLOSURE PASS (10 covered, 1 partial
  by design, 1 unsupported = the engine-control row #1112 supplies).

## Not yet specified (the fog)

| ticket | kind | default if "use your judgment" |
|---|---|---|
| Is true parity ONE-directional (R workflows reachable in Julia — the programme's definition) or TWO-directional (DRM.jl's `chibar_pvalue`, `lrt_boundary`, `heritability`/`icc`/`repeatability`, `aicc`, coevolution accessors also owed to drmTMB)? | decide-with-Shinichi | one-directional for this arc; file the reverse gap as drmTMB issues |
| DRM.jl's board lists `Non-Gaussian phylogenetic location-scale (mu + log sigma)`; drmTMB's board does not. Implemented, rejected, or merely unprojected? | task (read `cells.tsv`), then decide | project the ledger's answer; assert nothing until read |
| Promotion authority: is a Rose-scanned draft PR sufficient, or does each row need Shinichi's sentence? | decide-with-Shinichi | draft PR; the owner's merge is the sign-off |
| Student-t `nu` start labels; `vcov()` abort when `sdreport` fails: widen or record as limitations? | decide-with-Shinichi (not blocking) | record |
| Does DRM.jl echo the label map (payload names → `bridge_formula_labels_v1`) or does drmTMB reconstruct it? | research, DRM.jl lane's hands (`src/bridge.jl`) | echo (design 258 §3 forbids guessing on the R side) |
| The DRM.jl fixture's `rtol_coef = 10%` is flagged unjustified pending a drmTMB Wald-SE refit on biv-q4-phylo-reml (DRM.jl lane, 2026-09-02). | task = slice S4 here | receipt path sent to the DRM.jl lane |

## Out of scope (with the reason)

- Native mixed-family bivariate in TMB — ARC E scout: a new integration path (Gauss–Hermite or a
  new random-effect axis), and D-179 #3 made the row a permanent boundary.
- Interval coverage campaigns — D-181 #2.
- `mi()` in Julia — D-181 #1.
- `biv_student` structured markers — D-181 #3.
- CRAN submission and Julia General registration — D-164, D-181 #4.
- Any edit under `/Users/z3437171/Dropbox/Github Local/DRM.jl` — a live foreign lane.
