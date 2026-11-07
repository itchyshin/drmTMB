# Native family SD adapter map reconciliation

## Check result

Updated the internal map to match the scoped implementation evidence for
Student-t, zero-inflated NB2, and zero-truncated NB2 independent location
slopes. The map now says that its former ordinary-family implementation order
is stale and directs slice selection back to the capability inventory. This is
a documentation correction only; it adds no model support or programme-gate
evidence.

## Checks

- Read the Student-t, zero-inflated NB2, zero-truncated NB2, and Gamma animal
  slope after-task reports to verify the exact support boundaries.
- `git diff --no-index --check /dev/null
  docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`: exit 1
  because the untracked file differs from `/dev/null`; stdout and stderr were
  empty, so the check reported no whitespace errors.
- The scoped stale-wording search below returned no obsolete map phrases.

```sh
rg -n 'ordinary `mu` intercepts only|random slopes excluded|Suggested implementation order|ordinary-intercept routes' docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md
```

No test suite was run because this slice changes only an internal source map.
`gh issue list --repo itchyshin/drmTMB --state open --search 'native family SD
adapter map' --limit 10` returned no matches. No issue was changed; this was
reconciliation of existing evidence, not a new feature request.

## Limits

The map does not enumerate or close the full family, effect, endpoint, provider,
or engine universe. G0 and G3 remain open. The cited slice reports and their
tests remain the evidence for behavior; this file summarizes their scope and
does not establish programme-level parity.
