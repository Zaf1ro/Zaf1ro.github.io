---
title: DP - Memoization Search
abbrlink: a5fe
date: 2024-04-06 12:53:17
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
记忆化搜索通过存储已遍历的状态, 可避免对同一状态的重复遍历. 换句话说, 当计算某个子问题时, 首先应检查该子问题是否曾经计算过:
* 若已计算过, 则直接返回存储的结果
* 若未计算过, 则继续计算, 并在执行后保存结果

动态规划最重要的是得到**状态定义**和**状态转移方程**, 可以先将题目当作backtracking题目, 也就是, 将一个大问题拆分为一个小问题, 并思考以下三个问题:
* 当前操作
* 子问题
* 边界条件

记忆化搜索则通过记录已经遍历过的状态, 从而避免对同一状态重复遍历, 降低时间复杂度.


## 2. Steps
记忆化搜索作为动态规划的一种实现, 使用前需考虑动态规划最重要的两个部分:
* 状态定义
* 状态转移方程

知道问题对应的状态定义和转移方程后, 可定义一个缓存(通常为数组或哈希表)用于保存子问题的解, 并定义一个递归函数用于解决问题. 在递归函数中, 需先检查当前问题是否已计算过(能否在缓存中找到结果), 若不能则执行计算, 并在返回前将结果保存到缓存中.


## 2. Leetcode
### 198. House Robber
#### 1. Problem Description
You are a professional robber planning to rob houses along a street. Each house has a certain amount of money stashed, the only constraint stopping you from robbing each of them is that adjacent houses have security systems connected and **it will automatically contact the police if two adjacent houses were broken into on the same night**.
Given an integer array `nums` representing the amount of money of each house, return the maximum amount of money you can rob tonight **without alerting the police**.

Example 1:
```
Input: nums = [1,2,3,1]
Output: 4
Explanation: Rob house 1 (money = 1) and then rob house 3 (money = 3).
Total amount you can rob = 1 + 3 = 4.
```

#### 2. Solution
用回溯的思路, 可分为三个问题:
* 当前操作: 选或不选当前房子
* 子问题:
    * 若选择当前房子(`nums[i]`), 则查找第i+2个房子及其后面的房子的最大金额
    * 若不选择当前房子, 则查找第i+1房子及其后面的房子的最大金额
* 边界条件: 坐标超出数组边界

状态转换方程: dfs(i) = max(dfs(i+1), dfs(i-2)+nums[i])

```java
class Solution {
    public int rob(int[] nums) {
        return backtracking(nums, 0);
    }

    private int backtracking(int[] nums, int i) {
        if (i >= nums.length) return 0;
        return Math.max(backtracking(nums, i+1), backtracking(nums, i+2)+nums[i]);
    }
}
```
该算法虽然思路上正确, 但时间复杂度很高, 因为递归会对nums的很多元素进行多次选与不选的判断, 可通过记忆化搜索将递归中的结果保存下来, 下次遇到时可直接返回结果.
```java
class Solution {
    public int rob(int[] nums) {
        int[] memo = new int[nums.length];
        Arrays.fill(memo, -1);
        return backtracking(nums, 0, memo);
    }

    private int backtracking(int[] nums, int i, int[] memo) {
        if (i >= nums.length) return 0;
        if (memo[i] != -1) return memo[i];
        memo[i] = Math.max(backtracking(nums, i+1, memo), backtracking(nums, i+2, memo)+nums[i]);
        return memo[i];
    }
}
```

### 377. Combination Sum IV
#### 1. Problem Description
Given an array of **distinct** integers `nums` and a target integer `target`, return the number of possible combinations that add up to `target`.
The test cases are generated so that the answer can fit in a **32-bit** integer.

Example 1:
```
Input: nums = [1,2,3], target = 4
Output: 7
Explanation:
The possible combination ways are:
(1, 1, 1, 1)
(1, 1, 2)
(1, 2, 1)
(1, 3)
(2, 1, 1)
(2, 2)
(3, 1)
Note that different sequences are counted as different combinations.
```

#### 2. Solution
该问题的要求为:
* 数组中的元素可重复使用: Combination Sum
* 组合可重复: 与上述所有题都不同
* 组合长度没有要求, 但要求组合的总和: Combination Sum

模板一: 跳过元素与之前题目相同; 但选择元素时需注意: 由于题目允许重复的组合(元素顺序不同), 因此每次递归都要从第一个元素开始.
```java
class Solution {
    private int res = 0;
    
    public int combinationSum4(int[] nums, int target) {
        Arrays.sort(nums);
        backtracking(nums, 0, target);
        return res;
    }

    private void backtracking(int[] nums, int i, int target) {
        if (target == 0) {
            ++res;
            return;
        }
        if (i == nums.length || nums[i] > target) return;
        // skip
        backtracking(nums, i+1, target);
        // pick up
        backtracking(nums, 0, target-nums[i]); // 0 instead of i or i+1
    }
}
```

上述解法虽然可得到正确结果, 但当target的数值较大时, 时间复杂度会非常高, 原因在于很多重复递归. 假设`backtracking(i)`表示target为i时的组合数量, 假设数组为`[1,2]`, 则`backtracking(i) = backtracking(i-1) = backtracking(i-2)`; 假设数组中有n个元素, 则$backtracking(i) = \sum^{n-1}_{j=0}{backtracking(i-nums[j])}$, 因此可按照**记忆化搜索**来优化:
* 若状态为第一次遇到, 则将结果放入memo数组中
* 若状态不是第一次遇到, 则直接返回memo数组中的结果

```java
class Solution {
    public int combinationSum4(int[] nums, int target) {
        int[] memo = new int[target+1];
        Arrays.fill(memo, -1);
        memo[0] = 1;
        return backtracking(nums, target, memo);
    }

    private int backtracking(int[] nums, int target, int[] memo) {
        if (memo[target] != -1) return memo[target];
        int res = 0;
        for (int num: nums) {
            if (num > target) continue;
            res += backtracking(nums, target-num, memo);
        }
        memo[target] = res;
        return res;
    }
}
```

### 2466. Count Ways To Build Good Strings
#### 1. Problem Description
Given the integers `zero`, `one`, `low`, and `high`, we can construct a string by starting with an empty string, and then at each step perform either of the following:
* Append the character `'0'` `zero` times.
* Append the character `'1'` `one` times.

This can be performed any number of times.
A **good** string is a string constructed by the above process having a **length** between `low` and `high` (**inclusive**).
Return the number of **different** good strings that can be constructed satisfying these properties. Since the answer can be large, return it **modulo** `${10}^9 + 7$`.

Example 1:
```
Input: low = 3, high = 3, zero = 1, one = 1
Output: 8
Explanation: 
One possible valid good string is "011". 
It can be constructed as follows: "" -> "0" -> "01" -> "011". 
All binary strings from "000" to "111" are good strings in this example.
```

#### 2. Solution
依然套用回溯三要素:
* 当前操作: 向当前字符串添加zero次0, 或添加one次1
* 子操作: 返回剩余字符长度的情况下, 长度满足`[low, high]`的组合数
* 边界条件:
    * 字符串长度超过high, 返回0
    * 字符串长度位于`[low, high]`之间, 组合数+1

```java
class Solution {
    public int countGoodStrings(int low, int high, int zero, int one) {
        return backtracking(low, high, zero, one, 0);
    }

    private int backtracking(int low, int high, int zero, int one, int i) {
        if (i > high) return 0;
        int res = 0;
        if (i >= low && i <= high) {
            ++res;
        }
        res += backtracking(low, high, zero, one, i+zero) + backtracking(low, high, zero, one, i+one);
        return res;
    }
}
```

记忆化搜索: 用`memo`数组记录所有长度下的组合数, 减少重复回溯:
```java
class Solution {
    public int countGoodStrings(int low, int high, int zero, int one) {
        int[] memo = new int[high+1];
        Arrays.fill(memo, -1);
        return backtracking(low, high, zero, one, 0, memo);
    }

    private int backtracking(int low, int high, int zero, int one, int i, int[] memo) {
        if (i > high) return 0;
        if (memo[i] != -1) return memo[i];
        long res = 0;
        if (i >= low && i <= high) {
            ++res;
        }
        res += backtracking(low, high, zero, one, i+zero, memo) + backtracking(low, high, zero, one, i+one, memo);
        memo[i] = (int)(res % 1000000007);
        return memo[i];
    }
}
```

修改为DP:
```java
class Solution {
    public int countGoodStrings(int low, int high, int zero, int one) {
        int[] memo = new int[high+1];
        int MOD = (int)(1e9 + 7), res = 0;
        memo[0] = 1;
        for (int i = 0; i <= high; i++) {
            if (i >= zero) memo[i] = (memo[i] + memo[i-zero]) % MOD;
            if (i >= one) memo[i] = (memo[i] + memo[i-one]) % MOD;
            if (i >= low) res = (res + memo[i]) % MOD;
        }
        return res;
    }
}
```

### 740. Delete and Earn
#### 1. Problem Description
You are given an integer array `nums`. You want to maximize the number of points you get by performing the following operation any number of times:
* Pick any `nums[i]` and delete it to earn `nums[i]` points. Afterwards, you must delete **every** element equal to `nums[i] - 1` and **every** element equal to `nums[i] + 1`.
Return the **maximum number of points** you can earn by applying the above operation some number of times.

Example 1:
```java
Input: nums = [3,4,2]
Output: 6
Explanation: You can perform the following operations:
- Delete 4 to earn 4 points. Consequently, 3 is also deleted. nums = [2].
- Delete 2 to earn 2 points. nums = [].
You earn a total of 6 points.
```

#### 2. Solution
题目其实与House Robber相同: 将所有points映射到一个数组上, 若选择`nums[i]`, 则必须跳过`nums[i] + 1`, 因此回溯三要素为:
* 当前操作: 选或不选当前元素
* 子问题:
    * 若选择该元素: 获取第i+2个元素及其之后的最大point之和
    * 若不选择该元素: 获取第i+1个元素及其之后的最大point之和
* 边界条件:
    * 递归超出最大元素
    * 当前枚举元素不存在于`nums`中

```java
class Solution {
    public int deleteAndEarn(int[] nums) {
        int maxVal = 0;
        for (int num: nums) {
            maxVal = Math.max(maxVal, num);
        }
        int[] count = new int[maxVal+1];
        for (int num: nums) {
            ++count[num];
        }
        return backtracking(0, maxVal, count);
    }

    private int backtracking(int i, int max, int[] count) {
        if (i > max) return 0;
        if (count[i] == 0) return backtracking(i+1, max, count);
        int res = backtracking(i+1, max, count);
        res = Math.max(res, i * count[i] + backtracking(i+2, max, count));
        return res;
    } 
}
```

记忆化搜索优化后:
```java
class Solution {
    public int deleteAndEarn(int[] nums) {
        int maxVal = 0;
        for (int num: nums) {
            maxVal = Math.max(maxVal, num);
        }
        int[] count = new int[maxVal+1], memo = new int[maxVal+1];
        for (int num: nums) {
            ++count[num];
        }
        Arrays.fill(memo, -1);
        return backtracking(0, maxVal, count, memo);
    }

    private int backtracking(int i, int max, int[] count, int[] memo) {
        if (i > max) return 0;
        if (count[i] == 0) return backtracking(i+1, max, count, memo);
        if (memo[i] != -1) return memo[i];
        memo[i] = Math.max(backtracking(i+1, max, count, memo), i*count[i]+backtracking(i+2, max, count, memo));
        return memo[i];
    } 
}
```

### 2320. Count Number of Ways to Place Houses
#### 1. Problem Description
There is a street with `n * 2` **plots**, where there are `n` plots on each side of the street. The plots on each side are numbered from `1` to `n`. On each plot, a house can be placed.
Return the number of ways houses can be placed such that no two houses are adjacent to each other on the same side of the street. Since the answer may be very large, return it **modulo** `${10}^9 + 7$`.
Note that if a house is placed on the `$i^{th}$` plot on one side of the street, a house can also be placed on the `$i^{th}$` plot on the other side of the street.

Example 1:
```
Input: n = 1
Output: 4
Explanation: 
Possible arrangements:
1. All plots are empty.
2. A house is placed on one side of the street.
3. A house is placed on the other side of the street.
4. Two houses are placed, one on each side of the street.
```

#### 2. Solution
由于街道的两侧是相互独立的, 因此只需算一侧街道的组合数即可. 回溯三要素:
* 当前操作: 选或不选当前plot(第i个元素)
* 子问题: 若选择当前plot, 则需获取第i+2个元素及其之后元素的组合数; 若不选择当前plot, 则需获取第i+1个元素及其之后元素的组合数.
* 边界条件: 

```java
class Solution {
    private int MOD = (int)(1e9 + 7);

    public int countHousePlacements(int n) {
        int res = backtracking(0, n);
        return (int)(((long)res * res) % MOD);
    }

    private int backtracking(int i, int n) {
        if (i >= n) return 1;
        return (backtracking(i+1, n) + backtracking(i+2, n)) % MOD;
    }
}
```

假设f[i]表示前i个plot的放置数, 对于第i个plot:
* 若不放置房屋, 则第i-1个plot可放可不放, 则`f[i] = f[i-1]`
* 若放置房屋, 则第i-2个plot可放可不放, 则`f[i] = f[i-2]`

由于放置或不放置是两个不可能同时发生的事件, 根据加法原则, `f[i] = f[i-1] + f[i-2]`.
边界条件:
* f[0] = 1, 不放置任何房屋: 一种情况
* f[1] = 2, 放或不放置房屋: 两种情况

```java
class Solution {
    public int countHousePlacements(int n) {
        long[] dp = new long[n+1];
        dp[0] = 1;
        dp[1] = 2;
        int mod = (int)(1e9 + 7);
        for (int i = 2; i <= n; i++) {
            dp[i] = (dp[i-1] + dp[i-2]) % mod;
        }
        return (int)((dp[n] * dp[n]) % mod);
    }
}
```
