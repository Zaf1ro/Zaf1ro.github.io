---
title: Backtracking
category:
  - Algorithm
  - Basic
tag:
  - Algorithm
abbrlink: 9d13
date: 2024-04-05 12:42:10
keywords:
description:
---

## Introduction
遇到问题不要考虑多层情况, 只需考虑**边界条件**和**非边界条件的逻辑**, 剩下的交给数学归纳法.


## Subset Backtracking
子集型回溯的题目通常要求返回一个元素数组中所有组合的结果, 组合的长度不同, 但不允许存在重复组合. 以下是两种解题模板:
* 第一种模板: 对于每个元素只有两种操作: 选或不选. 因此可对数组中的每i个元素进行选和不选的两种操作, 接下来只需对`[i+1, n)`的数字中构造子集即可.
* 第二种模板: 每次必须选择一个元素. 因此必须选择第i个元素, 并从`[i+1, n-1]`, `[i+2, n-1]`, ..., `[n-1, n-1]`中构建子集.

需要注意的是, 为了去除重复的组合, 需指定一个元素遍历的顺序, 也就是`从左向右`或`从右向左`依次遍历, 遍历过程中不可回头.

### 78. Subsets
Given an integer array nums of **unique** elements, return all possible subsets (the power set).
The solution set **must not** contain duplicate subsets. Return the solution in **any order**.

Example 1:
```
Input: nums = [1,2,3]
Output: [[],[1],[2],[1,2],[3],[1,3],[2,3],[1,2,3]]
```

Example 2:
```
Input: nums = [0]
Output: [[],[0]]
```

#### Solution
模板一: 每个元素采取选或不选两种方式, 并逐步递归.
```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();
    
    public List<List<Integer>> subsets(int[] nums) {
        backtracking(nums, 0, new ArrayList<>());
        return res;
    }

    private void backtracking(int[] nums, int i, List<Integer> arr) {
        if (i == nums.length) {
            res.add(new ArrayList<>(arr));
            return;
        }
        // skip
        backtracking(nums, i+1, arr);
        // pick up
        arr.add(nums[i]);
        backtracking(nums, i+1, arr);
        arr.remove(arr.size()-1);
    }
}
```

模板二: 必须选择当前元素, 并从之后的每个元素中递归.
```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();
    
    public List<List<Integer>> subsets(int[] nums) {
        backtracking(nums, 0, new ArrayList<>());
        return res;
    }

    private void backtracking(int[] nums, int start, List<Integer> arr) {
        res.add(new ArrayList<>(arr));
        for (int i = start; i < nums.length; i++) {
            // pick up nums[i]
            arr.add(nums[i]);
            backtracking(nums, i+1, arr);
            arr.remove(arr.size()-1);
        }
    }
}
```

### 90. Subsets II
Given an integer array nums that may contain `duplicates`, return all possible subsets (the power set).

The solution set `must not` contain duplicate subsets. Return the solution in any order.

Example 1:
```
Input: nums = [1,2,2]
Output: [[],[1],[1,2],[1,2,2],[2],[2,2]]
```

Example 2:
```
Input: nums = [0]
Output: [[],[0]]
```

#### Solution
由于数组中存在重复元素, 因此直接套用模板一和模板二都会导致重复组合. 假设数组为`[1,1,1]`:
* 模板二: 先选择第一个1, 进入递归并退出递归后, 其实已经包含了所有组合, 因此第二个1和第三个1无需选择和进入递归. 若当前元素不是首个被选择的元素, 且与前一个元素相同(假设数组已排序), 那么上一个元素的递归结果已包含当前元素的递归结果, 跳过即可.
* 模板一: 当进入下一次递归时, 当前递归并不知道上一个元素是否被选择, 因此无法知道是否应该跳过.

```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();

    public List<List<Integer>> subsetsWithDup(int[] nums) {
        Arrays.sort(nums);
        backtracking(nums, 0, new ArrayList<>());
        return res;
    }

    private void backtracking(int[] nums, int start, List<Integer> arr) {
        res.add(new ArrayList<>(arr));
        for (int i = start; i < nums.length; i++) {
            if (i > start && nums[i] == nums[i-1]) continue; // skip if duplicate
            arr.add(nums[i]);
            backtracking(nums, i+1, arr);
            arr.remove(arr.size()-1);
        }
    }
}
```


### Palindrome Partitioning
Given a string `s`, partition `s` such that every substring of the partition is a **palindrome**. Return all possible palindrome partitioning of `s`.

Example 1:
```
Input: s = "aab"
Output: [["a","a","b"],["aa","b"]]
```

#### Solution
该题使用模板一, 但该题无需跳过某个字符, 而是判断选择的子字符串是否为回文串.
```java
class Solution {
    private List<List<String>> res = new ArrayList<>();

    public List<List<String>> partition(String s) {
        backtracking(s, 0, new ArrayList<>());
        return res;
    }

    private void backtracking(String s, int i, List<String> arr) {
        if (i == s.length()) {
            res.add(new ArrayList<>(arr));
            return;
        }
        for (int j = i+1; j <= s.length(); j++) {
            String s1 = s.substring(i, j), s2 = new StringBuilder(s1).reverse().toString();
            if (s1.equals(s2)) {
                arr.add(s1);
                backtracking(s, j, arr);
                arr.remove(arr.size()-1);
            }
        }
    }
}
```


## Combination Backtracking
组合型回溯的题目通常要求一个元素数组中的相同长度的组合结果, 且组合不可重复. 由于子集型回溯包含所有组合结果, 因此组合型回溯的组合结果其实是子集型回溯结果的一个子集. 假设元素数组为`[1,2,3]`, 则子集型回溯的流程如下:
* 选1, 组合为[1]
    * 选2, 组合为[1,2]
        * 选3, 组合为[1,2,3] -> 结束
    * 选3, 组合为[1,3] -> 结束
* 选2, 组合为[2] 
    * 选3, 组合为[2,3] -> 结束
* 选3, 组合为[3] -> 结束

若组合型回溯要求从`[1,2,3]`中选出所有长度为1的组合, 则为子集型回溯流程的第一列([1],[2],[3]); 若要求长度为2的组合, 则为子集型回溯流程中的第二列([1,2], [1,3], [2,3]). 因此可在子集型回溯的基础上做一些改动, 从而得到组合型回溯的结果: 假设当前数组的长度为m, 要求结果中的组合长度为k, 那么当前递归中还需`d = k - m`个数字, 假设从`[1, i]`中选择数字
* 若`m = k`, 则当前数组为结果中的一种组合
* 若`i < d`, 则必然无法选出k个数, 无需继续递归
 

### 77. Combinations
Given two integers `n` and `k`, return all possible combinations of `k` numbers chosen from the range `[1, n]`.
You may return the answer in **any order**.

Example 1:
```
Input: n = 4, k = 2
Output: [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
Explanation: There are 4 choose 2 = 6 total combinations.
Note that combinations are unordered, i.e., [1,2] and [2,1] are considered to be the same combination.
```

#### Solution
模板一: 对于每个元素只有两种情况: 选或不选. 选元素时需保证当前数组不超过k个元素, 不选时需检查之后的元素是否足够k个元素.
```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();

    public List<List<Integer>> combine(int n, int k) {
        backtracking(n, k, new ArrayList<>());
        return res;
    }

    private void backtracking(int i, int k, List<Integer> arr) {
        if (arr.size() == k) {
            res.add(new ArrayList<>(arr));
            return;
        }
        if (i > k - arr.size()) {
            backtracking(i-1, k, arr);
        }
        arr.add(i);
        backtracking(i-1, k, arr);
        arr.remove(arr.size()-1);
    }
}
```

模板二: 必须将当前元素放入数组中, 则需保证以下两点:
* 当前数组的长度不可超过k
* `[i+1, n]`表示之后还可以添加的元素数量, `k - 当前数组长度`表示组合还需要几个元素, 因此需保证`len([i+1, n]) >= k - len(arr)`

```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();

    public List<List<Integer>> combine(int n, int k) {
        backtracking(n, k, new ArrayList<>());
        return res;
    }

    private void backtracking(int i, int k, List<Integer> arr) {
        if (i < k - arr.size()) return;
        if (arr.size() == k) {
            res.add(new ArrayList<>(arr));
            return;
        }
        for (int j = i; j > 0; j--) {
            arr.add(j);
            backtracking(j-1, k, arr);
            arr.remove(arr.size()-1);
        }
    }
}
```

### 39. Combination Sum
Given an array of **distinct** integers `candidates` and a target integer target, return a list of all **unique combinations** of `candidates` where the chosen numbers sum to `target`. You may return the combinations in **any order**.
The **same** number may be chosen from candidates an **unlimited number of times**. Two combinations are unique if the frequency of at least one of the chosen numbers is different.
The test cases are generated such that the number of unique combinations that sum up to `target` is less than `150` combinations for the given input.

Example 1:
```
Input: candidates = [2,3,6,7], target = 7
Output: [[2,2,3],[7]]
Explanation:
2 and 3 are candidates, and 2 + 2 + 3 = 7. Note that 2 can be used multiple times.
7 is a candidate, and 7 = 7.
These are the only two combinations.
```

#### Solution
该题目需要注意两点:
* 每个元素都可以被选择无数次
* 没有要求组合的长度, 但要求当前数组的总和等于target, 因此需修改边界条件

模板一:
```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();

    public List<List<Integer>> combinationSum(int[] candidates, int target) {
        Arrays.sort(candidates);
        backtracking(candidates, 0, target, new ArrayList<>());
        return res;
    }
 
    private void backtracking(int[] candidates, int i, int target, List<Integer> arr) {
        if (target == 0) {
            res.add(new ArrayList<>(arr));
            return;
        }
        if (i == candidates.length || target < candidates[i]) return;
        // skip
        backtracking(candidates, i+1, target, arr);
        // pick up
        arr.add(candidates[i]);
        backtracking(candidates, i, target-candidates[i], arr); // i instead of i+1
        arr.remove(arr.size()-1);
    }
}
```

模板二:
```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();

    public List<List<Integer>> combinationSum(int[] candidates, int target) {
        Arrays.sort(candidates);
        backtracking(candidates, 0, target, new ArrayList<>());
        return res;
    }
 
    private void backtracking(int[] candidates, int i, int target, List<Integer> arr) {
        if (target == 0) {
            res.add(new ArrayList<>(arr));
            return;
        }
        if (i == candidates.length || target < candidates[i]) return;
        for (int j = i; j < candidates.length; j++) {
            arr.add(candidates[j]);
            backtracking(candidates, j, target-candidates[j], arr); // j instead of j+1
            arr.remove(arr.size()-1);
        }
    }
}
```

### 40. Combination Sum II
Given a collection of candidate numbers (`candidates`) and a target number (`target`), find all unique combinations in `candidates` where the candidate numbers sum to `target`.
Each number in `candidates` may only be used **once** in the combination.

Example 1:
```
Input: candidates = [10,1,2,7,6,1,5], target = 8
Output: 
[
    [1,1,6],
    [1,2,5],
    [1,7],
    [2,6]
]
```

#### Solution
该题需注意几个点:
* 每个元素只能使用一次: 与传统的子集型回溯问题相同
* 没有组合的长度要求, 而是求和要求: 与上一题相同
* 组合不可重复: 与子集型回溯的Subset II问题相同

因此可采用模板二, 并稍作修改:
```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();
    
    public List<List<Integer>> combinationSum2(int[] candidates, int target) {
        Arrays.sort(candidates);
        backtrack(candidates, 0, target, new ArrayList<>());
        return res;
    }

    private void backtrack(int[] candidates, int i, int target, List<Integer> arr) {
        if (target == 0) {
            res.add(new ArrayList<>(arr));
            return;
        }
        if (i == candidates.length || candidates[i] > target) return;
        for (int j = i; j < candidates.length; j++) {
            if (j > i && candidates[j-1] == candidates[j]) continue;
            arr.add(candidates[j]);
            backtrack(candidates, j+1, target-candidates[j], arr);
            arr.remove(arr.size()-1);
        }
    }
}
```

### 216. Combination Sum III
Find all valid combinations of `k` numbers that sum up to n such that the following conditions are true:
* Only numbers `1` through `9` are used.
* Each number is used **at most once**.

Return a list of all possible valid combinations. The list must not contain the same combination twice, and the combinations may be returned in any order.

Example 1:
```
Input: k = 3, n = 7
Output: [[1,2,4]]
Explanation:
1 + 2 + 4 = 7
There are no other valid combinations.
```

#### Solution
该题的要求如下:
* `[1, 9]`中每个数字只能选择一个: 元素只能向一个方向移动, 不能原地踏步
* 要求组合的长度: 边界条件中判断组合长度是否越界
* 要求组合的总和: 边界条件中判断组合总和是否越界

模板一:
```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();
    
    public List<List<Integer>> combinationSum3(int k, int n) {
        backtracking(k, n, 1, new ArrayList<>());
        return res;
    }

    private void backtracking(int k, int n, int i, List<Integer> arr) {
        if (n == 0 && k == 0) {
            res.add(new ArrayList<>(arr));
            return;
        }
        if (i > n || k == 0 || i > 9) return; // n cannot be negative, k cannot be negative, i cannot be bigger than 9
        // skip
        backtracking(k, n, i+1, arr);
        // pick up
        arr.add(i);
        backtracking(k-1, n-i, i+1, arr); // i -> i + 1, deduplicate
        arr.remove(arr.size()-1);
    }
}
```

模板二:
```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();
    
    public List<List<Integer>> combinationSum3(int k, int n) {
        backtracking(k, n, 1, new ArrayList<>());
        return res;
    }

    private void backtracking(int k, int n, int i, List<Integer> arr) {
        if (n == 0 && k == 0) {
            res.add(new ArrayList<>(arr));
            return;
        }
        if (i > n || k == 0) return;
        for (int j = i; j <= 9; j++) {
            arr.add(j);
            backtracking(k-1, n-j, j+1, arr); // j -> j + 1, deduplicate
            arr.remove(arr.size()-1);
        }
    }
}
```


## Permutation
排列型回溯的题目通常要求返回一个数组中所有元素的不同排列组合, 因此每个组合的长度与原数组相同, 组合的个数就是数组长度的阶乘, 假设数组为`[1,2,3]`, 则组合数为`3! = 1*2*3 = 6`. 相比于组合型回溯, 元素的顺序至关重要. 假设`path`表示已选元素的集合, `s`表示未选的元素, 回溯的整个流程如下:
* 当前操作: 从`s`中枚举每个元素作为组合的第i个元素(`path[i]`), 并将该元素从`s`中移除
* 子问题: 获得组合的第i+1个元素
* 边界条件: 组合的长度等同于数组长度

整个回溯可写作: `dfs(i, s) -> dfs(i+1, s-{x1}), dfs(i+1, s-{x2}) ....`

### 46. Permutations
Given an array `nums` of distinct integers, return all the possible permutations. You can return the answer in **any order**.

Example 1:
```
Input: nums = [1,2,3]
Output: [[1,2,3],[1,3,2],[2,1,3],[2,3,1],[3,1,2],[3,2,1]]
```

#### Solution
当前操作: 从`nums`中枚举每个数字, 作为`arr`的第i个数字
子问题: 获得`arr`的第i+1个数字
边界条件: `i == nums.length`时, 可将`arr`作为结果之一

需要注意的是, 当元素加入到`arr`时, 需从`nums`中移除该元素, 因此我们传入一个`isUsed`判断遍历的元素是否被采用.

```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();
    
    public List<List<Integer>> permute(int[] nums) {
        backtracking(nums, new ArrayList<>(), new boolean[nums.length]);
        return res;
    }

    private void backtracking(int[] nums, List<Integer> arr, boolean[] isUsed) {
        if (arr.size() == nums.length) {
            res.add(new ArrayList<>(arr));
            return;
        }
        for (int i = 0; i < nums.length; i++) {
            if (isUsed[i]) continue;
            isUsed[i] = true;
            arr.add(nums[i]);
            backtracking(nums, arr, isUsed);
            arr.remove(arr.size()-1);
            isUsed[i] = false;
        }
    }
}
```

### 47. Permutations II
Given a collection of numbers, `nums`, that might contain duplicates, return all possible unique permutations **in any order**.

Example 1:
```
Input: nums = [1,1,2]
Output:
[[1,1,2],
 [1,2,1],
 [2,1,1]]
```

#### Solution
该题与上一题基本相同, 唯一区别在于: 原数组中存在重复元素. 以`[1,1]`为例:
每次递归都枚举`nums`中的每个元素, 作为`arr`的第i个元素. 由于`nums[0] == nums[1]`, 因此, 当`nums[1]`作为`arr`的第一个元素时, 会与`nums[0]`作为`arr`的第一个元素产生的组合相同. 因此枚举当前元素时, 若满足以下两点, 则跳过当前元素:
* 当前元素与上一个元素值相等
* 上一个元素尚未作为组合中的元素 

```java
class Solution {
    private List<List<Integer>> res = new ArrayList<>();
    
    public List<List<Integer>> permuteUnique(int[] nums) {
        Arrays.sort(nums);
        backtracking(nums, new boolean[nums.length], new ArrayList<>());
        return res;
    }

    private void backtracking(int[] nums, boolean[] isUsed, List<Integer> arr) {
        if (arr.size() == nums.length) {
            res.add(new ArrayList<>(arr));
            return;
        }
        for (int i = 0; i < nums.length; i++) {
            if (isUsed[i]) continue;
            if (i > 0 && nums[i-1] == nums[i] && !isUsed[i-1]) continue;
            isUsed[i] = true;
            arr.add(nums[i]);
            backtracking(nums, isUsed, arr);
            arr.remove(arr.size()-1);
            isUsed[i] = false;
        }
    }
}
```

### 51. N-Queens
The **n-queens** puzzle is the problem of placing `n` queens on an `n x n` chessboard such that no two queens attack each other.
Given an integer `n`, return all distinct solutions to the **n-queens puzzle**. You may return the answer in **any order**.
Each solution contains a distinct board configuration of the n-queens' placement, where `'Q'` and `'.'` both indicate a queen and an empty space, respectively.

Example 1:
```
Input: n = 4
Output: [
    [".Q..",
     "...Q",
     "Q...",
     "..Q."],
    ["..Q.",
     "Q...",
     "...Q",
     ".Q.."]
]
Explanation: There exist two distinct solutions to the 4-queens puzzle as shown above
```

#### Solution
该题要求在`n*n`的棋盘上放置`n`个皇后, 由于两个皇后无法同行同列, 因此每个行只有一个皇后, 每一列也只有一个皇后. 对于对角线, 通过观察`[0,0] -> [n-1,n-1]`上的坐标, 可以发现该对角线上的行和列相减为`0`; 通过观察`[0,n-1] -> [n-1,0]`上的坐标, 可以发现该对角线上的行和列之和为`n-1`. 假设现在我们有一个长度为`n`的数组:
* 数组的坐标为皇后所在的行数
* 数组上的值为皇后所在的列数

假设数组上的值各不相同, 则该数组可看作`[0, n-1]`的全排列, 但排列组合还需要保证每个元素的`i + arr[i]`和`i - arr[i]`各不相同(对角线).
```java
class Solution {
    private List<List<String>> res = new ArrayList<>();
    
    public List<List<String>> solveNQueens(int n) {
        int[] arr = new int[n];
        backtracking(arr, 0, new boolean[n], new boolean[n*2], new boolean[n*2]);
        return res;
    }

    private void backtracking(int[] arr, int i, boolean[] cols, boolean[] diag1, boolean[] diag2) {
        if (i == arr.length) {
            List<String> rows = new ArrayList<>();
            for (int j = 0; j < arr.length; j++) {
                rows.add(new StringBuilder(".".repeat(arr[j])).append("Q").append(".".repeat(arr.length-1-arr[j])).toString());
            }
            res.add(rows);
            return;
        }
        for (int j = 0; j < arr.length; j++) {
            if (cols[j] || diag1[i+j] || diag2[i-j+arr.length]) continue;
            cols[j] = diag1[i+j] = diag2[i-j+arr.length] = true;
            arr[i] = j;
            backtracking(arr, i+1, cols, diag1, diag2);
            cols[j] = diag1[i+j] = diag2[i-j+arr.length] = false;
        }
    }
}
```
