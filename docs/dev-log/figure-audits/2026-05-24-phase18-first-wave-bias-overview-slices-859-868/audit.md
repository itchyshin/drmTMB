# Figure Audit: Phase 18 First-Wave Bias Overview Slices 859-868

Reader: `drmTMB` contributors checking whether the aggregate-bias overview is a
usable screening display for report review.

| Figure | Source Object | Visual Data Grain | Uncertainty Source | Reader Risk | Verdict |
| --- | --- | --- | --- | --- | --- |
| `embedded-plot-01.png` | Saved `slice-859` self-contained HTML | Aggregate bias rows only | None; this is not an interval display | Long parameter labels and facet strips are clipped in the historical saved artifact | Historical artifact only; not publication-ready |
| `aggregate-bias-overview-current-template.png` | Current Rmd template rerendered against the same `slice-859` CSVs | Aggregate bias rows only, ranked by absolute bias | None; caption states replicate-level clouds belong to later figures | Readers see row ranks rather than long parameter names; full names remain in the table below | Pass as a compact screening plot, not a final Florence figure |

Notes:

- The current template rerender keeps the data grain explicit: aggregate rows
  only, no replicate-level clouds, no confidence or compatibility intervals.
- The saved `slice-859` HTML remains useful as historical evidence that the
  section and embedded plot existed, but the current-template PNG is the visual
  evidence to carry forward.
- No plotting helper, likelihood, formula grammar, public API, or statistical
  claim changed during this validation pass.
