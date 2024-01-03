---
title: Same Tree
category:
  - Algorithm
  - Tree
tag:
  - Algorithm
abbrlink: 4098259726
date: 2018-02-13 10:41:21
---

## 1. Description
Given two binary trees, write a function to check if they are the same or not.
Two binary trees are considered the same if they are structurally identical and the nodes have the same value.
```text
Input:     1         1
          / \       / \
         2   3     2   3

        [1,2,3],   [1,2,3]

Output: true
```
 
```text
Input:     1         1
          /           \
         2             2

        [1,2],     [1,null,2]

Output: false
```
 
```text
Input:     1         1
          / \       / \
         2   1     1   2

        [1,2,1],   [1,1,2]

Output: false
```

## 2. DFS
相同树的判断条件:
* node1.left == node2.left
* node1.right == node2.right

注意: 判断node1和node2是否为null
```java
/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *   int val;
 *   TreeNode left;
 *   TreeNode right;
 *   TreeNode(int x) { val = x; }
 * }
 */

class Solution {
  public boolean isSameTree(TreeNode p, TreeNode q) {
    if (p == null && q == null) return p == q;
    if (p.val != q.val) return false;
    return isSameTree(p.left, q.left) && isSameTree(p.right, q.right);
  }
}
```
