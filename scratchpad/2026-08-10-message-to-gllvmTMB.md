# Draft message to the gllvmTMB team — re: PR #952, experimental binary LA-MSPL

**STATUS: DRAFT, NOT SENT.** Posting to another repo is outward-facing and needs Shinichi's
go-ahead. Suggested destination: a comment on gllvmTMB PR #952.

*(Draft 3. Draft 1 told the team their campaign was aimed at the wrong target and called their tail
instrumentation a bug — both inferred, neither established. Draft 2 asked instead of asserting, and
their reply corrected two further things: they already have the negative-tail series repair, their
counter instruments the OPPOSITE (overflow) tail with rejection, and our "authors do not defer
probit/cloglog" was too broad — existence is link-general, the SOFTNESS SCALING is not. Draft 3
incorporates all of that. Sections 2 and 3 of draft 2 are now largely moot; kept only what still
carries information.)*

---

## Note from the drmTMB side — one reframe, one exchange, one self-flag

We implemented binary MSPL in drmTMB independently over 2026-08-09/10, then read Kosmidis & Firth
(2021), Sterzinger & Kosmidis (2023) and Sterzinger, Kosmidis & Moustaki (2026) end to end. We
landed on the same shape as #952, including the same point-only inference fence.

**What we actually looked at on your side:** the PR description and a grep of
`codex/lane-b-mspl-reconcile-951`. We have not read the implementation, so anything below about your
code is a question, not a finding.

### 1. The reframe — the open question may be Laplace, not the links

**Sterzinger & Kosmidis (2023), p. 6**, on their own existence argument:

> *"The condition on the boundedness of (2) from above is just one sufficient condition … A weaker
> sufficient condition is that the penalized objective diverges to −∞ … From the numerous numerical
> experiments we carried out, **we encountered no evidence that this weaker condition does not hold
> for the adaptive quadrature and Laplace approximations** … that the glmer routine of the R package
> lme4 employs."*

The proof runs through the **exact** marginal likelihood being bounded above by one, as a pmf. The
Laplace criterion carries no such bound, so for Laplace the authors offer numerical evidence rather
than proof — and that evidence is **glmer's**.

Meanwhile the *link* side is settled. **Kosmidis & Firth (2021), *Biometrika* 108(1):71–82, §3.1
p. 76:**

> *"If the link function is such that ω(η) → 0 as η diverges to either −∞ or ∞, then the proofs of
> Theorem 1 and Corollary 1 carry through **unaltered** … The logit, probit, complementary log-log,
> log-log and cauchit links are some commonly used link functions for which ω(η) → 0."*

with `ω(η) = g(η)²/[G(η){1−G(η)}]`; their **Table 1** (p. 77) tabulates it for all five and states
all vanish. Theorem 1 needs **only X of full rank**, and Corollary 1 holds for **any** penalty power
`a > 0`. The 2023 composite inherits this: its second half turns only on the likelihood being a pmf
(link-free), and the variance-component penalty is a function of the Cholesky alone.

If your LA-MSPL is Laplace-based as the name and NEWS entry suggest, then **the finiteness
guarantee for your logit route sits on exactly the same footing as probit and cloglog would** — the
authors' numerics, on a different implementation.

**The question we cannot answer from outside:** what is the corrected all-link B2 campaign designed
to establish? If it is partly *"are these links admissible"*, §3.1 may already cover it. If it is
finite-sample behaviour, coverage, or TMB-Laplace-specific finiteness, it is measuring something the
literature does not — in which case **logit belongs in it as a control**, not as the settled case.

We had this backwards until yesterday: our own design doc said the authors *"leave the probit and
cloglog bounds for the mixed-effects case as future work."* They do not. #952's scope note is closer
to right than ours was.

### 2. The exchange — cloglog's negative tail

Evaluating `log μ = log(1 − e^{−e^η})` directly is correct as `η → +∞` and **wrong as `η → −∞`**:
below `η ≈ −745.13`, `e^η` underflows to exactly 0, so `log(0) = −∞` enters the weight with a minus
sign and the Jeffreys weight becomes **`+∞`** — the wrong sign for a weight tending to zero.
Measured in our R implementation: `η = −745` → `−745.56` (correct), `η = −746` → `+∞`.

The series branch fixes it. For `x = e^η` small,

```
1 − e^{−x} = x(1 − x/2 + x²/6 − …)   ⇒   log μ = η + log1p(−x/2 + …)
```

giving the correct limit `log w → log n + η`. Exact to 0.00e+00 at `η = −1000` in our tests, and
continuous across the branch switch. (Ours is R; yours is C++, so it is the form rather than the
code that transfers.)

We noticed you instrument this region —
`mspl_cloglog_tail_extension_count`, split into `..._likelihood_...` and `..._weight_...`. **Is that
counting the same regime?** If so, your approach is better than ours: we fixed the tail and moved
on, you count how often it fires and separate the two sites. We would like to copy that.

Independently, we also declined to port a probability-scale clamp for the same reason your comment
gives — you keep *"the stable MSPL likelihood kernels (especially cloglog)"* while `estimator_id = 0`
retains its historical clamp path. Two codebases reaching that split separately is reassuring.

### 3. The self-flag — our `n_eff`, not yours

The 2023 Appendix binds the scaling as `c = 2√(p/n)`. drmTMB substitutes
`n_eff = Σ(trials × frequency)`, which equals `n` only for single-trial Bernoulli — the paper's
setting. **Your guard restricts LA-MSPL to single-trial Bernoulli, so you are inside the licensed
regime and we are the ones extrapolating.** Raising it only because it would bite whoever relaxes to
grouped binomial first ([drmTMB#984](https://github.com/itchyshin/drmTMB/issues/984)).

### One reading note, if MSPL output reaches a vignette

KF2021 Theorem 2 and §2.2: shrinkage is toward the model implying **equiprobability across
observations**, *"with respect to a metric based on the expected information matrix rather than …
Euclidean distance. Hence, the reduced-bias estimates are only typically, rather than always,
smaller in absolute value."*

Concretely, under `detectseparation`-certified separation we measured finite but large,
seed-dependent slopes — complete 177→745, quasi-complete 83→3 197 across five seeds, every fit
reporting convergence, with quasi running *larger* than complete. That is the soft penalty behaving
as specified; guaranteed interiority is not guaranteed shrinkage. But a reader taking the point
estimate as an effect size will be badly misled. The honest signal is the ratio — our SE ≈ estimate,
correctly saying *no information*.

And your point-only fence is confirmable at source. KF2021 §2.1: *"there will always be a parameter
vector with large enough components that the usual Wald-type confidence intervals … will fail to
cover regardless of the nominal level α that is used."*

### Where we are, and an offer

drmTMB's MSPL entry point stays **logit-only**. The Jeffreys helper is link-general internally, with
the composite threaded and tested, but not reachable from the public API. Reasoning, including two
corrections we had to make to our own analysis once the papers arrived, is in
`docs/design/253-mspl-nonlogit-links-derivation.md`.

If your B2 campaign is going to measure TMB-Laplace finiteness, we would rather **align fixtures and
seeds than duplicate** — we owe the same evidence for logit and have Totoro time. Happy to share
what we have either way.
