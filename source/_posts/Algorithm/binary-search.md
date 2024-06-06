---
title: Binary Search
abbrlink: f015
date: 2023-04-11 21:01:57
category:
  - Algorithm
  - Basic
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
Binary Search(二分搜索)也称为half-interval search(折半搜索), 或logarithmic search(对数搜索), 用于在一个数组中找到目标值的位置. 以一个升序数组为例, 每次考察数组的中间元素:
* 若中间元素为目标值, 则结束搜索
* 若中间元素小于目标值, 则该元素左侧的值一定也小于目标值, 因此只需在右侧查找
* 若中间元素大于目标值, 则同理, 只需在左侧查找

Binary search的思想在于**减而治之**, 每次查找都排除掉一定不存在目标元素的区间, 并继续在可能存在目标元素的区间查找.
Binary search的时间复杂度为$O(\log(N))$(N为数组元素数), 非递归实现的空间复杂度为$O(1)$. 需要注意的是, 使用binary search的前提是**数组是广义有序的**: 对于任意中间元素, 该数组的一侧满足某种条件, 而另一侧不满足条件. 因此, binary search常用于查找满足某种条件的最大(小)值.


## 2. Implementation
Binary search的思想很简单, 但实现时存在很多需要考虑的细节.

### 2.1 Open / Closed
Binary search初始化查找区间时可指定不同范围, 假设数组长度为`n`, 以下是几种常见查找区间:
* left closed, right closed: $[0, n-1]$
* left closed, right open / left open, right closed: $[0, n)$ 或 $(-1, n-1]$
* left open, right open: $(-1, n)$

### 2.2 Value of mid
Binary search取中间值有两种方式:
*  $\lfloor\frac{\text{left}+\text{right}}{2}\rfloor$
* $\lfloor\frac{\text{left}+\text{right}+1}{2}\rfloor$

若元素个数为**奇数**, 则上述两种方式的结果相同; 若元素个数为**偶数**, 则第一种会取得靠左元素的下标, 而第二种会取得靠右元素的下标.

### 2.3 Out of bound
Binary search需要一个终止条件, 也就是`while`语句中的出界判断条件, 以下是三种常见的判断条件:
* $left \le right$
* $left < right$
* $left + 1 < right$

### 2.4 Update of mid
Binary search的每次循环都需要更新`mid`, 以下是三种更新`mid`的写法:
* $left = mid + 1, right = mid - 1$
* $left = mid + 1, right = mid$ 或 $left = mid, right = mid - 1$
* $left = mid, right = mid - 1$

### 2.5 Conclusion
以上实现看似存在很多组合方式, 但其实只有三种写法:
* 左闭右闭:
    * 初始区间: $[0, n-1]$
    * 出界判定条件: $left \le right$
    * 更新`mid`方式: $left = mid + 1, right = mid - 1$
* 左闭右开 或 左开右闭:
    * 初始区间: $[0, n)$ 或 $(-1, n-1]$
    * 出界判定条件: $left < right$
    * 更新`mid`方式: $left = mid + 1, right = mid$ 或 $left = mid, right = mid - 1$
* 左开右开: 
    * 初始区间: $(-1, n)$
    * 出界判定条件: $left + 1 < right$
    * 更新`mid`方式: $left = mid, right = mid$

上述三种写法可互相转化, 且各有优劣:
* 左闭右闭: 返回值一定处于$[0, n-1]$区间内, 但循环结束时`left`和`right`的值不同, 需判断返回哪一个值
* 左闭右开(或左开右闭): 循环结束时`left`和`right`相同, 但返回值存在出界风险(左闭右开可能返回`n`, 左开右闭可能返回`-1`), 且由于`left`(或`right`)为坐标的元素并未检查, 需在循环结束后额外判断
* 左开右开: 写法最简单, 但返回值存在出界风险(`-1`或`n`)


## 3. Variants of Binary Search
Binary search不光用于判断目标值是否包含在数组中, 还有很多其他使用情景(假设数组已排序):
1. 若数组中存在重复值, 查找目标值的第一个出现位置
  ```java
  int first(int[] a, int l, int r, int target) {
      int res = -1;
      while (l <= r) {
          int m = l + ((r - l + 1) >> 1);
          // If arr[m] < target, means all elements in [l, m - 1] < target
          if (a[m] < target) {
              l = m + 1;
          } else if (a[m] > target) { // If arr[m] > target, means all elements in [m + 1, r] > target
              r = m - 1;
          } else { // If a[m] == target, keep searching in [l, m - 1]
              res = m;
              r = m - 1;
          }
      }
      return res;
  }
  ```
2. 若数组中存在重复值, 查找目标值的最后一个出现位置
  ```java
  int last(int[] a, int l, int r, int target) {
      int res = -1;
      while (l <= r) {
          int m = l + ((r - l) >> 1);
          // If a[m] < target, means all elements in [l, m - 1] < target
          if (a[m] < target) {
              l = m + 1;
          } else if (a[m] > target) { // If a[m] > target, means all elements in [m + 1, r] > target
              r = m - 1;
          } else { // If a[m] == target, keep searching in [m + 1, r]
              res = m;
              l = m + 1;
          }
      }
      return res;
  }
  ```
3. 大于或等于目标值的最小元素的位置, 若存在多个元素等同目标值, 则取最左侧位置
  ```java
  int ceiling(int[] a, int l, int r, int target) {
      int res = -1;
      while (l <= r) {
          int m = l + ((r - l) >> 1);
          // If a[m] < target, means all elements in [l, m - 1] < target
          if (a[m] < target) {
              l = m + 1;
          } else { // If a[m] >= target, keep searching in [l, m - 1]
              res = m;
              r = m - 1;
          }
      }
      return res;
  }
  ```
4. 小于或等于目标值的最大元素的位置, 若存在多个元素等同目标值, 则取最右侧位置
  ```java
  int floor(int[] a, int l, int r, int target) {
      int res = -1;
      while (l <= r) {
          int m = l + ((r - l) >> 1);
          // If a[m] > target, means all elements in [m + 1, r] > target
          if (a[m] > target) {
              r = m - 1;
          } else { // If a[m] <= target, keep searching in [m + 1, r]
              res = m;
              l = m + 1;
          }
      }
      return res;
  }
  ```

总结一下, 存在四种查找元素的情况:
* 查找$\ge x$的元素
* 查找$> x$的元素: 可转换为$\ge x+1$的元素 
* 查找$< x$的元素: 可转换为$\ge x$的元素坐标减1
* 查找$\le x$的元素: 可转换为$> x$的元素坐标减1, 也就是$\ge x + 1$的元素坐标减1

因此, 上述四种情况都可转换为$\ge x$情况, 也可转换为其他情况.

## 4. Leetcode
### 34. Find First and Last Position of Element in Sorted Array
#### Problem Description
Given an array of integers `nums` sorted in non-decreasing order, find the starting and ending position of a given `target` value.

If `target` is not found in the array, return `[-1, -1]`.

You must write an algorithm with `$O(\log(n))$` runtime complexity.

Example 1:
```
Input: nums = [5,7,7,8,8,10], target = 8
Output: [3,4]
```

Example 2:
```
Input: nums = [5,7,7,8,8,10], target = 6
Output: [-1,-1]
```

#### Solution
由于数组已经排序, 因此可使用binary search查找第一个目标值元素和最后一个目标值元素的位置.
```java
class Solution {
    public int[] searchRange(int[] nums, int target) {
        return new int[] {
            lower_bound(nums, 0, nums.length-1, target),
            upper_bound(nums, 0, nums.length-1, target)
        };
    }

    private int lower_bound(int[] a, int l, int r, int target) {
        int res = -1;
        while (l <= r) {
            int m = l + ((r - l + 1) >> 1);
            if (a[m] < target) {
                l = m + 1;
            } else if (a[m] > target) {
                r = m - 1;
            } else {
                res = m;
                r = m - 1;
            }
        }
        return res;
    }

    private int upper_bound(int[] a, int l, int r, int target) {
        int res = -1;
        while (l <= r) {
            int m = l + ((r - l) >> 1);
            if (a[m] < target) {
                l = m + 1;
            } else if (a[m] > target) {
                r = m - 1;
            } else {
                res = m;
                l = m + 1;
            }
        }
        return res;
    }
}
```

### 153. Find Minimum in Rotated Sorted Array
#### Problem Description
Suppose an array of length `n` sorted in ascending order is **rotated** between `1` and `n` times. For example, the array `nums = [0,1,2,4,5,6,7]` might become:
* `[4,5,6,7,0,1,2]` if it was rotated `4` times.
* `[0,1,2,4,5,6,7]` if it was rotated `7` times.
Notice that **rotating** an array `[a[0], a[1], a[2], ..., a[n-1]]` 1 time results in the array `[a[n-1], a[0], a[1], a[2], ..., a[n-2]]`.

Given the sorted rotated array `nums` of **unique** elements, return the minimum element of this array.

You must write an algorithm that runs in `$O(\log(n))$` time.

Example 1:
```
Input: nums = [3,4,5,1,2]
Output: 1
Explanation: The original array was [1,2,3,4,5] rotated 3 times.
```

#### Solution
该数组分为两种情况:
* 未旋转: 最小元素为最左侧元素
* 旋转过: 最小元素在中间

因此我们只需考虑数组旋转过的情况: 若`nums[left] > nums[right]`, 则说明当前区间旋转过, 此时取中值存在两种情况:
* mid落在`[left, max]`: 中值落在左侧区间(`[left, max]`), 需向右移动(`nums[mid] >= nums[l]`)
* mid落在`[min, right]`: 中值落在右侧区间(`[min, right]`), 需向左移动(`nums[mid] < nums[l]`或`nums[mid] <= nums[right]`)

需要注意的是, 若`left + 1 == right`, 则`(l + r) / 2`返回left, 而不是right, 因此中值落在右侧区间时无需让`right = mid - 1`.
```java
class Solution {
    public int findMin(int[] nums) {
        int l = 0, r = nums.length - 1;
        while (l < r) {
            int m = l + ((r - l) >> 1);
            if (nums[m] >= nums[l] && nums[l] > nums[r]) {
                l = m + 1;
            } else {
                r = m;
            }
        }
        return nums[l];
    }
}
```


### 154. Find Minimum in Rotated Sorted Array II
#### Problem Description
Suppose an array of length `n` sorted in ascending order is **rotated** between `1` and `n` times. For example, the array `nums = [0,1,4,4,5,6,7]` might become:
* `[4,5,6,7,0,1,4]` if it was rotated `4` times.
* `[0,1,4,4,5,6,7]` if it was rotated `7` times.
Notice that rotating an array `[a[0], a[1], a[2], ..., a[n-1]]` 1 time results in the array `[a[n-1], a[0], a[1], a[2], ..., a[n-2]]`.

Given the sorted rotated array `nums` that may contain **duplicates**, return the minimum element of this array.

You must decrease the overall operation steps as much as possible.

Example 1:
```
Input: nums = [2,2,2,0,1]
Output: 0
```

#### Solution
该题与上一题相同, 唯一区别在于数组中存在重复元素, 可能破坏数组的**有序性**, 例如: 若`nums`为`[2,2,2,1,2]`, 则`nums[left]`, `nums[mid]`和`nums[right]`均为2, 此时无法判断最小值在mid的左侧或右侧, 只能缩小区间并再次查找.
```java
class Solution {
    public int findMin(int[] nums) {
        int l = 0, r = nums.length - 1;
        while (l < r) {
            int m = l + ((r - l) >> 1);
            if (nums[l] == nums[m] && nums[m] == nums[r]) {
                l++;
                r--;
            } else if (nums[l] >= nums[r] && nums[m] >= nums[l]) {
                l = m + 1;
            } else {
                r = m;
            }
        }
        return nums[l];
    }
}
```

### 852. Peak Index in a Mountain Array
#### Problem Description
An array `arr` a **mountain** if the following properties hold:
* `arr.length >= 3`
* There exists some `i` with `0 < i < arr.length - 1` such that:
  * `arr[0] < arr[1] < ... < arr[i - 1] < arr[i]`
  * `arr[i] > arr[i + 1] > ... > arr[arr.length - 1]`

Given a mountain array `arr`, return the index `i` such that `arr[0] < arr[1] < ... < arr[i - 1] < arr[i] > arr[i + 1] > ... > arr[arr.length - 1]`.

You must solve it in `$O(\log(n))$` time complexity.

Example 1:
```
Input: arr = [0,2,1,0]
Output: 1
```

#### Solution
题目中数组元素虽不按照升序或降序排列, 但仍具有有序性: 由于数组一定存在一个peak, 因此对于中值, 存在三种情况:
* `arr[mid] > arr[mid-1]`且`arr[mid] > arr[mid+1]`: 说明中值即为peak
* `arr[mid] < arr[mid-1]`: peak在左侧
* `arr[mid] < arr[mid+1]`: peak在右侧

```java
class Solution {
    public int peakIndexInMountainArray(int[] arr) {
        int l = 0, r = arr.length - 1;
        while (l <= r) {
            int m = l + ((r - l) >> 1);
            if (arr[m] > arr[m+1] && arr[m] > arr[m-1]) {
                return m;
            } else if (arr[m] < arr[m+1]) {
                l = m + 1;
            } else {
                r = m - 1;
            }
        }
        return -1;
    }
}
```


### 378. Kth Smallest Element in a Sorted Matrix
#### Problem Description
Given an `n x n` `matrix` where each of the rows and columns is sorted in ascending order, return the `$k^{th}$` smallest element in the matrix.

Note that it is the `$k^{th}$` smallest element in the sorted order, not the `$k^{th}$` distinct element.

You must find a solution with a memory complexity better than `$O(n^2)$`.

Example 1:
```
Input: matrix = [[1,5,9],[10,11,13],[12,13,15]], k = 8
Output: 13
Explanation: The elements in the matrix are [1,5,9,10,11,12,13,13,15], and the 8th smallest number is 13
```

#### Solution
由于matrix中的元素并不具有严格的有序性, 因此很难直接查找第k小的元素, 可换一种思路: matrix中最小值为`matrix[0][0]`, 最大值为`matrix[n-1][n-1]`, 第k小的元素一定存在于`[matrix[0][0], matrix[n-1][n-1]]`之间, 因此可采用binary search不断缩小区间: 假设第k小的数值为中值(mid), 并统计小于或等于mid的元素在matrix中有多少个:
* 若元素个数为k: x可能为答案, 也可能比答案大
* 若元素个数小于k: x比答案小
* 若元素个数大于k: x比答案大

对于行列均递增的矩阵, 可从`[n-1, 0]`出发, 该元素拥有以下特性:
* 该元素右侧的所有元素都大于该元素
* 该元素上面的所有元素都小于该元素

因此, 若该元素小于target, 则该元素以及其上的元素都小于target; 若该元素大于target, 则该元素右侧的所有元素都大于该元素.
```java
class Solution {
    public int kthSmallest(int[][] matrix, int k) {
        int n = matrix.length, l = matrix[0][0], r = matrix[n-1][n-1];
        while (l <= r) {
            int m = l + ((r - l) >> 1);
            if (floor(matrix, m) < k) {
                l = m + 1;
            } else {
                r = m - 1;
            }
        }
        return l;
    }

    private int floor(int[][] matrix, int target) {
        int i = matrix.length - 1, j = 0, res = 0;
        while (i >= 0 && j < matrix.length) {
            if (matrix[i][j] <= target) {
                res += i + 1;
                j++;
            } else {
                i--;
            }
        }
        return res;
    }
}
```


### 658. Find K Closest Elements
#### Problem Description
Given a **sorted** integer array `arr`, two integers `k` and `x`, return the `k` closest integers to `x` in the array. The result should also be sorted in ascending order.
An integer `a` is closer to `x` than an integer `b` if:
* `|a - x| < |b - x|`, or
* `|a - x| == |b - x|` and `a < b`

Example 1:
```
Input: arr = [1,2,3,4,5], k = 4, x = 3
Output: [1,2,3,4]
```

Example 2:
```
Input: arr = [1,2,3,4,5], k = 4, x = -1
Output: [1,2,3,4]
```

#### Solution
该题目可使用双指针解决: 每次判断前后指针与x的差值, 并缩小差值更大的一端, 直到两个指针之间的距离为k, 但这么做不能利用数组的有序性. 该题可看作求一个长度为k的区间, 并使区间内元素与x的距离的最大值最小, 可以发现, 距离x的最大值只与区间的两端有关. 假设区间的左边界坐标为`i`, 则右边界坐标为`i+k-1`, 因此可对比`arr[i]`和`arr[i+k-1]`与x的距离:
* `arr[i]`与x的距离更远: 向右移动
* `arr[i+k-1]`与x的距离更远: 向左移动

若使用`Math.abs(arr[i] - x)`和`Math.abs(arr[i+k-1] - x)`计算距离会出现一个问题: 若`arr[i] == arr[i+k-1]`, 则无法判断应向哪里移动, 因此改为`x - arr[i]`和`arr[i+k-1] - x`:
* `x < arr[i]`: `x - arr[i] < arr[i+k-1] - x`, 向左移动
* `arr[i] < x < arr[i+k-1]`: `x - arr[i] > 0` `arr[i+k-1] - x > 0`, 根据距离判断向哪里移动
* `x > arr[i]`: `x - arr[i] > arr[i+k-1] - x`, 向右移动

由于题目要求距离相同时, 坐标靠右的区间优先, 因此需判断`[i, i+k-1]`与`[i-1, i+k-2]`.
```java
class Solution {
    public List<Integer> findClosestElements(int[] arr, int k, int x) {
        int l = 0, r = arr.length - k;
        while (l < r) {
            int m = l + ((r - l) >> 1);
            if (x - arr[m] > arr[m+k-1] - x) {
                l = m + 1;
            } else {
                r = m;
            }
        }
        if (l > 0 && Math.abs(arr[l-1] - x) <= Math.abs(arr[l+k-1] - x)) {
            --l;
        }
        List<Integer> res = new ArrayList<>();
        while (k-- > 0) {
            res.add(arr[l++]);
        }
        return res;
    }
}
```


### 1060. Missing Element in Sorted Array
#### Problem Description
Given an integer array `nums` which is sorted in **ascending order** and all of its elements are **unique** and given also an integer `k`, return the `$k^{th}$` missing number starting from the leftmost number of the array.

Example 1:
```
Input: nums = [4,7,9,10], k = 1
Output: 5
Explanation: The first missing number is 5.
```

Example 2:
```
Input: nums = [4,7,9,10], k = 3
Output: 8
Explanation: The missing numbers are [5,6,8,...], hence the third missing number is 8.
```

#### Solution
对于数组中的每个元素, 可计算该元素之前缺失的元素个数: `nums[i] - nums[0] - i`, 若将缺失的元素个数组成一个数组, 可发现数组内的元素呈升序排列, 因此可借助binary search查找.
```java
class Solution {
    public int missingElement(int[] nums, int k) {
        int l = 0, r = nums.length - 1;
        while (l < r) {
            int m = l + ((r - l + 1) >> 1);
            if (nums[m] - nums[0] - m >= k) {
                r = m - 1;
            } else {
                l = m;
            }
        }
        return nums[0] + k + r;
    }
}
```


### 300. Longest Increasing Subsequence
#### Problem Description
Given an integer array `nums`, return the length of the longest **strictly increasing subsequence**.

Example 1:
```
Input: nums = [10,9,2,5,3,7,101,18]
Output: 4
Explanation: The longest increasing subsequence is [2,3,7,101], therefore the length is 4.
```

#### Solution
题目要求最长升序子序列, 因此可维护一个数组`arr`, 并从左向右遍历数组, 对于每个元素:
* 若该元素大于之前的所有元素, 则放入`arr`尾部
* 若该元素小于之前的某个元素, 则替换其位置

其中, 查找元素的插入位置可使用binary search.
```java
class Solution {
    public int lengthOfLIS(int[] nums) {
        int n = nums.length, size = 0;
        int[] arr = new int[n];
        for (int num: nums) {
            int l = 0, r = size - 1;
            while (l <= r) {
                int m = l + ((r - l) >> 1);
                if (arr[m] < num) {
                    l = m + 1;
                } else {
                    r = m - 1;
                }
            }
            if (l == size) ++size;
            arr[l] = num;
        }
        return size;
    }
}
```


### 436. Find Right Interval
#### Problem Description
You are given an array of `intervals`, where `intervals[i] = [$\text{start}_i$, $\text{end}_i$]` and each $\text{start}_i$ is unique.

The right interval for an interval `i` is an interval `j` such that `$\text{start}_j \ge \text{end}_i$`and `$\text{start}_j$` is **minimized**. Note that `i` may equal `j`.

Return an array of **right interval** indices for each interval `i`. If no **right interval** exists for interval `i`, then put `-1` at index `i`.

Example 1:
```
Input: intervals = [[3,4],[2,3],[1,2]]
Output: [-1,0,1]
Explanation: There is no right interval for [3,4].
The right interval for [2,3] is [3,4] since $\text{start}_0 = 3$ is the smallest start that is >= $\text{end}_1 = 3$.
The right interval for [1,2] is [2,3] since $\text{start}_1 = 2$ is the smallest start that is >= $\text{end}_2 = 2$.
```

#### Solution
题目要求right interval的start大于或等于当前interval的end, 且保证start值最小, 属于最经典的最大值最小化问题, 每次遍历每个interval的start即可获得答案, 而binary search适用于寻找最大(小)值, 因此可加速这一过程. 需要注意的是, 由于结果需与原数组中的interval一一对应, 因此原数组按照start排序时会破坏对应关系, 需用一个辅助数组记录对应interval的坐标.
```java
class Solution {
    public int[] findRightInterval(int[][] intervals) {
        int n = intervals.length;
        Integer[] index = new Integer[n];
        for (int i = 0; i < n; i++) {
            index[i] = i;
        }
        int[] res = new int[n];
        Arrays.sort(index, (a,b) -> intervals[a][0] - intervals[b][0]);
        for (int i = 0; i < n; i++) {
            int l = 0, r = n-1, target = intervals[i][1];
            while (l <= r) {
                int m = l + ((r - l) >> 1);
                if (intervals[index[m]][0] < target) {
                    l = m + 1;
                } else {
                    r = m - 1;
                }
            }
            res[i] = l < n ? index[l] : -1;
        }
        return res;
    }
}
```


### 1552. Magnetic Force Between Two Balls
#### Problem Description
In the universe Earth C-137, Rick discovered a special form of magnetic force between two balls if they are put in his new invented basket. Rick has n empty baskets, the `$i^{th}$` basket is at `position[i]`, Morty has `m` balls and needs to distribute the balls into the baskets such that the **minimum magnetic force** between any two balls is **maximum**.
Rick stated that magnetic force between two different balls at positions `x` and `y` is `|x - y|`.
Given the integer array `position` and the integer `m`. Return the required force.

Example 1:
```
Input: position = [1,2,3,4,7], m = 3
Output: 3
Explanation: Distributing the 3 balls into baskets 1, 4 and 7 will make the magnetic force between ball pairs [3, 3, 6]. The minimum magnetic force is 3. We cannot achieve a larger minimum magnetic force than 3.
```

#### Solution
若ball与ball之间距离十分大, 即便使用binary search加速查询, 也会非常耗时, 因此可换一种思路: 最大距离存在于一个固定范围, 假设`position`的长度为`n`, 需要放置`m`个ball, 那么答案的范围为`[1, position[n-1] - position[0]]`. 假设我们从该范围挑选一个数值, 依照该距离放置ball时可放置`k`个ball, 存在三种情况:
* `k > m`: 挑选的距离过小, 可以放置更多ball
* `k < m`: 挑选的距离过大, 没有足够空间放置ball
* `k == m`: 最后的ball之后可能还有空间, 但不足以放置下一个ball

因此可不断逼近, 直到距离可防止m个ball, 且没有剩余空间.
```java
class Solution {
    public int maxDistance(int[] position, int m) {
        Arrays.sort(position);
        int l = 1, r = position[position.length-1] - position[0];
        while (l <= r) {
            int mid = l + ((r - l) >> 1);
            if (count(position, mid) < m) {
                r = mid - 1;
            } else {
                l = mid + 1;
            }
        }
        return r;
    }

    private int count(int[] arr, int dist) {
        int cnt = 1;
        for (int i = 1, j = 0; i < arr.length; i++) {
            if (arr[i] - arr[j] >= dist) {
                ++cnt;
                j = i;
            }
        }
        return cnt;
    }
}
```


### 410. Split Array Largest Sum
#### Problem Description
Given an integer array `nums` and an integer `k`, split `nums` into `k` non-empty subarrays such that the largest sum of any subarray is **minimized**.
Return the minimized largest sum of the split.
A **subarray** is a contiguous part of the array.

Example 1:
```
Input: nums = [7,2,5,10,8], k = 2
Output: 18
Explanation: There are four ways to split nums into two subarrays.
The best way is to split it into [7,2,5] and [10,8], where the largest sum among the two subarrays is only 18.
```

#### Solution
与上一题思路相同, 选定一个值, 并查找子序列之和小于或等于该值的子序列数量, 使用binary search不断逼近答案.
```java
class Solution {
    public int splitArray(int[] nums, int k) {
        int l = 0, r = nums[0];
        for (int num: nums) {
            l = Math.max(l, num);
            r += num;
        }
        while (l <= r) {
            int m = l + ((r - l) >> 1);
            if (count(nums, m) <= k) {
                r = m - 1;
            } else {
                l = m + 1;
            }
        }
        return l;
    }

    private int count(int[] nums, int sum) {
        int cnt = 1, t = 0;
        for (int num: nums) {
            t += num;
            if (t > sum) {
                t = num;
                ++cnt;
            }
        }
        return cnt;
    }
}
```


### 1231. Divide Chocolate
#### Problem Description
You have one chocolate bar that consists of some chunks. Each chunk has its own sweetness given by the array `sweetness`.
You want to share the chocolate with your `k` friends so you start cutting the chocolate bar into `k + 1` pieces using `k` cuts, each piece consists of some **consecutive** chunks.
Being generous, you will eat the piece with the **minimum total sweetness** and give the other pieces to your friends.
Find the **maximum total sweetness** of the piece you can get by cutting the chocolate bar optimally.

Example 1:
```
Input: sweetness = [1,2,3,4,5,6,7,8,9], k = 5
Output: 6
Explanation: You can divide the chocolate to [1,2,3], [4,5], [6], [7], [8], [9]
```

#### Solution
假设总甜度为`sum(sweetness)`, 总人数为`k + 1`, 自己能得到的甜度位于`[0, sum(sweetness) / (k+1)]`范围内, 因此可binary search不断寻找将巧克力分为`k + 1`份的甜度最大值.
```java
class Solution {
    public int maximizeSweetness(int[] sweetness, int k) {
        int sum = 0;
        for (int s: sweetness) {
            sum += s;
        }
        int l = 0, r = sum / (k + 1);
        while (l <= r) {
            int m = l + ((r - l) >> 1);
            if (count(sweetness, m) < k + 1) {
                r = m - 1;
            } else {
                l = m + 1;
            }
        }
        return r;
    }

    private int count(int[] arr, int min) {
        int cnt = 0, sum = 0;
        for (int s: arr) {
            sum += s;
            if (sum >= min) {
                ++cnt;
                sum = 0;
            }
        }
        return cnt;
    }
}
```


### 354. Russian Doll Envelopes
#### Problem Description
You are given a 2D array of integers `envelopes` where `envelopes[i] = [$w_i$, $h_i$]` represents the width and the height of an envelope.
One envelope can fit into another if and only if both the width and height of one envelope are greater than the other envelope's width and height.
Return the maximum number of envelopes you can Russian doll (i.e., put one inside the other).
Note: You cannot rotate an envelope.

Example 1:
```
Input: envelopes = [[5,4],[6,4],[6,7],[2,3]]
Output: 3
Explanation: The maximum number of envelopes you can Russian doll is 3 ([2,3] => [5,4] => [6,7]).
```

#### Solution
题目要求外部envelope的长度和宽度都大于内部嵌套的envelope, 因此满足有序性, 可使用binary search查找. 但问题在于: 如何让长度和宽度同时满足有序. 若按照宽度排序, 则宽度较小的envelope可能长度大于其他envelope, 因此需分别讨论两个维度:
1. 先按照宽度排序
2. 再按照长度排序

宽度排序比较简单, 直接排序`envelopes`即可; 长度排序则比较复杂, 因为需在满足原有宽度顺序的情况下进行排序: 维护一个辅助数组, 遍历`envelopes`, 并按照长度将envelope放入数组:
* 若当前envelope的长度大于先前所有envelope, 则放在数组最后
* 若当前envelope的长度小于或等于某个envelope, 则放在该envelope的位置

若`envelopes`中的宽度不存在重复, 则辅助数组中的每个envelope都比前一个envelope大; 但`envelopes`中可能存在多个同等宽度的envelope, 从而导致辅助数组中的envelope无法满足条件, 因此需将相同宽度的envelope按照长度逆序排列, 让长度较大的envelope先放入数组, 并让长度较小的envelope替代该位置.
```java
class Solution {
    public int maxEnvelopes(int[][] envelopes) {
        Arrays.sort(envelopes, (a,b) -> a[0] == b[0] ? b[1] - a[1] : a[0] - b[0]);
        int[] dp = new int[envelopes.length];
        int size = 0;
        for (int[] e: envelopes) {
            int l = 0, r = size;
            while (l < r) {
                int m = l + ((r - l) >> 1);
                if (e[1] > dp[m]) {
                    l = m + 1;
                } else {
                    r = m;
                }
            }
            dp[r] = e[1];
            if (l == size) ++size;
        }
        return size;
    }
}
```


### 1847. Closest Room
#### Problem Description
There is a hotel with `n` rooms. The rooms are represented by a 2D integer array `rooms` where `rooms[i] = [$\text{roomId}_i$, $\text{size}_i$]` denotes that there is a room with room number `$\text{roomId}_i$` and size equal to `$\text{size}_i$`. Each `$\text{roomId}_i$` is guaranteed to be **unique**.
You are also given `k` queries in a 2D array `queries` where `queries[j] = [$\text{preferred}_j$, $\text{minSize}_j$]`. The answer to the `$j^{th}$` query is the room number `id` of a room such that:
* The room has a size of **at least** `$\text{minSize}_j$`
* `abs(id - $\text{preferred}_j$)` is **minimized**, where `abs(x)` is the absolute value of `x`.

If there is a **tie** in the absolute difference, then use the room with the **smallest** such `id`. If there is **no such room**, the answer is `-1`.
Return an array `answer` of length `k` where `answer[j]` contains the answer to the `$j^{th}$` query.

Example 1:
```
Input: rooms = [[2,2],[1,2],[3,2]], queries = [[3,1],[3,3],[5,2]]
Output: [3,-1,3]
Explanation: The answers to the queries are as follows:
Query = [3,1]: Room number 3 is the closest as abs(3 - 3) = 0, and its size of 2 is at least 1. The answer is 3.
Query = [3,3]: There are no rooms with a size of at least 3, so the answer is -1.
Query = [5,2]: Room number 3 is the closest as abs(3 - 5) = 2, and its size of 2 is at least 2. The answer is 3.
```

#### Solution + Balanced Binary Tree
题目要求room满足两个条件:
* `size >= minSize`
* `Math.abs(preferred - roomId)`最小

若将`rooms`按照size排序, 则可通过binary search找到大于或等于`minSize`的所有room范围; 但对于room id, 需在room范围内找到大于或等于`preferred`的最小值, 和小于或等于`preferred`的最大值, 因此也需让room按照id有序排列.
因此将`rooms`和`queries`按照room size逆序排列, 对于每一个`query`, 将room size大于或等于`minSize`的room放入一个red-black tree(红黑树), 这样后续query的`minSize`一定小于或等于红黑树内的room size. 对于room id, 可在红黑树内查询并得到最接近的id.
```java
class Solution {
    public int[] closestRoom(int[][] rooms, int[][] queries) {
        int m = rooms.length, n = queries.length, i = 0;
        TreeSet<Integer> set = new TreeSet<>();
        Arrays.sort(rooms, (a,b) -> b[1] - a[1]);
        Integer[] arr = new Integer[n];
        for (int j= 0; j < n; j++) {
            arr[j] = j;
        }
        Arrays.sort(arr, (a,b) -> queries[b][1] - queries[a][1]);
        int[] res = new int[n];
        for (int j: arr) {
            int id = queries[j][0], min = queries[j][1];
            while (i < m && rooms[i][1] >= min) {
                set.add(rooms[i++][0]);
            }
            Integer id1 = set.ceiling(id), id2 = set.floor(id);
            if (id1 == null && id2 == null) {
                res[j] = -1;
            } else if (id1 == null) {
                res[j] = id2;
            } else if (id2 == null) {
                res[j] = id1;
            } else {
                res[j] = Math.abs(id - id1) < Math.abs(id - id2) ? id1 : id2;
            }
        }
        return res;
    }
}
```


### 4. Median of Two Sorted Arrays
#### Problem Description
Given two sorted arrays `nums1` and `nums2` of size `m` and `n` respectively, return **the median** of the two sorted arrays.
The overall run time complexity should be `O(log (m+n))`.

Example 1:
```
Input: nums1 = [1,3], nums2 = [2]
Output: 2.00000
Explanation: merged array = [1,2,3] and median is 2.
```

Example 2:
```
Input: nums1 = [1,2], nums2 = [3,4]
Output: 2.50000
Explanation: merged array = [1,2,3,4] and median is (2 + 3) / 2 = 2.5.
```

#### Solution
```java
class Solution {
    public double findMedianSortedArrays(int[] nums1, int[] nums2) {
        int n = nums1.length + nums2.length;
        return (helper(nums1, nums2, 0, 0, (n-1)/2) + helper(nums1, nums2, 0, 0, n/2)) / 2.0;
    }

    private int helper(int[] nums1, int[] nums2, int i, int j, int t) {
        if (i == nums1.length) return nums2[j+t];
        if (j == nums2.length) return nums1[i+t];
        if (t == 0) return Math.min(nums1[i], nums2[j]);
        int n1 = i + t/2 < nums1.length ? nums1[i+t/2] : Integer.MAX_VALUE;
        int n2 = j + t/2 < nums2.length ? nums2[j+t/2] : Integer.MAX_VALUE;
        if (n1 < n2) {
            return helper(nums1, nums2, i+(t+1)/2, j, t-(t+1)/2);
        }
        return helper(nums1, nums2, i, j+(t+1)/2, t-(t+1)/2);
    }
}
```
