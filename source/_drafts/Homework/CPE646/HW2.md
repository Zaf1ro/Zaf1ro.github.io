---
title: HW2
category:
  - Homework
tag:
  - Homework
abbrlink: 3169165177
date: 2018-03-02 09:20:14
---

#### Problem 1
##### 1.1 Calculate the maximum likelihood estimation of parameter $\theta$
$$
p(x | \theta) = 
\begin{cases}
2 \theta x e^{- \theta x^2}, x \ge 0 \\\\[2ex]
0, otherwise    \\\\
\end{cases}
$$

The Likelihond function of this sample is:
$$
\begin{gather}
L = \prod\_{i=1}^n p(x | \theta) = \prod\_{i=1}^n 2 \theta x\_i e^{- \theta x\_i^2} \\\\
L = (2\theta)^n \cdot \prod\_{i=1}^n x\_i \cdot e^{ \sum\_{i=1}^{n}(-\theta x\_i^2)} 
\end{gather}
$$

Take logarithms on both sides:
$$
\begin{gather}
\log{L} = \log((2\theta)^n \cdot \prod\_{i=1}^n x\_i) + \sum\_{i=1}^{n}-\theta x\_i^2 = \\\\
\log((2\theta)^n) + \log(\prod\_{i=1}^n x\_i) + \sum\_{i=1}^{n}-\theta x\_i^2 = \\\\
n\log(2\theta) + \log(\prod\_{i=1}^n x\_i) + \sum\_{i=1}^{n}-\theta x\_i^2
\end{gather}
$$

The likelihond equation is 
$$
\begin{gather}
\because \frac{\partial{\log{L}}}{\partial{\theta}} = 0 \\\\
\therefore \frac{n}{2\theta} + \sum\_{i=1}^{n}-x\_i^2 = 0 \\\\
\therefore \theta = \frac{n}{2 \cdot \sum\_{i=1}^{n}x\_i^2}
\end{gather}
$$

##### 1.2 Calculate the Bayesian estimation of parameter $\theta$
we got the prior density for $\theta$ as a uniform distribution, let $D = {x\_1, x\_2, ... , x\_n}$, we have
$$
p(\theta | D) = \frac{p(D|\theta)p(\theta)}{\int{p(D|\theta)p(\theta)d\theta}} = \frac{\prod\_{k=1}{n}p(x\_k | \theta)p(\theta)}{\int{p(D|\theta)p(\theta)d\theta}}
$$
where $\int{p(D|\theta)p(\theta)d\theta}$ represents a normalization factor dependent of $\theta$. also we have 
$$
p(x|\theta) = 2\theta x e^{-\theta x^2}, x \ge 0 \\\\
p(\theta) = \frac{1}{\lambda}, 0 \le \theta \le \lambda
$$

So we got
$$
p(\mu | D) = \prod\_{x = 0}^{\lambda} \frac{2}{\lambda} \theta x e^{- \theta x^2} 
$$




#### Problem 2 
##### 2.1 Calculate the PCA transform vector e for $D=(D1, D2)$, and the project of each data sample $\tilde{x}\_k$
$$
\because m = \frac{1}{n}\sum\_{k=1}^{n}x\_k \\\\
\therefore m = 
\begin{bmatrix} 1 \\\\ \frac{1}{2} \\\\ \end{bmatrix} \\\\
$$
After subtract $m$, 
$$
D1 = 
\begin{Bmatrix}
\begin{bmatrix} 0 \\\\ \frac{3}{2} \\\\ \end{bmatrix}, 
\begin{bmatrix} -4 \\\\ -\frac{3}{2} \\\\ \end{bmatrix}, 
\begin{bmatrix} 3 \\\\ \frac{9}{2} \\\\ \end{bmatrix}, 
\begin{bmatrix} -2 \\\\ \frac{1}{2} \\\\ \end{bmatrix}
\end{Bmatrix} \\\\
$$

$$
D2 = 
\begin{Bmatrix}
\begin{bmatrix} -1 \\\\ -\frac{5}{2} \\\\ \end{bmatrix}, \begin{bmatrix} 4 \\\\ \frac{3}{2} \\\\ \end{bmatrix}, \begin{bmatrix} -2 \\\\ -\frac{9}{2} \\\\ \end{bmatrix}, \begin{bmatrix} -2 \\\\ \frac{1}{2} \\\\ \end{bmatrix}
\end{Bmatrix} \\\\
$$

then we can Calculate the covariance matrix
$$
\because S = \sum\_{k=1}^{n}(x\_k - m)(x\_k - m)^t \\\\
\therefore S = 
\begin{bmatrix} 0 & 0 \\\\ 0 & \frac{9}{4} \\\\ \end{bmatrix} + 
\begin{bmatrix} 16 & 6 \\\\ 6 & \frac{9}{4} \\\\ \end{bmatrix} + 
\begin{bmatrix} 9 & \frac{27}{2} \\\\ \frac{27}{2} & \frac{81}{4} \\\\ \end{bmatrix} + 
\begin{bmatrix} 4 & -1 \\\\ -1 & \frac{1}{4} \\\\ \end{bmatrix} + 
\begin{bmatrix} 9 & \frac{27}{2} \\\\ \frac{27}{2} & \frac{81}{4} \\\\ \end{bmatrix} + 
\begin{bmatrix} 1 & \frac{5}{2} \\\\ \frac{5}{2} & \frac{25}{4} \\\\ \end{bmatrix} + 
\begin{bmatrix} 16 & 6 \\\\ 6 & \frac{9}{4} \\\\ \end{bmatrix} + 
\begin{bmatrix} 4 & 9 \\\\ 9 & \frac{81}{4} \\\\ \end{bmatrix} + 
\begin{bmatrix} 4 & -1 \\\\ -1 & \frac{1}{4} \\\\ \end{bmatrix} \\\\
= \begin{bmatrix} 63 & 48.5 \\\\ 48.5 & 74.25 \\\\ \end{bmatrix} \\\\
$$

By using matlab, we can calculate the eigenvector and eigenvalue:
```matlab
>> A = [63,48.5;48.5,74.25]
A =
   63.0000   48.5000
   48.5000   74.2500

>> [d,v] = eig(A)
d =
   -0.7467    0.6651
    0.6651    0.7467

v =
   19.7999         0
         0  117.4501
```

so we can get the projection of all samples
$$
D1 =  
\begin{Bmatrix}
\begin{bmatrix} 0.5835 \\\\ 2.1586 \\\\ \end{bmatrix}, 
\begin{bmatrix} 1.5751 \\\\ -2.7421 \\\\ \end{bmatrix}, 
\begin{bmatrix} 0.3387 \\\\ 6.3942 \\\\ \end{bmatrix}, 
\begin{bmatrix} 1.4119 \\\\ 0.0816 \\\\ \end{bmatrix}
\end{Bmatrix} \\\\
$$

$$
D2 = 
\begin{Bmatrix}
\begin{bmatrix} -1.3303 \\\\ -1.4935 \\\\ \end{bmatrix}, 
\begin{bmatrix} -2.404 \\\\ 4.8191 \\\\ \end{bmatrix}, 
\begin{bmatrix} -1.9138 \\\\ -3.6520 \\\\ \end{bmatrix}, 
\begin{bmatrix} -1.5751 \\\\ 2.7421 \\\\ \end{bmatrix}
\end{Bmatrix} \\\\
$$

##### 2.2 Calculate the LDA transform vector w, and the project of each data sample
First we have to calculate the $m\_1, m\_2, S\_1, S\_2$
$$
m\_1 = \begin{bmatrix} \frac{1}{4} \\\\ \frac{7}{4} \\\\ \end{bmatrix} \\\\
m\_2 = \begin{bmatrix} \frac{7}{4} \\\\ -\frac{3}{4} \\\\ \end{bmatrix} \\\\
S\_1 = \begin{bmatrix} 26.75 & 22.25 \\\\ 22.25 & 18.75 \\\\ \end{bmatrix} \\\\
S\_2 = \begin{bmatrix} 22.75 & 26.375 \\\\ 26.375 & 34.75 \\\\ \end{bmatrix} \\\\
$$

So we got $S\_W$ and $S\_B$
$$
S\_W = S\_1 + S\_2 = \begin{bmatrix} 49.5 & 48.625 \\\\ 48.625 & 53.5 \\\\ \end{bmatrix} \\\\
S\_B = (m\_1 - m\_2) \* (m\_1 - m\_2)^t = \begin{bmatrix} 2.25 & -3.75 \\\\ -3.75 & 6.25 \\\\ \end{bmatrix} \\\\
$$

To maximize $J(w)$, must satisfy 
$$
S\_W^{-1} S\_B w = \lambda w \\\\
$$

By using Matlab, we can get $w$
```matlab
>> [d, v] = eig(S)
d =
   -0.8575    0.7161
   -0.5145   -0.6980

v =
    0         0
    0    2.7987
```

And we can calculate the project of each sample
$$
D1 = 
\begin{Bmatrix}
\begin{bmatrix} 0.5748 \\\\ -1.9104 \\\\ \end{bmatrix}, 
\begin{bmatrix} 1.8563 \\\\ 2.2414 \\\\ \end{bmatrix}, 
\begin{bmatrix} 0.1507 \\\\ -5.5478 \\\\ \end{bmatrix}, 
\begin{bmatrix} 1.5736 \\\\ -0.1835 \\\\ \end{bmatrix}
\end{Bmatrix} \\\\ 
D2 = 
\begin{Bmatrix}
\begin{bmatrix} -1.4323 \\\\ 1.3959 \\\\ \end{bmatrix}, 
\begin{bmatrix} -2.8552 \\\\ -3.9684 \\\\ \end{bmatrix}, 
\begin{bmatrix} -2.0071 \\\\ 3.3063 \\\\ \end{bmatrix}, 
\begin{bmatrix} -1.8563 \\\\ -2.2414 \\\\ \end{bmatrix}
\end{Bmatrix} \\\\ 
$$
