---
title: Balanced Binary Tree
category:
  - Algorithm
  - Tree
tag:
  - Algorithm
abbrlink: d6b9
date: 2018-02-13 13:10:28
---


## 1. Description
Given a binary tree, determine if it is height-balanced.
For this problem, a height-balanced binary tree is defined as: a binary tree in which the depth of the two subtrees of every node never differ by more than 1.
Example 1:
```
Given the following tree [3,9,20,null,null,15,7]:
    3
   / \
  9  20
    /  \
   15   7
Return true.
```

Example 2:
Given the following tree [1,2,2,3,3,null,null,4,4]:
```
       1
      / \
     2   2
    / \
   3   3
  / \
 4   4
Return false.
```



## 2. DFS
思路: 每个节点都判断其左子树和右子树的高度差是否大于1:
1. 如果节点左子树和右子树的高度差大于1, 则返回给上层节点Integer.MIN_VALUE
2. 如果节点左子树和右子树的高度差小于等于1, 则返回给上层其高度

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
  public int helper(TreeNode root) {
    if (root == null) return 0;
    int leftDepth = helper(root.left) + 1;
    int rightDepth = helper(root.right) + 1;
    if (leftDepth < 0 || rightDepth < 0) return Integer.MIN_VALUE;
    if (Math.abs(leftDepth - rightDepth) > 1) return Integer.MIN_VALUE;
    return Math.max(leftDepth, rightDepth);
  }
  
  public boolean isBalanced(TreeNode root) {
    return helper(root) >= 0; 
  }
}
```