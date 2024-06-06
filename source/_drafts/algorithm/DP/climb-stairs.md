---
title: Climb Stairs
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
abbrlink: 765073390
date: 2018-02-08 12:48:40
---

## 1. Min Cost Climbing Stairs
### 1.1 Description
On a staircase, the $i^{th}$ step has some non-negative cost cost[i] assigned (0 indexed).

Once you pay the cost, you can either climb one or two steps. You need to find minimum cost to reach the top of the floor, and you can either start from the step with index 0, or the step with index 1.

Example 1:
```text
Input: cost = [10, 15, 20]
Output: 15
Explanation: Cheapest is start on cost[1], pay that cost and go to the top.
```

Example 2:
```text
Input: cost = [1, 100, 1, 1, 1, 100, 1, 1, 100, 1]
Output: 6
Explanation: Cheapest is start on cost[0], and only step on 1s, skipping cost[3].
```

### 1.2 Dynamic Programming Solution
思路: 由于每一次移动只能向后移动一格或两格, 那么对于坐标为$n$的成本来说
$$ cost[n] = min(cost[n-1], cost[n-2]) + cost[n] $$
但最终的成本并不等于cost数组的最后一个元素, 因为当移动到cost数组中倒数第二个元素时可通过跳两格格子跳出, 所以最终结果应为:
$$ result = min(cost[length], cost[length-1]) $$

```java
class Solution {
  public int minCostClimbingStairs(int[] cost) {
    if (cost == null || cost.length < 2)
      return 0;
    
    int len = cost.length;
    for (int i = 2; i < len; i++)
      cost[i] += Math.min(cost[i-1], cost[i-2]);
    return Math.min(cost[len-1], cost[len-2]);
  }
}
```



## 2. Climbing Stairs
### 2.1 Description
You are climbing a stair case. It takes $n$ steps to reach to the top.
Each time you can either climb 1 or 2 steps. In how many distinct ways can you climb to the top?
Note: Given $n$ will be a positive integer.

* Example 1:
```text
Input: 2
Output:  2
Explanation:  There are two ways to climb to the top.
1. 1 step + 1 step
2. 2 steps
```

* Example 2:
```text
Input: 3
Output:  3
Explanation:  There are three ways to climb to the top.
1. 1 step + 1 step + 1 step
2. 1 step + 2 steps
3. 2 steps + 1 step
```

### 2.2 Dynamic Programming Solution
思路: 假设我们需要移动到$n$, 那么为了移动到$n$, 需要先移动到$n-1$或$n-2$(通过从$n-1$移动一格到$n$, 或通过$n-2$移动二格到$n$), 所以:
$$ dp[n] = dp[n - 1] + dp[n - 2] $$ 
可以发现, 这是一个Fabbonacci序列

```java
class Solution {
  public int climbStairs(int n) {
    int[] res = new int[n+1];
    res[0] = res[1] = 1;
    for (int i = 2; i <= n; i++)
      res[i] = res[i-1] + res[i-2];
    return res[n];
  }
}
```
