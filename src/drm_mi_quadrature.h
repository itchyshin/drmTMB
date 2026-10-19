#ifndef DRM_MI_QUADRATURE_H
#define DRM_MI_QUADRATURE_H

// Posterior-centred Gauss-Hermite rules for continuous mi() predictor priors
// (#1476 Beta / zero-one-Beta, #1477 Gamma).
//
// A row with a missing predictor x and an observed Gaussian response
// contributes the marginal
//
//   m_i = integral p(x) N(y_i; mu_i + beta * (x - x0_i), sd_i) dx,
//
// where p(x) is the mi() prior. The previous fixed rules (15-node
// Gauss-Legendre on (0, 1) for Beta, 20-node Gauss-Laguerre for Gamma) did
// not adapt to the prior: their prior mass sum(w_q p(x_q)) drifted from 1 by
// up to a factor of two (Beta) or collapsed to ~0 for Gamma shapes above ~40.
//
// Here the integral is taken on a transformed scale z (logit x for Beta,
// log x for Gamma) with Gauss-Hermite nodes centred at the mode of the row's
// posterior p(x | y_i) and scaled by its curvature:
//
//   z_q = z_hat + sqrt(2) * s * h_q,
//   log_terms(q) = log(w_q) + log(sqrt(pi)) + h_q^2 + log(sqrt(2) * s)
//                  + log p_z(z_q) + log N(y_i | x(z_q)),
//
// where (h_q, w_q) is a Gauss-Hermite rule whose weights sum to one. This is
// an exact change of variables, so any (z_hat, s) gives a consistent rule;
// the mode and curvature only control accuracy. The Gamma mode solves a
// quadratic in closed form; the Beta mode is bracketed by bisection on the
// score (always inside the bracket below) and polished with two Newton
// steps so that its derivative is carried by AD.
//
// Every operation is elementary and AD-safe at all orders; CondExp branches
// keep both arguments finite so no 0 * Inf reaches the reverse sweep.
// Accuracy (docs/design/149-missing-data-design.md, "Continuous mi() prior
// quadrature and case weights"; tests in
// test-missing-predictor-weights.R), with the 40-node rule passed from R:
// Gamma within ~1e-10 nats for shape >= 0.5 and ~1e-6 down to shape 0.1;
// Beta within ~2e-6 when both shapes are >= 2, ~5e-4 when both are >= 1 and
// ~3e-3 when both are >= 0.5.
// J- or U-shaped Beta priors (a shape well below 1) have a heavy logit-scale
// tail and are integrated less accurately (90th-percentile error 0.16 nats
// on the design-doc grid), though more accurately than the old fixed rule in
// all but 2 of 195 grid cells.

template<class Type>
Type drm_mi_log_inv_logit(Type z)
{
  return -logspace_add(Type(0.0), -z);
}

// log of integral Beta(x; a, b) N(r0 - bx * x; 0, sd_y) dx, with
// r0 = y - mu_i + bx * x0_i. Fills x_q and the per-node log integrand
// log_terms (prior importance weight plus response log density).
template<class Type>
Type drm_mi_beta_marginal(
    Type a,
    Type b,
    Type r0,
    Type bx,
    Type sd_y,
    const vector<Type>& gh_nodes,
    const vector<Type>& gh_weights,
    vector<Type>& x_q,
    vector<Type>& log_terms)
{
  Type lam = Type(1.0) / (sd_y * sd_y);
  Type lbeta_ab = lgamma(a) + lgamma(b) - lgamma(a + b);
  // Bracket for the posterior mode on z = logit(x): the score
  // d(z) = a - (a + b) x + lam * bx * (r0 - bx * x) * x * (1 - x)
  // is positive at z_lo and negative at z_hi whenever
  // c_bound >= 1 + a + b + lam * |bx| * (|r0| + |bx|); the bound below uses
  // |bx| |r0| <= (bx^2 + r0^2) / 2 to avoid abs()/sqrt() at bx = 0.
  Type c_bound = Type(1.0) + a + b +
    lam * (Type(1.5) * bx * bx + Type(0.5) * r0 * r0);
  Type z_lo = log(a) - log(c_bound) - Type(1.0);
  Type z_hi = log(c_bound) - log(b) + Type(1.0);
  for (int k = 0; k < 64; ++k) {
    Type z_mid = Type(0.5) * (z_lo + z_hi);
    Type x_mid = exp(drm_mi_log_inv_logit(z_mid));
    Type q_mid = x_mid * (Type(1.0) - x_mid);
    Type score = a - (a + b) * x_mid +
      lam * bx * (r0 - bx * x_mid) * q_mid;
    z_lo = CppAD::CondExpGt(score, Type(0.0), z_mid, z_lo);
    z_hi = CppAD::CondExpGt(score, Type(0.0), z_hi, z_mid);
  }
  Type z_hat = Type(0.5) * (z_lo + z_hi);
  Type curv = Type(1.0);
  for (int k = 0; k < 3; ++k) {
    Type x_k = exp(drm_mi_log_inv_logit(z_hat));
    Type q_k = x_k * (Type(1.0) - x_k);
    Type r_k = r0 - bx * x_k;
    Type score = a - (a + b) * x_k + lam * bx * r_k * q_k;
    curv = (a + b) * q_k +
      lam * bx * (bx * q_k * q_k - r_k * q_k * (Type(1.0) - Type(2.0) * x_k));
    curv = CppAD::CondExpGt(curv, Type(1e-300), curv, Type(1e-300));
    if (k < 2) {
      z_hat = z_hat + score / curv;
    }
  }
  Type scale = Type(1.0) / sqrt(curv);
  Type log_scale = log(sqrt(Type(2.0)) * scale) + Type(0.5) * log(Type(M_PI));
  for (int q = 0; q < gh_nodes.size(); ++q) {
    Type h = gh_nodes(q);
    Type z_q = z_hat + sqrt(Type(2.0)) * scale * h;
    Type log_x = drm_mi_log_inv_logit(z_q);
    Type log_1mx = drm_mi_log_inv_logit(-z_q);
    x_q(q) = exp(log_x);
    Type log_prior = a * log_x + b * log_1mx - lbeta_ab;
    log_terms(q) = log(gh_weights(q)) + h * h + log_scale + log_prior +
      dnorm(r0 - bx * x_q(q), Type(0.0), sd_y, true);
  }
  Type log_denom = log_terms(0);
  for (int q = 1; q < gh_nodes.size(); ++q) {
    log_denom = logspace_add(log_denom, log_terms(q));
  }
  return log_denom;
}

// log of integral Gamma(x; shape k, scale theta) N(r0 - bx * x; 0, sd_y) dx.
// On z = log x the posterior score is k - x / theta + lam * bx * (r0 - bx x) x,
// whose root is the positive root of lam bx^2 x^2 + (1/theta - lam bx r0) x - k,
// and the curvature there is exactly k + lam bx^2 x^2.
template<class Type>
Type drm_mi_gamma_marginal(
    Type k,
    Type theta,
    Type r0,
    Type bx,
    Type sd_y,
    const vector<Type>& gh_nodes,
    const vector<Type>& gh_weights,
    vector<Type>& x_q,
    vector<Type>& log_terms)
{
  Type lam = Type(1.0) / (sd_y * sd_y);
  Type A = lam * bx * bx;
  Type B = Type(1.0) / theta - lam * bx * r0;
  Type D = sqrt(B * B + Type(4.0) * A * k);
  // Cancellation-free root: 2k / (B + D) when B >= 0, otherwise
  // (D - B) / (2A) written as 2k / (4Ak / (D - B)). The inner CondExp keeps
  // the unselected branch finite when A = 0 (then B > 0 is always selected).
  Type d_minus_b = D - B;
  Type d_minus_b_safe =
    CppAD::CondExpGt(d_minus_b, Type(0.0), d_minus_b, Type(1.0));
  Type denom = CppAD::CondExpGe(
    B, Type(0.0), B + D, Type(4.0) * A * k / d_minus_b_safe);
  Type x_hat = Type(2.0) * k / denom;
  Type curv = k + A * x_hat * x_hat;
  Type scale = Type(1.0) / sqrt(curv);
  Type z_hat = log(x_hat);
  Type log_scale = log(sqrt(Type(2.0)) * scale) + Type(0.5) * log(Type(M_PI));
  Type log_norm = lgamma(k) + k * log(theta);
  for (int q = 0; q < gh_nodes.size(); ++q) {
    Type h = gh_nodes(q);
    Type z_q = z_hat + sqrt(Type(2.0)) * scale * h;
    x_q(q) = exp(z_q);
    Type log_prior = k * z_q - x_q(q) / theta - log_norm;
    log_terms(q) = log(gh_weights(q)) + h * h + log_scale + log_prior +
      dnorm(r0 - bx * x_q(q), Type(0.0), sd_y, true);
  }
  Type log_denom = log_terms(0);
  for (int q = 1; q < gh_nodes.size(); ++q) {
    log_denom = logspace_add(log_denom, log_terms(q));
  }
  return log_denom;
}

#endif
