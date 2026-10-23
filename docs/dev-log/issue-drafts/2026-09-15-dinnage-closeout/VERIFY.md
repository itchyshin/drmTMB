# Verification: Dinnage Closeout (2026-09-15)

Date: 2026-09-15

## Measurement Results

**1. Closed Issues Match**
Command: `gh issue list --repo itchyshin/drmTMB --state closed --label audit-dinnage --limit 200 --json number`
Result: 16 closed issues found (1306, 1307, 1308, 1309, 1310, 1311, 1312, 1313, 1314, 1318, 1321, 1322, 1330, 1331, 1347, 1352)
Expected: 16 issues from CLOSED.tsv
Status: MATCH

**2. Open Issues Count**
Command: `gh issue list --repo itchyshin/drmTMB --state open --label audit-dinnage --limit 200 --json number`
Result: 39 open issues
Expected: 39
Status: PASS

**3. Closed Issues State & Comments**
Command: `gh issue view <N> --repo itchyshin/drmTMB --json state,comments` (for each of 16 closed issues)
Result: All 16 issues have state == CLOSED, and last comment starts with "Status (2026-09-15)" and contains "Closing"
Expected: State CLOSED with conforming comment
Status: PASS

**4. Issue #1301 State & Comment**
Command: `gh issue view 1301 --repo itchyshin/drmTMB --json state,comments`
Result: State == OPEN, last comment starts with "Status (2026-09-15)" and does NOT contain "Closing" (states "stays open")
Expected: State OPEN with conforming comment
Status: PASS

**5. Em Dash Count**
Command: Count occurrences of "—" in each of 17 last comments
Result: 0 em dashes total across all 17 comments
Expected: 0
Status: PASS

## VERDICT: PASS
