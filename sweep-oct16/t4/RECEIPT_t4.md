# Receipt: sweep-oct16 lane t4 (edge-case grid)

Independent cloud-agent run. Never pushed to main, never merged, no PR (spec: issues only).

## Pins (`git rev-parse HEAD`)

| repo | SHA |
|---|---|
| itchyshin/drmTMB | `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` |
| itchyshin/DRModels.jl | `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` |

This receipt branch: `sweep-oct16/t4` (HEAD recorded after the commit that adds this file).

## Environment

- R 4.3.3, Ubuntu 24.04.5 x86_64, TMB 1.9.25, Matrix 1.6-5, drmTMB 0.7.1 installed from the pinned checkout.
- Julia 1.11.6, DRModels 0.7.2 at the pinned checkout, 1 thread.
- Hard timeouts: per-fit R `mcparallel` + SIGKILL at 60 s; per-cell GNU `timeout` 15 min (900 s) in `run_cell.sh`. No TIMEOUT rows occurred (every fit returned).

## Exact commands

```sh
git -C /workspace rev-parse HEAD
# ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
git clone https://github.com/itchyshin/DRModels.jl /home/ubuntu/src/DRModels.jl
git -C /home/ubuntu/src/DRModels.jl checkout f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
export R_LIBS_USER=/home/ubuntu/R/library
R CMD INSTALL /workspace
julia --project=/home/ubuntu/src/DRModels.jl -e 'using Pkg; Pkg.instantiate(); using DRModels'
cd /workspace
Rscript sweep-oct16/t4/t4_gen_data.R sweep-oct16/t4/data
# 750 datasets
Rscript sweep-oct16/t4/t4_fit_drmTMB.R sweep-oct16/t4/data sweep-oct16/t4/results/fits_drmTMB all 60
julia --project=/home/ubuntu/src/DRModels.jl \
  sweep-oct16/t4/t4_fit_DRModels.jl sweep-oct16/t4/data sweep-oct16/t4/results/fits_DRModels.csv all
Rscript sweep-oct16/t4/t4_analyse.R sweep-oct16/t4/results
```

Standalone confirms (after the grid):

```sh
Rscript  # bin_complete r01, pois_n8_lowmean r03, student r15, gauss_n8 r06, collin_sigma_exact r01
# log: sweep-oct16/t4/repro/confirm.log
julia --project=/home/ubuntu/src/DRModels.jl   # gauss_n8 r06: logLik 29.344, conv false
```

Seeds: nominal `20261016400 + 100*(k-1) + (rep-1)`, R `set.seed(seed %% 2^31)`, 50 reps, k = 1..15. Generator: `sweep-oct16/t4/t4_gen_data.R`.

## Pass bar (manual, after the classifier)

Pass: every fit either converged with finite logLik, SEs and a correct flag, or a clear error/warning; never `converged=TRUE` with a silent wrong answer; R and Julia agree on the flag.

The automated classifier in `t4_analyse.R` treats “boundary” cells as needing a boundary *flag*. Several of those cells are actually well-identified interior MLEs (Beta phi ≈ 1e4 with SE 0.07; NB2 with log-sigma around −2). The table below is the **manual** verdict against the written pass bar.

| cell | drmTMB vs pass bar | DRModels.jl vs pass bar | flag agree | notes |
|---|---|---|---|---|
| gauss_n8 | **FAIL** 6/50 silent wrong | pass (flags the ridge) | 43/50 | unbounded LS likelihood; R conv TRUE at logLik 0.5–13.6 nats below Julia |
| gauss_n12 | pass 50/50 | pass 50/50 | 50/50 | logLik agree ≤ 5e-9 |
| gauss_n20 | pass 50/50 | pass 50/50 | 50/50 | |
| pois_n8 | pass 50/50 | pass 50/50 | 50/50 | mean `exp(0.5+0.5x)` never hits all-zero |
| pois_n12 | pass 50/50 | pass 50/50 | 50/50 | |
| pois_n20 | pass 50/50 | pass 50/50 | 50/50 | |
| bin_complete | **FAIL** 50/50 silent | pass (warns) | 50/50 on the boolean, **disagree on meaning** | R conv TRUE, check_drm ok, SE ~1e5, no warning |
| bin_quasi | pass (degenerate) | pass (warns) | **0/50** | same optimum; flag semantics #1554 / #1270 |
| nb2_poisdata | mixed: 17 interior PASS; 33 Poisson-limit flagged degenerate, no boundary label | pass (warns) | 18/50 | Refs #1496, #1535, DRModels.jl #1072 |
| beta_phi1e4 | pass (finite ll, SE ≤ 0.07, 47/50 conv) | pass 50/50 | 47/50 | 3 R code-1; classifier over-flagged “SILENT_BOUNDARY” |
| student_gaussdata | **FAIL** 1/50 wrong logLik (1.02e40, flagged degenerate) | pass | 25/50 | Refs #1462; other splits are large-nu flag semantics |
| re_sd1e-4 | pass (50/50 conv; 29 status=boundary) | mixed (20/50 conv false at the same ll) | 30/50 | Julia g_tol; Refs #983 / #1050 |
| collin_sigma_exact | pass (50/50 degenerate, vcov errors) | pass (50/50 conv + warn) | **0/50** | Refs #1470, DRModels.jl #1110 |
| collin_sigma_near | pass (50/50 degenerate) | pass (warns; check_drm ok 50/50) | **0/50** | weakly identified, same ll |
| pois_n8_lowmean | **FAIL** 13/50 silent | pass (flags) | 49/50 | all-zero / extreme-x; Refs #1553, DRModels.jl #1109 |

No hangs. 750/750 R fits and 750/750 Julia fits returned inside the timeout.

## Issues filed or commented

**GitHub write from this agent returned 403** (`Resource not accessible by personal access token`) on both `issue_write` (create) and `add_issue_comment`. No issue numbers were created here. Drafts ready to paste: `sweep-oct16/t4/issue-drafts/`.

Matching existing issues (comment, do not re-file):

| URL | One line |
|---|---|
| https://github.com/itchyshin/drmTMB/issues/1469 | gauss_n8: 6/50 R conv TRUE while Julia is on an unbounded ridge (new symptom vs original scale test) |
| https://github.com/itchyshin/drmTMB/issues/1470 | exact collinear sigma at this pin is now `degenerate` 50/50, still no alias drop |
| https://github.com/itchyshin/drmTMB/issues/1496 | nb2_poisdata Poisson-limit SEs; 33/50 degenerate, no boundary flag |
| https://github.com/itchyshin/drmTMB/issues/1535 | same Poisson-limit reporting split on simulated Poisson data |
| https://github.com/itchyshin/drmTMB/issues/1270 | bin_complete 50/50 silent on R; bin_quasi R FALSE / Julia TRUE + warn |
| https://github.com/itchyshin/drmTMB/issues/1462 | student r15 logLik 1.02e40 at n=100, eta_nu 120.76 |
| https://github.com/itchyshin/drmTMB/issues/1553 | independent replicate: 13 silent pois_n8_lowmean (same reps) |
| https://github.com/itchyshin/drmTMB/issues/1554 | independent replicate: 238/750 flag disagreements; Julia 1.11.6 |
| https://github.com/itchyshin/DRModels.jl/issues/1109 | Julia twin of #1553 |
| https://github.com/itchyshin/DRModels.jl/issues/1110 | Julia conv TRUE + finite pseudo-inverse SEs on aliased sigma |
| https://github.com/itchyshin/DRModels.jl/issues/983 | related: re_sd1e-4 20/50 Julia conv false at the same logLik (g_tol) |
| https://github.com/itchyshin/DRModels.jl/issues/1072 | not re-run (bladdercancer); nb2_poisdata is the simulated analogue |

New issue that should be filed (draft only; 403):

- `sweep-oct16/t4/issue-drafts/NEW-gauss-n8-unbounded.md` — unbounded location-scale at n=8, R silent conv TRUE.

Not triggered, not re-filed: #1069, #1088.

Sibling t4 PR (not ours, not updated): https://github.com/itchyshin/drmTMB/pull/1552 head `claude/blissful-turing-r8xyyd`.

## Artifacts

- Fits: `sweep-oct16/t4/results/fits_drmTMB.csv`, `fits_DRModels.csv`
- Classifier: `classified.csv`, `cross_engine.csv`, `summary.md`
- Confirms: `sweep-oct16/t4/repro/confirm.log`, `sessionInfo.txt`
- Generator / fitters: `t4_gen_data.R`, `t4_fit_drmTMB.R`, `t4_fit_DRModels.jl`, `t4_analyse.R`, `run_cell.sh`
