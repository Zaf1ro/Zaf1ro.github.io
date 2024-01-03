---
title: MATLAB(4)
category:
  - Others
  - MATLAB
tag:
  - Others
abbrlink: 413903026
date: 2018-02-15 09:11:23
---

#### 1. Types of Arrays
##### 1.1 Multidimensional Arrays
1. create multidimensional array
可调用zeros, ones, rand和randn来生成多维矩阵和数组
```matlab
R = randn(3,4,5);   % create a 3-4-5 array, contains 3*4*5=60 random elements
```

2. create the permutations of 1:4
```matlab
p = perms(1:4)
ans =
     4     3     2     1
     4     3     1     2
     4     2     3     1
     4     2     1     3
     4     1     3     2
     4     1     2     3
     3     4     2     1
     3     4     1     2
     3     2     4     1
     3     2     1     4
     3     1     4     2
     3     1     2     4
     2     4     3     1
     2     4     1     3
     2     3     4     1
     2     3     1     4
     2     1     4     3
     2     1     3     4
     1     4     3     2
     1     4     2     3
     1     3     4     2
     1     3     2     4
     1     2     4     3
     1     2     3     4
```

3. interchange the magic square
```matlab

```
