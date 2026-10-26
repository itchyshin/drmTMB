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

## Current documentation repair continuation

The corrected tutorials were subsequently deployed in run40206865087 and verified live against its artifact, including mathematical rendering, menus, and search.

The prepared patch passed 27 focused assertions for documentation diagnostics, the 404 MathJax repair, and diagnostic-table subsetting. The subsetting test had four failures before the explicit drop-forwarding fix, and no failures, warnings, or skips afterward.

Roxygen 7.3.2 regenerated the owned help with NAMESPACE unchanged. The local v6 site build produced 241 HTML pages; independent checks found no broken local routes, anchors, or assets and 78 structurally consistent tables. Later method aliases and subsetting help require a fresh final artifact.

The source-tree contributor test initially failed because the disposable source export omitted tracked design fixtures. A complete-source retry and package check remain open. The two temporal tutorials were separately merged, deployed, and verified live before this broader patch. This record does not claim final deployment or complete audit acceptance.

The final affected test batch passed 70 assertions, including the repaired help generic, dependency/skip census, Dinnage documentation contract, and subprocess source-root resolution. The live build verifier now binds each site to the matching build source; 19 disposable controls pass.
