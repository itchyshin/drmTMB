# Design 256 — MSPL boundary penalty: the scale-equivariant, group-rate derivation (S1)

**Status: DESIGN DERIVATION. No code exists for anything in this document, no capability is
claimed, and nothing here is evidence about coverage, bias, or any other operating characteristic.
Every performance statement below is labelled a *prediction* and exists to be falsified by S3.**

**Reader: Noether's independent re-checker, and Fisher.** This is slice S1 of the MSPL boundary
programme scoped in
[`docs/dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md`](../dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md) §6.
Its job is to derive, before any implementation, a boundary penalty for random-effect standard
deviations that repairs the three defects the transfer packet found in the shipped mechanism, and
to state the conditions under which the repair is valid. It follows the project's
symbolic-alignment discipline: the mathematics is written first, term by term, and the
implementation contract is a consequence of it rather than a description of it.

The document is organised so that the two decisive results come early. §3 proves a classification
theorem that reduces the space of admissible penalties to a single family — this is what chooses
the penalty form, rather than a preference. §5 computes the Fisher information the softness
constant must be measured against, and finds it bounded above by `2g` uniformly in every other
design quantity — this is what chooses the rate.

---

## 1. What must be repaired

The transfer packet records three defects in the penalty shipped today
(`src/drmTMB.cpp:77-85`, `:5018-5046`; `R/mspl.R:112-128`; design 250 §"Stable q1/q2 covariance and
Huber coordinates"). Restated as mathematical requirements on the replacement:

**R1 — scale equivariance.** The shipped variance penalty is $D(\log \mathrm{sd})$, which is
anchored at $\mathrm{sd}=1$ in the user's response units, and whose quadratic/linear breakpoint
sits at $\mathrm{sd}\in[e^{-1},e]$ in those same units. Fisher measured the consequence: fitting
$y$ and $100\,y$ and back-scaling disagreed by up to $0.374$ in the SD, and the sign of the bias
change flipped across $\mathrm{sd}=1$
([Fisher §0](../dev-log/research/2026-08-16-mspl-transfer-fisher-verdict.md)). The replacement must
satisfy exact — not approximate — equivariance for the Gaussian location model.

**R2 — the softness rate must be measured against the right information.** The shipped constant is
$c_n = 2\sqrt{p/n_{\mathrm{eff}}}$ (`R/mspl.R:112-128`), calibrated to fixed-effect information,
which accumulates at rate $n$. Noether §4 named the risk; §5 below turns it into a proof:
variance-component information for a random-effect log-SD does not accumulate at rate $n$ at all.

**R3 — the guarded boundaries must be stated.** `blme`'s log-gamma penalty guards
$\mathrm{sd}\to0$ and not $\mathrm{sd}\to\infty$; Sterzinger & Kosmidis measured variance-component
estimates exceeding $800$ in absolute value under separation with that penalty in force
([Ranga §4](../dev-log/research/2026-08-16-mspl-transfer-ranga-literature.md)). A replacement must
say which boundaries it guards, and pay for whichever it does not.

To these the literature adds a fourth, which the rate condition discharges rather than the form:

**R4 — downstream model selection must survive.** In the factor-analysis paper's own simulations,
*non-decaying* versions of the classical penalties made AIC/BIC "completely fail" to select the
correct model; the $o_p(\sqrt n)$ decay is what restores correct behaviour (Ranga §5, quoting
Sterzinger, Kosmidis & Moustaki 2026). Penalty *rate*, not only penalty *shape*, is load-bearing.

---

## 2. Setup, notation, and the group that acts

### 2.1 The A1 cell

The derivation is carried out on the cell S2 would implement and S3 would measure: the balanced
Gaussian one-way random-intercept model, D-117's A1 design.

$$
y_{ij} \;=\; x_{ij}^{\top}\beta \;+\; u_j \;+\; \varepsilon_{ij},
\qquad j = 1,\dots,g,\quad i = 1,\dots,m,
$$

with $u_j \stackrel{\text{iid}}{\sim} N(0,\sigma_u^2)$ independent of
$\varepsilon_{ij}\stackrel{\text{iid}}{\sim} N(0,\sigma^2)$, and $n = gm$. Here $g$ is the number
of grouping-factor levels and $m = n_{\mathrm{per}}$ the common cluster size. The marginal
distribution of the $j$-th cluster is $y_j \sim N(X_j\beta, V)$ with

$$
V \;=\; \sigma^2 I_m + \sigma_u^2 J_m,
\qquad J_m = \mathbf{1}_m\mathbf{1}_m^{\top},
$$

whose eigenvalues are $\lambda_1 = \sigma^2 + m\sigma_u^2$ (multiplicity $1$, eigenvector
$\mathbf 1_m/\sqrt m$) and $\lambda_0 = \sigma^2$ (multiplicity $m-1$).

### 2.2 Coordinates

drmTMB optimises on the log scale. Write

$$
a \;=\; \log\sigma_u, \qquad
\ell \;=\; \log\sigma, \qquad
r \;=\; a - \ell \;=\; \log\!\left(\frac{\sigma_u}{\sigma}\right).
$$

The lower boundary $\sigma_u \to 0^{+}$ is $a\to-\infty$; the upper divergence
$\sigma_u\to\infty$ is $a\to+\infty$. On the compactified line $\overline{\mathbb R}$ both ends are
boundary. $r$ is the log signal-to-noise ratio of the random effect.

Throughout, $q_v$ denotes the number of penalised variance-component coordinates in the block
($q_v = 1$ for a q1 intercept block; $q_v = 3$ for a q2 block, following the shipped
$(\log L_{11},\log L_{22}, L_{21})$ coordinates of design 250).

### 2.3 The scale group

Let $c>0$ and consider the response rescaling $y \mapsto cy$ with the design $X$ and $Z$ held
fixed. The Gaussian log-likelihood obeys, exactly,

$$
\ell_L^{(cy)}(c\beta,\; a+\log c,\; \ell+\log c) \;=\; \ell_L^{(y)}(\beta, a, \ell) \;-\; n\log c .
\tag{2.1}
$$

The additive term $-n\log c$ does not depend on the parameters, so the maximiser transforms exactly:
$\hat\beta \mapsto c\hat\beta$, $\hat\sigma_u\mapsto c\hat\sigma_u$, $\hat\sigma\mapsto c\hat\sigma$.
**The MLE is exactly equivariant; equivariance can only be lost by the penalty.**

On the parameter side the group acts by simultaneous translation,

$$
G_t : (a,\ell)\;\longmapsto\;(a+t,\;\ell+t),\qquad t=\log c \in \mathbb R ,
\tag{2.2}
$$

with orbit direction $(1,1)^{\top}$ and invariant coordinate $r$.

**Definition (equivariance of a penalised estimator).** Let the maximised criterion be
$\ell_L + P^\ast$. The penalised estimator is exactly equivariant iff, for every $t$,
$P^\ast(G_t\theta) = P^\ast(\theta) + k(t)$ for some function $k$ not depending on $\theta$ —
i.e. the penalty changes only by a parameter-free constant along every orbit. Any such $P^\ast$
leaves (2.1)'s argmax structure intact.

---

## 3. The classification theorem — what forces the penalty form

This section does the work the brief asked for: it presents the decisive comparison between the
three candidate repairs and shows that the choice is forced, not preferred.

### 3.1 The three candidates, stated as penalties

- **(i) Residual-scale anchor.** $P^\ast = c\,Q(a-\ell)$: penalise the log signal-to-noise ratio.
  The anchor is a *model parameter* and therefore moves during optimisation.
- **(ii) Internal standardisation.** Standardise the response by a data statistic
  $\hat s_y$ with $\hat s_y \mapsto c\,\hat s_y$ (for example the marginal SD of $y$, or the
  residual SD of a fixed-effect-only pre-fit), penalise on the standardised scale, and undo. The
  pullback is $P^\ast = c\,Q(a - \log \hat s_y)$: a penalty in $a$ alone, with a *fixed* offset.
- **(iii) Anchor-free one-sided barrier.** $P^\ast = c\,Q(a)$ with $Q$ having no interior mode —
  the shape `blme` uses, $Q(a) = (\alpha-1)a$ from a $\mathrm{gamma}(\alpha,\lambda\to0)$ prior on
  the SD (Chung et al. 2013, via Ranga §2).

### 3.2 Theorem (the anchor dichotomy)

> **Theorem 1.** Let $P^\ast$ be continuous and depend on the parameters only through
> $(a,\ell)$.
>
> **(a)** $P^\ast$ makes the penalised estimator exactly equivariant under $\{G_t\}$ **iff**
> $$P^\ast(a,\ell) \;=\; Q(a-\ell) \;+\; \kappa\,\ell \;+\; \text{const}$$
> for some continuous $Q$ and some $\kappa\in\mathbb R$.
>
> **(b)** If in addition $P^\ast$ is bounded above on $\Theta$ — condition (E2) of
> Sterzinger, Kosmidis & Moustaki 2026, Thm 4.1 — then $\kappa = 0$, so
> $$P^\ast(a,\ell) \;=\; Q(a-\ell) \;=\; Q(r).$$
>
> **(c)** In particular, a penalty depending on $a$ **alone** is exactly equivariant iff it is
> affine, $P^\ast(a) = \kappa a + \text{const}$; and every affine penalty is unbounded above,
> violating (E2), and diverges to $-\infty$ at only one end of $\overline{\mathbb R}$.

**Proof.** *(a)* Exact equivariance requires $P^\ast(a+t,\ell+t) - P^\ast(a,\ell) = k(t)$ for all
$(a,\ell)$ and all $t$. Change coordinates to $(r,u)$ with $r=a-\ell$, $u=\ell$; the group acts as
$(r,u)\mapsto(r,u+t)$, so the condition reads $P^\ast(r,u+t)-P^\ast(r,u)=k(t)$, independent of both
$r$ and $u$. Fixing $r$ and varying $u$, the function $u\mapsto P^\ast(r,u)$ has $u$-increments
independent of $u$, hence $P^\ast(r,u) = Q(r) + \kappa(r)\,u$ for some $\kappa(r)$; independence of
the increment from $r$ forces $\kappa(r)\equiv\kappa$ constant. Continuity of $k$ and Cauchy's
functional equation give $k(t)=\kappa t$. Conversely any such $P^\ast$ satisfies the condition.

*(b)* $u=\ell$ ranges over all of $\mathbb R$ on $\Theta$. If $\kappa\neq0$ then
$P^\ast(r,u)\to+\infty$ as $u\to+\infty$ (if $\kappa>0$) or as $u\to-\infty$ (if $\kappa<0$), so
$P^\ast$ is unbounded above. Hence (E2) forces $\kappa=0$.

*(c)* A penalty in $a$ alone is the case $Q\equiv$ const of the above written in $(a,\ell)$
coordinates only if it is constant; more directly, applying *(a)* with $P^\ast$ free of $\ell$ gives
$P^\ast(a+t)-P^\ast(a) = k(t)$ for all $a,t$, so by the same Cauchy argument
$P^\ast(a) = \kappa a + \text{const}$. Such a $P^\ast$ is unbounded above (in $a$ if $\kappa>0$,
in $-a$ if $\kappa<0$) and satisfies $P^\ast\to-\infty$ at exactly one end. $\blacksquare$

### 3.3 What the theorem decides

**Candidate (iii) is eliminated as a two-sided form.** Theorem 1(c) says the *only* anchor-free
exactly-equivariant penalty is `blme`'s own affine shape — and that shape necessarily violates (E2)
and guards one boundary only. The theorem therefore *derives* `blme`'s documented failure mode
(Ranga §4: estimates $>800$ under separation) from its equivariance property: `blme` is
scale-equivariant *because* it is affine, and one-sided *because* it is affine. The two facts are
the same fact. No repair inside the anchor-free class exists.

**Candidate (ii) is admissible but strictly weaker than (i).** A data-statistic anchor is
equivariant (Theorem 1 applies with $\log\hat s_y$ playing the role of $\ell$, since
$\log\hat s_y\mapsto\log\hat s_y + t$) and boundedness above is then automatic, so (ii) is a
legitimate member of the same family. Its defect is the *quality of the anchor*, and it is
decisive at small $g$:

- If $\hat s_y$ is the marginal SD of $y$, it estimates $\sqrt{\sigma^2+\sigma_u^2}$ — it is
  contaminated by the very quantity being regularised, with contamination that grows exactly where
  the penalty is supposed to act hardest (large $r$).
- If $\hat s_y$ is a fixed-effect-only residual SD, its error relative to $\sigma$ is driven by the
  unmodelled random effect, hence is $O_p(g^{-1/2})$ — the **same order** as the estimation error
  in the target. Anchoring a $g$-rate problem to a $g$-rate statistic buys nothing.
- The model-based anchor $\ell = \log\sigma$, by contrast, is estimated at the $n$-rate: §5 gives
  $I_{\ell\ell} \asymp g(m-1) \asymp n$. It is the fastest-converging scale reference available
  inside the model.
- Technically, (ii) also makes $P$ a *data-dependent* function, which is not the fixed $P$ of the
  factor-analysis paper's condition N4. This is repairable — $\log\hat s_y \to^{p}\log s_0$ at
  $O_p(\cdot)$ rates, so the perturbation is of strictly smaller order than $c_g$ — but it is an
  extra argument that (i) does not need.

**Candidate (i) is chosen.** It is exactly equivariant by Theorem 1(b), admits a bounded-above
two-sided $Q$, and uses the fastest-converging scale reference in the model. §4.3 derives the
consequence of the anchor being a *moving* one, which is the only real cost, and shows it is
$O(c_g/n)$.

### 3.4 One extra dividend: the breakpoint becomes interpretable

The shipped negative Huber has its quadratic/linear breakpoint at $|{\cdot}|=1$. Under the shipped
form that means "$\mathrm{sd}$ within a factor of $e$ of one response unit" — an accident of
measurement. Under the repaired form it means

$$
|r|\le 1 \iff e^{-1} \;\le\; \frac{\sigma_u}{\sigma}\;\le\; e,
$$

i.e. *the random-effect SD is within a factor of $e$ of the residual SD* — a unit-free, readable
statement about signal-to-noise. The repair does not merely move the anchor; it makes the shape
parameter mean something.

---

## 4. The chosen penalty form

### 4.1 Statement

Let $D$ be the shipped negative Huber (`src/drmTMB.cpp:77-85`; design 250):

$$
D(t) \;=\;
\begin{cases}
-\tfrac12 t^2, & |t|\le 1,\\[2pt]
-|t| + \tfrac12, & |t| > 1,
\end{cases}
\qquad D\le 0,\quad D(0)=0,\quad D\in C^1,\quad |D'|\le 1 .
$$

Define the two-sided slope-scaled variant, for $\kappa_-,\kappa_+>0$,

$$
Q_{\kappa_-,\kappa_+}(t) \;=\;
\begin{cases}
\kappa_-\,D(t), & t\le 0,\\
\kappa_+\,D(t), & t>0 ,
\end{cases}
\tag{4.1}
$$

which is $C^1$ (both $D(0)=0$ and $D'(0)=0$, so value and slope match from either side) though not
$C^2$, and which reduces to $D$ at the default $\kappa_-=\kappa_+=1$.

**The derived penalty for a q1 random-intercept block is**

$$
\boxed{\;
P_v(\theta) \;=\; c_g \, Q_{\kappa_-,\kappa_+}\!\bigl(a - \log s(\theta)\bigr),
\qquad a=\log \sigma_u, \qquad
\log s(\theta) = \frac{1}{n}\sum_{i=1}^{n}\eta_i^{\sigma} ,
\;}
\tag{4.2}
$$

with $c_g$ given in §6, and $\eta_i^\sigma = \log\sigma_i$ the model's residual-scale linear
predictor. For a constant-$\sigma$ Gaussian fit, $\log s = \log\sigma = \ell$ exactly and (4.2)
reduces to $c_g\,Q(r)$.

The maximised criterion becomes

$$
\ell_{\mathrm{pen}}(\theta) \;=\; \ell_L(\theta) \;+\; c_n\,P_f(\beta) \;+\; c_g\,P_v(\theta),
\tag{4.3}
$$

with two softness constants, not one (§9). In TMB's minimisation convention the implementation
target is `nll_pen = nll_laplace - c_n * P_f - c_g * P_v`, added inside the template as a function
of the non-random parameters only, exactly as design 250 §"Stable q1/q2 covariance and Huber
coordinates" specifies for the shipped term.

Why the *mean* of $\eta^\sigma$ rather than the sigma intercept: every $\eta^\sigma_i$ shifts by
exactly $\log c$ under $y\mapsto cy$, so any fixed linear functional of $\eta^\sigma$ is an exactly
equivariant anchor; the row mean is chosen over $\beta_0^\sigma$ because the intercept refers to
$x=0$, which need not be inside the data.

### 4.2 The anchor is family-specific, and the defect is not universal

Assign each quantity an **equivariance weight** $w$: the power of $c$ by which it scales under
$y\mapsto cy$. The rule implied by Theorem 1 is: penalise $a - \log s$ where $s$ is any model
quantity with $w(s) = w(e^{a})$; if $w(e^a)=0$, take $s\equiv1$ and the shipped anchor is already
correct.

| route | mu linear predictor | $w(\sigma_u)$ | anchor $s$ |
| --- | --- | --- | --- |
| gaussian, identity link, location RE | $\eta = X\beta + Zu$, $y$ on $\eta$'s scale | $1$ | $\exp(\overline{\eta^\sigma})$ |
| skew_normal, identity link, location RE | as above | $1$ | $\exp(\overline{\eta^\sigma})$ |
| bivariate Gaussian, identity link | as above, per endpoint | $1$ | per-endpoint $\exp(\overline{\eta^{\sigma_k}})$ |
| gaussian, **sigma-side** RE (RE on $\log\sigma$) | $y\mapsto cy$ shifts the $\sigma$ intercept | $0$ | $1$ |
| lognormal, Gamma/log, Poisson/log, nbinom2, tweedie | $y\mapsto cy$ shifts the intercept | $0$ | $1$ |
| binomial (logit/probit/cloglog), cumulative_logit, beta, zero_one_beta | no scale group acts on the response | $0$ | $1$ |

**Consequence.** The anchor defect F1 is *not* a general property of the shipped penalty. It bites
exactly where the location random effect lives on an identity-link linear predictor — which is
exactly drmTMB's A1/D-117 target and nowhere else among the fitted families. On every log- or
logit-link route the scale group acts by *translation* of the linear predictor, which leaves $a$
invariant, and the shipped $D(a)$ is already exactly equivariant. This also re-derives, rather than
merely repeats, Fisher's remark that "for binomial the anchor is defensible — the logit latent
scale is fixed — which is exactly why the published route is binomial-only"
(Fisher §1c).

*Verification obligation for S2:* the link assignments in the table above are taken from the family
documentation in `R/drmTMB.R:69-73`; S2 must confirm each row against the family constructors in
`R/family.R` before wiring the anchor selection, and must fail loudly rather than default to
$s\equiv1$ for any family it cannot classify.

### 4.3 Consequence of a moving anchor

This is the cost the brief asked to be derived. With $P_v = c_g Q(r)$, $r = a-\ell$:

$$
\frac{\partial P_v}{\partial a} = c_g Q'(r),\qquad
\frac{\partial P_v}{\partial \ell} = -c_g Q'(r),\qquad
\nabla^2 P_v = c_g Q''(r)\begin{pmatrix}1 & -1\\ -1 & 1\end{pmatrix}.
\tag{4.4}
$$

Three consequences, in order of importance.

**(a) The penalty gradient is orthogonal to the orbit.**
$\nabla P_v \cdot (1,1)^{\top} = c_gQ' - c_gQ' = 0$. This is Theorem 1(b) in differential form: the
penalty exerts no force along the scale direction, which is precisely why equivariance is exact.
The Hessian (4.4) is rank one and negative semi-definite (since $Q''\le0$), so the penalty is
concave and reduces curvature only in the $r$ direction.

**(b) The residual scale is now displaced too, and provably negligibly.** Solving the penalised
score equations to first order, with $I$ the Fisher information for $(a,\ell)$,

$$
\hat\theta - \theta_0 \;\approx\; I^{-1}\bigl[\,U(\theta_0) + c_g Q'(r_0)\,(1,-1)^{\top}\bigr],
\tag{4.5}
$$

so the penalty-induced displacement is $c_gQ'(r_0)\,I^{-1}(1,-1)^{\top}$. Measured in standard
errors, the whole standardised displacement vector has norm

$$
\bigl\|\,c_g\,I^{-1/2}\nabla Q\,\bigr\|
\;\le\; \frac{c_g\,\|\nabla Q\|}{\sqrt{\lambda_{\min}(I)}}
\;=\; \frac{\sqrt2\,c_g\,|Q'(r_0)|}{\sqrt{\lambda_{\min}(I)}},
\tag{4.6}
$$

and §5 shows $\lambda_{\min}(I)$ is governed by the $a$ direction and is $\Theta(g)$. Per
coordinate, the displacement in $\ell$ measured in $\ell$'s own standard errors is
$O\!\bigl(c_g/\sqrt{I_{\ell\ell}}\bigr) = O\!\bigl(c_g/\sqrt{gm}\bigr)$, smaller than the
$a$-side ratio $O(c_g/\sqrt g)$ by a factor $\sqrt m$. **The more within-group replication, the
cheaper the moving anchor.**

**(c) The penalty is blind along the orbit — and the likelihood is not.** By (a), $P_v$ provides no
repulsion along sequences where $\sigma_u$ and $\sigma$ shrink together at the same rate ($r$
fixed, $\ell\to-\infty$). This is a genuine gap in the penalty, and it is closed by the likelihood
rather than the penalty: for $m\ge2$ with non-degenerate within-cluster residual variation,
$\ell_L\to-\infty$ as $\sigma\to0$ at fixed $r$. So the penalised objective is still coercive in
that direction. Stated as a condition: **(4.2) is admissible only for models whose likelihood is
already coercive along the scale orbit** — which excludes, for example, a one-observation-per-group
Gaussian design where $\sigma$ and $\sigma_u$ are not separately identified. S2 must reject
$m\equiv1$ designs rather than silently penalise a non-identified direction.

### 4.4 The q2 coordinates

Design 250 freezes the q2 penalty coordinates as $(\log L_{11},\, \log L_{22},\, L_{21})$ with
$L_{11}=e^{a_1}$, $L_{22}=e^{a_2}\operatorname{sech}z$, $L_{21}=e^{a_2}\tanh z$. Under
$y\mapsto cy$ we have $L\mapsto cL$, so the equivariant repair is coordinate-wise:

$$
P_v^{(q2)} \;=\; c_g\Bigl[\,
Q\bigl(\log L_{11} - \log s\bigr)
+ Q\bigl(\log L_{22} - \log s\bigr)
+ Q\bigl(L_{21}/s\bigr)\Bigr].
\tag{4.7}
$$

Each argument is invariant: $\log L_{kk}-\log s \mapsto \log L_{kk}-\log s$ and
$L_{21}/s\mapsto L_{21}/s$. This is the minimal change to the frozen coordinates and preserves the
design-250 prohibition on penalising $a_2$, $z$, $\rho$, or $\operatorname{atanh}\rho$ instead.
§10 treats what (4.7) does and does not fix.

---

## 5. The Fisher information for $\log\sigma_u$ — the group-rate calculation

The brief asks for $I_g$'s leading term in $g$ and $n_{\mathrm{per}}$, computed rather than
asserted. For the balanced Gaussian case it is closed-form.

### 5.1 Derivation

For a Gaussian marginal likelihood with mean $X\beta$ and covariance $V(\psi)$, the expected
information for variance parameters is
$I_{rs} = \tfrac12\sum_j \operatorname{tr}\bigl(V^{-1}\dot V_r V^{-1}\dot V_s\bigr)$, and the
$\beta$–$\psi$ block is exactly zero. Working first in $(\sigma_u^2,\sigma^2)$, and using

$$
V^{-1} = \frac{1}{\sigma^2}\Bigl(I - \frac{\sigma_u^2}{\lambda_1}J\Bigr),
\qquad V^{-1}J = \frac{J}{\lambda_1},\qquad \lambda_1 = \sigma^2+m\sigma_u^2,
$$

we get $V^{-1}JV^{-1} = J/\lambda_1^2$, hence $\operatorname{tr}(V^{-1}JV^{-1}J) = m^2/\lambda_1^2$
and $\operatorname{tr}(V^{-1}JV^{-1}) = m/\lambda_1^2$, while
$\operatorname{tr}(V^{-2}) = \lambda_1^{-2}+(m-1)\sigma^{-4}$. Therefore

$$
I_{\sigma_u^2\sigma_u^2} = \frac{g\,m^2}{2\lambda_1^2},\qquad
I_{\sigma_u^2\sigma^2} = \frac{g\,m}{2\lambda_1^2},\qquad
I_{\sigma^2\sigma^2} = \frac{g}{2}\Bigl[\frac{1}{\lambda_1^2}+\frac{m-1}{\sigma^4}\Bigr].
$$

Eliminating $\sigma^2$ gives the efficient (profiled) information for $\sigma_u^2$:

$$
I^{\mathrm{eff}}_{\sigma_u^2}
= I_{11} - \frac{I_{12}^2}{I_{22}}
= \frac{g\,m^2}{2\lambda_1^2}\cdot\frac{(m-1)\lambda_1^2}{\sigma^4+(m-1)\lambda_1^2}
= \frac{g\,m^2(m-1)}{2\bigl[\sigma^4+(m-1)\lambda_1^2\bigr]} .
$$

Transform to $a=\log\sigma_u$ with $\mathrm d\sigma_u^2/\mathrm d a = 2\sigma_u^2$:

$$
\boxed{\;
I_g \;:=\; I^{\mathrm{eff}}_{aa}
\;=\; \frac{2\,g\,m^2(m-1)\,\sigma_u^4}
{\sigma^4 + (m-1)\bigl(\sigma^2+m\sigma_u^2\bigr)^2}
\;=\; 2g\,\Phi(\kappa,m),
\qquad \kappa := \frac{m\sigma_u^2}{\sigma^2},
\;}
\tag{5.1}
$$

$$
\Phi(\kappa,m) \;=\; \frac{(m-1)\kappa^{2}}{1+(m-1)(1+\kappa)^{2}} \;\in\;[0,1).
$$

Likewise $I_{\ell\ell} = 2g\bigl[\sigma^4/\lambda_1^2 + (m-1)\bigr] \asymp 2g(m-1) \asymp 2n$.

### 5.2 The bound, and what it means

> **Proposition 2.** For every $g\ge1$, $m\ge2$, $\sigma>0$, $\sigma_u>0$,
> $$ I_g \;=\; 2g\,\Phi(\kappa,m) \;<\; 2g . $$
> The bound is attained only in the limits $\sigma\to0$ or $\sigma_u\to\infty$.

*Proof.* $\sigma^4 + (m-1)\lambda_1^2 > (m-1)(m\sigma_u^2)^2 = (m-1)m^2\sigma_u^4$, so the ratio in
(5.1) is $<1$. $\blacksquare$

Three readings, each load-bearing:

1. **The information for $\log\sigma_u$ is capped at $2g$ no matter how much within-group
   replication you buy.** Increasing $m$ from $4$ to $400$ cannot push $I_g$ past $2g$. This proves
   Noether §4's concern (R2) rather than asserting it: $c_n = 2\sqrt{p/n_{\mathrm{eff}}}$ is
   calibrated against an information that this parameter does not have.
2. **$I_g \to 0$ as $\sigma_u\to0$.** The information for the log-SD *vanishes* at the very
   boundary the penalty targets ($\Phi\to (m-1)\kappa^2/m \to 0$). This is the geometric heart of
   the problem: at the boundary the likelihood is locally flat in $a$, so an $O(1)$ penalty force
   produces an unbounded displacement in $a$. It is also why the penalty works at all.
3. **$I_g \to 2g$ as $\sigma_u/\sigma\to\infty$** — the pure group rate, matching the elementary
   information $g/(2\sigma_u^4)$ for a variance estimated from $g$ independent draws, transformed
   to the log scale. The cap is not an artefact; it is the model telling us that a random-effect SD
   is a $g$-observation problem.

### 5.3 Numerical verification

The closed forms (5.1) were checked against a numerically differentiated
$\tfrac{g}{2}\operatorname{tr}(V^{-1}\dot V_r V^{-1}\dot V_s)$ computed directly in the
$(a,\ell)$ coordinates over a $7\times2\times3\times4$ grid
($\sigma_u\in\{0.05,0.25,0.5,1,2,4,20\}$, $\sigma\in\{0.7,2.1\}$, $m\in\{2,4,10\}$,
$g\in\{5,10,25,40\}$; script retained in the session scratchpad, not committed):

- maximum relative error in $I_{aa}$: $2.9\times10^{-9}$
- maximum relative error in $I^{\mathrm{eff}}_{aa}$: $1.5\times10^{-10}$
- maximum $I^{\mathrm{eff}}_{aa}/(2g)$ over the grid: $0.99976$ — Proposition 2 holds throughout
- $\lambda_{\min}(I)$ tracks $I^{\mathrm{eff}}_{aa}$ to within a factor $1.06$, confirming the
  $a$-direction is the least-informed one, as used in (4.6).

At the D-117 A1 cell ($g=10$, $m=4$, $\sigma=0.7$):

| $\sigma_u$ | 0.05 | 0.25 | 0.5 | 1.0 | 2.0 | 4.0 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| $\Phi$ | 0.0003 | 0.0996 | 0.4348 | 0.7905 | 0.9412 | 0.9848 |
| $I_g$ | 0.006 | 1.99 | 8.70 | 15.81 | 18.82 | 19.70 |
| $\mathrm{se}(a) = I_g^{-1/2}$ | 12.8 | 0.709 | 0.339 | 0.252 | 0.230 | 0.225 |

---

## 6. The softness constant $c_g$

### 6.1 The displacement principle

Derive the rate condition rather than importing it. From (4.5), with $|Q'|$ bounded, the penalised
estimator satisfies

$$
\sqrt{I}\,(\hat a - a_0)
\;=\; \underbrace{\frac{U(a_0)}{\sqrt I}}_{\rightsquigarrow\,N(0,1)}
\;+\; \underbrace{\frac{c_g\,Q'(r_0)}{\sqrt I}}_{=:\ \delta_g} \;+\; o_p(1).
\tag{6.1}
$$

Asymptotic normality **centred at the truth** therefore requires $\delta_g\to0$, i.e.

$$
c_g \;=\; o\bigl(\sqrt{I_g}\bigr) \;=\; o\bigl(\sqrt g\,\bigr)
\qquad\text{(by Proposition 2, since }\Phi(\kappa_0,m)\text{ is a fixed constant at an interior truth)} .
\tag{6.2}
$$

Consistency needs only the weaker $c_g|Q(r_0)| = o(n)$, so (6.2) is the binding condition — exactly
the structure of Sterzinger, Kosmidis & Moustaki 2026 Thm 5.2 (condition N4), with $\sqrt n$
replaced by $\sqrt{I_g}$ because the information is what the condition is really about (Ranga §1
records their own derivation of $\rho = 2\sqrt{2/n^3}$ "from the $\sqrt{n/2}$ rate at which Fisher
information accumulates for a variance parameter under independence").

**$\delta_g$ is the design quantity**: it is the maximum displacement of $\hat a$ measured in its
own standard errors. Softness is exactly the statement $\delta_g\to0$. This is also why the *Huber*
shape matters and not merely the anchor: $|D'|\le1$ everywhere, so $\delta_g\le c_g/\sqrt{I_g}$
uniformly. A pure quadratic penalty, with unbounded derivative, admits no such uniform bound.

### 6.2 Cross-check: the displacement principle reproduces Chung's Property 1

Chung et al. 2013 prove: under a quadratic approximation to the profile log-likelihood with
$\hat\sigma^{\mathrm{ML}}_\theta=0$, the $\mathrm{gamma}(\alpha,\lambda\to0)$-penalised estimate is
$\hat\sigma_\theta = \widehat{\mathrm{se}}\cdot\sqrt{\alpha-1}$, so $\alpha=2$ gives exactly one
standard error (Ranga §2). Deriving it in the present framework: maximise
$-\sigma^2/(2s^2) + (\alpha-1)\log\sigma$ in $\sigma$, giving $-\sigma/s^2+(\alpha-1)/\sigma=0$,
hence $\sigma = s\sqrt{\alpha-1}$. Reproduced exactly. The framework is therefore continuous with
the one published calibration result in this area, and Chung's $\alpha$ is visible as a growth
constant on the log scale (§6.4).

### 6.3 The chosen constant

Proposition 2 supplies a *parameter-free* information scale, $2g$, which upper-bounds $I_g$
uniformly. Using it — rather than a plug-in $\hat I_g$, which would make $c$ a function of the
parameters and add a spurious $c'(a)Q(a)$ term to the score — gives the mirror of the paper's
$2\sqrt{p/n}$:

$$
\boxed{\;
c_g \;=\; 2\sqrt{\frac{q_v}{g}}
\;}
\tag{6.3}
$$

where $q_v$ is the number of penalised variance-component coordinates in the block and $g$ the
number of retained levels of the grouping factor (after complete-case pruning, mirroring design
250's treatment of $n_{\mathrm{eff}}$). Then

$$
\delta_g \;\le\; \frac{c_g}{\sqrt{2g}} \;=\; \frac{\sqrt{2q_v}}{g} \;\longrightarrow\; 0,
\qquad
c_g = O(g^{-1/2}) = o(\sqrt g)\ \checkmark,
\qquad
c_g = o(g) \subseteq o(n)\ \checkmark .
$$

**Graceful degradation, as the brief requires.**

- *$g$ grows, $m$ fixed:* $c_g\to0$ like $g^{-1/2}$ and $\delta_g\to0$ like $g^{-1}$. The penalty
  vanishes relative to the data, protecting AIC/BIC (R4).
- *$m$ grows, $g$ fixed:* $c_g$ is **unchanged**, which is correct: by Proposition 2, $I_g$ cannot
  exceed $2g$ no matter how large $m$ is, so a constant that shrank with $m$ would be softening
  against information that does not exist. In this regime $\delta_g$ does fall, but only through
  $\Phi(\kappa,m)\uparrow$, i.e. through the genuine information gain, which saturates.
- *Both grow:* $\delta_g = O(1/g)$, dominated by $g$ alone. Correct, and the point of the whole
  exercise.

Numerically, at the D-117 A1 cell $c_g = 2/\sqrt{10} = 0.632$, against the shipped
$c_n = 2\sqrt{2/40} = 0.447$; the repaired constant is of the same order at the design point but
decays in $g$ rather than $n$. The resulting maximum displacements $\delta_g = c_g/\sqrt{I_g}$
(computed, $m=4$, $\sigma=0.7$):

| $\sigma_u\backslash g$ | 5 | 10 | 25 | 40 |
| --- | ---: | ---: | ---: | ---: |
| 0.25 | 0.896 | 0.448 | 0.179 | 0.112 |
| 0.50 | 0.429 | 0.214 | 0.086 | 0.054 |
| 1.00 | 0.318 | 0.159 | 0.064 | 0.040 |
| 2.00 | 0.292 | 0.146 | 0.058 | 0.036 |
| 4.00 | 0.285 | 0.143 | 0.057 | 0.036 |

Read this table as the honest budget of what the penalty can do: at $g=10$ it may move the estimate
by at most a fifth of a standard error away from the boundary region, and by $g=40$ by four
percent of one. **A penalty this soft cannot rescue a badly-calibrated interval; it can only
prevent a degenerate one.** Any S3 result claiming a large coverage repair at $g=40$ would
contradict this table and should be treated as an implementation error before it is treated as a
finding.

### 6.4 Shape: growth constant, and why it is not a free extra knob

Near the lower boundary $Q_{\kappa_-,\kappa_+}(r)\to\kappa_-(r+\tfrac12)$, so the objective bonus
behaves like $c_g\kappa_-\log\sigma_u$ + const, i.e. the induced density has a polynomial zero
$p(\sigma_u)\propto\sigma_u^{\,c_g\kappa_- - 1}$ and the growth constant in Noether §1's sense is

$$
c^{\text{growth}} \;=\; c_g\,\kappa_- \;>\;0 \quad\checkmark
$$

(Noether's convention: the shipped Huber at unit coefficient has $c^{\text{growth}}=1$; Chung's
$\alpha=2$ has $c^{\text{growth}}=2$; his coverage-optimal $\alpha=3$ has $3$). Note that for a
*symmetric* Huber, $\kappa$ and $c_g$ are not separately identified — scaling $D$ is the same as
scaling $c_g$. The genuine extra freedom is the **asymmetry** $\kappa_+/\kappa_-$, which controls
how hard the upper boundary is guarded independently of the lower one. Defaults and arms:

- **Default $\kappa_-=\kappa_+=1$** — the shipped shape, changed in no way except its argument.
- **$\kappa_-=2$** — the Chung $\alpha=3$ analogue, which the one published tuning study found
  better for *coverage* than for point bias (Ranga §2). A pre-registered S3 arm, not a default.
- **$\kappa_+\ll\kappa_-$** — retains (E3) at the upper boundary (any $\kappa_+>0$ suffices) while
  making the upper-side pull arbitrarily weak. This is the tuning handle aimed directly at
  Fisher's F1 complaint that the shipped penalty *worsens* bias above the anchor. Also an S3 arm.

---

## 7. Which boundaries are guarded

**Explicit two-sided statement.** With $Q_{\kappa_-,\kappa_+}$ and $\kappa_\pm>0$:

$$
\sigma_u/s \to 0^{+} \;\Rightarrow\; r\to-\infty \;\Rightarrow\; P_v \to -\infty
\qquad\text{(lower guard, growth constant } c_g\kappa_-),
$$
$$
\sigma_u/s \to \infty \;\Rightarrow\; r\to+\infty \;\Rightarrow\; P_v \to -\infty
\qquad\text{(upper guard, growth constant } c_g\kappa_+).
$$

**Both boundaries are guarded.** This closes `blme`'s documented hole (Ranga §4) and is not
optional: Theorem 1 showed that giving up the upper guard means giving up boundedness above (E2),
which is a hypothesis of the existence theorem the whole construction rests on.

**What the upper guard costs, stated honestly.** The upper-side force is a shrinkage of $\sigma_u$
toward the residual scale, so for a true $\sigma_u$ well above $\sigma$ the penalty adds downward
bias. **The repair does not eliminate Fisher's measured sign flip; it relocates it from
$\sigma_u = 1$ (a unit accident) to $\sigma_u = s$ (a scale-free, interpretable place), and bounds
its magnitude.** Bounded is the operative word: the force is $\le c_g\kappa_+$ in the score, hence
$\le\delta_g$ standard errors, hence $O(1/g)$, whereas `blme`'s failure mode is unbounded
(estimates $>800$). Trading an unbounded upper failure for a bounded, vanishing upper bias is the
substance of the choice, and §13 makes the relocation a falsifiable prediction rather than a claim.

**What is not guarded.** The scale-orbit direction (§4.3c) — closed by likelihood coercivity, not
by the penalty, and only for designs with $m\ge2$ and genuine within-cluster variation.

---

## 8. Verification against (E1)–(E3) and the rate conditions

Each line is a verification, not a citation. Conditions as stated in Sterzinger, Kosmidis &
Moustaki 2026, Thm 4.1 / 5.1 / 5.2, quoted through Ranga §1.

**(E1) Continuity on $\Theta$.** $D\in C^1(\mathbb R)$ (at $|t|=1$ both $D$ and
$D'(t)=-t \to -\operatorname{sign}t$ agree), and $Q_{\kappa_-,\kappa_+}\in C^1$ by the matching of
value and slope at $t=0$ shown in §4.1. The map $\theta\mapsto r = a - \overline{\eta^\sigma}$ is
affine in the fitting coordinates, hence smooth. Composition gives $P_v\in C^1(\Theta)$. ✓

**(E2) Bounded above on $\Theta$.** $Q_{\kappa_-,\kappa_+}(t)\le Q(0)=0$ for all $t$ and
$c_g>0$, so $\sup_\Theta P_v = 0$, attained at $\sigma_u = s$. ✓ *(This is the condition the affine
`blme` shape fails — Theorem 1(c).)*

**(E3) Divergence at $\partial\Theta$ with $\lambda_{\min}(\Sigma)$ bounded away from $0$.** For
the one-way model $\Sigma = \sigma^2 I_m + \sigma_u^2 J_m$ has $\lambda_{\min}(\Sigma)=\sigma^2$,
so the theorem's side condition is exactly $\sigma^2 \ge \epsilon > 0$; combined with likelihood
coercivity bounding $\sigma$ above on relevant sequences, $\log s$ stays in a compact set. Then
$\sigma_u\to0^+ \Rightarrow r\to-\infty \Rightarrow P_v\to-\infty$, and
$\sigma_u\to\infty \Rightarrow r\to+\infty \Rightarrow P_v\to-\infty$. ✓ *(Sequences with
$\sigma\to0$ jointly are excluded by the side condition itself; §4.3c records that they are
repelled by $\ell_L$.)*

**(C3) $P^\ast\le0$ everywhere.** $c_g>0$ and $Q\le0$, so $P_v\le0$ on $\Theta$. ✓

**Consistency, $o_p(n)$.** At a fixed interior truth $r_0$, $|Q(r_0)|<\infty$ is a fixed constant,
so $|c_gP_v(\theta_0)| = c_g|Q(r_0)| = O(g^{-1/2}) \to 0$; a fortiori
$n^{-1}c_g P_v(\theta_0)\to^{p}0$. ✓ *(Note the penalty vanishes absolutely, not merely
relatively — a strictly stronger property than the condition requires.)*

**Asymptotic normality, $o_p(\sqrt{I_g})$.** By (6.1)–(6.3),
$\delta_g \le c_g/\sqrt{2g} = \sqrt{2q_v}/g\to0$, so $c_g = o_p(\sqrt{I_g})$. ✓ The bounded
derivative $|Q'|\le\max(\kappa_-,\kappa_+)$ is what makes this uniform in $r_0$ rather than
pointwise. ✓

**Rotation-invariance / fixed $P$ (N4).** $Q$ is a fixed function of $\theta$, not of the data —
this is the property candidate (ii) would have sacrificed (§3.3) and (i) preserves. ✓

---

## 9. The composite: two penalties, two rates

### 9.1 The objective

With the fixed-effect Jeffreys term retained unchanged
(`src/drmTMB.cpp:5003-5016`; design 250 eq. for $P_f$):

$$
\ell_{\mathrm{pen}} = \ell_L(\beta,\psi) \;+\; c_n P_f(\beta) \;+\; c_g P_v(\psi),
\qquad c_n = 2\sqrt{\frac{p}{n_{\mathrm{eff}}}},\quad c_g = 2\sqrt{\frac{q_v}{g}} .
\tag{9.1}
$$

This is the single most consequential structural change from the shipped mechanism, which applies
one constant to both terms (`src/drmTMB.cpp:5043-5044`:
`mspl_c_n * (mspl_jeffreys + mspl_variance_negative_huber)`).

### 9.2 Why the two-rate composition is safe

**Functional separability.** $P_f$ depends only on $\beta$, evaluated at the fixed-effects-only
information; $P_v$ depends only on the variance-side coordinates $(a,\overline{\eta^\sigma})$.
Hence $\nabla^2 P^\ast$ is block-diagonal and there is no penalty-level cross-Hessian. Noether §4
established this for the shipped form; the moving anchor does not break it, because
$\overline{\eta^\sigma}$ is a variance-side coordinate, still disjoint from $\beta$.

**Information block-diagonality.** For a Gaussian marginal likelihood with mean $X\beta$ and
covariance $V(\psi)$, $E[\partial^2\ell_L/\partial\beta\,\partial\psi] = 0$ exactly. So for the A1
cell the two blocks decouple at the information level as well as the penalty level, and the
standardised displacement (6.1) splits:

$$
I^{-1/2}\bigl(c_n\nabla P_f + c_g\nabla P_v\bigr)
= \Bigl(\,c_n I_{\beta\beta}^{-1/2}\nabla P_f,\;\; c_g I_{\psi\psi}^{-1/2}\nabla P_v \Bigr).
\tag{9.2}
$$

Each component must vanish separately, giving $c_n = o(\sqrt{I_{\beta\beta}}) = o(\sqrt n)$ and
$c_g = o(\sqrt{I_{\psi\psi}}) = o(\sqrt g)$ **independently**. Both asymptotic arguments survive
unchanged, and consistency composes trivially: $c_nP_f + c_gP_v = o_p(n) + o_p(g) = o_p(n)$ since
$g\le n$.

**The named condition under which they cannot interact badly.**

> **Condition COMP.** The two-rate composite preserves both asymptotic arguments provided
> (a) the penalties are functionally separable in $(\beta,\psi)$, and
> (b) the information correlation between the blocks is bounded away from unity,
> $$\rho_{\beta\psi} := \bigl\|I_{\beta\beta}^{-1/2} I_{\beta\psi} I_{\psi\psi}^{-1/2}\bigr\| \le \bar\rho < 1 .$$

Under (a) and (b) the leakage of the variance-side penalty into the $\beta$-block displacement is
$O(\bar\rho\, c_g/\sqrt{I_{\psi\psi}}) = O(\bar\rho\,c_g/\sqrt g)\to0$, and symmetrically for the
other direction, so neither constant needs to know about the other. For the Gaussian A1 cell
$\rho_{\beta\psi}=0$ exactly and (b) is vacuous; for non-Gaussian families it holds asymptotically
whenever the model is jointly identified. **What COMP forbids** is a design where the fixed effects
and the variance components are jointly near-non-identified ($\bar\rho\to1$) — there the two
penalties would compete through the likelihood, and the separate rate conditions would no longer
suffice. S2 is Gaussian-only, so the exact case applies; any later extension must re-check (b).

---

## 10. The $\rho$ boundary: correlations at $\pm1$

A sketch with the growth condition, as the brief permits, plus the part of the treatment that
follows immediately and the part that must be deferred with a reason.

**Coordinate and boundary.** drmTMB stores the correlation as $z$ with $\rho=\tanh z$, so
$\rho\to\pm1 \iff z\to\pm\infty$: on the fitting scale the correlation boundary is again at
infinity, structurally the same as the SD boundary.

**Growth condition.** A penalty on $z$ repels $\rho=\pm1$ iff its log-scale growth constant is
positive, i.e. $\liminf_{|z|\to\infty} |P(z)|/|z| = c^{\text{growth}}>0$. The negative Huber
$D(z)$ satisfies this with $c^{\text{growth}}=1$ per side, symmetrically. Verified against
(E1)–(E3): $D\in C^1$ ✓; $D\le D(0)=0$, bounded above ✓; $D(z)\to-\infty$ as $z\to\pm\infty$,
diverging at both $\rho=+1$ and $\rho=-1$ ✓. Rate: information for a random-effect correlation
also accumulates at the group rate, so $c_g$ of (6.3) is the right constant with $q_v$ counting the
correlation coordinate.

**Equivariance is free here.** $\rho$ is invariant under $y\mapsto cy$ ($w(\rho)=0$), so a penalty
on $z$ needs no anchor at all and is exactly equivariant as it stands. This is the $s\equiv1$ row of
§4.2's table.

**What (4.7) does and does not repair.** The shipped q2 coordinates are
$(\log L_{11},\log L_{22}, L_{21})$, not $(a_1,a_2,z)$, and the correlation enters through
$L_{21}=e^{a_2}\tanh z$ and $L_{22}=e^{a_2}\operatorname{sech}z$. Equation (4.7) makes all three
arguments invariant under the *response* scale group. It does **not** make them invariant under the
*predictor* scale group $x\mapsto d\,x$: a random slope has units of $y/x$, so $L_{22}$ and $L_{21}$
carry weight $-1$ in $d$, and the residual-scale anchor $s$ knows nothing about $x$. Repairing that
would require a predictor-scale anchor such as $\mathrm{sd}(x)$ — a *data statistic*, which
reintroduces every objection §3.3 raised against candidate (ii), and does so in a setting where the
statistic is not even a model quantity.

**Deferral, with the reason.** The full q2 treatment is deferred out of S1 because it needs a
second, independent equivariance analysis in the predictor scale group and a second information
calculation (the correlation and slope-SD information rates in a q2 block are not the scalar
calculation of §5). S2 is iid-q1-only by the programme's own scoping, so nothing downstream is
blocked. What S1 does fix is the *statement* of the target: any q2 extension must satisfy
equivariance in **both** groups or explicitly document which one it abandons, and (4.7) is the
correct $y$-side half.

---

## 11. Košuta, Langerholc & Blagus 2026 — read in full, and why the data-augmentation route is not taken

The brief required an attempt to read this paper before deriving. **The main text was obtained in
full** (Biometrics 82(1), `ujag013`, Open Access CC-BY, DOI `10.1093/biomtc/ujag013`, 10 pages
read directly from the publisher PDF). The Web Appendices A–I — which hold the exact
$\eta_i$ construction (App. B.II), the Wishart-on-precision variant (App. A), the proofs (App. D),
and the full simulation tables (App. F–H) — were **not** obtained and are marked UNVERIFIED where
relied on. A companion R package `glmmTMBaug` is named in the paper's data-availability statement;
not inspected.

### 11.1 What it actually does

The penalty is an inverse-Wishart on the random-effect covariance $\Sigma$ (their eq. 3):

$$
J(\Sigma;\Psi,\nu) = \det(\Sigma)^{-(\nu+q+1)/2}\exp\Bigl\{-\tfrac12\operatorname{tr}(\Psi\Sigma^{-1})\Bigr\},
\qquad
\hat\theta_{\mathrm{PML}} = \arg\max_\theta\bigl[\ell(\theta;y) + \log J\bigr].
$$

It is realised **without touching the objective**, by data augmentation: $q$ pseudo-clusters of $q$
pseudo-observations each, with $X_i = 0$, $Z_i = I_q$, weights $w_{ij}\to\infty$ (in practice
$10^8$), and pseudo-responses $g^{-1}(\eta_i)$ where the $\eta_i$ decompose $c^{-1}\Psi$ with
$c = N_0/q$, $N_0=\nu+q+1$. Their default is $\nu = 2q-1$, so $N_0=3q$ and $c=3$. The scale matrix
$\Psi$ is **data-dependent**: built from the eigendecomposition of the ML estimate $\hat\Sigma$,
with eigenvalues shrunk toward their mean by a factor $\tau$ chosen as the largest value whose
marginal log-likelihood drop is below a fixed $\chi^2$ cutoff of $1.92$.

Their Lemma 1 guards **all** boundaries at once — $\lambda_i\to0^+$, $\lambda_i\to\infty$, and
(via Remark 1) $|r_{ij}|\to1$ — for any positive-definite $\Psi$ and $\nu+q+1>0$.

### 11.2 Two things I derived from it that the paper does not state

**(a) Their penalty is exactly scale-equivariant, and Theorem 1 says why.** Under $y\mapsto cy$,
$\hat\Sigma\mapsto c^2\hat\Sigma$ so $\Psi\mapsto c^2\Psi$, and

$$
\log J(c^2\Sigma;\,c^2\Psi,\nu) = \log J(\Sigma;\Psi,\nu) \;-\; (\nu+q+1)\,q\log c ,
$$

a parameter-free constant. ✓ **And Theorem 1 explains the design choice they do not comment on:**
had they anchored $\Psi$ to a *model parameter* (say the residual variance) rather than a *data
statistic*, the $-(\nu+q+1)/2\log\det\Sigma$ term would contribute the $\kappa\ell$ piece of
Theorem 1(a) with $\kappa\neq0$, and (E2) would fail. Their construction is the data-statistic
branch — candidate (ii) — realised with an inverse-Wishart shape. That an independent 2026 paper
lands inside the family Theorem 1 classifies is the strongest external corroboration this
derivation has. *(Derivation mine; AGENT-INFERRED, not a claim in the paper.)*

**(b) For $q=1$ their construction degenerates, in a way that reinstates F1.** Their shrinkage
target shrinks the eigenvalues of $\hat\Sigma$ *toward their mean*. For a scalar random intercept
there is exactly one eigenvalue, so its mean is itself and $\tilde\Lambda=\Lambda$ for every $\tau$:
$\Psi = 3\hat\sigma^2_{u,\mathrm{ML}}$. But $\hat\sigma^2_{u,\mathrm{ML}} = 0$ at precisely the
replicates that need the penalty, and the paper's own safeguard is to truncate eigenvalues to
$[10^{-4},10^{4}]$ — so on a boundary replicate the anchor becomes the truncation floor
$10^{-4}$, **a constant in the user's response units**. That is defect F1 again, relocated from
$\mathrm{sd}=1$ to $\mathrm{sd}=10^{-2}$. *(AGENT-INFERRED from the main text; the exact $\eta_i$
construction is in the unfetched Web Appendix B.II and could conceivably differ. Flag as a lead,
not as a finding, and re-check against the appendix before citing.)*

### 11.3 Why the route is not taken

| criterion | this derivation (4.2) | Košuta et al. 2026 |
| --- | --- | --- |
| E1–E3 | satisfied (§8) | satisfied (their Lemma 1) |
| scale equivariance | exact, model anchor | exact, data-statistic anchor |
| both boundaries guarded | yes | yes |
| **softness rate** | $c_g = 2\sqrt{q_v/g} = o(\sqrt g)$ | **none — fixed strength, $O(1)$** |
| behaviour at $q=1$ | the target case | shrinkage target degenerates (§11.2b) |
| smallest true variance studied | S3 will include exactly $0$ | $0.001$; no true-zero cell |
| coverage measured on | the variance component itself (S3 target) | fixed-effect slope only |
| smallest cluster count studied | S3 goes to $g=5$ | $N=25$ |
| implementation | direct objective, TMB tape | pseudo-observations, $w=10^8$ |

**Decision: direct-objective route; the data-augmentation route is recorded as a rejected
alternative.** Three reasons, in order of force.

1. **Rate.** Their penalty has no $n$- or $g$-dependent scaling in its form. Its asymptotic
   negligibility rests on the standard MAP/Firth argument — a bounded penalty gradient against a
   growing likelihood — which delivers consistency but is *not* the $o_p(\sqrt{I})$ condition R4
   requires. This programme exists partly because Ranga §5 found that undecayed penalties make
   AIC/BIC "completely fail"; adopting an $O(1)$ penalty would import exactly that hazard.
2. **Shape incompatibility.** Data augmentation realises an inverse-Wishart penalty and only an
   inverse-Wishart penalty; the negative Huber is not of that form, so the two routes are not
   interchangeable for the chosen $Q$. Choosing the augmentation route would mean choosing the
   inverse-Wishart shape — which §11.2b shows degenerates at $q=1$.
3. **Numerics.** $w=10^8$ pseudo-observation weights inside drmTMB's Laplace fold is a conditioning
   hazard we would be importing to avoid a C++ edit we already know how to make: the shipped MSPL
   term proves the objective hook exists (`src/drmTMB.cpp:5018-5046`).

**What is kept.** Their boundary taxonomy (Definition 1: $\lambda\to0$, $\lambda\to\infty$,
and both at once) is the cleanest statement of R3 in the literature and is adopted as the
vocabulary for §7. Their finding that ML/REML hit a correlation boundary of $-1$ on real data with
point estimates in the thousands is independent corroboration of the upper-boundary risk. And
crucially: **their coverage evaluation is for the fixed-effect slope only, and their grid contains
no true-zero cell.** Ranga's gap — no study anywhere of *profile-likelihood interval coverage of a
penalised variance component* — survives this paper intact.

---

## 12. Rejected alternatives, with reasons

| # | alternative | why rejected |
| --- | --- | --- |
| A1 | Keep the shipped $D(a)$, anchored at $\mathrm{sd}=1$ | Not equivariant for identity-link location REs (§2.3, Fisher §0 measured it). Defensible only where $w(\sigma_u)=0$ (§4.2), which is where it already is. |
| A2 | Anchor-free affine penalty (`blme`'s $(\alpha-1)a$) | Theorem 1(c): the only equivariant $a$-only form, but necessarily unbounded above (E2 fails) and one-sided. Its documented $>800$ divergence (Ranga §4) is this theorem, measured. |
| A3 | Data-statistic anchor, $\hat s_y$ (candidate ii) | Admissible, but the anchor converges at best at the $g$-rate and is contaminated by the target (§3.3). Strictly dominated by the $n$-rate model anchor. |
| A4 | Jeffreys-style prior on the variance component | Growth constant $c^{\text{growth}}=0$: flat on the log scale, no repulsion at all. The category error Noether §1 named; recorded here so it is not re-proposed. |
| A5 | Inverse-Wishart via data augmentation (Košuta et al.) | §11.3: no softness rate, shape degenerates at $q=1$, $w=10^8$ numerics. Retained as a candidate for $q\ge2$ blocks, where the shrinkage target is non-degenerate. |
| A6 | Plug-in constant $c_g = \delta\sqrt{\hat I_g}$ | Makes $c$ a function of the parameters, adding a $c'(a)Q(a)$ term to the score and destroying the bounded-derivative property that makes $\delta_g$ uniform (§6.1). Proposition 2's parameter-free bound $2g$ removes the need. |
| A7 | One shared constant for $P_f$ and $P_v$ (the shipped composition) | The two blocks are softened against information growing at $n$ and at $g$ respectively; a single constant cannot satisfy both conditions (§9). This is defect R2 in its structural form. |
| A8 | Pure quadratic (non-Huber) penalty on $r$ | Unbounded derivative, so no uniform bound on the displacement (6.1) and no protection against a large pull at extreme $r$. The Huber's $|D'|\le1$ is load-bearing, not decorative. |

---

## 13. What S3 must measure

The derivation is only worth having if it can be killed. This section converts it into
pre-registerable, falsifiable predictions. **All statements below are predictions, not claims.**

### 13.1 The two properties whose failure kills the derivation

**K1 — exact scale equivariance under $y$-rescaling.** Fit $y$, then $c\,y$ for
$c\in\{10^{-2},10^{2}\}$, back-scale, and require agreement in $\hat\sigma_u$, $\hat\sigma$, and
both profile endpoints to optimiser tolerance (target: relative difference $<10^{-6}$). This is a
*theorem* (Theorem 1(b) + eq. 2.1), so a failure is either an implementation bug or an error in
§3.2. It is a hard gate: run it before any campaign compute is requested, per Fisher's PRT-1. It
must also be a unit test shipped with S2, not only a campaign check.

**K2 — the sign-flip point tracks the residual scale, not the unit.** The derivation predicts that
the penalty's bias contribution changes sign at $r=0$, i.e. at $\sigma_u = s$. Test by running the
sd-ladder at **two residual scales**, $\sigma\in\{0.7,\,2.1\}$: the flip point must move with
$\sigma$, from $\sigma_u\approx0.7$ to $\sigma_u\approx2.1$. If the flip point does not move, the
anchor is not doing what §4 says it does and the repair is void regardless of any coverage number.
*(This cell — a second residual scale — does not exist in the D-117 grid and must be added. It is
the cell that discriminates the derivation from its alternative, so it is not optional.)*

### 13.2 Predictions on the ladder

Grid, following the packet §6 S3 row and Fisher §3, with the K2 addition:
$\sigma_u\in\{0,\,0.25,\,0.5,\,1,\,2,\,4\}$ × $g\in\{5,10,25,40\}$ × $n_{\mathrm{per}}\in\{4,10\}$
× $\sigma\in\{0.7,2.1\}$, paired seeds, arms ML / REML / penalised.

**P1 — where it should help.** Below the anchor ($r<0$, i.e. $\sigma_u<\sigma$) and at small $g$:
the largest predicted effect is at $g=5$–$10$, $\sigma_u\le0.5\sigma$. Magnitude is capped by §6.3's
table: at most $0.90$ SE at $g=5$, $0.45$ SE at $g=10$, $0.18$ SE at $g=25$ for $\sigma_u=0.25$.

**P2 — where it should not hurt.** At $g=40$ the penalised and ML arms should agree on pooled
coverage to within Monte Carlo error, because $\delta_g\le0.11$ SE there. A material difference at
$g=40$ falsifies the softness constant (6.3), not merely its calibration.

**P3 — behaviour at true $\sigma_u=0$, with a predicted size class.** Repeating the §6.2
calculation with strength $c_g\kappa_-$: at a replicate where the ML estimate is at the boundary,
the penalised estimate sits at

$$
\hat\sigma_u \;=\; \widehat{\mathrm{se}}\bigl(\hat\sigma_u^{\mathrm{ML}}\bigr)\cdot\sqrt{c_g\,\kappa_-}\,,
\qquad\text{i.e. a displacement of }\sqrt{c_g\kappa_-}\text{ standard errors},
$$

giving, at $\kappa_-=1$: **$0.95$ SE at $g=5$, $0.80$ SE at $g=10$, $0.63$ SE at $g=25$,
$0.56$ SE at $g=40$** — decaying only as $g^{-1/4}$. Chung's undecayed $\alpha=2$ sits at exactly
$1.00$ SE at every $g$, so this construction is predicted to displace **60–95% as far as `blme`
does**, and to keep doing so at every $g$.
*Predicted size class at true $\sigma_u=0$:* over-coverage of a few percentage points above nominal
(predict the 0.96–0.99 band, not 0.999), with interval-width inflation in the low tens of percent at
$g=5$ and single digits at $g\ge10$ — scaled down from Chung's measured +60% at $J=3$ / +30% at
$J=5$ under his *stronger* $\alpha=3$ (Ranga §2). If measured over-coverage at true zero exceeds
0.99, the constant is too strong and (6.3) needs recalibration inside the $o(\sqrt g)$ class.

**P4 — the boundary flag is deleted at every $g$, and this is not a repair.** Because the
displacement is strictly positive for all finite $g$, a penalised profile never reaches zero and
`profile.boundary` reads $\approx0\%$ at every cell. This is structural and softness does not cure
it. **Therefore Fisher's scoring rule is mandatory and not negotiable: conditional coverage must be
computed on the ML-defined boundary subset via paired seeds.** Scoring the penalised arm on its own
boundary flag is guaranteed to report a repair that the derivation says cannot be there.

**P5 — the falsifier, restated from Fisher §3.** If the penalised arm's conditional coverage on the
ML-defined boundary subset does not beat REML's measured $0.828$, the penalty relabels rather than
repairs and the arc stops.

**P6 — model selection is unharmed (secondary).** With $c_g\to0$, AIC/BIC comparison between an
RE and a no-RE model should be indistinguishable from ML at $g\ge25$. This is the R4 check; a
failure would indicate the decay is not operating as (6.3) says.

### 13.3 Arms on the shape

Pre-register $\kappa_-\in\{1,2\}$ (shipped shape vs the Chung $\alpha=3$ analogue, which the one
published tuning study found better for coverage than for bias) and one asymmetric arm
$\kappa_+ = 0.25\,\kappa_-$, which the derivation predicts will preserve the lower-boundary
behaviour while shrinking the upper-side bias that Fisher measured. Freeze the recovery statistic
in advance: `VERDICT-100K.md:171-190` records that statistic choice alone spans $-0.12$ to $-0.77$
on identical data.

---

## 14. REML composite: deferred

The hard reject of `REML = TRUE` together with a penalty (`R/drmTMB.R:372-378`;
`R/mspl-estimator.R:212-214`; `tests/testthat/test-reml-penalty-guard.R`) remains the
mathematically defensible position and this document does not attempt to relax it. The reason is
now sharper than "different estimators". First, $c_g$ was derived in §6 against a specific
quantity — the ML efficient information $I_g = 2g\Phi$ of §5 — and REML maximises a different
criterion whose curvature in $a$ is not that quantity; the degrees-of-freedom correction alone
changes the leading term, and nothing in §6 survives the substitution without being redone.
Second, and more seriously, the composite (9.1) contains a fixed-effect Jeffreys term $P_f(\beta)$
which is a function of $\beta$ — but REML integrates $\beta$ out rather than estimating it as a free
parameter, so the composite objective is not even well-posed in the REML criterion without deciding
what $P_f$ means there. No such derivation exists in this repository or in any source in the
programme's literature sweep. **The reject stands; relaxing it is a separate derivation slice, not
a flag to flip.**

---

## Provenance and negative space

**Repository facts** are cited to file:line and were read in
`.worktrees/mspl-s0s1` at branch `claude/mspl-boundary-s0-s1`: `src/drmTMB.cpp:77-85` (negative
Huber), `:5003-5016` (Jeffreys term), `:5018-5046` (composition and $c_n$ application),
`:87-125` (the PC-prior phylo penalty), `R/mspl.R:112-128` ($c_n$), `:247-256` (the R-side Huber),
`R/penalty.R:1-90` (`drm_phylo_penalty`), `docs/design/250-mspl-binomial-logit-alignment.md`.

**Borrowed results** are cited to the source review that carries them: the (E1)–(E3) + rate
template and the AIC/BIC warning to
[Ranga §1, §5](../dev-log/research/2026-08-16-mspl-transfer-ranga-literature.md) quoting
Sterzinger, Kosmidis & Moustaki 2026 (*Psychometrika* 91:494–507); Chung et al. 2013's Property 1,
the $\alpha=2$/$\alpha=3$ split, the width costs and the null over-coverage to Ranga §2; `blme`'s
one-sided failure to Ranga §4; the anchor measurement and the ML-boundary scoring rule to
[Fisher §0, §1](../dev-log/research/2026-08-16-mspl-transfer-fisher-verdict.md); the growth
condition, the Jeffreys category error and the $c_n$-rate risk to
[Noether §1, §4, §5](../dev-log/research/2026-08-16-mspl-transfer-noether-math.md).

**Derived here, not borrowed:** Theorem 1 and its corollaries (§3.2–3.3); the equivariance-weight
family classification (§4.2); the moving-anchor analysis (§4.3); Proposition 2 and the closed-form
$I_g$ (§5); the displacement principle and $c_g$ (§6); Condition COMP (§9.2); the Košuta
equivariance derivation and the $q=1$ degeneracy (§11.2); all predictions in §13.

**Numerically verified:** the closed forms (5.1) against numerical differentiation of the expected
information over a 168-point grid (max relative error $1.5\times10^{-10}$; Proposition 2's bound
respected at every point). Script in the session scratchpad; **not committed and not a package
test** — S2 must re-express the check as a shipped unit test.

**UNVERIFIED ledger.**

| claim | status | why |
| --- | --- | --- |
| Košuta et al. 2026 Web Appendices A–I (exact $\eta_i$ construction, Wishart-on-precision variant, proofs, full simulation tables) | UNVERIFIED | OUP supplementary material not fetched; main text only. |
| The $q=1$ degeneracy of Košuta's shrinkage target (§11.2b) | AGENT-INFERRED | Follows from the main-text description of shrinking eigenvalues toward their mean; Web Appendix B.II could differ. Treat as a lead. |
| Košuta's penalty is exactly scale-equivariant (§11.2a) | derived here, not stated in the paper | Algebra shown in full; the paper does not discuss equivariance anywhere in the main text. |
| The family→link→equivariance-weight table (§4.2) | PARTIALLY VERIFIED | Links read from `R/drmTMB.R:69-73` documentation, not from the family constructors in `R/family.R`. S2 must confirm each row. |
| Sterzinger, Kosmidis & Moustaki 2026 conditions as stated | second-hand | Read through Ranga's verbatim quotation of the ingested text, not from the primary PDF in this session. |
| Every performance number in §13 | PREDICTION | Derived from the algebra above and from Chung's measured analogues. Nothing in §13 has been measured in drmTMB. |

**What this document does NOT do.** It changes no code, adds no argument, touches no release
surface, and makes no capability claim. It does not treat: REML composites (§14); bivariate or
structured random-effect blocks; predictor-scale equivariance for random slopes (§10); the full q2
correlation information calculation (§10); heritability/ratio targets (programme slice S4); the
interval machinery a penalised profile would need — Fisher §1d records that `confint`, `profile`,
`logLik`, `anova` and `summary(conf.int = TRUE)` all abort on an MSPL fit today, and nothing here
changes that. Any interval reported in S3 must come from a reference distribution that is itself
derived, not assumed.

---

## Sign-off — the S1 gate

This derivation is not accepted until both boxes below are checked by a reviewer who did not write
it.

- [ ] **Noether independent re-check.** Theorem 1's proof (including the Cauchy step and the (E2)
      argument), the closed-form $I_g$ and Proposition 2 re-derived independently, the $c_g$ rate
      argument, the §8 condition-by-condition verification, and Condition COMP.
- [ ] **Fisher inference re-check.** Whether §13's predictions are genuinely falsifiable as stated,
      whether K1/K2 are the right killers, whether P3's size class is defensible, and whether the
      ML-defined-boundary scoring rule (P4) is correctly binding on the campaign design.

**S2 (implementation) must not start before both boxes are checked.** A penalty written before the
derivation is accepted would repeat, with a more plausible-looking lever, exactly the sequence the
transfer packet was convened to prevent.

> Related: design 250 (MSPL binomial alignment) · design 251 (MSPL Wald covariance) ·
> design 218/219 (the bias-correction wall) ·
> [`…-drmtmb-mspl-transfer-packet.md`](../dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md) §6 (the five-slice programme) ·
> `…/2026-08-15-d117-reml-arm/VERDICT.md` · `…/2026-08-05-d117-chibar-cutoff-arm/VERDICT.md`
