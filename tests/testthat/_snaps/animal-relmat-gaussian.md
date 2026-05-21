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

