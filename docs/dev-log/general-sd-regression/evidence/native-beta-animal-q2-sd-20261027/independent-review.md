# Independent bounded review

Read-only reviewer: GPT-6.1 Terra, high reasoning, task `gamma_relmat_sd_review`. The reviewer authored no implementation or test edits and ran no fits.

The review checked the Beta mean adjustment, shape-floor boundary, analytic score and curvature, full two-field prior normalization and Laplace correction, target mapping, Gamma q2 map reuse, selected-optimum comparisons, raw/scaled extraction and supplied A/Ainv equivalence. The reviewer recommended admitting Ainv because the same Q backend already supports it, and replacing relative reversed-formula coefficient tolerances with the declared absolute tolerance. Both changes were made before the final regression run.

No remaining P0/P1 issue was identified in the bounded patch review. A final neighbor audit confirmed that the public Julia route already refuses this model before marshalling or setup; a setup-mocked check independently exercised that refusal. No live Julia parity or interval calibration follows.

Exact foreign-ref review found nearby provider-selection, stable-density and reporting work in the newest refs. The implementation preserves the current provider-selection/refusal code and edits only the coefficient-SD insertion and one C++ loading hunk. Foreign additions absent from this candidate remain for later integration; no whole builder or family-density branch was transplanted.
