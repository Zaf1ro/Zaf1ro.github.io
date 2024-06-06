---
title: Plus One
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: 2229123694
date: 2018-02-23 01:22:17
---

## 1. Description
Given a non-negative integer represented as a non-empty array of digits, plus one to the integer.
You may assume the integer do not contain any leading zero, except the number 0 itself.
The digits are stored such that the most significant digit is at the head of the list.



## 2. Solution
思路: 由于只加1, 所以数值上每一位的处理分两种情况:
1. 数值的位为9, 进位
2. 数值的位不为9, 加1后退出

```java
class Solution {
  public int[] plusOne(int[] digits) {
    if (digits == null) return digits;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (digits[i] == 9) {
        digits[i] = 0;
      } else {
        digits[i]++;    /* the digit is not 9, so add 1 and return the result */
        return digits;
      }
    }
    int[] res = new int[digits.length + 1]; /* the digits is 999 or others */
    res[0] = 1;
    return res;
  }
}
```
