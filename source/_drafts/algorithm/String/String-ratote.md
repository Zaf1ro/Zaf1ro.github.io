---
title: Rotate String
category:
  - Algorithm
  - String
tag:
  - Algorithm
abbrlink: 9e936a58
date: 2018-01-04 23:57:42
---

## 1. Description
针对一个字符串, 移动n个字符到字符串的尾部. 例如: s="abcdef", n=2, 则输出"cdefab"



## 2. 暴力法
每次向左移动一位, 直到移动了n位
注意点:
1. 保存第一位元素, 移动完放置到最后一位
```java
class Solution {
  public void leftShift(char[] arr) {
    char tmp = arr[0];
    for (int i=0; i<arr.length-1; i++)
      arr[i] = arr[i+1];
    arr[arr.length-1] = tmp;
  }

  public String RotateString(String s, int n) {
    if (s == null || s.length() == 0) return s;
    char[] arr = s.toCharArray();
    while (n-->0) leftShift(arr);
    return new String(arr);
  }
}
```



## 3. 反转法
针对这个问题, 可将一个字符串分为两个部分: X, 即为需要移动到尾部的字符串. Y, 即为需要向前移动的字符串. 反转操作写作"X^T"(例如: X="abc", X^T="cba"). 那么(X^T + Y^T)^T = Y+X. 例如s="abcedf", n=3. 先将"abc"反转为"cba", 再将"edf"反转为"fde", 最后将"cbafde"反转为"edfabc", 实现了整个反转.
```java
class Solution{
  public void reverse(char[] arr, int i, int j) {
    while (i < j) {
      char tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
      i++;
      j--;
    }
  }

  public String RotateString(String s, int n) {
    if (s == null || s.length() == 0) return s;
    char[] arr = s.toCharArray();
    reverse(arr, 0, n-1);
    reverse(arr, n, s.length()-1);
    reverse(arr, 0, s.length()-1);
    return new String(arr);
  }
}
```



## 4. 将n个字符移动到头部
针对一个字符串, 移动n个字符到字符串的头部. 例如: s="abcdef", n=2, 则输出"efabcd"
```java
class Solution {
  public void reverse(char[] arr, int i, int j){
    while (i < j) {
      char tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
      i++;
      j--;
    }
  }

  public String RotateString(String s, int n) {
    if (s == null || s.length() == 0) return s;
    char[] arr = s.toCharArray();
    reverse(arr, 0, s.length()-1);
    reverse(arr, 0, n-1);
    reverse(arr, n, s.length()-1);
    return new String(arr);
  }
}
```



## 5. 反转单词
给定一个字符串, 反转其中的单词. 例如: s="the sky is blue", 返回"blue is sky the". 空间复杂度为O(1), 时间复杂度为O(n)
注意点:
1. 先反转整个字符串
2. 再反转每个单词

```java
class Solution {
  public void reverse(char[] arr, int i, int j){
    while (i < j) {
      char tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
      i++;
      j--;
    }
  }
  
  public void reverseWords(char[] str) {
    if (str == null || str.length() == 0) return str;
    reverse(str, 0, str.length-1);
    int j = 0;
    for (int i=0; i<str.length; i++) {
      if(str[i] == ' ') {
        reverse(str, j, i-1);
        j = i+1;
      }
    }
    reverse(str, j, str.length-1);
  }
}
```
