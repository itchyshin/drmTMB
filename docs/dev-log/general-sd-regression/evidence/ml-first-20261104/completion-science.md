# Independent completion review: source and mathematics

4 November 2026. Read-only review of the approved first-delivery slice, independent judgment. No fits, tests, commits, posts or source edits were run by this reviewer. Verdict: **no blocking source/math finding in the reviewed slice**. This is not a merge authorization or full-programme completion finding; the full R check and exact-head integration/post-merge gates remain pending.

## Source identity and evidence examined

R baseline: `9e2c03f6fdcb9091418cb629f2ca7f30da695e3d`, branch `codex/sd-article-ml`. Current `R/julia-bridge.R` SHA-256 independently measured as `4d5c188f10fc73f75ddf0a602fa5d97bb1880f5f65b3469752e9d469f6159ab7`, matching the final frozen receipt. Julia reviewed at `c037268c76d29234a2174354ae4319b4d98e7c29`; the diff from `f4fa3aed451636b6ffa442ce2632515513d23b1f` contains docs/assets/news only. The R C++ diff from baseline is empty.

Read GOAL.md, acceptance-design.md and the approved PLAN; inspected the complete bridge diff, new stored-prediction payload tests, extended live B34 comparisons and their row-order/mode assertions; neighboring design, fixed-predictor, offset-refusal and Binomial-response helpers; article Gamma generation/fit script; hand-derived Gamma oracle; final frozen execution receipt, structured prediction log, Gamma results and numerical-probe records. The frozen receipt reports every job exit 0 and identical before/after dictionaries, including native DLL `29dcf6d30daed35200951533fabbaad6bed5e715c383b9fe15f6d5ce6a5567de`. This is inspection of retained executions, not a new execution by the reviewer.

## Mathematical and contract findings

- Stored structured `mu` prediction now forms `eta = X beta + eta_re`; response prediction applies the fitted Binomial link or the existing canonical response link. Explicit `newdata` returns before this branch and retains RE=0 semantics. SD selector processing also precedes it. A missing, failed, nonfinite or wrong-length field cannot pass as a valid conditional prediction.
- Reconstructing the retained fixed predictor before adding the field avoids inversion of rounded probabilities and overflowing log-link means. The existing global bridge offset refusal protects the reconstruction's offset boundary. Older objects lacking retained data/coefficients keep the inverse-link fallback for fitted values.
- Response residuals use retained observations directly, avoiding cancellation in `residual + population mean`. Binomial two-column counts pass through the existing canonical successes/trials converter, so residuals are on observed-proportion scale. Missing/legacy encodings retain their previous fallback. The new tests cover overflow, rounding, grouped Binomial counts and legacy response absence.
- The live B34 extensions check stored link/response output, explicit-newdata output and serialization. Existing independently assembled group-mode contributions, shuffled group order and native comparisons strengthen these beyond agreement between two wrappers using the same payload. They qualify the selected exports, not every structured provider/layout.
- For Gamma, `shape = 1/sigma^2`, the hand log-density and first/second derivatives in the oracle agree. With `b = D u`, `u ~ N(0,K)`, its Gaussian prior normalization and Laplace Hessian term yield the stated marginal objective. Raw non-unit `K` implies marginal group-effect SD `s_g sqrt(K_gg)`, exactly the article's scale interpretation. No likelihood or estimation method changes are introduced here.

## Claims and remaining gates

On the exact Gamma article draw, retained native/bridge log likelihoods are -572.328865533066/-572.328865533047; their independent-Laplace gaps are approximately -2.02e-11/0, below the predeclared 1e-5 tolerance. The article shows estimated one-unit SD ratio 1.073 versus generating 1.492 and explicitly declines a recovery claim. The method distinction between ordinary Julia quadrature and structured Laplace remains visible. RE=0 is correctly distinguished from integration over random effects, and direct Julia fitted output is distinguished from the R bridge contract.

Numerical probes remain findings rather than advertised fixes: ZeroOneBeta seed 20261409 returned while 20261412 retains its SE error; plain constant-SD NB2 bad fits are nonconverged; the Binomial locator is explicitly not bound to the historical -26.9 case. Preserve those qualifications in any issue/update. Preserve the aborted old DLL verification wave as historical evidence.

Six source-admitted article cells and the row-preserving 21,246-row audit do not establish broad runtime accuracy or coverage. G5 and D-342 stay deferred; original G0-G4/G6-G8 remain the wider programme's finish line. Full R check, exact-head CI/merge checks, main-job verification and deployed-page checks must still finish before their corresponding completion claims. No tolerance relaxation or scope expansion is justified by this review.

## Review notes

Naturalness self-review of this report: perceived AI-like style 3/10, medium confidence; technical-review genre, whole report. The verdict states its boundary early; the source/math list is appropriate parallel material. “Claims and remaining gates” keeps findings distinct from pending integration. No prose repair needed. Science gate: pass within the inspected equations/contracts. Facts gate: pass against the named source and retained logs, with current executions explicitly not rerun. Reference gate: not applicable to literature; local identifiers and source identity checked. Reviewer: independent completion-science agent, 4 November 2026; evidence already seen as described above. Exact-draft assessment validator was not run: **NOTASSESSED** under that separate completion safeguard.

Operational note: `graft ask` automatically refreshed one graph file before answering; no deliberate source or graph edit was requested by this reviewer. Claimed graft saving (~649,181 tokens across two retained estimate lines) is the tool's hypothetical full-file comparison, not measured model-token savings.
