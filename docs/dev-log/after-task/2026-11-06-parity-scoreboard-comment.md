# After task: parity scoreboard comment

## Goal and change

A contributor reading `tools/write-parity-scoreboard.R` should see that the matrix generator emits its named pending R-only capabilities as unreconciled rows and rejects unexpected missing names. The previous comment said all R-only names abort. The change affects comments only; it does not alter model code, generated data, user-facing documentation, or package behavior.

## Checks and consistency

On Totoro, the proposed script regenerated the scoreboard byte-for-byte identically to the unmodified script from R candidate `99cca41194d89bfe5f7dca9e8800ab1122156632` and Julia status pin `da8b3f8711beb5ef3186b890544c2e7850c7f194`. A separate probe found all 22 pending rows present, non-green, unreconciled, and uncited on the Julia axis. The generator emitted a `beta()` deprecation warning. These checks establish reporting behavior at the named sources, not numerical parity.

The patch targets the stale source comment. No equations, formula syntax, examples, generated docs, NEWS, or pkgdown navigation changed. No new test was added for a comment-only edit. The existing unexpected-name guard remains in place.

## Limits and next action

PR #1657's source-tree GitHub check was cancelled during dependency setup. The comment correction does not resolve that check, the shared workflow ownership, the separate worker-shutdown message, or the route-level parity work. The issue tracker was left unchanged; this correction belongs to the existing PR review. The local evidence packet retains the scripts and logs.

The edited script is byte-identical to the proposal used in the Totoro regeneration. A separate local regeneration attempt stopped because the shared Julia checkout is not at the required historical pin; it was not switched or modified. A search for open issues using `parity scoreboard` returned no matches. The raw local refusal is retained in the external evidence packet.

An isolated Totoro checkout at the same R HEAD also applied both the comment and check-log changes, regenerated the scoreboard against the pinned Julia checkout, and matched the unmodified output byte-for-byte. `git diff --check` passed. This comparison does not run the GitHub CI job.
