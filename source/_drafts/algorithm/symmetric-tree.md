---
title: Symmetric Tree
category:
  - Algorithm
  - Tree
tag:
  - Algorithm
abbrlink: 2302601484
date: 2018-02-13 13:39:21
---

## 1. Description
Given a binary tree, check whether it is a mirror of itself (ie, symmetric around its center).
For example, this binary tree [1,2,2,3,4,4,3] is symmetric:
```text
    1
   / \
  2   2
 / \ / \
3  4 4  3
```
But the following [1,2,2,null,3,null,3] is not:
```text
    1
   / \
  2   2
   \   \
   3    3
```



## 2. DFS
对称树的成立条件:
1. node.left.left == node.right.right
2. node.left.right == node.right.left

注意: 判断左节点和右节点是否为null
```java
/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *     int val;
 *     TreeNode left;
 *     TreeNode right;
 *     TreeNode(int x) { val = x; }
 * }
 */

class Solution {
  public boolean helper(TreeNode left, TreeNode right){
    if (left == null || right == null) return left == right;
    if (left.val != right.val) return false;
    return helper(left.left, right.right) && helper(left.right, right.left);
  }
  
  public boolean isSymmetric(TreeNode root) {
    if (root == null) return true;
    return helper(root.left, root.right);
  }
}
```