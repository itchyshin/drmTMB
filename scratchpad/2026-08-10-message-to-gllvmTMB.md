# Reply to the gllvmTMB team — re: PR #952

**STATUS: DRAFT, NOT SENT.** Needs Shinichi's go-ahead.

*(Supersedes drafts 1-2, which are in git history. Draft 1 asserted things inferred from a PR body
and a grep. Draft 2 asked instead. Their reply corrected three of our claims, so this is a reply,
not a note.)*

---

Thank you — that corrects us on three counts and we have amended our docs accordingly.

**1. The cloglog tail: our inference was wrong twice over.** You already have the negative-tail
series repair, and your `mspl_cloglog_*_tail_extension_count` instruments the **opposite** extreme
(`η > 690`, near overflow), rejecting any MSPL fit that touches it rather than returning it. We had
guessed it was catching the underflow regime we hit. It wasn't, and you'd already handled that one.

**2. Our "the authors do not defer probit/cloglog" was too broad, and you drew the line exactly
right.** Verified against 2023 §7, p. 7: `c = 2√(p/n)` comes from a delta-method argument **at
β = 0**, where logit's `ω(0) = ¼` gives `Var(η̂) ≈ 4p/n`. Probit's `ω(0) = 2/π ≈ 0.637` gives
`c ≈ 1.25√(p/n)` — a different constant, and Theorem C.1's gradient bound carries the same
logit-derived constants.

So the split is: **existence** link-general and proved (KF2021 Thm 1, §3.1, Table 1); **softness /
asymptotics** logit-specific and genuinely future work. Our design doc had originally said the
right thing, we "corrected" it into being wrong, and you caught it. Fixed in
`docs/design/252` §7 and `253` Addendum 3.

A consequence we hadn't drawn: **drmTMB's `c_n = 2√(p/n_eff)` would be the wrong constant for
probit/cloglog** — not merely unproved. That is now a second, link-specific reason our guard stays,
alongside the link-independent Laplace one.

**3. B2 keeping all three links is right**, and your framing is clearer than our question: the
campaign tests the implementation and finite-sample behaviour, with logit as the necessary control.
Understood.

**Where we differ, and we'd value your view.** Your point 3 says finite estimates and a finite
penalized Hessian *"do not license Wald SEs **or intervals**."* drmTMB currently ships MSPL **Wald
standard errors** while blocking intervals — `vcov()` and `summary()` work; `confint`, `profile`,
`logLik`, `AIC`, `BIC`, `anova` all error.

Our reasoning was that KF2021 §2.1 condemns the *intervals* specifically, and that a reported SE is
a legitimate scale summary. Yours is the stricter and possibly better position: a reported SE
invites the user to build the interval that fails.

We have one piece of evidence bearing on it — a 60,000-fit pre-registered calibration study
(15 cells × 1000 reps × 4 engines, logit) measuring `R = mean(SE)/sd(β̂)`. In the **identified**
regime MSPL SEs are calibrated, `R ∈ [0.93, 1.05]`. In deep separation the ratio stops being
interpretable, because the point estimates degenerate — at `η_d = −10`, 996/1000 replicates take
essentially one value, so `sd(β̂)` measures atom-hopping rather than sampling variability. Which
arguably supports *your* fence more than ours.

If you have a sharper argument for blocking SEs outright we would rather align than diverge on this.

**Offer stands:** if B2 measures TMB-Laplace finiteness, we'd rather share fixtures and seeds than
duplicate — we owe the same evidence for logit and have Totoro capacity.
