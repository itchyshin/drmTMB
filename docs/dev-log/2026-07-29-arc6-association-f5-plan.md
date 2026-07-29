# Arc 6 Association F5: public alpha interface — plan only

> **Status: Phase 0–2 planning only.** This document does not approve code,
> public documentation, a capability promotion, a new simulation, or a public
> `vcov()`/`confint()` claim.

## 🎯 GOAL

```text
PLATFORM: Codex. Deliver an approval-ready, bounded implementation plan for
Arc 6 Association F5: an alpha-only uncertainty surface, if Shinichi approves
it after the F4R closeout is merged. HEADLINE: turn the private F4R
high-information alpha interval-feasibility result into a precise eligibility
decision, not a generic association-inference claim. IN PARALLEL: inspect the
existing association object/API and audit wording/claim boundaries. DEFER:
eta-scale intervals, slopes, random effects, lower-information designs,
missingness, other family pairs, generic rho12 inference, and public capability
promotion. DISCIPLINE: no F5 code or public claim before explicit approval;
recheck PR #864 and current main first; if execution is approved, use focused
R tests and a separate validation decision before any compute; close with an
after-task report, handoff, and claim audit.
```

## Arc card

**Mode:** size; preparation only until explicit approval.  
**Requested outcome:** a new, clean Codex lane with an executable next-arc plan.  
**Mechanism authority:** read-only planning, durable handover, and PR #864
closeout only; no F5 implementation, compute, public docs, or ledger promotion.  
**Recommended executable arc:** 6–10 hours after approval, **inferred** from
the existing narrow association object, its S3 methods, tests, documentation,
and claim audit.  
**Arc 0 outcome:** one written eligibility contract for a possible alpha-only
public interface, including the evidence it may cite and the evidence it must
not imply.  
**State transition:** private F4R evidence -> approval-ready F5 design; no
capability metric changes in this planning arc.  
**Risk branch:** if F4R cannot support an operational public eligibility rule,
stop before implementation and return a decision memo plus the smallest
additional validation design.

| Segment | Planned time | Output / stop point |
| --- | ---: | --- |
| Orient and F4R re-read | 45 min | Confirm merged closeout and exact claim boundary. |
| Eligibility/API contract | 90 min | Alpha target, object class, failure behavior, exclusions. |
| Focused implementation and tests | 180–270 min | Only after approval; otherwise not entered. |
| Claim/docs audit | 60–90 min | Public wording remains bounded to the tested route. |
| Verification and closeout | 75–105 min | Focused tests, after-task, handoff, and review. |

## What the brain and repository already establish

F4R is a private PASS for the alpha-scale Godambe-Wald interval on the exact
fixed-effect, complete-pair Bernoulli x ordinary-NB2 intercept grid at
`n = 480` or `960`. It retains all 16,000 attempts; 15,978 have alpha point,
Godambe, and interval availability, while 22 boundary-unresolved attempts are
retained as unavailable. Coverage lies between 0.935 and 0.957, with no
provenance disagreement. The closeout is recorded in
`docs/dev-log/2026-07-29-arc6-f4r-completion-review.md`.

That result does **not** establish a generic association standard error or
interval, an eta interval, a sample-size rule, a slope/random-effect route, or
inference for other pair classes. The current public articles therefore retain
their beta language. F5 must not repurpose direct `biv_lognormal()` `rho12`
evidence as staged latent-normal `eta` evidence.

## Candidate F5 contract — pending owner decision

The only candidate public surface worth considering is deliberately small:

- an alpha-scale `vcov()`/`confint()` route for the named staged association
  object, with an exact `association = ~ 1` fixed-effect complete-pair
  Bernoulli x ordinary-NB2 fit;
- explicit alpha target naming and no eta-scale back-transformation claim;
- deterministic unavailable/failure output outside the tested eligibility
  predicate rather than an approximate fallback; and
- documentation that says the calculation was validated only on the frozen
  high-information fixture, not across arbitrary sample sizes or models.

The plan must first decide whether F4R can support a user-visible eligibility
predicate at all. It must **not** quietly turn `n >= 480` into a general rule:
F4R did not test that rule across margins, dispersion, predictors, or design.
If no defensible predicate exists, the correct F5 outcome is a private
developer API/diagnostic or a further validation design—not a public method.

## Ultra-plan receipt

**ARC PROGRAM:** size mode; planning completed here, execution 6–10 hours only
after explicit approval.  
**SEARCH:** repository and local brain retrieval; no external literature search
is required for the F4R-to-F5 scope decision.  
**LUNA SUITABILITY:** no for the core eligibility decision: it joins statistical
claim boundaries, S3 API behavior, and a public interface. A later mechanical
call-site inventory may use a low-cost scout.  
**ULTRA EFFORT:** no.  
**CONTEXT BRAKE:** fresh task required after F4R closeout; this handover is that
boundary.  
**D-43 PANEL:** not fired; F5 has no milestone claim until approval, evidence,
and implementation exist.

| Slice | Owner / effort | Dependency | Deliverable |
| --- | --- | --- | --- |
| S0: closeout rehydrate | Codex, medium | PR #864 green and merged | Verify F4R receipt and current `main`. |
| S1: object/API inventory | Codex, high | S0 | Exact existing class, S3 entry points, eligibility/failure behavior. |
| S2: inference boundary | Fisher + Rose review | S0 | Decide whether a public predicate is defensible. |
| S3: implementation | Codex, high | explicit owner approval + S1/S2 | Narrow alpha-only method and tests, or stop. |
| S4: prose/claim audit | Florence/Pat/Rose as appropriate | S3 | Reader-facing wording and failure guidance. |
| S5: verification/close | Rose + mechanical checks | S3/S4 | Tests, after-task, plan-actual reconciliation, handoff. |

## Questions still open

**Question — should F5 seek a public method now, or only an internal
diagnostic?** F4R validates one high-information fixture, but not a broadly
usable sample-size rule. **Recommendation:** approve only the planning and
contract work now; do not approve public implementation until the next task
identifies a defensible, fail-closed eligibility boundary. **Safe default:**
keep the current beta/public-withholding language. **What continues:** PR #864
closeout and the read-only object/API inventory.

## Explicitly deferred

Eta intervals; lower-information grids; slopes; random effects; missingness;
weights or offsets; additional families/pairs; generic `rho12`; REML; profile
or bootstrap interfaces; a public capability-ledger promotion; and changes to
the bivariate non-Gaussian/cross-family beta labels are all outside F5 unless
separately approved.
