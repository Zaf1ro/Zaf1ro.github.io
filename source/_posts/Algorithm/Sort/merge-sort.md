---
title: Merge Sort
category:
  - Algorithm
  - Sort
tag:
  - Algorithm
abbrlink: ab19
date: 2023-03-21 17:03:28
keywords:
description:
---

## 1. Merge Sort
Merge sort(归并排序)是一种**comparison-based sorting algorithm**(基于比较的排序算法), 并且大部分实现都能做到stable sort(相同元素在输入和输出中的相对位置保持不变). Merge sort是一种**divide-and-conquer algorithm**(分治算法): 将两个已排序的数组合并为一个大的排序数组, 该操作可递归排序整个数组: 将数组分为两半, 排序这两个数组(递归), 合并两个数组. 算法时间复杂度为$O(n\log(n))$, 空间复杂度分为两种情况:
* $O(n)$:: 申请一个辅助数组, merge两个数组时存放元素
* $O(1)$: In-place merge sort(原地归并排序), 但此类算法存在一些妥协: 要么无法做到stable, 要么时间复杂度上升到$O(n\log^2(n))$, 或对数据集有限制条件, 且算法实现较复杂.

时间复杂度为$O(n\log(n))$, 且空间复杂度为$O(n)$的merge sort分为以下两种实现方法.

### 1.1 Top-down Merge Sort
Top-down merge sort递归地将数组拆分为子数组, 直到子数组的长度为1, 然后在每个递归层级中将拆分的子数组合并为一个大的数组, 如下图:
![Top-down Merge Sort](/images/Algorithm/merge-sort-top-down.png)

以下是Top-down merge sort的Java实现:
```java
class Solution {
    public int[] sortArray(int[] nums) {
        int n = nums.length;
        mergeSort(nums, new int[n], 0, n-1);
        return nums;
    }

    private void mergeSort(int[] nums, int[] aux, int l, int r) {
        if (l >= r) return;
        int m = l + ((r - l) >> 1);
        mergeSort(nums, aux, l, m);
        mergeSort(nums, aux, m+1, r);
        merge(nums, aux, l, m, r);
    }

    private void merge(int[] nums, int[] aux, int l, int m, int r) {
        System.arraycopy(nums, l, aux, l, r - l + 1);
        int i = l, j = m + 1;
        for (int k = l; k <= r; k++) {
            if (i > m)                 nums[k] = aux[j++];
            else if (j > r)            nums[k] = aux[i++];
            else if (aux[i] <= aux[j]) nums[k] = aux[i++];
            else                       nums[k] = aux[j++];
        }
    }
}
```
以上代码存在很多可以优化的地方:
* 对于过小的数组, 可使用insertion sort排序
* 若两个拆分的数组已经排序好(`a[last] <= b[first]`), 则不需要合并
* 每次合并都需复制数值: 对拆分的两个子数组调用sort方法时, 第一次sort将结果放入辅助数组, 第二次sort将结果放回原数组, 因此需切换原数组和辅助数组

以下是优化后的Java实现:
```java
class Solution {
    public int[] sortArray(int[] nums) {
        int n = nums.length;
        mergeSort(Arrays.copyOf(nums, n), nums, 0, n-1);
        return nums;
    }

    private void mergeSort(int[] src, int[] dst, int l, int r) {
        if (l >= r) return;
        int m = l + ((r - l) >> 1);
        mergeSort(dst, src, l, m);
        mergeSort(dst, src, m+1, r);
        if (src[m] <= src[m+1]) {
            System.arraycopy(src, l, dst, l, r - l + 1);
            return;
        }
        merge(src, dst, l, m, r);
    }

    private void merge(int[] src, int[] dst, int l, int m, int r) {
        int i = l, j = m + 1;
        for (int k = l; k <= r; k++) {
            if (i > m)                 dst[k] = src[j++];
            else if (j > r)            dst[k] = src[i++];
            else if (src[i] <= src[j]) dst[k] = src[i++];
            else                       dst[k] = src[j++];
        }
    }
}
```

### 1.2 Bottom-up Merge Sort
Bottom-up merge sort的思路为: 先合并所有单元素, 再合并包含两个元素的子数组, 依次类推. 该方法的代码量更小, 且无需递归.
![Bottom-up Merge Sort](/images/Algorithm/merge-sort-bottom-up.png)

以下是Bottom-up merge sort的Java实现:
```java
class Solution {
    public int[] sortArray(int[] nums) {
        mergeSort(nums);
        return nums;
    }

    private void mergeSort(int[] nums) {
        int n = nums.length;
        int[] aux = new int[n];
        for (int len = 1; len < n; len <<= 1) {
            for (int l = 0; l < n-len; l += len+len) {
                merge(nums, aux, l, l+len-1, Math.min(l+len+len-1, n-1));
            }
        }
    }

    private void merge(int[] nums, int[] aux, int l, int m, int r) {
        System.arraycopy(nums, l, aux, l, r - l + 1);
        int i = l, j = m + 1;
        for (int k = l; k <= r; k++) {
            if (i > m)                 nums[k] = aux[j++];
            else if (j > r)            nums[k] = aux[i++];
            else if (aux[i] <= aux[j]) nums[k] = aux[i++];
            else                       nums[k] = aux[j++];
        }
    }
}
```


## 23. Merge k Sorted Lists
You are given an array of `k` linked-lists `lists`, each linked-list is sorted in ascending order.

Merge all the linked-lists into one sorted linked-list and return it.

Example 1:
```
Input: lists = [[1,4,5],[1,3,4],[2,6]]
Output: [1,1,2,3,4,4,5,6]
Explanation: The linked-lists are:
[
  1->4->5,
  1->3->4,
  2->6
]
merging them into one sorted list:
1->1->2->3->4->4->5->6
```

### Merge Sort
假设链表的总长度为`n`, 合并两个链表(已排序)需遍历两个链表, 时间复杂度为O(n); 若存在`k`个链表, 每次只合并其中的两个链表, 则时间复杂度为$O(\sum^k_{i=1}(i \times n)) = O(\frac{(1+k) \times k}{2} \times n) = O(k^2n)$. 因此可用merge sort的思想: 将k个链表合并为$\frac{k}{2}$个链表, 再将$\frac{k}{2}$合并为$\frac{k}{4}$个链表, 直到获得最终结果, 时间复杂度为$\sum^{\infty}_{i=1}{\frac{k}{2^i} \times 2^i n} = O(kn \times \log(k))$, 空间复杂度为$O(\log(k))$
```java
/**
 * Definition for singly-linked list.
 * public class ListNode {
 *     int val;
 *     ListNode next;
 *     ListNode() {}
 *     ListNode(int val) { this.val = val; }
 *     ListNode(int val, ListNode next) { this.val = val; this.next = next; }
 * }
 */
class Solution {
    public ListNode mergeKLists(ListNode[] lists) {
        if (lists.length == 0) return null;
        return mergeSort(lists, 0, lists.length-1);
    }

    private ListNode mergeSort(ListNode[] lists, int l, int r) {
        if (l >= r) return lists[l];
        int m = l + ((r - l) >> 1);
        ListNode l1 = mergeSort(lists, l, m), l2 = mergeSort(lists, m+1, r);
        return merge(l1, l2);
    }

    private ListNode merge(ListNode l1, ListNode l2) {
        ListNode dummy = new ListNode(), t = dummy;
        while (l1 != null && l2 != null) {
            if (l1.val <= l2.val) {
                t.next = l1;
                l1 = l1.next;
            } else {
                t.next = l2;
                l2 = l2.next;
            }
            t = t.next;
        }
        t.next = l1 == null ? l2 : l1;
        return dummy.next;
    }
}
```


## 315. Count of Smaller Numbers After Self
Given an integer array `nums`, return an integer array `counts` where `counts[i]` is the number of smaller elements to the right of `nums[i]`.

Example 1:
```
Input: nums = [5,2,6,1]
Output: [2,1,1,0]
Explanation:
To the right of 5 there are 2 smaller elements (2 and 1).
To the right of 2 there is only 1 smaller element (1).
To the right of 6 there is 1 smaller element (1).
To the right of 1 there is 0 smaller element.
```

### Merge Sort
Merge sort中, 每个元素都会和其右边的元素作对比, 例如, 索引`0`上的元素会先与索引`1`上的元素作对比, 再与索引`[2,3]`上的元素作对比, 依次类推. 假设合并时有两个子数组: 左子数组`a`和右子数组`b`, `a`中元素的index一定小于`b`的元素, 若取出`b`的元素, 则取出的元素一定小于`a`的首个元素(也意味着小于`a`的剩余所有元素), 满足题目要求. 因此下次取出`a`的元素时, 可将其加入`counts`中.
```java
class Solution {
    public List<Integer> countSmaller(int[] nums) {
        int n = nums.length;
        int[] src = new int[n]; // index of nums
        for (int i = 1; i < n; i++) {
            src[i] = i;
        }
        int[] count = new int[n], aux = Arrays.copyOf(src, n);
        mergeSort(nums, aux, src, 0, n-1, count);
        List<Integer> res = new ArrayList<>();
        for (int num: count) {
            res.add(num);
        }
        return res;
    }

    private void mergeSort(int[] nums, int[] src, int[] dst, int l, int r, int[] count) {
        if (l >= r) return;
        int m = l + ((r - l) >> 1);
        mergeSort(nums, dst, src, l, m, count);
        mergeSort(nums, dst, src, m+1, r, count);
        if (nums[src[m]] <= nums[src[m+1]]) {
            System.arraycopy(src, l, dst, l, r-l+1);
            return;
        }
        merge(nums, src, dst, l, m, r, count);
    }

    private void merge(int[] nums, int[] src, int[] dst, int l, int m, int r, int[] count) {
        int i = l, j = m + 1, cnt = 0;
        for (int k = l; k <= r; k++) {
            if (i > m) {
                dst[k] = src[j++];
            } else if (j > r || nums[src[i]] <= nums[src[j]]) {
                count[src[i]] += cnt; // all numbers in right subarry which retrieved before nums[i]
                dst[k] = src[i++];
            } else {
                cnt++; // nums[j] < nums[i]
                dst[k] = src[j++];
            }
        }
    }
}
```


## 2426. Number of Pairs Satisfying Inequality
You are given two **0-indexed** integer arrays `nums1` and `nums2`, each of size n, and an integer `diff`. Find the number of **pairs** `(i, j)` such that:
* `0 <= i < j <= n - 1`
* `nums1[i] - nums1[j] <= nums2[i] - nums2[j] + diff`

Return the **number of pairs** that satisfy the conditions.

Example 1:
```
Input: nums1 = [3,2,5], nums2 = [2,2,1], diff = 1
Output: 3
Explanation:
There are 3 pairs that satisfy the conditions:
1. i = 0, j = 1: 3 - 2 <= 2 - 2 + 1. Since i < j and 1 <= 1, this pair satisfies the conditions.
2. i = 0, j = 2: 3 - 5 <= 2 - 1 + 1. Since i < j and -2 <= 2, this pair satisfies the conditions.
3. i = 1, j = 2: 2 - 5 <= 2 - 1 + 1. Since i < j and -3 <= 2, this pair satisfies the conditions.
Therefore, we return 3.
```

### Merge Sort + Binary Search
假设nums1和nums2的长度为`n`, 题目中的不等式`nums1[i] - nums1[j] <= nums2[i] - nums[j] + diff`可转换为`nums1[i] - nums2[i] - (nums1[j] - nums2[j]) <= diff`, 假设数组`diff`表示长度为`n`的数组, `diff[i] = nums1[i] - nums2[i]`, 则上述不等式可改为`diff[i] - diff[j] <= diff`, 也就是说, 在一个数组中找到两个值的差值在特定区间内.
Merge sort合并时, 假设左子数组为`a`, 右子数组为`b`, 每当取出`a`中的元素时, 可在`b`中二分查找`a[i] - diff <= b[j]`
```java
class Solution {
    public long numberOfPairs(int[] nums1, int[] nums2, int diff) {
        int n = nums1.length;
        for (int i = 0; i < n; i++) {
            nums1[i] -= nums2[i];
        }
        System.arraycopy(nums1, 0, nums2, 0, n);
        return mergeSort(nums1, nums2, 0, n-1, diff);
    }

    private long mergeSort(int[] nums, int[] aux, int l, int r, int diff) {
        if (l >= r) return 0;
        int m = l + ((r - l) >> 1);
        return mergeSort(nums, aux, l, m, diff) 
            + mergeSort(nums, aux, m+1, r, diff)
            + merge(nums, aux, l, m, r, diff);
    }

    private long merge(int[] nums, int[] aux, int l, int m, int r, int diff) {
        long cnt = 0;
        for (int k = l, i = l, j = m + 1; k <= r; k++) {
            if (i > m) {
                aux[k] = nums[j++];
            } else if (j > r || nums[i] <= nums[j]) {
                int t = binarySearch(nums, m+1, r, nums[i] - diff);
                cnt += r - t + 1;
                aux[k] = nums[i++];
            } else {
                aux[k] = nums[j++];
            }
        }
        System.arraycopy(aux, l, nums, l, r - l + 1);
        return cnt;
    }

    private int binarySearch(int[] nums, int l, int r, int target) {
        while (l <= r) {
            int m = l + ((r - l) >> 1);
            if (nums[m] < target) {
                l = m + 1;
            } else {
                r = m - 1;
            }
        }
        return l;
    }
}
```


## 327. Count of Range Sum
Given an integer array `nums` and two integers `lower` and `upper`, return the number of range sums that lie in `[lower, upper]` inclusive.

Range sum `S(i, j)` is defined as the sum of the elements in `nums` between indices `i` and `j` inclusive, where `i <= j`.

Example 1:
```
Input: nums = [-2,5,-1], lower = -2, upper = 2
Output: 3
Explanation: The three ranges are: [0,0], [2,2], and [0,2] and their respective sums are: -2, -1, 2.
```

### Presum + Merge Sort + Binary Search
题目要求一段区间的元素之和满足特定上下限, 假设`nums`的前缀和数组为`presum`, 则`[i,j]`的元素之和等价为`presum[j] - presum[i-1]`, 因此问题转化为: 如何找到`presum`中两个元素的差值位于上下限内. 使用merge sort, 合并左子数组`a`和右子数组`b`时, 对于每一个`a[i]`, 找到符合条件的`b[j]`.
```java
class Solution {
    public int countRangeSum(int[] nums, int lower, int upper) {
        int n = nums.length;
        long[] arr = new long[n];
        for (int i = 0; i < n; i++) { // presum
            arr[i] = nums[i] + (i > 0 ? arr[i-1] : 0);
        }
        return mergeSort(arr, Arrays.copyOf(arr, n), 0, n-1, lower, upper);
    }

    private int mergeSort(long[] nums, long[] aux, int l, int r, int lo, int up) {
        if (l == r) {
            return nums[l] > up || nums[l] < lo ? 0 : 1;
        }
        int m = l + ((r - l) >> 1);
        return mergeSort(nums, aux, l, m, lo, up)
            + mergeSort(nums, aux, m+1, r, lo, up)
            + merge(nums, aux, l, m, r, lo, up);
    }

    private int merge(long[] nums, long[] aux, int l, int m, int r, int lo, int up) {
        int cnt = 0;
        for (int k = l, i = l, j = m + 1; k <= r; k++) {
            if (i > m) {
                aux[k] = nums[j++];
            } else if (j > r || nums[i] <= nums[j]) {
                int r1 = floor(nums, m+1, r, nums[i]+lo), r2 = ceil(nums, m+1, r, nums[i]+up);
                cnt += r2 - r1 + 1;
                aux[k] = nums[i++];
            } else {
                aux[k] = nums[j++];
            }
        }
        System.arraycopy(aux, l, nums, l, r - l + 1);
        return cnt;
    }

    private int ceil(long[] nums, int l, int r, long upper) {
        while (l <= r) {
            int m = l + ((r - l) >> 1);
            if (nums[m] > upper) {
                r = m - 1;
            } else {
                l = m + 1;
            }
        }
        return r;
    }

    private int floor(long[] nums, int l, int r, long lower) {
        while (l <= r) {
            int m = l + ((r - l) >> 1);
            if (nums[m] < lower) {
                l = m + 1;
            } else {
                r = m - 1;
            }
        }
        return l;
    }
}
```
