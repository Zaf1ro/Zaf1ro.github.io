---
title: Depth of Binary Tree
category:
  - Algorithm
  - Tree
tag:
  - Algorithm
abbrlink: '5994'
date: 2018-02-12 18:07:22
---

## 1. Maximum Depth of Binary Tree
### 1.1 Description
Given a binary tree, find its maximum depth.
The maximum depth is the number of nodes along the longest path from the root node down to the farthest leaf node.
For example: Given binary tree [3, 9, 20, null, null, 15, 7],
```text
     3
    / \
   9  20
  / \
 15  7
```
return its depth = 3.

### 1.2 DFS
思路: 深度遍历时将每个节点的较长的子树长度传给父节点
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
  public int maxDepth(TreeNode root) {
    if (root == null) return 0;
    int leftDepth = maxDepth(root.left);
    int rightDepth = maxDepth(root.right);
    return Math.max(leftDepth, rightDepth) + 1;
  }
}
```



## 2. Minimum Depth of Binary Tree
### 2.1 Description
Given a binary tree, find its minimum depth.
The minimum depth is the number of nodes along the shortest path from the root node down to the nearest leaf node.

### 2.2 DFS
思路: 深度遍历时将每个节点的较短的子树长度传给父节点
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
  public int minDepth(TreeNode root) {
    if (root == null) return 0;
    int leftDepth = minDepth(root.left);
    int rightDepth = minDepth(root.right);
    return (leftDepth == 0 || rightDepth == 0) ? leftDepth + rightDepth + 1 : Math.min(leftDepth, rightDepth) + 1;
  }
}
```