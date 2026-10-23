# Parity follow-up decisions (owner, 2026-09-03 morning)

Reader: anyone picking up drmTMB's R-Julia parity work, and the DRM.jl lane.

These four answers were given by Shinichi at the close of the overnight true-parity lane
(`docs/dev-log/plan-actual/2026-09-03-true-parity-night.md`), with each option's cost stated before
the choice. They are recorded in the vault as D-213. They settle questions that had been carried in
the plan since 2026-09-02, so they should not be re-derived.

## 1. `summary()`'s derived "repeatability" row is renamed

`icc()` and `repeatability()` keep the canonical meaning: the focal component's variance over that
component plus the residual. `summary()`'s derived row divides by the TOTAL variance (every mu
random-effect variance plus the residual), which is deliberate and documented against issue #695,
but it means the same word named two different numbers whenever a fit has two or more structured
components. The row is renamed to state what it computes; its arithmetic is unchanged. drmTMB is
pre-CRAN under D-164, so the rename costs nothing now and would cost a deprecation cycle later.

## 2. drmTMB asks for q4 Wald standard errors

DRM.jl defaults `q4_vcov = false` for bivariate q4 phylogenetic fits, so the bridge returns an
all-NaN `vcov()` and the q4 SE receipt's Wald block stays `not_comparable`. DRM.jl #611 established
that the values are finite, positive definite, and agree with an independent Hessian below 1e-5 when
the option is on. drmTMB sends `q4_vcov = TRUE` when it wants those standard errors, rather than
waiting on a foreign lane to change a default. The fix is in our control and needs no DRM.jl change.

## 3. All four open follow-ups are commissioned

Not one of them, all four: pre-checking DRM.jl's route limits before the engine boots; issue #1130
(the default `nlminb` tolerance leaves location-scale fits about 1e-5 short of the optimum); issue
#1129 (`imputed()` returns Gaussian `mi()` conditional modes that are off by 1e-4 to 1e-3 because the
inner Newton is not tight at the final theta); and a same-seed bootstrap design, without which
cross-engine bootstrap endpoints differ by up to 0.18 at R = 20 purely from independent random
number streams and no bootstrap parity claim is measurable at all.

## 4. True parity is one-directional

R workflows must run on the Julia engine. Julia-only accessors come to R when a user asks for one,
not as a standing commitment; the reverse gap stays as issues #1116 to #1118. `heritability()`,
`icc()` and `repeatability()` were ported last night because a user asked for them, and that is the
pattern rather than a promise to port the rest. This closes the fog item the ultra-plan had carried
since 2026-09-02.

## What these decisions do not change

No capability row is promoted, no interval coverage is claimed (D-181 #2 stands: capability parity,
not coverage), no CRAN or registration action is implied (D-164), and no DRM.jl file is edited from
this side.
