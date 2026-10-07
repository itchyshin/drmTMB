#ifndef DRM_CJS_KERNEL_HPP
#define DRM_CJS_KERNEL_HPP

// Exact first-capture-conditional two-state forward likelihood. Histories and
// masks are flat individual-major vectors. `first` and `end` are zero-based
// occasion indices at this C++ boundary; R's public object remains 1-based.
template<class Type>
Type cjs_log1p(const Type &z) {
  Type az = CppAD::CondExpGt(z, Type(0), z, -z);
  Type zsafe = CppAD::CondExpLt(az, Type(1e-5), z, Type(0));
  Type z2 = zsafe * zsafe;
  Type series = zsafe - z2 / Type(2) + z2 * zsafe / Type(3) -
                z2 * z2 / Type(4) + z2 * z2 * zsafe / Type(5);
  Type regular = log(Type(1) + z);
  return CppAD::CondExpLt(az, Type(1e-5), series, regular);
}

template<class Type>
Type cjs_softplus(const Type &x) {
  Type ax = CppAD::CondExpGt(x, Type(0), x, -x);
  Type xp = CppAD::CondExpGt(x, Type(0), x, Type(0));
  return xp + cjs_log1p(exp(-ax));
}

template<class Type>
Type cjs_logsoftplus(const Type &x) {
  Type safe_x = CppAD::CondExpGt(x, Type(-35), x, Type(-35));
  Type regular = log(cjs_softplus(safe_x));
  return CppAD::CondExpGt(x, Type(-35), regular, x);
}

template<class Type>
Type cjs_logaddexp(const Type &a, const Type &b) {
  const Type neg_inf = Type(-std::numeric_limits<double>::infinity());
  Type aa = CppAD::CondExpEq(a, neg_inf, Type(0), a);
  Type bb = CppAD::CondExpEq(b, neg_inf, Type(0), b);
  Type m = CppAD::CondExpGt(aa, bb, aa, bb);
  Type d = CppAD::CondExpGt(aa, bb, bb - aa, aa - bb);
  Type regular = m + cjs_log1p(exp(d));
  return CppAD::CondExpEq(a, neg_inf, b,
         CppAD::CondExpEq(b, neg_inf, a, regular));
}

template<class Type>
Type cjs_log_death(const Type &delta, const Type &eta) {
  // If x = delta * log(1 + exp(-eta)), then 1 - phi = 1 - exp(-x).
  // The small-x expansion avoids cancellation and retains a finite log death
  // probability at eta around +1000, where exp(-eta) itself underflows.
  Type x = delta * cjs_softplus(-eta);
  Type xs = CppAD::CondExpGt(x, Type(1e-5), Type(1e-5), x);
  Type correction = cjs_log1p(-xs / Type(2) + xs * xs / Type(6) -
                          xs * xs * xs / Type(24));
  Type small = log(delta) + cjs_logsoftplus(-eta) + correction;
  Type large_x = CppAD::CondExpGt(x, Type(1e-5), x, Type(1e-5));
  Type large = cjs_log1p(-exp(-large_x));
  return CppAD::CondExpGt(x, Type(1e-5), large, small);
}

template<class Type>
Type cjs_nll(const vector<int> &y,
             const vector<int> &observed,
             const vector<int> &first,
             const vector<int> &end,
             const vector<Type> &delta,
             const vector<Type> &eta_phi,
             const vector<Type> &eta_p,
             const vector<int> &frequency,
             int N,
             int T) {
  Type nll = Type(0);
  for (int i = 0; i < N; ++i) {
    Type log_alive = Type(0);
    Type log_dead = Type(0);
    bool dead_possible = false;
    for (int t = first(i) + 1; t <= end(i); ++t) {
      const int sidx = i * (T - 1) + (t - 1);
      const int didx = i * T + t;
      Type log_phi = -delta(sidx) * cjs_softplus(-eta_phi(sidx));
      Type log_death = cjs_log_death(delta(sidx), eta_phi(sidx));
      Type next_alive = log_alive + log_phi;
      Type next_dead = dead_possible
        ? cjs_logaddexp(log_dead, log_alive + log_death)
        : log_alive + log_death;
      dead_possible = true;
      if (observed(didx)) {
        if (y(didx)) {
          next_alive -= cjs_softplus(-eta_p(didx));
          dead_possible = false;
        } else {
          next_alive -= cjs_softplus(eta_p(didx));
          dead_possible = true;
        }
      }
      log_alive = next_alive;
      log_dead = next_dead;
    }
    Type log_likelihood = dead_possible
      ? cjs_logaddexp(log_alive, log_dead)
      : log_alive;
    nll -= Type(frequency(i)) * log_likelihood;
  }
  return nll;
}

#endif
