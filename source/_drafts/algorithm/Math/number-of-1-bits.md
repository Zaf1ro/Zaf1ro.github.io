---
title: Number of 1 bits
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: 3682875956
date: 2018-01-18 09:08:20
---

## 1. Description
Write a function that takes an unsigned integer and returns the number of ’1' bits it has. For example, the 32-bit integer ’11' has binary representation 00000000000000000000000000001011, so the function should return 3.
```java
class Solution {
  public int hammingWeight(int n) {}
}
```



## 2. 问题点
位运算计算每一位是否为1
```java
class Solution {
  public int hammingWeight(int n) {
    int res = 0;
    while (n != 0) {
      if ((n & 0x1) == 1) res++;
      n >>= 1;  // 不断的右移n
    }
    return res;
  }
}
```



## 3. 可能产生的问题
1. 上述解决方案只能针对 n > 0 的情况, 当 n < 0 时可能会陷入死循环. 因为负数的右移操作是带符号右移, 最终数字会变为0xFFFFFFFF
2. 解决方案:
* 使用一个unsigned int值不断对比n, 并左移该值(Java并不提供unsigned int, 可使用C++)
```java
class Solution {
  public int hammingWeight(int n) {
    int res = 0;
    int tmp = 1;

    // 由于没有unsigned int, 所以tmp最后会变为Integer.MIN_VALUE
    while (tmp == Integer.MIN_VALUE || tmp > 0) {
      if ((n & tmp) != 0) res++;   // 对比n和tmp
      tmp <<= 1;          // 不断左移
    }
    return res;
  }
}
```
* Java提供了>>>(无符号右移), 可直接右移负数
```java
class Solution {
  public int hammingWeight(int n) {
    int res = 0;
    while(n != 0){
      if((n & 0x1) == 1) res++;
      n >>>= 1;     // 无符号右移
    }
    return res;
  }
}
```



## 4. 提高效率
虽然上述代码的时间复杂度为O(1), 但无论n的值为多少, 都需要进行32次运算, 很多次运算都是无用的.
解决方案: n & (n - 1) 可去除n的最右侧的二进制1, 不断的循环删除n中的1直到n变为0.
可能的问题: 虽然循环的次数减少, 但n - 1为算术操作, 比位运算速度慢得多.
```java
class Solution {
  public int hammingWeight(int n) {
    int res = 0;
    while (n != 0) {
      ++res;
      n = n & (n - 1);  // 去除n的二进制中的最右侧1
    }
    return res;
  }
}
```



## 5. 相关问题
1. Given an integer, write a function to determine if it is a power of two.
问题分析: 
* 首先 n <= 0 时必不为2的整数次方
* 其次, 当 n & (n - 1) 不为0时, 说明n中有两个或两个以上的1, 说明不为2的整数次方
* 剩下的情况则为2的整数次方

```java
class Solution {
  public boolean isPowerOfTwo(int n) {
    if (n <= 0) return false;
    return (n & (n - 1)) == 0;
  }
}
```

2. The Hamming distance between two integers is the number of positions at which the corresponding bits are different. Given two integers x and y, calculate the Hamming distance. For example: x = 1(0001), y = 4(0100), then return 2
问题分析:
* x & y 即可得到位不相同的数字
* 统计得到的数字中1的个数

```java
class Solution {
  public int hammingDistance(int x, int y) {
    int tmp = x ^ y;
    int res = 0;
    while (tmp != 0) {
      if ((tmp & 0x1) == 1) ++res;
      tmp >>>= 1;
    }
    return res;
  }
}
```
