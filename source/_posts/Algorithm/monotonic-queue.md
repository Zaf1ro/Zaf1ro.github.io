---
title: Monotonic Queue
abbrlink: 7faa
date: 2023-06-25 17:38:04
category:
  - Algorithm
  - Date Structure
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
单调队列是一种特殊的**double ended queue**(双端队列, 简称deque):
* 元素只能从队尾进入
* 队内元素可从队首和队尾出队
* 队内元素始终保持单调递增或递减

使用单调队列时, 通常会在队内保存元素的坐标, 而不是元素本身, 从而方便之后获得元素的坐标信息.


## 2. Monotonicity
假设一个单调队列的元素从队首到队尾始终保持单调递减, 向单调队列添加新元素时存在以下情况:
* 若单调队列为空, 则将新元素加入队尾
* 若队尾元素大于当前元素, 则将新元素加入队尾
* 若队尾元素小于或等于当前元素, 则弹出队尾元素, 直到满足上述两个情况之一

可以发现, 上述描述与单调栈的入栈没有任何区别. 单调队列只在此基础上多了一个**移除队首元素**的操作, 类似于向右移动滑动窗口的左指针, 因此从某种程度来说, `单调队列 = 单调栈 + 滑动窗口`.


## 3. Use Case
给定一个数组`win`, 且已知该数组的最小值为`min`, 若向该数组添加一个元素`x`, 只需比较`min`和`x`即可知道添加元素后`win`的最小值. 但若从数组头部移除一个元素, 则无法直接获知最小值: 若移除的元素为`min`, 则需遍历`win`所有元素来重新寻找新的最小值. 可以发现, 从数组尾部加入元素, 从数组头部移除元素, 符合滑动窗口的定义, 因此单调队列是一种求滑动窗口最值的方法.
对于加入元素操作, 由于需要维护单调队列的单调性, 因此时间复杂度并不是$O(1)$; 但算法的整体时间复杂度仍为$O(n)$, 其中$n$为数组长度, 因为每个元素最多被添加或移除一次. 算法的空间复杂度为$O(k)$, $k$为滑动窗口的长度.


## 4. Leetcode
### 1438. Longest Continuous Subarray With Absolute Diff Less Than or Equal to Limit
#### Problem Description
Given an array of integers `nums` and an integer `limit`, return the size of the longest **non-empty** subarray such that the absolute difference between any two elements of this subarray is less than or equal to `limit`.

Example 1:
```
Input: nums = [10,1,2,4,7,2], limit = 5
Output: 4 
Explanation: The subarray [2,4,7,2] is the longest since the maximum absolute diff is |2-7| = 5 <= 5.
```

#### Solution
```java
class Solution {
    public int longestSubarray(int[] nums, int limit) {
        Deque<Integer> desc = new LinkedList<>(), asc = new LinkedList<>();
        int l = 0, max = 0;
        for (int r = 0; r < nums.length; r++) {
            // in
            while (!desc.isEmpty() && nums[r] > nums[desc.peekLast()]) desc.pollLast();
            while (!asc.isEmpty() && nums[r] < nums[asc.peekLast()]) asc.pollLast();
            desc.offerLast(r);
            asc.offerLast(r);
            // out
            while (nums[desc.peekFirst()] - nums[asc.peekFirst()] > limit) {
                int left = nums[l++];
                if (left == nums[desc.peekFirst()]) desc.pollFirst();
                if (left == nums[asc.peekFirst()]) asc.pollFirst(); 
            }
            // add
            max = Math.max(max, r - l + 1);
        }
        return max;
    }
}
```

### 1696. Jump Game VI
#### Problem Description
You are given a **0-indexed** integer array `nums` and an integer `k`.
You are initially standing at index `0`. In one move, you can jump at most `k` steps forward without going outside the boundaries of the array. That is, you can jump from index `i` to any index in the range `[i + 1, min(n - 1, i + k)]` **inclusive**.
You want to reach the last index of the array (index `n - 1`). Your **score** is the **sum** of all `nums[j]` for each index `j` you visited in the array.
Return the **maximum score** you can get.

Example 1:
```
Input: nums = [1,-1,-2,4,-7,3], k = 2
Output: 7
Explanation: You can choose your jumps forming the subsequence [1,-1,4,3] (underlined above). The sum is 7.
```

#### Solution
```java
class Solution {
  public int maxResult(int[] nums, int k) {
    Deque<Integer> deque = new LinkedList<>();
    int max = nums[0];
    for (int i = 0; i < nums.length; i++) {
      while (!deque.isEmpty() && i - deque.peekFirst() > k) {
        deque.pollFirst();
      }
      if (!deque.isEmpty()) {
        nums[i] += nums[deque.peekFirst()];
      }
      while (!deque.isEmpty() && nums[i] >= nums[deque.peekLast()]) {
        deque.pollLast();
      }
      deque.offerLast(i);
    }
    return nums[nums.length-1];
  }
}
```

### 239. Sliding Window Maximum
#### Problem Description
You are given an array of integers `nums`, there is a sliding window of size `k` which is moving from the very left of the array to the very right. You can only see the `k` numbers in the window. Each time the sliding window moves right by one position. Return **the max sliding window**.

Example 1:
```
Input: nums = [1,3,-1,-3,5,3,6,7], k = 3
Output: [3,3,5,5,6,7]
Explanation: 
Window position                Max
---------------               -----
[1  3  -1] -3  5  3  6  7       3
 1 [3  -1  -3] 5  3  6  7       3
 1  3 [-1  -3  5] 3  6  7       5
 1  3  -1 [-3  5  3] 6  7       5
 1  3  -1  -3 [5  3  6] 7       6
 1  3  -1  -3  5 [3  6  7]      7
```

#### Solution
```java
class Solution {
    public int[] maxSlidingWindow(int[] nums, int k) {
        int[] res = new int[nums.length - k + 1];
        int j = 0;
        Deque<Integer> deque = new LinkedList<>();
        for (int i = 0; i < nums.length; i++) {
            // in
            while (!deque.isEmpty() && nums[deque.peekLast()] <= nums[i]) {
                deque.pollLast();
            }
            deque.offerLast(i);
            // out
            if (deque.peekFirst() <= i - k) {
                deque.pollFirst();
            }
            // add
            if (i >= k - 1) {
                res[j++] = nums[deque.peekFirst()];
            }
        }
        return res;
    }
}
```

### 2398. Maximum Number of Robots Within Budget
#### Problem Description
You have `n` robots. You are given two **0-indexed** integer arrays, `chargeTimes` and `runningCosts`, both of length `n`. The `$i^{th}$` robot costs `chargeTimes[i]` units to charge and costs` runningCosts[i]` units to run. You are also given an integer budget.
The **total cost** of running `k` chosen robots is equal to `max(chargeTimes) + k * sum(runningCosts)`, where `max(chargeTimes)` is the largest charge cost among the `k` robots and `sum(runningCosts)` is the sum of running costs among the `k` robots.
Return the **maximum** number of **consecutive** robots you can run such that the total cost **does not** exceed `budget`.

Example 1:
```
Input: chargeTimes = [3,6,1,3,4], runningCosts = [2,1,3,4,5], budget = 25
Output: 3
Explanation: 
It is possible to run all individual and consecutive pairs of robots within budget.
To obtain answer 3, consider the first 3 robots. The total cost will be max(3,6,1) + 3 * sum(2,1,3) = 6 + 3 * 6 = 24 which is less than 25.
It can be shown that it is not possible to run more than 3 consecutive robots within budget, so we return 3.
```

#### Solution
```java
class Solution {
    public int maximumRobots(int[] chargeTimes, int[] runningCosts, long budget) {
        Deque<Integer> desc = new LinkedList<>();
        long sum = 0;
        int l = 0, max = 0;
        for (int r = 0; r < chargeTimes.length; r++) {
            // in
            sum += runningCosts[r];
            while (!desc.isEmpty() && chargeTimes[r] >= chargeTimes[desc.peekLast()]) {
                desc.pollLast();
            }
            desc.offerLast(r);
            // out
            while (!desc.isEmpty() && sum * (r - l + 1) + chargeTimes[desc.peekFirst()] > budget) {
                sum -= runningCosts[l];
                if (l == desc.peekFirst()) desc.pollFirst();
                ++l;
            }
            // add
            max = Math.max(max, r - l + 1);
        }
        return max;
    }
}
```

### 862. Shortest Subarray with Sum at Least K
#### Problem Description
Given an integer array `nums` and an integer `k`, return the length of the shortest non-empty **subarray** of `nums` with a sum of at least `k`. If there is no such **subarray**, return `-1`.
A **subarray** is a **contiguous** part of an array.

Example 1:
```
Input: nums = [2,-1,2], k = 3
Output: 3
```

#### Solution
```java
class Solution {
    public int shortestSubarray(int[] nums, int k) {
        long[] presum = new long[nums.length+1];
        for (int i = 0; i < nums.length; i++) {
            presum[i+1] = presum[i] + nums[i];
        }
        Deque<Integer> deque = new LinkedList<>();
        int min = Integer.MAX_VALUE;
        for (int i = 0; i <= nums.length; i++) {
            while (!deque.isEmpty() && presum[i] - presum[deque.peekFirst()] >= k) {
                min = Math.min(min, i - deque.pollFirst());
            }
            while (!deque.isEmpty() && presum[i] <= presum[deque.peekLast()]) {
                deque.pollLast();
            }
            deque.offerLast(i);
        }
        return min == Integer.MAX_VALUE ? -1 : min;
    }
}
```


### 1499. Max Value of Equation
#### Problem Description
You are given an array `points` containing the coordinates of points on a 2D plane, sorted by the x-values, where `$points[i] = [x_i, y_i]$` such that `$x_i < x_j$` for all `$1 \le i < j \le points.length$`. You are also given an integer `k`.
Return the maximum value of the equation `$y_i + y_j + |x_i - x_j|$` where `$|x_i - x_j| \le k$` and `$1 \le i < j \le points.length$`.
It is guaranteed that there exists at least one pair of points that satisfy the constraint `$|x_i - x_j| \le k$`.

Example 1:
```
Input: points = [[1,3],[2,0],[5,10],[6,-10]], k = 1
Output: 4
Explanation: The first two points satisfy the condition |xi - xj| <= 1 and if we calculate the equation we get 3 + 0 + |1 - 2| = 4. Third and fourth points also satisfy the condition and give a value of 10 + -10 + |5 - 6| = 1.
No other pairs satisfy the condition, so we return the max of 4 and 1.
```

#### Solution
```java
class Solution {
    public int findMaxValueOfEquation(int[][] points, int k) {
        Deque<int[]> deque = new LinkedList<>();
        int max = Integer.MIN_VALUE;
        for (int r = 0; r < points.length; r++) {
            int x = points[r][0], y = points[r][1];
            while (!deque.isEmpty() && x - deque.peekFirst()[0] > k) {
                deque.pollFirst();
            }
            if (!deque.isEmpty()) {
                max = Math.max(max, y+x+deque.peekFirst()[1]);
            }
            while (!deque.isEmpty() && y-x >= deque.peekLast()[1]) {
                deque.pollLast();
            }
            deque.offer(new int[]{x, y-x});
        }
        return max;
    }
}
```
