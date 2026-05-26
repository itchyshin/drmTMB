# Phase 18 Bounded-Runner Roadmap Sync Slices 669-678

Reader: `drmTMB` contributors checking whether the roadmap, simulation
programme, and simulation README describe the bounded runner consistently.

Slices 669-678 synchronize the current text with the implemented private Phase
18 runner status. The main correction is vocabulary: Phase 18 private
bootstrap artifacts are not a new broad public bootstrap interval API. The
package already has a limited public direct-target
`confint(..., method = "bootstrap")` route; Phase 18 bootstrap interval rows
are simulation artifacts for admitted surfaces and remain separate.

## Source Evidence

- `docs/design/41-phase-18-simulation-programme.md` records the shared bounded
  replicate runner, serial default, Unix `multicore` backend, 10-worker cap,
  closure-aware `summarise_fun_factory`, and nested-parallel guard plan.
- `ROADMAP.md` now states that broad operating-characteristic grids remain
  planned and that private Phase 18 bootstrap artifacts are separate from the
  limited direct-target public `confint()` bootstrap route.
- `inst/sim/README.md` describes the private bounded execution contract,
  separate replicate and bootstrap backends for Student-t shape and bivariate
  residual `rho12`, requested-versus-actual worker metadata, and the no-nested
  multicore rule.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 669-671 | Audit current bounded-runner wording | ROADMAP, Phase 18 programme, simulation README, runner code, and tests were searched for backend/bootstrap claims |
| 672-674 | Correct stale public-bootstrap wording | ROADMAP and the Phase 18 programme now distinguish private Phase 18 artifacts from limited public direct-target `confint()` bootstrap |
| 675-676 | Preserve PSOCK boundary | The docs keep package simulation helpers to serial and Unix `multicore`; PSOCK remains outside this helper surface |
| 677-678 | Record validation and handoff evidence | Check-log and after-task entries record commands and unsupported boundaries |

## Commands

```sh
rg -n "bounded|parallel|multicore|PSOCK|psock|bootstrap interval|public bootstrap|bootstrap_backend|requested_cores|actual|cores|Slices 669-678|669|678|Phase 18" ROADMAP.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md
rg -n "phase18_runner_parallel_plan|psock|multicore|requested_cores|bootstrap_backend|bootstrap.backend|phase18_assert_no_nested_parallel" inst/sim/R inst/sim/run tests/testthat/test-phase18-* .github/workflows/phase18-simulation-grid.yaml
```

## Result

The sync found and fixed one stale wording risk: ROADMAP treated public
bootstrap intervals as still planned, even though selected direct
`confint(..., method = "bootstrap")` targets are already implemented. The
current wording now says what is true:

- broad operating-characteristic grids remain planned;
- private Phase 18 bootstrap interval artifacts are simulation evidence, not a
  new public interval API;
- the public direct-target bootstrap route remains limited to selected
  `confint()` targets;
- Phase 18 package simulation helpers support serial execution and Unix
  `multicore`, not PSOCK;
- nested replicate-layer and bootstrap-layer multicore requests remain
  disallowed.

The remaining ROADMAP `psock` hit is the developer-only Ayumi bootstrap
prototype for a specific diagnostic target, not the Phase 18 package simulation
helper surface.

No likelihood, formula grammar, public API, roxygen topic, pkgdown navigation,
or rendered site output changed.
