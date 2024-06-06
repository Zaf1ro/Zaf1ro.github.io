---
title: Sqrt(x)
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: b4f3
date: 2018-01-21 10:26:05
---

## 69. Sqrt(x)
### 1. Description
Implement int sqrt(int x).
Compute and return the square root of x.
x is guaranteed to be a non-negative integer.

### 2. 二分法
x的开平方结果一定在[1, x]范围内, 所以可用二分法不断缩减搜索范围
```java
class Solution {
  public int mySqrt(int x) {
    if (x == 0) return 0;
    int left = 1;
    int right = x;
    int res = 1;
    while (left < right) {
      int mid = left + ((right - left) >> 1);
      if (mid <= x / mid) {
        left = mid + 1;
        res = left;
      } else {
        right = mid - 1;
      }
    }
    return res;
  }
}
```

### 3. 牛顿迭代法
一种在实数域和复数域上近似求解方程的方法, 可用于此题的求解

#### 3.1 理论
假设需要求解的方程为 $f(x) = 0$
首先找到一个接近 $f(x) = 0$ 解的值 $x\_0$, 计算对应的 $f(x\_0)$ 的切线斜率 $f^{\prime}(x\_0)$ . 这样就可以得到 $\left( x\_0, f(x\_0) \right)$ 且斜率为 $f^{\prime}(x\_0)$ 的直线与x轴的交点, 记为 $x\_1$, 并依次迭代. 公式如下:
$$ 0 = (x\_{n+1} - x\_n) \cdot f^{\prime}(x\_n) + f(x\_n) $$
此公式还可以简化为以下公式:
$$ x\_{n+1} = x\_n - \frac{x\_n}{f^{\prime}(x\_n)} $$
 
通过不断的计算切线和x轴的交点得到的 $x\_n$ 会不断接近 $f(x) = 0$ 的解. 如下图所示:
 
![Newton Iteration Analysis](/images/Algorithm/Newton_Iteration.gif)

#### 3.2 代码
对于此题来说, 公式如下:
\begin{gather}
\sqrt{c} \text{ is equal to } x^2 = c, x^2 - c = 0 \\\\[2ex]
\because \quad x\_{n+1} = x\_n - \frac{x\_{n}^{2} - c}{(x\_{n}^{2} - c)^{\prime}} \\\\
\therefore \quad x\_{n+1} = x\_{n} - \frac{x\_{n}^{2} - c}{2x\_n} \\\\
\therefore \quad x\_{n+1} = \frac{1}{2} \cdot \left( x\_n + \frac{c}{x\_n} \right){}
\end{gather}
 
```java
class Solution {
  public int mySqrt(int x) {
    long r = x;
    while (r * r > x)
      r = (r + x / r) / 2;
    return (int)r;
  }
}
```
