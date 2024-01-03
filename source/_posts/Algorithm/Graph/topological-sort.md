---
title: Topological Sort
abbrlink: 285f
date: 2023-03-11 18:10:16
category:
  - Algorithm
  - Graph
tag:
  - Algorithm
keywords:
description:
---

## 207. Course Schedule
There are a total of `numCourses` courses you have to take, labeled from `0` to `numCourses - 1`. You are given an array prerequisites where `$\text{prerequisites}[i] = [a_i, b_i]$` indicates that you must take course `$b_i$` first if you want to take course `$a_i$`.

For example, the pair `[0, 1]`, indicates that to take course `0` you have to first take course `1`.
Return `true` if you can finish all courses. Otherwise, return `false`.

Example 1:
```
Input: numCourses = 2, prerequisites = [[1,0]]
Output: true
Explanation: There are a total of 2 courses to take.
To take course 1 you should have finished course 0. So it is possible.
```

### Kahn's algorithm
Topological sort用于在DAG(Directed Acyclic Graph, 有向无环图)中对每个vertex排序. 例如, graph中的vertex表示需要执行的任务, edge表示一个任务依赖另一个任务的结果, 若graph为DAG, 则topological sort可提供一种合理的任务执行顺序; 但若graph中存在circle, 则无法排序. 一个DAG至少存在一种排序方式.
Kahn算法是最经典的topological sort算法, 思路如下:
* 将所有**indegree**(入度, 指向该vertex的edge数)为0的vertex放入queue
* 不断取出queue元素, 直至queue为空
    * 取出一个vertex(`v1`), 将`v1`放入执行序列`list`中
    * 遍历`v1`指向的vertex(`v2`), 将`v2`的indegree - 1
    * 若`v2`的indegree为0, 将`v2`放入queue
* queue为空时, 若`list`包含所有vertex, 说明图中无环, `list`即为一个topologically sorted order

该算法的时间复杂度为`$O(v + e)$`(v为vertex数, e为edge数)
```java
class Solution {
    public boolean canFinish(int numCourses, int[][] prerequisites) {
        List<Integer>[] nodes = new List[numCourses];
        for (int i = 0; i < numCourses; i++) {
            nodes[i] = new ArrayList<>();
        }
        int[] indegrees = new int[numCourses];
        for (int[] p: prerequisites) {
            if (p[0] == p[1]) return false;
            indegrees[p[0]]++;
            nodes[p[1]].add(p[0]);
        }
        Queue<Integer> q = new LinkedList<>();
        for (int i = 0; i < numCourses; i++) {
            if (indegrees[i] == 0) {
                q.offer(i);
            }
        }
        int cnt = 0;
        while (!q.isEmpty()) {
            int i = q.poll();
            for (int j: nodes[i]) {
                if (--indegrees[j] == 0) {
                    q.offer(j);
                }
            }
            cnt++;
        }
        return cnt == numCourses;
    }
}
```


## 329. Longest Increasing Path in a Matrix
Given an `m x n` integers `matrix`, return the length of the longest increasing path in `matrix`.

From each cell, you can either move in four directions: left, right, up, or down. You **may not** move **diagonally** or move **outside the boundary** (i.e., wrap-around is not allowed).

Example 1:
```
Input: matrix = [[9,9,4],[6,6,8],[2,1,1]]
Output: 4
Explanation: The longest increasing path is [1, 2, 6, 9].
```

### Kahn's algorithm
每个格子的最长递增路径只与周围四格的数值和路径长度有关, 假设当前格子的数值(`matrix[i][j]`)大于其他格子(`matrix[x][y]`), 则`path[i][j] = max(path[x][y] + 1), (x,y)与(i,j)相邻`.

将matrix中的格子想象成vertex, 将数值的增长作为edge 整个matrix可看作一个DAG. 若多个节点可能指向同一中间节点, 则中间节点应选取相邻节点的最长路径, indegree为0的节点路径为1, 向数值更高的节点不断推进即可得到最长递增路径.
```java
class Solution {
    public int longestIncreasingPath(int[][] matrix) {
        int m = matrix.length, n = matrix[0].length;
        List<Integer>[] edges = new List[m * n];
        for (int i = 0; i < m * n; i++) {
            edges[i] = new ArrayList<>();
        }
        int[] indegrees = new int[m * n];
        int[][] dirs = {{0,1}, {1,0}, {0,-1}, {-1,0}};
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                for (int[] dir: dirs) {
                    int x = i + dir[0], y = j + dir[1];
                    if (x < 0 || x >= m || y < 0 || y >= n || matrix[x][y] <= matrix[i][j]) continue;
                    indegrees[x * n + y]++;
                    edges[i * n + j].add(x * n + y);
                }
            }
        }
        Queue<int[]> q = new LinkedList<>();
        for (int i = 0; i < m * n; i++) {
            if (indegrees[i] == 0) q.offer(new int[]{i, 1});
        }
        int[] path = new int[m * n];
        int res = 0;
        while (!q.isEmpty()) {
            int[] t = q.poll();
            res = Math.max(res, t[1]);
            for (int j: edges[t[0]]) {
                if (--indegrees[j] == 0) {
                    path[j] = Math.max(path[j], t[1]+1);
                    q.offer(new int[]{j, path[j]});
                }
            }
        }
        return res;
    }
}
```


## 1632. Rank Transform of a Matrix
Given an `m x n` matrix, return a new matrix `answer` where `answer[row][col]` is the **rank** of `matrix[row][col]`.

The **rank** is an **integer** that represents how large an element is compared to other elements. It is calculated using the following rules:
* The rank is an integer starting from 1.
* If two elements p and q are in the **same row or column**, then:
    * If `p < q` then `rank(p) < rank(q)`
    * If `p == q` then `rank(p) == rank(q)`
    * If `p > q` then `rank(p) > rank(q)`
* The **rank** should be as **small** as possible.

Example 1:
```
Input: matrix = [[1,2],[3,4]]
Output: [[1,2],[2,3]]
Explanation:
The rank of matrix[0][0] is 1 because it is the smallest integer in its row and column.
The rank of matrix[0][1] is 2 because matrix[0][1] > matrix[0][0] and matrix[0][0] is rank 1.
The rank of matrix[1][0] is 2 because matrix[1][0] > matrix[0][0] and matrix[0][0] is rank 1.
The rank of matrix[1][1] is 3 because matrix[1][1] > matrix[0][1], matrix[1][1] > matrix[1][0], and both matrix[0][1] and matrix[1][0] are rank 2.
```

### Kahn's algorithm + union find
对于第i行, 第j列的数字`m[i][j]`, 其需和同行/同列的其他数字比较: 假设第i行有m个数字比`m[i][j]`小, 第j列上有n个数字比`m[i][j]`小, 则该数字的rank至少为`max(m, n) + 1`; 若同行或同列中出现相同值的数字, 则这两个数字必须拥有相同rank值, 这导致即便两个数字不同行也不同列, 也可能拥有相同的rank值(`m[i][j] == m[k][j] == m[k][t]`). 因此题目可拆分为两个问题:
* 若同行或同列中的数字数值不同, 如何分配rank值
* 若同行或同列中的数字数值相同, 如何保证rank值相同

以行为例, 假设一行中存在n个数字(不存在相同数值), 对其排序后可获得一个递增数组, 将每个数字想象为一个节点, 数值偏小的节点指向数值更大的节点, 从而形成一个DAG. 对每一列执行相同操作后, 整个图会存在一些节点的**indegree**为0, 表示该节点在同行同列中的数值最小, 因此其rank值最低(`1`), 再使用topological sort为不同大小的数字分配rank值. 对于同行或同列上数值相同的数字, 可使用union find, 将数值相同的数字放入一个集合, 之后分配rank值时统一处理.

```java
class Solution {
    private int[] parents, ranks;

    public int[][] matrixRankTransform(int[][] matrix) {
        int m = matrix.length, n = matrix[0].length;
        parents = new int[m*n];
        ranks = new int[m*n];
        for (int i = 1; i < m*n; i++) {
            parents[i] = i;
        }
        // store the same value in one row into subset
        for (int i = 0; i < m; i++) {
            Map<Integer, List<Integer>> map = new HashMap<>();
            for (int j = 0; j < n; j++) {
                map.putIfAbsent(matrix[i][j], new ArrayList<>());
                map.get(matrix[i][j]).add(i*n+j);
            }
            for (List<Integer> arr: map.values()) {
                for (int k = 1; k < arr.size(); k++) {
                    union(arr.get(k-1), arr.get(k));
                }
            }
        }
        // store the same value in one column into subset
        for (int j = 0; j < n; j++) {
            Map<Integer, List<Integer>> map = new HashMap<>();
            for (int i = 0; i < m; i++) {
                map.putIfAbsent(matrix[i][j], new ArrayList<>());
                map.get(matrix[i][j]).add(i*n+j);
            }
            for (List<Integer> arr: map.values()) {
                for (int k = 1; k < arr.size(); k++) {
                    union(arr.get(k-1), arr.get(k));
                }
            }
        }
        int[] indegrees = new int[m * n];
        List<Integer>[] edges = new List[m * n];
        for (int i = 0; i < m*n; i++) {
            edges[i] = new ArrayList<>();
        }
        // connect sorted numbers in one row
        for (int i = 0; i < m; i++) {
            int[][] arr = new int[n][2];
            for (int j = 0; j < n; j++) {
                arr[j][0] = matrix[i][j];
                arr[j][1] = j;
            }
            Arrays.sort(arr, (a,b) -> a[0] - b[0]);
            for (int j = 1; j < n; j++) {
                if (arr[j-1][0] == arr[j][0]) continue;
                int p1 = find(i * n + arr[j-1][1]), p2 = find(i * n + arr[j][1]);
                edges[p1].add(p2);
                indegrees[p2]++;
            }
        }
        // connect sorted numbers in one column
        for (int j = 0; j < n; j++) {
            int[][] arr = new int[m][2];
            for (int i = 0; i < m; i++) {
                arr[i][0] = matrix[i][j];
                arr[i][1] = i;
            }
            Arrays.sort(arr, (a,b) -> a[0] - b[0]);
            for (int i = 1; i < m; i++) {
                if (arr[i-1][0] == arr[i][0]) continue;
                int p1 = find(arr[i-1][1] * n + j), p2 = find(arr[i][1] * n + j);
                edges[p1].add(p2);
                indegrees[p2]++;
            }
        }
        // topological sort
        Queue<Integer> q = new LinkedList<>();
        for (int i = 0; i < m*n; i++) {
            if (i == find(i) && indegrees[i] == 0) {
                q.offer(i);
            }
        }
        Arrays.fill(ranks, 1);
        while (!q.isEmpty()) {
            int i = q.poll();
            for (int j: edges[i]) {
                ranks[j] = Math.max(ranks[j], ranks[i]+1);
                if (--indegrees[j] == 0) q.offer(j);
            }
        }
        // fill rank
        int[][] ans = new int[m][n];
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                ans[i][j] = ranks[find(i * n + j)];
            }
        }
        return ans;
    }

    private int find(int i) {
        if (parents[i] != i) parents[i] = find(parents[i]);
        return parents[i];
    }

    private void union(int i, int j) {
        i = find(i);
        j = find(j);
        if (i == j) return;
        if (ranks[i] <= ranks[j]) {
            parents[i] = j;
            if (ranks[i] == ranks[j]) ranks[j]++;
        } else {
            parents[j] = i;
        }
    }
}
```


## 2246. Longest Path With Different Adjacent Characters
 You are given a **tree** (i.e. a connected, undirected graph that has no cycles) **rooted** at node `0` consisting of `n` nodes numbered from `0` to `n - 1`. The tree is represented by a **0-indexed** array `parent` of size `n`, where `parent[i]` is the parent of node `i`. Since node `0` is the root, `parent[0] == -1`.

You are also given a string `s `of length `n`, where `s[i]` is the character assigned to node `i`.

Return the length of the **longest path** in the tree such that no pair of **adjacent** nodes on the path have the same character assigned to them.

Example 1:
```
Input: parent = [-1,0,0,1,1,2], s = "abacbe"
Output: 3
Explanation: The longest path where each two adjacent nodes have different characters in the tree is the path: 0 -> 1 -> 3. The length of this path is 3, so 3 is returned.
It can be proven that there is no longer path that satisfies the conditions.
```

### Kahn's algorithm
题目要求找到树上一条最长路径, 路径上的相邻字符不能重复, 该题目类似于tree的最大路径和: 对于当前节点`node`, 其存在`n`个子节点(`$\text{child}_1, \text{child}_2, \cdots, \text{child}_{n-1}, \text{child}_n$`), 对于每个子节点, 存在两种情况:
* 若`node`上的字符与`$\text{child}_i$`相同: 不考虑该子树
* 若`node`上的字符与`$\text{child}_i$`不同: 记录该子树的最长路径长度

对于一个节点来说, 最长路径值为`1 + 子树的最长路径 + 子树的第二长路径`, 因此不必记录每个子树的长度, 只需记录前两名的长度. 使用topological sort可避免访问一个节点多次, 因为没有访问一个节点的所有子树之前, 我们不能处理该节点; 当所有子树处理完毕时, 其父节点的indegree应为0.
```java
class Solution {
    public int longestPath(int[] parent, String s) {
        int n = s.length(), res = 0;
        int[][] path = new int[n][2];
        int[] indegrees = new int[n];
        for (int i = 0; i < n; i++) {
            if (parent[i] < 0) continue;
            indegrees[parent[i]]++;
        }
        Queue<Integer> q = new LinkedList<>();
        for (int i = 0; i < n; i++) {
            if (indegrees[i] == 0) {
                q.offer(i);
            }
        }
        while (!q.isEmpty()) {
            int i = q.poll(), j = parent[i];
            res = Math.max(res, 1 + path[i][0] + path[i][1]); // longest path for current node
            if (j == -1) continue;
            if (--indegrees[j] == 0) {
                q.offer(j);
            }
            if (s.charAt(i) == s.charAt(j)) continue;
            int p = 1 + Math.max(path[i][0], path[i][1]); // longest path for parent node
            if (p > path[j][0]) { // update longest path
                path[j][1] = path[j][0];
                path[j][0] = p;
            } else if (p > path[j][1]) { // update second longest path
                path[j][1] = p;
            }
        }
        return res;
    }
}
```


## 2127. Maximum Employees to Be Invited to a Meeting
A company is organizing a meeting and has a list of n employees, waiting to be invited. They have arranged for a large **circular** table, capable of seating **any number** of employees.

The employees are numbered from `0` to `n - 1`. Each employee has a **favorite** person and they will attend the meeting **only if** they can sit next to their favorite person at the table. The favorite person of an employee is **not** themself.

Given a **0-indexed** integer array `favorite`, where `favorite[i]` denotes the favorite person of the `$i^{th}$` employee, return the **maximum number of employees** that can be invited to the meeting.

Example 1:
```
Input: favorite = [2,2,1,2]
Output: 3
Explanation:
The above figure shows how the company can invite employees 0, 1, and 2, and seat them at the round table.
All employees cannot be invited because employee 2 cannot sit beside employees 0, 1, and 3, simultaneously.
Note that the company can also invite employees 1, 2, and 3, and give them their desired seats.
The maximum number of employees that can be invited to the meeting is 3.
```

### Kahn's algorithm + Pseudoforest
把每个员工想象为vertex, 员工之间的喜爱就是edge, 例如, `$\text{favorite}[v_1] = v_2$`, 则`$v_1$`指向`$v_2$`, 由于每个人必须有一个喜爱的人, 且不能指定自己为喜爱的人, 因此graph存在以下特性:
* 图中必存在一个或多个circle(环).
* 非circle上的vertex会指向circle上的vertex
* 任意两个circle不存在交集: 若两个circle共享一个vertex, 则该vertex的outdegree为2, 但一个员工只能有一个喜爱的人, 因此不可能存在.

由于是圆桌会议, 因此一个人身边只能坐两个人. 假设多个vertex指向同一vertex, 该vertex只能选择一个人坐在其身边(另一边要坐喜爱的人). 根据vertex的位置, 可将vertex分为两类:
* circleVertex: circle上的vertex
* branchVertex: 不构成circle, 但直接或间接指向circle上的vertex

circle的数量也会导致排座方案不同:
* circleVertex的数量为2: 假设$v_1$指向$v_2$, $v_2$指向$v_1$, 则$v_1$和$v_2$可坐在一起, $v_1$的另一侧可坐指向$v_1$的branchVertex, $v_2$同理
* circleVertex的数量大于2: circleVertex的左右两端已坐满人(员工喜爱的人, 喜爱该员工的人), 由于无法移除任何一个circleVertex(只要移除其中一个, 指向该节点的节点就无法参与会议, 导致所有circleVertex都不能参加会议), 因此只能移除所有branchVertex

因此, 会议的排座方案有两种, 两者取最大值即为结果:
* 全部由circleVertex数量为2的circle组成, 每个circleVertex都可以携带一个最长的branchVertex
* 由一个circleVertex数量大于2的circle组成, 但每个circleVertex必须移除所有branchVertex

代码方面: 先使用topological sort计算每个circleVertex上的branchVert的数量, 再遍历每个circle, 计算circleVertex数量.

```java
class Solution {
    public int maximumInvitations(int[] favorite) {
        int n = favorite.length;
        int[] indegrees = new int[n], branch = new int[n];
        for (int i = 0; i < n; i++) {
            indegrees[favorite[i]]++; 
        }
        Queue<Integer> q = new LinkedList<>();
        for (int i = 0; i < n; i++) {
            if (indegrees[i] == 0) {
                q.offer(i);
            }
        }
        int cnt = 0, c1 = 0, c2 = 0;
        while (!q.isEmpty()) {
            int i = q.poll(), j = favorite[i];
            cnt++;
            if (--indegrees[j] == 0) {
                q.offer(j);
            }
            branch[j] = Math.max(branch[j], 1 + branch[i]);
        }
        while (cnt < n) {
            int i = 0, nodeOnBranch = 0, nodeOnCircle = 0;
            while (indegrees[i] == 0) i++;
            while (indegrees[i] > 0) {
                nodeOnCircle++;
                cnt++;
                nodeOnBranch += branch[i];
                --indegrees[i];
                i = favorite[i];
            }
            if (nodeOnCircle > 2) {
                c1 = Math.max(c1, nodeOnCircle);
            } else {
                c2 += nodeOnCircle + nodeOnBranch;
            }
        }
        return Math.max(c1, c2);
    }
}
```
