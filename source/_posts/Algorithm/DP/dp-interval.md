---
title: DP - Interval
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
abbrlink: 2a4c
date: 2024-06-03 13:08:26
keywords:
description:
---

## 1. Introduction
区间动态规划是一个特殊的线性DP问题方法, 通常以**区间长度**划分阶段, 以区间的左右端点作为状态, 一个状态由比它长度更小的状态(长度更小)转换而来. 区间DP的思想为: 先在小区间内获得最优解, 再合并小区间来获取大区间的最优解, 最终获得整个区间的最优解.
根据小区间向大区间的不同转移情况, 区间DP问题可分为两类:
* 区间从中心向两侧扩展, 如区间$[i+1, j-1]$转移到$[i,j]$
* 多个小区间合并为一个大区间, 如区间$[i,k]$和区间$[k+1,j]$转移为区间$[i,j]$

### 1.1 The First Interval DP Problem
从中间向两侧拓展的区间DP问题的状态转移方程通常为:
$$
dp[i][j] = max/min(dp[i+1][j-1], dp[i+1][j], dp[i][j-1]) + cost[i][j],i < j
$$

1. $dp[i][j]$表示区间$[i,j]$(从坐标i到坐标j上所有元素)上的最值
2. $cost[i][j]$表示从小区间转移到大区间的代价
3. max/min取决于题目要求

此类区间DP问题的思路如下:
1. 枚举区间起点
2. 枚举区间终点
3. 根据状态转移方程计算从小区间转移到大区间后的最优解

```py
for i in range(size - 1, -1, -1):       # start of interval
    for j in range(i + 1, size):        # end of interval
        # state transition
        dp[i][j] = max(dp[i + 1][j - 1], dp[i + 1][j], dp[i][j - 1]) + cost[i][j]
```

### 1.2 The Second Interval DP Problem
多个小区间合并为大区间的区间DP问题的状态转移方程通常为:
$$
dp[i][j] = max/min(dp[i][k] + dp[k+1][j] + cost[i][j]), i \le k < j
$$

1. $dp[i][j]$表示区间$[i,j]$(从坐标i到坐标j上所有元素)上的最值
2. $cost[i][j]$表示将两个区间($[i,k]$, $[k+1,j]$)合并为一个区间的代价
3. max/min取决于题目要求

此类区间DP问题的思路如下:
1. 枚举区间长度
2. 枚举区间起点
3. 枚举区间的分割点
4. 根据状态转移方程计算合并区间后的最优解

```py
for l in range(1, n):           # start of interval
  for i in range(n):            # length of interval
    j = i + l - 1               # end of interval
    if j >= n:
      break
    for k in range(i, j + 1):   # mid of interval
      # state transition
      dp[i][j] = max(dp[i][j], dp[i][k] + dp[k + 1][j] + cost[i][j])
```


## 2. Leetcode
### 516. Longest Palindromic Subsequence
#### Problem Description
Given a string `s`, find the longest palindromic **subsequence**'s length in `s`.
A **subsequence** is a sequence that can be derived from another sequence by deleting some or no elements without changing the order of the remaining elements.

Example 1:
```
Input: s = "bbbab"
Output: 4
Explanation: One possible longest palindromic subsequence is "bbbb".
```

#### Solution
```java
class Solution {
    public int longestPalindromeSubseq(String s) {
        int n = s.length(), res = 0;
        int[][] dp = new int[n][n];
        for (int i = 0; i < n; i++) {
            for (int j = i; j >= 0; j--) {
                if (j == i) {
                    dp[j][i] = 1;
                } else if (s.charAt(j) == s.charAt(i)) {
                    dp[j][i] = 2 + dp[j+1][i-1];
                } else {
                    dp[j][i] = Math.max(dp[j][i-1], dp[j+1][i]);
                }
                res = Math.max(res, dp[j][i]);
            }
        }
        return res;
    }
}
```
