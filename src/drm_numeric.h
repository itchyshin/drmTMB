#ifndef DRMTMB_NUMERIC_H
#define DRMTMB_NUMERIC_H

// log(1 + exp(eta)), the softplus. logspace_add(0, eta) is the numerically
// stable form across the entire range (TMB implements it via log1p), so the
// former small-x Taylor series / direct-log / eta>35 branching was redundant --
// and less accurate than log1p, differing from this form only at the last bit
// (~1e-16) while carrying larger series-truncation error. See design doc 176.
template<class Type>
Type drm_log1p_exp_stable(Type eta)
{
  return logspace_add(Type(0.0), eta);
}

// Stable log(1 + x) for non-negative x. The direct expression loses x when
// x is tiny; the short alternating series is accurate in that region and
// remains differentiable on the TMB tape.
template<class Type>
Type drm_log1p_nonnegative(Type x)
{
  Type series =
    x - x * x / Type(2.0) + x * x * x / Type(3.0);
  Type direct = log(Type(1.0) + x);
  return CppAD::CondExpLt(x, Type(1e-5), series, direct);
}

template<class Type>
Type drm_log1mexp(Type log_p)
{
  Type u = -log_p;
  Type series_arg = u - u * u / Type(2.0) + u * u * u / Type(6.0);
  Type series = log(series_arg);
  Type direct = log(Type(1.0) - exp(log_p));
  return CppAD::CondExpLt(u, Type(1e-6), series, direct);
}

template<class Type>
Type drm_log_inv_logit(Type eta)
{
  return -logspace_add(Type(0.0), -eta);
}

template<class Type>
Type drm_log1m_inv_logit(Type eta)
{
  return -logspace_add(Type(0.0), eta);
}

template<class Type>
Type drm_log_inv_logit_diff(Type upper, Type lower)
{
  return upper + drm_log1mexp(lower - upper) -
    logspace_add(Type(0.0), upper) -
    logspace_add(Type(0.0), lower);
}

// ---------------------------------------------------------------------------
// Binomial link generalisation (model_type == 18 only: logit/probit/cloglog,
// link_code 0/1/2). See docs/design/252-binomial-link-generalisation.md.
// ---------------------------------------------------------------------------

// Stable log Phi(x), the tail-safe log-scale standard normal CDF. Adapted
// from gllvmTMB's gll_log_pnorm() (src/gllvmTMB.cpp:113-146); see
// inst/COPYRIGHTS for provenance. For x >= -20 this is the direct
// log(pnorm(x)) (pnorm(-20) = 2.8e-89, ~200 orders of headroom before
// underflow). Below that it switches to the Mills-ratio asymptotic expansion
// (Abramowitz & Stegun 26.2.12):
//   log Phi(x) = -x^2/2 - log(-x) - log(sqrt(2 pi))
//                + log(1 - 1/x^2 + 3/x^4 - 15/x^6 + 105/x^8)
// which keeps the result finite past the point where pnorm() itself
// underflows to exactly 0 (x ~ -37.5) and log() would return -Inf.
// The conditional-expression form evaluates BOTH branches, so each branch is
// fed a clamped argument that keeps it finite on the side where it is not
// selected.
template<class Type>
Type drm_log_pnorm(Type x)
{
  Type cut = Type(-20.0);
  Type xa = CppAD::CondExpLt(x, cut, x, cut);            // min(x, -20)
  Type inv2 = Type(1.0) / (xa * xa);
  Type series = Type(1.0) - inv2 * (Type(1.0) - Type(3.0) * inv2 *
                (Type(1.0) - Type(5.0) * inv2 *
                (Type(1.0) - Type(7.0) * inv2)));
  Type tail = -Type(0.5) * xa * xa - log(-xa) -
    Type(0.5) * log(Type(2.0) * M_PI) + log(series);
  Type xd = CppAD::CondExpLt(x, cut, cut, x);            // max(x, -20)
  Type direct = log(pnorm(xd));
  return CppAD::CondExpLt(x, cut, tail, direct);
}

// log(mu) and log(1-mu) for the linear predictor eta, dispatched on
// link_code (0 = logit, 1 = probit, 2 = cloglog). Used at every binomial
// mean/likelihood site. Every branch stays entirely on the log scale -- no
// probability-scale clamp (contrast gllvmTMB's gll_clamp() before dbinom();
// see inst/COPYRIGHTS for why that clamp was deliberately NOT ported).
template<class Type>
struct DrmBinomLogMu {
  Type log_mu;
  Type log_one_minus_mu;
};

template<class Type>
DrmBinomLogMu<Type> drm_binom_log_mu(Type eta, int link_code)
{
  DrmBinomLogMu<Type> out;
  if (link_code == 1) {
    // probit: mu = Phi(eta); 1 - mu = Phi(-eta) by symmetry.
    out.log_mu = drm_log_pnorm(eta);
    out.log_one_minus_mu = drm_log_pnorm(-eta);
  } else if (link_code == 2) {
    // cloglog: mu = 1 - exp(-exp(eta)).
    // log(1 - mu) = -exp(eta) exactly -- no cancellation risk.
    // log(mu) = log(1 - exp(-exp(eta))), via the existing stable
    // drm_log1mexp() primitive (its argument -exp(eta) is always <= 0).
    Type exp_eta = exp(eta);
    out.log_one_minus_mu = -exp_eta;
    out.log_mu = drm_log1mexp(-exp_eta);
  } else {
    // logit (default, link_code == 0): mu = 1 / (1 + exp(-eta)).
    out.log_mu = drm_log_inv_logit(eta);
    out.log_one_minus_mu = drm_log1m_inv_logit(eta);
  }
  return out;
}

// log|dmu/deta| for the linear predictor eta, dispatched on link_code (0 =
// logit, 1 = probit, 2 = cloglog). Used ONLY by the MSPL Jeffreys weight
// n * (dmu/deta)^2 / (mu * (1 - mu)). This is NOT derivable from
// drm_binom_log_mu(): the logit-only collapse log(n) - softplus(eta) -
// softplus(-eta) is specific to the logit working weight, not a form that
// generalises by substituting log_mu / log_one_minus_mu, so it needs its own
// stable primitive per link.
template<class Type>
Type drm_binom_log_mu_eta(Type eta, int link_code)
{
  if (link_code == 1) {
    // probit: mu.eta(eta) = dnorm(eta); log|mu.eta| = dnorm(eta, log = TRUE).
    return dnorm(eta, Type(0.0), Type(1.0), true);
  } else if (link_code == 2) {
    // cloglog: mu.eta(eta) = exp(eta - exp(eta)); log|mu.eta| = eta - exp(eta).
    return eta - exp(eta);
  } else {
    // logit (default, link_code == 0): mu.eta(eta) = exp(eta)/(1+exp(eta))^2;
    // log|mu.eta| = -softplus(eta) - softplus(-eta), using the existing
    // stable softplus primitive drm_log1p_exp_stable().
    return -drm_log1p_exp_stable(eta) - drm_log1p_exp_stable(-eta);
  }
}

// ---------------------------------------------------------------------------
// Cancellation-free gamma-function ratios (#1467).
// ---------------------------------------------------------------------------

// log(1 + x) for x >= 0, accurate to a few ulps over the whole range. The
// plain log(1 + x) keeps only about eps / x relative accuracy (2e-12 at
// x = 1e-4), which is not good enough inside drm_lgamma_ratio() below. For
// x < 1e-4 a five-term series is used (relative truncation error below
// 2e-21). Above that the Goldberg correction log(u) * x / (u - 1), u = 1 + x,
// cancels the rounding of u (Goldberg 1991, "What every computer scientist
// should know about floating-point arithmetic", Theorem 4). The conditional
// records both branches, so each branch sees x clamped into the region where
// it is finite (u - 1 is never 0 on the Goldberg branch).
template<class Type>
Type drm_log1p_accurate(Type x)
{
  Type cut = Type(1e-4);
  Type xs = CppAD::CondExpLt(x, cut, x, cut);
  Type series = xs * (Type(1.0) - xs * (Type(0.5) - xs * (Type(1.0) / Type(3.0) -
    xs * (Type(0.25) - xs / Type(5.0)))));
  Type xd = CppAD::CondExpLt(x, cut, cut, x);
  Type u = Type(1.0) + xd;
  Type direct = log(u) * xd / (u - Type(1.0));
  return CppAD::CondExpLt(x, cut, series, direct);
}

// lgamma(x + m) - lgamma(x) for x > 0 and data m >= 0 (an integer count in
// every current caller). The direct difference subtracts two values of size
// about x log(x) to recover a value of size about m log(x), so once x is
// large it loses about eps * x log(x) absolutely: 3e-3 per call at x = 1e13,
// which is where beta_binomial's phi sits as sigma -> 0. For x >= 100 the
// Stirling series is differenced analytically instead:
//   lgamma(x + m) - lgamma(x)
//     = (x - 1/2) log1p(m / x) + m log(x + m) - m + S(x + m) - S(x),
//   S(z) = 1/(12 z) - 1/(360 z^3) + 1/(1260 z^5),
// whose truncation error is below 1/(1680 x^7) = 6e-18 at the switch, and
// whose terms are all of size m log(x) or smaller. m = 0 returns exactly 0 on
// both branches. The direct branch is kept below the switch, where it is
// accurate to about 1e-13, and is finite (unclamped) on the far side; the
// Stirling branch sees x clamped to the switch so S() stays bounded.
template<class Type>
Type drm_lgamma_ratio(Type x, Type m)
{
  Type cut = Type(100.0);
  Type direct = lgamma(x + m) - lgamma(x);
  Type xs = CppAD::CondExpLt(x, cut, cut, x);
  Type z = xs + m;
  Type iz = Type(1.0) / z;
  Type ix = Type(1.0) / xs;
  Type iz2 = iz * iz;
  Type ix2 = ix * ix;
  Type s_z = iz * (Type(1.0) / Type(12.0) - iz2 * (Type(1.0) / Type(360.0) -
    iz2 / Type(1260.0)));
  Type s_x = ix * (Type(1.0) / Type(12.0) - ix2 * (Type(1.0) / Type(360.0) -
    ix2 / Type(1260.0)));
  Type stirling = (xs - Type(0.5)) * drm_log1p_accurate(m * ix) +
    m * log(z) - m + (s_z - s_x);
  return CppAD::CondExpLt(x, cut, direct, stirling);
}

// Beta-binomial log-probability of y successes in `trials`, with shapes alpha
// and beta_shape (already floored by the caller). Written as three
// drm_lgamma_ratio() terms, which is the same expression as
//   lchoose(trials, y) + lbeta(y + alpha, trials - y + beta_shape)
//     - lbeta(alpha, beta_shape)
// but tends smoothly to the binomial log-probability as alpha + beta_shape
// grows, instead of carrying eps * phi log(phi) rounding noise (#1467).
template<class Type>
Type drm_beta_binomial_log_density(Type y, Type trials, Type alpha,
                                   Type beta_shape)
{
  Type failures = trials - y;
  Type log_choose = lgamma(trials + Type(1.0)) -
    lgamma(y + Type(1.0)) -
    lgamma(failures + Type(1.0));
  return log_choose +
    drm_lgamma_ratio(alpha, y) +
    drm_lgamma_ratio(beta_shape, failures) -
    drm_lgamma_ratio(alpha + beta_shape, trials);
}

#endif
