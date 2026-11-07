# Priors design review and checkpoint

## Task goal

Design explicit fixed-effect regularization for drmTMB and DRModels.jl, followed by random-effect SD priors and a separate tmbstan assessment.

## Files created or changed

Only this isolated lane directory was written. PLAN.md is the current proposal; PLAN.v1.md preserves the initial reviewed draft. Assessment records identify their exact bytes. No implementation files changed.

## Checks run and exact outcomes

Canonical contract, efficiency procedure, repository rules, route manifest and relevant design skills read. Git/status/ownership checks and main-source inspection completed. Managed worktree created at drmTMB source `9fea3036791e9bd836e080d9297cd04b1b29c2f8`, initially clean. Narrow design-path lease granted. Official comparator and sampler documentation read. No fits, package tests or sampler runs were attempted because this is a design review.

The first prose-check invocation used a relative path, which the checker resolved against the brain checkout and did not read. It was rerun with the absolute draft path. That run read the draft and returned FINDINGS: 0, with zero em dashes. Exact-draft assessment of v1 was recorded successfully; science remained unknown pending numerical tests. Whitespace check produced no diagnostic; `git diff --no-index` exit 1 denotes file differences against the empty file.

## Consistency audit

Existing phylogenetic penalties, MSPL, the Julia bridge refusal and the requested new fixed-effect priors are distinguished. The API examples are explicitly proposed and are not placed in public tutorials. No README, NEWS, pkgdown, formula grammar or source behaviour was changed. The symbolic normal penalty, ridge precision convention and SD Jacobian distinction were checked by inspection and a bounded second read. Numerical agreement and interval calibration remain untested.

## Tests of the tests

No new executable tests exist. The proposed suite requires wrong-block, excluded-intercept, duplicate-penalty, wrong-lambda and dropped-rebuild mutations. Cross-dpar same-name fixtures were added after review to expose coordinate aliasing.

## What did not go smoothly

The graph reflects a different checkout revision: its R/drmTMB.R line spans were stale relative to main. Immutable source reads corrected the locations. Broad penalty/path output was larger than useful; subsequent inspection narrowed to exact source spans. The managed checkout took several minutes to create. No duplicate creation request or source-checkout edits were made.

## Team learning and process improvements

A bounded Luna medium source scout returned immutable sibling findings. Reusing that returned scout for design review exposed four material ambiguities. The current plan separates fixed-effect G0 from SD choice, defines the final optimized-column boundary, clarifies random-effect-SD regression refusals, and requires cross-dpar coordinate tests. These are proposed design improvements; no package validation policy changed.

## Design-document updates

PLAN.md contains the mathematical decomposition, proposed API, staged gates and compute envelope. No numbered design ID was allocated because preflight reported duplicate IDs. This design-only checkpoint is retained under the owned directory; normal check-log and after-task integration is deferred until the implementation lane has cleared ownership.

## pkgdown and documentation updates

None required for this private proposal. Implemented features will require roxygen, examples, reference navigation and a rendered reader workflow before completion.

## GitHub issue maintenance

Open drmTMB issue searches for prior and tmbstan were read. No clearly matching general fixed-effect-prior issue was found in those bounded results. No external issue, comment, PR or message was created. Julia issue matching remains open.

## Known limitations and next actions

CARRIED-OVER: the managed design worktree contains uncommitted proposal files only. Other dirty worktrees, stashes and PR #1651 are untouched. No push, merge, release or publication is authorized. Fixed-effect G0 approval is the next decision; package edits must first clear file ownership and create an isolated Julia lane. Before resuming, inspect git status and the exact current main refs, then read PLAN.md. Do not rerun discovery fits: none were started.

Style self-review: technical checkpoint, whole file, 3/10 perceived AI-like style, medium confidence. The exact source hash and the sentence describing the failed relative-path check make the evidence reproducible; the repeated section structure is required by the report protocol. Science gate unknown because no numerical tests ran; facts pass within recorded command outputs; references not applicable to this checkpoint's source-free prose. Reviewed by Codex on 5 November 2026. Exact-draft assessment for this checkpoint: NOTASSESSED; only the main proposal has a validated assessment record.
