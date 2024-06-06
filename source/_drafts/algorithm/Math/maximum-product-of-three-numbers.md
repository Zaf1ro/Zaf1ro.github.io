---
title: Maximum Product of Three Numbers
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: 2467508319
date: 2018-02-23 05:15:26
---

## 1. Description
Given an integer array, find three numbers whose product is maximum and output the maximum product.
Example 1:
```text
Input: [1,2,3]
Output: 6
```
Example 2:
```text
Input: [1,2,3,4]
Output: 24
```



## 2. Sorting
思路: 最大数值的出现有两种情况: 
1. 最小负值 \* 第二小负值 \* 最大正值
2. 最大正值 \* 第二大正值 \* 第三大正值

通过排序可得上述所有数值

```java
class Solution {
  public int maximumProduct(int[] nums) {
    Arrays.sort(nums);
    return Math.max(nums[0] * nums[1] * nums[nums.length - 1], 
      nums[nums.length - 1] * nums[nums.length - 2] * nums[nums.length - 3]);
  }
}
```



## 3. Find max and min
思路: 上述解法中用到了排序, 但数组过长时其实对许多无用数值也进行了排序, 从而降低了效率. 设置几个变量记录所需数值即可.

```java
class Solution {
  public int maximumProduct(int[] nums) {
    int max1 = Integer.MIN_VALUE, max2 = Integer.MIN_VALUE, max3 = Integer.MIN_VALUE;
    int min1 = Integer.MAX_VALUE, min2 = Integer.MAX_VALUE;
    
    for (int i: nums) {
      if (i > max1) { /* the largest number */
        max3 = max2;
        max2 = max1;
        max1 = i;
      } else if (i > max2) { /* the 2th largest number */
        max3 = max2;
        max2 = i;
      } else if (i > max3) { /* the 3th largest number */
        max3 = i;
      }

      if (i < min1) { /* the smallest number */
        min2 = min1;
        min1 = i;
      } else if (i < min2) { /* the 2th smallest number */
        min2 = i;
      }
    }
  
    return Math.max(max1 * max2 * max3, max1 * min1 * min2);
  }
}
```
