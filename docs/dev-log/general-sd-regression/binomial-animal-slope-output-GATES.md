# Gates: native Binomial animal-slope prediction and simulation

OWNS: `R/methods.R`, `tests/testthat/test-binomial-animal-slope-sd-regression.R`, `docs/dev-log/general-sd-regression/binomial-animal-slope-output-GATES.md`, `docs/dev-log/after-task/2026-10-21-native-binomial-animal-slope-output.md`, `docs/dev-log/check-log.d/2026-10-21-native-binomial-animal-slope-output.md`

Scope: carry the animal random-slope design through native q=1 structured-effect prediction and fresh marginal simulation; preserve intercept behavior.

- [x] G1: Focused native animal-slope test passes with a failing-test guard and public prediction/simulation assertions.
  CHECK: cd ../../.. && OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'results <- devtools::test(filter = "binomial-animal-slope-sd-regression", reporter = "summary"); if (!testthat:::all_passed(results)) quit(status = 1); cat("ANIMAL_SLOPE_TESTS_PASS\n")'
  EXPECT: ANIMAL_SLOPE_TESTS_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/docs/dev-log/general-sd-regression; path=9b3b586a2d69/27 entries; output=ℹ Testing drmTMB | Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration (mock-driven marshalling tests are counted by CI's 'Julia bridge glue executes (mock-driven, no Julia)' step).

- [x] G2: Patch whitespace checks pass.
  CHECK: cd ../../.. && git diff --check -- R/methods.R && python3 -c 'from pathlib import Path; p=Path("tests/testthat/test-binomial-animal-slope-sd-regression.R"); lines=p.read_text().splitlines(); bad=[i for i,line in enumerate(lines, 1) if line.rstrip() != line]; assert not bad, bad; assert p.read_bytes().endswith(b"\n") and not p.read_bytes().endswith(b"\n\n"); print("OWNED_WHITESPACE_PASS")'
  EXPECT: OWNED_WHITESPACE_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/docs/dev-log/general-sd-regression; path=9b3b586a2d69/27 entries; output=OWNED_WHITESPACE_PASS

- [x] G3: Independent code review confirms q=1 intercept behavior, slope design application, and simulator path.
  EVIDENCE: Independent review on 2026-10-21 confirmed that the q=1 helper multiplies each latent value by its stored design column, preserving intercept contributions where the design is one and applying the animal slope loading to conditional prediction and fresh marginal draws. The test fixture uses 33 symmetric points from -1 to 1, so each group has an actual zero row; an explicit count assertion prevents vacuous zero-row checks. Reviewer did not run tests; G1 provides the execution evidence.
