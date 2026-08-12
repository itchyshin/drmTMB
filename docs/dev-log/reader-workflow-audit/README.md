# Reader-workflow audit

This directory records a reader-first usability audit rather than a capability
promotion. The runner `tools/run-reader-workflow-audit.R` creates ten small,
article-shaped analyses using exported `drmTMB` functions only after loading the
development checkout. Each fixture is written as a small CSV and read back
before fitting, so the workflow also exercises the ordinary tabular import
boundary. Every TSV row records the exact model, estimand,
uncertainty route, diagnostic call, report artifact, evidence tier, and first
failed point rather than treating a successful fit as proof that diagnostics,
uncertainty, reporting, or scientific interpretation are ready.

The generated TSV is a smoke receipt: it establishes that a small workflow can
be exercised on a specific checkout. It is not recovery or coverage evidence,
and it never widens a capability status.
