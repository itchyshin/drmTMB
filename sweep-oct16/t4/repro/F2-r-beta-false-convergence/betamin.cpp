// Minimal TMB model: the textbook Beta log-likelihood (no drmTMB code), used by f2_mechanism.R
// to show that CppAD tape optimisation amplifies the lgamma-difference rounding at large phi.
#include <TMB.hpp>
template<class Type>
Type objective_function<Type>::operator() () {
  DATA_VECTOR(y); DATA_MATRIX(X);
  PARAMETER_VECTOR(b); PARAMETER(ls);
  vector<Type> eta = X * b;
  Type phi = exp(Type(-2.0) * ls);
  Type nll = 0;
  for (int i = 0; i < y.size(); ++i) {
    Type mu = Type(1e-12) + (Type(1.0) - Type(2e-12)) / (Type(1.0) + exp(-eta(i)));
    nll -= dbeta(y(i), mu * phi, (Type(1.0) - mu) * phi, true);   // TMB's own dbeta()
  }
  REPORT(nll);
  return nll;
}
