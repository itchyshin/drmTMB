set -u
WT=/Users/z3437171/local-scratch/parity-joint/wt-fam-biv-student
PIN=/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc
cd "$WT"
run_focused () {
  NOT_CRAN=true OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true \
  DRM_JL_PATH="$PIN" DRM_JL_PHYLO_PATH="$PIN" \
  Rscript -e 'suppressMessages(devtools::load_all(".", quiet=TRUE)); df <- as.data.frame(testthat::test_file("tests/testthat/test-julia-family-biv_student.R", reporter="silent")); cat(sprintf("FAIL %d SKIP %d PASS %d ERROR %d\n", sum(df$failed), sum(df$skipped), sum(df$passed), sum(df$error)))' 2>&1 | grep -E "^FAIL"
}
echo "===== RC0 BASELINE (no defect) ====="
run_focused

echo
echo "===== RC1 PLANT: delete the spec(\"biv_student\", fe = TRUE) registry row ====="
shasum -a 256 R/julia-family-registry.R
python3 - <<'PY'
p="R/julia-family-registry.R"; s=open(p).read()
old='    spec("cumulative_logit", fe = TRUE, dispersionless = TRUE),'
new='    spec("cumulative_logit", fe = TRUE, dispersionless = TRUE)'
assert s.count(old)==1
s=s.replace(old,new)
i=s.index('    spec("biv_student", fe = TRUE)')
j=s.index("\n", i)
s=s[:i]+s[j+1:]
open(p,"w").write(s)
print("PLANTED: registry row removed")
PY
run_focused
git show HEAD:R/julia-family-registry.R > R/julia-family-registry.R
shasum -a 256 R/julia-family-registry.R
git diff --quiet HEAD -- R/julia-family-registry.R && echo "RESTORED_BYTE_IDENTICAL" || echo "RESTORE_FAILED"

echo
echo "===== RC2 PLANT: drop \"nu\" from the biv_student default-label branch ====="
shasum -a 256 R/julia-bridge.R
python3 - <<'PY'
p="R/julia-bridge.R"; s=open(p).read()
old='    for (dpar in c("sigma1", "sigma2", "nu", "rho12")) add_default(dpar)'
new='    for (dpar in c("sigma1", "sigma2", "rho12")) add_default(dpar)'
assert s.count(old)==1
open(p,"w").write(s.replace(old,new))
print("PLANTED: nu removed from the biv_student defaulter")
PY
run_focused
git show HEAD:R/julia-bridge.R > R/julia-bridge.R
shasum -a 256 R/julia-bridge.R
git diff --quiet HEAD -- R/julia-bridge.R && echo "RESTORED_BYTE_IDENTICAL" || echo "RESTORE_FAILED"

echo
echo "===== RC3 PLANT: remove the scope-fence call site ====="
python3 - <<'PY'
p="R/julia-bridge.R"; s=open(p).read()
old='  drm_julia_refuse_biv_student_beyond_native(formula, family_type)\n'
assert s.count(old)==1
open(p,"w").write(s.replace(old,""))
print("PLANTED: fence call removed")
PY
run_focused
git show HEAD:R/julia-bridge.R > R/julia-bridge.R
git diff --quiet HEAD -- R/julia-bridge.R && echo "RESTORED_BYTE_IDENTICAL" || echo "RESTORE_FAILED"

echo
echo "===== RC4 PLANT: remove the confint biv_student guard ====="
python3 - <<'PY'
p="R/julia-bridge.R"; s=open(p).read()
old='''  if (identical(object$model$model_type, "biv_student")) {
    cli::cli_abort(
      "{.fn confint} is not implemented for model type {.val {object$model$model_type}}; interval and profile claims are deferred."
    )
  }
  dots <- list(...)'''
assert s.count(old)==1
open(p,"w").write(s.replace(old,'  dots <- list(...)'))
print("PLANTED: confint guard removed")
PY
run_focused
git show HEAD:R/julia-bridge.R > R/julia-bridge.R
git diff --quiet HEAD -- R/julia-bridge.R && echo "RESTORED_BYTE_IDENTICAL" || echo "RESTORE_FAILED"

echo
echo "===== FINAL STATE ====="
run_focused
git status --porcelain
