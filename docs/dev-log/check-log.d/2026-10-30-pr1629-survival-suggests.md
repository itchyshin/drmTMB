# 2026-10-30: declare survival in Suggests for #1629

CI R CMD check warned `'::' or ':::' import not declared from: 'survival'`
in the tests (shard 1/3/4). The new pin uses
`bf(survival::Surv(time, event) ~ age)`. Added `survival` to Suggests.
No likelihood or default change.
