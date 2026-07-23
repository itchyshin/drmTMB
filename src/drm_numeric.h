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

#endif
