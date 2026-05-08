---
name: prose-style-review
description: Review and improve drmTMB prose in README files, vignettes, pkgdown articles, after-task reports, release notes, design docs, and manuscript-style text for clarity, concrete claims, stable terminology, citations, and reader fit.
---

# Prose Style Review

Use this skill for substantial prose, especially public documentation and
after-task reports. It is a compact drmTMB adaptation inspired by
`yzhao062/agent-style`; do not copy that project into this repository or add a
package dependency.

## Reader First

Before editing, name the reader:

- applied ecology, evolution, or environmental-science user;
- adjacent-field graduate student;
- statistical method developer;
- R package contributor;
- reviewer of a paper, grant, or release.

Write for that reader's current knowledge. Explain a term when the reader
would otherwise have to infer it from context.

## Review Checklist

1. Lead with purpose before mechanics.
2. For model docs, pair symbolic equation, R syntax, and interpretation.
3. Replace vague nouns with concrete functions, parameters, files, equations,
   checks, or numerical results.
4. Use active voice when the actor matters.
5. Delete filler phrases such as "it is important to note that", "in order to",
   "various factors", "significant improvements", and "leverages".
6. Do not over-bullet. Use bullets for genuine lists; use prose for one or two
   connected ideas.
7. Keep terms stable: `sigma`, `rho12`, `sd(group)`, `meta_known_V(V = V)`,
   `phylo()`, `spatial()`, `mu`, and `nu` for the first shape parameter.
   Mention `tau` only when explaining a second shape parameter or when
   contrasting drmTMB's `sigma` with meta-analysis notation. Use `skew` only as
   an interpretation or documented alias, not as the default canonical name.
8. Support factual, statistical, or literature claims with citations, local
   evidence, check outputs, or a clear "design assumption" label.
9. For tutorials and error-message docs, tell the reader what to do next when a
   model or syntax is unsupported.
10. Define location, scale, shape, and coscale at first use. In particular,
    connect coscale to residual correlation `rho12`.
11. End paragraphs with the point the reader should carry forward.
12. Avoid repeated sentence openings and repeated paragraph-summary closers.

## Role Guidance

- Pat checks whether an applied user can follow the prose, run the example,
  and interpret the output.
- Rose checks stale wording, unsupported claims, duplicated summaries, and
  contradictions with code, docs, tests, roadmap, or after-task notes.
- Documentation writers check examples, headings, equations, citations, and
  pkgdown navigation as one learning path.

## Output

For a review-only task, return:

- blocking confusion;
- important friction;
- small polish;
- suggested wording for the highest-impact fixes.

For an edit task, make the smallest prose edits that fix the problem, then
record what changed in the check log or after-task report when the task is
meaningful.
