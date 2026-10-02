# T3-8 Toeplitz redesign decision

## Finding

The direct prototype's covariance is

\[
V_i=s_a^2R(r_1,\ldots,r_{K-1})+\sigma^2I.
\]

With one observation per series--occasion and every positive-lag correlation
free, this has an exact non-identifiability. For an admissible constant \(c\)
near one,

\[
s_{a,new}^2=c s_a^2,\qquad
r_{d,new}=r_d/c,\qquad
\sigma_{new}^2=\sigma^2+(1-c)s_a^2
\]

leave \(V_i\) unchanged. The deterministic test
`test-temporal-homtoep-identifiability.R` verifies this equality for both the
dense covariance and its Gaussian likelihood. The timed pilot consequently had
15 finite optima but 15 non-positive-definite observed Hessians.

This is a model property, not a TMB, optimizer, or finite-difference defect.
The recorded temporal implementation library reaches the same design boundary:
[glmmTMB's covariance vignette](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html)
disables free residual dispersion for flexible Toeplitz comparisons. It follows
that a direct Toeplitz provider cannot promise the AR1/OU decomposition into
stable differences, persistent deviation, and independent residual noise.

## Decision required

Choose one identified scientific contract before any profile, coverage, reader,
or public-interface work resumes.

### M — marginal homogeneous Toeplitz covariance (recommended for ordinary CSV panels)

Fit a single within-series covariance:

\[
y_i\sim N(X_i\beta,\;s_T^2R(r_1,\ldots,r_{K-1})).
\]

` s_T ` is the total marginal within-series SD. There is no separately estimated
observation-level `sigma`, no latent temporal-process SD, and no conditional
temporal random-effect prediction. The result answers: *do correlations at
equal discrete lags depart from an AR1/OU decay pattern?* It is suited to the
ordinary one-row-per-series--occasion CSV layout. AR1 and OU remain the routes
for a latent-process plus residual-noise decomposition.

An independent 80-series by six-occasion pure-R spike fits this exact
marginal likelihood with a positive numerical observed-information matrix (minimum
eigenvalue 47.77). It is retained as an M-candidate feasibility check, not as
recovery, interval, or production-provider evidence.

The redesign must use a distinct public marker (provisionally
`temporal_cov(1 | id, time = occasion, structure = "homtoep")`) so a covariance
model cannot be mistaken for a temporal random effect. The exact name remains a
formula-review decision. It must preserve common complete equally spaced
schedules, positive-definite PACF coordinates, dense marginal oracle tests,
and fixed-effect covariance/interval qualification.

### R — replicated latent Toeplitz process

Admit an explicit replicate key \(j\) and fit

\[
y_{ikj}=x_{ikj}^{T}\beta+a_{ik}+\epsilon_{ikj},\qquad
\operatorname{Cov}(a_{ik},a_{il})=s_a^2r_{|k-l|},\qquad
\epsilon_{ikj}\sim N(0,\sigma^2).
\]

Repeated independent measurements at each series--occasion identify the
within-occasion residual variation separately from the shared temporal process.
This keeps the AR1/OU-style scientific decomposition, but requires a different
CSV admission rule: `(id, occasion, replicate)` must be unique and the panel
must contain enough within-occasion replication. The current duplicate-key
rejection and one-row layout deliberately do not provide this information.

### Not selected — fixed nugget or silent optimizer changes

Fixing `sigma` to an arbitrary value, hiding the Hessian diagnostic, or widening
the campaign changes the interpretation without resolving the data information.
Those paths are excluded from the programme.

## Recommendation and consequences

Choose **M** for the first public Toeplitz capability: it matches ordinary panel
CSV data, is the established flexible-covariance convention, and makes its
single variance interpretation explicit. Keep the direct latent prototype only
as non-public research evidence. Choose **R** only when the target data have
actual replicate observations at each time and the scientific aim requires a
separate residual-noise estimate.

After a choice, freeze a replacement P2 contract, retire the current public
`homtoep` marker before release, and restart deterministic tests, recovery,
pilot, interval calibration, documentation, and campaign gates against the
chosen likelihood. Prior direct-prototype recovery evidence does not transfer to
the redesigned public model.
