---
title: Reverse Integer
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: 122f
date: 2022-06-12 14:05:34
keywords:
description:
---

## 7. Reverse Integer
### 1. Description
Given a signed 32-bit integer `x`, return `x` with its digits reversed. If reversing `x` causes the value to go outside the signed 32-bit integer range `$[-2^{31}, 2^{31} - 1]$`, then return `0`.

Assume the environment does not allow you to store 64-bit integers (signed or unsigned).

Example:
```
Input: x = 123
Output: 321
```

### 2. Solution
```java
class Solution {
    public int reverse(int x) {
        int res = 0, prev = 0;
        while (x != 0) {
            res = res * 10 + x % 10;
            x /= 10;
            if (res / 10 != prev) return 0;
            prev = res;
        }
        return res;
    }
}
```
