# S0-A2 proposed correction — recession-cone contract

Status: **PROPOSED, NOT EXECUTED**

**This proposal authorizes neither execution nor hurdle/S1 work.**

Parent evidence: commit d740bd007
Reader: mathematical and inference reviewers deciding whether a revised S0 run is licensed

## 1. Why an additive correction is required

The retained S0 run correctly stopped because its frozen 'mu_complete'
contract expected a finite intercept while
'detectseparation::detect_separation()' returned '-Inf'. That disagreement
does not establish a detector defect. For

~~~r
data.frame(
  y01 = c(0L, 0L, 1L, 1L),
  x = c(-2, -1, 1, 2)
)
~~~

the separating directions form a cone. Writing a direction as
\(d=(d_0,d_1)\), complete separation requires

\[
d_0-2d_1<0,\qquad d_0-d_1<0,\qquad
d_0+d_1>0,\qquad d_0+2d_1>0,
\]

or equivalently

\[
d_1>0,\qquad -d_1<d_0<d_1.
\]

Thus the slope sign is forced positive, while the intercept can be negative,
zero, or positive across valid rays. The old 'finite' expectation described
one convenient ray \(d=(0,1)\), not an invariant coefficientwise result.

This proposal does not edit or supersede the retained failure. It defines the
new contract that would have to pass before S0 could advance.

## 2. Exact fixed-design object

For grouped binomial-logit observations with \(0\le y_i\le m_i\), finite
offset \(o_i\), positive effective weight \(w_i\), design row \(x_i^\top\),
and \(\eta_i=o_i+x_i^\top\beta\), use the log-likelihood

\[
\ell(\beta)
=
\sum_i w_i
\left[
y_i\eta_i-m_i\log\{1+\exp(\eta_i)\}
\right]
+C(y,m,w).
\]

Rows with zero effective weight and masked response rows are removed before
constructing the design and response vectors. Rank is checked before any
separation classification.

Define the recession cone

\[
\mathcal C =
\left\{
d:
\begin{array}{ll}
x_i^\top d\le 0, & y_i=0,\\
x_i^\top d=0, & 0<y_i<m_i,\\
x_i^\top d\ge 0, & y_i=m_i.
\end{array}
\right\}.
\]

Offsets and positive weights do not change this cone. A direction is
likelihood-improving when at least one boundary-row inequality is strict.
Along \(\beta+td\), each boundary contribution is non-decreasing and every
strict boundary contribution is strictly increasing for finite \(t\);
interior grouped rows are unchanged because \(x_i^\top d=0\).

For an intercept-bearing logit model, the revised experiment requires finite
design entries and offsets, \(m_i>0\), valid \(0\le y_i\le m_i\), positive
active weights, and full column rank. Under these conditions, the maintained
detector documentation cites overlap as necessary and sufficient for finite
maximum-likelihood estimates; strict concavity then gives a unique finite
maximizer. The revised experiment tests only this bounded domain:

- a nonzero improving direction proves that no finite maximizer exists;
- absence of an improving direction is the fixed-design finite-MLE gate;
- rank deficiency is a separate identifiability state, never called overlap;
- complete versus quasi-complete separation describes row margins, not a
  unique coefficientwise infinity vector.

Analytic fixture truth together with the independently formulated cone and
strict-margin problems is the oracle. The maintained detector is the subject
under test; its existence, class, and coefficient indicators are compared
against that oracle.

Complete-versus-quasi classification is a separate feasibility problem. After
expanding grouped observations to Bernoulli rows, let
\(\bar x_k=(2y_k-1)x_k\). Write \(d=d^+-d^-\), with
\(d^+,d^-\ge0\), and solve

\[
\max_{d,\delta}\ \delta
\quad\text{subject to}\quad
\bar x_k^\top d\ge\delta\ \text{for every }k,\qquad
{\bf 1}^\top(d^++d^-)\le1.
\]

After separation has been established, \(\delta^*>10^{-8}\) is the
complete-separation gate and \(|\delta^*|\le10^{-8}\) is the quasi-complete
gate. A non-finite optimum, an optimum below \(-10^{-8}\), or an
uncertain solver status/residual stops the run. The normalized improving-cone
problem alone cannot distinguish these classes, because a completely
separated dataset can also admit rays with some zero margins.

## 3. Direction reporting

Let the signed boundary margins be

\[
r_i(d)=
\begin{cases}
-x_i^\top d, & y_i=0,\\
x_i^\top d, & y_i=m_i.
\end{cases}
\]

Build the boundary matrix \(B\) in exact retained-row order: use \(-x_i^\top\)
for all-failure rows and \(+x_i^\top\) for all-success rows. Build \(E\) from
interior grouped-binomial rows. Preserve the coefficient order and names from
the exact drmTMB model matrix. An admissible normalized certificate satisfies

\[
Bd\ge0,\qquad Ed=0,\qquad {\bf 1}^\top Bd\ge1.
\]

Scaling makes this normalization possible whenever an improving direction
exists.

Pin the independently formulated oracle to ROI 1.0-2 with
ROI.plugin.lpsolve 1.0-2 and solver 'lpsolve' in the isolated library. This is
not an independent computational implementation because the maintained
detector uses the same backend. Retain solver status, objective, solution,
maximum constraint residual, row order, coefficient order, package versions,
and a numerical feasibility tolerance of \(10^{-8}\). Any nonzero solver
status or residual above tolerance is unresolved and stops the run.

For each coefficient \(j\), solve three independent feasibility problems:

1. \(\mathcal C\), normalized, with \(d_j\ge1\);
2. \(\mathcal C\), normalized, with \(d_j\le-1\);
3. \(\mathcal C\), normalized, with \(d_j=0\).

Report the feasible sign set, not a single detector-selected sign:

- 'forced_positive': positive feasible; negative and zero infeasible;
- 'forced_negative': negative feasible; positive and zero infeasible;
- 'fixed_on_recession_cone': zero feasible; positive and negative infeasible;
- 'optional_{...}': two or three signs feasible;
- 'no_recession_direction': the normalized base problem is infeasible;
- 'rank_deficient': the design rank gate failed.

The exact label may be simplified in the implementation, but the three
feasibility bits must be retained. When the improving cone exists, check each
detector-reported 'Inf', '-Inf', or finite '0' coefficient against its
corresponding positive, negative, or zero feasibility bit. Do not require the
whole reported vector to be one common LP ray: the maintained interface
documents coefficientwise infinity indicators, while this experiment has not
established that their joint sign pattern is a single returned recession
certificate. When the normalized cone is infeasible, all three sign bits are
necessarily false; handle overlap separately by requiring detector
'outcome = FALSE' and finite '0' indicators for every coefficient.

## 4. Revised fixture truth

| Fixture | Existence/class truth | Cone-level coefficient truth |
|---|---|---|
| overlap | finite interior MLE; no separation | normalized cone infeasible |
| 'mu_complete_shifted_forced': 'x = 0:3', 'y = c(0L, 0L, 1L, 1L)' | no finite MLE; complete | intercept forced \(-\); slope forced \(+\) |
| 'mu_complete_shifted_forced_mirror': 'x = 0:3', 'y = c(1L, 1L, 0L, 0L)' | no finite MLE; complete | intercept forced \(+\); slope forced \(-\) |
| 'mu_complete_centered_ambiguous' | no finite MLE; complete | intercept signs \(\{-,0,+\}\); slope forced \(+\) |
| quasi-complete | no finite MLE; quasi-complete | intercept fixed at zero on the recession cone; slope forced \(+\) |
| all successes, intercept only | no finite MLE; complete | intercept forced \(+\) |
| all failures, intercept only | no finite MLE; complete | intercept forced \(-\) |
| grouped/expanded quasi pair | same existence, class, and feasible sign sets | intercept fixed at zero; slope forced \(+\) |
| rank-deficient overlap | rank deficient, separation not run | no cone claim |

For the shifted complete fixture, \((-3,2)\) is an explicit certificate and
the inequalities force \(d_1>0\) and \(-2d_1<d_0<-d_1\). For the centered
ambiguity control, \((-1,2)\), \((0,1)\), and \((1,2)\) are explicit
negative-, zero-, and positive-intercept certificates. Mirrored certificates
are their negatives.

The shifted fixtures retain an exact forced coefficientwise direction test;
the centered fixture prevents a detector-selected LP solution from being
mistaken for a unique direction.

Zero-weight, finite-offset, and response-mask controls derived from the
centered fixture inherit intercept feasibility \(\{-,0,+\}\) and forced
positive slope. No executable truth is inherited from the old finite-intercept
assertion.

## 5. Independent compiled-objective checks

The exact-source drmTMB fit object exposes the compiled TMB objective as
'fit$obj$fn(par)' and the optimized fixed effects in 'fit$opt$par'. The
balanced overlap fixture has exact optimum \(\beta_0=0\), so every ray can use
the same deterministic zero base point. A revised harness must:

1. fit each fixture once only to obtain the exact retained model object;
2. assert 'length(fit$opt$par) == ncol(fit$model$X$mu)' and that every free
   entry is named 'beta_mu'; otherwise stop rather than infer indices;
3. require 'names(coef(fit, dpar = "mu"))' to equal
   'colnames(fit$model$X$mu)';
4. require 'fit$obj$env$parList(fit$opt$par)$beta_mu' to equal the extracted
   coefficients in that exact order;
5. set 'par_0 <- fit$opt$par; par_0[] <- 0';
6. set 'par_t <- par_0; par_t[] <- t * d', then require
   'fit$obj$env$parList(par_t)$beta_mu == t * d' in model-matrix order;
7. evaluate 'fit$obj$fn()' at the predeclared grid
   \(t\in\{0,0.5,1,2,4,8,16\}\);
8. retain the raw objective at every \(t\), ray, and fixture;
9. compare 'fit$obj$fn(par_t) - fit$obj$fn(par_0)' with the independent
   grouped-binomial negative log-likelihood difference. Differencing removes
   any fixture-constant combinatorial term.

Required rays:

- shifted complete: \((-3,2)\);
- mirrored shifted complete: \((3,-2)\);
- centered ambiguity control: \((-1,2)\), \((0,1)\), \((1,2)\);
- quasi-complete: \((0,1)\);
- all successes/failures: \(+1\)/\(-1\);
- overlap: both signs along each coordinate axis through \(\beta_0=0\).

For separated fixtures, every declared separating ray must be non-worsening
within \(10^{-8}\) and must show at least one strict improvement larger than
\(10^{-8}\) before numerical plateau. For overlap, the fitted objective must
be lower than both \(+t\) and \(-t\) perturbations on each coordinate axis at
\(t=1\), with direct and compiled objective differences agreeing within
\(10^{-8}\).

Finite optimizer coefficients, convergence codes, gradients, and 'pdHess'
remain descriptive symptoms only.

## 6. New artifacts and gate order

A licensed corrected run must create new files and must not overwrite the
original runner, failed TSV, or closeout receipts:

- 'scratchpad/separation-s0a2-cone-spike.R'
- 'scratchpad/separation-s0a2-cone-results.tsv'
- 'docs/dev-log/after-task/<date>-separation-s0a2-cone-experiment.md'
- 'docs/dev-log/plan-actual/<date>-separation-s0a2.md'

Gate order:

1. Preserve d740bd007 and its seven artifacts byte-for-byte.
2. Run rank and exact-row extraction checks.
3. Run the independent cone feasibility oracle.
4. Check detector class and its coefficient sign-pattern feasibility.
5. Run grouped/expanded equivalence.
6. Run direct and compiled objective rays.
7. Only if all preceding gates pass, run zero-weight, offset, and response-mask
   controls.
8. A revised binomial PASS creates eligibility for a separately approved
   hurdle slice; it does not authorize hurdle execution.

## 7. Falsifiers

Stop and retain the new failure if:

- the normalized cone feasibility problem and analytic fixture truth disagree;
- the strict-margin LP class disagrees with either analytic fixture truth or
  the detector's complete/quasi class;
- under separation, a detector coefficient status is incompatible with its
  corresponding coefficientwise feasibility bits;
- under overlap, the detector reports separation or any non-finite coefficient
  indicator;
- forced signs or mirrored tails disagree;
- grouped and expanded forms differ in existence, class, or sign feasibility;
- rank deficiency is labelled separation or overlap;
- direct and compiled objective differences disagree beyond tolerance;
- a declared separating ray worsens the compiled objective;
- overlap lacks an interior compiled-objective minimum;
- exact retained rows, offsets, weights, masks, trials, or design columns are
  reconstructed approximately.

## 8. Pre-run receipt and claim boundary

Before execution, record:

- current HEAD descends from d740bd007;
- original TSV SHA-256 remains
  efc0c296fa2e7117436593cfe662c454a5937506ad4bea9207f4ce7b92d2c030;
- original spike SHA-256 remains
  bda50d37438ec24c8146ab2fd482ccc294c373187303062ed0592a948acd919a;
- original symbolic contract SHA-256 remains
  43b655ddfbe4278a7dba8e0311572741d4c698c3e5a2027c80c2808073fa5fd4;
- the original seven S0 artifacts have no diff;
- R/**, src/**, tests, release surfaces, Lane B files, and original S0
  artifacts remain untouched;
- fresh session_ownership.sh and lane_preflight.sh receipts;
- no automation or process owns this worktree;
- the proposal commit leaves the worktree clean.

Execution requires explicit approval using this scope:

> Run corrected binomial S0-A2 only; no hurdle, S1, package integration, PR,
> push, or merge.

Passing S0-A2 would establish only the revised fixed-effect binomial-mu core.
It would not retroactively erase the first STOP, and it would not by itself
establish hurdle equivalence, GLMM theory, an exported diagnostic, warnings,
intervals, penalties, zi, count-family separation, or any public drmTMB
capability.

## 9. Review disposition

On 2026-08-08, the same three bounded review lenses reread the corrected
contract:

- Fisher/inference: **FINAL APPROVE**;
- Emmy/architecture and harness: **FINAL APPROVE**;
- Rose/lane integrity: **FINAL APPROVE**.

These verdicts approve the proposed contract as ready for an explicit
execution decision. They do not authorize the S0-A2 run, hurdle, S1, package
integration, a push, a PR, or a merge.
