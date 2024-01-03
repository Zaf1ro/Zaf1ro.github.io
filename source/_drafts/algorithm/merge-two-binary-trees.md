---
title: Merge Two Binary Trees
category:
  - Algorithm
  - Tree
tag:
  - Algorithm
abbrlink: 4016618364
date: 2018-02-13 10:57:39
---

## 1. Description
Given two binary trees and imagine that when you put one of them to cover the other, some nodes of the two trees are overlapped while the others are not.
You need to merge them into a new binary tree. The merge rule is that if two nodes overlap, then sum node values up as the new value of the merged node. Otherwise, the NOT null node will be used as the node of new tree.

Example 1:
```text
Input: 
	Tree 1                     Tree 2                  
          1                     2      
         / \                   / \                 
        3   2                 1   3 
       /                       \   \    
      5                         4   7           

Output: 
	     3
	    / \
	   4   5
	  / \   \ 
	 5   4   7
```



## 2. DFS
思路: 深度遍历的同时将两个树的节点相加
注意: 判断遍历的节点是否为null
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
  public TreeNode mergeTrees(TreeNode t1, TreeNode t2) {
    if (t1 == null && t2 == null)
      return null;

    TreeNode node = new TreeNode((t1 == null ? 0 : t1.val) + (t2 == null ? 0 : t2.val));
    node.left = mergeTrees(t1 == null ? t1 : t1.left, t2 == null ? t2 : t2.left);
    node.right = mergeTrees(t1 == null ? t1 : t1.right, t2 == null ? t2 : t2.right);
    return node;
  }
}
```
