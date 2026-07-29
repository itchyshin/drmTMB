# AOI-1 handover — full fixed-effect Association-of-Interest surface

## State

AOI-0 merged F4R PR #864 after green CI. AOI-1 is implemented on
`codex/aoi-full-fixed`, branched from the resulting `origin/main` merge commit
`47b9d94677993ee07036703ac049a6fa8c18a4b8`. The tested AOI-1 implementation
commit is `90c186611`.

## What is present

For frozen-margin literal Bernoulli × ordinary-NB2 pairs only,
`association = ~ x1 + x2 + habitat + x1:habitat` and standard fixed-effect
model-matrix variants now fit. The object stores exact training design metadata.
`predict()` preserves historical fitted margins with no arguments; link and
response association predictions, including compatible `newdata`, are available
as point estimates only.

## Evidence

`devtools::test(filter = "associate-pairs-bernoulli-nb2", stop_on_failure = TRUE)`
passed 87/87. The complete association suite passed 485/485. Fisher and Rose
reviewed the implementation, caught transform replay and uncertainty-option
gaps, and cleared the repaired version. See the AOI-1 after-task receipt.

## Hard boundaries

Do not expose the private sandwich through `vcov()`, `confint()`, profiles, or
standard errors. Do not make a public association inference claim. Do not alter
capability ledgers or public articles. Do not touch Lane B `sd()`/Arc D or
foreign association branches. No recovery or coverage campaign was launched.

## Next decision

AOI-2 is a separate proposal: first write a preregistered multi-predictor
point-recovery ladder, run only a local non-empty smoke after owner approval,
then obtain explicit owner approval before a DRAC campaign. AOI-3 additionally
requires a grounded methods review before the multi-parameter uncertainty
contract and full-refit calibration are frozen. The no-compute decision packet
is [`2026-07-29-aoi2-aoi3-validation-protocol.md`](../2026-07-29-aoi2-aoi3-validation-protocol.md).
