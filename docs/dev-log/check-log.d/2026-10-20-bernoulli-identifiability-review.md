# Bernoulli one-observation-per-group source review

- Updated `docs/dev-log/general-sd-regression/research.md` with the latest
  NotebookLM challenge response and primary-source boundary.
- NotebookLM browser was verified under `itchyshin@gmail.com`; its follow-up
  distinguishes non-recovery of each group effect from population parameter
  identification. It also confirms that the 14-source corpus gives no general
  theorem for predictor-dependent SD regression.
- Verified Stringer v2 Sections 2.1–2.2 and 4.3.1 at
  <https://arxiv.org/html/2310.01589>. The Bernoulli simulation uses a
  group-invariant covariance matrix; its interval results do not validate
  covariate-dependent SD coefficients.
- Verified Joe (2008), Abstract and Sections 1 and 4, at
  <https://www.sciencedirect.com/science/article/abs/pii/S0167947308002533>.
  The paper concerns Laplace-estimation bias in selected discrete mixed
  models, not identifiability of predictor-dependent SDs.
- No package test or fit was run; this is a research-record change only.
- No GitHub issue was changed. The model implementation and calibration gates
  remain open; one observation per group is not classified as a universal
  structural exclusion.
