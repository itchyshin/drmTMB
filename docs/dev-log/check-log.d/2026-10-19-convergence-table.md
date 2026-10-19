# 2026-10-19 — Convergence budget table

Replaced the ambiguous two-panel lollipop plot with a generated five-column table. Both Gaussian fits use the same model, data and explicit starts with Newton polishing disabled. The table reports selected-attempt function counts, maximum absolute gradient, convergence code and gradient-check status. The text explains the 0.001 threshold and the limits of a small gradient. The unrelated status map uses neutral labels.

The extracted example passed finite-value, opposite-side-of-threshold and convergence/status checks using the existing isolated selector installation. The first candidate failed the intended contrast because Newton polishing rescued the low-budget fit; the final example explicitly disables polishing in both fits. Local HTML rendering passed; publication and CI receipts follow in the task closeout. No fitting code, defaults, formula grammar or likelihood changed.
