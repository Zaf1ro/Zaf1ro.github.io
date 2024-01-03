---
title: Self Dividing Numbers
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: a41c
date: 2018-02-23 04:54:21
---

## 1. Description
A self-dividing number is a number that is divisible by every digit it contains.
For example, 128 is a self-dividing number because 128 % 1 == 0, 128 % 2 == 0, and 128 % 8 == 0.
Also, a self-dividing number is not allowed to contain the digit zero.
Given a lower and upper number bound, output a list of every possible self dividing number, including the bounds if possible.
Example 1,
```text
Input: 
left = 1, right = 22
Output: [1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 15, 22]
```



## 2. Solution
思路: 注意数值上的位不能为0
```java
class Solution {
  public boolean helper(int num){
    int origin = num;
    while (num > 0) {
      if (num % 10 == 0 || origin % (num % 10) != 0) return false;
      num /= 10;
    }
    return true;
  }
  
  public List<Integer> selfDividingNumbers(int left, int right) {
    List<Integer> res = new ArrayList<>();
    for (int i = left; i <= right; i++)
      if (helper(i)) res.add(i);
    return res;
  }
}
```
