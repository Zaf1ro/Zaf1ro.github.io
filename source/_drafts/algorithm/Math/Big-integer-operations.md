---
title: Big integer operations
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: 55aa0509
date: 2018-01-16 18:08:53
---

## 1. 加法运算
### 1.1 Description
Given two non-negative integers num1 and num2 represented as string, return the sum of num1 and num2.
```java
class Solution {
  public String addStrings(String num1, String num2) {}
}
```

### 1.2 问题点
1. 返回字符串的长度
2. 返回字符串的leading zero
3. 数值进位

```java
class Solution {
  public String addStrings(String num1, String num2) {
    int len1 = num1.length();
    int len2 = num2.length();
    int carry = 0;
    int len3 = Math.max(len1, len2) + 1; // 返回值的长度为最长字符串长度+1
    char[] res = new char[len3];
    while (len1 > 0 || len2 > 0) {
      int n1 = len1 > 0 ? num1.charAt(len1 - 1) - '0' : 0;
      int n2 = len2 > 0 ? num2.charAt(len2 - 1) - '0' : 0;
      int n = n1 + n2 + carry;
      if (n > 9) { // 进位操作
        res[len3 - 1] = Character.forDigit(n % 10, 10);
        carry = n / 10;
      } else {
        carry = 0;
        res[len3 - 1] = Character.forDigit(n, 10);
      }
      len1 --;
      len2 --;
      len3 --;
    }
    res[0] = Character.forDigit(carry, 10);
    String str = new String(res);
    // remove leading zero
    return res[0] != '0' ? str : str.substring(1, str.length());
  }
}
```



## 2. 乘法运算
### 2.1 Description
Given two non-negative integers num1 and num2 represented as strings, return the product of num1 and num2.
```java
class Solution {
  public String multiply(String num1, String num2) {}
}
```

### 2.2 问题点
1. num1 == 0 || num2 == 0: 直接返回0
2. 数值进位
3. 返回字符串的长度
4. leading zero

```java
class Solution {
  public String multiply(String num1, String num2) {
    // 判断是否有乘数为0
    if (num1.equals("0") || num2.equals("0")) return "0";
    
    int len1 = num1.length();
    int len2 = num2.length();
    int[] arr = new int[len1 + len2];
    
    for (int i = len1 - 1; i >= 0; i--) {
      int n1 = num1.charAt(i) - '0';
      for (int j = len2 - 1; j >= 0; j--) {
        int n2 = num2.charAt(j) - '0';
        arr[i + j + 1] += n1 * n2;  // 乘法操作
      }
    }
    for (int i = arr.length - 1; i > 0; i--) {
      if (arr[i] > 9) { // 进位操作
        arr[i - 1] += arr[i] / 10;
        arr[i] = arr[i] % 10;
      }
    }
    StringBuilder sb = new StringBuilder();
    int i = 0;
    while (arr[i] == 0) ++i;   // remove leading zero
    for (;i < arr.length; i++)
      sb.append(Character.forDigit(arr[i], 10));
    return sb.toString();
  }
}
```

