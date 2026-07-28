# Lane B E4 validation receipt

## Atlas union

| Check | Result |
|---|---:|
| q1 atlas rows | 26 = P1 11 + P2 4 + P4 11 |
| q2/q4 atlas rows | 26 = P3 |
| high-q atlas rows | 24 = P5 8 + P6 16 |
| Atlas union | 76 unique IDs, exact equality with frozen structured field-missing E2 set |
| Atlas disposition | 76 `source_receipt_only_not_recovered`; 0 candidate cards |
| Retained controls | 6, all outside the atlas and still non-direct |

The union check rejects duplicates, omitted or out-of-cohort IDs, and any
status other than the source-only non-recovery disposition.

## E0 invariant

```text
Lane-B E0 readiness verified: 158 target cells; 62 recovered targets;
2 retained negative targets; 97 unresolved cells;
pregrid_authorized=FALSE.
```

## Scope audit

Only E4 files under `docs/dev-log/` are permitted. `git diff --check` passed.
No canonical binding, package/test, schedule, smoke, pregrid, remote, ledger,
capability, configuration, public/default, or API surface was changed. No fit,
profile, smoke, pregrid, or remote command ran.
