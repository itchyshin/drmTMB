# Two random-intercept SD prior oracle fixtures

These numerical fixtures were independently generated using dense Gaussian
covariance calculations before the package implementations were evaluated.
The frozen files contain simulated inputs, objective values, derivatives and
fit references. They do not contain source copied from another package.

- `frozen.json`: SHA-256 `d2bfbbac2d5e0127c90ef877c01259fda56526b2797240ddf718e0f782f6e1e2`
- `asymmetric-frozen.json`: SHA-256 `91de5613071175a8789a349243230a2023ae6aadd70bb35f9d6acc48938a0b85`

The fixture stores generation details, parameter order, and finite-difference
step sizes. A near-boundary unpenalized SD may have a poorly conditioned Hessian;
compare the objective and score instead of demanding parameter equality there.
