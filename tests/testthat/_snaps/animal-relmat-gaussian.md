# animal and relmat reject unsupported or malformed known matrices

    Code
      drmTMB(bf(y ~ x + animal(1 | id, pedigree = pedigree_missing_parent), sigma ~ 1),
      data = ped_sim$data)
    Condition
      Error in `drm_standardize_pedigree()`:
      ! `animal()` pedigree pedigree_missing_parent parents must appear in the id column.
      x Missing parent id: "missing".

---

    Code
      drmTMB(bf(y ~ x + animal(1 | id, pedigree = pedigree_cycle), sigma ~ 1), data = ped_sim$
        data)
    Condition
      Error in `drm_pedigree_topological_order()`:
      ! `animal()` pedigree pedigree_cycle must not contain parent-offspring cycles.
      x Could not resolve individuals: "id1", "id5", "id7", and "id8".

---

    Code
      drmTMB(bf(y ~ x + animal(1 + x | id, pedigree = pedigree_valid), sigma ~ 1),
      data = ped_sim$data)
    Condition
      Error in `extract_gaussian_mu_known_term()`:
      ! Only intercept-only `animal()` `mu` effects are implemented.
      x Requested structured coefficients: "(Intercept)" and "x".
      i Use `animal(1 | id, pedigree = pedigree_valid)`.
      i Structured slopes need separate recovery evidence before they are advertised for `animal()`.

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

---

    Code
      drmTMB(bf(mu1 = y ~ x + relmat(1 | id, Q = Q), mu2 = y ~ x + relmat(1 | id, Q = Q),
      sigma1 = ~ relmat(1 | id, Q = Q), sigma2 = ~1, rho12 = ~1), family = biv_gaussian(),
      data = dat)
    Condition
      Error in `detect_biv_structured_q4_terms()`:
      ! Partial relmat location-scale blocks are not implemented.
      x `mu1`, `mu2`, and `sigma1` contains `relmat()`, but `sigma2` do not.
      i Use matching labelled intercepts in `mu1`, `mu2`, `sigma1`, and `sigma2`.

---

    Code
      drmTMB(bf(mu1 = y ~ x + animal(1 | id, Ainv = Q), mu2 = y ~ x + animal(1 | id,
      Ainv = Q), sigma1 = ~ animal(1 | id, Ainv = Q), sigma2 = ~ animal(1 | id, Ainv = Q),
      rho12 = ~1), family = biv_gaussian(), data = dat)
    Condition
      Error in `detect_biv_structured_q4_terms()`:
      ! Animal-model q=4 location-scale blocks require an explicit covariance-block label.
      x `mu1`, `mu2`, `sigma1`, and `sigma2` uses unlabelled `animal()` syntax.
      i Use one shared label, for example `animal(1 | p | group, ...)`, across `mu1`, `mu2`, `sigma1`, and `sigma2`.

---

    Code
      drmTMB(bf(mu1 = y ~ x + relmat(1 | p | id, Q = Q), mu2 = y ~ x + relmat(1 | q |
        id, Q = Q), sigma1 = ~1, sigma2 = ~1, rho12 = ~1), family = biv_gaussian(),
      data = dat)
    Condition
      Error in `guard_biv_known_mu_terms()`:
      ! Matched bivariate `relmat()` location terms must use the same covariance-block label.
      x `mu1` uses block `p`.
      x `mu2` uses block `q`.
      i Use matching terms such as `relmat(1 | p | id, Q = Q)` in both formulas, or leave both terms unlabelled.

