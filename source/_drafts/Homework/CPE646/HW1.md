---
title: HW1
category:
  - Homework
tag:
  - Homework
abbrlink: 636276419
date: 2018-02-09 14:47:41
---

ID: 10427009
Name: Jiaxu Duan

#### Problem 1
##### 1.1 Calculate the likelihood value for each class if x=5.
\begin{gather}
\because p(x|\omega\_1) \sim N(0, 1)  \\\\
\therefore p(x|\omega\_1) = \frac{1}{\sqrt{2\pi} } e^{-\frac{1}{2} x^2} \\\\
\because p(x|\omega\_2) \sim N(2, 4) \\\\
\therefore p(x|\omega\_2) = \frac{1}{4\sqrt{2\pi} } e^{-\frac{1}{2} (\frac{x-2}{4})^2} \\\\
\text{if x is 5, then} \\\\[2ex]
p(x|\omega\_1) = \frac{1}{\sqrt{2\pi} } e^{-\frac{1}{2} 5^2} = 1.49 \times 10^{-6} \\\\
p(x|\omega\_2) = \frac{1}{4\sqrt{2\pi} } e^{-\frac{1}{2} (\frac{5-2}{4})^2} = 7.528 \times 10^{-2}
\end{gather}

##### 1.2 Calculate the evidence value if x=5
\begin{gather}
\because p(x) = \sum\_{i=1}^{n}p(x|\omega\_i)P(\omega\_i) \\\\
And, \quad P(\omega\_1) = \frac{3}{5}, P(\omega\_2) = \frac{2}{5} \\\\
\therefore p(x) = p(x|\omega\_1)P(\omega\_1) + p(x|\omega\_2)P(\omega\_2) = 3.01 \times 10^{-2}
\end{gather}

##### 1.3 Calculate the posterior probability value for each class if x=5.
\begin{gather}
\because p(\omega\_i|x) = \frac{p(x|\omega\_i) \cdot p(\omega\_i)}{p(x)} \\\\
\therefore p(\omega\_1|x) = \frac{p(x|\omega\_1) \cdot p(\omega\_1)}{p(x)} = 3.44 \times 10^{-5} \\\\
p(\omega\_2|x) = \frac{p(x|\omega\_2) \cdot p(\omega\_2)}{p(x)} = 1.000
\end{gather}

##### 1.4 Calculate the likelihood ratio value if x=5
\begin{gather}
\because \text{likelihood ratio is } \frac{p(x|\omega\_1)}{p(x|\omega\_2)} \\\\
\therefore \frac{p(x|\omega\_1)}{p(x|\omega\_2)} = \frac{3.44 \times 10^{-5}}{1.00} = 3.44 \times 10^{-5}
\end{gather}

##### 1.5 Calculate the likelihood ratio threshold for zero-one loss function
\begin{gather}
\because \theta\_\lambda = \frac{P(\omega\_2)}{P(\omega\_1)} \\\\
\therefore \theta\_\lambda = \frac{0.4}{0.6} = \frac{2}{3}
\end{gather}

##### 1.6 Calculate the likelihood ratio threshold for the following risk matrix
\begin{gather}
\because \text{likelihood ratio threshold is } \frac{\lambda\_{12} - \lambda\_{22}}{\lambda\_{21} - \lambda\_{11}} \cdot \frac{P(\omega\_2)}{P(\omega\_2)} \\\\
\therefore \text{the likelihood ratio threshold is } \frac{4 - 0}{2 - 0} \cdot \frac{0.4}{0.6} = \frac{4}{3}
\end{gather}

##### 1.7 Calculate the Bayes risk value if x=5.
\begin{gather}
\because R(\alpha\_i|x) = \sum\_{i=1}^{n} \lambda(\alpha\_i|\omega\_i)P(\omega\_i|x) \\\\
\therefore R(\alpha\_1|x) = \lambda\_{11}P(\omega\_1|x) + \lambda\_{12}P(\omega\_2|x) = 0 + 4 \times gauss(2,4,5) = 0.301, \\\\ 
R(\alpha\_2|x) = \lambda\_{21}P(\omega\_1|x) + \lambda\_{22}P(\omega\_2|x) = 2 \times gauss(0,1,5) + 0 = 2.98 \times 10^{-6}
\end{gather}




#### Problem 2
##### 2.1 Calculate the decision boundary
This is the `case 3`: $\sum\_i = arbitrary$
\begin{gather}
\because g\_i (x) = x^t W\_i x + w\_i^t x + w\_{i0}, \quad W\_i = - \frac{1}{2} \sum\nolimits\_i^{-1}, \quad w\_i = \sum\nolimits\_i^{-1} \mu\_i \\\\
w\_{i0} = -\frac{1}{2} \mu\_i^t \sum\nolimits\_i^{-1} \mu\_i - \frac{1}{2} \ln{\left| \sum\nolimits\_i \right|} + \ln{P(\omega\_i)}
\end{gather}

$$ 
\therefore \sum\nolimits\_1^{-1} = \frac{1}{2} \cdot \begin{bmatrix} 2 & 0 \\\\ 0 & 1 \\\\ \end{bmatrix} = \begin{bmatrix} 1 & 0 \\\\ 0 & \frac{1}{2} \\\\ \end{bmatrix}, \quad \sum\nolimits\_2^{-1} = \frac{1}{2 - 1} \cdot \begin{bmatrix} 2 & 1 \\\\ 1 & 1 \\\\ \end{bmatrix} = \begin{bmatrix} 2 & 1 \\\\ 1 & 1 \\\\ \end{bmatrix} 
$$

$$
W\_1 = - \frac{1}{2} \cdot \begin{bmatrix} 1 & 0 \\\\ 0 & \frac{1}{2} \\\\ \end{bmatrix} = \begin{bmatrix} -\frac{1}{2} & 0 \\\\ 0 & -\frac{1}{4} \\\\ \end{bmatrix}, \quad W\_2 = - \frac{1}{2} \cdot \begin{bmatrix} 2 & 1 \\\\ 1 & 1 \\\\ \end{bmatrix} = \begin{bmatrix} -1 & -\frac{1}{2} \\\\ -\frac{1}{2} & -\frac{1}{2} \\\\ \end{bmatrix}
$$

$$
w\_1 = \begin{bmatrix} -\frac{1}{2} & 0 \\\\ 0 & -\frac{1}{4} \\\\ \end{bmatrix} \cdot  \begin{bmatrix} 0 \\\\ 0 \\\\ \end{bmatrix} = \begin{bmatrix} 0 \\\\ 0 \\\\ \end{bmatrix}, \quad
w\_2 = \begin{bmatrix} 2 & -1 \\\\ -1 & 1 \\\\ \end{bmatrix} \cdot \begin{bmatrix} 2 \\\\ 2 \\\\ \end{bmatrix} = \begin{bmatrix} 2 \\\\ 0 \\\\ \end{bmatrix}
$$

$$
w\_{10} = 0 -\frac{1}{2} \ln{2} + \ln{\frac{1}{4}} = -0.5 \times 0.693 + -1.386 = -1.7325 \\\\
w\_{20} = -2 -\frac{1}{2} \ln{1} + \ln{\frac{3}{4}} = -2 +0 - 0.288 = -2.288
$$

$$
\text{When $g\_1 (x) = g\_2 (x)$ :} \\\\
\begin{bmatrix} x\_1 & x\_2 \\\\ \end{bmatrix} \begin{bmatrix} -\frac{1}{2} & 0 \\\\ 0 & -\frac{1}{4} \\\\ \end{bmatrix} \begin{bmatrix} x\_1 \\\\ x\_2 \\\\ \end{bmatrix} + \begin{bmatrix} 0 & 0 \\\\ \end{bmatrix} \begin{bmatrix} x\_1 \\\\ x\_2 \\\\ \end{bmatrix} - 1.7325 = \begin{bmatrix} x\_1 & x\_2 \\\\ \end{bmatrix} \begin{bmatrix} -1 & \frac{1}{2} \\\\ \frac{1}{2} & -\frac{1}{2} \\\\ \end{bmatrix} \begin{bmatrix} x\_1 \\\\ x\_2 \\\\ \end{bmatrix} + \begin{bmatrix} 2 & 0 \\\\ \end{bmatrix} \begin{bmatrix} x\_1 \\\\ x\_2 \\\\ \end{bmatrix} - 2.288 \\\\
-\frac{1}{2} x\_{1}^{2} - \frac{1}{4} x\_{2}^{2} - 1.7325 = -x\_{1}^{2} - \frac{1}{2} x\_{2}^{2} + x\_{1}x\_{2} + 2x\_{1} - 2.288 \\\\
\frac{1}{2}x\_{1}^{2} + \frac{1}{4}x\_{2}^{2} - x\_{1}x\_{2} - 2x\_{1} + 0.5555 = 0
$$

##### 2.2 Calculate the Bhattacharyya error bound
$$
\because k(\beta) = \frac{\beta(1-\beta)}{2} (\mu\_2-\mu\_1)^t [\beta\sum\_1 + (1-\beta)\sum\_2]^{-1} (\mu\_2-\mu\_1) + \frac{1}{2} \ln{\frac{|\beta \sum\_1 + (1-\beta)\sum\_2|}{|\sum\_1|^{\beta} |\sum\_2|^{1-\beta}}} \\\\
And \quad \beta = \frac{1}{2}
$$

$$
\therefore k(\frac{1}{2}) = \frac{1}{8}  \begin{bmatrix} 2 & 2 \\\\ \end{bmatrix}  \begin{bmatrix} 1 & \frac{1}{2} \\\\ \frac{1}{2} & 2 \end{bmatrix}^{-1} \begin{bmatrix} 2 \\\\ 2 \\\\ \end{bmatrix} + \frac{1}{2} \ln{\frac{\frac{7}{4}}{\sqrt{2} \sqrt{1}}} \\\\
= \frac{4}{7} + 0.6167 = 1.1901
$$
