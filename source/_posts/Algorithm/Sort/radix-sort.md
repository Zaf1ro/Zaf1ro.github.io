---
title: Radix Sort
category:
  - Algorithm
  - Sort
tag:
  - Algorithm
abbrlink: a577
date: 2023-03-15 22:47:24
keywords:
description:
---

## Radix Sort
Radix Sort(基数排序)是一种**non-comparative sorting algorithm**(非比较排序算法). 算法会根据元素的radix将元素分配到不同的bucket, 若元素包含多个radix, 可依次对每个radix进行排序, 从而实现对所有元素的排序. Radix(也称为base)为表示一种数字的数学符号数量, 以十进制为例, radix为10, 因为每一位只能使用`[0, 9]`范围的数学符号.
根据排序时digit order的不同, radix sort分为两种: **MSD**(most significant digit)和**LSD**(least significant digit), 以数字1234为例, MSD从1开始, LSD从4开始. 以下是LSD和MSD的不同适用场景:
* LSD: 较短的元素排在较长的元素前, 且相同长度的元素按字典顺序排序, 例如integer
* MSD: string或等长的integer

Radix sort通常使用counting sort实现, 时间复杂度为$O(d(n+b))$(`n`为元素数量, `d`为digit数量, `b`为bucket数量), 空间复杂度为`$O(b + n)$`. 若bucket数或digit数远多于元素数, 可使用基于比较的排序, 时间复杂度为`$O(nk\log(n))$`.

以下是基于LSD的integer排序:
```java
private final static int BIT_PER_BYTE = 8; 
private final static int R = 1 << BIT_PER_BYTE; // each byte is between 0 and 255
private final static int mask = R - 1;

private static void LSDsort(int[] nums) {
    int[] aux = new int[nums.length];
    // each integer contains 4 bytes, LSD from low order to high order byte
    for (int d = 0; d < 4; d++) {
        int[] count = new int[R+1];
        // compute frequency counts
        for (int num: nums) {
            int c = (num >> BIT_PER_BYTE * d) & mask;
            count[c+1]++;
        }
        // compute cumulates
        for (int i = 0; i < R; i++) {
            count[i+1] += count[i];
        }
        // for highest order byte, 0x80-0xFF are all negative numbers
        if (d == 3) {
            // count of negative and positive number
            int neg = count[R] - count[R>>1], pos = count[R>>1];
            for (int i = 0; i < R>>1; i++) {
                count[i] += neg;
            }
            for (int i = R>>1; i < R; i++) {
                count[i] -= pos;
            }
        }
        // distribute
        for (int num: nums) {
            int c = (num >> BIT_PER_BYTE * d) & mask;
            aux[count[c]++] = num;
        }
        int[] tmp = nums;
        nums = aux;
        aux = tmp;
    }
}
```

以下是基于MSD的string排序:
```java
public static void MSDsort(String[] arr) {
    MSDsort(arr, 0, arr.length-1, 0, new String[n]);
}

// return dth character of s, 0 if d >= length of string 
private static int charAt(String s, int idx) {
    if (idx < 0 || idx >= s.length()) return 0;
    return s.charAt(idx);
}

private static void MSDsort(String[] arr, int l, int r, int d, String[] aux) {
    if (l >= r) return;
    int[] count = new int[256];
    // compute frequency of dth character in each string
    for (int i = l; i <= r; i++) {
        count[charAt(arr[i], d)+1]++;
    }
    // compute cumulates
    for (int i = 0; i < 255; i++) {
        count[i+1] += count[i];
    }
    // distribute
    for (int i = l; i <= r; i++) {
        aux[count[charAt(arr[i], d)]++] = arr[i];
    }
    for (int i = l; i <= r; i++) {
        arr[i] = aux[i];
    }
    // recursively sort for each character
    for (int i = 0; i < 255; i++) {
        MSDsort(arr, l+count[i], l+count[i+1]-1, d+1, aux);
    }
}
```


## 2343. Query Kth Smallest Trimmed Number
You are given a **0-indexed** array of strings nums, where each string is of **equal length** and consists of only digits.

You are also given a **0-indexed** 2D integer array `queries` where `$queries[i] = [k_i, trim_i]$`. For each `queries[i]`, you need to:
* **Trim** each number in `nums` to its **rightmost** trimi digits.
* Determine the **index** of the `$k_i^{th}$` smallest trimmed number in nums. If two trimmed numbers are equal, the number with the **lower** index is considered to be smaller.
* Reset each number in `nums` to its original length.

Return an array `answer` of the same length as `queries`, where `answer[i]` is the answer to the `$i^{th}$` query.

Example 1:
```
Input: nums = ["102","473","251","814"], queries = [[1,1],[2,3],[4,2],[1,2]]
Output: [2,2,1,0]
Explanation:
1. After trimming to the last digit, nums = ["2","3","1","4"]. The smallest number is 1 at index 2.
2. Trimmed to the last 3 digits, nums is unchanged. The 2nd smallest number is 251 at index 2.
3. Trimmed to the last 2 digits, nums = ["02","73","51","14"]. The 4th smallest number is 73.
4. Trimmed to the last 2 digits, the smallest number is 2 at index 0.
```

### Radix Sort
Radix sort依次比较index上的character时, 会完成每个trimmed number的排序.
```java
class Solution {
    private int R = 128;

    public int[] smallestTrimmedNumbers(String[] nums, int[][] queries) {
        Map<Integer, List<int[]>> map = new HashMap<>(); // trim -> ith smalllest, index;
        int n = nums.length, m = queries.length, k = nums[0].length();
        for (int i = 0; i < k; i++) {
            map.put(i, new ArrayList<>());
        }
        for (int i = 0; i < m; i++) {
            map.get(k-queries[i][1]).add(new int[]{queries[i][0]-1, i});
        }
        int[] res = new int[m], index = new int[n], aux = new int[n];
        for (int i = 1; i < n; i++) {
            index[i] = i;
        }
        for (int d = k-1; d >= 0; d--) {
            int[] count = new int[R+1];
            for (int i = 0; i < n; i++) {
                char c = nums[index[i]].charAt(d);
                count[c+1]++;
            }
            for (int i = 0; i < R; i++) {
                count[i+1] += count[i];
            }
            for (int i = 0; i < n; i++) {
                char c = nums[index[i]].charAt(d);
                aux[count[c]++] = index[i];
            }
            int[] t = index;
            index = aux;
            aux = t;
            List<int[]> q = map.get(d);
            for (int[] p: q) {
                res[p[1]] = index[p[0]];
            }
        }
        return res;
    }
}
```


## 164. Maximum Gap
Given an integer array `nums`, return the maximum difference between two successive elements in its sorted form. If the array contains less than two elements, return `0`.

You must write an algorithm that runs in linear time and uses linear extra space.

Example 1:
```
Input: nums = [3,6,9,1]
Output: 3
Explanation: The sorted form of the array is [1,3,6,9], either (3,6) or (6,9) has the maximum difference 3.
```

### Radix Sort
基于比较的排序算法只能达到$O(n\log(n))$时间复杂度, 可使用radix sort排序数组. 题目规定$nums[i] \ge 0$, 因此不必处理负值的高位byte.
```java
class Solution {
    private final int BITS_PER_BYTE = 8;
    private final int R = 1 << 8;
    private final int MASK = R - 1;
    
    public int maximumGap(int[] nums) {
        if (nums.length < 2) return 0;
        int[] aux = new int[nums.length];
        for (int d = 0; d < 4; ++d) {
            int[] count = new int[R+1];
            for (int num: nums) {
                int t = (num >> BITS_PER_BYTE * d) & MASK;
                ++count[t+1];
            }
            for (int i = 0; i < R; i++) {
                count[i+1] += count[i];
            }
            for (int num: nums) {
                int t = (num >> BITS_PER_BYTE * d) & MASK;
                aux[count[t]++] = num;
            }
            int[] t = nums;
            nums = aux;
            aux = t;
        }
        int res = 0;
        for (int i = 1; i < nums.length; i++) {
            res = Math.max(res, nums[i] - nums[i-1]);
        }
        return res;
    }
}
```


