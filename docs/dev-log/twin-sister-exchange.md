# Twin/Sister Exchange Log

This log implements the daily exchange protocol from #437 and the sprint epic
#436. It is a working ledger, not a claim that any sister-repo result has been
validated in `drmTMB`.

## Protocol

For each workday with active `drmTMB` development, spend 20-30 minutes on a
bounded scout pass before implementation work. Record one compact lesson card
per relevant source:

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
