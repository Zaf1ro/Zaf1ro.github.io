---
title: DP - Longest Common Subsequence
abbrlink: 8be9
date: 2024-06-02 13:24:59
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
该问题属于
Longest common subsequence(最长公共子序列, 简称**LCS**)的问题描述为: 给定两个字符串$s1$和$s2$, $s1$的长度为$m$, $s2$的长度为$n$, 求他们的最长公共子序列.
这里牵扯到**subsequence**的定义, 通常字符串有关的算法会涉及两种子集定义:
* subsequence: 子序列, 从字符串$S$中将若干字符提取出来, 且不改变字符相对位置的序列, 因此字符不连续但顺序不变
* substring: 字串, 表示字符串$S$中从$i$到$j$的一段子字符串, 字符连续且顺序不变

例如, $s1 = zabcde$, $s2 = acez$, 则s1和s2的公共子序列为`$ace$`.


## 2. Brute Force
暴力算法的思路为: 穷举$s1$和$s2$的所有子序列, 并找到最长的相同序列.


## Dynamic Programming
子序列的本质在于选或不选当前字符对. 假设从后向前遍历$s1$和$s2$, 对于$s1$的第$i$个字符和$s2$的第$j$个字符, 有以下四种选择:
* 选$s1[i]$, 也选$s2[j]$: 子问题变为求$s1$的前$i-1$个字符和$s2$的前$j-1$个字符的最长公共子序列
* 不选$s1[i]$, 也不选$s2[j]$: 子问题变为求$s1$的前$i-1$个字符和$s2$的前$j-1$个字符的最长公共子序列
* 选$s1[i]$, 不选$s2[j]$: 子问题变为求$s1$的前$i$个字符和s2的前$j-1$个字符的最长公共子序列
* 选$s2[j]$, 不选$s1[i]$: 子问题变为求$s1$的前$i-1$个字符和s2的前$j$个字符的最长公共子序列

可以发现, 无论哪种情况都会缩短$s1$或$s2$的长度, 因此用动态规划解决该问题时步骤如下:
1. 划分阶段: 按照$s1$和$s2$的坐标进行阶段划分
2. 定义状态: $s1$的坐标$i$和$s2$的坐标$j$, 定义一个二维数组$dp[i][j]$, 第一维表示$s1$的前$i$个字符, 第二维表示$s2$的前$j$个字符, 二维数组的值表示$s1$的前$i$个字符和$s2$的前$j$个字符组成的的最长公共子序列.
3. 状态转移方程: 根据上述不同选择情况, 该算法的状态转移方程可写为:
    $$
    dp[i][j] = 
    \begin{cases}
        max(dp[i-1][j], dp[i][j-1], dp[i-1][j-1] + 1), & s1[i] = s2[j] \\\\[2ex]
        max(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]), & s1[i] \ne s2[j]
    \end{cases}
    $$

    上述状态转移方程存在两点可以优化:
    * 当$s1[i] = s2[j]$时, 不需要跳过$s1[i]$或$s2[j]$, 因为`跳过字符`并不能获得比`不跳过`更长的公共子序列
    * 当$s1[i] = s2[j]$时, 不需要跳过$s1[i]$和$s2[j]$, 因为$dp[i-1][j]$和$dp[i][j-1]$已包含$dp[i-1][j-1]$的情况

    简化后的状态转移方程如下:
    $$
    dp[i][j] = 
    \begin{cases}
        dp[i-1][j-1] + 1,            & s1[i] = s2[j] \\\\[2ex]
        max(dp[i-1][j], dp[i][j-1]), & s1[i] \ne s2[j]
    \end{cases}
    $$
4. 初始条件: 若$i = 0$或$j = 0$, 则$s1$或$s2$的长度为0, 则最长公共子序列的长度为0.
5. 最终结果: 根据状态定义, $dp[m][n]$表示$s1$的前$m$个字符和$s2$的前$n$个字符的最长公共子序列长度

算法的时间复杂度为$O(m \times n)$, 空间复杂度为$O(m+n)$, $m$为$s1$的长度, $n$为$s2$的长度.


## 4. Leetcode
### 1143. Longest Common Subsequence
#### Problem Description
Given two strings `text1` and `text2`, return the length of their longest **common subsequence**. If there is no common subsequence, return `0`.
A **subsequence** of a string is a new string generated from the original string with some characters (can be none) deleted without changing the relative order of the remaining characters.
* For example, `"ace"` is a subsequence of `"abcde"`.

A **common subsequence** of two strings is a subsequence that is common to both strings.

Example 1:
```
Input: text1 = "abcde", text2 = "ace" 
Output: 3  
Explanation: The longest common subsequence is "ace" and its length is 3.
```

#### Solution
```java
class Solution {
    public int longestCommonSubsequence(String text1, String text2) {
        int m = text1.length(), n = text2.length();
        int[] dp = new int[n+1];
        for (int i = 0; i < m; i++) {
            int prev = dp[0];
            for (int j = 0; j < n; j++) {
                int t = dp[j+1];
                dp[j+1] = text1.charAt(i) == text2.charAt(j) ? prev + 1 : Math.max(dp[j+1], dp[j]);
                prev = t;
            }
        }
        return dp[n];
    }
}
```

### 583. Delete Operation for Two Strings
#### Problem Description
Given two strings `word1` and `word2`, return the **minimum number of steps** required to make `word1` and `word2` the same.
In one step, you can delete exactly one character in either string.

Example 1:
```
Input: word1 = "sea", word2 = "eat"
Output: 2
Explanation: You need one step to make "sea" to "ea" and another step to make "eat" to "ea".
```

#### Solution
```java
class Solution {
    public int minDistance(String word1, String word2) {
        int m = word1.length(), n = word2.length(); 
        int[][] dp = new int[m+1][n+1];
        for (int i = 1; i <= m; i++) {
            dp[i][0] = i;
        }
        for (int j = 1; j <= n; j++) {
            dp[0][j] = j;
        }
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                dp[i+1][j+1] = word1.charAt(i) == word2.charAt(j) ? dp[i][j] : Math.min(dp[i+1][j], dp[i][j+1]) + 1; 
            }
        }
        return dp[m][n];
    }
}
```

### 97. Interleaving String
#### Problem Description
Given strings `s1`, `s2`, and `s3`, find whether `s3` is formed by an **interleaving** of `s1` and `s2`.
An **interleaving** of two strings `s` and t is `a` configuration where `s` and `t` are divided into `n` and `m` substrings respectively, such that:
* $s = s_1 + s_2 + \cdots + s_n$
* $t = t_1 + t_2 + \cdots + t_m$
* $|n - m| \le 1$
* The interleaving is $s_1 + t_1 + s_2 + t_2 + s_3 + t_3 + \cdots$ or $t_1 + s_1 + t_2 + s_2 + t_3 + s_3 + \cdots$

Example 1:
```
Input: s1 = "aabcc", s2 = "dbbca", s3 = "aadbbcbcac"
Output: true
Explanation: One way to obtain s3 is:
Split s1 into s1 = "aa" + "bc" + "c", and s2 into s2 = "dbbc" + "a".
Interleaving the two splits, we get "aa" + "dbbc" + "bc" + "a" + "c" = "aadbbcbcac".
Since s3 can be obtained by interleaving s1 and s2, we return true.
```

#### Solution
```java
class Solution {
    public boolean isInterleave(String s1, String s2, String s3) {
        int m = s1.length(), n = s2.length(), k = s3.length();
        if (m + n != k) return false;
        boolean[][] dp = new boolean[m+1][n+1];
        dp[0][0] = true;
        for (int i = 0; i < m && i < k && s1.charAt(i) == s3.charAt(i); i++) {
            dp[i+1][0] = true;
        }
        for (int j = 0; j < n && j < k && s2.charAt(j) == s3.charAt(j); j++) {
            dp[0][j+1] = true;
        }
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                if (s1.charAt(i) == s3.charAt(i+j+1)) {
                    dp[i+1][j+1] |= dp[i][j+1];
                }
                if (s2.charAt(j) == s3.charAt(i+j+1)) {
                    dp[i+1][j+1] |= dp[i+1][j];
                }
            }
        }
        return dp[m][n];
    }
}
```

### 72. Edit Distance
#### Problem Description
Given two strings `word1` and `word2`, return **the minimum number of operations** required to convert `word1` to `word2`.
You have the following three operations permitted on a word:
* Insert a character
* Delete a character
* Replace a character

Example 1:
```
Input: word1 = "horse", word2 = "ros"
Output: 3
Explanation: 
horse -> rorse (replace 'h' with 'r')
rorse -> rose (remove 'r')
rose -> ros (remove 'e')
```

#### Solution
```java
class Solution {
  public int minDistance(String word1, String word2) {
    int m = word1.length(), n = word2.length();
    int[][] dp = new int[m+1][n+1];
    for (int i = 1; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int i = 1; i <= n; i++) {
      dp[0][i] = i;
    }
    for (int i = 0; i < m; i++) {
      for (int j = 0; j < n; j++) {
        if (word1.charAt(i) == word2.charAt(j)) {
          dp[i+1][j+1] = dp[i][j];
        } else {
          dp[i+1][j+1] = Math.min(dp[i][j], Math.min(dp[i+1][j], dp[i][j+1])) + 1;
        }
      }
    }
    return dp[m][n];
  }
}
```

### 1458. Max Dot Product of Two Subsequences
#### Problem Description
Given two arrays `nums1` and `nums2`.
Return the maximum dot product between **non-empty** subsequences of `nums1` and `nums2` with the same length.
A subsequence of a array is a new array which is formed from the original array by deleting some (can be none) of the characters without disturbing the relative positions of the remaining characters. (ie, `[2,3,5]` is a subsequence of `[1,2,3,4,5]` while `[1,5,3]` is not).

Example 1:
```
Input: nums1 = [2,1,-2,5], nums2 = [3,0,-6]
Output: 18
Explanation: Take subsequence [2,-2] from nums1 and subsequence [3,-6] from nums2.
Their dot product is (2*3 + (-2)*(-6)) = 18.
```

#### Solution
```java
class Solution {
    public int maxDotProduct(int[] nums1, int[] nums2) {
        int m = nums1.length, n = nums2.length, max = Integer.MIN_VALUE;
        int[][] dp = new int[m+1][n+1];
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                int k = nums1[i] * nums2[j];
                max = Math.max(max, k);
                dp[i+1][j+1] = Math.max(k+dp[i][j], Math.max(dp[i][j+1], dp[i+1][j]));
            }
        }
        return dp[m][n] > 0 ? dp[m][n] : max; 
    }
}
```

### 1092. Shortest Common Supersequence 
#### Problem Description
Given two strings `str1` and `str2`, return the shortest string that has both `str1` and `str2` as **subsequences**. If there are multiple valid strings, return any of them.
A string `s` is a subsequence of string `t` if deleting some number of characters from `t` (possibly `0`) results in the string `s`.

Example 1:
```
Input: str1 = "abac", str2 = "cab"
Output: "cabac"
Explanation: 
str1 = "abac" is a subsequence of "cabac" because we can delete the first "c".
str2 = "cab" is a subsequence of "cabac" because we can delete the last "ac".
The answer provided is the shortest such string that satisfies these properties.
```

#### Solution
```java
class Solution {
    public String shortestCommonSupersequence(String str1, String str2) {
        int m = str1.length(), n = str2.length();
        int[][] dp = new int[m+1][n+1];
        for (int i = 1; i <= m; i++) dp[i][0] = i;
        for (int i = 1; i <= n; i++) dp[0][i] = i;
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                if (str1.charAt(i) == str2.charAt(j)) {
                    dp[i+1][j+1] = dp[i][j] + 1;
                } else {
                    dp[i+1][j+1] = Math.min(dp[i+1][j], dp[i][j+1]) + 1;
                }
            }
        }
        int i = m-1, j = n-1;
        StringBuilder sb = new StringBuilder();
        while (i >= 0 || j >= 0) {
            if (i < 0) {
                sb.insert(0, str2.substring(0, j+1));
                break;
            }
            if (j < 0) {
                sb.insert(0, str1.substring(0, i+1));
                break;
            }
            if (str1.charAt(i) == str2.charAt(j)) {
                sb.insert(0, str1.charAt(i--));
                --j;
            } else if (dp[i][j+1] < dp[i+1][j]) {
                sb.insert(0, str1.charAt(i--));
            } else {
                sb.insert(0, str2.charAt(j--));
            }
        }
        return sb.toString();
    }
}
```
