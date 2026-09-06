# The second blind spot, measured: permanent ENVIRONMENT skips in CI

Leaf `environment-skip-census`. Branch `claude/parity-environment-skip-census`,
worktree base `origin/main` **2fcbb0fbf**, merged forward to **3c1f61a77**. Every number below was measured in
this run on this machine (macOS 15, R 4.6.0, `OPENBLAS_NUM_THREADS=1`) or read
out of a named GitHub Actions run; nothing is quoted forward from a brief.

## 1. Goal

PR #1222 measured the first family of permanent CI skips: tests whose premise is
a path `.Rbuildignore` removes from the tarball. In its own `not_covered` it
named a second family and declined to guess at it -- skips caused by the
**runner** rather than the **build**. Count that family, list it as a
re-derivable artefact, and judge which of its members are legitimate and which
hide a capability the package claims.

## 2. Resume note

Nothing is carried over. The artefact regenerates with
`Rscript tools/write-env-skip-census.R`; the guard runs in the ordinary suite as
`tests/testthat/test-env-skip-census.R`.

## 3. Implemented

- `tests/testthat/helper-env-skip-census.R` -- the scanner. Parse-tree, not
  grep: it walks `utils::getParseData()` for `SYMBOL_FUNCTION_CALL` tokens
  naming a skip verb, so prose and comments are not counted. For each site it
  also captures the nearest enclosing `if` condition, because a bare
  `skip("fixture unavailable")` usually sits one line under the `file.exists()`
  that decided it, and reading only the call would file that as run-decided.
- `tools/write-env-skip-census.R` -- generator (`--check` for staleness), which
  **sources the scanner rather than containing it**.
- `inst/extdata/env-skip-census.tsv` -- the artefact: 263 rows, one per
  (file, gate_class), with a site count. **Deliberately not one row per line.**
  A per-line artefact would be re-derived every time anything shifted a line
  number above a skip -- most test edits -- so it would churn constantly, conflict
  in every parallel branch, and become a file people regenerate to make red go
  away. Aggregated, it moves only when a file gains or loses a gate or a gate
  changes class. Per-line detail is one `Rscript tools/write-env-skip-census.R`
  away.
- `tests/testthat/test-env-skip-census.R` -- three guards (section 7).

**Why the scanner lives under `tests/testthat/` and not `tools/`.** `^tools$` is
in `.Rbuildignore`. A scanner under `tools/` could not run under `R CMD check`:
it would sit inside blind spot #1 while measuring blind spot #2, and its own
guard would print as a permanent skip. From `tests/testthat/` the same code runs
in the tarball on every runner, and the artefact lives in `inst/extdata/`, which
ships. This leaf's guard is the one guard in this area that is not inside either
blind spot.

## 4. The census (static)

`Rscript tools/write-env-skip-census.R` at 2fcbb0fbf plus this leaf's own files:

```
                      depends runs skips
  build-premise             0    0    55
  cran-lane                 0  126     0
  engine-drm-jl             0    0   105
  env-var-optin             0    0     9
  external-tool             0   20     0
  locale                    2    0     0
  os                        0    7     0
  platform-numeric          3    0     0
  runtime-conditional      13    0     0
  suggests-package          0  427     0

767 skip call sites total
  696 environment-axis (the runner could satisfy them)
  55 build-axis (only the build can satisfy them -- PR #1222)
  16 runtime-axis (the run's own data decides)

114 ENVIRONMENT-PERMANENT sites: the drmTMB CI runner never satisfies
these, in 39 test files.
  engine-drm-jl    105 sites in 35 files
  env-var-optin      9 sites in  4 files
```

`grep -c` over the same tree returns 430 `skip_if_not_installed(` against the
parser's 427: three of those occurrences are prose. The number is the deliverable,
so it comes from the parser.

## 5. What CI actually does (measured, not assumed)

Evidence: **GitHub Actions run 34004644639**, workflow `R-CMD-check`, branch
`main`, head **eccb10299**, conclusion `success`, four `ubuntu-latest` shards,
R 4.6.1 on Ubuntu 24.04.4, 2026-09-06. Log pulled with `gh run view --log`.

Shard summaries, verbatim:

```
[ FAIL 0 | WARN 27 | SKIP 260 | PASS 7173 ]   shard 1/4
[ FAIL 0 | WARN 26 | SKIP  34 | PASS 5020 ]   shard 2/4
[ FAIL 0 | WARN 15 | SKIP  42 | PASS 4959 ]   shard 3/4
[ FAIL 0 | WARN  6 | SKIP  22 | PASS 6106 ]   shard 4/4
```

**358 skips, 23,258 passes.** Parsing all four `Skipped tests` blocks gives 358
skips over 270 distinct reasons, of which exactly **62 are environment-permanent**:

- **54** `DRM.jl engine not available (set DRM_JL_PATH)`
- **8** `fragile near-boundary structured recovery (opt in: DRMTMB_RUN_FRAGILE_RECOVERY=1)`

The other 296 are build-premise skips -- PR #1222's territory.

### The brief's hypothesis is false, and that is the first finding

The brief expected `skip_if_not_installed(JuliaCall)` and `fmesher`/`sf` gates
"on a runner that never installs them". **They are all installed.** All 24
distinct packages named by the 427 `skip_if_not_installed()` sites appear in that
run's `Session info` package table -- `ape 5.8-1`, `JuliaCall 0.17.6`,
`fmesher 0.8.0`, `sf`, `glmmTMB 1.1.14`, `lme4 2.0-6`, `metafor`, `ordinal`,
`tweedie`, `palmerpenguins`, `detectseparation 0.4.0`, and the rest --
because `setup-r-dependencies@v2` installs Suggests. No `skip_if_not_installed`
reason appears anywhere in the run's 358 skips. **The 427 largest-looking gates
in the suite cost nothing.** Same for the 20 external-tool gates (git, bash,
python3, Rscript, pandoc via `setup-pandoc@v2`), the 126 `skip_on_cran()` sites
(`NOT_CRAN: true` is in the job env), and the 7 `skip_on_os("windows")` sites
(routine runs are ubuntu-only, so they execute).

## 6. Measurements (D-139): what the two permanent gates hide

Same two-mode method PR #1222 used: run the affected files with the premise
absent, then present, and diff. Estimated before running from a two-file pre-run
(58 s); actual 28.4 min, inside the estimate.

### 6a. `engine-drm-jl` -- DRM.jl **aee371cc9** (`drmjl-ref-aee371cc`)

33 of the 34 DRM.jl-gated test files, one R process per mode,
`pkgload::load_all()`.

| | engine absent (what CI does) | engine present |
|---|---:|---:|
| passing assertions | **1,232** | **2,024** |
| skips | 53 | 2 |
| **failures** | 0 | **3** |
| wall clock | 29.5 s | 27.9 min |

**792 assertions -- 39.1% of the live total -- have never run on any CI runner.**

`test-xfam-bridge.R` could not be run standalone by this harness in **either**
mode (`path does not exist` at file scope), so it is excluded from both columns
symmetrically and its 8 gates are unmeasured.

### 6b. `env-var-optin` -- `DRMTMB_RUN_FRAGILE_RECOVERY=1`

Three files, `CI=true` in both modes.

| | opt-in unset (what CI does) | opt-in set |
|---|---:|---:|
| passing assertions | **23** | **134** |
| skips | 8 | 0 |
| failures | 0 | 0 |
| wall clock | 1.9 s | 26.2 s |

**111 more assertions.** Total hidden behind the two environment-permanent
gates: **903 assertions.**

### The size finding

The brief guessed this family was "probably larger" than the build one. It is
not. Blind spot #1 hides **23,493** assertions (PR #1222); blind spot #2 hides
**903** -- about 26x smaller. What makes it matter is not its size but its
subject: #1's hidden assertions are almost all development-tooling and dashboard
audits, while #2's are the `engine = "julia"` bridge, an exported, documented,
user-facing capability.

## 7. RED CONTROLS

Four, all planted, all shown failing, all restored.

**A. A new skip site that the census does not list.**

```
FAILURE: 'test-env-skip-census.R:37:5'
inst/extdata/env-skip-census.tsv is out of date.
  NOT IN CENSUS (new or changed skip site):
    test-zz-red-control-env-census.R	2	skip_if_not_installed	suggests-package	environment	runs	skip_if_not_installed("brms")
```

**B. A `skip_if_not_installed()` on a package DESCRIPTION does not Suggest.**
This is the disease guard, not bookkeeping: CI installs Suggests, so a target
outside Suggests skips permanently on every runner, forever, in green ink.

```
FAILURE: 'test-env-skip-census.R:77:3'
Expected `undeclared` to be identical to `character(0)`.
`actual`:   "brms"
skip_if_not_installed() names brms, which DESCRIPTION does not Suggest. CI never
installs those, so the guarded tests skip permanently on every runner.
```

**C. A third environment-permanent gate class appearing without a decision.**
Planted `skip_on_ci()`; test 3 failed (1 failure), the other direction green.

**D. A censused site that disappears.** Line 38 of
`tests/testthat/test-shard-selection.R` commented out:

```
FAILURE: 'test-env-skip-census.R:37:5'
inst/extdata/env-skip-census.tsv is out of date.
  IN CENSUS BUT NO LONGER PRESENT:
    test-shard-selection.R	38	skip_if	runtime-conditional	runtime	depends	skip_if(length(files) == 0L, "no test files visible from the working directory")
```

Restored with `git show HEAD:<path> > <path>`; md5 `53e0b13ee72632d9739b0fe7d9ef720b`
before and after, identical. `git status --porcelain` after all four controls
listed only this leaf's four intended new files.

## 8. Findings: three live red assertions CI structurally cannot see

Mode B is not clean. Three assertions on `main` are **red today** and no CI run
can reach them.

**1 and 2 -- stale fence expectations, and they are pin-independent.**
`test-julia-family-truncated_nbinom2.R:170` and
`test-julia-family-zero_one_beta.R:204` both expect a **DRM.jl-side** message
(`TruncatedNegBinomial2() currently supports fixed effects only`). What they get
is the **R-side** scope fence added by PR #1196:

```
x | `engine = "julia"` admits "truncated_nbinom2" only on the `fe`
  | (fixed-effect) route of the Julia family registry, with no random-effect or
  | scale-submodel support yet.
```

That string is emitted at `R/julia-bridge.R:1245`, **before Julia is reached**,
so this failure does not depend on the DRM.jl commit at all: the R-side fence now
refuses first, and the two assertions were never re-run because CI cannot reach
them. The fence works; the tests' expectations went stale behind the gate.

**3 -- a pure-R contract assertion fenced behind a Julia gate.**
`test-julia-predict-quantile.R:513` compares its quantile spec table with
`drmTMB:::drm_julia_registry_families("fe")` and is missing `skew_normal`
(admitted by PR #1176) and `biv_gaussian`. This assertion needs no Julia
whatsoever -- it is R comparing two R objects -- yet it sits inside a
`drm_skip_live_julia()` block, so the registry grew and nothing noticed.

**I did not fix these.** They live in files owned by sibling parity lanes
(#1204, #1213/#1214 neighbourhood) and fixing three unrelated expectations from a
census leaf would collide with them. They are reported here and in the PR body
for the owner to route.

## 9. Judgement: legitimate, or a claimed capability never tested?

| gate class | sites | verdict |
|---|---:|---|
| `suggests-package` | 427 | **Legitimate and free.** All 24 targets installed on the runner; every guarded test runs. |
| `cran-lane` | 126 | **Legitimate.** `NOT_CRAN: true` makes them no-ops in repository CI; they exist for CRAN. |
| `external-tool` | 20 | **Legitimate and free.** git/bash/python3/Rscript/pandoc all present. |
| `os` | 7 | **Legitimate.** All name windows; routine runs are ubuntu, so they run. Skipped only on the tag matrix, which is where the OS question is asked. |
| `env-var-optin` | 9 | **Legitimate but re-examinable.** Deliberately fenced, documented in `docs/dev-log/known-limitations.md`, named opt-in. See below. |
| `engine-drm-jl` | 105 | **THE DISEASE.** Same shape as blind spot #1: a documented, exported capability whose tests print as passes and have never run. |

### `engine = "julia"` is claimed and untested on every runner

The package exports `engine = "julia"`, ships `inst/extdata/julia-capabilities.tsv`
with rows marked `supported` and `covered`, documents the bridge in public
vignettes, and roughly a dozen open PRs tonight are admitting further families to
it. **No CI runner has ever executed one line of it.** The workflow sets no
`DRM_JL_PATH`, installs no Julia. 105 gates, 35 files, 792 assertions, and
today three of them are red.

PR #1163 mitigates part of this -- a Linux step runs eleven **mock-driven** bridge
files -- and its own `not_covered` is exactly right that "mocks cannot see a
DRM.jl signature mismatch". Findings 1 and 2 above are a sharper version of the
same point: they are not signature mismatches but **stale expectations**, and a
mock cannot see those either.

### Cost of closing it (owner decision -- I am not proposing it)

Nothing needs installing on the R side; the gap is Julia. A job would need
`julia-actions/setup-julia`, a DRM.jl checkout, and `Pkg.instantiate` +
precompile.

- **Measured here:** 27.9 min of wall clock for 33 files, one warm process, on a
  laptop with a **warm** Julia depot.
- **Not measured here, and it is the part that decides the bill:** a GitHub
  runner starts cold. Julia install plus a first DRM.jl dependency resolve and
  precompile is real and unmeasured by this leaf. `julia-actions/cache` would
  amortise it across runs; the first run pays in full.
- **Shape, if the owner wants one:** a single `ubuntu-latest` job, not a fifth
  shard and not part of the 4-way matrix -- the shards check the tarball, and
  this needs a source checkout with a DRM.jl clone beside it. That is the same
  shape PR #1222 chose, for the same reason.

An intermediate that costs nothing: **792 assertions are not all live-engine
assertions.** Finding 3 is a pure-R registry comparison sitting behind a Julia
gate for no reason. Moving the mock-satisfiable assertions out from behind
`drm_skip_live_julia()` would recover part of the 792 with no Julia at all. That
is a real slice, and it is not this one.

### The fragile-recovery fence, re-examined

Cost is **not** the reason to keep it: the whole family runs in **26.2 s** and was
**green** here. The stated reason is cross-platform BLAS/LAPACK irreproducibility
turning the release-tag full-OS matrix red, and that reason survives -- my green
run is macOS, one platform, and proves nothing about Ubuntu or Windows. But
routine runs are **ubuntu-only and single-platform**, which is precisely the
setting the fence was not written for. Setting `DRMTMB_RUN_FRAGILE_RECOVERY=1` on
the routine ubuntu job only, and leaving it unset on the tag matrix, would buy
111 assertions for 26 seconds. **Owner decision. I did not make it.**

## 10. Checks run

- `Rscript tools/write-env-skip-census.R` -- 767 sites, artefact written.
  Re-derived byte-identically after merging `origin/main` forward from
  2fcbb0fbf to 3c1f61a77, which is the determinism check that matters while
  main is moving hourly.
- `Rscript tools/write-env-skip-census.R --check` -- clean.
- `test-env-skip-census.R` under `pkgload::load_all()`: `FAIL 0 | SKIP 0 | PASS 5`.
- Four red controls above, each shown failing and restored.
- Two-mode DRM.jl measurement, 33 files, both directions.
- Two-mode fragile-recovery measurement, 3 files, both directions.
- **The guard runs inside the built tarball -- proven, not assumed.**
  `R CMD build --no-build-vignettes` ships all three of
  `inst/extdata/env-skip-census.tsv`,
  `tests/testthat/helper-env-skip-census.R` and
  `tests/testthat/test-env-skip-census.R` (and correctly does *not* ship
  `tools/write-env-skip-census.R`). Installed to a scratch library and run from
  the extracted `tests/testthat`:

  ```
  [ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
  ```

  `SKIP 0` is the whole point: this guard is in neither blind spot. Planting the
  `brms` red control into the *extracted tarball* gives
  `[ FAIL 3 | WARN 0 | SKIP 0 | PASS 3 ]` with the same three messages, so it
  fails there too rather than merely passing vacuously.
- New/changed files are ASCII only (`LC_ALL=C grep -n '[^ -~]'` finds nothing in
  the two R files and the TSV).
- No file under `R/` was touched, so the non-ASCII `R CMD check` WARNING surface
  is unchanged.

## 11. Not covered

- **`test-xfam-bridge.R`** -- 8 `engine-drm-jl` gates, unmeasured; it fails at
  file scope under a standalone `test_file()` in both modes.
- **Cold-runner Julia cost** -- the number that decides whether closing the gap
  is affordable. My depot was warm. Not measured.
- **The three red assertions are reported, not fixed.**
- **macOS only.** Every two-mode number here is macOS/R 4.6.0. The CI-side
  numbers are Ubuntu/R 4.6.1 from run 34004644639. Greenness does not transfer
  between them; the *counts* of what is skipped do, because the gates are
  configuration, not numerics.
- **The `locale` pair** (`test-julia-formula-constructs.R:197,201`) is marked
  `depends`, not resolved: the runner collates `C.UTF-8`, the two sites disagree
  in opposite senses, and on that runner both are masked by an upstream
  `engine-drm-jl` gate anyway.
- **No CI workflow change.** `.github/workflows/R-CMD-check.yaml` is untouched,
  deliberately: PR #1222 has an open edit to that file and a second concurrent
  edit would conflict. The census guard runs in the ordinary suite instead.
- **Blind spot #3, if there is one**, is not looked for. This leaf closed the
  one #1222 named.
