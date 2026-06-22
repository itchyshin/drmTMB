# Ayumi Follow-On Implementation Slices

> Implementation-scope update: this file captured the phylo-first follow-on
> after the Ayumi balance research arc. The broader structured random-effect
> implementation scope is now tracked in
> `docs/design/207-structured-random-effect-balance-100-slices.md` and its
> validator-owned dashboard ledgers.

## Purpose

This is the follow-on implementation arc after the Ayumi phylogenetic balance
research plan. The previous 100 slices answered the status question. This plan
targets the remaining capability gaps without changing the public claim
boundary.

The target is route-specific completion: native TMB ML, native TMB REML,
direct DRM.jl, and R-via-Julia each need their own fit, inference, coverage,
bridge, documentation, and public-reply gates.

## Boundaries

- Do not call q4 Patterson-Thompson REML HSquared AI-REML.
- Do not use REML or AI-REML wording outside exact-Gaussian cells with direct
  derivation and validation.
- Do not promote the R bridge until native R, direct DRM.jl, and R-via-Julia
  parity are all row-specific and current.
- Do not claim calibrated profile/bootstrap coverage until coverage has been
  evaluated for the target row.
- Do not claim 10,440-tip sigma-phylo intervals from small smokes, target
  availability, or direct Julia source availability.
- Do not post the Ayumi issue reply until the exact final text is approved.

## Slice Plan

| Slice | Phase | Task | Deliverable | Gate |
| --- | --- | --- | --- | --- |
| F001 | Rehydrate | Re-read A001-A100 closeout and A099 gate | current-state note | no stale assumption |
| F002 | Rehydrate | Refresh live issue access and latest Ayumi context | issue refresh note or inaccessible note | no reply from stale context |
| F003 | Rehydrate | Map open issue IDs across drmTMB and DRM.jl | issue ledger row | blockers named |
| F004 | Rehydrate | Re-run mission-control validator | check-log entry | validator green |
| F005 | Rehydrate | Re-run focused phylo native ML tests | check-log entry | focused tests green |
| F006 | Rehydrate | Re-run focused native REML rejection tests | check-log entry | rejection boundary green |
| F007 | Rehydrate | Re-run direct DRM.jl q4/profile symbol smoke | check-log entry | direct status current |
| F008 | Rehydrate | Re-run R-via-Julia bridge path smoke | check-log entry | bridge route current |
| F009 | Rehydrate | Freeze route vocabulary for this arc | dashboard or design row | stable terms |
| F010 | Rehydrate | Write after-start report | after-task note | next agent recoverable |
| F011 | Native REML Math | Define the exact Gaussian q1 sigma-side REML target | derivation note | target explicit |
| F012 | Native REML Math | Compare sigma-side restricted score with ML score | derivation note | terms match code symbols |
| F013 | Native REML Math | Define matched `mu+sigma` REML covariance target | derivation note | covariance target explicit |
| F014 | Native REML Math | Identify fixed-effect nuisance dimensions for sigma-side REML | derivation note | no hidden df assumption |
| F015 | Native REML Math | Audit whether q2/q4 REML belongs in native TMB or DRM.jl first | decision note | route chosen |
| F016 | Native REML Math | Define boundary behavior for tiny scale SDs | design note | no silent success |
| F017 | Native REML Math | Specify Hessian/AI diagnostics needed before promotion | diagnostic checklist | exact-Gaussian only |
| F018 | Native REML Math | Review derivation with Noether/Gauss criteria | review note | equation-code consistency |
| F019 | Native REML Math | Add rejection-preserving tests for unimplemented REML cells | test plan | current failures intentional |
| F020 | Native REML Math | Bank native REML derivation decision | after-task note | go/no-go named |
| F021 | Native REML Prototype | Add internal q1 sigma-side REML prototype behind a gate | internal code or rejection note | not public |
| F022 | Native REML Prototype | Add deterministic tiny simulation for q1 sigma-side REML | focused test | finite recovery |
| F023 | Native REML Prototype | Compare prototype against native ML on same estimand where valid | diagnostic row | estimand separation clear |
| F024 | Native REML Prototype | Add status payload for q1 sigma-side REML | dashboard row | status explicit |
| F025 | Native REML Prototype | Add early rejection for unsupported q1 edge cases | test | clear error |
| F026 | Native REML Prototype | Add matched `mu+sigma` prototype decision | code or deferral note | route explicit |
| F027 | Native REML Prototype | Test matched `mu+sigma` label/tree mismatch behavior | focused test | no silent mismatch |
| F028 | Native REML Prototype | Add boundary diagnostic for matched REML prototype | diagnostic row | boundary visible |
| F029 | Native REML Prototype | Run focused q1 REML stress grid | validation artifact | failures classified |
| F030 | Native REML Prototype | Bank q1 native REML prototype status | after-task note | no public promotion unless gates pass |
| F031 | Native q2/q4 REML | Decide whether native q2 REML should be implemented or rejected | decision note | q2 route explicit |
| F032 | Native q2/q4 REML | Decide whether native q4 REML is out of scope for current arc | decision note | q4 route explicit |
| F033 | Native q2/q4 REML | Preserve q2/q4 rejection messages if deferred | tests | unsupported cells clear |
| F034 | Native q2/q4 REML | If q2 proceeds, define exact Gaussian q2 target | derivation note | exact target |
| F035 | Native q2/q4 REML | Add q2 direct target inventory row | dashboard row | target tracked |
| F036 | Native q2/q4 REML | Add q2 tiny recovery smoke or deferral artifact | test or note | evidence exists |
| F037 | Native q2/q4 REML | Audit q4 correlation target status | design note | derived vs direct clear |
| F038 | Native q2/q4 REML | Keep q4 REML public wording unsupported | docs patch | no overclaim |
| F039 | Native q2/q4 REML | Run REML forbidden-claim scan | check-log entry | scan clean |
| F040 | Native q2/q4 REML | Bank q2/q4 REML decision | after-task note | future route recoverable |
| F041 | Native ML Inference | Freeze native ML q1/q4 target inventory | dashboard update | direct/derived target split |
| F042 | Native ML Inference | Add q1 sigma-side profile smoke | focused test | profile status row |
| F043 | Native ML Inference | Add matched `mu+sigma` profile smoke | focused test | profile status row |
| F044 | Native ML Inference | Add q4 SD profile-target smoke | focused test | SD status row |
| F045 | Native ML Inference | Add q4 correlation derived-target warning | docs/test | no direct interval claim |
| F046 | Native ML Inference | Add bootstrap refit accounting for q1 sigma-side | dashboard row | refits counted |
| F047 | Native ML Inference | Add bootstrap refit accounting for matched `mu+sigma` | dashboard row | refits counted |
| F048 | Native ML Inference | Run small coverage pilot for q1 sigma-side | validation artifact | coverage labelled pilot |
| F049 | Native ML Inference | Run small coverage pilot for matched `mu+sigma` | validation artifact | coverage labelled pilot |
| F050 | Native ML Inference | Bank native ML inference status | after-task note | no broad coverage claim |
| F051 | Direct DRM.jl | Refresh direct q4 profile/bootstrap API smoke | validation row | direct status current |
| F052 | Direct DRM.jl | Reproduce scale-axis undercoverage note from current branch | validation note | caveat current |
| F053 | Direct DRM.jl | Add direct q1 sigma-side parity target | DRM.jl issue or row | target named |
| F054 | Direct DRM.jl | Add direct matched `mu+sigma` parity target | DRM.jl issue or row | target named |
| F055 | Direct DRM.jl | Compare direct Julia and native R q1 point estimates | parity artifact | same estimand |
| F056 | Direct DRM.jl | Compare direct Julia and native R q1 intervals where available | parity artifact | interval route explicit |
| F057 | Direct DRM.jl | Add direct q4 target-map export | artifact | target names stable |
| F058 | Direct DRM.jl | Add direct q4 failure taxonomy | validation note | failures classified |
| F059 | Direct DRM.jl | Run direct DRM.jl forbidden-claim scan | check-log entry | exact-Gaussian boundary |
| F060 | Direct DRM.jl | Bank direct DRM.jl readiness status | after-task note | not R bridge support |
| F061 | R-via-Julia Bridge | Define bridge promotion contract for each Ayumi row | design note | row-specific |
| F062 | R-via-Julia Bridge | Add q1 sigma-side payload schema row | dashboard row | schema stable |
| F063 | R-via-Julia Bridge | Add matched `mu+sigma` payload schema row | dashboard row | schema stable |
| F064 | R-via-Julia Bridge | Add q4 payload schema row or deferral | dashboard row | q4 status explicit |
| F065 | R-via-Julia Bridge | Add q1 sigma-side reconstruction smoke | focused test | payload reconstructs |
| F066 | R-via-Julia Bridge | Add matched `mu+sigma` reconstruction smoke | focused test | payload reconstructs |
| F067 | R-via-Julia Bridge | Add q1 parity smoke against direct DRM.jl | focused test | same row |
| F068 | R-via-Julia Bridge | Add bridge rejection messages for unsupported q4/coverage | test | no silent route |
| F069 | R-via-Julia Bridge | Run bridge forbidden-claim scan | check-log entry | no bridge overclaim |
| F070 | R-via-Julia Bridge | Bank bridge promotion decision | after-task note | promoted rows named |
| F071 | Ayumi Data | Refresh raw data bundle availability | data-readiness row | path current |
| F072 | Ayumi Data | Re-run Model A+ wrapper if data is present | artifact | primary model current |
| F073 | Ayumi Data | Re-run no-mean-phylo comparator if data is present | artifact | comparator current |
| F074 | Ayumi Data | Re-run q4 native ML status harness if data is present | artifact | diagnostic status current |
| F075 | Ayumi Data | Re-run q4 profile budget only if gated by small smokes | artifact or deferral | compute bound explicit |
| F076 | Ayumi Data | Add one-observation-per-tip diagnostic row | dashboard row | design limitation explicit |
| F077 | Ayumi Data | Add scale-side sensitivity guidance | design note | interpretation bounded |
| F078 | Ayumi Data | Add data preflight reproducibility script status | check-log entry | rerun path clear |
| F079 | Ayumi Data | Summarize real-data route matrix | design note | Model A+ primary |
| F080 | Ayumi Data | Bank Ayumi data rerun status | after-task note | no interval overclaim |
| F081 | Docs | Update formula grammar for newly promoted rows only | docs patch | grammar matches support |
| F082 | Docs | Update known limitations for deferred rows | docs patch | unsupported cells visible |
| F083 | Docs | Update README preview wording if support changes | docs patch | public wording current |
| F084 | Docs | Add applied-user route table | docs/design or vignette draft | primary route clear |
| F085 | Docs | Add Pat readability audit | review note | applied user can choose |
| F086 | Docs | Add Rose stale-claim audit | review note | no contradiction |
| F087 | Docs | Add Gauss/Noether equation-code audit | review note | math/code alignment |
| F088 | Docs | Add Fisher inference audit | review note | coverage claims bounded |
| F089 | Docs | Rebuild dashboard/status artifacts | generated or manual update | validator green |
| F090 | Docs | Bank docs synchronization | after-task note | public story stable |
| F091 | Reply | Refresh exact Ayumi issue thread | issue note | latest context known |
| F092 | Reply | Update local reply draft from latest thread | draft | no stale opener |
| F093 | Reply | Run forbidden-claim scan on exact reply text | check-log entry | scan clean |
| F094 | Reply | Ask maintainer to approve exact reply text | approval note | explicit approval |
| F095 | Reply | Post reply only after exact approval | issue comment | A099 banked |
| F096 | Reply | Record posted URL and local transcript | check-log entry | public action recoverable |
| F097 | Closeout | Update slice ledger statuses | dashboard row | no queued ambiguity |
| F098 | Closeout | Run final validation and focused tests | check-log entry | green gates |
| F099 | Closeout | Commit implementation/doc updates | git commit | recoverable bundle |
| F100 | Closeout | Write closeout checkpoint | recovery note | next arc clear |

## First Execution Recommendation

Start with F001-F010, then F011-F020. The highest-leverage decision is whether
native sigma-side REML has a clean exact-Gaussian target worth implementing in
TMB, or whether that route should remain rejected while direct DRM.jl carries
the next exact-Gaussian work.
