# Decision: D-93 is discharged under Reading B — REML's measured position stated

**2026-08-15 (evening) · decided by Shinichi · lane `claude/07-cran-ladder`**

## The decision, in his words

> **"Reading B — lift D-93 with REML stated"**

given in direct response to the closing question of
[`2026-08-15-d93-decision-packet.md`](2026-08-15-d93-decision-packet.md) §7, after the REML arm
had been measured
([`…d117-reml-arm/VERDICT.md`](../simulation-artifacts/2026-08-15-d117-reml-arm/VERDICT.md)).

## What this means, exactly

**Discharged:** the D-93 hold on the *inference question*. The bar for the random-effect SD
interval is an **honest interval at its achievable small-sample coverage** — the `g`-tapered
floor (`ss_floor(10) = 0.918`), which the measured profile route clears under both ML (0.9248)
and REML (0.9463) — with the shortfall, the point bias, the miss asymmetry, and the boundary
caveat all stated in user-facing terms. Not nominal-exact coverage.

**The attached condition — "with REML stated":** the capability claim must state REML's measured
position, not merely ML's. Concretely: on the tested A1 design (scalar Gaussian, `g = 10`, ML vs
REML, 400,000 paired replicates), `REML = TRUE` moves profile-interval coverage 0.9248 → 0.9463,
roughly halves the SD point-estimate bias (−10.9% → −4.6%), and collapses the upper-tail miss
asymmetry from 5.7:1 to 2.0:1 — measured on this cell only. Discharging this condition is the
companion change to this record (branch `claude/d93-reml-statement`).

**NOT decided by this:**

- **D-117** — still RECOMMENDED, NOT DECIDED. Its four conditions are met; the discharge remains
  a separate owner call. Nothing here touches it.
- **Whether `confint()`/docs should *recommend* REML** for small-`g` random-effect SDs, or change
  any default. "Stated" is disclosure; "recommended" is an API/scope decision with its own slice
  and review (handover step 4). **Open.**
- **The release itself.** 0.7.0 still proceeds only through the remaining gates: the five
  re-freeze preconditions
  ([`2026-08-15-070-refreeze-timing-decision.md`](2026-08-15-070-refreeze-timing-decision.md)),
  the platform matrix against the eventual frozen bytes, win-builder, the D-43 panel, and the
  submission decision — all unchanged, all still owed. `status_claim` remains **`tarball-clean`**.

## The trade this accepts, on the record

Reading B accepts that *documented* does the work *fixed* was originally meant to do — the trade
declined on 2026-07-27. What changed between then and now, and why this is not the same trade:
the defect as it stood then was a 0.509-coverage interval at half its proper width; the position
accepted now is a 0.4-point shortfall under REML (0.9463 vs 0.95) with near-balanced misses,
`lme4`-matching behaviour, boundary warnings on every interval route, and the residual bias
disclosed with numbers in four user-facing places. The gap between those two positions is the
A1 fix, the profile route, the REML measurement, and the disclosure work — all measured.

## Proposed brain delta (staged, NOT written — D-37)

The vault is not written by this lane without explicit approval. Proposed text for
`memory/DECISIONS.md`, to append to D-93 on Shinichi's approval:

> **✅ DISCHARGED 2026-08-15 (Shinichi: "Reading B — lift D-93 with REML stated").** The bar is
> the honest-interval reading, not nominal-exact. Decided on the D-93 decision packet after the
> pre-registered 400k REML arm measured 0.9248 → 0.9463 (CI excludes 0.95; NARROWS BUT DOES NOT
> CLOSE). Condition: REML's measured position stated in the capability claim (done, drmTMB PR —
> see repo record `docs/dev-log/release-audits/2026-08-15-d93-decision-reading-b.md`). D-117 and
> the release gates are untouched; 0.7.0 still proceeds only through the re-freeze preconditions
> and platform matrix.

> Related: brain `DECISIONS.md` D-93 / D-97 / D-117 · `2026-08-15-d93-decision-packet.md` ·
> `…d117-reml-arm/VERDICT.md` · `2026-08-15-070-refreeze-timing-decision.md`
