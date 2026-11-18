# Two-intercept oracle: MIT provenance

Shinichi confirmed that the identified oracle scripts and fixtures may be made available under the MIT license in `LICENSE`, subject to final provenance review. This confirmation concerns these identified artifacts; it does not relicense third-party or drmTMB GPL source or resolve the unknown original Julia converter.

## Scope and trace

The artifacts describe a dense Gaussian two-random-intercept oracle used to validate targeted SD prior calculations. The retained Codex session records creation of `oracle.py` on 13 November 2026 at 20:18:46 UTC, a one-literal correction at 20:19:14, and creation of `supplemental.py` at 20:21:23. Reconstructing the creation calls and correction yields the exact generator bytes listed below; an independent reviewer confirmed that match. The session records alone do not prove absence of earlier copied material or establish a human author or copyright owner.

The first generator run failed because SciPy was unavailable. The corrected run succeeded and recorded `frozen.json`; the supplemental run recorded `asymmetric-frozen.json`. The original SciPy version was not recorded. A separate mathematical reviewer checked the dense likelihood, derivatives, finite-difference agreement and wrong-implementation controls before package results were examined. These checks establish numerical evidence, not legal ownership or inferential calibration.

| Artifact | SHA-256 |
|---|---|
| `oracle.py` | `d6e272b9993c686a50909ffca6714154503f29a666bb49c3b00f533da064c80e` |
| `supplemental.py` | `b11598b421f6f57360b38f6541e76a1614a9a52e7f04585566fb23942d038ec7` |
| `frozen.json` | `d2bfbbac2d5e0127c90ef877c01259fda56526b2797240ddf718e0f782f6e1e2` |
| `asymmetric-frozen.json` | `91de5613071175a8789a349243230a2023ae6aadd70bb35f9d6acc48938a0b85` |
| `verify.py` | `a77e51aa95b8f4a2f1237f0b181fc46a8f2e5f5a4c11c82f26a3fd5d5fcad7b5` |
| `verify_asymmetric.py` | `a2c62e2728c678db76b5bafb89f8098158e07f29c9f4bcfb636fbb3e4cd0cdb0` |

`manifest.json` and `asymmetric-manifest.json` are the original retained hash manifests. Run `python3 verify.py` and `python3 verify_asymmetric.py` with NumPy and SciPy available; they read the frozen JSON and do not require either package. The scripts use Python assertions, so run them without `python -O`. Record interpreter and dependency versions with any reproduction. The verifiers can validate stored results without reconstructing the missing original SciPy version.

## Julia fixture and license boundary

The Julia `test/fixtures/prior_table_oracle.jl` contains numerical arrays reproduced from the two pinned JSON files. Its original converter was not retained; a later independently written replacement regenerates it byte for byte. The inspected Julia diff showed no demonstrated copied drmTMB GPL implementation source. This is a scoped source review, not an affirmative license determination for every input or a legal opinion.

The original Julia converter and original SciPy version remain unrecorded. The separately written replacement converter and the numerical checks do not establish those missing historical details.

## Verification, 14 November 2026

The copied files matched both original manifests. Using the specified Miniconda interpreter, `verify.py` passed 90 points, 12 fits and seven controls; `verify_asymmetric.py` passed 60 points and eight fits. Maximum finite-difference gradient errors were 6.89e-10 and 6.41e-10; scaled Hessian errors were 2.85e-7 and 2.76e-7. The verification logs and post-run version receipt are retained separately from this fixture directory. The post-run check reported Python 3.13.2, NumPy 2.3.3 and SciPy 1.16.2; the verifier logs did not record versions during execution. This check does not establish the original generator's SciPy version.
