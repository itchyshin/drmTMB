# R-hub sanitizer adjudication — candidate `12a5cc5bc`

Date: 2026-08-18

Run: https://github.com/itchyshin/drmTMB/actions/runs/32150223826

The workflow ran at evidence commit `37c2bfe04bdaee542d4e881ea306b4f8827b858c`.
Its parent package source is candidate source commit
`12a5cc5bcc36ed1b83d969e5147e29bc98aaadf6`; the intervening files are under
the build-excluded `docs/` directory. R-hub built from the checkout, so this is same-source
evidence, not server attestation of candidate SHA-256 `e9c5556d…`.

## Per-job evidence

| Job | Job ID | Workflow conclusion | Evidence verdict |
| --- | ---: | --- | --- |
| clang-ASAN | `95754029844` | success (30m43s) | PASS: `Status: OK`; `FAIL 0 · WARN 96 · SKIP 143 · PASS 11403`; no AddressSanitizer report |
| clang-UBSAN | `95754029866` | success (25m48s) | PASS: `Status: OK`; `FAIL 0 · WARN 96 · SKIP 143 · PASS 11403`; no undefined-behaviour runtime report |
| rchk | `95754029771` | failure (6m13s) | FAIL, adjudicated as the pre-existing TMB-header signature: four protection-stack findings in installed `TMB/include/tmb_core.hpp`, plus analyzer state explosion; zero protection findings in `drmTMB.cpp` |
| gcc-ASAN | `95754029806` | success (67m07s) | PASS: `Status: OK`; `FAIL 0 · WARN 51 · SKIP 143 · PASS 11403`; no AddressSanitizer report |

The rchk signature exactly reproduces the previously adjudicated dependency/framework class. It
reports state-space explosion in `strptime_internal`, `bcEval_loop`, `RunGenCollect`, and
`objective_function<double>::operator()()`, then four possible protection-stack imbalances at
installed `TMB/include/tmb_core.hpp:1243`, `:1515`, and `:2277`. The associated negative-depth and
over-unprotect messages are also in those TMB headers. No protection finding cites `drmTMB.cpp`;
its only compile messages are pre-existing unused-variable warnings.

The matching 2026-08-07 adjudication is preserved at
`../platform/rhub-rchk-adjudication.md`. This file carries fresh matching output for the current
source rather than inheriting that disposition without evidence. The job remains a failure and is
not described as an rchk pass.

## Raw-log integrity

- `rhub-clang-asan-job.log`:
  `a7ed5a2b1a59646c61fc034bff4406119efab777f68444d409fd1194a28702e1`;
- `rhub-clang-ubsan-job.log`:
  `792798cd8d77b1f7c27a3199dbc361a6da37656045589b2c9813b141249a78c7`;
- `rhub-rchk-job.log`:
  `ec9a81cc55b1dd4624ca5822e9b96369c287f81a40cae758b4dfe86750e3faf5`;
- `rhub-gcc-asan-job.log`:
  `e806ac3935792befcb95277971ed170cad4d9bdd90833a5d38c8d1f233ef0f94`;
- `rhub-run-screenshot.png`:
  `1ae1cfa4ad894515a9a79bff799a9e6a222cabb2e04214329c8499ea395a19ab`.

The screenshot supplied by the maintainer is a visual receipt of the terminal workflow summary:
the three sanitizer jobs are green and `rchk` alone is red. The raw job logs remain the basis for
the detailed dispositions above.

The run is terminal and all three sanitizer raw logs are preserved and successful. The run-level
conclusion remains failure because `rchk` is red. R-hub supplies same-source diagnostics only; the
pending exact-byte R-oldrelease result and raw email records remain necessary before any
`platform-clean` decision.
