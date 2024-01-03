---
title: Intersection of Two Linked Lists
category:
  - Algorithm
  - Linked List
tag:
  - Algorithm
abbrlink: a3ff
date: 2018-02-21 12:38:20
---

## 1. Description
Write a program to find the node at which the intersection of two singly linked lists begins.
For example, the following two linked lists:
```text
A:    a1 → a2
        ↘
          c1 → c2 → c3
        ↗      
B: b1 → b2 → b3
```



## 2. Solution
思路: 假设链表A和链表B的共同段的长度为x, 链表A非共同段的长度为y, 链表B费共同段的长度为z, 则A的总长度为x+y, B的总长度为x+z. 假设两个节点坐标m和n分别从A和B的链表头部出发, m走到A的终点后再从B的头部出发, n走到B的终点后再从A的头部出发, 则m和n走过的长度为x+y+z. 所以两者一定会在intersection处相遇.

Time Complexity: $O(m+n)$
Space Complexity: $O(1)$

```java
/**
 * Definition for singly-linked list.
 * public class ListNode {
 *   int val;
 *   ListNode next;
 *   ListNode(int x) {
 *     val = x;
 *     next = null;
 *   }
 * }
 */

public class Solution {
  public ListNode getIntersectionNode(ListNode headA, ListNode headB) {
    if (headA == null || headB == null) return null;
    ListNode a = headA, b = headB;
    while (a != b) {
      a = a == null ? headB : a.next;   /* keep going or start from another linked-list */
      b = b == null ? headA : b.next;
    }
    return a;
  }
}
```
