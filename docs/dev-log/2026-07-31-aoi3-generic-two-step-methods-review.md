# AOI-3 generic two-step uncertainty methods review

## Status and scope

**PRIVATE METHODS CONTEXT — not an AOI-3 clearance.** This review uses a
curated third-party public corpus about generic two-step estimation. It does
not establish a drmTMB-specific theorem, numerical implementation, finite-sample
target, comparator calibration, or public uncertainty claim.

The Gemini Notebook / NotebookLM corpus is
`7e0a29a6-523f-4d03-b3df-3b75ff372639`, titled *AOI-3 Bernoulli-NB2 two-stage
uncertainty design*. Project methods were not sent to the corpus: the
project-specific question was refused as an external-disclosure risk, so all
questions and generated artifacts were deliberately generic.

## Curated corpus

The final corpus contains five readable, third-party sources; Wikipedia,
StackExchange, a GitHub package page, and off-target papers were removed before
synthesis.

1. Ackerberg, Chen & Hahn, *A practical asymptotic variance estimator for
   two-step semiparametric estimators* ([Cemmap PDF](https://www.cemmap.ac.uk/wp-content/uploads/2020/08/CWP2211.pdf)).
2. Hardin, *The robust variance estimator for two-stage models* ([Stata Journal PDF](https://www.stata-journal.com/abstracts/st0018.pdf)).
3. Gonçalves et al., *Bootstrapping Two-Stage Quasi-Maximum Likelihood
   Estimators of Time Series Models* ([PDF](https://public.econ.duke.edu/~ap172/GHPS_JBES_2023.pdf)).
4. *Practical considerations for sandwich variance estimation in two-stage
   regression settings* ([arXiv PDF](https://arxiv.org/pdf/2209.10061)).
5. Varin, Reid & Firth, *An overview of composite likelihood methods*
   ([PDF](http://utstat.toronto.edu/reid/research/A09-300_edited_varin.pdf)).

NotebookLM report/audio/video generation was fired on 2026-07-31 and is
pending: report `6cb96f95-601a-4f19-9e75-4a6e4722dacb`, audio
`a01c5d3a-3803-4194-9625-e8e4f23a52bd`, video
`ca6290a6-73c0-415b-a2a5-4bd7195e7b95`.

## Grounded synthesis

The corpus consistently distinguishes a covariance conditional on an estimated
first step from a two-step covariance that propagates first-step uncertainty.
For a generic two-step estimator, the latter needs a joint or stacked
estimating-equation representation, including cross-stage derivative and score
terms; simply applying a second-stage Hessian or score covariance conditions on
the first step. Ackerberg et al. describe numerical equivalences that can make
the complete calculation look like a standard parametric two-step variance
formula, but that is not a license to omit the first-stage terms.

The generic literature supports a complete refit bootstrap as a useful
comparator precisely because every fitted stage is re-estimated in each
replicate. Gonçalves et al. emphasize that this substitutes computational work
for difficult derivative bookkeeping, while also making clear that its validity
depends on the resampling scheme and assumptions. It is therefore a validation
comparator, not automatic proof that any analytic sandwich is calibrated.

The corpus also warns against treating an available standard error as a
finite-sample guarantee. The arXiv review notes that naive two-stage sandwich
or bootstrap-standard-error intervals can have poor coverage in some settings.
Thus the AOI-3 all-attempt availability denominator, coefficient-wise
covariance/SE comparison, and held-out derived-prediction checks remain
necessary empirical gates rather than optional reporting.

## Consequences for the private AOI-3 design

- Keep the private analytic candidate explicitly two-stage: audit the full
  stacked score/bread/meat and coefficient ordering, not only the stage-2
  curvature.
- Keep a complete refit comparator: each replicate must regenerate data and
  refit every stage; reusing outer fitted margins or stage-2 curvature is not a
  full-refit check.
- Treat unavailable/non-finite analytic quantities as failed attempted
  quantities in any future calibration denominator.
- Do not freeze finite-sample pass thresholds from this generic corpus. They
  require the AOI-3R2 diagnostic receipt and a separately authorized,
  preregistered calibration plan.

## Explicit non-claims

This review does **NOT** cover a package API, the correctness of any drmTMB
sandwich code, Bernoulli × ordinary-NB2 asymptotics, a numerical-derivative
choice, an interval method, a coverage result, or a public association
inference claim.
