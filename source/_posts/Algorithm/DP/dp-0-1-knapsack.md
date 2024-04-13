---
title: Dynamic Programming - 0/1 Knapsack
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

## Introduction
0-1背包问题: 有n个物品, 第i个物品的体积为w[i], 价值为v[i], 每个物品至多选一次, 求体积和不超过capacity时的最大价值和.
这类问题先从回溯的三要素思考:
* 当前操作: 枚举到第i个物品, 有两种选择:
    * 选择该物品, 剩余容量下降, 价值增加
    * 不选该物品, 剩余容量不变, 价值不变
* 子问题: 剩余容量为c时, 之后物品能得到的最大价值和
* 边界条件:
    * 物品枚举完毕: 结束递归
    * 当前物品的体积超过剩余容量: 不选当前物品

因此, 其状态转换方程为: `dfs(i, c) = max(dfs(i+1, c), dfs(i+1, c-w[i])+v[i])`. 其中, `c`表示剩余容量, `i`表示`[i, n]`范围内的所有物品, 不单指第i个物品.


## 494. Target Sum
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

### Solution 
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
