# C17-C1 support-floor attainability audit

## Question

Does the C17-C1 rule requiring at least two observed zeroes, two observed ones,
and ten interior observations in every one of 64 groups provide a reliable
hard gate for the exact approved DGP with 50 observations per group?

This is a decision-support audit. It does not change the frozen gate, promote
`mc-0570`, or authorize a merge.

## Exact calculation

For group random effect \(b_g \sim N(0, 0.45^2)\), define

\[
p_g = \operatorname{logit}^{-1}(0.10 + b_g), \qquad
z = \operatorname{logit}^{-1}(-0.40) = 0.4013123.
\]

Each of the 50 observations falls into one of three categories with
probabilities

\[
P(Y=0\mid b_g)=z(1-p_g),\quad
P(Y=1\mid b_g)=zp_g,\quad
P(0<Y<1\mid b_g)=1-z.
\]

Conditional on the number of boundary observations \(B\sim
\operatorname{Binomial}(50,z)\), the number of ones is
\(O\mid B,b_g\sim\operatorname{Binomial}(B,p_g)\). The exact conditional
group-pass probability is therefore

\[
\sum_{B=4}^{40} P(B)
\{P(O\le B-2\mid B,b_g)-P(O\le 1\mid B,b_g)\}.
\]

Base R numerical integration over \(b_g\) gives a marginal per-group pass
probability of `0.9961244898`. Because the 64 group effects and observations
are independent under the DGP, the probability that every group passes in one
M=64 attempt is

\[
0.9961244898^{64}=0.7799585313.
\]

The probability that all four frozen M=64 attempts pass is therefore

\[
0.7799585313^4=0.3700718500.
\]

Thus the hard gate rejects a correct DGP realization with probability
`0.62992815`. Its expected number of failing groups is only `0.248` per M=64
attempt, but one such group fails the entire attempt.

The calculation is reproducible with base R:

```r
zoi <- plogis(-0.40)
group_pass_given_b <- function(b) {
  coi <- plogis(0.10 + b)
  vapply(coi, function(p) {
    boundary_n <- 4:40
    sum(
      dbinom(boundary_n, 50, zoi) *
        (pbinom(boundary_n - 2, boundary_n, p) -
           pbinom(1, boundary_n, p))
    )
  }, numeric(1))
}
p_group <- integrate(
  function(b) group_pass_given_b(b) * dnorm(b, 0, 0.45),
  -Inf, Inf, rel.tol = 1e-12, subdivisions = 1000
)$value
c(
  per_group = p_group,
  all_64 = p_group^64,
  all_four_attempts = p_group^(64 * 4)
)
```

## Expected four-attempt outcomes

| Attempts passing the all-groups floor | Probability |
|---:|---:|
| 0/4 | 0.0023 |
| 1/4 | 0.0332 |
| 2/4 | 0.1767 |
| 3/4 | 0.4176 |
| 4/4 | 0.3701 |

The prospective run-3 outcome, 2/4 attempts passing the support floor, has
probability `0.1767` under the exact DGP. It is not unusual evidence against
the generator or estimator.

## Separation from estimator performance

All four prospective M=64 fits passed convergence, Hessian, gradient,
non-boundary SD, mode-correlation, rung-mean parameter-recovery, and
`lme4::glmer()` comparator gates. The two support-floor failures also had
finite interior `sd_coi_hat` values (`0.5028` and `0.3986`), mode correlations
of `0.710` and `0.564`, and maximum gradients below `0.00064`.

The observed failures therefore measure sparse within-group atom information,
not failure to fit or recover the exact scoped model. They are important user
warnings: an individual group with no observed ones or only one observed atom
cannot strongly identify its own conditional mode. They do not directly
contradict recovery of the population-level fixed effects and latent SD at the
approved M=64 rung.

## Design options

| Option | Consequence under the exact DGP |
|---|---|
| Treat the two-per-atom floor as an information warning | Retains every unconditional attempt and all estimator gates; describes the actual limitation without a 63% stochastic false-block rate. |
| Require at least one zero and one one per group | All-four pass probability rises to `0.8760`, but the threshold remains an arbitrary realization gate. |
| Keep the two-per-atom hard floor and use 80 observations/group | All-four pass probability rises to `0.9530`, but this changes the claimed information regime from the approved 50 observations/group. |
| Keep the current hard floor at 50 observations/group | A correct four-attempt campaign passes only 37% of the time; repeated reruns would invite seed selection. |

## Recommendation

Follow the governing C17 discipline: retain the unconditional denominator,
keep every estimator and recovery gate hard, and convert the per-group atom
floor into a visible sample-information warning. State that M=64 with 50
observations/group supports population-level point-fit recovery, while groups
with fewer than two observed zeroes or ones may have weakly identified
conditional modes.

This revision requires owner authorization because it changes the later Ultra
Plan's explicit hard gate. Without that authorization, C17-C1 remains blocked,
the carrier stays branch-only, and C17-C2 must not begin.
