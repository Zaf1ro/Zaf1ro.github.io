---
title: String Contains
category:
  - Algorithm
  - String
tag:
  - Algorithm
abbrlink: 7561d971
date: 2018-01-05 10:07:59
---

## 1. Description
给定两个字符串A和B, 判断A字符串是否包含B, 不需要判断字符串顺序. 例如: A="ABCD", B="BAD", 返回true



## 2. Brute Force
针对字符串b中的每个字符, 都在字符串a中查找.
Time Complexity: $O(n^2)$
Space Complexity: $O(1)$
```java
class Solution {
  public boolean StringContains(String a, String b) {
    for (int i = 0; i < b.length(); i++) {
      int j;
      for (j = 0; j < a.length(); j++)
        if(b.charAt(i) == a.charAt(j)) break;
      if (j >= a.length()) return false;
    }
    return true;
  }
}
```



## 3. Sorting
先对字符串A和B进行排序, 然后进行线性扫描. 
Time Complexity: $O(\log(n))$
Space Complexity: $O(1)$
```java
class Solution{
  public boolean StringContains(String a, String b) {
    char[] arr1 = a.toCharArray();
    char[] arr2 = b.toCharArray();
    Arrays.sort(arr1);
    Arrays.sort(arr2);
    for (int i = 0, j = 0; j < arr2.length; i++, j++) { 
      while (i < arr1.length && arr1[i] < arr2[j])
        i++;
      if (i >= arr1.length || arr1[i] > arr2[j])
        return false;
    }
    return true;
  }
}
```



## 4. Statistic
先遍历String A, 将每个字母出现的次数记录在数组中. 再遍历String B, 查看数组元素是否大于0.
Time Complexity: $O(n)$
Space Complexity: $O(1)$
```java
class Solution {
  public boolean StringContains(String a, String b) {
    int[] times = new int[26];
    for (int i = 0; i < a.length(); i++)
      times[(int)a.charAt(i) - 'a']++;

    for(int i = 0; i < b.length(); i++)
      if(times[(int)b.charAt(i) - 'a']-- == 0)
        return false;

    return true;
  }
}
```
