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
Type cjs_logsumexp(const vector<Type> &x) {
  Type total = Type(-std::numeric_limits<double>::infinity());
  for (int j = 0; j < x.size(); ++j) total = cjs_logaddexp(total, x(j));
  return total;
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
Type cjs_history_loglik(const vector<int> &y,
                        const vector<int> &observed,
                        const vector<int> &first,
                        const vector<int> &end,
                        const vector<Type> &delta,
                        const vector<Type> &eta_phi,
                        const vector<Type> &eta_p,
                        int i,
                        int T,
                        Type b_phi = Type(0),
                        Type b_p = Type(0),
                        int terminal_phi = 0,
                        int terminal_p = 0) {
  Type log_alive = Type(0);
  Type log_dead = Type(0);
  bool dead_possible = false;
  for (int t = first(i) + 1; t <= end(i); ++t) {
    const int sidx = i * (T - 1) + (t - 1);
    const int didx = i * T + t;
    Type eta_s = eta_phi(sidx) +
      ((terminal_phi && t == T - 1) ? Type(0) : b_phi);
    Type log_phi = -delta(sidx) * cjs_softplus(-eta_s);
    Type log_death = cjs_log_death(delta(sidx), eta_s);
    Type next_alive = log_alive + log_phi;
    Type next_dead = dead_possible
      ? cjs_logaddexp(log_dead, log_alive + log_death)
      : log_alive + log_death;
    dead_possible = true;
    if (observed(didx)) {
      Type eta_d = eta_p(didx) +
        ((terminal_p && t == T - 1) ? Type(0) : b_p);
      if (y(didx)) {
        next_alive -= cjs_softplus(-eta_d);
        dead_possible = false;
      } else {
        next_alive -= cjs_softplus(eta_d);
        dead_possible = true;
      }
    }
    log_alive = next_alive;
    log_dead = next_dead;
  }
  return dead_possible ? cjs_logaddexp(log_alive, log_dead) : log_alive;
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
  for (int i = 0; i < N; ++i)
    nll -= Type(frequency(i)) * cjs_history_loglik(
      y, observed, first, end, delta, eta_phi, eta_p, i, T);
  return nll;
}

// Marginal likelihood for persistent individual intercepts. The same latent
// value is added at every survival interval and detection occasion in a given
// animal's complete history. Gauss-Hermite nodes and normalized weights are
// data, fixed for the entire optimizer run at one rule order.
template<class Type>
Type cjs_individual_nll(const vector<int> &y,
                        const vector<int> &observed,
                        const vector<int> &first,
                        const vector<int> &end,
                        const vector<Type> &delta,
                        const vector<Type> &eta_phi,
                        const vector<Type> &eta_p,
                        const vector<int> &frequency,
                        const vector<Type> &nodes,
                        const vector<Type> &weights,
                        const vector<Type> &log_sd_phi,
                        const vector<Type> &log_sd_p,
                        const vector<int> &eligibility,
                        int selection,
                        int has_phi,
                        int has_p,
                        int terminal_phi,
                        int terminal_p,
                        int N,
                        int T,
                        vector<Type> &history_loglik,
                        vector<Type> &history_log_num,
                        vector<Type> &history_log_den) {
  Type nll = Type(0);
  const int Q = nodes.size();
  for (int i = 0; i < N; ++i) {
    const int Qphi = has_phi ? Q : 1;
    const int Qp = has_p ? Q : 1;
    bool informative = false;
    for (int t = first(i) + 1; t <= end(i); ++t)
      if (observed(i * T + t)) informative = true;
    if (!informative && !selection) {
      history_loglik(i) = Type(0);
      history_log_num(i) = Type(0);
      history_log_den(i) = Type(0);
      continue;
    }
    Type sigma_phi = has_phi ? exp(log_sd_phi(i)) : Type(0);
    Type sigma_p = has_p ? exp(log_sd_p(i)) : Type(0);
    vector<Type> phi_prefix(Qphi);
    vector<Type> p_prefix(Qp);
    Type log_den_phi = Type(-std::numeric_limits<double>::infinity());
    Type log_den_p = Type(-std::numeric_limits<double>::infinity());
    for (int a = 0; a < Qphi; ++a) {
      Type b_phi = has_phi ? sigma_phi * nodes(a) : Type(0);
      Type logw_phi = has_phi ? log(weights(a)) : Type(0);
      Type select_phi = Type(0);
      if (selection) {
        for (int t = eligibility(i); t < first(i); ++t) {
          int idx = i * (T - 1) + t;
          Type eta = eta_phi(idx) +
            ((terminal_phi && t == T - 2) ? Type(0) : b_phi);
          select_phi -= delta(idx) * cjs_softplus(-eta);
        }
      }
      phi_prefix(a) = logw_phi + select_phi;
      if (selection)
        log_den_phi = cjs_logaddexp(log_den_phi, phi_prefix(a));
    }
    for (int b = 0; b < Qp; ++b) {
      Type b_p = has_p ? sigma_p * nodes(b) : Type(0);
      Type logw_p = has_p ? log(weights(b)) : Type(0);
      Type select_p = Type(0);
      if (selection) {
        for (int t = eligibility(i); t <= first(i); ++t) {
          int idx = i * T + t;
          if (observed(idx)) {
            Type eta = eta_p(idx) +
              ((terminal_p && t == T - 1) ? Type(0) : b_p);
            select_p += y(idx) ? -cjs_softplus(-eta) : -cjs_softplus(eta);
          }
        }
      }
      p_prefix(b) = logw_p + select_p;
      if (selection)
        log_den_p = cjs_logaddexp(log_den_p, p_prefix(b));
    }

    const Type log_den = selection ? log_den_phi + log_den_p : Type(0);
    if (selection && !std::isfinite(asDouble(log_den)))
      Rf_error("CJS selection normalization probability is zero or non-finite for history %d",
               i + 1);
    if (!informative && selection) {
      // The empty observed suffix has likelihood one at every latent node.
      // Copying the same denominator preserves exact numerator/denominator
      // equality for final-first and otherwise uninformative histories.
      history_log_num(i) = log_den;
      history_log_den(i) = log_den;
      history_loglik(i) = Type(0);
      continue;
    }

    int last_capture = first(i);
    for (int t = first(i) + 1; t <= end(i); ++t) {
      int didx = i * T + t;
      if (observed(didx) && y(didx)) last_capture = t;
    }

    Type log_num = Type(-std::numeric_limits<double>::infinity());
    for (int t = first(i) + 1; t <= end(i); ++t) {
      const int sidx = i * (T - 1) + (t - 1);
      const int didx = i * T + t;

      // Death occurs on the interval ending at t. The animal is alive only
      // through t-1, so this term contains no detection emission at t.
      if (t > last_capture) {
        vector<Type> phi_death(Qphi);
        for (int a = 0; a < Qphi; ++a) {
          Type b_phi = has_phi ? sigma_phi * nodes(a) : Type(0);
          Type eta = eta_phi(sidx) +
            ((terminal_phi && t == T - 1) ? Type(0) : b_phi);
          phi_death(a) = phi_prefix(a) + cjs_log_death(delta(sidx), eta);
        }
        log_num = cjs_logaddexp(log_num,
          cjs_logsumexp(phi_death) + cjs_logsumexp(p_prefix));
      }

      // Advance the alive prefixes through occasion t for the next possible
      // death time. Missing surveys contribute no detection emission.
      for (int a = 0; a < Qphi; ++a) {
        Type b_phi = has_phi ? sigma_phi * nodes(a) : Type(0);
        Type eta = eta_phi(sidx) +
          ((terminal_phi && t == T - 1) ? Type(0) : b_phi);
        phi_prefix(a) -= delta(sidx) * cjs_softplus(-eta);
      }
      if (observed(didx)) {
        for (int b = 0; b < Qp; ++b) {
          Type b_p = has_p ? sigma_p * nodes(b) : Type(0);
          Type eta = eta_p(didx) +
            ((terminal_p && t == T - 1) ? Type(0) : b_p);
          p_prefix(b) += y(didx) ? -cjs_softplus(-eta) : -cjs_softplus(eta);
        }
      }
    }

    // The final term is survival through each individual's own administrative
    // endpoint, with detections included through that endpoint.
    log_num = cjs_logaddexp(log_num,
      cjs_logsumexp(phi_prefix) + cjs_logsumexp(p_prefix));
    const Type log_likelihood = selection ? log_num - log_den : log_num;
    history_log_num(i) = log_num;
    history_log_den(i) = selection ? log_den : Type(0);
    history_loglik(i) = log_likelihood;
    nll -= Type(frequency(i)) * log_likelihood;
  }
  return nll;
}

// Conditional CJS negative log likelihood plus a normalized standard-normal
// prior for the shared latent intercepts. TMB's Laplace correction removes
// the prior's Gaussian normalization constant; retaining it here makes the
// integrated target exactly the joint history product under N(0, I).
template<class Type>
Type cjs_shared_nll(const vector<int> &y,
                    const vector<int> &observed,
                    const vector<int> &first,
                    const vector<int> &end,
                    const vector<Type> &delta,
                    const vector<Type> &eta_phi,
                    const vector<Type> &eta_p,
                    const vector<int> &frequency,
                    const vector<Type> &u_phi,
                    const vector<Type> &u_p,
                    int N,
                    int T) {
  Type nll = cjs_nll(y, observed, first, end, delta, eta_phi, eta_p,
                     frequency, N, T);
  const Type log_two_pi = log(Type(6.2831853071795864769));
  for (int j = 0; j < u_phi.size(); ++j)
    nll += Type(0.5) * u_phi(j) * u_phi(j) + Type(0.5) * log_two_pi;
  for (int j = 0; j < u_p.size(); ++j)
    nll += Type(0.5) * u_p(j) * u_p(j) + Type(0.5) * log_two_pi;
  return nll;
}

#endif
