---
title: Counting Bits
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
abbrlink: 2360897686
date: 2018-02-07 10:08:30
---

## 1. Description
Given a non negative integer number num. For every numbers i in the range $0 ≤ i ≤ num$ calculate the number of 1's in their binary representation and return them as an array.
Example: For num = 5 you should return [0, 1, 1, 2, 1, 2].



## 2. Normal Solution
思路: 对小于n的每个值的每一位进行检查并统计
Time Complexity: $O(32n)$
Space Complexity: $O(1)$
```java
class Solution {
  public int[] countBits(int num) {
    int[] res = new int[num + 1];
    for (int i = 0; i <= num; i++)
      for (int j = 0; j < 31; j++)
        if ((i & (1 << j)) > 0) res[i]++;
    return res;
  }
}
```



## 3. Dynamic Solution
思路: 对于任意数值, 有以下两种情况:
* 对于任意偶数$n$, 其位个数一定与 $n/2$ 的位个数相同. 例如: $24 = 16 + 8$, $12 = 8 + 4$, 相当于24的所有位向右移动一位. 
* 对于任意奇数$m$, 其位个数与 $m/2$ 的位个数相差1

Time Complexity: $O(n)$
Space Complexity: $O(n)$

```java
class Solution {
  public int[] countBits(int num) {
    int[] res = new int[num + 1];
    for(int i = 0; i <= num; i++)
      res[i] = res[i >> 1] + (i & 1);
    return res;
  }
}
```