# Review: acceptance bands after moving to 97.5% fitted intervals

The corrected native Bernoulli first look used 97.5% fitted profile intervals
for all 3,000 planned attempts. The frozen decision contract still uses a
coverage acceptance band of [0.925, 0.975] and a null false-positive band of
[0.025, 0.075]. Those bands place the expected rates for a calibrated 97.5%
interval at their edges: expected coverage is 0.975 and the expected null
false-positive rate is 0.025.

An independent inference review concluded that this makes passing difficult:
the decision requires the full 97.5% Monte Carlo interval to lie inside each
band, so a calibrated result is likely to be classified as ambiguous. The bands
appear centered on the historical 95% target. This is a methods finding, not a
change to the frozen rule. The contract and bands remain unchanged pending a
reviewed decision about the intended estimand, tolerance bands, and repeated-look
error control.

For the corrected first look, coverage was 0.965, 0.980, and 0.979 for truths
-0.5, 0, and 0.5. The exact 97.5% binomial intervals were [0.9496, 0.9768],
[0.9676, 0.9886], and [0.9664, 0.9879]. The null false-positive rate was
0.020, with interval [0.0114, 0.0324]. Under the frozen bands all four gates
are ambiguous, so the helper returns `look2_required`. This is a mechanical
classification, not evidence that the 97.5% intervals are calibrated. The
higher coverage and lower false-positive rate are consistent with conservative
intervals.

The production run completed all 3,000 fits; every fit was healthy, every
profile interval valid, and every independent Laplace-oracle check passed. The
campaign summary script was not registered in the campaign's source registry.
Its SHA-256, input manifest hash, registry hash, supervisor-receipt hash, and
summary hashes are recorded in `evidence/calibration-20261017/first-look-postfix-20261019-v2/summary-tool-receipt.json`.
The full 15,016-file output copy is in that directory. Key file hashes match the
remote receipt. A full local per-file checksum pass was stopped because it was
too slow on the Dropbox-backed copy; full byte-by-byte transfer verification is
therefore not claimed.

No acceptance-band change or second-look fit was authorized by this review.
