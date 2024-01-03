---
title: Monotonic Stack
abbrlink: 261c
date: 2023-06-23 10:01:57
category:
  - Algorithm
  - Date Structure
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
单调栈首先是一种栈, 元素只能从一端输入和输出, 且栈内元素保持单调性: 元素始终保持递增或递减. 通常会在栈内保存元素的坐标, 而不是元素本身, 这样既可以从栈内找到对应元素, 也可保留元素的坐标信息.


## 2. Procedure
描述单调栈的单调性时, 若栈底元素小于栈顶元素, 则称为单调递增; 反之, 则称为单调递减. 为维护单调栈的单调性, **插入元素**时需比较插入元素与栈顶元素: 假设存在一个单调栈, 其栈内自顶向下的元素为`{0, 11, 45, 81}`, 若插入元素为14, 为保证该栈**单调递减**, 需依次弹出栈顶元素`0, 11`, 该栈最终变为`{14, 45, 81}`.


## 42. Trapping Rain Water
Given `n` non-negative integers representing an elevation map where the width of each bar is `1`, compute how much water it can trap after raining.

Example 1:
```
Input: height = [0,1,0,2,1,0,1,3,2,1,2,1]
Output: 6
Explanation: The above elevation map (black section) is represented by array [0,1,0,2,1,0,1,3,2,1,2,1]. In this case, 6 units of rain water (blue section) are being trapped.
```

### Solution
题目要求返回雨水的总量, 通过观察可以发现, 若存在雨水, 则一定存在`高低高`的结构, 例如`{1,0,1}`. 因此可维护一个单调栈: 遍历数组时, 栈的性质保证栈底元素的坐标一定比栈顶元素更小; 且该栈保持单调递减, 从而保证之前的bar高于之后的bar, 形成一个`高低`的结构. 当某个bar大于栈顶元素时, 可能存在两种情况:
* 栈内只有一个元素, 不足以形成`高低高`
* 栈内存在两个或以上元素, 可以形成`高低高`

需要注意的是, 水坑的高度不一定由当前元素决定, 也取决于左侧单调栈中的元素, 例如`{1,0,2}`, 遍历到`height[2]`时, 水坑的高度应为`min(1,2) = 1`; 水坑的宽度也不一定为1, 例如`{2,1,0,2}`, 遍历到`height[3]`时, 先计算`height[1:3]`的雨水量, 再计算`height[0,3]`的雨水量, 为防止重复计算, 需记录上一个水坑的高度. 该方法的时间复杂度为`$O(n)$`.
```java
class Solution {
    public int trap(int[] height) {
        Deque<Integer> deque = new ArrayDeque<>();
        int res = 0;
        for (int i = 0; i < height.length; i++) {
            int h = height[i], prev = 0;
            while (!deque.isEmpty() && h >= height[deque.peekLast()]) {
                prev = height[deque.pollLast()];
                if (!deque.isEmpty()) {
                    int t = deque.peekLast();
                    res += (Math.min(height[t], h) - prev) * (i - t - 1);
                }
            }
            deque.offerLast(i);
        }
        return res;
    }
}
```


## 84. Largest Rectangle in Histogram
Given an array of integers `heights` representing the histogram's bar height where the width of each bar is `1`, return the area of the largest rectangle in the histogram.

Example 1:
```
Input: heights = [2,1,5,6,2,3]
Output: 10
Explanation: The above is a histogram where width of each bar is 1.
The largest rectangle is shown in the red area, which has an area = 10 units.
```

Example 2:
```
Input: heights = [2,4]
Output: 4
```

### Solution
题目要求返回bar组成的最大矩形面积, 可以发现一个规律: 最大矩形面积的高度一定是某一个bar的高度, 最大矩形的宽度为该bar向左右延伸的最大宽度, 因此矩形的面积为`heights[i] * (r - l + 1)`. 若我们对每个bar向左右延伸, 即可得到最终答案, 该方法的时间复杂度为`$O(n^2)$`. 当对一个bar向左(或右)延伸时, 存在三种可能:
* 当前bar的高度大于或等于目标bar, 可继续向外延伸
* 抵达数组边界, 无法继续向外延伸
* 当前bar的高度小于目标bar, 无法继续向外延伸

因此, 以一个bar的高度作为矩形高度时, 其延伸的bar的高度一定大于或等于该bar. 若维护一个单调栈, 其单调性为递增, 若当前元素(bar的高度)大于栈顶元素, 则说明当前元素为栈顶元素的右边界, 而左边界分为两种情况:
* 若单调栈只存在一个栈顶元素, 存在两种情况: 
    * 栈顶元素之前的bar都高于栈顶元素
    * 栈顶元素为数组的第一个元素

    无论以上哪种情况, 左边界都可以为`-1`
* 若单调栈存在多个元素, 则栈内其他元素一定小于栈顶元素, 可作为左边界

需要注意的是, 由于只有当前元素小于栈顶元素时才会弹出栈顶元素, 因此需在数组最后添加一个高度为`0`的bar, 保证所有bar构成的矩形都被会计算. 该算法的时间复杂度为`$O(n)$`.
```java
class Solution {
    public int largestRectangleArea(int[] heights) {
        int res = 0, n = heights.length;
        int[] arr = new int[n+1];
        System.arraycopy(heights, 0, arr, 0, n);
        Deque<Integer> deque = new ArrayDeque<>();
        for (int i = 0; i < n + 1; i++) {
            while (!deque.isEmpty() && arr[i] <= arr[deque.peekLast()]) {
                int h = arr[deque.pollLast()], l = deque.isEmpty() ? -1 : deque.peekLast();
                res = Math.max(res, h * (i - l - 1));
            }
            deque.offerLast(i);
        }
        return res;
    }
}
```


## 85. Maximal Rectangle
Given a `rows x cols` binary `matrix` filled with `0`'s and `1`'s, find the largest rectangle containing only `1`'s and return its area.

Example 1:
```
Input: matrix = [
    ["1","0","1","0","0"],
    ["1","0","1","1","1"],
    ["1","1","1","1","1"],
    ["1","0","0","1","0"]
]
Output: 6
Explanation: The maximal rectangle is shown in the above picture.
```

### Solution
题目要求返回由`1`组成的最大矩形面积. 若使用上一题的思路, 可轻松求得`matrix`第一行中的最大矩形面积; 将第二行的数值添加第一行, 即可得到`matrix`前两行中的最大矩形面积, 以此类推, 可获得`matrix`中的最大矩形面积. 该算法的时间复杂度为`$O(mn)$`(`m`和`n`为`matrix`的行数和列数).
```java
class Solution {
    public int maximalRectangle(char[][] matrix) {
        int m = matrix.length, n = matrix[0].length, res = 0;
        int[] arr = new int[n+1];
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                arr[j] = matrix[i][j] == '0' ? 0 : arr[j] + 1;
            }
            res = Math.max(res, maxRectangle(arr));
        }
        return res;
    }

    private int maxRectangle(int[] arr) {
        int n = arr.length, res = 0;
        Deque<Integer> deque = new ArrayDeque<>();
        for (int i = 0; i < n; i++) {
            while (!deque.isEmpty() && arr[i] <= arr[deque.peekLast()]) {
                int h = arr[deque.pollLast()], l = deque.isEmpty() ? -1 : deque.peekLast();
                res = Math.max(res, h * (i - l - 1));
            }
            deque.offerLast(i);
        }
        return res;
    }
}
```

## 2030. Smallest K-Length Subsequence With Occurrences of a Letter
You are given a string `s`, an integer `k`, a letter `letter`, and an integer `repetition`.

Return the **lexicographically smallest** subsequence of `s` of length `k` that has the letter `letter` appear at least `repetition` times. The test cases are generated so that the `letter` appears in `s` at least `repetition` times.

A **subsequence** is a string that can be derived from another string by deleting some or no characters without changing the order of the remaining characters.

A string `a` is **lexicographically smaller** than a string `b` if in the first position where `a` and `b` differ, string `a` has a letter that appears earlier in the alphabet than the corresponding letter in `b`.

Example 1:
```
Input: s = "leet", k = 3, letter = "e", repetition = 1
Output: "eet"
Explanation: There are four subsequences of length 3 that have the letter 'e' appear at least 1 time:
- "lee" (from "leet")
- "let" (from "leet")
- "let" (from "leet")
- "eet" (from "leet")
The lexicographically smallest subsequence among them is "eet".
```

### Solution
题目要求返回最小字典序的字符串, 而一个**单调递增**的单调栈会不断尝试将**位置靠前且字典序更大的字符**替换为**位置靠后且字典序更小的字符**, 因此可使用单调栈, 但该题存在两条附件条件:
1. 返回的字符串长度为`k`
2. 返回的字符串中包含至少`reptition`个字符`letter`

维护一个单调递增的单调栈的过程可分为两个步骤:
1. 出栈: 查看当前字符是否小于栈顶字符, 若小于, 则弹出栈顶字符
2. 入栈: 将当前字符放入栈中

为满足题目的额外要求, 需在出栈和入栈时附加额外判断. 假设当前字符为`c`, 栈顶元素为`t`
1. 出栈:
    * 若栈为空或`c >= t`, 无需任何操作
    * 若栈不为空, 且`c < t`, 则需考虑题目的附加条件:
        * 若弹出`t`导致后续字符无法满足长度`k`, 则不弹出`t`
        * 若`t`为`letter`, 且弹出`t`导致后续字符无法满足至少`repetition`个`letter`, 则不弹出`t`
    * 若上述条件均满足, 弹出`t`才能保证最小字典序
2. 入栈:
    * 若`c == letter`: 直接放入栈中
    * 若`c != letter`: 若添加该字符后, 剩余空间无法满足`reptition`个`letter`, 则不添加该字符

```java
class Solution {
    public String smallestSubsequence(String s, int k, char letter, int repetition) {
        Deque<Character> deque = new ArrayDeque<>();
        int cnt = 0, n = s.length();
        for (char c: s.toCharArray()) {
            if (c == letter) ++cnt;
        }
        for (int i = 0; i < n; i++) {
            char c = s.charAt(i);
            while (!deque.isEmpty() && c < deque.peekLast() && (deque.size() + n - i > k) && (cnt >= repetition + (deque.peekLast() == letter ? 1 : 0))) {
                if (deque.pollLast() == letter) ++repetition;
            }
            if (c == letter) --cnt;
            if (deque.size() < k) {
                if (c == letter) {
                    deque.addLast(c);
                    --repetition;
                } else if (deque.size() + repetition < k) {
                    deque.addLast(c);
                }
            }
        }
        StringBuilder sb = new StringBuilder();
        while (!deque.isEmpty()) {
            sb.append(deque.pollFirst());
        }
        return sb.toString();
    }
}
```


## 321. Create Maximum Number
You are given two integer arrays `nums1` and `nums2` of lengths `m` and `n` respectively. `nums1` and `nums2` represent the digits of two numbers. You are also given an integer `k`.

Create the maximum number of length `k <= m + n` from digits of the two numbers. The relative order of the digits from the same array must be preserved.

Return an array of the `k` digits representing the answer.

Example 1:
```
Input: nums1 = [3,4,6,5], nums2 = [9,1,2,5,8,3], k = 5
Output: [9,8,6,5,3]
```

### Solution
对于一个字符串长度为`m`的字符串, 若需找出长度为`k`($k \le m$)的最大数, 可用单调栈将较小的元素弹出, 并保持单调栈内的元素单调递减; 本题要求返回两个数组的最大组合数, 因此可按以下步骤:
1. 使用单调栈, 保证两个数组分别保持有序的前提下, 找出每个数组的最大数
2. 将上一步获得的两个最大数组合为一个最大数

假设`$|\text{nums1}|$`为`m`, `$|\text{nums2}|$`为`n`, 且`$k \le m + n$`, 则`nums1`的可选长度为`$[max(k-n, 0), min(k, m)$]`. 单调栈和合并数字都可保证顺序, 因此返回的数字一定保持正序.

```java
class Solution {
    public int[] maxNumber(int[] nums1, int[] nums2, int k) {
        int[] res = new int[k], arr = null;
        for (int m = Math.max(k-nums2.length, 0); m <= Math.min(k, nums1.length); m++) {
            int[] arr1 = maxNum(nums1, m), arr2 = maxNum(nums2, k-m);
            arr = merge(arr1, arr2);
            if (largerThan(arr, 0, res, 0)) {
                res = arr;
            }
        }
        return res;
    }

    private int[] maxNum(int[] arr, int n) {
        Deque<Integer> deque = new ArrayDeque<>();
        for (int i = 0; i < arr.length; i++) {
            while (!deque.isEmpty() && arr[i] > deque.peekLast() && deque.size() + arr.length - i > n) {
                deque.pollLast();
            }
            deque.addLast(arr[i]);
        }
        int[] res = new int[n];
        for (int i = 0; i < n && !deque.isEmpty(); i++) {
            res[i] = deque.pollFirst();
        }
        return res;
    }

    private int[] merge(int[] arr1, int[] arr2) {
        int m = arr1.length, n = arr2.length, i = 0, j = 0;
        int[] res = new int[m+n];
        while (i < m && j < n) {
            res[i+j] = largerThan(arr1, i, arr2, j) ? arr1[i++] : arr2[j++];
        }
        while (i < m) {
            res[i+j] = arr1[i++];
        }
        while (j < n) {
            res[i+j] = arr2[j++];
        }
        return res;
    }

    private boolean largerThan(int[] arr1, int i, int[] arr2, int j) {
        while (i < arr1.length && j < arr2.length) {
            int d = arr1[i++] - arr2[j++];
            if (d != 0) return d > 0;
        }
        return i != arr1.length;
    }
}
```
