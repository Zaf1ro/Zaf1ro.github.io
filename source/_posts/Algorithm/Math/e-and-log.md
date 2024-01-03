---
title: exp() and ln()
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: d42f
date: 2018-03-11 15:03:17
---

## 1. 以e为底的指数函数
考虑到exp(x)的定义域为整个实数域, 所以需要先对x进行分段:
* 整数段: 使用快速幂来求解
```java
/* 假设exp为正值且为整数值 */
public double pow1(double base, int exp) {
  double res = 1.0;
  while (exp > 0) {
    if ((exp & 0x1) == 1) res *= base;
    base *= base;
    exp >>= 1;
  }
  return res;
}
```
* 小数段: 使用泰勒展开式不断提高精度
```java
public double pow2(double exp) {
  if (exp > 1e-3) {
    double ee = pow2(exp / 2);
    return ee * ee;
  }
  return 1 + exp + exp*exp/2 + pow1(exp, 3)/6 + pow1(exp,4)/24 + pow1(exp,5)/120;
}
```

这里之所以用泰勒展开式求小数段e的次方, 是因为在泰勒展开式写作:
$$
g(x) = \sum\_{n=0}^\infty\frac{f^{(n)}(x\_0)}{n!}(x-x\_0)^n
$$
其中$\frac{d}{dx}(e^x) = e^x$, 而且$x\_0$为0, 所以$f(x) = exp(x)$时的泰勒展开式为
$$
g(x) = \sum\_{n=0}^\infty\frac{e^0}{n!}x^n = \sum\_{n=0}^\infty\frac{x^n}{n!} = 1 + x + \frac{x^2}{2} + \cdots + \frac{x^n}{n!} + \cdots
$$

由于我们无法计算无限项之和, 所以需要降低有限项之和的误差. 这里有两个方法:
1. 计算更多项n, 缺点在于$x^n$和$n!$的计算量变大
2. 由于$e^n = e^{\frac{n}{2}} * e^{\frac{n}{2}}$, 所以可通过计算$e^{\frac{n}{2}}$来降低误差, 因为这里求得是0到n的收敛, n越接近0则误差越小

最后是exp()函数的代码:
```java
public double exp(double exp) {
  double absExp = Math.abs(exp);
  double res = pow1(e, (int)absExp) * pow2(absExp - (int)absExp);
  return exp < 0 ? 1/res : res;
}
```



## 2. ln()
Java中的Math.log()也就是ln(), ln()可用辛普森积分公式来求结果. 以下是辛普森积分公式:
$$
\int\_a^bf(x)dx = \frac{b-a}{6}[ f(a) + 4f\left( \frac{a+b}{2} \right) + f(b)] \\\\
\because \int\_a^b\frac{1}{x}dx = \ln{|b|} - \ln{|a|}\\\\
\therefore \int\_1^b\frac{1}{x}dx = \ln{|b|}
$$
因此ln(x)可通过用辛普森积分公式求结果:
$$
\ln{n} = \int\_1^n\frac{1}{x}dx = \frac{n-1}{6}[ 1 + 4\frac{2}{1+n} + \frac{1}{n} ]
$$

```java
public double simpson(double a, double b) {
  return ((b - a)/6)*(1/a+4*(2/(a+b))+1/b);
}

public double helper(double a, double b) {
  double res = simpson(a, b);
  double mid = a + (b - a) / 2;
  double left = simpson(a, mid);
  double right = simpson(mid, b);
  if (Math.abs(right + left - res) > 1e-10)
    return helper(a, mid) + helper(mid, b);
  return left + right;
}

public double ln(double x) {
  return helper(1, x);
}
```



### 3. 拓展应用: 实数次方
由于$a^x = exp(x\ln{a})$, 所以$a^x$完全可以通过指数函数和对数函数实现
```java
public double powf(double a, double x) {
  return exp(x * ln(a));
}
```
