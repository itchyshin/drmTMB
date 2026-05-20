# animal and relmat reject unsupported or malformed known matrices

    Code
      drmTMB(bf(y ~ x + animal(1 | id, pedigree = ped), sigma ~ 1), data = dat)
    Condition
      Error in `build_known_precision_mu_structure()`:
      ! Pedigree-derived animal-model precision is planned but not implemented yet.
      x Requested `animal(1 | id, pedigree = ped)`.
      i Use a precomputed inverse relatedness matrix with `animal(1 | id, Ainv = Ainv)` for the first fitted animal-model path.

---

    Code
      drmTMB(bf(y ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1), data = dat)
    Condition
      Error in `extract_gaussian_mu_known_term()`:
      ! Only intercept-only `relmat()` `mu` effects are implemented.
      x Requested structured coefficients: "(Intercept)" and "x".
      i Use `relmat(1 | id, Q = Q)`.
      i Structured slopes need separate recovery evidence before they are advertised for `relmat()`.

---

    Code
      drmTMB(bf(y ~ x + relmat(1 | id, Q = bad_Q), sigma ~ 1), data = dat)
    Condition
      Error in `drm_standardize_relatedness_matrix()`:
      ! `relmat()` matrix bad_Q row and column names must match.
      x Rows without matching columns: "missing_id".
      x Columns without matching rows: "id1".
