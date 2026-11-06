# Student-t SD endpoint guard

The Student-t builder now refuses `sd(..., dpar = "nu")` instead of silently dropping it. The test-first regression failed before the guard and passed after it. The focused Student-t SD test passed 28 assertions; the broader Student filter passed; the explicitly configured Julia bridge filter passed two live tests. Student-t SD regression remains limited to the `mu` endpoint. Full checks and programme-wide interval coverage were not run.

Exact commands and the first failing assertion are recorded in `docs/dev-log/after-task/2026-10-22-student-sd-target-guard.md`.
