# Arc 6.5 plan-versus-actual receipt

The owner approved execution and Totoro simulation in thread `019f9041-2a97-7850-b8d5-79ebe96a2aa9`. Source commits `bc2c1c29` and `51647467` add the frozen literal-Bernoulli rectangle route, tail-stable thresholds, oracle/simulator tests, and an all-attempt recovery runner. Focused Arc 6.1, 6.2, and 6.5 tests passed.

Totoro ran the corrected frozen source `51647467196f9f212dea0bcb323fe649462f570d` at `~/hsq_work/arc65-runs/2026-07-24-51647467-r10/`. It retained 220 raw attempts: 180 interior and 40 rare/near-boundary HOLD attempts. Seventeen of 18 interior cells passed the rule of 10/10 returned estimates and absolute mean bias at most 0.10. The `n=120`, asymmetric-prevalence, true `eta=0.5` cell returned 9/10 because one fit was `boundary_unresolved`.

**Terminal disposition: HOLD.** The all-attempt denominator is not weakened. PR #821 stays open and unmerged; no recovery, interval, coverage, or capability claim is made. A new owner decision is required before changing the boundary policy, sample-size floor, or recovery design.
