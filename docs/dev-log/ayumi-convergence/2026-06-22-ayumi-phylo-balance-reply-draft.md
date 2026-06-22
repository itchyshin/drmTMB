# Ayumi Phylo Balance Reply Draft

Status: local draft only. The external GitHub issue was not readable from this
session, so refresh the issue thread before posting. Do not post this text until
the maintainer approves the exact final comment.

## Draft

Hi Ayumi,

Thank you for pressing on the `phylo_*` balance question. I think your concern
is right: for a location-scale analysis, it would be awkward to support
phylogenetic structure only in the location model if the scientific question is
also about trait variability.

The current answer is route-specific.

In native drmTMB with ML, the univariate Gaussian `phylo()` intercept cells are
now balanced at the fit-target level: `mu`, `sigma`, and matched `mu+sigma`
phylogenetic intercept models all have local evidence rows and tests. That
means the model syntax and point-fit target are available for those cells, but
it does not by itself prove calibrated profile or bootstrap interval coverage.

In native drmTMB with REML, the support is narrower. The current exact-Gaussian
REML path is mean-side only for phylogenetic structured effects. Scale-side,
matched `mu+sigma`, bivariate q2, and bivariate q4 phylogenetic REML requests
are still rejected rather than silently treated as supported.

For your current applied workflow, the clean run-now model is still Model A+:
phylogenetic location effects for both traits, fixed-effect `sigma1` and
`sigma2`, and residual correlation `rho12`. That model is the strongest
current full-data anchor. A scale-side phylogenetic term can be useful as a
sensitivity or diagnostic fit when `check_drm()` is clean, but with roughly one
observation per tip it should not be interpreted as settled scale-phylogenetic
uncertainty without stronger interval or replication evidence.

For the bivariate q4 route, native ML can expose q4 point/status rows and direct
SD targets, but q4 correlations are still derived targets and interval support
is not calibrated. Direct DRM.jl has q4 profile/bootstrap machinery, but that
is direct Julia evidence, not yet promoted R bridge support; prior bootstrap
evidence also warns about scale-axis undercoverage.

So the short version is: yes, your balance concern is real. We should not claim
that the whole location-scale phylogenetic surface is solved. Native ML is much
more balanced for the univariate Gaussian intercept cells than it was; native
REML, bivariate q4 inference, bridge promotion, and calibrated scale-side
intervals remain open work.

I would currently recommend reporting Model A+ as the primary analysis, and
treating the scale-side and q4 fits as sensitivity/diagnostic routes until the
remaining inference gates are banked.

## Pre-Post Checklist

- Refresh the live issue and adjust the opening if Ayumi has added new
  context.
- Re-run the forbidden-claim scan on the exact final comment.
- Do not add claims about native q4 REML, non-Gaussian REML, HSquared AI-REML,
  R bridge support, public optimizer controls, or 10,440-tip intervals.
- Confirm whether the maintainer wants a short reply, a long technical reply,
  or a reply plus links to local/PR evidence.
