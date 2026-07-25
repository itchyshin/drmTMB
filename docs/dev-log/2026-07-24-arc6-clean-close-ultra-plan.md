# Arc 6 clean-close ultra-plan

## Decision

Close Arc 6 in two deliberately separate lanes. The reader-first beta
documentation and the bounded Bernoulli x ordinary-NB2 association-slope
implementation can be reviewed and merged through ordinary package and CI
gates. The retained Arc 6.5 Bernoulli x Bernoulli recovery failure needs a
fresh recovery-repair lane. It must not be repaired by changing its historical
220-attempt receipt, weakening its denominator, or relabelling its HOLD.

The two lanes share no capability promotion. In particular, neither lane adds
joint-model `rho12`, standard errors, confidence intervals, profiles,
coverage, random effects, generic association formulas, Julia, or CRAN claims.

## Lane A: reader-first beta API and documentation

**Branch:** `codex/arc6-reader-first-beta-docs`.

### Implementation boundary

The only new fitted association regression is one finite numeric covariate for
literal Bernoulli x ordinary-NB2 margins:

\[
  \eta_i = \tanh(\beta_0 + \beta_1 x_i).
\]

The documented equation has no numerical guard. The implementation evaluates
the correlation infinitesimally inside the open interval only to prevent an
exact plus-or-minus-one correlation from reaching the numerical rectangle
integrator.

### Required local tests

1. Existing independent rectangle-oracle, factorization, normalization,
   endpoint-failure, response-order, and simulation tests for the five
   admitted pair classes.
2. Ten admitted family/data combinations as an integration smoke matrix. This
   tests dispatch and common boundaries; it is not a recovery study.
3. A deterministic two-coefficient simulated Bernoulli x ordinary-NB2 fixture
   that recovers the direction and approximate magnitude of the slope.
4. A row-specific independent `mvtnorm` oracle: the summed likelihood must
   agree when \(\eta_i\) changes across rows.
5. Multistart agreement plus finite-difference score and diagonal-curvature
   diagnostics for both beta coefficients.
6. Rejection tests for factors, multiple predictors, interactions, offsets,
   random effects, non-finite covariates, and non-Bernoulli x ordinary-NB2
   pair classes.
7. One-call `biv_associate()` equivalence to the two-margin workflow.

### Merge gate

Run regenerated documentation, the focused association tests, the broader
association test filter, rendered versions of both reader articles,
`pkgdown::check_pkgdown()`, and `git diff --check`. Then push, obtain a
review, require all package/docs CI checks to be green, merge, and verify the
deployed article titles and text. A full local `R CMD check` is desirable but
is not substituted by an incomplete or interrupted run; CI remains the merge
gate.

## Lane B: Arc 6.5 recovery repair

**New branch after Lane A:** `codex/arc6-5-recovery-repair`.

### Immutable starting evidence

The historical source commit is `51647467196f9f212dea0bcb323fe649462f570d`.
Its Totoro receipt retains 220 attempts: 180 interior and 40 predeclared
rare/near-boundary HOLD attempts. The exact failed interior attempt is
`n = 120`, asymmetric prevalence, true `eta = 0.5`, replicate 1, seed
`650016`, with `boundary_unresolved`. Therefore that receipt remains HOLD.

### Phase B0: diagnosis, not repair

1. Authenticate and inspect the raw Totoro attempt for seed 650016 without
   modifying artifacts.
2. Replay that exact data at the frozen source and current main, saving a
   separate diagnostic bundle: fitted margins, response table, rectangle
   masses/endpoints, every multistart objective, optimizer messages,
   finite-difference score/curvature, and a one-dimensional association-link
   likelihood profile.
3. Independently compare the discrete rectangle likelihood at a fixed grid of
   association links to the `mvtnorm` oracle. Classify the failure as an
   endpoint/integration defect, optimizer/multistart defect, weak curvature,
   a genuine boundary solution, or unresolved.
4. No historical summary, gate, or receipt changes in this phase.

### Phase B1: frozen repair proposal

Only if B0 identifies a reproducible numerical defect, write the exact source
change, independent oracle test, regression fixture containing seed 650016,
and a new all-attempt runner. If B0 instead shows weak identification or a
genuine boundary likelihood, retain HOLD and stop; a sample-size floor is a
new design decision, not a numerical repair.

### Phase B2: approval-required compute campaign

Before remote execution, obtain explicit approval for a new design file that
states source SHA, all seeds, grid, attempted-replicate count, retained fields,
run host, success rule, and how the old 220 attempts remain separately
reported. Use Totoro for this modest CPU grid (at most 100 cores) unless its
availability or a larger replicated grid makes a DRAC array preferable. Do not
use GitHub Actions for recovery computation or artifact storage.

The campaign must retain every attempt, including numerical failures. It must
include the original failed cell and its exact seed as a named regression cell,
plus enough independent replicates to make a recovery conclusion meaningful.
No pooled promotion with the old HOLD is allowed.

### B3: disposition

An independent audit checks source and artifact hashes, seed uniqueness,
denominators, oracle agreement, and the predeclared gate. A passing new campaign
can support only the precisely tested recovery statement; a failure leaves Arc
6.5 HOLD. Either outcome receives an after-task report and capability/doc
reconciliation.

## Final closeout

After each lane, regenerate reader artefacts, run the after-task validator,
record exact checks in `docs/dev-log/check-log.md`, remove merged branches only
after their merge SHA and deployed documentation are verified, and leave a
handoff that names any remaining HOLD and the exact next command.
