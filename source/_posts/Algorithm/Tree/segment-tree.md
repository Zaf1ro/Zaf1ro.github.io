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

### Segment Tree
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


## 327. Count of Range Sum
Given an integer array `nums` and two integers `lower` and `upper`, return the number of range sums that lie in `[lower, upper]` inclusive.
Range sum `S(i, j)` is defined as the sum of the elements in nums between indices `i` and `j` inclusive, where `i <= j`.

Example 1:
```
Input: nums = [-2,5,-1], lower = -2, upper = 2
Output: 3
Explanation: The three ranges are: [0,0], [2,2], and [0,2] and their respective sums are: -2, -1, 2.
```

### Segment Tree
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


## 218. The Skyline Problem
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

### Segment Tree
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

## 2569. Handling Sum Queries After Update
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

### Segment Tree
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


## 732. My Calendar III
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

### Segment Tree
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
