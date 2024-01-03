---
title: Counting Sort
abbrlink: 387d
date: 2023-03-19 22:29:48
category:
  - Algorithm
  - Sort
tag:
  - Algorithm
keywords:
description:
---

## Counting Sort
Counting sort是一种**non-comparative sorting algorithm**(非比较排序算法), 主要用于数值偏小的正整数集合排序. 假设数组`A`拥有`n`个元素`{1,2,...,k}`, 算法步骤如下:
1. 创建一个数组`C`, 其长度为`k`, 所有元素初始化为0
2. 遍历`A`, 对于每个元素`i`, `C[i]`加一
3. 遍历`C`, 对于每个元素`j`, 将`C[j]`个`j`放入结果中

算法的时间复杂度为`$O(n + k)$`(`n`为元素数, `k`为键值范围). 需要注意的是, 若`A`中拥有两个数字3, 则上述步骤只会将3放入结果中两遍. 若想保持算法的**stability**(稳定性), 则需对算法步骤做出修改: `C[j]`原本用于表示元素`j`的出现次数, 若对`[1, k-1]`范围的`C[j]`执行`C[j] += C[j-1]`, 则`C[j]`表示`[0, j]`范围内元素的出现次数, 再次遍历`A`时, 对于每个元素`i`, `C[i]`则表示`i`在`A`中的位置, 从而让该排序算法成为**stable sort**, 时间复杂度为`$O(n + k + n)  = O(2n + k) = O(n + k)$`.


## 1122. Relative Sort Array
Given two arrays `arr1` and `arr2`, the elements of `arr2` are distinct, and all elements in `arr2` are also in `arr1`.

Sort the elements of `arr1` such that the relative ordering of items in `arr1` are the same as in `arr2`. Elements that do not appear in `arr2` should be placed at the end of `arr1` in **ascending** order.

Example 1:
```
Input: arr1 = [2,3,1,3,2,4,6,7,9,2,19], arr2 = [2,1,4,3,9,6]
Output: [2,2,2,1,4,3,3,9,6,7,19]
```

### Counting sort
先统计`$arr_1$`中每个元素的出现次数, 再遍历`$arr_2$`, 将每个出现过的元素加入结果中, 最后再遍历`$arr_1$`, 将剩余元素放入结果中. `count`作为一个辅助数组, 既可保证元素按照`$arr_2$`中的顺序, 也可作为一个字典帮助查询`$arr_1$`中的元素是否出现在`$arr_2$`中.
```java
class Solution {
    public int[] relativeSortArray(int[] arr1, int[] arr2) {
        int[] count = new int[1001], res = new int[arr1.length];
        for (int num: arr1) {
            ++count[num];
        }
        int i = 0;
        for (int num: arr2) {
            while (count[num]-- > 0) res[i++] = num;
        }
        for (int num = 0; num <= 1000; num++) {
            while (count[num]-- > 0) res[i++] = num;
        }
        return res;
    }
}
```


## 274. H-Index
Given an array of integers `citations` where `citations[i]` is the number of citations a researcher received for their `$i^{th}$` paper, return compute the researcher's **h-index**.

According to the definition of h-index on Wikipedia: A scientist has an index `h` if `h` of their n papers have at least `h` citations each, and the other `n − h` papers have no more than `h` citations each.

If there are several possible values for `h`, the maximum one is taken as the **h-index**.

Example 1:
```
Input: citations = [3,0,6,1,5]
Output: 3
Explanation: [3,0,6,1,5] means the researcher has 5 papers in total and each of them had received 3, 0, 6, 1, 5 citations respectively.
Since the researcher has 3 papers with at least 3 citations each and the remaining two with no more than 3 citations each, their h-index is 3.
```

### Counting sort
创建一个`count`数组, 并遍历`citations`, 统计每篇论文的引用次数, 此时`C`中的`i`为引用次数, `C[i]`为该引用次数的论文数. 若统计`C`中每个元素的**suffix sum**(后缀和), 则`C[i]`表示`[i, 1000]`引用次数的总论文数, 若`C[i] >= i`, 则表示有`i`篇论文, 它们的引用次数大于或等于`i`, 满足H-index的定义.
```java
class Solution {
    public int hIndex(int[] citations) {
        int[] count = new int[1001];
        for (int c: citations) {
            ++count[c];
        }
        for (int i = 1000; i > 0; i--) {
            count[i-1] += count[i];
            if (count[i] >= i) return i;
        }
        return 0;
    }
}
```
