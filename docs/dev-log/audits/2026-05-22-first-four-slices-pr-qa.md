# First Four Slices: PR, Render, Alt Text, and Caption QA

Date: 2026-05-22

## Scope

This note records the first four-slice follow-up after the Confidence Eye and
figure-gallery repair:

1. keep the existing draft PR as the review surface;
2. render-check the figure-heavy articles;
3. audit figure alt text across the rendered pages;
4. add explicit `figure-gallery` captions that name the estimand, data grain,
   scale, and uncertainty source.

The active review roles were Ada, Florence, Fisher, Pat, Grace, and Rose. They
are review perspectives, not spawned agents.

## PR Surface

The active branch is `codex/cpp-helper-extraction`. It already has draft PR
[#297](https://github.com/itchyshin/drmTMB/pull/297), titled "Audit CI,
references, and Confidence Eye figures". This slice updates that PR rather than
opening a duplicate.

## Rendered Pages Checked

The following pages were rebuilt with `pkgdown::build_article()`:

| Article | Rendered path |
| --- | --- |
| `figure-gallery` | `pkgdown-site/articles/figure-gallery.html` |
| `model-workflow` | `pkgdown-site/articles/model-workflow.html` |
| `bivariate-coscale` | `pkgdown-site/articles/bivariate-coscale.html` |
| `simulation-plot-grammar` | `pkgdown-site/articles/simulation-plot-grammar.html` |

Browser QA used a local static server at `http://127.0.0.1:8472/` because the
in-app browser blocks direct `file://` navigation. The rendered pages loaded
successfully over the local server.

## Alt Text And Caption Audit

| Article | Content images | Missing alt text | Captions | Verdict |
| --- | ---: | ---: | ---: | --- |
| `figure-gallery` | 21 | 0 | 21 | Passed after adding explicit captions to all gallery figures. |
| `model-workflow` | 5 | 0 | 0 | Passed for alt text; captions remain a later article-specific polish slice. |
| `bivariate-coscale` | 2 | 0 | 0 | Passed for alt text; captions remain a later article-specific polish slice. |
| `simulation-plot-grammar` | 5 | 0 | 0 | Passed for alt text; captions remain a later simulation-grammar polish slice. |

## Caption Rule Applied

The new `figure-gallery` captions are deliberately short. Each caption should
answer at least one of these questions without duplicating the alt text:

- What is the estimand: `mu`, `sigma`, `nu`, `zi`, `rho12`, `sd(group)`,
  marginal mean, correlation row, support status, or simulation operating
  characteristic?
- What marks are being drawn: raw observations, fitted rows, conditional modes,
  Confidence Eyes, point-interval summaries, support markers, replicate errors,
  or aggregate simulation summaries?
- What uncertainty is shown: 95% Wald band, log-SD Wald eye, Fisher-z Wald eye,
  `emmeans` fixed-effect interval, display approximation from row-wise Wald
  limits, MCSE interval, or no interval because the derived surface does not
  provide one?

Rose records the guardrail: alt text tells a screen-reader user what the figure
looks like and what pattern matters; captions tell every reader what inferential
object and uncertainty source the figure should be understood as showing.

