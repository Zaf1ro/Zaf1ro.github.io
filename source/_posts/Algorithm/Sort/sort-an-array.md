---
title: Sort an Array
category:
  - Algorithm
  - Sort
tag:
  - Algorithm
abbrlink: 1d0a
date: 2023-02-28 16:27:46
keywords:
description:
---

## 912. Sort an Array
Given an array of integers nums, sort the array in ascending order and return it.
You must solve the problem without using any built-in functions in $O(nlog(n))$ time complexity and with the smallest space complexity possible.
Example 1:
```
Input: nums = [5,2,3,1]
Output: [1,2,3,5]
Explanation: After sorting the array, the positions of some numbers are not changed (for example, 2 and 3), while the positions of other numbers are changed (for example, 1 and 5).
```

## 2. Bubble Sort
```java
class Solution {
  public int[] sortArray(int[] nums) {
    for (int i = nums.length-1; i > 0; i--) {
      for (int j = i-1; j >= 0; j--) {
        if (nums[j] > nums[i]) {
          swap(nums, i, j);
        }
      }
    }
    return nums;
  }

  private void swap(int[] nums, int i, int j) {
    int t = nums[i];
    nums[i] = nums[j];
    nums[j] = t;
  }
}
```

## 3. Insertion Sort
```java
class Solution {
  public int[] sortArray(int[] nums) {
    for (int i = 1; i < nums.length; i++) {
      for (int j = i-1; j >= 0; j--) {
        if (nums[j] > nums[j+1]) {
          swap(nums, j, j+1);
        } else {
          break;
        }
      }
    }
    return nums;
  }

  private void swap(int[] nums, int i, int j) {
    int t = nums[i];
    nums[i] = nums[j];
    nums[j] = t;
  }
}
```

## 4. Merge Sort
```java
class Solution {
  public int[] sortArray(int[] nums) {
    mergeSort(nums, 0, nums.length-1);
    return nums;
  }

  private void mergeSort(int[] nums, int l, int r) {
    if (l == r) return;
    int m = l + (r - l) / 2;
    mergeSort(nums, l, m);
    mergeSort(nums, m+1, r);
    merge(nums, l, m, r);
  }

  private void merge(int[] nums, int l, int m, int r) {
    int p1 = l, p2 = m+1, i = 0;
    int[] t = new int[r - l + 1];
    while (p1 <= m && p2 <= r) t[i++] = nums[p1] < nums[p2] ? nums[p1++] : nums[p2++];
    while (p1 <= m) t[i++] = nums[p1++];
    while (p2 <= r) t[i++] = nums[p2++];
    for (i = 0; i < t.length; i++) {
      nums[l+i] = t[i];
    }
  }
}
```

## 5. Quick Sort
```java
class Solution {
  private static final Random rand = new Random();

  public int[] sortArray(int[] nums) {
    quickSort(nums, 0, nums.length-1);
    return nums;
  }

  private void quickSort(int[] nums, int l, int r) {
    if (l >= r) return;
    int[] p = partition(nums, l, r);
    quickSort(nums, l, p[0]-1);
    quickSort(nums, p[1]+1, r);
  }

  private int[] partition(int[] nums, int l, int r) {
    int less = l, more = r-1, i = l;
    swap(nums, l+rand.nextInt(r-l+1), r);
    while (i <= more) {
      if (nums[i] < nums[r]) {
        swap(nums, i++, less++);
      } else if (nums[i] > nums[r]) {
        swap(nums, i, more--);
      } else {
        i++;
      }
    }
    swap(nums, more+1, r);
    return new int[]{less, more};
  }

  private void swap(int[] nums, int i, int j) {
    int t = nums[i];
    nums[i] = nums[j];
    nums[j] = t;
  }
}
```

## 6. Heap Sort
```java
class Solution {
  public int[] sortArray(int[] nums) {
    for (int i = 1; i < nums.length; i++) {
      insert(nums, i);
    }
    for (int i = nums.length-1; i > 0; i--) {
      swap(nums, 0, i);
      heapify(nums, 0, i);
    }
    return nums;
  }

  private void insert(int[] nums, int i) {
    int p = (i - 1) / 2;
    while (nums[p] < nums[i]) {
      swap(nums, p, i);
      i = p;
      p = (i - 1) / 2;
    }
  }

  private void heapify(int[] nums, int i, int size) {
    int l = 2 * i + 1; // left child
    while (l < size) {
      int largest = l+1 < size && nums[l+1] > nums[l] ? l+1 : l;
      if (nums[largest] <= nums[i]) break;
      swap(nums, i, largest);
      i = largest;
      l = 2 * i + 1;
    }
  }

  private void swap(int[] nums, int i, int j) {
    int t = nums[i];
    nums[i] = nums[j];
    nums[j] = t;
  }
}
```

## 7. Summary
排序算法的**stability**(稳定性)定义为: 相同key元素在排序后不会改变之前的相对顺序. 若数组中元素类型为**primitive type**, 如integer, 则稳定性没有太大意义; 若数组中元素类型为自定义class, 则需考虑是否采用具有稳定性的排序算法, 例如, 我们对学生按照年龄排序, 再按照班级排序, 若排序算法具有稳定性, 则排序后的学生先按照班级依次排列, 且每个班的学生按照年龄从小到大排序; 若排序算法不具有稳定性, 则同一班的学生可能不按照年龄排序.

| Sort Algorithm | Time Complexity | Space complexity | Stability |
|:---:|---|---|:---:|
| Bubble Sort    | $O(N^2)$ | $O(1)$ | $\checkmark$ |
| Insertion Sort | $O(N^2)$ | $O(1)$ | $\checkmark$ |
| Merge Sort | $O(N*\log(N))$ | $O(N)$ | $\checkmark$ |
| Quick Sort | $O(N*\log(N))$ | $O(\log(N))$ | $\times$ |
| Heap Sort | $O(N*\log(N))$ | $O(1)$ | $\times$ |
