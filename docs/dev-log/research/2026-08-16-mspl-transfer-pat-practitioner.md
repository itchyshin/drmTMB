# MSPL-for-boundaries — the practitioner view (Pat)

**2026-08-16 · Pat (applied-PhD-student user tester lens) · input to
`2026-08-16-drmtmb-mspl-transfer-packet.md` · written by the orchestrator from Pat's returned
content (the `user_tester` agent type carries no Write tool).**

## 1. What an ecologist does today when `sd-hat = 0`

The documented path is: `drmTMB()` → `check_drm()` → `confint(..., method="profile")` → read
`conf.status`/`profile.boundary` (`vignettes/first-week-intervals.Rmd:74-136`). The vignette's own
worked example is 18 groups, not 10 — the harder case isn't demonstrated, only described. Its
"when not to trust" list (lines 112-136) gives three facts and one remedy: (a)
`profile.boundary==TRUE` conditional coverage measured as low as 0.1021 (`?confint.drmTMB`
"Boundary intervals", lines 268-277); (b) the SD point estimate runs 8.3–15.8% low; (c)
`REML=TRUE` "helps here, measurably, without fixing everything" — moves coverage 0.9248→0.9463,
roughly halves bias, but "the boundary caveat above still applies under REML" (lines 279-287,
echoed in the vignette lines 126-131). The single remedy stated is "prefer more groups when the
design allows it" (`man/confint.drmTMB.Rd:293`, `vignettes/first-week-intervals.Rmd:119-120`).

That is where the path strands the user. An ecologist with 10 sites and a completed field season
cannot get more groups. `bias_correct`/`small_sample_df` only shift the Wald interval's centre and
width (`man/confint.drmTMB.Rd:129-149`) — they do not touch profile intervals and do not apply
once a fit is flagged at boundary. No documented option converts a boundary fit into a
non-boundary one. The actual severity is worse than the vignette's own example implies: at
`g10_n04_sd05`, 495/1000 replicates (49.5%) landed at the boundary flag, with conditional coverage
0.8566/0.8881 (`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/VERDICT.md:52`),
and one companion cell showed 0/89 conditional coverage against nominal 0.95
(`docs/dev-log/after-task/2026-08-09-d117-discharge-100k-regate.md:246-250`). A user who read only
the vignette would not learn that "up to half your fits" is a realistic number for their design;
they'd learn "it can happen, get more groups." Today's honest answer to "what do I do" is: report
the point estimate as indicative, do not trust the interval, and do not draw an inference about
among-group variance from this fit.

## 2. Would `sigma-hat` never being zero HELP or CONFUSE?

Two audiences split cleanly on the repository's own citation list. `?confint.drmTMB`'s references
(lines 445-450) include Wolak, Fairbairn & Paulsen (2012) on repeatability estimation in ecology —
the canonical use case is "is there genuine among-group variance," i.e., audience (a): is R (or
`sigma-hat`) distinguishable from zero. A softly-penalized estimator that structurally cannot
return exactly zero removes that answer at its root: the point estimate becomes uninformative
about whether the true SD is zero, by construction, not by evidence. That is a different question
from audience (b), who wants an honestly-calibrated interval and is currently told a flagged
interval "is not a repair for a boundary" (`man/confint.drmTMB.Rd:267`) — for them, a penalized
point estimate that shifts the anchor away from the boundary could genuinely help, provided the
interval machinery is re-derived around it (it is not yet — MSPL's own doc says
confint/profiles/logLik "remain deliberately unavailable" for the existing binomial route,
`man/drmTMB.Rd:177-178`).

Per the package's own evidence base (the Wolak citation, the whole D-117 arc being framed around a
random-intercept variance-component SD), audience (a) — "is the random effect there at all" —
looks like the primary ecology/evolution audience for RE-SD estimation, not a secondary one. Any
generalization of MSPL to RE-SD boundaries needs to be brutally explicit, in the very first
paragraph a user reads, that it trades away the "is it zero" answer for a "here is a stabilized
point and (eventually) a better interval" answer — and that lme4/glmmTMB will report exactly 0 on
the identical data. Silence on that trade would be the single most damaging documentation failure
available here.

## 3. Naming and defaults

Parsed cold, "MSPL" is an opaque acronym; nothing in the token tells a newcomer it means
"estimator that avoids the zero boundary." The package already has two adjacent, deliberately
distinct mechanisms: `penalty = drm_phylo_penalty(...)` produces a fit **labeled MAP** and
regularizes "a weakly-identified phylogenetic standard deviation" (`man/drmTMB.Rd:139-144`);
`estimator = "mspl"` is a *different* mechanism (fixed-effect Jeffreys + negative-Huber
covariance-Cholesky penalty) scoped to binomial-logit/probit/cloglog separation, and its own
design doc goes out of its way to say MSPL is "not... an alias for REML or the existing
phylogenetic penalty argument" (`docs/design/250-mspl-binomial-logit-alignment.md:19-23`). A third
generalized use of "penalize the RE-SD toward not-zero" would land in the gap between these two
existing, already-distinguished mechanisms — exactly the confusion the design doc pre-emptively
disclaimed against. Folding a general RE-SD-boundary fix into `estimator = "mspl"` would overload
a name users already have to learn means "binomial separation fix for fixed effects."

glmmTMB users expect a `REML=` switch and a boundary warning, nothing more. brms users expect
`prior(exponential(1), class="sd")` — an explicit, inspectable prior object. blme users expect
`cov.prior = gamma(...)` — a named prior argument distinct from the estimator choice. The
least-confusing surface for drmTMB, if this generalizes, is closer to `penalty`/blme's `cov.prior`
than to `estimator`: an explicit, opt-in, inspectable argument (e.g., extending
`drm_phylo_penalty()`-style objects to ordinary `sd(group)` targets) that a user must name and can
print/summarize, rather than a silent default or a second unexplained `estimator` token. **Do not
add a fourth vocabulary word; extend the one (`penalty`) that ecologists already have a foothold
on from the phylogenetic-SD case.**

## 4. The trust question

The repository's own documentation is unusually candid — it records a wrong pre-registered
prediction and shows the arithmetic
(`docs/dev-log/after-task/2026-08-09-d117-discharge-100k-regate.md:17`), and states plainly that a
"profile interval is not a repair for a boundary" (`man/confint.drmTMB.Rd:267`). That candor is
the trust asset, not the absence of boundary events. A default that silently never returns zero
would spend that asset: a reviewer who fits the same model in lme4 and gets exactly 0, then sees
drmTMB return 0.03, has no way to tell from the summary output alone whether that is honest
small-sample recovery or an artifact of an un-asked-for prior — unless the fit is conspicuously
labeled (as MAP fits already are, `man/drmTMB.Rd:143`) and the estimand change is stated up front.
Per this repo's own operating principle — usability is uncompromisable but honesty gates
everything — the read: **opt-in, clearly labeled, and documented as changing what is estimated (a
regularized point, not the MLE) reads as MORE trustworthy; a silent default reads as LESS
trustworthy**, specifically because it breaks comparability with lme4/glmmTMB without flagging it.

## Recommendation

**Explicit opt-in argument, never a default** — extend the existing `penalty`/MAP vocabulary (not
`estimator = "mspl"`) to ordinary `sd(group)` boundary targets, with the fit visibly relabeled and
interval machinery withheld until separately validated.

**Biggest user risk:** an ecologist compares a penalized-by-default drmTMB fit to an lme4 fit that
legitimately estimated zero variance, silently loses the ability to ask "is there any among-group
variance at all," and never learns the estimand changed underneath them.
