#ifndef DRMTMB_NUMERIC_H
#define DRMTMB_NUMERIC_H

template<class Type>
Type drm_log1p_pos(Type x)
{
  Type series = x - x * x / Type(2.0) + x * x * x / Type(3.0);
  Type direct = log(Type(1.0) + x);
  return CppAD::CondExpLt(x, Type(1e-6), series, direct);
}

template<class Type>
Type drm_log1p_exp_stable(Type eta)
{
  Type eta_for_direct = CppAD::CondExpGt(eta, Type(35.0), Type(0.0), eta);
  Type x = exp(eta_for_direct);
  Type series = x - x * x / Type(2.0) + x * x * x / Type(3.0);
  Type direct = log(Type(1.0) + x);
  Type small = CppAD::CondExpLt(x, Type(1e-6), series, direct);
  Type stable = logspace_add(Type(0.0), eta);
  return CppAD::CondExpGt(eta, Type(35.0), stable, small);
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

#endif
