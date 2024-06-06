---
title: DP (Dynamic Programming)
abbrlink: '1614'
date: 2024-04-04 12:16:09
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
Dynamic programming(动态规划), 简称**DP**, 是一种求解多阶段决策过程最优化问题的方法. 简单来说, DP用递归的方式将复杂问题分解为更简单的子问题.
DP的整体思路可分为两步:
* 将**复杂问题**分解为若干个**重叠的子问题**, 每个子问题的求解过程都构成一个**阶段**, 在完成一个阶段的计算后, DP才会执行下一个阶段的计算
* 求解子问题的过程中, 可按照**Top-down approach**(自顶向下方式)或**Bottom-up approach**(自底向上方式)求解子问题的解, 并将结果保存到一个表格中, 当再次求解该子问题时, 可直接从表格中查询解, 从而避免大量重复计算.

DP和分治算法的不同之处在于:
* DP求解的问题中, 子问题往往是相互关联的, 且会存在多个重叠的子问题
* DP会将子问题的解保存到表格中, 从而避免重复计算


## 2. Applicable Range
并不是所有问题都可以用DP解决, DP解决的问题通常满足三个特征.

### 2.1 Optimal substructure
若一个问题拥有**最优子结构**的性质, 则该问题的最优解也包含其子问题的最优解. 举个例子, 假设原问题$S$可拆分为多个子问题$\Arr{a_1, a_2, a_3, a_4}$, $a_1$得到一个最优解后, 问题转换为求解$\Arr{a_2, a_3, a_4}$, 若$S$的最优解可由$a_1$的局部最优解和$\Arr{a_2, a_3, a_4}$的最优解构成, 则$S$具有最优子结构性质.

### 2.2 Overlapping Subproblem
若一个问题拥有**重叠子问题**的性质, 则该问题拆分后的子问题并不总是新问题, 换句话说, 多个子问题的解依赖于另一个子问题的解. DP算法可利用该性质将每个子问题的解保存到表格中, 并在以后使用时直接查询. 以**fibonacci sequence**(斐波那契数列)为例, $f(5)$的解依赖于$f(3)$和$f(4)$的解, 而$f(4)$的解也依赖于$f(3)$, 因此该问题拥有重叠子问题性质.

### 2.3 No After-Effect
若一个问题具有无后效性, 则一旦一个子问题计算后, 该问题的解永远不会更改. 举个例子, 在有向无环图中寻找最短路径时, 假设我们已找到从A到D的最短路径值, 无论之后路径如何选择, 从A到D的最短路径值永远不会改变.


## 3. Steps
动态规划解决问题的思路如下:
1. 划分问题: 将原问题按顺序(时间顺序, 空间顺序, 或其他顺序)分解为若干个相互关联的子问题, 划分后的子问题一定是有序的, 否则问题无解
2. 定义状态: 将与子问题相关的所有变量(位置, 数量, 体积, 空间等)作为一个**状态**, 状态需具备无后效性
3. 状态转移: 根据相邻两个状态的关系, 推导出状态间的转移方式, 也称为**状态转移方程**
4. 初始条件和边界条件: 根据问题, 状态定义, 和状态转移方程, 确定初始条件和边界条件
5. 最终结果: 按照一定顺序求解每个子问题, 确定最终结果


## 4. Category
动态规划问题可划分为几种不同类型的问题:
* Linear DP(线性DP): 具有**线性**阶段划分的动态规划方法
* Tree DP: 在**树形结构**上进行推导的动态规划方法
* Digit DP: 与**数位**相关的计数类动态规划方法
* Probabilistic DP: 用于求解**概率与期望**的动态规划方法
* State Compression DP: 应用于**小规模**数据上, 利用**二进制**性质来进行状态定义与状态转移的动态规划方法

### 4.1 Linear Dynamic Programming
线性DP还可以划分为其他DP问题:
* 单串DP: 输入为单个数组或字符串的线性DP问题, 状态可定义为$dp[i]$, 如`最长递增子序列`(LIS), `最大子数组和`
* 双串DP: 输入为两个数组或字符串的线性DP问题, 状态可定义为$dp[i][j]$, 如`最长公共子序列`(LCS), `最长重复子数组`, `编辑距离`

背包问题, 区间DP问题, 和数位问题都属于线性DP问题, 但由于每个问题都有很多变种, 因此通常会分开讨论.