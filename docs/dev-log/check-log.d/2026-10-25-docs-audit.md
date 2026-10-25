# Documentation audit, 25 October 2026

## First R tutorial restoration

Source baseline: `77a122eec4a7a5d7ac0216e398d7a0f706971d28`.
The pkgdown publication run `40196830385` succeeded with Pages artifact
`12601436160`, digest `df9e9e4ee6b8ba41e55ae3f57401732c6b0cee6e0122a4d4b187bf57ece8787b`.
Both temporal tutorial URLs, the article index, temporal reference, and search
index returned HTTP 200 and matched that artifact byte-for-byte. Browser checks
found both tutorials in the menu and search results.

Visual review found doubled LaTeX escapes in the temporal guide. Its equations
rendered as raw text. This patch removes one escape level in the introduction;
all example code remains unchanged. A full pkgdown rebuild and the existing
public-surface check passed. A MathML check rejects the previous live HTML and
accepts the rebuilt display equation with beta and phi preserved. The paired
tutorial is a positive rendering control. Both tutorial contexts had already
executed all 14 chunks, including the omitted temporal profile snippet.

The corrected equation still needs publication and direct live verification.
The broader two-package audit remains in progress. This record does not claim
new model support, interval calibration, package release, or completion of the
full documentation audit. Canonical dirty checkouts were preserved.

Task evidence and the approved plan are under the projectless documentation
audit workspace, `work/docs-audit/`; final reports will be in its `outputs/`.
