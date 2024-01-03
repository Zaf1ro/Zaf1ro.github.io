---
title: cos() and sin()
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: 27b4
date: 2018-03-12 13:29:10
---

## 1. 泰勒展开式
通过泰勒展开式获得sin(x)和cos(x)的多项式表达
$$
\because f(x) = f(a) + \frac{f'(a)}{1!}(x-a) + \frac{f^{(2)}(a)}{2!}(x-a)^2 + \cdots + \frac{f^{(n)}(a)}{n!}(x-a)^n \\\\
\therefore sin(x) = \frac{cos(0)}{1!} - \frac{cos(0)}{3!}x^3 + \frac{cos(0)}{5!}x^5 - \frac{cos(0)}{7!}x^7 + \frac{cos(0)}{9!}x^9 \cdots \\\\
= 1 - \frac{1}{3!}x^3 + \frac{1}{5!}x^5 - \frac{1}{7!}x^7 + \frac{1}{9!}x^9 \cdots \\\\
cos(x) = cos(0) + \frac{cos(0)}{2!}x^2 - \frac{cos(0)}{4!}x^4 + \frac{cos(0)}{6!}x^6 - \frac{cos(0)}{8!}x^8 \cdots \\\\
= 1 + \frac{1}{2!}x^2 - \frac{1}{4!}x^4 + \frac{1}{6!}x^6 - \frac{1}{8!}x^8 \cdots
$$



## 2. 缩小区间
在使用泰勒展开式前, 需要先缩减x的区间:
1. 利用周期性将x的范围缩减到$(-\pi, \pi]$
2. 利用奇偶性将x的范围缩减到$[0, \pi]$
3. 利用诱导公式将x的范围缩减到$[-\frac{\pi}{2}, \frac{\pi}{2}]$
4. 利用诱导公式将x的范围缩减到$[-\frac{\pi}{4}, \frac{\pi}{4}]$

诱导公式:
1. $sin(\pi + \alpha) = -sin \alpha$
2. $cos(\pi + \alpha) = -cos \alpha$
3. $sin(\frac{\pi}{2} - \alpha) = cos \alpha$
4. $cos(\frac{\pi}{2} - \alpha) = sin \alpha$



## 3. 代码
```java
private static final double PI = 3.14159265358979323846;

double sin(double x)
{
  double fl = 1;
  /* narrow the range to [-2pi, 2pi] */
  if (x > 2*PI || x < -2*PI) x -= (int)(x / (2*PI)) * 2*PI;
  
  /* narrow the range to [-pi, pi] */
  if (x > PI) x -= 2*PI;
  if (x < -PI) x += 2*PI;

  /* narrow the range to [-pi/2, pi/2] */
  if (x > PI/2) {
    x -= PI;
    fl *= -1;
  }
  if (x<-PI/2) {
    x += PI;
    fl *= -1;
  }

  /* narrow the range to [-pi/4, pi/4] */
  if (x > PI/4) 
    return cos(PI/2 - x);
  else 
    return fl * (x - pow(x, 3)/6 + pow(x, 5)/120 - pow(x, 7)/5040 + pow(x, 9)/362880);
}

double cos(double x)
{
  double fl = 1;
  if (x > 2*PI || x<-2*PI) x -= (int)(x/(2*PI)) * 2*PI;
  
  if (x > PI) x -= 2*PI;
  if (x < -PI) x += 2*PI;

  if (x > PI/2) {
    x -= PI;
    fl *= -1;
  }
  if (x<-PI/2) {
    x += PI;
    fl *= -1;
  }

  if (x > PI/4) 
    return sin(PI/2 - x);
  else 
    return fl*(1 - pow(x, 2)/2 + pow(x, 4)/24 - pow(x, 6)/720 + pow(x, 8)/40320);
}
```
