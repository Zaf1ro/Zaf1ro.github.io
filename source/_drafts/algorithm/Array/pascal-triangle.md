---
title: Pascal Triangle
category:
  - Algorithm
  - Array
tag:
  - Algorithm
abbrlink: 720c
date: 2018-01-31 09:02:45
---

## 1. 问题1
### 1.1 Description
Given numRows, generate the first numRows of Pascal's triangle.
For example, given numRows = 5, Return
```text
[
     [1],
    [1,1],
   [1,2,1],
  [1,3,3,1],
 [1,4,6,4,1]
]
```

### 1.2 解法
思路: 第m行的第n个元素 = 第m-1行的第n-1个元素值 + 第m-1行的第n个元素. 越界数值可视为0
```java
public class Solution {
  public List<List<Integer>> generate(int numRows) {
    List<List<Integer>> res = new ArrayList<List<Integer>>();
    if (numRows <= 0)
      return res;

    for (int i = 0; i < numRows; i++) {
      List<Integer> row =  new ArrayList<Integer>();
      for (int j = 0; j < i + 1; j++){
        if (j == 0 || j == i){
          row.add(1);
        } else {
          row.add(res.get(i - 1).get(j - 1) + res.get(i - 1).get(j));
        }
      }
      res.add(row);
    }
    return res;
  }
}
```



## 2. 问题2
### 2.1 Description
Given an index k, return the kth row of the Pascal's triangle.
For example, given k = 3,
Return [1,3,3,1].

### 2.2 解法1
思路: 和上一题一样, 每一行生成一个数组
```java
class Solution {
  public List<Integer> getRow(int rowIndex) {
    if (rowIndex < 0) 
      return new ArrayList<>();
    
    List<Integer> prev = null, row = null;
    for (int i = 0; i <= rowIndex; i++){
      row = new ArrayList<>();
      for (int j = 0; j <= i; j++) {
        if (j == 0 || j == i)
          row.add(1);
        else
          row.add(prev.get(j - 1) + prev.get(j));
      }
      prev = row;
    }
    return row;
  }
}
```

### 2.3 解法2
思路: 从后向前累加数组元素
```java
class Solution {
  public List<Integer> getRow(int rowIndex) {
    List<Integer> row = new ArrayList<>();
    if (rowIndex < 0)
      return row;
    
    for (int i = 0; i < rowIndex + 1 ; i++)
      row.add(0);
    
    row.set(0, 1);
    for (int i = 1; i <= rowIndex; i++)
      for (int j = i; j > 0; j--)
        row.set(j, row.get(j) + row.get(j - 1));

    return row;
  }
}
```
