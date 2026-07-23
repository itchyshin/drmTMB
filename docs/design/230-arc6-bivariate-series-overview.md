# Arc 6 bivariate series — mixed-family implementation overview

> **Implementation authority 2 of 2 (roadmap only).** This document governs
> the order and boundaries of Arc 6's two-response programme. The linked
> Arc 6.1 Ultra Plan is historical planning provenance; the implemented
> [Arc 6.2 contract](232-arc6-2-gaussian-nbinom2-contract.md), exact
> [Arc 6.3 contract](233-arc6-3-bivariate-lognormal-contract.md), and
> source-level [Arc 6.4 contract](234-arc6-4-bivariate-student-contract.md)
> record the current development boundaries.
> Neither document authorizes recovery, capability promotion, Julia,
> `meta_V()`, or CRAN work.

## Purpose

Arc 6 develops a coherent series of **two-response** models after 0.6. It is
not a promise of every possible pairwise distribution. The programme has three
separate routes, because the same word “correlation” answers different
scientific questions in different families:

| Route | When it is appropriate | Main estimand | Public surface |
| --- | --- | --- | --- |
| Existing exact Gaussian model | Both responses are Gaussian | Gaussian residual `rho12` | `biv_gaussian()` |
| Margin-first latent-normal association | The two fitted margins must stay numerically unchanged and residual co-occurrence is the question | latent-normal correlation `eta` | `associate_pairs(..., kernel = latent_normal())` |
| Direct exact family kernel | A shared mechanism has a stronger biological interpretation than a copula | kernel-specific parameter | later, named construction only |

`corpair()` remains a fourth, distinct future layer: correlation among named
latent Gaussian random effects. It is neither `rho12` nor the within-row mixed
response association.

## Architecture that scales without pretending all pairs are the same

For the general mixed-family route, fit each margin first on an identical,
stable complete-pair analysis set and retain an immutable snapshot of its
estimates, formula, response values, row identity/order, and package
provenance. Then estimate a named association kernel conditional on those
snapshots:

```r
fit_1 <- drmTMB(..., family = <margin 1>, data = paired_complete_data)
fit_2 <- drmTMB(..., family = <margin 2>, data = paired_complete_data)

assoc <- associate_pairs(
  fit_1, fit_2,
  kernel = latent_normal(),
  association = ~ 1
)
```

`associate_pairs()` is a provisional name that Boole and Emmy must confirm
before code. An explicit named kernel is compulsory; independence is not a
hidden default. The initial implementation has fixed effects, literal 0/1
binary data where applicable, complete pairs, and intercept-only `eta`.

For Gaussian-copula `latent_normal()`, low-dimensional likelihood evaluation
is exact in the two-response setting:

| Margin combination | Stage-2 observation contribution |
| --- | --- |
| continuous × continuous | copula density times the two marginal densities |
| continuous × discrete | continuous density times a conditional-normal CDF difference |
| discrete × discrete | bivariate-normal rectangle, evaluated as four CDF corners |

For discrete margins, arbitrary PIT residuals are prohibited: the likelihood
uses the appropriate CDF jump or rectangle. `eta` is a standard-normal latent
association conditional on the frozen margins. It is not, in general, a
response-scale Pearson correlation; derived response-scale summaries must be
covariate-specific and separately validated.

This is the package adaptation of established two-stage copula/IFM reasoning,
not a novelty claim. The technical and comparator evidence is retained in
[`2026-07-23-arc6-latent-normal-research-report.md`](../dev-log/2026-07-23-arc6-latent-normal-research-report.md),
including MCMCglmm, brms, GLLVM, and direct count-model precedents.

## Arc count and stopping rule

**Arc 6 is an umbrella programme, not one enormous implementation task.** It
has eight proposed, sequential implementation subarcs. Each is a separate
fresh task with its own symbolic review, code, oracle, simulator, user
contract, review, and owner stop. This keeps a new likelihood or CDF adapter
inside one workable context window and stops a difficult pair from consuming
the next pair's validation budget.

Arcs **6.1--6.4** are implemented development slices at their separately
recorded evidence levels. Arcs 6.5--6.8 are a visible order of work, not
standing authorization to implement them. Direct kernels and research-gated
classes receive a number only when the owner opens them.

## The eight proposed implementation subarcs

Every row below needs an independent oracle, joint simulator, error contract,
and owner gate. “Later” means unimplemented and unsupported.

| Arc | Pair class | First representative | Association form | Principal risk | Status |
| --- | --- | --- | --- | --- | --- |
| Comparator | Gaussian × Gaussian | existing model | exact Gaussian `rho12` | compatibility only | existing comparator; never replaced |
| 6.1 | continuous × binary | Gaussian × Bernoulli | density × conditional-normal Bernoulli probability | prevalence, separation, boundary `eta` | implemented; regression smoke recorded separately |
| 6.2 | continuous × overdispersed count | Gaussian × NB2 | density × conditional-normal count-CDF interval | count tails and CDF cancellation | implemented; point-estimate-only, smoke recorded separately |
| 6.3 | lognormal × lognormal | two lognormal margins | exact bivariate normal on log response scale | scale interpretation | implemented; source-tested only, no smoke/recovery/inference claim |
| 6.4 | Student-t × Student-t | two compatible Student-t margins | exact bivariate t with a shared degrees-of-freedom contract | common-`nu` identification and tails | implemented; source-tested only, no smoke/recovery/inference claim |
| 6.5 | binary × binary | paired Bernoulli | bivariate-normal rectangle | rare cells and near separation | later |
| 6.6 | binary × count | Bernoulli × NB2 | bivariate-normal rectangle | rare rectangles and tails | later |
| 6.7 | count × count | NB2 × NB2 | bivariate-normal rectangle | tail stability and latent-scale interpretation | later |
| 6.8 | cross-pair integration | all previously admitted Arc 6 pair classes | common post-fit contract plus exact-special compatibility checks | accidental pair-specific drift | final series gate before new classes |

Ordinal/categorical and zero-modified, bounded, or nonstandard-CDF margins
are **not yet implementation arcs**. They first need separate feasibility
research on cutpoints, atoms, CDF/quantile semantics, and identification. A
direct shared-Gamma, odds-ratio, or directed conditional model is likewise a
new demand-led arc, not an eighth automatic item.

### Arc 6.8: mixed-family integration gate

Arc 6.8 is deliberately **not** a new likelihood or a claim that arbitrary
families are supported. It is the series-level check that the several admitted
mixed pairs actually form one coherent user-facing system. It begins only after
the earlier relevant arcs have their individual evidence.

Its required matrix uses every admitted representative (at minimum Gaussian ×
Bernoulli, Gaussian × NB2, Bernoulli × Bernoulli, Bernoulli × NB2, and NB2 ×
NB2; plus lognormal × lognormal and Student-t × Student-t if those special
arcs were approved). It verifies that:

1. each margin remains identical to its frozen standalone fit;
2. pair order is symmetric where the declared likelihood is symmetric, with
   response labels and predictions swapped correctly;
3. `associate_pairs()` has one stable contract for provenance, diagnostics,
   `fitted()`, marginal prediction, joint simulation, and unsupported-method
   errors across all latent-normal pairs;
4. exact-special models retain their own honest `rho12` scale rather than
   being silently relabelled as latent-normal `eta`; and
5. no route leaks Gaussian-only `rho12`, `corpair()`, interval, or capability
   semantics into a mixed pair.

Arc 6.8 needs no new family merely to run its tests. It tests the **several
mixed distributions together** after their individual likelihoods have earned
admission, then stops for an owner decision: open a new CDF-adapter research
arc, choose a direct kernel, or return to the Q-series.

### Exact-special-family batch

Some same-family pairs deserve exact joint models instead of the general
two-stage copula route.

For two lognormal responses, the exact special model is

\[
(\log Y_1,\log Y_2) \sim N\left(
  \begin{bmatrix}\mu_1\\\mu_2\end{bmatrix},
  \begin{bmatrix}
    \sigma_1^2 & \rho_{12}\sigma_1\sigma_2\\
    \rho_{12}\sigma_1\sigma_2 & \sigma_2^2
  \end{bmatrix}
\right).
\]

Here `rho12` has the honest, exact meaning **correlation of log-scale
residuals**. It is not the raw-scale correlation. At fixed covariates the
derived raw-scale correlation is

\[
\operatorname{cor}(Y_1,Y_2)=
\frac{\exp(\rho_{12}\sigma_1\sigma_2)-1}
{\sqrt{[\exp(\sigma_1^2)-1][\exp(\sigma_2^2)-1]}}.
\]

For Student-t × Student-t, `biv_student()` uses a bivariate-t distribution
with one **shared** degrees-of-freedom parameter and `rho12` as the
scatter/residual correlation. Its `sigma1` and `sigma2` are Student-t scales,
not standard deviations. At finite `nu`, `rho12 = 0` is uncorrelated but not
independent because both responses share the same row-level mixing draw. A
generic skew-normal ×
skew-normal model is *not* in this batch: a joint skew-normal distribution has
dependence and skewness parameters that interact, so a single Gaussian-style
`rho12` would be misleading.

## Direct kernels remain a deliberately separate branch

The latent-normal route is a general association engine, not the answer to
every scientific question. Later direct kernels can be superior where their
parameter describes a known process:

| Candidate kernel | Candidate pair | Estimand | Required proof before a plan |
| --- | --- | --- | --- |
| shared-Gamma bivariate NB | compatible overdispersed counts | shared intensity and derived covariance | preserve the selected drmTMB marginal mean and dispersion contracts |
| four-cell odds-ratio model | literal Bernoulli × Bernoulli | conditional odds ratio | solve all four cells and establish compatibility limits |
| directed conditional model | a scientifically ordered pair | conditional effect in declared direction | preserve both stated marginal/prediction meanings |

No direct kernel is a shortcut around the adapter, oracle, simulator,
diagnostic, and evidence requirements. It becomes an additional named model,
not an interchangeable `rho` switch.

## Per-lane deliverables and common ceiling

Each admitted pair or batch requires, before a public capability statement:

1. a written likelihood and parameter constraints that agree with the R API
   and TMB implementation;
2. an independent R oracle and exact joint simulator;
3. the kernel-appropriate zero-association check, response-swap,
   normalization, and boundary checks; plus the relevant
   discrete-tail/cancellation checks (for exact bivariate Student-t,
   `rho12 = 0` must explicitly remain non-product at finite `nu`);
4. marginal response-scale `fitted()` and `predict()` semantics, a joint-pair
   simulation contract, an association extractor, and explicit errors for
   unsupported Gaussian-only methods;
5. a pre-registered recovery ledger retaining every attempt; and
6. fresh Boole, Emmy, Gauss, Curie, Fisher, and Rose review at the appropriate
   gate.

For the first mixed lanes, the ceiling is a fixed-effect, complete-pair,
intercept-only `eta` **point estimate plus diagnostics**. The stage-2 Hessian
treats stage-1 margins as fixed and therefore cannot justify a standard error,
Wald interval, profile interval, coverage assertion, or capability-tier
promotion. Those require a later validated sandwich/Godambe route or a
bootstrap that refits both stages.

## Decision and compute gates

1. Arc 6.2 owner approval authorized the two named development smokes only:
   Arc 6.1 regression and Arc 6.2 new-pair, each with a separate ledger.
2. Smoke evidence does not authorize recovery, inference, or capability
   promotion.
3. Only after smoke evidence and a separate owner decision may a retained
   all-attempt campaign run on Totoro or DRAC; never GitHub Actions.
4. Each next representative pair or exact-special batch has its own symbolic,
   API, and inference review before implementation.
5. Mission Control receives a feasibility table describing planned, built,
   and evidenced lanes. Its capability counts remain derived from the existing
   ledger and unchanged unless a separate decision and evidence warrant it.

## Explicit deferrals

Until a later owner decision, Arc 6 excludes association slopes, random,
phylogenetic, and structured effects; partial pairs; offsets; weights;
`mi()`; `meta_V()`; REML; Julia; CRAN; generic family-pair claims; interval or
coverage claims; and all capability promotion.
