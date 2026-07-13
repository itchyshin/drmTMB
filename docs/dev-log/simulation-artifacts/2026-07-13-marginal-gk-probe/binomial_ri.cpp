#include <TMB.hpp>

template<class Type>
Type objective_function<Type>::operator() () {
  DATA_VECTOR(y);
  DATA_VECTOR(x);
  DATA_IVECTOR(group);
  DATA_INTEGER(n_group);

  PARAMETER_VECTOR(beta);
  PARAMETER(log_sd);
  PARAMETER_VECTOR(u);

  Type sd = exp(log_sd);
  Type nll = 0;

  for (int g = 0; g < n_group; ++g) {
    nll -= dnorm(u(g), Type(0), sd, true);
  }
  for (int i = 0; i < y.size(); ++i) {
    Type eta = beta(0) + beta(1) * x(i) + u(group(i));
    nll -= dbinom(y(i), Type(1), invlogit(eta), true);
  }

  REPORT(sd);
  ADREPORT(sd);
  return nll;
}
