---
title: DP - Group Knapsack Problem
abbrlink: b233
date: 2024-04-21 11:31:25
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
分组背包问题: 有$n$组物品和一个容量为$c$的背包, 第i组物品有$g[i]$个物品, 第i组物品的第j个物品的体积为$w[i][j]$, 价值为$v[i][j]$, 在不超过背包容量上限的前提下, 放入背包的物品的最大价值之和. 该题目有以下几点需要考虑:
* 每组物品只能选择一个放入背包, 也可以跳过
* 背包有容量限制, 因此无法将所有物品放入背包
* 将物品放入背包时, 背包的价值增加, 但剩余容量下降, 选择哪些物品可最大化背包价值


## 2. Dynamic Programming
动态规划解决该问题可分为以下几步:
1. 划分阶段: 按照物品组号和背包剩余容量进行阶段划分
2. 定义状态: 物品组号$i$和背包剩余容量$c_i$, 定义一个二维数组$dp[i][c_i]$, 表示前i组物品放入一个容量为$c_i$的背包时可获得的最大价值
3. 状态转移方程: 对于第i-1组物品, 我们有很多选择:
    * 不选择第$i-1$组中的任何物品, 可获得价值为$dp[i-1][c_i]$
    * 选择第$i-1$组中的第1件物品, 可获得价值为$dp[i-1][c_i - w[i-1][0]] + v[i-1][0]$
    * 选择第$i-1$组中的第2件物品, 可获得价值为$dp[i-1][c_i - w[i-1][1]] + v[i-1][1]$
    * $\cdots \cdots$

    以此类推, 状态转移方程可写作:
    $$
    dp[i][c_i] = max(dp[i-1][c_i], dp[i-1][c_i - w[i-1][k]] + v[i-1][k]), 0 \le k \lt g[i-1]
    $$
4. 初始条件:
    * 若$c_i = 0$, 则背包无法放入任何物品, 价值为0, 即$dp[i][0] = 0, 0 \le i \le n$
    * 若$i = 0$, 则没有任何物品可以放入背包, 价值为0, 即$dp[0][c_i] = 0, 0 \le c_i \le c$
5. 最终结果: 根据状态定义, $dp[n][c]$表示`前i组物品放入一个容量为c的背包可获得的最大价值`, 即为答案

时间复杂度为$O(n \times W \times c)$, $n$为物品的组数, $W$为每组物品的数量, $c$为背包容量. 空间复杂度为$O(c * \sum_{i=0}^{n-1}{g[i]})$


## 3. Optimization
由于$dp[i][c_i]$只与$dp[i-1][c_i]$和$dp[i-1][c_i - w[i-1][k]]$有关, 因此可使用**滚动数组**将空间复杂度优化到$O(c)$.


## 4. Leetcode
### 1155. Number of Dice Rolls With Target Sum
#### Problem Description
You have `n` dice, and each dice has k faces numbered from `1` to `k`.
Given three integers `n`, `k`, and `target`, return the number of possible ways (out of the `$k^n$` total ways) to roll the dice, so the sum of the face-up numbers equals `target`. Since the answer may be too large, return it **modulo** `${10}^9 + 7$`.

Example 1:
```
Input: n = 1, k = 6, target = 3
Output: 1
Explanation: You throw one die with 6 faces.
There is only one way to get a sum of 3.
```

#### Solution
```java
class Solution {
    public int numRollsToTarget(int n, int k, int target) {
        final int MOD = (int)(1e9 + 7);
        int[][] dp = new int[n+1][target+1];
        dp[0][0] = 1;
        for (int i = 0; i < n; i++) {
            for (int j = 1; j <= target; j++) {
                for (int m = 1; m <= j && m <= k; m++) {
                    dp[i+1][j] = (dp[i+1][j] + dp[i][j-m]) % MOD;
                }
            }
        }
        return dp[n][target];
    }
}
```
