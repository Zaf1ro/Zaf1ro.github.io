---
title: Excel Sheet
category:
  - Algorithm
  - Math
tag:
  - Algorithm
abbrlink: 528922831
date: 2018-02-23 02:51:04
---

## 1. Excel Sheet Column Number
### 1.1 Description
Description
Given a column title as appear in an Excel sheet, return its corresponding column number.
For example:
```text
  A -> 1
  B -> 2
  C -> 3
  ...
  Z -> 26
  AA -> 27
  AB -> 28
```

### 1.2 Solution
思路: 可将该题当做26进制的操作, 与10进制相同.
```java
class Solution {
  public int titleToNumber(String s) {
    if (s == null) return 0;
    int res = 0;
    for (int i = s.length() - 1, j = 0; i >= 0; i--, j++)
      res += Math.pow(26, j) * (s.charAt(i) - 'A' + 1);
    return res;
  }
}
``` 



## 2. Excel Sheet Column Title
### 2.1 Description
Given a positive integer, return its corresponding column title as appear in an Excel sheet.
For example:
```text
  1 -> A
  2 -> B
  3 -> C
  ...
  26 -> Z
  27 -> AA
  28 -> AB 
```

### 2.2 Solution
思路: 如上体相同, 但需要先确定第一个英文字母(代表最大的数值). 所以可用递归的深度遍历从前向后找到所有英文字母.
```java
class Solution {
  public String convertToTitle(int n) {
    if (n == 0) return "";
    if (n < 26) return "" + (char)(n - 1 + 'A');
    return "" + convertToTitle(n / 26) + convertToTitle(n % 26);
  }
}
```
