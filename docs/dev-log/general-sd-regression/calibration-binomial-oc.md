# Exact component-level operating characteristics for the Bernoulli screen

Status: preliminary deterministic analysis. It does not adopt the proposed
bands, authorize new seeds, or qualify a fitted Bernoulli model.

## Question and calculation

The approved calibration plan targets two-sided 95% fitted profile intervals.
It uses exact two-sided 97.5% binomial intervals for Monte Carlo rates at two
looks: 1,000 attempts per truth at look one, then 3,000 more and a cumulative
4,000 if the first look is ambiguous. The planned rate bands are coverage
[0.925, 0.975], null false-positive rate [0.025, 0.075], and valid-interval
fraction with a lower confidence limit of at least 0.950.

This script exactly enumerates the possible counts for one binomial gate at a
time. A component that passes or fails at look one stops; an ambiguous
component alone triggers look two. Two-sided bands create separate low- and
high-count failure ranges, which the calculation sums separately. The
probabilities have no Monte Carlo error, but they are not the operating
characteristics of the global campaign. The full campaign continues when any
required gate is ambiguous, and its metrics are dependent. This calculation
does not describe the distribution of fitted profile intervals.

## Results

Probabilities use two-sided 97.5% exact binomial intervals for the Monte Carlo
rate and the approved ordinary-condition bands. “Final” means the
one-component stopping rule above.

| Metric and true rate | Look-one pass | Look-one fail | Look-one ambiguous | Final pass | Final fail | Final inconclusive |
|---|---:|---:|---:|---:|---:|---:|
| Coverage, nominal 0.950 | 0.7973 | 0.0000 | 0.2027 | 1.0000 | 0.0000 | 0.0000 |
| Coverage, lower boundary 0.925 | 0.0108 | 0.0115 | 0.9777 | 0.0205 | 0.0213 | 0.9582 |
| Coverage, 1 pp below 0.915 | 0.0003 | 0.1411 | 0.8585 | 0.0003 | 0.5533 | 0.4463 |
| Coverage, 2.5 pp below 0.900 | 0.0000 | 0.7158 | 0.2842 | 0.0000 | 0.9996 | 0.0004 |
| Coverage, upper boundary 0.975 | 0.0084 | 0.0116 | 0.9800 | 0.0175 | 0.0225 | 0.9600 |
| Coverage, overcoverage 0.990 | 0.0000 | 0.9176 | 0.0824 | 0.0000 | 1.0000 | 0.0000 |
| False-positive rate, nominal 0.050 | 0.7973 | 0.0000 | 0.2027 | 1.0000 | 0.0000 | 0.0000 |
| False-positive rate, lower boundary 0.025 | 0.0084 | 0.0116 | 0.9800 | 0.0175 | 0.0225 | 0.9600 |
| False-positive rate, upper boundary 0.075 | 0.0108 | 0.0115 | 0.9777 | 0.0205 | 0.0213 | 0.9582 |
| False-positive rate, 1 pp above 0.085 | 0.0003 | 0.1411 | 0.8585 | 0.0003 | 0.5533 | 0.4463 |
| False-positive rate, 2.5 pp above 0.100 | 0.0000 | 0.7158 | 0.2842 | 0.0000 | 0.9996 | 0.0004 |
| False-positive rate, under-rejection 0.010 | 0.0000 | 0.9176 | 0.0824 | 0.0000 | 1.0000 | 0.0000 |
| Valid fraction, expected 0.990 | 1.0000 | 0.0000 | 0.0000 | 1.0000 | 0.0000 | 0.0000 |
| Valid fraction, floor 0.950 | 0.0093 | 0.0106 | 0.9801 | 0.0199 | 0.0214 | 0.9586 |
| Valid fraction, below floor 0.930 | 0.0000 | 0.6625 | 0.3375 | 0.0000 | 0.9990 | 0.0010 |

At either coverage boundary, this one-component procedure is inconclusive
about 96% of the time after the second look. It detects a rate 1 percentage
point beyond a boundary as a failure about 55% of the time by look two, and a
rate 2.5 points beyond with probability above 99%. A true rate of 0.990 is
rejected by the coverage band with probability effectively one at look two,
so the approved two-sided band can detect substantial overcoverage as well as
undercoverage. These are marginal single-gate properties only.

## Interpretation limits and required review

At truth zero, each planned attempt belongs to exactly one of three categories:
valid and covering zero, valid and excluding zero, or invalid. Thus planned
coverage plus planned false-positive rate equals the valid fraction. Conditional
on valid intervals, coverage and false-positive rate are complements. The
component scenarios in the table are marginal calculations; values from
different rows must not be combined as an independent joint scenario. A full
campaign analysis must preserve the zero-truth three-category outcome and its
dependence with estimated bias and interval validity.

The current contract uses all planned attempts for coverage and FPR; invalid
intervals are noncoverage and are not false positives. The separate validity
gate remains. Approximate bias intervals are descriptive diagnostics and are
not acceptance gates. The completed corrected first-look worker requested
97.5% fitted profile intervals. That run is exploratory and does not establish
the 95% profile-interval target.

The target domain is only the native logit Bernoulli q1 random-intercept
simulation described in `native-calibration-design.md`: 160 groups with 16
observations each, group predictor from -1 to 1, observation predictor
standard normal, fixed effects (-0.3, 0.6), intercept log-SD log(0.8), and
SD-slope truths -0.5, 0, and 0.5. The analysis does not generalize to other
Bernoulli designs, random-effect types, or Julia.

Independent review decided that the two approximate bias intervals remain
diagnostics only. The complete current synthetic stopping rule has now been
evaluated for 1,000 campaigns per scenario, with attempt-level dependence and
Monte Carlo uncertainty, in
`evidence/campaign-oc-bias-diagnostics-20261019/`. That analysis checks the
decision procedure only. It does not justify the margins from literature or
calibrate profile intervals for fitted Bernoulli models. A clean 95%-profile
fit campaign and recovery/uncertainty evidence remain outstanding.

## Reproduction

Run `Rscript tools/general-sd-regression/calibration-binomial-oc.R`. The
calculation is deterministic and uses no random numbers, model fits, or remote
compute.
