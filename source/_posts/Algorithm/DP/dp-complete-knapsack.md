---
title: DP - Complete Knapsack Problem
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
abbrlink: '6100'
date: 2024-04-15 09:09:41
keywords:
description:
---

## 1. Introduction
完全背包问题: 有$n$种物品和一个容量为$c$的背包, 第$i$种物品的体积为$w[i]$, 价值为$v[i]$, 在不超过背包容量上限的前提下, 求能放入背包中物品的最大价值之和. 该题目有以下几点需要考虑:
* 每种物品有无数件, 因此可以将多个相同物品放入背包
* 背包有容量上限, 因此无法将无限个物品放入背包
* 将物品放入背包时, 背包的价值增加, 但剩余容量下降, 选择哪些物品可最大化背包价值

可以发现, 完全背包和01背包的区别在于: 每种物品有无限件. 01背包中, 对于第$i-1$个物品只有两种选择: 跳过或放入背包, 因此只有0或1; 但对于完全背包, 可以跳过第$i-1$种物品, 也可以放入一个, 二个, 最多装$\frac{c}{w[i-1]}$件第$i-1$种物品. 因此可在01背包的基础上加一层循环: 枚举第$i-1$种物品的所有可选件数, 从而将完全背包变为01背包.


## 2. Dynamic Programming
动态规划解决该问题时可分为以下几步:
1. 划分阶段: 按照物品种类和背包剩余容量进行阶段划分
2. 定义状态: 物品种类$i$和背包剩余容量$c_i$, 可申请一个$dp[n][c]$, 第一维表示`第$i$种物品`, 第二维表示`当前背包的剩余容量`, 数组值表示`前$i$种物品放入一个容量为$c_i$的背包可获得的最大价值和`.
3. 状态转移方程: 由于每种物品的选择数没有限制, 因此状态转移方程可写为:
  $$
  dp[i][c_i] = max(dp[i−1][c_i − k \times w[i−1]] + k \times v[i−1]), 0 \le k \le \frac{c_i}{w[i-1]}
  $$
4. 初始条件: 
  * 若$c = 0$, 则无法放入任何物品, 价值为0, 即$dp[i][0] = 0, 0 \le i \le n$
  * 若$i = 0$, 则没有任何物品可放入背包, 价值为0, 即$dp[0][c_i] = 0, 0 \le c_i \le c$
5. 最终结果: 根据状态定义, $dp[n][c]$表示`前$n$种物品放入一个容量为$c$的背包可获得的最大价值`, 即为答案

时间复杂度: $O(n \times c \times \sum_{i=0}^{n-1}{\frac{c}{w[i]}})$, $n$为物品种类数, $c$为背包的初始容量, $w[i]$为第$i$种物品的体积. 空间复杂度为$O(n \times c)$.


## 3. Optimization
### 3.1 State Transition
完全背包的状态转移方程可展开为:
$$
dp[i][c_i] = max
    \begin{cases}
        dp[i-1][c_i], \\\\[2ex]
        dp[i-1][c_i-w[i-1]] + v[i-1], \\\\[2ex]
        dp[i-1][c_i-2 \times w[i-1]] + 2 \times v[i-1], \\\\[2ex]
        \cdots \cdots \\\\[2ex]
        dp[i−1][c_i − k \times w[i−1]] + k \times v[i−1], & k = \lfloor \frac{c_i}{w[i-1]} \rfloor
    \end{cases}
$$

而对于$dp[i][c_i - w[i-1]]$, 其状态转移方程为:
$$
dp[i][c_i - w[i-1]] = max
    \begin{cases}
        dp[i-1][c_i - w[i-1]], \\\\[2ex]
        dp[i-1][c_i - 2 \times w[i-1]] + v[i-1], \\\\[2ex]
        dp[i-1][c_i - 3 \times w[i-1]] + 2 \times v[i-1], \\\\[2ex]
        \cdots \cdots \\\\[2ex]
        dp[i−1][c_i − k \times w[i−1]] + (k - 1) \times v[i−1], & k = \lfloor \frac{c_i}{w[i-1]} \rfloor
    \end{cases}
$$

$dp[i][c_i]$有$k+1$项, $dp[i][c_i - w[i-1]]$有$k$项, 可以发现, $dp[i][c_i]$的第二项和与$dp[i][c_i - w[i-1]]$的第一项相差$v[i-1]$, 以此类推, 可用$dp[i][c_i - w[i]] + v[i-1]$替换$dp[i][c_i]$的$[1, k+1]$项. 简化后的状态转移方程如下:
$$
dp[i][c_i] = 
  \begin{cases}
    dp[i-1][c_i], & c_i \lt w[i-1] \\\\[2ex]
    max(dp[i-1][c_i], dp[i][c_i - w[i-1]] + v[i-1]), & c_i \ge w[i-1]
  \end{cases}
$$

完全背包的状态转换方程与01背包的状态转移方程很相似, 唯一区别在于:
* 01背包: 从$dp[i-1][c_i - w[i-1]] + v[i-1]$转换到$dp[i][c_i]$
* 完全背包: 从$dp[i][c_i - w[i-1]] + v[i-1]$转换到$dp[i][c_i]$

### 3.2 Space complexity
通过观察状态转换方程可知, $dp[i][c_i]$只与$dp[i-1][c_i]$和$dp[i][c_i - w[i-1]]$有关, 因此可使用一个一维数组dp[c]保存上一阶段的所有状态, 采用**滚动数组**的方式更新状态.


## 4. Leetcode
### 322. Coin Change
#### Problem Description
You are given an integer array `coins` representing coins of different denominations and an integer `amount` representing a total amount of money.
Return **the fewest number of coins** that you need to make up that amount. If that amount of money cannot be made up by any combination of the coins, return `-1`.
You may assume that you have an infinite number of each kind of coin.

Example 1:
```
Input: coins = [1,2,5], amount = 11
Output: 3
Explanation: 11 = 5 + 5 + 1
```

Example 2:
```
Input: coins = [2], amount = 3
Output: -1
```

#### Solution
```java
class Solution {
    public int coinChange(int[] coins, int amount) {
        int[] dp = new int[amount+1];
        Arrays.fill(dp, Integer.MAX_VALUE / 2);
        dp[0] = 0;
        for (int i = 0; i < coins.length; i++) {
            for (int j = coins[i]; j <= amount; j++) {
                dp[j] = Math.min(dp[j], dp[j-coins[i]] + 1);
            }
        }
        return dp[amount] >= Integer.MAX_VALUE / 2 ? -1 : dp[amount];
    }
}
```

### 518. Coin Change II
#### Problem Description
You are given an integer array `coins` representing coins of different denominations and an integer `amount` representing a total amount of money.
Return **the number of combinations that make up that amount**. If that amount of money cannot be made up by any combination of the coins, return `0`.
You may assume that you have an infinite number of each kind of coin.

Example 1:
```
Input: amount = 5, coins = [1,2,5]
Output: 4
Explanation: there are four ways to make up the amount:
5=5
5=2+2+1
5=2+1+1+1
5=1+1+1+1+1
```

#### Solution
```java
class Solution {
    public int change(int amount, int[] coins) {
        int[] dp = new int[amount+1];
        dp[0] = 1;
        for (int i = 0; i < coins.length; i++) {
            for (int j = coins[i]; j <= amount; j++) {
                dp[j] = dp[j] + dp[j-coins[i]];
            }
        }
        return dp[amount];
    }
}
```
