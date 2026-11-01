# 2026-10-19 — Convergence budget table

Replaced the ambiguous two-panel lollipop plot with a generated five-column table. Both Gaussian fits use the same model, data and explicit starts with Newton polishing disabled. The table reports selected-attempt function counts, maximum absolute gradient, convergence code and gradient-check status. The text explains the 0.001 threshold and the limits of a small gradient. The unrelated status map uses neutral labels.

The extracted example passed finite-value, opposite-side-of-threshold and convergence/status checks using the existing isolated selector installation. The first candidate failed the intended contrast because Newton polishing rescued the low-budget fit; the final example explicitly disables polishing in both fits. Local HTML rendering passed; publication and CI receipts follow in the task closeout. No fitting code, defaults, formula grammar or likelihood changed.

## Runner scheduling recovery

The original package shards remained unassigned for over an hour; one same-commit rerun also queued. The completed source-tree job used ubuntu-24.04. Select that known passing image explicitly for Linux check and website jobs, retaining matrix check names, all commands, OS coverage, gates and protections. This tests an alias scheduling issue; it does not establish the provider's root cause. The prior source-tree suite passed 24,554 checks. Timings and retry receipts are retained in /tmp/drm-table-CI-DIAGNOSIS.md and /tmp/drm-table-ci-timings.json.
