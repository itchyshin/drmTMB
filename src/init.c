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
#include <R_ext/Rdynload.h>

SEXP drm_meuwissen_luo_inbreeding(SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
  {"drm_meuwissen_luo_inbreeding", (DL_FUNC)&drm_meuwissen_luo_inbreeding, 2},
  {NULL, NULL, 0}
};

void R_init_drmTMB(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  /* TMB looks up MakeADFun symbols dynamically; keep this TRUE. */
  R_useDynamicSymbols(dll, TRUE);
}
