# Pedigree and known-precision edge tests (#1599)

Merged the test-only PR candidate, originally at `ef3bc4690f27644458aa48cdc212fa8061481f15`, with exact current main `2fb93b768977330fc9939d86375c37329a539277` in a dedicated local worktree. The merge completed without conflicts. Candidate before this report update: `d7f9d1775ed79a29f3d03ec744290682bf68fb8d`. The root `check-log.md` was preserved because current main contains append-only records.

`R_PROFILE_USER=/dev/null Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-pedigree-known-precision-edges.R")'`: PASS, 66 expectations, 0 failures, 0 warnings, 0 skips (29.4 seconds). `python3 tools/capability_ledger.py --check`: PASS (31 generated outputs). `python3 tools/capability_ledger.py --check-c14-receipt-equivalence`: PASS (3 eligible; 7 retained source-different receipts). `python3 -m unittest tools.tests.test_capability_ledger`: PASS (81 tests). `git diff --check`: PASS.

The after-task structural check passes. The Brain closeout wrapper remains blocked by nine unmet global acceptance gates outside this PR and worktree; no unrelated gate was edited. Prose check passes with 0 findings.

This is focused evidence only. The full package suite and current-candidate `R CMD check` were not run. The previous exact-PR-head workflow run `39856569302` was cancelled with three of four Linux shards and the source-tree job passing. The PR remains draft; this local candidate was not pushed.
