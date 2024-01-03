---
title: Happy Number
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: 5a0f
date: 2018-02-23 02:38:14
---

## 1. Description
Write an algorithm to determine if a number is "happy".
A happy number is a number defined by the following process: Starting with any positive integer, replace the number by the sum of the squares of its digits, and repeat the process until the number equals 1 (where it will stay), or it loops endlessly in a cycle which does not include 1. Those numbers for which this process ends in 1 are happy numbers.
Example: 19 is a happy number
```text
12 + 92 = 82
82 + 22 = 68
62 + 82 = 100
1 + 0 + 0 = 1
```



## 2. Solution
思路: 判断一个数是否为Happy Number很容易, 主要在于判断是否进入死循环. 可借鉴"链表是否有环"问题的思路, 设置slow和fast坐标来看两者是否会相同.
```java
class Solution {
  public int helper(int n) {
    int res = 0;
    while (n > 0) {
      res += (int)Math.pow(n % 10, 2);
      n /= 10;
    }
    return res;
  }

  public boolean isHappy(int n) {
    if (n == 1) return true;
    int slow = n, fast = n;
    do {
      fast = helper(helper(fast));
      slow = helper(slow);
      if (fast == 1 || slow == 1) return true;
    } while (slow != fast);
    return false;
  }
}
```
