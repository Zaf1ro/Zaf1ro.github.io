---
title: Segment Tree
abbrlink: b357
date: 2023-09-14 09:43:37
tags:
  - Algorithm
category:
  - Algorithm
  - Tree
keywords:
description:
---

## 1. Introduction
线段树(Segment Tree)是一种基于分治思想的二叉树, 用于维护**区间信息**. 线段树的每一个节点都对应一个区间$[left, right]$, `left`和`right`通常为整数:
* 非叶子节点表示任意一段区间
* 叶子节点表示一个**单位区间**(长度为1), 因此$left = right$
* 非叶子节点的**左子节点**表示$[left, (left + right) / 2]$区间, **右子节点**表示$[(left+right)/2+1, right]$区间
* 根节点表示整个区间

若整个区间内有$n$个元素, 则单点更新, 区间更新, 和区间查询的时间复杂度为$O(\log n)$, 空间复杂度为$O(2 \times 2^{\log_2 n})$, 约等于$4 \times n$


## 2. Implementation
二叉树有两种存储结构:
* 链式存储: 类与指针
* 顺序存储: 数组

由于线段树几乎是一种完全二叉树, 因此很适合采用**顺序存储**实现:
* 根节点的下标为1
* 若某个非叶子节点的下标为$i$, 则其左子节点坐标为$2 \times i$, 右子节点坐标为$2 \times i + 1$
* 若某个非根节点的下标为$i$, 则其父节点的下标为$i / 2$

### 2.1 Point Update
单点更新: 更新某个单位区间(单个元素)的值, 例如, 将第i个元素的值更新为val, 可采用递归方式从根节点出发:
1. 若当前节点为非叶子节点, 则判断目标元素在左子树还是右子树
2. 若为当前节点为叶子节点, 则更新该节点值
3. 从非叶子节点返回时, 更新该节点的区间值(区间和, 区间最值)

### 2.2 Range Query
区间查询: 查询一个区间的值, 例如, 查询$[left, right]$区间的值. 可采用递归方式从根节点出发:
1. 若目标区间完全覆盖当前节点所在区间($[l, r]$), 即$left \le l$且$right \ge r$, 则返回该节点的区间值
2. 若目标区间与当前节点所在区间($[l, r]$)无交集, 即$left > r$或$right < l$, 跳过该节点
3. 若目标区间与当前节点所在区间有交集, 即不符合上述所有情况:
    * 若目标区间与其左子节点所在区间($[l, m]$)有交集, 即$left \le m$, 则在左子节点查询
    * 若目标区间与其右子节点所在区间($[m+1, r]$)有交集, 即$right > m$, 则在右子节点查询
    * 返回左右子树聚合(sum, max, 或min)的结果

### 2.3 Range Update
区间更新: 更新一个区间的值, 例如, 将$[left, right]$区间内的所有元素更新为val.  
线段树中进行单点更新, 区间查询时的时间复杂度为$O(\log n)$, 而在区间更新中, 若某个节点所在区间被目标区间覆盖, 则该节点下的所有区间值都需要更新, 因此时间复杂度为$O(n)$.
为减少更新的次数和时间复杂度, 可在线段树的节点中添加一个**延迟标记**, 该标记表示**该节点所在区间已更新, 但其子节点并未更新**. 因此, 更新其子节点的操作被推迟到后续操作, 从而将区间更新的时间复杂度降到$O(\log n)$.
使用了延迟标记的区间更新的步骤如下:
1. 若目标区间完全覆盖当前节点所在区间($[l, r]$), 即$left \le l$且$right \ge r$, 则更新当前节点值, 并更新延迟标记
2. 若目标区间与当前节点所在区间($[l, r]$)无交集, 即$left > r$或$right < l$, 跳过该节点
3. 若目标区间与当前节点所在区间y有交集:
    * 若当前节点的延迟标记不为空, 则更新其子节点(更新左右子节点的延迟标记, 并清空当前节点的延迟标记)
    * 若目标区间与其左子节点所在区间($[l, m]$)有交集, 即$left \le m$, 则更新其左子节点
    * 若目标区间与其右子节点所在区间($[m+1, r]$)有交集, 即$right > m$, 则更新其右子节点
    * 更新子节点结束后, 更新当前节点的区间值(sum, max, min) 


### 3. Applicable Range
线段树通常用于以下问题:
* RMQ(Range Maximum/Minimum Query): 对于长度为$n$的数组`nums`, 求`nums`在区间$[l, r]$中的最值
* 更新某个元素值后查询区间值
* 更新一个区间的值后查询区间值
* 更新某个元素值后查询满足条件的最长区间值: 需在更新节点值后合并区间
* Scan line(扫描线): 用于解决图形的面积, 周长问题. 例如, 求多个重叠矩形的总面积, 可从下向上扫描整个图形, 用线段树维护矩形的y值, 矩形的下边为1, 上边为-1.


## 4. Leetcode
### 315. Count of Smaller Numbers After Self
#### Problem Description
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

#### Solution
```java
class Solution {
    class Node {
        public int s, e, cnt;
        public Node l, r;
        public Node(int start, int end) {
            this.s = start;
            this.e = end;
        }
    }

    private Node build(int start, int end) {
        Node node = new Node(start, end);
        if (start == end) return node;
        int mid = start + ((end - start) >> 1);
        node.l = build(start, mid);
        node.r = build(mid+1, end);
        return node;
    }

    private void insert(Node node, int num) {
        if (node.s == node.e) {
            ++node.cnt;
            return;
        }
        int mid = node.s + ((node.e - node.s) >> 1);
        if (num > mid) {
            insert(node.r, num);
        } else {
            insert(node.l, num);
        }
        node.cnt = node.l.cnt + node.r.cnt;
    }

    private int count(Node node, int start, int end) {
        if (start <= node.s && end >= node.e) {
            return node.cnt;
        }
        int l = 0, r = 0, mid = node.s + ((node.e - node.s) >> 1);
        if (start <= mid) {
            l = count(node.l, start, end);
        }
        if (end > mid) {
            r = count(node.r, start, end);
        }
        return l + r;
    }

    public List<Integer> countSmaller(int[] nums) {
        int min = Integer.MAX_VALUE, max = Integer.MIN_VALUE;
        for (int num: nums) {
            min = Math.min(min, num);
            max = Math.max(max, num);
        }
        Node root = build(--min, max);
        List<Integer> res = new ArrayList<>();
        for (int i = nums.length - 1; i >= 0; i--) {
            res.add(0, count(root, min, nums[i]-1));
            insert(root, nums[i]);
        }
        return res;
    }
}
```

### 327. Count of Range Sum
#### Problem Description
Given an integer array `nums` and two integers `lower` and `upper`, return the number of range sums that lie in `[lower, upper]` inclusive.
Range sum `S(i, j)` is defined as the sum of the elements in nums between indices `i` and `j` inclusive, where `i <= j`.

Example 1:
```
Input: nums = [-2,5,-1], lower = -2, upper = 2
Output: 3
Explanation: The three ranges are: [0,0], [2,2], and [0,2] and their respective sums are: -2, -1, 2.
```

#### Solution
```java
class Solution {
    class Node {
        public int l, r, cnt;
        public Node(int l, int r) {
            this.l = l;
            this.r = r;
        }
    }

    private Node[] tree;

    private void build(int i, int l, int r) {
        tree[i] = new Node(l, r);
        if (l == r) return;
        int mid = l + ((r - l) >> 1);
        build(i*2, l, mid);
        build(i*2+1, mid+1, r);
    }

    private void insert(int i, int num) {
        if (tree[i].l == tree[i].r) {
            ++tree[i].cnt;
            return;
        }
        int mid = (tree[i].l + tree[i].r) >> 1;
        if (num > mid) insert(i*2+1, num);
        if (num <= mid) insert(i*2, num);
        tree[i].cnt = tree[i*2].cnt + tree[i*2+1].cnt;
    }

    private int count(int i, int l, int r) {
        if (l <= tree[i].l && r >= tree[i].r) {
            return tree[i].cnt;
        }
        int mid = tree[i].l + ((tree[i].r - tree[i].l) >> 1), res = 0;
        if (l <= mid) res += count(i*2, l, r);
        if (r > mid) res += count(i*2+1, l, r);
        return res;
    }

    public int countRangeSum(int[] nums, int lower, int upper) {
        long[] presum = new long[nums.length+1];
        for (int i = 0; i < nums.length; i++) {
            presum[i+1] = presum[i] + nums[i];
        }
        Set<Long> set = new HashSet<>();
        for (long p: presum) {
            set.add(p);
            set.add(p - lower);
            set.add(p - upper);
        }
        List<Long> arr = new ArrayList<>(set);
        Collections.sort(arr);
        int n = arr.size();
        Map<Long, Integer> map = new HashMap<>();
        for (int i = 0; i < n; i++) {
            map.put(arr.get(i), i+1);
        }
        tree = new Node[n * 4];
        build(1, 1, n);
        int res = 0;
        for (long p: presum) {
            res += count(1, map.get(p-upper), map.get(p-lower));
            insert(1, map.get(p));
        }
        return res;
    }
}
```

### 218. The Skyline Problem
#### Problem Description
A city's **skyline** is the outer contour of the silhouette formed by all the buildings in that city when viewed from a distance. Given the locations and heights of all the buildings, return the **skyline** formed by these buildings collectively.
The geometric information of each building is given in the array `buildings` where `$\text{buildings}[i] = [\text{left}_i, \text{right}_i, \text{height}_i]$`:
* `$\text{left}_i$` is the x coordinate of the left edge of the `$i^{th}$` building.
* `$\text{right}_i$` is the x coordinate of the right edge of the `$i^{th}$` building.
* `$\text{height}_i$` is the height of the `i^{th}` building.

You may assume all buildings are perfect rectangles grounded on an absolutely flat surface at height `0`.
The **skyline** should be represented as a list of "key points" **sorted by their x-coordinate** in the form `$[[x_1,y_1],[x_2,y_2],...]$`. Each key point is the left endpoint of some horizontal segment in the skyline except the last point in the list, which always has a y-coordinate `0` and is used to mark the skyline's termination where the rightmost building ends. Any ground between the leftmost and rightmost buildings should be part of the skyline's contour.

Example 1:
![The Skyline Problem Example 1](/images/Algorithm/segment-tree/the-skyline-problem.jpg)

```
Input: buildings = [[2,9,10],[3,7,15],[5,12,12],[15,20,10],[19,24,8]]
Output: [[2,10],[3,15],[7,12],[12,0],[15,10],[20,8],[24,0]]
Explanation:
Figure A shows the buildings of the input.
Figure B shows the skyline formed by those buildings. The red points in figure B represent the key points in the output list.
```

#### Solution
```java
class Solution {
    public class Node {
        public int l, r, h;
        public Node(int l, int r) {
            this.l = l;
            this.r = r;
        }
    }

    private void build(int i, int l, int r) {
        tree[i] = new Node(l, r);
        if (l == r) return;
        int mid = l + ((r - l) >> 1);
        build(i*2, l, mid);
        build(i*2 + 1, mid+1, r);
    }

    private void pushdown(int i) {
        int h = tree[i].h;
        if (h > 0) {
            tree[2*i].h = Math.max(tree[2*i].h, h);
            tree[2*i+1].h = Math.max(tree[2*i+1].h, h);
            tree[i].h = 0;
        }
    }

    private void update(int i, int l, int r, int h) {
        if (l <= tree[i].l && r >= tree[i].r) {
            tree[i].h = Math.max(tree[i].h, h);
            return;
        }
        pushdown(i);
        int mid = (tree[i].l + tree[i].r) >> 1;
        if (l <= mid) update(i*2, l, r, h);
        if (r > mid) update(i*2+1, l, r, h);
    }

    private int query(int i, int x) {
        if (tree[i].l == tree[i].r) return tree[i].h;
        pushdown(i);
        int mid = tree[i].l + ((tree[i].r - tree[i].l) >> 1);
        return x <= mid ? query(i*2, x) : query(i*2+1, x);
    }

    private Node[] tree;

    public List<List<Integer>> getSkyline(int[][] buildings) {
        List<Integer> arr = new ArrayList<>();
        for (int[] b: buildings) {
            arr.add(b[0]);
            arr.add(b[1]);
        }
        arr = new ArrayList<>(new HashSet<>(arr));
        Collections.sort(arr);
        int n = arr.size();
        Map<Integer, Integer> map = new HashMap<>();
        for (int i = 0; i < n; i++) {
            map.put(arr.get(i), i+1);
        }
        tree = new Node[n * 4];
        build(1, 1, n);
        for (int[] b: buildings) {
            update(1, map.get(b[0]), map.get(b[1])-1, b[2]);
        }
        List<List<Integer>> res = new ArrayList<>();
        for (int i = 0, prev = 0; i < n; i++) {
            int h = query(1, map.get(arr.get(i)));
            if (h != prev) {
                prev = h;
                res.add(Arrays.asList(arr.get(i), h));
            }
        }
        return res;
    }
}
```

### 2569. Handling Sum Queries After Update
#### Problem Description
You are given two **0-indexed** arrays `nums1` and `nums2` and a 2D array `queries` of queries. There are three types of queries:
1. For a query of type 1, `queries[i] = [1, l, r]`. Flip the values from `0` to `1` and from `1` to `0` in `nums1` from index `l` to index `r`. Both `l` and `r` are **0-indexed**.
2. For a query of type 2, `queries[i] = [2, p, 0]`. For every index `$0 \le i \lt n$`, set `nums2[i] = nums2[i] + nums1[i] * p`.
3. For a query of type 3, `queries[i] = [3, 0, 0]`. Find the sum of the elements in `nums2`.

Return an array containing all the answers to the third type queries.

Example 1:
```
Input: nums1 = [1,0,1], nums2 = [0,0,0], queries = [[1,1,1],[2,1,0],[3,0,0]]
Output: [3]
Explanation: After the first query nums1 becomes [1,1,1]. After the second query, nums2 becomes [1,1,1], so the answer to the third query is 3. Thus, [3] is returned.
```

#### Solution
```java
class Node {
    public long sum;
    public int l, r;
    public boolean lazy;
    public Node(int l, int r) {
        this.l = l;
        this.r = r;
        this.lazy = false;
    }
}

class Solution {
    private Node[] tree;

    private void build(int[] nums, int i, int l, int r) {
        tree[i] = new Node(l, r);
        if (l == r) {
            tree[i].sum = nums[l];
            return;
        }
        int mid = l + ((r - l) >> 1);
        build(nums, 2*i, l, mid);
        build(nums, i*2+1, mid+1, r);
        tree[i].sum = tree[2*i].sum + tree[i*2+1].sum;
    }

    private void pushdown(int i) {
        if (tree[i].lazy) {
            int l = i * 2, r = l + 1;
            tree[l].lazy = !tree[l].lazy;
            tree[l].sum = tree[l].r - tree[l].l + 1 - tree[l].sum;
            tree[r].lazy = !tree[r].lazy;
            tree[r].sum = tree[r].r - tree[r].l + 1 - tree[r].sum;
            tree[i].lazy = false;
        }
    }

    private void update(int i, int l, int r, int s, int e) {
        if (s <= l && e >= r) {
            tree[i].sum = r - l + 1 - tree[i].sum;
            tree[i].lazy = !tree[i].lazy;
            return;
        }
        pushdown(i);
        int mid = l + ((r - l) >> 1);
        if (s <= mid) update(i*2, l, mid, s, e);
        if (e > mid) update(i*2+1, mid+1, r, s, e);
        tree[i].sum = tree[i*2].sum + tree[i*2+1].sum;
    }

    public long[] handleQuery(int[] nums1, int[] nums2, int[][] queries) {
        int n = nums1.length;
        tree = new Node[n * 4];
        build(nums1, 1, 0, n-1);
        long sum = 0;
        for (int num: nums2) {
            sum += num;
        }
        List<Long> res = new ArrayList<>();
        for (int[] q: queries) {
            if (q[0] == 1) {
                update(1, 0, n-1, q[1], q[2]);
            } else if (q[0] == 2) {
                sum += q[1] * tree[1].sum;
            } else {
                res.add(sum);
            }
        }
        return res.stream().mapToLong(i->i).toArray();
    }
}
```

### 732. My Calendar III
#### Problem Description
A `k`-booking happens when `k` events have some non-empty intersection (i.e., there is some time that is common to all k events.)
You are given some events `[startTime, endTime)`, after each given event, return an integer `k` representing the maximum `k`-booking between all the previous events.
Implement the `MyCalendarThree` class:
* `MyCalendarThree()` Initializes the object.
* `int book(int startTime, int endTime)` Returns an integer `k` representing the largest integer such that there exists a `k`-booking in the calendar.

Example 1:
```
Input:
["MyCalendarThree", "book", "book", "book", "book", "book", "book"]
[[], [10, 20], [50, 60], [10, 40], [5, 15], [5, 10], [25, 55]]

Output:
[null, 1, 1, 2, 3, 3, 3]

Explanation:
MyCalendarThree myCalendarThree = new MyCalendarThree();
myCalendarThree.book(10, 20); // return 1
myCalendarThree.book(50, 60); // return 1
myCalendarThree.book(10, 40); // return 2
myCalendarThree.book(5, 15); // return 3
myCalendarThree.book(5, 10); // return 3
myCalendarThree.book(25, 55); // return 3
```

#### Solution
```java
class Node {
    public int l, r, add, max;
}

class MyCalendarThree {
    private int count = 1, N = (int)1e9;
    private Node[] tree;

    public MyCalendarThree() {
        tree = new Node[20 * 400 * 4];
    }

    private void pushdown(int i) {
        tree[tree[i].l].add += tree[i].add;
        tree[tree[i].r].add += tree[i].add;
        tree[tree[i].l].max += tree[i].add;
        tree[tree[i].r].max += tree[i].add;
        tree[i].add = 0;
    }

    private void lazyCreate(int i) {
        if (tree[i] == null) tree[i] = new Node();
        if (tree[i].l == 0) {
            tree[i].l = ++count;
            tree[tree[i].l] = new Node();
        }
        if (tree[i].r == 0) {
            tree[i].r = ++count;
            tree[tree[i].r] = new Node();
        }
    }

    private void update(int i, int l, int r, int s, int e) {
        if (s <= l && e >= r) {
            ++tree[i].add;
            ++tree[i].max;
            return;
        }
        lazyCreate(i);
        pushdown(i);
        int mid = l + ((r - l)>> 1);
        if (s <= mid) update(tree[i].l, l, mid, s, e);
        if (e > mid) update(tree[i].r, mid+1, r, s, e);
        tree[i].max = Math.max(tree[tree[i].l].max, tree[tree[i].r].max);
    }
    
    public int book(int startTime, int endTime) {
        update(1, 0, N, startTime, endTime-1);
        return tree[1].max;
    }
}
```
