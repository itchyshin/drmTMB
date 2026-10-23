# Julia structured fixed-effect inference provider forwarding

## 1. Goal

Let a univariate `engine = "julia"` structured fit retain the exact
general-covariance provider needed to refit an ordinary fixed-effect target
through `confint(method = "profile" | "bootstrap")`.

## 2. Implemented

The univariate `relmat` / `animal` / `spatial` bridge now stores its existing
structured payload on the fitted object. `drm_julia_call_fixef_inference()`
maps that payload's one matrix to `K`, `A`, or `coords`, forwards those nullable
arguments through JuliaCall, and the generated Julia helper supplies them to
`DRM._bridge_fit()`. Both Gaussian and generic `DRM.bootstrap_result()`
branches now carry the same `K`, `A`, and `coords` values into their marginal
simulation/refit calls.

The point-fit structured route is unchanged. A Gaussian `spatial()` payload
continues to be translated before storage into its native fixed-range covariance
`K` and a `relmat()` Julia formula.

## 3a. Decisions and Rejected Alternatives

The change reuses the point-fit payload rather than reparsing the user formula
or reconstructing its provider at interval time. It leaves the phylogenetic SD
entry point and the point-fit `drmTMB_drm_bridge_structured()` primitive alone.

The shared readiness field cannot expose bootstrap without also making the same
fixed-effect target selectable for profile. The tests therefore verify both
methods reach the generated helper; the bounded live check below exercises both
methods without making a profile calibration or performance claim.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-structured-inference.R`
- this report

## 5. Checks Run

The retained behaviour-red pure-R mock is
`/private/tmp/drm-parity-20260830/provider-bootstrap-r/pure-r-red-provider-20260831T000001Z.log`.
It failed before the source change because the univariate structured fit stored
no payload and the fixed-effect Julia call sent no provider matrix.

The focused new test passed 48 expectations after the final change:
`/private/tmp/drm-parity-20260830/provider-bootstrap-r/pure-r-green-bootstrap-provider-20260831T000006Z.log`.

Review found that the generated helper initially supplied the provider to the
point refit but not to either `DRM.bootstrap_result()` call. The retained
secondary red guard
`/private/tmp/drm-parity-20260830/provider-bootstrap-r/pure-r-red-bootstrap-provider-20260831T000004Z.log`
failed because it found one rather than two provider-forwarding bootstrap
branches. Both branches now pass the provider.

The adjacent focused suite also passed:
`Rscript --vanilla -e 'devtools::test(filter = "julia-(structured-inference|bootstrap-tree|inference)", reporter = "summary")'`;
its receipt is
`/private/tmp/drm-parity-20260830/provider-bootstrap-r/pure-r-focused-bootstrap-provider-20260831T000005Z.log`.
It ran the provider, phylo-tree, and ordinary-inference mocks. Four existing
live Julia cases in `test-julia-inference.R` skipped because their `callr`
children had no DRM.jl path; they are not live evidence for this slice.

After the final comment-only covariance-scale correction, the same focused
suite passed again; its receipt is
`/private/tmp/drm-parity-20260830/provider-bootstrap-r/pure-r-focused-rose-wording-20260831T000007Z.log`.

The bounded public R integration check passed for both Gaussian `relmat(K)`
fixed-effect profile and bootstrap through `engine = "julia"`:
`/private/tmp/drm-parity-20260830/provider-bootstrap-r-live/actual-r-relmat-bootstrap-profile-final.log`
(SHA-256 `0072100bb2e38d3f4662f7242b7caaea181b977ed55d429b6240daba95c26863`).
Its driver source-loaded this exact R checkout and exact DRM.jl path, retained
the `K` provider, and used BLAS one. Public profile returned status `profile`
with bounds equal to direct `DRM.drm_bridge_inference`; public bootstrap also
had zero point and bound differences, using `B = 2` and 2/2 successful refits.
Driver SHA-256: `74bac059f0bb9f12e73a591cc2295f872a52cc76da7a0cb25f9eed8dbce566be`.

## 6. Tests of the Tests

The first retained test attempt had a mock-fixture environment error and is not
used as behavioural red evidence. After correcting the fixture only, the
retained red test failed on the intended missing payload, missing `K`, and
shifted generated-helper positions. The green test exercises public `confint()`
for both profile and bootstrap, captures the generated-helper call, and checks
the supplied provider and both nullable neighbours for each route. The review
guard additionally counts the provider-forwarding argument sequence in both
generated bootstrap branches; it is a source-plumbing guard, not a numerical
test.

## 7a. Issue Ledger

No issue, commit, PR, or public capability record was changed. This is a
narrow continuation of the approved Julia fixed-effect inference bridge work.

## 8. Consistency Audit

The new fixed-effect argument order preserves the existing nullable tree as
argument five; the adjacent phylo forwarding test remains green. The point-fit
structured primitive still accepts and forwards `K`, `A`, and `coords` exactly
as before. Gaussian spatial has a pre-existing pure-R lock that confirms its
conversion to `K` and `relmat()`.

## 9. What Did Not Go Smoothly

The initial test fixture passed `environment()` from the test instead of the
formula/provider environment, so its `K` symbol was unavailable; an empty
`conditional_re` list also did not match the bridge object's expected shape.
Those fixture-only defects were corrected before retaining the behaviour red.
Review then found the second forwarding omission: the initial refit received
the provider but both bootstrap branches dropped it. The additional retained
red guard caught that exact omission before the two-branch repair.

## 10. Known Residuals

The actual evidence is limited to the Gaussian `relmat(K)` fixed-effect profile
and bootstrap fixture above. It does not establish live animal or spatial
inference, cross-engine parity beyond that direct Julia comparison, profile or
bootstrap calibration, performance, any larger bootstrap count, or a new
structured family/formula surface. `B = 2` is a bounded forwarding check, not
coverage evidence. The existing univariate route remains one intercept-only
structured mean term with `sigma ~ 1`; non-Gaussian coordinate-based spatial
remains rejected and must use a precomputed `relmat` covariance.

## 11. Team Learning

For refit-based inference, retaining a bridge formula and data is insufficient
when the original point fit used an out-of-band covariance provider. The fitted
object needs the already-built and validated exact provider payload, especially when a
surface syntax such as Gaussian `spatial()` is translated before it reaches the
engine.

## 12. Cross-Product Coverage

The pure-R cross-product covers univariate Gaussian fixed-effect profile and
bootstrap routing for `relmat(K)`, `animal(A)`, and coordinate `spatial()`
after its established conversion to `K`/`relmat`; each case asserts the two
irrelevant provider arguments are NULL. The bounded actual-R cell adds public
Gaussian `relmat(K)` profile (status `profile`, bounds equal to direct
`DRM.drm_bridge_inference`) and bootstrap (`B = 2`, 2/2 successful refits, zero
point and bound differences), with BLAS one. It does NOT cover live animal or
spatial inference, non-Gaussian coordinate spatial, bivariate fixed effects,
structured slopes, residual-scale structured effects, larger bootstrap counts,
performance, or profile/bootstrap interval calibration.
