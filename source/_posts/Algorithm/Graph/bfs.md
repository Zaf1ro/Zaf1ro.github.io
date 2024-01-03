---
title: BFS for Graph
abbrlink: 9bcb
date: 2023-03-06 11:58:37
category:
  - Algorithm
  - Graph
tag:
  - Algorithm
keywords:
description:
---

## 542. 01 Matrix
Given an `m x n` binary matrix `mat`, return the distance of the nearest `0` for each cell.
The distance between two adjacent cells is `1`.

Example 1:
```
Input: mat = [[0,0,0],[0,1,0],[0,0,0]]
Output: [[0,0,0],[0,1,0],[0,0,0]]
```

Example 2:
```
Input: mat = [[0,0,0],[0,1,0],[1,1,1]]
Output: [[0,0,0],[0,1,0],[1,2,1]]
```

### 1. Solution
从每个值为0的格子出发, BFS扫描整个matrix, 并更新距离. 单次扫描matrix的时间复杂度为`O(mn)`(m为matrix的行数, n为matrix的列数), 因此该算法的时间复杂度为`O(mn * mn)`.
```java
class Solution {
    class Node {
        public int x;
        public int y;
        public int dist;
        public Node(int x, int y, int dist) {
            this.x = x;
            this.y = y;
            this.dist = dist;
        }
    }

    private int[][] dirs = {{0,1}, {1,0}, {0,-1}, {-1,0}};

    public int[][] updateMatrix(int[][] mat) {
        int m = mat.length, n = mat[0].length;
        int[][] res = new int[m][n];
        for (int i = 0; i < m; i++) {
            Arrays.fill(res[i], Integer.MAX_VALUE);
        }
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                if (mat[i][j] == 0) bfs(mat, res, i, j, m, n);
            }
        }
        return res;
    }

    private void bfs(int[][] mat, int[][] res, int i, int j, int m, int n) {
        res[i][j] = 0;
        Queue<Node> q = new LinkedList<>();
        q.offer(new Node(i, j, 0));
        while (!q.isEmpty()) {
            Node node = q.poll();
            for (int[] dir: dirs) {
                int x = node.x+dir[0], y = node.y+dir[1], d = node.dist+1;
                if (x < 0 || x >= m || y < 0 || y >= n || d >= res[x][y]) continue;
                res[x][y] = d;
                q.offer(new Node(x, y, d));
            }
        }
    }
}
```

### 2. Solution 2
方法1的核心思路是从每个0出发, 遍历整个表, 若整个表大部分为0, 则会不断更新0上的距离值, 从而导致时间复杂度偏高; 可将所有值为0的格子放入queue, 不断逼近1所在的格子, 可避免重复访问值为0的格子, 时间复杂度为`O(mn)`.
```java
class Solution {
    class Node {
        public int x;
        public int y;
        public Node(int x, int y) {
            this.x = x;
            this.y = y;
        }
    }

    private int[][] dirs = {{0,1}, {1,0}, {0,-1}, {-1,0}};

    public int[][] updateMatrix(int[][] mat) {
        int m = mat.length, n = mat[0].length;
        int[][] res = new int[m][n];
        boolean[][] visited = new boolean[m][n];
        Queue<Node> q = new LinkedList<>();
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                if (mat[i][j] == 0) q.offer(new Node(i, j)); // add all 
            }
        }
        int dist = 1;
        while (!q.isEmpty()) {
            int size = q.size();
            while (size-- > 0) {
                Node node = q.poll();
                for (int[] dir: dirs) {
                    int x = node.x + dir[0], y = node.y + dir[1];
                    if (x < 0 || x >= m || y < 0 || y >= n || visited[x][y]) continue;
                    if (mat[x][y] == 1) res[x][y] = dist; // set value at the first time, must be the shortest distance
                    visited[x][y] = true;
                    q.offer(new Node(x, y));
                }
            }
            ++dist; // increase distance for each circle
        }
        return res;
    }
}
```


## 934. Shortest Bridge
You are given an `n x n` binary matrix `grid` where `1` represents land and `0` represents water.
An island is a 4-directionally connected group of `1`'s not connected to any other `1`'s. There are **exactly two islands** in `grid`.
You may change `0`'s to `1`'s to connect the two islands to form one island.
Return the smallest number of `0`'s you must flip to connect the two islands.

### 1. Solution
与上题相同, 先将第一个岛屿的所有格子加入queue, 再BFS搜索第二个岛屿, 返回首次抵达第二个岛屿的距离.
```java
class Solution {
    class Node {
        public int x, y;
        public Node(int x, int y) {
            this.x = x;
            this.y = y;
        }
    }

    private int[][] dirs = {{1,0}, {0,1}, {-1,0}, {0,-1}};

    public int shortestBridge(int[][] grid) {
        int m = grid.length, n = grid[0].length;
        Queue<Node> q = new LinkedList<>();
        boolean[][] visited = new boolean[m][n];
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                if (grid[i][j] == 0) continue;
                dfs(grid, visited, q, i, j, m, n);
                i = m;
                j = n;
            }
        }
        int res = 0;
        while (!q.isEmpty()) {
            int size = q.size();
            while (size-- > 0) {
                Node node = q.poll();
                for (int[] dir: dirs) {
                    int x = node.x + dir[0], y = node.y + dir[1];
                    if (x < 0 || x >= m || y < 0 || y >= n || visited[x][y]) continue;
                    if (grid[x][y] == 1) return res;
                    visited[x][y] = true;
                    q.offer(new Node(x, y));
                }
            }
            res++;
        }
        return -1;
    }

    private void dfs(int[][] grid, boolean[][] visited, Queue<Node> q, int i, int j, int m, int n) {
        if (i < 0 || i >= m || j < 0 || j >= n || visited[i][j] || grid[i][j] == 0) return;
        q.offer(new Node(i, j));
        visited[i][j] = true;
        for (int[] dir: dirs) {
            dfs(grid, visited, q, i+dir[0], j+dir[1], m, n);
        }
    }
}
```


## 127. Word Ladder
A **transformation sequence** from word beginWord to word endWord using a dictionary wordList is a sequence of words $\text{beginWord} \rightarrow s_1 \rightarrow s_2 \rightarrow \cdots \rightarrow s_k$ such that:
* Every adjacent pair of words differs by a single letter.
* Every $s_i$ for $1 \le i \le k$ is in `wordList`. Note that `beginWord` does not need to be in `wordList`.
* $s_k == \text{endWord}$

Given two words, `beginWord` and `endWord`, and a dictionary `wordList`, return the **number of words** in the **shortest transformation sequence** from `beginWord` to `endWord`, or `0` if no such sequence exists.

Example 1:
```
Input: beginWord = "hit", endWord = "cog", wordList = ["hot","dot","dog","lot","log","cog"]
Output: 5
Explanation: One shortest transformation sequence is "hit" -> "hot" -> "dot" -> "dog" -> cog", which is 5 words long.
```

Example 2:
```
Input: beginWord = "hit", endWord = "cog", wordList = ["hot","dot","dog","lot","log"]
Output: 0
Explanation: The endWord "cog" is not in wordList, therefore there is no valid transformation sequence.
```

### 1. Solution
将每个单词看作graph中的node, 则**one letter change**为node间的edge. 先建立graph, 从beginWord出发, BFS搜索endWord. 算法复杂度为`$O(n^2 * c)$`(n为单词个数, c为一个单词的长度).
```java
class Solution {
    public int ladderLength(String beginWord, String endWord, List<String> wordList) {
        if (!wordList.contains(endWord)) return 0;
        // construct graph
        wordList.add(beginWord);
        Map<String, List<String>> map = new HashMap<>();
        for (String word: wordList) {
            map.put(word, new ArrayList<>());
        }
        for (int i = 0; i < wordList.size(); i++) {
            for (int j = i+1; j < wordList.size(); j++) {
                String s1 = wordList.get(i), s2 = wordList.get(j);
                if (isOneLetterChange(s1, s2)) {
                    map.get(s1).add(s2);
                    map.get(s2).add(s1);
                }
            }
        }
        // bfs
        Set<String> visited = new HashSet<>();
        Queue<String> q = new LinkedList<>();
        q.offer(beginWord);
        visited.add(beginWord);
        int res = 1;
        while (!q.isEmpty()) {
            int size = q.size();
            ++res;
            while (size-- > 0) {
                String s = q.poll();
                List<String> arr = map.get(s);
                if (arr == null) continue;
                for (String t: arr) {
                    if (visited.contains(t)) continue;
                    if (t.equals(endWord)) return res;
                    q.offer(t);
                    visited.add(t);
                }
            }
        }
        return 0;
    }

    private boolean isOneLetterChange(String s1, String s2) {
        int res = 0;
        for (int i = 0; i < s1.length(); i++) {
            if (s1.charAt(i) != s2.charAt(i)) res++;
        }
        return res == 1;
    }
}
```

### 2. Solution
上述解法需两两对比wordList中的单词, 因此时间复杂度为$O(n^2)$级别, 可换一种思路: 将一个单词的每个字母替换为一个通用字符, 如`abc`, 可生成`*bc`, `a*c`, `ab*`三个单词, 可将这三个单词看作graph中`abc`节点的edge, 若两个单词相差一个字符, 则会共享一个edge, 从而避免两两对比字符串. 算法的时间复杂度为`$O(n * c)$`.
```java
class Solution {
    private Map<String, Integer> map = new HashMap<>();
    private int idx = 0;
    private List<List<Integer>> edges = new ArrayList<>();

    public int ladderLength(String beginWord, String endWord, List<String> wordList) {
        // connect all words
        addEdge(beginWord);
        for (String word: wordList) {
            addEdge(word);
        }
        if (!map.containsKey(endWord)) return 0;
        // bfs
        int res = 0, begin = map.get(beginWord), end = map.get(endWord);
        Queue<Integer> q = new LinkedList<>();
        q.offer(begin);
        Set<Integer> visited = new HashSet<>();
        visited.add(begin);
        while (!q.isEmpty()) {
            int size = q.size();
            ++res;
            while (size-- > 0) {
                int i = q.poll();
                List<Integer> arr = edges.get(i);
                for (int next: arr) {
                    if (next == end) return res / 2 + 1;
                    if (visited.contains(next)) continue;
                    visited.add(next);
                    q.offer(next);
                }
            }
        }
        return 0;
    }

    // create all edges
    private void addEdge(String word) {
        char[] arr = word.toCharArray();
        for (int i = 0; i < arr.length; i++) {
            arr[i] = '*';
            connect(word, new String(arr));
            arr[i] = word.charAt(i);
        }
    }

    // connect node and edge
    private void connect(String w1, String w2) {
        int i1 = getWordIdx(w1), i2 = getWordIdx(w2);
        edges.get(i1).add(i2);
        edges.get(i2).add(i1);
    }

    // get index of node/edge in this.edges
    private int getWordIdx(String word) {
        if (!map.containsKey(word)) {
            int res = idx;
            map.put(word, idx++);
            edges.add(new ArrayList<>());
            return res;
        }
        return map.get(word);
    }
}
```


## 854. K-Similar Strings
Strings `s1` and `s2` are **k-similar**(for some non-negative integer `k`) if we can swap the positions of two letters in `s1` exactly `k` times so that the resulting string equals `s2`.

Given two anagrams `s1` and `s2`, return the smallest `k` for which `s1` and `s2` are **k-similar**.

Example 1:
```
Input: s1 = "ab", s2 = "ba"
Output: 1
Explanation: The two string are 1-similar because we can use one swap to change s1 to s2: "ab" --> "ba".
```

Example 2:
```
Input: s1 = "abc", s2 = "bca"
Output: 2
Explanation: The two strings are 2-similar because we can use two swaps to change s1 to s2: "abc" --> "bac" --> "bca".
```

### 1. Solution
将`s1`看作graph的起始node, 其permutation为相邻节点, 如`abc`, 其permutation为`bac`
, `cba`, `acb`. 从`s1`出发, BFS拓展整个graph, 直到抵达`s2`. 算法的时间复杂度为`$O(n^n)$`
```java
class Solution {
    private Queue<String> q = new LinkedList<>();
    private Set<String> visited = new HashSet<>();

    public int kSimilarity(String s1, String s2) {
        q.offer(s1);
        visited.add(s1);
        int res = 0;
        while (!q.isEmpty()) {
            int size = q.size();
            while (size-- > 0) {
                String word = q.poll();
                if (word.equals(s2)) return res;
                visited.add(word);
                getPermutation(word.toCharArray());
            }
            ++res;
        }
        return res;
    }

    private void getPermutation(char[] s) {
        for (int i = 0; i < s.length; i++) {
            for (int j = i+1; j < s.length; j++) {
                swap(s, i, j);
                String word = new String(s);
                if (!visited.contains(word)) {
                    q.offer(word);
                }
                swap(s, i, j);
            }
        }
    }

    private void swap(char[] arr, int i, int j) {
        char c = arr[i];
        arr[i] = arr[j];
        arr[j] = c;
    }
}
```

### 2. Solution
上述算法的时间复杂度过高, 因为其中包含大量不必要的swap: 若`s1`与`s2`在`i`位置不同, 则必定需要一次swap, 若相同, 则一定不需要swap, 因此, 生成s1的permutation时, 可跳过所有`s1[i] == s2[i]`的情况; 若`s1[i] != s2[i]`, 则从`s1`的`[i+1 ...)`范围上寻找与`s2[i]`相同的字符并交换. 算法的时间复杂度为`$O(n^2)`.
```java
class Solution {
    class Node {
        public String word;
        public int pos;
        public Node(String word, int pos) {
            this.word = word;
            this.pos = pos;
        }
    }
    
    public int kSimilarity(String s1, String s2) {
        Queue<Node> q = new LinkedList<>();
        q.offer(new Node(s1, 0));
        Set<String> visited = new HashSet<>();
        visited.add(s1);
        int res = 0;
        while (!q.isEmpty()) {
            int size = q.size();
            while (size-- > 0) {
                Node node = q.poll();
                String word = node.word;
                int pos = node.pos;
                if (word.equals(s2)) return res;
                while (pos < word.length() && word.charAt(pos) == s2.charAt(pos)) pos++;
                char[] arr = word.toCharArray();
                for (int i = pos + 1; i < arr.length; i++) {
                    if (arr[i] == s2.charAt(i)) continue;
                    if (arr[i] == s2.charAt(pos)) {
                        swap(arr, pos, i);
                        String w = new String(arr);
                        if (!visited.contains(w)) {
                            q.offer(new Node(w, pos+1));
                            visited.add(w);
                        }
                        swap(arr, pos, i);
                    }
                }
            }
            ++res;
        }
        return res;
    }

    private void swap(char[] arr, int i, int j) {
        char c = arr[i];
        arr[i] = arr[j];
        arr[j] = c;
    }
}
```


## 301. Remove Invalid Parentheses
Given a string `s` that contains parentheses and letters, remove the minimum number of invalid parentheses to make the input string valid.

Return a list of unique strings that are valid with the minimum number of removals. You may return the answer in any order.

Example 1:
```
Input: s = "()())()"
Output: ["(())()","()()()"]
```

Example 2:
```
Input: s = "(a)())()"
Output: ["(a())()","(a)()()"]
```

Example 3:
```
Input: s = ")("
Output: [""]
```

### Solution
题目要求最少删除次数, 因此可使用BFS依次删除一个字符, 当出现合法字符串时, 说明可以停止删除操作. 删除字符时需注意两点:
* 不要删除除`(`, `)`外的其他字符
* 若两个相同字符相邻, 删除第一个字符或第二个字符会产生相同字符串, 因此可跳过以加速算法

```java
class Solution {
    public List<String> removeInvalidParentheses(String s) {
        List<String> res = new ArrayList<>();
        Set<String> set = new HashSet<>();
        set.add(s);
        while (!set.isEmpty()) {
            Set<String> next = new HashSet<>();
            for (String s1: set) {
                if (isValid(s1)) {
                    res.add(s1);
                    continue;
                }
                for (int i = 0; i < s1.length(); i++) {
                    if (i > 0 && s1.charAt(i-1) == s.charAt(i)) continue;
                    if (s1.charAt(i) != '(' && s1.charAt(i) != ')') continue;
                    next.add(s1.substring(0, i) + s1.substring(i+1));
                }
            }
            if (!res.isEmpty()) break;
            set = next;
        }
        return res;
    }

    private boolean isValid(String s) {
        int cnt = 0;
        for (int i = 0; i < s.length(); i++) {
            if (s.charAt(i) == '(') {
                cnt++;
            } else if (s.charAt(i) == ')') {
                cnt--;
            }
            if (cnt < 0) return false;
        }
        return cnt == 0;
    }
}
```
