# Pre-registration (written before any wave-8 or old-base result was read)

Date: 2026-11-08. Everything below is copied from the original harness (`../fuzz-gap-map/classify.py` and its README), not chosen after looking.

Cells: the same 3008 cells (`cells.tsv` 2756 + `cells_indep.tsv` 198 + `cells_slope.tsv` 54), same data files, same runners (`run_r.R`, `run_julia.jl`, `driver.py`, unchanged copies). R reference: drmTMB 0.8.1 from the Totoro library `~/drm_campaign_20261108/Rlib`, `engine = "tmb"`.

Agreement: a cell where both engines return FITS agrees if |logLik_R - logLik_Julia| <= 1e-4, and disagrees if larger. (Original: 175 agree, largest agreeing gap 2.6e-06.)

Outcome rules (unchanged):
- FITS: call returned, logLik finite, and R `opt$convergence == 0` or Julia `fit.converged == true`.
- REFUSES: R `cli_abort`; Julia `ArgumentError` or `ErrorException` whose text does not match the numeric-failure regex.
- ERRORS (crash): any other exception type (MethodError, AssertionError, PosDefException, ...) or a process that died.
- NONCONVERGED: returned, convergence flag false. TIMEOUT: no result in 180 s (R) or 300 s (Julia), inconclusive, never a gap.

Cell classes: both-fit, R-only (R fits, Julia refuses), Julia-only, both-refuse, crash-Julia / crash-R, nonconverged, inconclusive.

Comparison rules fixed in advance:
- "Flipped to fit": old-base class R-only, crash-Julia, nonconverged or inconclusive with R fitting, and wave-8 Julia FITS.
- "Got WORSE": any cell where old-base Julia FITS and wave-8 Julia is not FITS; or both-fit agreeing (<= 1e-4) on old base and disagreeing on wave 8; or Julia outcome REFUSES on old base and ERRORS on wave 8; or any new AssertionError / PosDefException / other crash type absent on the old base for that cell.
- New agreement threshold results are reported for all newly both-fit cells, with no cell dropped.
- Not repeated here: sigma-side shapes, bridge (`engine = "julia"`), estimates and SEs (same limits as the original).

Compute plan: Totoro only, at most 40 cores in total (R 10 workers; Julia 20 workers old base + 20 workers wave 8 never above 40 together), one thread per process, `nice -n 10`. Estimate: R about 1 minute; Julia 15 to 40 minutes per tip (original was 12.6 min at 20 workers); setup and precompile about 15 minutes. Total about 1 to 1.5 hours, under the 3 h line.
