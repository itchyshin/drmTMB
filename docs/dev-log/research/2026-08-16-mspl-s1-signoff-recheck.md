# S1 sign-off re-check — design 256 (Noether + Fisher)

**2026-08-16 · Cursor · adversarial default NOT ACCEPTED → both ACCEPTED after one required fix**  
**Lane:** `claude/mspl-boundary-s0-s1` @ `f91751a41` (+ this commit)  
**Worktree:** `.worktrees/mspl-s0s1`  
**Foreign lanes left alone:** missing-data (#1033 / Claude), 0.7 freeze
(`claude/07-freeze-3-evidence`), `claude/eloquent-driscoll-521fa1`, dirty primary checkout.

## Rehydration / classification (OWED §1)

| Item | Class | Live note |
| --- | --- | --- |
| Lane preflight + fetch/prune | **DONE** | Clean worktree; `HEAD == origin/claude/mspl-boundary-s0-s1` = `f91751a41` |
| S0 defect gates + RMSE pass | **DONE** | Committed under `docs/dev-log/simulation-artifacts/2026-08-16-mspl-s0-defect-gates/` |
| S1 derivation (design 256) | **DONE** | On lane branch; sign-off was unchecked |
| S1 Noether + Fisher re-check | **OWED → DONE** | This receipt |
| S2 implementation | **OWED** (unblocked by this receipt) | Narrow A1 `sd(group)` cell; `penalty` vocabulary; not started here |
| S3 campaign | **PROTECTED** | Needs prereg + Shinichi D-139 approval; not authorised |
| S4 heritability | **PROTECTED** | Not started |
| 0.7 candidate / freeze lane | **PROTECTED** | Do not touch shipped files on `main` while quiesce holds |
| Missing-data lane (#1033) | **PROTECTED FOREIGN** | Claude; do not edit `R/missing-data.R` / related |
| Research notes claimed "on `origin/main`" | **RETRACTED claim** | Live: notes live on **`claude/07-freeze-3-evidence` @ `6977b36e8`**, not on `origin/main`. Read via that ref only; do not merge the freeze lane to fetch them. |
| Primary checkout `AGENTS.md` dirty | **PROTECTED** | Never stage from `claude/handover-freshness-0718` |

## Noether re-check

**Verdict: ACCEPTED** after correcting §6.3's displacement bound wording.

| Check | Result |
| --- | --- |
| Theorem 1 (a)–(c), Cauchy step, (E2) | **PASS.** Continuity ⇒ $k(t)=\kappa t$; $\kappa\neq0$ ⇒ unbounded above ⇒ (E2) forces $\kappa=0$; $a$-only equivariant ⇒ affine ⇒ one-sided + (E2) fail. Pathological discontinuous Cauchy solutions correctly excluded by continuity. |
| Closed-form $I_g$ (5.1) | **PASS.** Re-derived: $I^{\mathrm{eff}}_{\sigma_u^2}=g m^2(m-1)/(2[\sigma^4+(m-1)\lambda_1^2])$, then $I_{aa}=I^{\mathrm{eff}}(2\sigma_u^2)^2$ recovers (5.1). D-117 table reproduced in R to printed digits. |
| Proposition 2 | **PASS.** Algebra: denom $>(m-1)m^2\sigma_u^4$ ⇒ $I_g<2g$. Grid max $I_g/(2g)=0.99976$. |
| $c_g$ rate / softness | **PASS at fixed interior $\Phi$.** $c_g=2\sqrt{q_v/g}$ ⇒ $\delta_g=O(g^{-1/2})$ when $\Phi(\kappa_0,m)$ bounded away from 0. |
| §8 (E1)–(E3), C3, rates, N4 | **PASS** as written for the chosen $Q_{\kappa_-,\kappa_+}$ and moving-anchor form. |
| Condition COMP | **PASS for S2 (Gaussian A1).** $\rho_{\beta\psi}=0$ exactly; non-Gaussian extensions must re-check (b). |

**Required fix (applied in design 256 §6.3 before ticking):** the line
$\delta_g \le c_g/\sqrt{2g}$ treated the **large-$\Phi$** scale as a uniform upper bound. That is
backwards: $\sqrt{2g}$ maximises the denominator, so $c_g/\sqrt{2g}$ is an *optimistic scale*, not
a ceiling. Independently: at $g=10$, $m=4$, $\sigma=0.7$, $\sigma_u=0.05$, actual
$\delta_g = c_g/\sqrt{I_g} \approx 8.1$ SE while $c_g/\sqrt{2g}\approx0.14$. Near-boundary
largeness is already stated in §5.2; §6.3 now matches. The numerical table (which uses actual
$I_g$ and starts at $\sigma_u=0.25$) was already correct.

**Not blocking:** numerical verification script for (5.1) remains uncommitted (UNVERIFIED ledger);
S2 must ship it as a unit test.

## Fisher re-check

**Verdict: ACCEPTED**, with two carry-forwards into any S3 prereg (not blockers for S2).

| Check | Result |
| --- | --- |
| §13 falsifiable as written | **PASS.** K1/K2/P1–P6 are operational; predictions vs claims are labelled. |
| K1 / K2 as killers | **PASS / right killers.** K1 is theorem-backed (implementation vs §3.2). K2 discriminates the moving residual-scale anchor from a unit accident; the second $\sigma$ cell is mandatory. |
| P3 size class | **PASS with lock-in.** Chung Property 1 mapping $\hat\sigma_u=\widehat{\mathrm{se}}\sqrt{c_g\kappa_-}$ is defensible **only** if $\widehat{\mathrm{se}}$ is the quadratic-approx scale from §6.2, not a singular-Hessian SE at the ML boundary. S3 prereg must freeze that definition. Size class 0.96–0.99 over-coverage is order-of-magnitude, not a hard gate. |
| P4 ML-defined-boundary scoring | **PASS / correctly binding.** Matches Fisher's transfer verdict: penalised `profile.boundary` ≈0% is structural flag deletion, not a repair. Paired-seed ML subset is mandatory. |
| P5 vs softness budget | **Carry-forward, not a reject.** Derivation already predicts max ~0.21 SE move at $g=10$ near the helpful region; beating REML's 0.828 conditional coverage may fail on arithmetic. Treat a large $g=40$ "repair" as an implementation error first (table §6.3). |

## What this receipt does **not** authorise

- S3 Totoro/DRAC campaign (D-139).
- Merging this lane to `main` while the 0.7 quiesce forbids shipped-file merges (docs-only would be
  fine later; S2 will touch `R/`/`src/` and must wait for quiesce or an owner exception).
- Touching the missing-data lane or the freeze-3-evidence branch.
- Relaxing REML×penalty mutual exclusion (§14).

## Next OWED after this receipt

**S2** — implement the derived penalty on the A1 iid `sd(group)` cell only, as a `penalty`
vocabulary extension (not a new `estimator` token), experimental, MAP-labeled, `confint`
withheld; ship tests including S0 Experiment A as regression; fail loudly on unclassifiable
family equivariance weights (§4.2). **Check the 0.7 quiesce before any shipped-file commit
aimed at `main`.**
