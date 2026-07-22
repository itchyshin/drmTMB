# Homepage and navigation: audit closeout

- **Audit date:** 2026-07-21
- **Pinned base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`
- **Sources:** `README.md`, `_pkgdown.yml`
- **Rendered route:** `index.html`
- **Scope:** homepage, navbar labels, and reference-section labels; no Julia
  implementation or owner-held `bivariate-coscale` source was changed.

## Findings and repair

The README reader path was checked against the article menu and the current
0.6 release-scope boundary. It correctly directs first-time users to getting
started, family choice, model maps, diagnostics, and documented specialist
routes.

A P1 global navigation inconsistency remained after the Julia article repair:
the Specialist Routes menu advertised “Running models with the Julia engine”
and “Cross-family bivariate (Julia)”, and the reference group called those
methods experimental. The bridge is halted/deferred. The menu now says “Julia
support (future work)” and “Cross-family bivariate (deferred)”; the reference
group explains that the retained bridge methods are compatibility surfaces, not
current fitting routes. README now says the same explicitly.

## Render and checks

- `pkgdown::build_home(pkg = ".")` completed after a permitted CRAN-sidebar
  network lookup; the initial sandboxed build failed only because that lookup
  could not resolve `cloud.r-project.org`.
- `git diff --check` passed.
- Fresh render evidence: `renders/homepage-desktop-1440x1000.png` and
  `renders/homepage-mobile-390x844.png`.
- Mobile inspection confirmed a readable sequence of route cards, code blocks,
  capability boundary, and navigation trigger.

## Boundary retained

This repair does not restore, test, install, benchmark, or certify the Julia
engine; it neither alters a reference method nor changes a model claim. The
full reference route/search/sitemap verification remains part of the next
reference-documentation phase.
