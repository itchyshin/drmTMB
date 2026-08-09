# #870 — family scope of `offset()`: analysis for Shinichi's decision

**Date:** 2026-08-09 · **Lane:** Claude task 1, Stage A (candidate preparation)
**Baseline:** `origin/main@ac363cadb` · **Status:** analysis only — no code or docs changed
**Requested by:** Shinichi, 2026-08-09 ("I'll decide now — give me the analysis")

## Headline

**#870's premise is inverted, and the analysis found a different, real defect.**

The 29-issue sweep recorded #870 as *"`R/drmTMB.R:7294-7302, 9001-9026` permits
offsets for any `mu`"*, framing the decision as **all-`mu` versus count-family-only**.
Measured against current main, the code is **not** permissive-for-all-`mu`: it is
already family-scoped to exactly three builders, and it rejects offsets everywhere
else. There is therefore **no permissive-code problem to decide.**

What there *is*: the **documentation claims a family the code rejects.** The roxygen
grants `offset(log(exposure))` to zero-truncated negative-binomial `mu`; a live fit
aborts. That is a user-facing overclaim on a public surface, which is exactly the
class of defect Gate 0 of the CRAN release gate exists to catch.

## Evidence

### The gate is default-deny

`drm_reject_phase1_terms(rhs, dpar, allow_offset = FALSE)` (`R/drmTMB.R:9022`) adds
`"offset"` to its unsupported list whenever `allow_offset` is not `TRUE`
(`R/drmTMB.R:9039-9041`). Of ~23 call sites, **three** opt in:

| Site | Enclosing builder | Family key in the dispatch (`R/drmTMB.R:395-440`) | Guard |
| --- | --- | --- | --- |
| `R/drmTMB.R:6239` | `drm_build_binomial_spec` (`:6156`) | `binomial` | `allow_offset = TRUE` |
| `R/drmTMB.R:6793` | `drm_build_poisson_spec` (`:6641`) | `poisson` | `allow_offset = TRUE` |
| `R/drmTMB.R:7322` | `drm_build_nbinom2_spec` (`:7074`) | `nbinom2` | `allow_offset = identical(entry$dpar, "mu")` |

`truncated_nbinom2` has its **own** builder (`drm_build_truncated_nbinom2_spec`,
`:7637`) whose single rejection call at `:7759` uses the **default `allow_offset =
FALSE`**, and it covers `mu_entry` explicitly.

### Confirmed by fitting, not by reading

Live toolchain (R 4.6.0, TMB 1.9.21), toy `n = 200`, `mu = ~ x + offset(log(ex))`:

| Family | Result |
| --- | --- |
| `poisson()` | **FITS** — offset accepted |
| `nbinom2()` | **FITS** — offset accepted |
| `binomial()` | **FITS** — offset accepted |
| `truncated_nbinom2()` | **REJECTED** — `The `mu` formula contains unsupported term: "offset"` |
| `beta_binomial()` | **REJECTED** — same |

### The documented contract disagrees on exactly one family

`R/drmTMB.R:21-24` (roxygen):

> Binomial `mu` formulas may include standard R `offset()` terms on the
> logit-event-probability scale. Poisson, ordinary negative-binomial, **and
> zero-truncated negative-binomial** `mu` formulas may include standard R
> `offset(log(exposure))` terms for exposure or effort…

`truncated_nbinom2()` is claimed and does not work. The other three claims are
correct and verified above.

## Blast radius of the overclaim — narrow

| Surface | Carries the claim? |
| --- | --- |
| `R/drmTMB.R:22-23` (roxygen source) | **Yes — the origin** |
| `man/drmTMB.Rd:169-171` (generated) | **Yes — inherited** |
| `vignettes/formula-grammar.Rmd` | No — its offset rows are Poisson and NB2 only |
| `NEWS.md:1554, 1556` | No — names Poisson and NB2 only |
| `README.md` | No — no `offset` mention |

**One source sentence and its generated `.Rd`.** Nothing else repeats it.

## The decision

The all-`mu`-vs-count-only policy question **does not arise** — the code already
enumerates. What remains is a two-way choice about the mismatch:

**Option 1 — correct the documentation (recommended).** Delete the three words
"and zero-truncated negative-binomial" from `R/drmTMB.R:23`, re-run
`devtools::document()`. Docs then match measured behaviour exactly. Cost: a
three-word deletion plus regeneration. Risk: none — it removes a claim, so it cannot
break a working user model. It **does** change installed bytes (`man/drmTMB.Rd`), so
it is a **Stage B** change, prepared now and landed with the release bytes.

**Option 2 — implement the offset for `truncated_nbinom2`.** Pass
`allow_offset = identical(entry$dpar, "mu")` at `R/drmTMB.R:7759` and ship tests.
Honest cost: this is a **capability addition inside a release slice**. The truncated
NB2 likelihood renormalises over the positive support, so an exposure offset is not
merely additive on the log-mean the way it is for Poisson/NB2 — it needs its own
recovery evidence before any claim, not just a flag flip. `beta_binomial()` has the
same gap and the same argument. This belongs in a post-0.7 family lane.

**Recommendation: Option 1.** It makes 0.7.0 honest for a three-word cost. Option 2
is real work with an evidence burden, and putting it in the release slice is the
scope creep the gate exists to stop. Record `truncated_nbinom2` + `beta_binomial`
offset support as post-0.7 in the issue.

## What this does not do

Does not discharge D-93 or D-117 · does not advance any release rung · does not bump
DESCRIPTION · does not change code or docs (Stage A is docs-only; the Option 1 diff
is prepared in `2026-08-09-07-stage-b-byte-fixes.md` and held for Stage B) · does not
close #870.

## Confidence

**High** for the family map and the mismatch: three independent lines of evidence —
the dispatch switch, the `allow_offset` call-site inventory, and a live fit per
family. **Medium** for the Option 2 cost estimate: the renormalisation argument is
sound but I did not derive or test a truncated-NB2 offset likelihood.
