# Q-Series q1 `mu` SR150 Pregrid Runner

## 1. Task

Turn the reviewed q1 `mu` retained-denominator contract into an executable,
artifact-only SR150 pregrid path for the four Gaussian q1 `mu` intercept
direct-SD rows.

## 2. Scope

In scope: runner mode, wrapper, Nibi SLURM dispatch script, focused tests,
mission-control guard, dashboard/check-log wording.

Out of scope: submitting the DRAC job, importing SR150 results, changing any
Q-Series support-cell status, or making any `inference_ready`/`supported`
claim.

## 3. Implementation

- Added `pregrid` mode to
  `tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R`.
- Added `tools/run-structured-re-gaussian-lowq-mu-intercept-pregrid.R`, which
  defaults to `--run-kind=pregrid`, `--n-rep=150`, and
  `--write-dashboard=false`.
- Added `tools/slurm/q1-mu-intercept-pregrid-nibi.sbatch` for a scheduler-run
  source snapshot, package install, exact command capture, module list,
  session info, source manifest, runner stdout/stderr, and `seff` when
  available.
- Added lower/upper miss rates and upper:lower miss ratio to the pregrid
  summary output.

## 4. Guardrails

The pregrid runner refuses non-SR150 pregrid runs, refuses dashboard writes,
requires the four exact q1 `mu` intercept rows, requires a Nibi/Rorqual host
class or host name, and requires the retained-denominator contract status
`fisher_rose_grace_reviewed_sr150_pregrid_ready`.

## 5. Checks

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells and 4 q1 `mu` retained-denominator contract rows.
- Runner parse check for dry-run, pregrid, and smoke wrappers: passed.
- `bash -n tools/slurm/q1-mu-intercept-pregrid-nibi.sbatch`: passed.
- Embedded dashboard script syntax check via extracted `<script>` and
  `node --check /tmp/drmtmb-dashboard-script.js`: passed.
- `git diff --check` on touched files: passed.
- Focused R test:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 8996 PASS / 0 FAIL / 0 WARN /
  0 SKIP.

## 6. Claim Boundary

This promotes exactly no Q-Series row. It authorizes an artifact-only SR150
retained-denominator pregrid execution path and does not claim interval
coverage, `inference_ready`, `supported`, q1 sigma, matched `mu+sigma`, q2,
q4/q8, non-Gaussian interval evidence, REML, AI-REML, bridge support, or public
support. `MCSE <= 0.01` remains a top-up target, not an SR150 pass claim.

## 7. Known Residuals

- Nibi job `16976756` has been submitted and was pending with reason `Priority`
  at dispatch.
- No SR150 artifacts have been imported into the dashboard.
- Fisher/Rose/Grace still need to review the actual SR150 denominator output
  before any row-level status edit.
