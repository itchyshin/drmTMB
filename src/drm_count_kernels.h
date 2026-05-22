#ifndef DRMTMB_COUNT_KERNELS_H
#define DRMTMB_COUNT_KERNELS_H

#include "drm_numeric.h"

template<class Type>
Type drm_nbinom2_log_count_product(Type y, Type alpha)
{
  Type y_minus_one = y - Type(1.0);
  Type sum_j = y * y_minus_one / Type(2.0);
  Type sum_j2 = y * y_minus_one * (Type(2.0) * y - Type(1.0)) / Type(6.0);
  Type sum_j3 = sum_j * sum_j;
  Type sum_j4 = y * y_minus_one * (Type(2.0) * y - Type(1.0)) *
    (Type(3.0) * y * y - Type(3.0) * y - Type(1.0)) / Type(30.0);
  Type sum_j5 = y * y * y_minus_one * y_minus_one *
    (Type(2.0) * y * y - Type(2.0) * y - Type(1.0)) / Type(12.0);
  Type alpha2 = alpha * alpha;
  Type series =
    alpha * sum_j -
    alpha2 * sum_j2 / Type(2.0) +
    alpha2 * alpha * sum_j3 / Type(3.0) -
    alpha2 * alpha2 * sum_j4 / Type(4.0) +
    alpha2 * alpha2 * alpha * sum_j5 / Type(5.0);
  Type inv_alpha = Type(1.0) / alpha;
  Type lgamma_ratio = lgamma(y + inv_alpha) - lgamma(inv_alpha) +
    y * log(alpha);
  return CppAD::CondExpLt(alpha * y, Type(1e-2), series, lgamma_ratio);
}

template<class Type>
Type drm_nbinom2_log_density(Type y, Type eta_mu, Type log_sigma)
{
  Type alpha = exp(Type(2.0) * log_sigma) + Type(1e-300);
  Type log1p_alpha_mu = drm_log1p_exp_stable(log(alpha) + eta_mu);
  return
    y * eta_mu -
    lgamma(y + Type(1.0)) -
    y * log1p_alpha_mu -
    log1p_alpha_mu / alpha +
    drm_nbinom2_log_count_product(y, alpha);
}

template<class Type>
Type drm_nbinom2_log_p0(Type eta_mu, Type log_sigma)
{
  Type alpha = exp(Type(2.0) * log_sigma) + Type(1e-300);
  Type log1p_alpha_mu = drm_log1p_exp_stable(log(alpha) + eta_mu);
  return -log1p_alpha_mu / alpha;
}

#endif
