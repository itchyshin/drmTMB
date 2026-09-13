# Fisher review — R3.3 importance-sampling reference

## Verdict

R3.3 resolves the R3.2 rank ambiguity for this three-tip fixture. The two
previously unresolved cells are separated by 0.4015 NLL, approximately 57
combined batch standard errors. Both meet the predeclared diagnostics: eight
batches, converged direct modes, and minimum ESS 1278 and 991. No Hessian
eigenvalue was floored in either retained proposal.

Together with R3.2's stable cells, the direct-reference ordering is
`ridge/ridge < interior/ridge < ridge/interior < interior/interior`, matching
native Laplace. Estimator repair is not justified by this evidence.

## Boundary and next action

Laplace changes contrast sizes: ridge/interior versus interior/interior differs
by about 0.081 NLL natively and 0.401 under the reference. R3.3 therefore does
not validate profile curvature, interval calibration, 128-tip behavior, or
rate recovery. The next task should predeclare informative and weak likelihood
geometry regimes and assess native recovery, boundaries, profiles, and
intervals. It must not claim exact-likelihood recovery or broaden public OU
support.
