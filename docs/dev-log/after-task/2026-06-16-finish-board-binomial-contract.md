# After-task: Finish-board widget and binomial response contract

## Purpose

Implement the first non-Ayumi slice from the combined twin finish plan:
make the mission-control dashboard issue-led, record the plain
Bernoulli/binomial response contract for `drmTMB#569`, and pin the
`drmTMB#544` bridge-gate registry contract without touching Claude-owned
Gaussian/Ayumi engine work.

## What changed

- Extended `docs/dev-log/dashboard/status.json` with a row-oriented
  `finish_board` covering Critical Path, Issue Ledger, Twin Claim Board,
  Cross-Package Lessons, Evidence Gates, and Release Readiness.
- Updated `docs/dev-log/dashboard/index.html` to render the finish board and
  bumped the dashboard build from `r4` to `r5`.
- Hardened `tools/validate-mission-control.py` so it checks standing review
  names, finish-board lanes, owner names, issue URLs, status vocabulary,
  evidence requirements, matrix row count, and the dashboard build/version
  match.
- Added `drmTMB#569` to the master capability matrix and the master local-R
  work queue before older q8/skew/structured work.
- Recorded the planned first binomial response contract in:
  `docs/design/01-formula-grammar.md`,
  `docs/design/02-family-registry.md`,
  `docs/design/03-likelihoods.md`,
  `docs/design/06-distribution-roadmap.md`,
  `docs/design/19-family-link-contract.md`, and
  `docs/design/24-denominator-response-syntax.md`.
- Added the `drmTMB#544` bridge-gate registry schema and CI-fail conditions to
  `docs/design/168-r-julia-finish-capability-matrix.md`.

## Issue ledger

- Created `drmTMB#577`: <https://github.com/itchyshin/drmTMB/issues/577>
- Posted the `drmTMB#569` binomial consensus comment:
  <https://github.com/itchyshin/drmTMB/issues/569#issuecomment-4718667648>
- Posted the `drmTMB#544` bridge-gate registry comment:
  <https://github.com/itchyshin/drmTMB/issues/544#issuecomment-4718667677>
- Posted the `drmTMB#491` queue-order update:
  <https://github.com/itchyshin/drmTMB/issues/491#issuecomment-4718667645>

## Contract decisions

The first public binomial route is:

```r
drmTMB(bf(y01 ~ x), family = stats::binomial(), data = dat)
drmTMB(bf(cbind(successes, failures) ~ x), family = stats::binomial(), data = dat)
```

The model is:

```text
Y_i ~ Binomial(n_i, mu_i)
logit(mu_i) = X_mu[i, ] beta_mu
```

The first slice is fixed-effect `mu` only. It rejects non-logit links,
factor-response ordering, proportions plus `weights`, `weights = trials`,
`successes / trials`, `sigma`, `nu`, `rho12`, `zi`, `zoi`, `coi`, random
effects, structured effects, bivariate or mixed responses, and
`engine = "julia"`.

The first evidence claim is fixed-effect estimation plus `stats::glm()` parity,
including likelihood constants so `logLik`, AIC, and BIC agree on overlapping
likelihoods.

## Boundaries kept

- No changes to `src/drmTMB.cpp`.
- No changes to Claude-owned Gaussian density, log-sigma clamp, penalty/MAP,
  optimizer, profile, or scale-phylo guidance paths.
- No DRM.jl code changes.
- No Julia bridge promotion for binomial.
- No claim that beta-binomial evidence validates plain binomial support.
- No Ayumi Model A LR number was quoted.

Scale-side phylogenetic wording in the touched files uses weak-identification
language and avoids promoting speed or scale-phylo as the lead novelty. The
dashboard and matrix keep predictor-dependent residual `rho12` visible as the
lead `drmTMB` novelty.

## Checks

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/status-json-check.out
python3 tools/validate-mission-control.py
sh tools/start-mission-control.sh --background
npx playwright screenshot --full-page --viewport-size=1440,1200 http://127.0.0.1:8765/ /tmp/drmtmb-finish-board-desktop.png
npx playwright screenshot --full-page --viewport-size=390,1400 http://127.0.0.1:8765/ /tmp/drmtmb-finish-board-mobile.png
curl -fsS http://127.0.0.1:8765/status.json | python3 -c 'import json,sys; status=json.load(sys.stdin); sections={"Critical Path","Issue Ledger","Twin Claim Board","Cross-Package Lessons","Evidence Gates","Release Readiness"}; lanes={row["lane"] for row in status["finish_board"]}; ids={row["id"] for row in status["finish_board"]}; print("finish_rows", len(status["finish_board"])); print("missing_lanes", sorted(sections-lanes)); print("has_binomial", "drmTMB-569-binomial-fixed" in ids); print("matrix_rows", len(status["matrix"])); assert not sections-lanes; assert "drmTMB-569-binomial-fixed" in ids; assert len(status["finish_board"]) == 10; assert len(status["matrix"]) == 17'
```

Result:

```text
mission_control_ok: 18/68 banked_or_verified, 3 active, 17 matrix rows, 10 finish rows
dashboard already listening at http://127.0.0.1:8765/
finish_rows 10
missing_lanes []
has_binomial True
matrix_rows 17
```

Rendered screenshots were captured at:

- `/tmp/drmtmb-finish-board-desktop.png`
- `/tmp/drmtmb-finish-board-mobile.png`

R package checks were not run because this slice changes dashboard/design
contracts only: no R code, roxygen, C++, tests, or compiled artifacts changed.

## Next steps

1. Serve and browser-check the dashboard on desktop and mobile.
2. Open the dashboard/widget PR and watch CI.
3. After the Claude-owned `src/drmTMB.cpp` seam clears, implement
   `drmTMB#569` in a separate PR with fixed-effect likelihood, method-surface
   tests, `stats::glm()` parity, and simulation smoke evidence.
4. Implement the generated `drmTMB#544` bridge gate registry and CI guard in a
   separate PR without promoting binomial bridge support.
