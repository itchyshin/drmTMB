#ifndef DRMTMB_RESPONSE_KERNELS_H
#define DRMTMB_RESPONSE_KERNELS_H

// Pluggable per-family response log-density leaf, used by the missing-predictor
// mi() quadrature so a non-Gaussian response can reuse the same integration
// loop. P2 extracts only the Gaussian case (a pure refactor: the returned value
// is byte-identical to the inline dnorm it replaces); P3 fills the other
// families and wires them into non-Gaussian-response mi() call sites.
//
// Contract:
//   * weights(i) is applied OUTSIDE this leaf at every call site -- do NOT
//     absorb it here, or every caller's semantics change.
//   * eta_val / log_sigma_val carry live AD gradient; never route them through
//     asDouble() (that would silently zero their gradients).
//   * model_type is a plain int (DATA_INTEGER), so this switch is resolved at
//     tape construction -- it is not a CondExp/taping concern.
template<class Type>
Type drm_response_log_density(
    int model_type,
    Type y_val,
    Type eta_val,
    Type log_sigma_val,
    Type V_known_val,
    Type trials_val)
{
  (void) trials_val; // used by the binomial leaf added in P3
  switch (model_type) {
    case 1: {
      // gaussian: identity mean, sd = sqrt(V_known + exp(2*log_sigma)).
      // This exp(2*log_sigma) form is the one used at every mi()-branch call
      // site; it is NOT bit-identical to the vanilla no-mi path's sigma*sigma
      // precompute, which is deliberately left untouched.
      Type sigma_i = sqrt(V_known_val + exp(Type(2.0) * log_sigma_val));
      return dnorm(y_val, eta_val, sigma_i, true);
    }
    case 6: {
      // poisson: log link, mu = exp(eta); no dispersion or trials.
      return dpois(y_val, exp(eta_val), true);
    }
    case 18: {
      // binomial: logit link; trials_val successes-out-of-trials.
      Type log_p1 = -logspace_add(Type(0.0), -eta_val);
      Type log_p0 = -logspace_add(Type(0.0), eta_val);
      Type failures = trials_val - y_val;
      Type log_choose = lgamma(trials_val + Type(1.0)) -
        lgamma(y_val + Type(1.0)) - lgamma(failures + Type(1.0));
      return log_choose + y_val * log_p1 + failures * log_p0;
    }
    case 7: {
      // nbinom2: log link via eta; dispersion size = exp(-2*log_sigma).
      // The kernel takes the raw linear predictor (eta), NOT mu.
      return drm_nbinom2_log_density(y_val, eta_val, log_sigma_val);
    }
    default:
      // Non-Gaussian response leaves are added in P3; unreachable in P2 (only
      // the model_type == 1 mi() block calls this helper).
      return Type(0.0);
  }
}

#endif // DRMTMB_RESPONSE_KERNELS_H
