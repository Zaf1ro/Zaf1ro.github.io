---
title: Depth Of Binary Tree
category:
  - Algorithm
  - Tree
tag:
  - Algorithm
abbrlink: b9b5
date: 2018-08-02 11:23:34
---

## 1. Maximum Depth of Binary Tree
### 1.1 Description
Given a binary tree, find its maximum depth.
The maximum depth is the number of nodes along the longest path from the root node down to the farthest leaf node.
Example:
```text
Given binary tree [3, 9, 20, null, null, 15, 7],
  3
   / \
  9  20
  /  \
   15   7
```
return its depth = 3.

### 1.2 DFS Solution
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
    return 1 + Math.max(maxDepth(root.left), maxDepth(root.right));
  }
}
```



## 2. Minimum Depth of Binary Tree
### 2.1 Description
Given a binary tree, find its minimum depth.
The minimum depth is the number of nodes along the shortest path from the root node down to the nearest leaf node.
Example:
```text
Given binary tree [3,9,20,null,null,15,7]:
    3
   / \
  9  20
    /  \
   15   7
```
return its minimum depth = 2.

### 2.2 DFS Solution
```java
class Solution {
  public int minDepth(TreeNode root) {
    if (root == null) return 0;
    
    int left = minDepth(root.left);
    int right = minDepth(root.right);
    if (left==0 && right==0) return 1;
    else if (left==0 || right==0) return left==0 ? right+1 : left+1;
    return Math.min(left,right)+1;
  }
}
```

## 2.3 BFS Solution
```java
class Solution {
  public int minDepth(TreeNode root) {
    if (root == null) return 0;
    
    Queue<TreeNode> queue = new LinkedList<>();
    queue.offer(root);
    int res = 1;
    while (!queue.isEmpty()) {
      int len = queue.size();
      while (len-- > 0) {
        TreeNode node = queue.poll();
        if (node.left==null && node.right==null)
          return res;
        if(node.left != null)
          queue.offer(node.left);
        if(node.right != null)
          queue.offer(node.right);
      }
      res++;
    }
    return res;
  }
}
```
