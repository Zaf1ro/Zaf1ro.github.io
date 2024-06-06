---
title: Invert Binary Tree
category:
  - Algorithm
  - Tree
tag:
  - Algorithm
abbrlink: 134380217
date: 2018-02-13 10:28:54
---

## 1. Description
Invert a binary tree.
```text
     4
   /   \
  2     7
 / \   / \
1   3 6   9
```
to
```text
     4
   /   \
  7     2
 / \   / \
9   6 3   1
```



## 2. DFS
思路: 深度遍历的同时不断交换节点的左子树和右子树
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
  public void swapSubtree(TreeNode root){
    TreeNode tmp = root.left;
    root.left = root.right;
    root.right = tmp;
  }
  
  public TreeNode invertTree(TreeNode root) {
    if (root == null) return null;
    swapSubtree(root);
    invertTree(root.left);
    invertTree(root.right);
    return root;
  }
}
```
