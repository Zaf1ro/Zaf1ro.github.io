---
title: Guess Number Higher or Lower
category:
  - Algorithm
  - Binary Search
tag:
  - Algorithm
abbrlink: 1793713463
date: 2018-02-26 22:40:03
---

## 1. Description
We are playing the Guess Game. The game is as follows:
I pick a number from 1 to n. You have to guess which number I picked.
Every time you guess wrong, I'll tell you whether the number is higher or lower.
You call a pre-defined API guess(int num) which returns 3 possible results (-1, 1, or 0):
```text
-1 : My number is lower
 1 : My number is higher
 0 : Congrats! You got it!
```
Example:
```
n = 10, I pick 6.
Return 6.
```



## 2. Binary Search
思路: 二分法解决, 根据guess()的结果来判断下一次的区间范围
```java
/* The guess API is defined in the parent class GuessGame.
   @param num, your guess
   @return -1 if my number is lower, 1 if my number is higher, otherwise return 0
    int guess(int num);
*/
public class Solution extends GuessGame {
  public int guessNumber(int n) {
    int left = 1, right = n;
    while (left < right) {
      int mid = left + ((right - left) >> 1);
      int res = guess(mid);
      if (res == 0) return mid;
      if (res > 0) left = mid + 1; /* go to the right half */
      if (res < 0) right = mid; /* go to the left half */
    }
    return left;
  }
}
```
