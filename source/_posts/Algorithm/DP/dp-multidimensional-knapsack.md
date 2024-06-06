---
title: DP - Multidimensional Knapsack Problem
abbrlink: 2f11
date: 2024-04-29 16:23:47
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
多维背包问题: 有$n$件物品和一个体积容量为$W$, 重量上限为$D$的背包, 第$i$件物品的体积为$w[i]$, 重量为$d[i]$, 价值为$v[i]$, 在不超过背包的承重和容量下, 求放入背包的物品的最大价值之和. 该题目有以下几点需要考虑:
* 每件物品只可以放入背包一次, 也可以跳过
* 由于背包有承重和体积限制, 因此可能无法将所有物品放入背包
* 将物品放入背包后, 背包的价值增加, 但剩余载重和容量下降, 选择哪些物品可最大化背包价值


## 2. Dynamic Programming
动态规划算法解决该问题时, 可拆分为以下步骤:
1. 划分阶段: 按照物品的序号, 当前背包的剩余载重, 和剩余容量上限进行阶段划分
2. 定义状态: 定义一个三维数组$dp[i][d_i][w_i]$, 表示前$i$件物品放入一个载重为$d_i$, 容量为$w_i$的背包中可获得的最大价值
3. 状态转移方程:
  $$
  dp[i][d_i][w_i] = max(dp[i-1][d_i][w_i], dp[i-1][d_i-d[i-1]][w_i-w[i-1]] + v[i-1]), 0 \le d_i \le D, 0 \le w_i \le W
  $$
4. 初始条件:
  * 若$d_i = 0$或$w_i = 0$, 则背包无法容纳任何物品, 价值为0, 即$dp[i][d_i][0] = 0, 0 \le i \le n, 0 \le d_i \le D$, $dp[i][0][w_i] = 0, 0 \le i \le n, 0 \le w_i \le W$
  * 若$i = 0$, 则没有物品可放入背包, 价值为0, 即$dp[0][d_i][w_i] = 0, 0 le d_i \le D, 0 le w_i \le W$
5. 最终结果: 根据状态定义, $dp[n][D][W]$表示前$n$件物品放入一个载重为$D$, 容量为$W$的背包中可获得的最大价值, 即为答案.

时间复杂度为$O(n \times D \times W)$, 其中$n$为物品件数, $D$为背包载重上限, $W$为背包容量上限. 空间复杂度为$O(n \times D \times W)$


## 3. Optimization
通过观察状态转移方程可知, dp[i][d_i][w_i]只与dp[i-1][d_i][w_i]和dp[i-1][d_i - d[i-1]][w_i - w[i-1]]有关, 因此可使用**滚动数组**将空间复杂度优化到$O(D \times W)$.


## 4. Leetcode
### 474. Ones and Zeroes
#### Problem Description
You are given an array of binary strings `strs` and two integers `m` and `n`.
Return **the size of the largest subset of strs** such that there are **at most** `m` `0`'s and `n` `1`'s in the subset.
A set `x` is a **subset** of a set `y` if all elements of `x` are also elements of `y`.

Example 1:
```
Input: strs = ["10","0001","111001","1","0"], m = 5, n = 3
Output: 4
Explanation: The largest subset with at most 5 0's and 3 1's is {"10", "0001", "1", "0"}, so the answer is 4.
Other valid but smaller subsets include {"0001", "1"} and {"10", "1", "0"}.
{"111001"} is an invalid subset because it contains 4 1's, greater than the maximum of 3.
```

#### Solution
```java
class Solution {
  public int findMaxForm(String[] strs, int m, int n) {
    int[][] count = new int[strs.length][2];
    for (int i = 0; i < strs.length; i++) {
      for (char c: strs[i].toCharArray()) {
        ++count[i][c == '0' ? 0 : 1];
      }
    }
    int[][] dp = new int[m+1][n+1];
    for (int i = 0; i < strs.length; i++) {
      for (int j = m; j >= count[i][0]; j--) {
        for (int k = n; k >= count[i][1]; k--) {
          dp[j][k] = Math.max(dp[j][k], dp[j-count[i][0]][k-count[i][1]] + 1);
        }
      }
    }
    return dp[m][n];
  }
}
```
