# After-task: unknown nlminb control warning (#1734)

## Task goal

Emit a classed `drmTMB_unknown_optimizer_control` warning with did-you-mean text when `control` contains an unrecognized `nlminb()` element (for example `eval.maxx`), keep the fit behaviour unchanged, and avoid the duplicate generic `nlminb` warning.

## Files changed

- `R/utils.R` — `drm_suggest_closest_name()`, `drm_nlminb_control_names()` (same suggestion logic as #1698 / PR #1721).
- `R/control.R` — `drm_sanitize_nlminb_controls()`; strip unknown names before optimization.
- `tests/testthat/test-fix-1734-unknown-optimizer-control.R`.
- `NEWS.md`, `docs/dev-log/check-log.d/2026-11-12-fix-1734-unknown-optimizer-control.md`.

## Checks run

```text
branch: 3 tests, 7 expectations, 0 failures (test-fix-1734-unknown-optimizer-control.R)
main:   expect_warning(class = drmTMB_unknown_optimizer_control) fails; nlminb generic warning only
```

`R/drmTMB.R` was not edited; no model-15 capability recertify.

## Consistency audit

- Plain `control = list(...)` and `drm_control(optimizer = list(...))` both pass through `drm_control()` when `optimizer_method` is `nlminb`.
- Valid names (`eval.max`, `iter.max`) unchanged.

## Known limitations

- Direct `stats::nlminb()` calls from `profile()` refits are unchanged; only the public `drm_control()` / `drm_parse_control()` path is sanitized.

## Next actions

None for this slice.
