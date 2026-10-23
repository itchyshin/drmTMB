/* Meuwissen & Luo (1992) pedigree inbreeding, T-row / max-heap walk.
 *
 * Method: Genet. Sel. Evol. 24:305-313. Walk matches HSquared.jl
 * `_meuwissen_luo_inbreeding` (MIT; src/pedigree.jl at
 * eee5f7aa7640abafa6b2efd2b71a66182db77459). That source is not vendored.
 * No gllvmTMB or other GPL source is copied.
 *
 * Inputs are 1-based integer sire/dam vectors (0 = unknown parent), already
 * topologically ordered (parents before offspring). F_0 = -1. One unknown
 * parent => F_i = 0.
 */

#include <stddef.h>
#include <Rconfig.h>
#ifdef HAVE_ENUM_BASE_TYPE
#define DRMTMB_RESTORE_HAVE_ENUM_BASE_TYPE 1
#undef HAVE_ENUM_BASE_TYPE
#endif
#include <R_ext/Boolean.h>
#ifdef DRMTMB_RESTORE_HAVE_ENUM_BASE_TYPE
#define HAVE_ENUM_BASE_TYPE 1
#endif
#include <Rinternals.h>
#include <R_ext/Error.h>
#include <R_ext/Memory.h>

static double f0(int k, const double *F) {
  return k == 0 ? -1.0 : F[k - 1];
}

static void heap_push(int *h, int *hn, int x) {
  int i, p, tmp;
  h[*hn] = x;
  i = *hn;
  *hn += 1;
  while (i > 0) {
    p = (i - 1) / 2;
    if (h[p] >= h[i]) {
      break;
    }
    tmp = h[p];
    h[p] = h[i];
    h[i] = tmp;
    i = p;
  }
}

static int heap_pop_max(int *h, int *hn) {
  int top, last, n, i, left, right, m, tmp;
  top = h[0];
  *hn -= 1;
  if (*hn == 0) {
    return top;
  }
  last = h[*hn];
  h[0] = last;
  n = *hn;
  i = 0;
  for (;;) {
    left = 2 * i + 1;
    right = left + 1;
    m = i;
    if (left < n && h[left] > h[m]) {
      m = left;
    }
    if (right < n && h[right] > h[m]) {
      m = right;
    }
    if (m == i) {
      break;
    }
    tmp = h[i];
    h[i] = h[m];
    h[m] = tmp;
    i = m;
  }
  return top;
}

SEXP drm_meuwissen_luo_inbreeding(SEXP sire_sexp, SEXP dam_sexp) {
  R_xlen_t n, i;
  int *sire, *dam, *heap, heap_n, s, d, j, sj, dmj;
  double *F, *L, lj, fi;
  SEXP F_sexp;

  if (TYPEOF(sire_sexp) != INTSXP) {
    sire_sexp = PROTECT(coerceVector(sire_sexp, INTSXP));
  } else {
    PROTECT(sire_sexp);
  }
  if (TYPEOF(dam_sexp) != INTSXP) {
    dam_sexp = PROTECT(coerceVector(dam_sexp, INTSXP));
  } else {
    PROTECT(dam_sexp);
  }

  n = XLENGTH(sire_sexp);
  if (XLENGTH(dam_sexp) != n) {
    UNPROTECT(2);
    error("sire and dam must have the same length");
  }

  sire = INTEGER(sire_sexp);
  dam = INTEGER(dam_sexp);
  F_sexp = PROTECT(allocVector(REALSXP, n));
  F = REAL(F_sexp);
  L = (double *)R_alloc((size_t)n, sizeof(double));
  heap = (int *)R_alloc((size_t)n, sizeof(int));
  for (i = 0; i < n; ++i) {
    L[i] = 0.0;
  }

  for (i = 0; i < n; ++i) {
    s = sire[i];
    d = dam[i];
    if (s == NA_INTEGER || d == NA_INTEGER) {
      UNPROTECT(3);
      error("sire and dam must be integer codes (0 = unknown)");
    }
    if (s < 0 || s > n || d < 0 || d > n) {
      UNPROTECT(3);
      error("parent index out of range");
    }
    if (s == 0 || d == 0) {
      F[i] = 0.0;
      continue;
    }
    L[i] = 1.0;
    heap_n = 0;
    heap_push(heap, &heap_n, (int)(i + 1));
    fi = 0.0;
    while (heap_n > 0) {
      j = heap_pop_max(heap, &heap_n);
      lj = L[j - 1];
      L[j - 1] = 0.0;
      sj = sire[j - 1];
      dmj = dam[j - 1];
      fi += lj * lj * (0.5 - 0.25 * (f0(sj, F) + f0(dmj, F)));
      if (sj != 0) {
        if (L[sj - 1] == 0.0) {
          heap_push(heap, &heap_n, sj);
        }
        L[sj - 1] += 0.5 * lj;
      }
      if (dmj != 0) {
        if (L[dmj - 1] == 0.0) {
          heap_push(heap, &heap_n, dmj);
        }
        L[dmj - 1] += 0.5 * lj;
      }
    }
    F[i] = fi - 1.0;
  }

  UNPROTECT(3);
  return F_sexp;
}
