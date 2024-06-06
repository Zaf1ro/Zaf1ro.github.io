---
title: Palindrome Number
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: 2987848299
date: 2018-02-07 15:49:22
---

## 1. Description
Determine whether an integer is a palindrome. Do this without extra space.

## 2. Compare reverse number
思路: 首先x为负值时, 直接返回false. 如果x为非负值, 则反转x得到y, 对比x和y. 这里并不需要考虑反转值溢出的情况, 因为一旦发生溢出, 说明x不为反转值. 简而言之:
$$ 不存在一个x值, 其反转值y溢出int范围, 且x为\text{palindrome number} $$

Time Complexity: $O(n)$
Space Complexity: $O(1)$

```java
class Solution {
  public boolean isPalindrome(int x) {
    if (x < 0) return false;
    int tmp = x;
    int rev = 0;
    while (tmp > 0) {
      rev = rev * 10 + tmp % 10;
      tmp /= 10;
    }
    return x == rev;
  }
}
```



## 3. Revised Solution
思路: 上述解法虽然简单, 但是需要创建x的整个反转值. 其实只要建立半个反转值即可. 但是有以下几个特殊情况需要考虑
* x < 0: 返回false
* x % 10 == 0: 返回false
* x == 0: 返回true
* 其他情况下对比half和x

Time Complexity: $O(n)$
Space Complexity: $O(1)$

```java
class Solution {
  public boolean isPalindrome(int x) {
    if (x < 0 || (x > 0 && x % 10 == 0)) return false;
    int half = 0;
    while (x > half) {
      half = half * 10 + x % 10;
      x /= 10;
    }
    return (x == half || x == half / 10);
  }
}
```
