---
title: Interaction f Two Array
category:
  - Algorithm
  - Array
tag:
  - Algorithm
abbrlink: 3560542613
date: 2018-01-29 12:06:12
---

## 1. 问题1
### 1.1 Description
Given two arrays, write a function to compute their intersection.

Example: 
Given nums1 = [1, 2, 2, 1], nums2 = [2, 2], return [2].

Note:
* Each element in the result must be unique.
* The result can be in any order.

### 1.2 HashSet
思路: 通过HashSet筛选出两个数组重合的部分
Time Complexity: O(n)
Space Complexity: O(n)
```java
class Solution {
  public int[] intersection(int[] nums1, int[] nums2) {
    Set<Integer> set = new HashSet<>();
    Set<Integer> interaction = new HashSet<>();
    
    for (int i: nums1)
      set.add(i);
    
    for (int i: nums2)
      if (set.contains(i))
        interaction.add(i);
    
    int[] res = new int[interaction.size()];
    Iterator<Integer> iter = interaction.iterator();
    for (int i = 0; i < res.length; ++i)
      res[i] = iter.next();
  
    return res;
  }
}
```

### 1.3 Sorting
对两个数组进行排序, 然后通过对比找到两数组中重合部分
Time Complexity: O(nlogn)
Space Complexity: O(n)
```java
class Solution {
  public int[] intersection(int[] nums1, int[] nums2) {
    Arrays.sort(nums1);
    Arrays.sort(nums2);
    int i = 0, j = 0;
    List<Integer> arr = new ArrayList<>();
    while (i < nums1.length && j < nums2.length) {
      if (nums1[i] == nums2[j]){
        arr.add(nums1[i]);
        while(i+1 < nums1.length && nums1[i] == nums1[i+1]) i++;
        while(j+1 < nums2.length && nums2[j] == nums2[j+1]) j++;
        i++;
        j++;
      } else if (nums1[i] < nums2[j]) {
        while(i+1 < nums1.length && nums1[i] == nums1[i+1]) i++;
        i++;
      } else {
        while(j+1 < nums2.length && nums2[j] == nums2[j+1]) j++;
        j++;
      }
    }

    int[] res = new int[arr.size()];
    for (int k = 0; k < res.length; k++)
      res[k] = arr.get(k);
  
    return res;
  }
}
```



## 2. 问题2
### 2.1 Description
Given two arrays, write a function to compute their intersection.

Example:
Given nums1 = [1, 2, 2, 1], nums2 = [2, 2], return [2, 2].

Note:
* Each element in the result should appear as many times as it shows in both arrays.
* The result can be in any order.

### 2.2 HashMap
思路: 先统计第一个数组中每个元素的出现次数, 再统计两个数组重复的元素在第二个数组中的出现次数, 结合可得结果.
Time Complexity: O(n)
Space Complexity: O(n)
```java
class Solution {
  public int[] intersect(int[] nums1, int[] nums2) {
    Map<Integer, Integer> map = new HashMap<>();
    for (int i: nums1)
      map.put(i, map.getOrDefault(i, 0) + 1);

    Map<Integer, Integer> interaction = new HashMap<>();
    for (int i: nums2)
      if (map.containsKey(i))
        interaction.put(i, interaction.getOrDefault(i, 0) + 1);
    
    List<Integer> arr = new ArrayList<>();
    for (Integer i: interaction.keySet()) {
      int times = Math.min(interaction.get(i), map.get(i));   /* 取最少出现次数 */
      for (int j = 0; j < times; j++)
        arr.add(i);
    }
    
    int[] res = new int[arr.size()];
    for (int i = 0; i < arr.size(); i++)
      res[i] = arr.get(i);

    return res;
  }
}
```

### 2.3 Sorting
思路: 与上一题相同, 只是要统计重复元素出现的次数
Time Complexity: O(nlogn)
Space Complexity: O(n)
```java
class Solution {
  public int[] intersect(int[] nums1, int[] nums2) {
    Arrays.sort(nums1);
    Arrays.sort(nums2);
    int i = 0, j = 0;
    int len1 = nums1.length, len2 = nums2.length;
    List<Integer> interaction = new ArrayList<>();
    
    while (i < len1 && j < len2) {
      if (nums1[i] == nums2[j]) {
        int t1 = 1, t2 = 1;
        while (i+1 < len1 && nums1[i] == nums1[i+1]) { t1++; i++; }
        while (j+1 < len2 && nums2[j] == nums2[j+1]) { t2++; j++; }
        for(int k = 0; k < Math.min(t1, t2); k++)
          interaction.add(nums1[i]);
        i++;
        j++;
      } else if (nums1[i] < nums2[j]) {
        while (i+1 < len1 && nums1[i] == nums1[i+1]) i++;
        i++;
      } else {
        while (j+1 < len2 && nums2[j] == nums2[j+1]) j++;
        j++;
      }
    }
    
    int[] res = new int[interaction.size()];
    for (int k = 0; k < res.length; k++)
      res[k] = interaction.get(k);

    return res;
  }
}
```
