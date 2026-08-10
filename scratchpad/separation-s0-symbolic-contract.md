# S0-A symbolic contract — fixed-design binary separation

## Scope / estimand

This contract covers only fixed-effect, logit-linked binary likelihood blocks:

- Binomial `mu`: `bf(y01 ~ x)` or `bf(cbind(success, failure) ~ x)`, `family = stats::binomial(link = "logit")`.
- Hurdle-NB2 `hu`: `bf(count ~ 1, sigma ~ 1, hu ~ x)`, `family = truncated_nbinom2()`.

The detector authority is the maintained `detectseparation::detect_separation` API, including its documented use as `glm(..., method = "detect_separation", separation_type = TRUE)`. Do not use a `brglm2` shim.

All core LP fixtures use unit weights, an intercept, and a full-column-rank fixed-effect design. The sole rank-deficient fixture is a negative control and is not a separation claim.

## Symbolic criterion

For active Bernoulli rows \(A=\{i:\mathrm{observed}_i=1,\ w_i>0\}\), let

\[
\eta_i=o_i+x_i^\top\beta,\qquad
p_i=\operatorname{logit}^{-1}(\eta_i),\qquad
z_i=2y_i-1.
\]

The active binomial log likelihood is

\[
\ell(\beta)=\sum_{i\in A}w_i\{y_i\log p_i+(1-y_i)\log(1-p_i)\}.
\]

A separating ray is a nonzero \(d\) such that

\[
z_i x_i^\top d\ge0\quad \forall i\in A,
\]

with at least one strict inequality. It is:

- **complete** when \(z_i x_i^\top d>0\) for every active row;
- **quasi-complete** when at least one active row has equality and at least one has strict inequality.

Finite offsets \(o_i\) do not alter this ray criterion: they are \(O(1)\) while \(t x_i^\top d\) is evaluated as \(t\to\infty\).

For grouped binomial rows with successes \(s_i\), failures \(f_i\), and \(m_i=s_i+f_i\), the equivalent conditions are

\[
\begin{array}{rcl}
s_i>0,\ f_i=0 &\Rightarrow& x_i^\top d\ge0,\\
s_i=0,\ f_i>0 &\Rightarrow& x_i^\top d\le0,\\
s_i>0,\ f_i>0 &\Rightarrow& x_i^\top d=0.
\end{array}
\]

Complete separation requires strict inequalities for every pure-success or pure-failure group; mixed groups necessarily make the case quasi-complete.

For hurdle-NB2, define the observed zero gate \(g_i=\mathbb{1}(y_i=0)\),

\[
\eta_{h,i}=x_{h,i}^{\top}\beta_h,\qquad h_i=\operatorname{logit}^{-1}(\eta_{h,i}).
\]

On active rows, the exact hurdle likelihood factorizes as

\[
\ell_i=
g_i\log h_i+
(1-g_i)\{\log(1-h_i)+
\log f_{\rm NB2}(y_i;\mu_i,\sigma_i)-\log[1-f_{\rm NB2}(0;\mu_i,\sigma_i)]\}.
\]

Thus the `hu` separation criterion is the binary criterion above with response \(g_i\), not with \(\mathbb{1}(y_i>0)\). A `hu ~ x` ray that assigns higher hurdle-zero probability at negative \(x\) has negative slope direction.

## Alignment table

| Symbol | R field / formula | Fixture construction | Extractor | Truth |
|---|---|---|---|---|
| \(y_i\) | `y01`; `bf(y01 ~ x)` | `0/1` Bernoulli vectors below | maintained detector coefficient vector | `0` = finite, `Inf` / `-Inf` = directional infinity |
| \((s_i,f_i)\) | `cbind(success, failure)`; `bf(cbind(success, failure) ~ x)` | grouped quasi-complete fixture below | detector on grouped binomial design; normalized objective difference | same separation class and coefficient directions as expanded data |
| \(X=(1,x)\) | implicit intercept in `~ x` | every core fixture has `x` and default intercept | `model.matrix(~ x, data)` | rank 2 for every core LP fixture |
| \(d_\mu\) | coefficient order `c("(Intercept)", "x")` | complete/quasi binomial: `c(0, 1)` | exact likelihood ray | intercept finite; `x -> +Inf` |
| \(o_i\) | `offset(off)` inside binomial `mu` formula | finite offset control below | active-row LP and ray direction | unchanged from unoffset fixture |
| \(w_i\) | `weights = w` | zero-weight contradictory row below | active-row LP after `w > 0` filter | excluded row cannot alter separation truth |
| \(\mathrm{observed}_i\) | `missing = miss_control(response = "include")` | `NA_integer_` contradictory response below | active-row LP after observed-response mask | masked row cannot alter separation truth |
| \(g_i=\mathbb{1}(y_i=0)\) | `hu ~ x`; `family = truncated_nbinom2()` | hurdle fixtures below | `coef(fit, dpar = "hu")` in later empirical work; exact `hu` block ray now | complete/quasi `hu` direction is `c(0, -1)` |
| \((\mu_i,\sigma_i)\) | `count ~ 1, sigma ~ 1` | fixed intercept-only positive-count component | separate `mu` / `sigma` extraction only | not a separation estimand; no S0 infinity claim |
| rank control | `bf(y01 ~ x + twox)` | `twox = 2 * x` | rank diagnostic, not detector truth | rank deficiency is not separation |

## Fixture table

| ID | Exact construction | Formula / component | Expected status |
|---|---|---|---|
| `mu_complete` | ```r\ndata.frame(\n  y01 = c(0L, 0L, 1L, 1L),\n  x = c(-2, -1, 1, 2)\n)\n``` | `bf(y01 ~ x)` | complete; `(Intercept) = 0` (finite), `x = Inf`; ray `d = c(0, 1)` |
| `mu_quasi` | ```r\ndata.frame(\n  y01 = c(0L, 0L, 1L, 1L),\n  x = c(-1, 0, 0, 1)\n)\n``` | `bf(y01 ~ x)` | quasi-complete; `(Intercept) = 0` (finite), `x = Inf`; equality rows are both observations at `x = 0`; ray `d = c(0, 1)` |
| `mu_finite` | ```r\ndata.frame(\n  y01 = c(0L, 1L, 0L, 1L, 0L, 1L),\n  x = c(-1, -1, 0, 0, 1, 1)\n)\n``` | `bf(y01 ~ x)` | no separation; `(Intercept) = 0`, `x = 0` (both finite) |
| `mu_quasi_expanded` | ```r\ndata.frame(\n  y01 = c(0L, 0L, 0L, 1L, 1L, 1L),\n  x = c(-1, -1, 0, 0, 1, 1)\n)\n``` | `bf(y01 ~ x)` | quasi-complete; `(Intercept) = 0`, `x = Inf`; ray `c(0, 1)` |
| `mu_quasi_grouped` | ```r\ndata.frame(\n  success = c(0L, 1L, 2L),\n  failure = c(2L, 1L, 0L),\n  x = c(-1, 0, 1)\n)\n``` | `bf(cbind(success, failure) ~ x)` | quasi-complete; `(Intercept) = 0`, `x = Inf`; same parameter-dependent likelihood geometry as `mu_quasi_expanded` |
| `hu_complete` | ```r\ndata.frame(\n  count = c(0L, 0L, 0L, 2L, 3L, 6L),\n  x = c(-3, -2, -1, 1, 2, 3)\n)\n``` | `bf(count ~ 1, sigma ~ 1, hu ~ x)` | `hu` complete; `hu:(Intercept) = 0`, `hu:x = -Inf`; ray `d_h = c(0, -1)`. `mu` and `sigma`: outside the separation truth. |
| `hu_quasi` | ```r\ndata.frame(\n  count = c(0L, 0L, 0L, 2L, 3L, 6L),\n  x = c(-3, -1, 0, 0, 1, 3)\n)\n``` | `bf(count ~ 1, sigma ~ 1, hu ~ x)` | `hu` quasi-complete; `hu:(Intercept) = 0`, `hu:x = -Inf`; equal-gate rows are `x = 0` with one zero and one positive count. `mu` and `sigma`: outside the separation truth. |
| `rank_deficient_control` | ```r\ndata.frame(\n  y01 = c(0L, 1L, 0L, 1L, 0L, 1L),\n  x = c(-1, -1, 0, 0, 1, 1),\n  twox = c(-2, -2, 0, 0, 2, 2)\n)\n``` | `bf(y01 ~ x + twox)` | rank deficient by construction; no per-coordinate separation or infinity truth is licensed. It is not a separated fixture. |

## Ray grid and numeric gates

Let \(\operatorname{sp}(u)=\log(1+\exp u)\), and evaluate rays without fitting.

\[
t\in\{0,2,4,8,16\}.
\]

For `mu_complete` at \(\beta(t)=t(0,1)\),

\[
L_C(t)=2\operatorname{sp}(-2t)+2\operatorname{sp}(-t).
\]

For `mu_quasi` at \(\beta(t)=t(0,1)\),

\[
L_Q(t)=2\log 2+2\operatorname{sp}(-t).
\]

For `mu_finite` at \(\beta(t)=\pm t(0,1)\),

\[
L_F(t)=2\{\operatorname{sp}(t)+\operatorname{sp}(-t)\}+2\log 2.
\]

| \(t\) | \(L_C(t)\) | \(L_Q(t)\) | \(L_F(t)\) |
|---:|---:|---:|---:|
| 0 | 2.772588722240 | 2.772588722240 | 4.158883083360 |
| 2 | 0.290155877922 | 1.640150383206 | 5.894006405292 |
| 4 | 0.036970668581 | 1.422594216956 | 9.458894072791 |
| 8 | 0.000671037816 | 1.386965173866 | 17.387635986611 |
| 16 | 0.000000225070 | 1.386294586190 | 33.386294811261 |

Required gates:

- Direct deterministic evaluation matches every displayed value within `1e-8`.
- `mu_complete`: strictly decreasing on the grid; `L_C(16) < 2.3e-7`; `L_C(0)-L_C(16) > 2.7725884`.
- `mu_quasi`: strictly decreasing on the grid; `abs(L_Q(16) - log(4)) < 1e-6`; `L_Q(0)-L_Q(16) > 1.3862940`.
- `mu_finite`: for both ray signs, `L_F(2)-L_F(0) > 1.7`; no decreasing separating ray is permitted.
- `hu_complete` and `hu_quasi`: after holding `mu` and `sigma` fixed, the `hu`-block normalized NLL changes must equal the corresponding \(L_C(t)-L_C(0)\) and \(L_Q(t)-L_Q(0)\), respectively, under \(\beta_h(t)=t(0,-1)\).
- Expanded and grouped quasi fixtures must have identical normalized ray curves:
  \[
  [L(t)-L(0)]_{\rm expanded}=[L(t)-L(0)]_{\rm grouped}
  \]
  within `1e-8`. Raw NLLs may differ by the binomial combinatorial constant.

## Hurdle factorization / invariance fixtures

Use the same `x` and zero gate in both frames:

```r
hu_invariance_a <- data.frame(
  count = c(0L, 0L, 0L, 2L, 3L, 6L),
  x = c(-3, -1, 0, 0, 1, 3)
)

hu_invariance_b <- data.frame(
  count = c(0L, 0L, 0L, 1L, 5L, 12L),
  x = c(-3, -1, 0, 0, 1, 3)
)
```

For both:

```r
bf(count ~ 1, sigma ~ 1, hu ~ x)
# family = truncated_nbinom2()
```

Required invariances:

- `g = as.integer(count == 0L)` is exactly `c(1L, 1L, 1L, 0L, 0L, 0L)` for both frames.
- At every fixed `beta_h`, the `hu` log-likelihood block is exactly identical between frames.
- The complete/quasi classification and `hu:x -> -Inf` direction depend only on `g` and `X_h`, not on the magnitudes `2, 3, 6` versus `1, 5, 12`.
- The positive-count NB2 block may differ; it must not be used to revise the `hu` separation truth.

## Exact-row controls

| Control | Exact construction | Required truth |
|---|---|---|
| Zero weight | ```r\nmu_zero_weight <- data.frame(\n  y01 = c(0L, 0L, 1L, 1L, 0L),\n  x = c(-2, -1, 1, 2, 2),\n  w = c(1, 1, 1, 1, 0)\n)\n``` with `bf(y01 ~ x)`, `weights = w` | The final row is contradictory but inactive. Active rows are exactly `mu_complete`; classification remains complete and `x = Inf`. |
| Finite offset | ```r\nmu_finite_offset <- data.frame(\n  y01 = c(0L, 0L, 1L, 1L),\n  x = c(-2, -1, 1, 2),\n  off = c(-0.7, 0.2, 0.4, -0.3)\n)\n``` with `bf(y01 ~ x + offset(off))` | All offsets are finite. Classification remains complete; ray remains `c(0, 1)`; `(Intercept)` remains finite and `x = Inf`. Raw ray values need not equal the zero-offset table. |
| Response mask | ```r\nmu_response_mask <- data.frame(\n  y01 = c(0L, 0L, 1L, 1L, NA_integer_),\n  x = c(-2, -1, 1, 2, 2)\n)\n``` with `bf(y01 ~ x)`, `missing = miss_control(response = \"include\")` | The masked final row is excluded from the response likelihood. Its active rows are exactly `mu_complete`; classification remains complete and `x = Inf`. |
| Hurdle zero weight | ```r\nhu_zero_weight <- data.frame(\n  count = c(0L, 0L, 0L, 2L, 3L, 6L, 0L),\n  x = c(-3, -2, -1, 1, 2, 3, 3),\n  w = c(1, 1, 1, 1, 1, 1, 0)\n)\n``` with `bf(count ~ 1, sigma ~ 1, hu ~ x)`, `weights = w` | The final zero would contradict `hu_complete` but has zero weight. The active `hu` gate remains complete with `hu:x = -Inf`. |
| Hurdle response mask | ```r\nhu_response_mask <- data.frame(\n  count = c(0L, 0L, 0L, 2L, 3L, 6L, NA_integer_),\n  x = c(-3, -2, -1, 1, 2, 3, 3)\n)\n``` with `bf(count ~ 1, sigma ~ 1, hu ~ x)`, `missing = miss_control(response = \"include\")` | The final row is excluded by `observed_y`; the active `hu` gate remains complete with `hu:x = -Inf`. |

## Falsifiers / stop rules

Stop the lane rather than reinterpret results if any of the following occurs:

- A core full-rank fixture is not classified as its stated complete, quasi-complete, or finite case by the maintained detector.
- Any expected direction reverses: binomial `x` must be `Inf`; hurdle `hu:x` must be `-Inf`.
- `mu_quasi` is reported as complete, or `mu_complete` as quasi-complete.
- Any exact ray gate fails, including the complete-to-zero versus quasi-to-\(\log 4\) distinction.
- Grouped and expanded normalized likelihood curves differ by more than `1e-8`, or imply different coefficient-direction truth.
- Altering positive hurdle counts changes the fixed-\(\beta_h\) `hu` block, its LP classification, or its ray direction.
- A zero-weight or response-masked contradictory row changes the active-row LP truth.
- A finite offset changes the asymptotic ray direction.
- The rank-deficient control is called separated merely because its design is singular, or any coordinate-specific `Inf` status is asserted from that control.
- Empirical adjudication is required before claiming package-level behavior for: detector argument adaptation after weights, offsets, or response masks; equality of compiled-objective and symbolic ray values; and preservation of hurdle factorization under an actual joint optimization.