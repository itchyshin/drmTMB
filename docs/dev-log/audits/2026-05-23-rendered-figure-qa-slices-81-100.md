# Rendered Figure QA: Slices 81-100

## Scope

Slices 81-100 close the current rendered-figure sweep by adding one
case-appropriate rendered figure to each remaining family or model-family
tutorial that was still figure-free: `robust-student`, `count-nbinom2`,
`proportion-beta-binomial`, and `meta-analysis`.

No package code, likelihood, formula grammar, extractor, interval method, or
exported plotting helper changed.

## Figure Decisions

| Slice | Article | Figure chunk | Visual data grain | Uncertainty or support source | Verdict |
| --- | --- | --- | --- | --- | --- |
| 81 | rendered inventory | family tutorial gap | four tutorial pages had no article figure | not applicable | improve |
| 82 | `robust-student` | source decision | robust family motivated by large residuals | raw response tails are warranted | add raw-plus-fitted figure |
| 83 | `robust-student` | `robust-student-tail-figure` | observed growth values plus Gaussian and Student-t fitted `mu` points | none; point comparison only | keep |
| 84 | `count-nbinom2` | source decision | zero-inflated NB2 has several fitted response-scale components | no interval columns in the example | add component display |
| 85 | `count-nbinom2` | `count-model-parts-figure` | conditional mean, unconditional mean, NB2 `sigma`, and zero-inflation probability | facets use separate x scales; no interval geometry | keep |
| 86 | `proportion-beta-binomial` | source decision | denominator-aware proportions still have raw tray observations | fitted tray-level scatter is not a CI | add raw-plus-fitted scatter display |
| 87 | `proportion-beta-binomial` | `beta-binomial-tray-figure` | raw tray proportions plus fitted expected probability | bars are plus or minus one fitted proportion SD, not confidence intervals | keep |
| 88 | `meta-analysis` | source decision | article needs to separate known sampling variance from fitted heterogeneity | variance components, not intervals | add variance-component display |
| 89 | `meta-analysis` | `meta-variance-components-figure` | mean known sampling variance plus fitted extra heterogeneity variance | stacked variance components with total point | keep |
| 90 | rendered HTML | robust-student inventory | one referenced image | 0 missing alt text, 1 caption | accepted |
| 91 | rendered HTML | count-nbinom2 inventory | one referenced image | 0 missing alt text, 1 caption | accepted |
| 92 | rendered HTML | proportion-beta-binomial inventory | one referenced image | 0 missing alt text, 1 caption | accepted |
| 93 | rendered HTML | meta-analysis inventory | one referenced image | 0 missing alt text, 1 caption | accepted |
| 94 | rendered PNG | robust-student image | raw tails and fitted points visible | no fake interval | accepted |
| 95 | rendered PNG | count-nbinom2 image | response-scale fitted components separated by facet | mixed units are separated | accepted |
| 96 | rendered PNG | proportion-beta-binomial image | raw proportions plus fitted scatter bars visible | bars labelled as fitted scatter | accepted |
| 97 | rendered PNG | meta-analysis image | known sampling and fitted heterogeneity variances separated | total point visible | accepted |
| 98 | rendered checklist | article inventory | figure counts refreshed for previous and new figure pages | not applicable | updated |
| 99 | visualization grammar | family tutorial rule | raw, fitted component, and variance-component displays separated | not applicable | updated |
| 100 | after-task/check-log | durable evidence | validation commands and limitations | not applicable | recorded |

## Rendered Figures

Rendered images inspected directly:

- `pkgdown-site/articles/robust-student_files/figure-html/robust-student-tail-figure-1.png`
- `pkgdown-site/articles/count-nbinom2_files/figure-html/count-model-parts-figure-1.png`
- `pkgdown-site/articles/proportion-beta-binomial_files/figure-html/beta-binomial-tray-figure-1.png`
- `pkgdown-site/articles/meta-analysis_files/figure-html/meta-variance-components-figure-1.png`

Florence accepted the four images because each has a clear first reading and
does not reuse the Confidence Eye grammar where it is not warranted. Fisher
accepted the uncertainty grammar: the Student-t and count figures are fitted
point/component displays; the beta-binomial bars are fitted tray-level scatter,
not confidence intervals; the meta-analysis bars are variance components, not
parameter uncertainty. Pat accepted the reader decoding because each figure
appears near the table or text it visualizes.

## Remaining Limits

These figures are article recipes. They do not add package plotting helpers and
do not claim formal interval evidence where the examples only compute fitted
points or fitted distributional scatter.
