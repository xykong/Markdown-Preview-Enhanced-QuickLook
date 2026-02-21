# KaTeX Math Document (~15KB)

Tests KaTeX rendering performance for inline and block math expressions.

## Basic Algebra

Inline math: $ax^2 + bx + c = 0$ has solutions $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$.

The discriminant $\Delta = b^2 - 4ac$ determines the nature of roots:
- $\Delta > 0$: two distinct real roots
- $\Delta = 0$: one repeated real root  
- $\Delta < 0$: two complex conjugate roots

Block equation:

$$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$

## Calculus

**Fundamental Theorem of Calculus:**

$$\int_a^b f'(x)\,dx = f(b) - f(a)$$

**Taylor Series:**

$$f(x) = \sum_{n=0}^{\infty} \frac{f^{(n)}(a)}{n!}(x-a)^n$$

**Euler's Identity:**

$$e^{i\pi} + 1 = 0$$

**Cauchy Integral Formula:**

$$f(z_0) = \frac{1}{2\pi i} \oint_\gamma \frac{f(z)}{z - z_0}\,dz$$

**Fourier Transform:**

$$\hat{f}(\xi) = \int_{-\infty}^{\infty} f(x)\, e^{-2\pi i x \xi}\,dx$$

**Inverse Fourier Transform:**

$$f(x) = \int_{-\infty}^{\infty} \hat{f}(\xi)\, e^{2\pi i x \xi}\,d\xi$$

## Linear Algebra

**Matrix multiplication** $C = AB$ where $C_{ij} = \sum_k A_{ik} B_{kj}$:

$$\begin{pmatrix} a & b \\ c & d \end{pmatrix} \begin{pmatrix} e & f \\ g & h \end{pmatrix} = \begin{pmatrix} ae+bg & af+bh \\ ce+dg & cf+dh \end{pmatrix}$$

**Determinant** of a 3×3 matrix:

$$\det(A) = \begin{vmatrix} a & b & c \\ d & e & f \\ g & h & i \end{vmatrix} = a(ei-fh) - b(di-fg) + c(dh-eg)$$

**Eigenvalue equation:**

$$A\mathbf{v} = \lambda\mathbf{v}$$

The characteristic polynomial $\det(A - \lambda I) = 0$ yields eigenvalues $\lambda$.

**SVD Decomposition:**

$$A = U\Sigma V^T$$

Where $U \in \mathbb{R}^{m \times m}$, $\Sigma \in \mathbb{R}^{m \times n}$, $V \in \mathbb{R}^{n \times n}$.

## Probability and Statistics

**Bayes' Theorem:**

$$P(A \mid B) = \frac{P(B \mid A)\,P(A)}{P(B)}$$

**Normal Distribution PDF:**

$$f(x) = \frac{1}{\sigma\sqrt{2\pi}} e^{-\frac{1}{2}\left(\frac{x-\mu}{\sigma}\right)^2}$$

**Central Limit Theorem**: If $X_1, X_2, \ldots, X_n$ are i.i.d. with mean $\mu$ and variance $\sigma^2$, then:

$$\sqrt{n}\left(\bar{X}_n - \mu\right) \xrightarrow{d} \mathcal{N}(0, \sigma^2)$$

**Entropy** (Shannon):

$$H(X) = -\sum_{x} p(x) \log_2 p(x)$$

**KL Divergence:**

$$D_{KL}(P \| Q) = \sum_x P(x) \log\frac{P(x)}{Q(x)}$$

## Information Theory

**Channel Capacity** (Shannon-Hartley):

$$C = B \log_2\left(1 + \frac{S}{N}\right)$$

**Mutual Information:**

$$I(X; Y) = \sum_{x,y} p(x,y) \log\frac{p(x,y)}{p(x)p(y)}$$

## Physics

**Maxwell's Equations** (differential form):

$$\nabla \cdot \mathbf{E} = \frac{\rho}{\varepsilon_0}$$

$$\nabla \cdot \mathbf{B} = 0$$

$$\nabla \times \mathbf{E} = -\frac{\partial \mathbf{B}}{\partial t}$$

$$\nabla \times \mathbf{B} = \mu_0\left(\mathbf{J} + \varepsilon_0 \frac{\partial \mathbf{E}}{\partial t}\right)$$

**Schrödinger Equation:**

$$i\hbar \frac{\partial}{\partial t}\Psi(\mathbf{r},t) = \hat{H}\Psi(\mathbf{r},t)$$

**Einstein Field Equations:**

$$G_{\mu\nu} + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4} T_{\mu\nu}$$

**Lorentz Factor:**

$$\gamma = \frac{1}{\sqrt{1 - \frac{v^2}{c^2}}}$$

## Number Theory

**Euler's Totient Function** for prime $p$: $\varphi(p) = p - 1$

**Fermat's Little Theorem**: If $p$ is prime and $\gcd(a, p) = 1$:

$$a^{p-1} \equiv 1 \pmod{p}$$

**RSA**: Given public key $(n, e)$ and private key $(n, d)$:

$$c = m^e \bmod n \qquad m = c^d \bmod n$$

**Riemann Zeta Function:**

$$\zeta(s) = \sum_{n=1}^{\infty} \frac{1}{n^s} = \prod_{p \text{ prime}} \frac{1}{1-p^{-s}}$$

## Machine Learning

**Gradient Descent Update:**

$$\theta_{t+1} = \theta_t - \eta \nabla_\theta \mathcal{L}(\theta_t)$$

**Softmax Function:**

$$\text{softmax}(x_i) = \frac{e^{x_i}}{\sum_j e^{x_j}}$$

**Cross-Entropy Loss:**

$$\mathcal{L} = -\sum_i y_i \log(\hat{y}_i)$$

**Attention Mechanism** (Transformer):

$$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V$$

**Backpropagation** chain rule:

$$\frac{\partial \mathcal{L}}{\partial w} = \frac{\partial \mathcal{L}}{\partial a} \cdot \frac{\partial a}{\partial z} \cdot \frac{\partial z}{\partial w}$$
