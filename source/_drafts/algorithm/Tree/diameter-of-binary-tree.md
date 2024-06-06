---
title: Diameter of Binary Tree
category:
  - Algorithm
  - Tree
tag:
  - Algorithm
abbrlink: 3652139352
date: 2018-02-13 14:47:03
---

## 1. Diameter of Binary Tree
Given a binary tree, you need to compute the length of the diameter of the tree. The diameter of a binary tree is the length of the longest path between any two nodes in a tree. This path may or may not pass through the root.
Example:
Given a binary tree 
```text
      1
     / \
    2   3
   / \   
  4   5  
```
Return 3, which is the length of the path [4, 2, 1, 3] or [5, 2, 1, 3].



## 2. DFS
思路: 由于每个节点都可能是longest path中的一部分, 所以需要深度遍历每个节点的左子树和右子树, 并将该节点的高度传给父节点
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
  int max = 0;
  
  public int helper(TreeNode root) {
    if (root == null) return 0;
    int leftDepth = helper(root.left);
    int rightDepth = helper(root.right);
    max = Math.max(max, leftDepth + rightDepth);
    return Math.max(leftDepth, rightDepth) + 1;
  }
  
  public int diameterOfBinaryTree(TreeNode root) {
    helper(root);
    return max;
  }
}
```
