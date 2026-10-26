# Current documentation audit checks, 2026-10-25

The prepared patch passed 27 focused assertions for documentation diagnostics, the 404 MathJax repair, and diagnostic-table subsetting. The subsetting test had four failures before the explicit drop-forwarding fix, and no failures, warnings, or skips afterward.

Roxygen 7.3.2 regenerated the owned help with NAMESPACE unchanged. The local v6 site build produced 241 HTML pages; independent checks found no broken local routes, anchors, or assets and 78 structurally consistent tables. Later method aliases and subsetting help require a fresh final artifact.

The source-tree contributor test initially failed because the disposable source export omitted tracked design fixtures. A complete-source retry and package check remain open. The two temporal tutorials were separately merged, deployed, and verified live before this broader patch. This record does not claim final deployment or complete audit acceptance.

The final affected test batch passed 70 assertions, including the repaired help generic, dependency/skip census, Dinnage documentation contract, and subprocess source-root resolution. The live build verifier now binds each site to the matching build source; 19 disposable controls pass.
