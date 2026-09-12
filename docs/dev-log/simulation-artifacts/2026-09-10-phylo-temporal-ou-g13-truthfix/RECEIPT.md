# G13 corrected-truth no-refit receipt

The Rorqual re-verifier consumed the 3,500 sealed G12 task archives and their
SHA-256 sidecars. It did not load `drmTMB` or launch a model fit.

- Campaign estimator source: `384048d7eb6be3950dcf28a4aef91a3fb616184a`.
- Closure-bundle source: `de65cab2a0cf83d78ccdcc1750438c7f5099ab63`.
- Corrected target-registry logic: `0ee980cb0ab4c643099094a4e3ab0e8776451928`.
- Rorqual job: `20895722`; 1 CPU, 4 GiB, two-hour ceiling; completed in 71 seconds with 486,216 KiB maximum RSS.
- Immutable campaign archive-manifest SHA-256: `fc2a7a43dab7e82e9133f6c70638328e4e203405c8a4bf5b64784c91deaf7333`.
- Closure bundle SHA-256: `0cc95331d3f21fbb178ea2ee260e21017ba6711ee22fa4c3c5336df4ed0a4781`.

The corrected truth map is intercept/between/within = 0/0.5/0.5 for every
P1--P4 cell, matching the frozen task worker. Six of nine primary
coefficient-cell rows qualify. The P1, P2, and P3 intercept profiles fail the
predeclared coverage condition (0.870, 0.922, and 0.895); all six slope rows
qualify. This is an unmet calibration gate, not a claim of qualified OU
fixed-effect interval support.

Totoro independently reran the same no-refit verifier against the durable
archive set. `RESULTS.md`, `task-inventory.csv`, `summary.csv`, and
`assessment.csv` matched the Rorqual files byte-for-byte. The durable paths
are `/home/snakagaw/drmtmb-campaigns/phylo-ou-g12-384048d7-20260910/g13-result-de65cab2-truthfix`
and `/home/snakagaw/drmtmb-campaigns/phylo-ou-g12-384048d7-20260910/g13-totoro-replay-de65cab2-truthfix`.
