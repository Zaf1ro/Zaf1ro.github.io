---
title: Palindrome Linked List
category:
  - Algorithm
  - Linked List
tag:
  - Algorithm
abbrlink: d4c
date: 2018-02-07 19:29:19
---

## 1. Description
Given a singly linked list, determine if it is a palindrome.



## 2. Two Pointers Solution
思路: 使用两个节点: slow, fast. slow向后移动一次时, fast向后移动两次. 当 fast == null 或 fast.next == null时, slow一定遍历了半个链表. slow在遍历链表时对链表进行反转. 反转后从中心向两端遍历, 检查是否为回文链表. fast遍历完后分为两种情况:
* fast == null 时结束: 说明链表节点数为偶数
* fast.next == null时结束: 说明链表节点数为奇数

Time Complexity: $O(n)$
Space Complexity: $O(1)$

```java
/**
 * Definition for singly-linked list.
 * public class ListNode {
 *   int val;
 *   ListNode next;
 *   ListNode(int x) { val = x; }
 * }
 */

class Solution {
  public boolean isPalindrome(ListNode head) {
    ListNode slow = head, fast = head, pre = null, next = null;
    while (fast != null && fast.next != null) {
      fast = fast.next.next;  /* fast一直向后遍历 */
      next = slow.next; /* slow一边遍历, 一边反转链表 */
      slow.next = pre;
      pre = slow;
      slow = next;
    }

    /* 奇数节点, slow需要再向后移动一次 */
    if (fast != null) slow = slow.next;     

    while (slow != null) { /* 从中心向左右遍历 */
      if(pre.val != slow.val) return false;
      pre = pre.next;
      slow = slow.next;
    }
    return true;
  }
}
```
