# Twin/Sister Exchange Log

This log implements the daily exchange protocol from #437 and the sprint epic
#436. It is a working ledger, not a claim that any sister-repo result has been
validated in `drmTMB`.

## Protocol

For each workday with active `drmTMB` development, spend 20-30 minutes on a
bounded scout pass before implementation work. Record one compact lesson card
per relevant source:
This log closes the first #437 exchange protocol. Its purpose is to let
`drmTMB` learn from `DRM.jl`, `gllvmTMB`, `GLLVM.jl`, and benchmark sidecars
without turning sister-package speed, coverage, convergence, or implementation
claims into `drmTMB` evidence.

## Protocol

Each scout card should record:

- source repo and local path;
- branch and short commit;
- observed pattern or problem;
- applicability to `drmTMB`;
- proposed action;
- provenance or licensing risk;
- comment status.

Leave a comment or issue in a sibling repo only when there is concrete
evidence: file path, behavior, failing command, missing test, design mismatch,
or a reusable implementation pattern. Mirror replies back here or in #437 with
an explicit accept, decline, or defer decision.

## First Scout: 2026-05-30

| Source | State | Observed pattern | drmTMB action | Risk and comment status |
| --- | --- | --- | --- | --- |
| `DRM.jl` at `/Users/z3437171/Dropbox/Github Local/DRM.jl` | `phase-0-team-workflows`, commit `31a2260`, dirty with many new workflow/docs files | The digital twin uses an issue-led work ledger, explicit formula parity with `drmTMB`, Workflow Q, and a Pólya scouting role. The scout also found a naming mismatch: `AGENTS.md` says `meta_V()` while `report/DRM-architecture.md` still says `meta_known_V(V = V)`. The maintainer confirmed that `meta_known_V()` is deprecated and `meta_V(V = V)` is the current spelling. | Adopt the daily exchange routine in #437 and keep any future R-Julia bridge as a separate design issue. | MIT/GPL boundary matters. Comment left as `DRM.jl` issue #1, with the maintainer correction added. |
| `GLLVM.jl` at `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` | `docs-vitepress-site...origin/docs-vitepress-site`, commit `0601d64`, clean | The Julia twin uses engine-quality gates: finite-difference checks, R parity, JET, Allocs, Aqua, and multi-shape tests before claims. | Use the same gate language for `DRM.jl`-inspired `drmTMB` benchmark or parity issues, but keep claims package-specific. | No code copied. No comment left. |
| `gllvmTMB` at `/Users/z3437171/Dropbox/Github Local/gllvmTMB` | `main...origin/main [behind 105]`, commit `9dcac03`, clean | The sister package keeps higher-dimensional multivariate GLLVM work in a separate scope and uses a short live roadmap plus issue/reset discipline. | Keep high-dimensional latent-variable ideas out of `drmTMB`; borrow only the live-ledger discipline for #436-#444. | Local checkout is behind origin, so refresh before citing current status. No comment left. |
| `GLLVM.jl` older local checkout at `/Users/z3437171/Dropbox/Github Local/gllvmTMB.jl` | `main...origin/main`, commit `6a0d090`, clean | This is not a separate package; it is an older local checkout path for `GLLVM.jl`. It records PPCA starts, profile-out ideas, bootstrap/profile intervals, and structure-aware linear algebra as speed and inference levers. The older checkout also has `CLAUDE.md` test guidance that conflicts with the newer `GLLVM.jl` AGENTS quality-battery wording. | Treat PPCA starts, `sigma ~ 1` profile-out, and bootstrap/profile rescue paths as candidate future design issues for `drmTMB`, not immediate code changes. | MIT licensed. Comment left as `GLLVM.jl` issue #14, with the package-name correction added. |
| `gllvmTMB-julia-bench` at `/Users/z3437171/Dropbox/Github Local/gllvmTMB-julia-bench` | `main`, commit `9de254a`, dirty with many generated scripts/results | The benchmark report contains useful speed and ADEMP-equivalence patterns, but the checkout is dirty and benchmark-specific. The scout also found public docs that still mention a private `~/.claude` plan path and old stage wording. | Use it only as hypothesis and benchmark-design inspiration until a clean source state and `drmTMB`-specific artifacts exist. | GPL-3 in `DESCRIPTION`, no Git remote in this checkout, and dirty state means internal evidence only. No comment left because there is no configured remote. |

## First drmTMB Problem Noted

The sprint setup found stale current-status wording in the Phase 6c roadmap:
the early Phase 6c paragraph still said `phylo(1 + x | species, tree = tree)`
did not fit, while later roadmap rows, formula grammar, tests, and structural
parity notes record the first phylogenetic, animal-model, and `relmat()`
one-slope Gaussian `mu` paths as fitted. This was routed to #438 and #442 and
patched in `ROADMAP.md` during the sprint scaffold.

## Outgoing Comments

- `DRM.jl` #1:
  <https://github.com/itchyshin/DRM.jl/issues/1>
- `GLLVM.jl` #14:
  <https://github.com/itchyshin/GLLVM.jl/issues/14>
- `gllvmTMB-julia-bench`: no comment left because the local checkout has no
  configured remote.

The outgoing comments are documentation and workflow notes only. They do not
ask either sibling package to adopt `drmTMB` code, and they do not claim that
sister-repo performance or coverage is `drmTMB` evidence.

## Second Scout: 2026-05-30 Overnight

| Source | State | Observed pattern | drmTMB action | Risk and comment status |
| --- | --- | --- | --- | --- |
| `DRM.jl` at `/Users/z3437171/Dropbox/Github Local/DRM.jl` | branch observed as `gaussian-animal-phylo`, commit `5cf13f6` | The digital twin is moving structured Gaussian effects in small, named steps: independent random slope, `relmat()` closed-form GLS, and Gaussian structured `animal()`/`phylo()` effects. Its Gaussian random-slope route also keeps a recovery test for `(0 + x | g)` separate from a source guard that keeps correlated `(1 + x | g)` planned. | Use the same shape in #442 and #446: one dependence layer, one estimand, one evidence gate, then a status update. Do not bundle phylo, spatial, animal, and `relmat()` slope promotion into one support claim. Keep core recovery tests and unsupported-syntax rejection tests paired. | MIT/GPL boundary still matters. No code copied. No comment warranted because the useful lesson is already internal to `drmTMB` planning. |
| `GLLVM.jl` at `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` | `article-pitfalls...origin/article-pitfalls`, commit `583d1ea` | The sister Julia package separates a quick core test run from the full `Pkg.test()` quality battery that carries Aqua/JET and CI parity. It also keeps profile/bootstrap CI checks, benchmark cells, and coverage simulations as named evidence gates with convergence counts, usable-interval denominators, and Monte Carlo SE. | In #446, separate CRAN-safe focused `drmTMB` tests from optional heavy simulation, benchmark, quality, and comparator gates. A cell can be source-tested, smoke-artifact-ready, diagnostic-pilot-ready, or formal-pilot-ready without pretending all gates are the same. Coverage or power tables should report attempted fits, converged fits, usable intervals, and MCSE. | No code copied. No comment warranted; the lesson is workflow structure, not a bug or missing test in the sibling repo. |

Decision: accept both lessons for planning language only. They support the
Phase 6c issue taxonomy and #446 simulation plan, but they do not count as
`drmTMB` recovery, power, accuracy, coverage, or speed evidence.

## Third Scout: 2026-05-30 Overnight

| Source | State | Observed pattern | drmTMB action | Risk and comment status |
| --- | --- | --- | --- | --- |
| `DRM.jl` at `/Users/z3437171/Dropbox/Github Local/DRM.jl` | branch observed as `gaussian-multi-re`, commit `2edd781`, dirty local work present | The digital twin keeps simulation/readability gates as one slice ledger: tests name the DGP and recovery target, and dev-log entries tie small capabilities to test plus documentation evidence. | For #446, keep each random-slope operating-characteristic lane readable: DGP, estimand, fit route, recovery/coverage/power status, and planned neighbours in the same note. For #444, use status-tagged reader pages only when rendered docs and evidence ledgers are current. | Dirty local work means this is workflow inspiration only. No code copied and no sibling comment warranted. |
| `GLLVM.jl` at `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` | branch observed as `fix-vitepress-deploy-path`, commit `281fe07`, clean | A profile-derived coverage fix is preserved as a narrative regression test before full coverage lives in bench scripts. Parity and quality gates are opt-in rather than part of the light local suite. | When a #446 random-slope grid exposes bad coverage, degenerate intervals, or convergence artifacts, promote the smallest failing cell into a focused regression test that records the failure story. Keep heavy comparator/parity work optional and separate from CRAN-safe checks. | MIT/GPL boundary still matters. No code copied. No comment warranted. |
| `gllvmTMB` at `/Users/z3437171/Dropbox/Github Local/gllvmTMB` | `main`, commit `9dcac03`, clean but behind origin | Reader-first docs start with user questions and explicit "Start Here" routes, while advanced examples wait for data, diagnostics, validation, and rendered HTML. Warnings name fallback behavior and what the user should do next. | For #444, use two reader views rather than a larger architecture import: compact formula syntax plus interpretation/status map. For #446, write failure and fallback notes that tell future users or agents the next action. | Checkout is behind origin, so refresh before citing current package status. No code copied and no comment warranted. |

Decision: accept these as process lessons for #444 and #446 only. They do not
validate any `drmTMB` accuracy, coverage, power, speed, or package-scope claim.
- proposed `drmTMB` action;
- provenance or licensing risk;
- comment status: none, comment needed, comment left, reply received,
  accepted, declined, or deferred.

The exchange is a design and coordination loop. It is not a substitute for
local `drmTMB` tests, likelihood comparisons, simulation artifacts, rendered
docs, or GitHub Actions checks. Do not copy code from sibling repositories
without provenance review and an `inst/COPYRIGHTS` update. Keep
higher-dimensional multivariate lessons in `gllvmTMB` unless a one-response or
two-response `drmTMB` issue explicitly admits the design.

## Closeout Decision

The first #437 loop is complete as a protocol and evidence ledger. It produced
three accepted planning lessons:

1. Keep random-slope support rows separated by evidence tier: source-tested,
   artifact-ready, diagnostic-only, recovery-ready, coverage-ready, and
   power-ready are different states.
2. Keep core tests, heavy simulation gates, benchmarks, and coverage claims in
   separate lanes with denominators for attempted fits, converged fits, usable
   intervals, and Monte Carlo uncertainty.
3. Keep reader docs paired with status maps and next-action guidance so users
   see the nearest fitted alternative when a planned route is rejected.

These lessons informed the Phase 6c random-slope closeouts and the #446
simulation plan. They did not add a likelihood, formula grammar, parser route,
simulation grid, benchmark result, missing-data behavior, or external-code
copy.

## Scout Cards

| Date | Sources | Lesson | `drmTMB` disposition | Provenance and comment status |
| --- | --- | --- | --- | --- |
| 2026-05-30 | `DRM.jl`, `GLLVM.jl`, `gllvmTMB`, an older local `GLLVM.jl` checkout path, and `gllvmTMB-julia-bench` | Add compact lesson cards before coding and make cross-repo corrections visible. | Accepted for process. The log now requires source handles, applicability, action, and provenance risk before a lesson affects the roadmap. | Comments/issues were mirrored to `DRM.jl` issue 1 and `GLLVM.jl` issue 14. No `gllvmTMB-julia-bench` issue was left because the local checkout had no configured Git remote. |
| 2026-05-31 | `DRM.jl` branch `gaussian-animal-phylo`, commit `5cf13f6`; `GLLVM.jl` branch `article-pitfalls`, commit `583d1ea` | Separate `(0 + x | g)` recovery evidence from correlated `(1 + x | g)` planned or rejected evidence; separate ordinary gates from heavy simulation and coverage grids. | Accepted for planning only. This became status-discipline for #438, #441, #442, and #446. | No code copied. No `DRM.jl` or `GLLVM.jl` speed, coverage, or recovery result was treated as `drmTMB` evidence. |
| 2026-05-31 | `DRM.jl` branch `gaussian-multi-re`, commit `2edd781`, dirty; `GLLVM.jl` branch `fix-vitepress-deploy-path`, commit `281fe07`, clean; `gllvmTMB` `main`, commit `9dcac03`, clean but behind origin | Keep simulation/readability ledgers connected: DGP, estimand, fit route, recovery, coverage, power, and planned neighbours should be visible together. Promote the smallest failing simulation cell to a narrative regression test before broad coverage grids. | Accepted for planning only. This reinforced the #446 run order and the #444 reader-path closeout. | No code copied. No sibling-package speed, coverage, or recovery result was treated as `drmTMB` evidence. |

## Corrections Locked In

- Use `GLLVM.jl` for the Julia sister package. `gllvmTMB.jl` is not a separate
  package name; any such wording refers only to an older local checkout path.
- Use `meta_V(V = V)` as the current known-sampling-covariance spelling.
  `meta_known_V(V = V)` is a deprecated compatibility alias, not the preferred
  route.
- `gllvmTMB` remains the higher-dimensional multivariate package. `drmTMB`
  stays scoped to one-response and two-response models.

## Next Use

#437 can close with this ledger. #436 remains the sprint parent until its own
closeout confirms that the child issues, roadmap, tests, docs, pkgdown checks,
and remaining follow-up issues agree. Future exchange notes should be appended
only when they produce a concrete `drmTMB` action, issue comment, or explicit
defer decision.
