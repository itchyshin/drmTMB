# Prospective Bernoulli calibration contract proposal

Status: **historical proposal, superseded by `staged-calibration-contract.md`.**
The 19 October contract freeze retains the 95% fitted profile-interval target
and uses 97.5% Monte Carlo confidence intervals. The candidate rules below
document the review that led to that contract; they are not a separate pending
proposal or launch authority. The completed 97.5%-profile first look remains
exploratory and cannot count toward calibration under the frozen contract.

## Why a prospective contract is needed

The completed native first look used two-sided 97.5% profile intervals, whose
nominal coverage is 97.5% and whose two-sided null exclusion probability is
2.5%. The frozen coverage and false-positive bands remain centered on 95%
interval targets. The resulting `look2_required` decision is a mechanical
classification under those frozen rules, not evidence that the 97.5% intervals
are calibrated. The exact observed results and review are in
`calibration-0975-band-audit.md` and the retained `first-look-postfix-20261019-v2/`
evidence.

The completed sample used a different fitted-interval level from the approved
target, so it remains exploratory and cannot count toward the 95% calibration
campaign. Reclassifying its results under a 95% interval target would not
create evidence for intervals that were never computed.

## Historical candidate design reviewed before contract freeze

| Component | Candidate rule | Basis and limitation |
|---|---|---|
| Fitted intervals | Two-sided 95% profile intervals, verified per attempt | Restores the original approved calibration target. The completed 97.5% profile-interval run remains exploratory and cannot establish this target. |
| Calibration targets | Planned-attempt coverage 0.95 at each predeclared slope truth; planned-attempt null false-positive rate 0.05 at truth zero | These are the approved ordinary-condition targets. Invalid intervals are noncoverage and not false positives; both rates use all planned attempts. Report valid-only rates as diagnostics, with denominators explicit. |
| Monte Carlo uncertainty | Exact two-sided 97.5% binomial intervals for planned coverage, planned FPR, and validity at each look | Retains the repeated-look precision allocation while restoring the original 95% fitted interval target. Component intervals are marginal, not simultaneous across the grid. |
| Practical bands | Planned coverage [0.925, 0.975]; planned null FPR [0.025, 0.075] | The original approved ±0.025 tolerance around the nominal rates. These two rates and validity are dependent; at truth zero their counts form a joint multinomial partition. The bands test both under- and overcoverage/rejection, unlike the later one-sided proposal. |
| Attempts | 1,000 per truth at look one; if no gate fails and at least one is ambiguous, add 3,000 per truth and analyze 4,000 cumulative per truth at look two | Retains the planned staged allocation but uses a fresh seed stream. Counts are not justified by the literature corpus; evaluate the complete campaign rule under joint attempt-level scenarios before freezing. |
| Valid-interval gate | At each truth, the lower endpoint of the two-sided 97.5% exact binomial interval for valid fraction, using all planned attempts, must be at least 0.95 | Retains the approved availability gate. Invalid intervals remain in the planned denominator, count as noncoverage, and do not count as false positives. |
| Valid-only rates | Report conditional coverage and conditional FPR alongside planned rates | At truth zero, conditional coverage plus conditional FPR equals one; planned coverage plus planned FPR equals the valid fraction. These identities are explicit dependencies, not independent gates. |
| Bias diagnostics | Report log-SD-slope and relative `exp(slope)` bias with finite-estimate denominators and approximate Monte Carlo t intervals | Following inference review, these are descriptive diagnostics only and do not enter staged acceptance. The nonlinear relative-bias estimand requires a stated target under each error distribution; zero mean log-slope error does not imply zero mean relative scale bias. Point-estimator recovery remains a separate validation requirement. |
| Claim scope | Prefer one predeclared conjunction: every required component in the fixed domain passes; component intervals remain marginal, not simultaneous | A global conjunction can be framed as an intersection-union decision requiring all components to pass. Separate cell-specific claims or post-hoc selection need a declared multiplicity policy. |

The approved primary estimands use all planned attempts. At truth zero,
coverage, false positives, and invalid intervals form a three-category
partition. Thus planned coverage plus planned FPR equals the valid fraction.
The nominal rates 0.95 and 0.05 sum to one, so exact nominal rates imply no
invalid intervals; the practical bands allow a joint range of imperfect yield
and interval behavior. The separate valid-fraction floor is not a substitute
for checking that joint range. The campaign analysis must generate the three
categories together and report valid-only rates as diagnostics.

At the zero truth, conditional coverage and conditional FPR are complements
for valid ordered intervals, but the approved planned-denominator gates are
not redundant because invalid attempts are a third category. The full gate
vector originally included three planned-coverage gates, three validity gates,
three log-bias gates, three relative-bias gates, and one planned-FPR gate.
Following inference review, the bias intervals are diagnostics only; the
current gate vector contains planned coverage, validity, and planned
false-positive criteria. The candidate must restore the per-fit profile level to 0.95; the
existing 97.5% worker path and its completed results remain separate
exploratory evidence. No historical worker, helper, contract, or retained
result is rewritten by this proposal.

The broad plan already approves the 95% fitted-interval target, the ±0.025
ordinary-condition bands, and the 1,000 plus 3,000 attempt schedule. This
proposal restores those choices after the worker drifted to a 97.5% fitted
interval. The complete joint OC analysis is still needed to characterize the
actual pass, fail, and continuation probabilities; it does not select new
thresholds. The completed 3,000-attempt 97.5% first look may inform runtime
feasibility, but it cannot count toward the 95% confirmatory look.

Independent reviewers identified the denominator identity: at zero, planned
coverage and planned false-positive rates sum to the valid fraction. This
rules out treating these rates as independent when evaluating campaign
operating characteristics. The exact component analysis in
`calibration-binomial-oc.md` remains a single-gate diagnostic; it omits the
campaign stopping rule, dependent metrics, and fitted-estimate bias gates. It
does not change the approved thresholds or claim scope.

## NotebookLM and reviewer synthesis

The connected personal-account methods notebook was asked specifically whether
its sources justify calibration margins, replicate counts, or a two-look rule
for predictor-dependent random-effect SDs. The answer is no: it identified no
source establishing those design choices for this model. It distinguished
the fitted interval level from Monte Carlo uncertainty and warned against
selecting thresholds after observing look one. NotebookLM is a triage aid;
those claims were checked against the approved plan, retained code, and
independent inference reviews, not treated as authority.

Two independent inference reviewers evaluated the later 97.5% proposal, not
the originally approved 95% design. Their findings are used here to correct
the estimands and expose the need for campaign-level OC. A single
predeclared all-components conjunction may be evaluated as such; separate
cell-specific claims require a declared multiplicity policy. No threshold or
sample-size change is adopted.

## Evidence and next gate

- `staged-calibration-contract.md`: current frozen rule; unchanged.
- `calibration-0975-band-audit.md`: observed first-look rates and mismatch.
- `research.md`: primary-source limits and bounded NotebookLM review.
- `evidence/calibration-20261017/first-look-postfix-20261019-v2/`: retained
  exploratory results and source receipts.

Historical next gate (completed and superseded): independently review the
campaign-level OC harness and its scenario-based results, then run a bounded
timing check for the corrected 95% first-look chain without modifying retained
historical artifacts. The review and synthetic rule-level smoke are recorded
in `docs/dev-log/after-task/2026-10-19-staged-bias-diagnostics-decision.md`;
the smoke is not fitted-model calibration. Before any shared compute,
verify the live Totoro/DRAC lanes, run the bounded source-to-binary pre-run, and
estimate the full campaign runtime. Any campaign projected above three hours
requires its measured pre-run results and explicit approval.
