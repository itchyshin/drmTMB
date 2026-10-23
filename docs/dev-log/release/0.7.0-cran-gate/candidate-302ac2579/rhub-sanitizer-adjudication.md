# R-hub sanitizer adjudication — candidate `302ac2579` (run 31908844744)

**2026-08-15 · dispatched at the exact candidate commit on branch `candidate-302ac2579` ·
config `clang-asan,clang-ubsan,gcc-asan,rchk` · IN PROGRESS at first write — this document is
completed per-job as jobs land, and says so per row.**

Run: https://github.com/itchyshin/drmTMB/actions/runs/31908844744

## Provenance caveat, stated up front

R-hub builds its own tarball from the source checkout: these jobs are **same-commit, not
same-bytes** evidence (the frozen candidate's bytes are `0d150ef3…`; R-hub compiles from
`302ac2579` directly). Same relationship as the prior candidate's ledger recorded. The
exact-bytes classes are the local `--as-cran` and the Totoro valgrind run.

## Per-job verdicts

| job | conclusion | adjudication |
| --- | --- | --- |
| setup | success | n/a |
| **clang-asan** | **failure** | **NO SANITIZER FINDINGS — job failure is vignette non-convergence, see below** |
| **clang-ubsan** | **success** | **PASS — `Status: OK` INCLUDING vignette rebuilds**: the three fragile vignettes converge under UBSAN's instrumented build, so instrumentation per se does not break them |
| **gcc-asan** | **success** | **PASS — tests, examples, and `--run-donttest` all clean under a second, independent ASAN compiler**; vignette rebuild `SKIPPED` by that container's config, so this job does NOT discriminate the clang-asan vignette failure and is not cited as doing so |
| **rchk** | **failure** | **NOISE — identical signature to the 2026-08-07 adjudication, inherited with fresh evidence** |

**Matrix summary (run complete, conclusion `failure` at the job-gate level, adjudicated):** zero
memory-safety or undefined-behaviour findings across all three sanitizer jobs; the only red jobs
are the pre-adjudicated rchk noise class and a vignette-convergence quirk specific to the
clang-ASAN environment, which clang-ubsan's own full vignette rebuild bounds from the other side.

### clang-asan — zero sanitizer reports; the failure is numerical, not memory-safety

The full job log (22,769 lines) contains **no `AddressSanitizer` report of any kind** — no
heap/stack/use-after errors, no LeakSanitizer summary. The single grep hit for the word is the
workflow's own detection code echoed into the log. The job's exit-1 comes from `R CMD check`'s
vignette-rebuild step: three vignettes — `animal-models.Rmd`, `phylogenetic-spatial.Rmd`,
`spatial-models.Rmd` — fail with

> `drmTMB()` failed in all `stats::nlminb()` optimizer preset attempts …
> Caused by error in `optimizer()`: ! NA/NaN gradient evaluation

**Adjudication: a numerical-robustness observation in the instrumented environment, not a
sanitizer finding.** ASAN builds run unoptimized with different floating-point behaviour; these
three spatial/phylogenetic fits are the package's most numerically delicate. The same vignettes
rebuilt cleanly the same evening in the exact-bytes local `--as-cran` (`[84s/97s] OK`, all 23
vignettes) and in `R CMD build`. The prior sanitizer pass (2026-08-07, head `744b9fbe`) predates
~8 days of `src/`/`R/` movement and a container refresh, so which of those flipped the
convergence is not established here; what IS established is that no memory error was detected
anywhere in the job.

**Follow-up worth its own slice (not a platform blocker):** make the three fragile vignette fits
robust to unoptimized builds (better starting values or a precomputed-fixture fallback), so an
instrumented environment cannot fail the check for non-sanitizer reasons.

### rchk — the pre-adjudicated noise class, re-confirmed

Tonight's failing findings are **byte-for-byte the same signature** adjudicated NOISE on
2026-08-07 (`platform/rhub-rchk-adjudication.md`): `too many states (abstraction error?)` in R's
own `strptime_internal`, `bcEval_loop`, `RunGenCollect`, and TMB's templated
`objective_function<double>::operator()()`. Zero findings attributable to `drmTMB.cpp`. The
prior adjudication is inherited **with fresh matching evidence**, not by reference alone.
