---
title: DP - 0/1 Knapsack Problem
abbrlink: 539a
date: 2024-04-07 11:43:20
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
0/1背包问题: 有$n$个物品和一个容量为$c$的背包, 第$i$个物品的体积为$w[i]$, 价值为$v[i]$, 在不超过背包容量上限的情况下, 求能放入背包中物品的最大价值之和. 该题目有以下几点需要考虑:
* 每个物品只能放入背包一次
* 背包有容量上限, 因此可能无法将所有物品都放入背包
* 将物品放入背包时, 背包的价值增加, 但剩余容量下降, 选择哪些物品可最大化背包内的物品价值之和


## 2. Brute Force
背包问题的暴力解法就是枚举所有物品组合, 判断每个组合能否放入背包, 并统计最大价值, 时间复杂度为$O(2^n)$. 这种解法不是动态规划, 而是回溯算法.


## 3. Dynamic Programming
动态规划算法解决该问题时, 可拆分为以下步骤:
1. 拆分问题: 按照物品坐标和背包剩余容量进行划分
    * 原问题: 背包剩余容量为`$c$`且还有`$n$`个物品时, 求最大价值
    * 子问题: 背包剩余容量为`$c_k$`且还有`$k$`个物品时最大价值, 与背包剩余容量为`$c - c_k$`且还有`$n-k$`个物品时的最大价值之和
2. 定义状态: 物品坐标`$i$`和剩余容量`$c_i$`, 可申请一个`$dp[n][c]$`表格, 表示前`$n$`个物品放入一个容量为`c`的背包时的最大价值.
3. 状态转移方程: 对于`前$i$个物品且容量为$c_i$的最大价值`这个问题, 可转换为两个子问题:
    * 前$i-1$个物品的最大价值: 前$0$个物品($i = 1$)表示背包中没有任何物品, 因此价值为$0$, 容量为$c$
    * 第$i$个物品是否放入背包:
        * 将第$i$个物品放入背包: $dp[i-1][c_{i-1}-w[i]] + v[i]$
        * 跳过第$i$个物品: $dp[i-1][c]$

    因此, 状态转移方程如下:
    $$
    dp[i][c_i] = 
    \begin{cases}
        dp[i-1][c_{i-1}],                              & c < w[i] \\\\[2ex]
        max(dp[i-1][c_{i-1}], dp[i-1][c_{i-1}-w[i]] + v[i]), & c \ge w[i]
    \end{cases}
    $$
4. 初始条件:
    * 若$c = 0$, 则没有容量放下任何物品, 价值为0, 即$dp[i][0] = 0, 0 \le i \le c$
    * 若$i = 0$, 则没有任何物品可放入背包, 价值为0, 即$dp[0][w], 0 \le c_i \le c$
5. 最终结果: 根据$dp[i][c_i]$的定义, $dp[n][w]$表示前$n$个物品且容量为$w$时的最大价值, 即为答案.

DP的时间复杂度为$O(n \times w)$, 空间复杂度为$O(n \times w)$


## 4. Optimization
求解过程中, `前i件物品的状态`只与`前i-1件物品的状态`有关, 与其他阶段的状态无关. 也就是说, 我们只会用到$dp[i][c]$, $dp[i-1][c]$, 和$dp[i-1][c-w[i-1]]$. 因此无需保存所有阶段的状态, 只需两个一维数组分别保存相邻两个阶段的状态; 进一步优化, 可只使用一个一维数组用于保存上一阶段的状态, 采用**滚动数组**的方式进行优化.


## 5. Leetcode
### 494. Target Sum
#### Problem Description
You are given an integer array `nums` and an integer `target`.
You want to build an **expression** out of nums by adding one of the symbols `'+'` and `'-'` before each integer in nums and then concatenate all the integers.
For example, if `nums = [2, 1]`, you can add a `'+'` before `2` and a `'-'` before `1` and concatenate them to build the expression `"+2-1"`.
Return the number of different **expressions** that you can build, which evaluates to `target`.

Example 1:
```
Input: nums = [1,1,1,1,1], target = 3
Output: 5
Explanation: There are 5 ways to assign symbols to make the sum of nums be target 3.
-1 + 1 + 1 + 1 + 1 = 3
+1 - 1 + 1 + 1 + 1 = 3
+1 + 1 - 1 + 1 + 1 = 3
+1 + 1 + 1 - 1 + 1 = 3
+1 + 1 + 1 + 1 - 1 = 3
```

#### Solution 
对于每个元素有两种选择: 正数或负数. 回溯三要素如下:
* 当前操作: 枚举每个元素, 对于第i个元素, 可当作正数或负数, `target = target +/- nums[i]`
* 子问题: 对于第i+1个和之后的元素, 使得target变为0
* 边界条件: i为n, 表示抵达数组末尾, 查看target是否为0

```java
class Solution {
    public int findTargetSumWays(int[] nums, int target) {
        return dfs(nums, 0, target);
    }

    private int dfs(int[] nums, int i, int target) {
        if (i == nums.length) {
            return target == 0 ? 1 : 0;
        }
        return dfs(nums, i+1, target+nums[i]) + dfs(nums, i+1, target-nums[i]);
    }
}
```

假设`nums`中存在数组之和为target的解法, 假设正数元素之和P, 负数元素之和为N, 则`P - N = target`, `P + N = sum(nums)`, 因此`2P = target + sum(nums)`.
* 若`target + sum(nums)`为奇数, 则不存在解
* 若`target + sum(nums)`为负数, 由于`0 <= nums[i] <= 1000`, 因此不存在解

因此该问题可转换为: 存在一个数组`nums`, 从中挑选一些元素并让其之和等于`(target + sum(nums)) / 2`. 从而让题目与01背包问题相同.

```java
class Solution {
    public int findTargetSumWays(int[] nums, int target) {
        int n = nums.length;
        for (int num: nums) {
            target += num;
        }
        if (target < 0 || target % 2 == 1) return 0;
        return backtracking(nums, 0, target/2);
    }

    private int backtracking(int[] nums, int i, int target) {
        if (target < 0) return 0;
        if (i == nums.length) {
            return target == 0 ? 1 : 0;
        }
        return backtracking(nums, i+1, target) + backtracking(nums, i+1, target-nums[i]);
    }
}
```

修改为dp数组:
```java
class Solution {
    public int findTargetSumWays(int[] nums, int target) {
        int n = nums.length;
        for (int num: nums) {
            target += num;
        }
        if (target < 0 || target % 2 == 1) return 0;
        target /= 2;
        int[][] dp = new int[n+1][target+1];
        dp[n][0] = 1; // 边界条件
        for (int i = n-1; i >= 0; i--) {
            for (int j = 0; j <= target; j++) {
                if (nums[i] > j) {
                    dp[i][j] = dp[i+1][j]; // 跳过不选
                } else {
                    dp[i][j] = dp[i+1][j] + dp[i+1][j-nums[i]]; // 加法原则: 若事件A和B不可能同时发生, 则发生事件A和B的总数等于发生A和发生B的数量之和
                }
            }
        }
        return dp[0][target];
    }
}
```
