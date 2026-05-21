# After Task: Pkgdown Root Site Deployment Hotfix

## Goal

Restore the public pkgdown site at `https://itchyshin.github.io/drmTMB/` so
applied users can reach the package reference and articles from the canonical
project URL.

## Implemented

Changed `_pkgdown.yml` to use `development: mode: release`. This tells pkgdown
to build the public root artifact instead of placing the rendered site under
the development subdirectory.

## Mathematical Contract

No statistical model, likelihood, formula grammar, parameter scale, or
simulation contract changed. This was a website deployment configuration fix.

## Files Changed

- `_pkgdown.yml`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-pkgdown-root-site-hotfix.md`

## Checks Run

```sh
Rscript -e "pkgdown::build_site(new_process = FALSE, install = TRUE)"
test -f pkgdown-site/index.html && echo root-index-present || echo root-index-missing
test -f pkgdown-site/dev/index.html && echo dev-index-present || echo dev-index-missing
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'development:\s*$|mode:\s*auto|mode:\s*release|pkgdown-site/dev|itchyshin.github.io/drmTMB/dev' _pkgdown.yml .github docs README.md NEWS.md
gh issue list --repo itchyshin/drmTMB --state open --search 'pkgdown OR webpage OR "GitHub Pages" OR Pages' --limit 10 --json number,title,state,url
gh workflow run pkgdown --repo itchyshin/drmTMB --ref main
gh run view 26222653484 --repo itchyshin/drmTMB --json status,conclusion,updatedAt,url,jobs
curl -I -L --max-time 20 https://itchyshin.github.io/drmTMB/
curl -I -L --max-time 20 https://itchyshin.github.io/drmTMB/reference/index.html
curl -I -L --max-time 20 https://itchyshin.github.io/drmTMB/articles/structural-dependence.html
```

- Local `pkgdown::build_site()` completed successfully.
- The generated artifact contained `pkgdown-site/index.html`.
- The generated artifact did not contain `pkgdown-site/dev/index.html`.
- `git diff --check` was clean.
- `pkgdown::check_pkgdown()` reported no problems.
- The routing scan found the intended `mode: release` setting and no current
  `mode: auto` or `/drmTMB/dev` deployment target.
- GitHub Actions run `26222653484` completed successfully, including the
  `pkgdown` and `deploy` jobs.
- The public root URL, reference index, and structural-dependence article each
  returned HTTP 200 after the deploy.

## Tests Of The Tests

This task did not add package tests because it did not change R behavior. The
deployment check is artifact-level: the local site build must place
`index.html` at `pkgdown-site/index.html` rather than under `pkgdown-site/dev/`.

## Consistency Audit

The pkgdown configuration still points at `https://itchyshin.github.io/drmTMB/`.
The navbar and reference index were not changed. No generated documentation was
committed.

## GitHub Issue Maintenance

An open-issue search for `pkgdown`, `webpage`, `GitHub Pages`, and `Pages`
found broad docs and release issues, but no issue specifically tracking the
broken public root URL. No duplicate issue was opened for this small hotfix.

## What Did Not Go Smoothly

The first public URL check still returned 404 because the GitHub Pages workflow
had not finished deploying the new artifact. After the deploy job completed,
the public root URL returned HTTP 200.

## Team Learning

Grace should treat `development: mode: auto` as risky for the public Pages
artifact when the repository version is in development. Pat's useful-user check
is simple: the canonical root URL must load, not only a development subpath.

## Known Limitations

This hotfix restores the deployment location. It does not audit every rendered
article for reader flow or refresh structural-dependence examples.

## Next Actions

Continue the next structural-dependence parity slices, starting with publishing
or rebasing the isolated slice-1-to-8 branch and then moving into q=4
animal/relmat and spatial parity evidence.
