# q4 Patterson-Thompson Is Not HSquared AI-REML

This note exists to prevent a naming drift. The HSquared lesson is useful for
exact Gaussian sparse mixed models. It does not license calling the bivariate q4
phylogenetic location-scale route "AI-REML".

## Exact Target Boundary

The transferable HSquared ingredients are:

- sparse Gaussian mixed-model equations;
- determinant identities for Gaussian restricted likelihoods;
- Takahashi selected-inverse traces and diagonals;
- explicit estimator provenance;
- validation-status discipline before public claims.

Those ingredients apply directly only when the estimand is an exact Gaussian
REML/MME target. The current DRM.jl pilot target is the location-only Gaussian
phylogenetic mean cell.

## q4 Is A Different Object

The Ayumi q4 cell has four phylogenetic axes (`mu1`, `mu2`, `sigma1`,
`sigma2`), residual correlation `rho12`, scale parameters, and an augmented
likelihood. Its current honest methods are ML/Laplace, profile/bootstrap, and
the q4 Patterson-Thompson correction where that correction is actually derived,
implemented, and verified.

The q4 Patterson-Thompson correction is a restricted-likelihood correction for
the q4 objective. It is not the HSquared average-information algorithm and does
not by itself provide an AI update, an AI covariance, or 10k-scale interval
readiness.

## Required Language

Use:

- "q4 Patterson-Thompson correction" when that exact correction is meant;
- "observed-information diagnostic" for observed Hessian checks;
- "profile/bootstrap interval" for interval evidence;
- "ML/Laplace" for non-Gaussian or augmented-Laplace routes;
- "exact Gaussian REML/MME" for the location-only Gaussian pilot.

Do not use:

- "q4 AI-REML";
- "non-Gaussian AI-REML";
- "HSquared proves q4 scalability";
- "AI-REML solves Ayumi intervals";
- "10k sigma-phylo interval ready" before `drmTMB#570` and `DRM.jl#293` are
  cleared with evidence.

## Local Evidence As Of 2026-06-21

The clean DRM.jl worktree has internal exact-Gaussian diagnostics only:
supplied-variance REML helper, dense same-estimand GLS oracle, Takahashi trace
and PEV diagnostics, AI-vs-observed diagnostic, finite-difference optimizer
experiment, status/schema rows, and focused tests. This evidence is useful for
the Gaussian pilot and for bridge-provenance discipline. It is not evidence for
q4 scale-axis inference or Ayumi's 10,440-tip interval workflow.
