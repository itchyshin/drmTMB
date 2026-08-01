# Lane C C16 endgame programme

## Goal

Execute the authorised Lane C endgame against a clean `origin/main` source,
without treating the 30 current `not_implemented` rows as a homogeneous
backlog.  A ledger transition remains conditional on an exact live contract,
active carrier, independent oracle, retained all-attempt recovery, source
fingerprint, and fresh Fisher/Noether/Rose GO.  Failures remain visible as
durable blockers.

## Source and lane receipt

- Base: `origin/main` at `ea991e6da` (after the Lane A #854 merge and C14 #875).
- C16 worktree: `/private/tmp/drmtmb-c16-endgame`, branch
  `codex/lane-c-c16-endgame`.
- `lane_preflight.sh` found foreign Codex Lane B PR #858 and foreign
  documentation PR #869.  C16 owns neither their files nor their claims.
- The previous C15 branch is deliberately preserved and is not a C16 base.
- The DRM.jl sweep found fixed zero-one-beta mixture semantics only, not a
  reusable random-effect fitter.

## Programme map

| Wave | Cells | Work class | Earliest outcome |
| --- | --- | --- | --- |
| A | `mc-0583`–`mc-0587`, `mc-0593`–`mc-0597` | Canonical-source rerun and adjudication | Ten independent GO/BLOCK decisions; no package-code change is expected initially. |
| B | `mc-0577` | Evidence/review bridge | One ledger decision only if current-source equivalence and two missing reviews are obtained. |
| C | `mc-0570`, `mc-0578` | Ordinary `coi` q1 carrier then matching slope | Separate R/TMB/extractor/oracle/recovery decisions. |
| D | `mc-0603`–`mc-0607`, `mc-0613`–`mc-0617` | Structured atom endpoints | First one q1 provider per endpoint; no q2+ representation is implied. |
| E | `mc-0426` | NB2 structured-sigma q2 architecture | Phylo-only covariance-contract/oracle decision before admission. |
| F | `mc-0198`, `mc-0324`, `mc-0325`, `mc-0455`, `mc-0462`, `mc-0537` | Native representation frontiers | Individual Go/Block contracts; no generic bivariate/high-q switch. |

## Locked contracts and boundaries

Wave A is the first executable cohort.  All five providers are already
statically admitted for exact unlabelled q1 zero-one-beta `mu` and `sigma`
effects.  It will add source-pinned runners and provider-specific likelihood
oracles where missing, then **rerun the retained DGP contracts** on the clean
C16 source.  Historical fit output is never transferred as current evidence.
Every `(cell_id, provider, dpar)` pair receives its own named receipt with the
source SHA, runner hash, DGP/precision digest, exact formula, and declared
`mu` or `sigma` estimand.  `sigma`
uses the existing structured field in `log_sigma`; the legacy carrier name
does not license a different estimand.

`mc-0577` is not code work unless source equivalence fails: it has a retained
four-attempt recovery record but lacks the Noether/Rose review bridge.  The
ordinary `coi` cells require a new endpoint carrier; no `coi` result transfers
from `zoi`.  Structured atom cells require closed endpoint routing and remain
q1-only until a new contract explicitly opens a higher-dimensional target.

The six native-frontier rows are not simple parser omissions.  In particular,
univariate Gaussian q4 and a duplicate Gaussian bivariate spelling require a
census/representation decision rather than recovery; native bivariate
Poisson, skew-normal, and Tweedie require a named joint likelihood before any
formula can be admitted.

No profiles, intervals, coverage, bootstrap campaign, default/API broadening,
or GitHub Actions compute is in scope.  Local fixtures come first.  Any need
for Totoro or DRAC is stopped for separate approval.  Lane A association and
Lane B scale/interval work remain out of scope.

## Execution gates

For every attempted cell:

1. Pin and report the source SHA plus clean/dirty state.
2. Prove formula-to-map-to-TMB carrier routing and reject neighbouring forms.
3. Compare the complete likelihood plus latent penalty to an independent
   provider-specific dense oracle; include AD/finite-difference and
   nonzero-effect dependency checks.  The zero-one-beta oracles contain the
   full three-part mixture and precision penalty: `mu` injects the field into
   `eta_mu`; `sigma` injects it into `log_sigma` and records its unclamped
   range.  Both use an appropriate fixed/IID control; no `mu` fixture is a
   `sigma` oracle.
4. Retain every local recovery attempt, control, gradient, convergence,
   Hessian, boundary, and clamp result.
5. Obtain fresh Fisher, Noether, and Rose GO/BLOCK review.
6. Promote only GO cells, regenerate/check the ledger, and verify Mission
   Control's canonical source fingerprint and count.

The Wave A integration guard permits only `mc-0583`–`mc-0587` and
`mc-0593`–`mc-0597` to change.  Their paired q2-plus boundary rows
`mc-0695`–`mc-0704` must remain `rejected_by_design`; no profile or interval
status may appear.  A BLOCK receipt leaves its leaf unchanged.

## Context and sequencing brake

This programme is intentionally multi-session.  Wave A is the first bounded
implementation/recovery milestone; it has no authority to open Waves C--F.
Complete or block Wave A, then start a fresh task with its source-pinned
receipt before choosing the next wave.  C16 success is a truthful sequence of
independent decisions, not a pre-authorised `30 -> 0` claim.
