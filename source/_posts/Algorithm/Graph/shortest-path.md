---
title: Shortest Path in Graph
abbrlink: c8ae
date: 2023-03-09 14:49:10
category:
  - Algorithm
  - Graph
tag:
  - Algorithm
keywords:
description:
---

## 1. Introduction
图(graph)是一个二元集$G = (V(G), E(G))$, 其中$V(G)$称为vertex set(点集), $E(G)$为$V(G)$中各个节点之间的边的集合, 称为edge set(边集). 若G的每条边都可被赋予一个数, 称为weight(权).
最短路径算法用于找到图中两点之间的最短路. 假设图中`n`为点的数量, `m`为边的数量, 对于边权为正的图, 一条最短路径拥有以下属性:
* 任意两点之间的最短路径不会经过重复节点
* 任意两点之间的最短路径不会经过重复边
* 任意两点之间的最短路径上的点数不会超过`n`, 边数不会超过`n-1`
* 任意两点之间的最短路径的子路径仍为最短路径: 假设a到e的最短路径为`a->b->c->d->e`, 则a到c的最短路径一定为`a->b->c`; 反过来说, 若i到j的最短路径经过节点k, 则`i到j的最短路径`等同于`i到k的最短路径`加上`k到j的最短路径`

### 1.1 Dijkstra's algorithm
Dijkstra算法用于在graph中寻找一个node到其他node的最短路径, 从而生成**shortest-path tree**(最小路径树). 算法步骤如下:
1. 创建一个集合`set`, 用于保存所有已访问的node
2. 创建一个表`table`, 表示从起始点`source`到其他node的距离, `source`到自身的距离为0, `source`到其他node的距离为`$+\infty$`
3. 若`set`没有包含所有node, 则循环执行以下步骤:
    1. 从`table`取出一个点`node`, 其距离`source`最短, 且不包含在`set`中
    2. 将`node`加入`set`
    3. 遍历`node`的相邻边, 并更新相邻点到`source`的距离, 存在两种情况:
        * `node`到`source`的距离 + 相邻边的距离 < 相邻点到`source`的距离: 更新`table`中相邻点到`source`的距离
        * 反之不更新

Dijkstra算法每次将一个node加入set集合, 因此每个node至少处理一次, 且每次挑选最小距离的节点仍需扫描一遍, 因此算法时间复杂度为`$O(n^2)$`. 可使用最小堆优化时间复杂度, 每次取出最小距离节点, 或修改节点距离的时间复杂度为$O(\log{n})$, 因此算法时间复杂度为`$n\log{n}$` 需要注意的是, Dijkstra算法不支持负权重的边, 也不支持负权重的环.

### 1.2 Floyd-Warshall algorithm
Floyd算法用于计算图中任意两点的最短路径, 支持有向图和负权重的边. 假设`D(i,j,k)`表示从节点i到节点j的最短路径, 且该路径只经过`(1...k)`集合中的节点, 因此:
* 若i到j的最短路径经过k, 则`D(i,j,k) = D(i,k,k-1) + D(k,j,k-1)`
* 若i到j的最短路径不经过k, 则`D(i,j,k) = D(i,j,k-1)`

因此, `D(i,j,k) = min(D(i,k,k-1) + D(k,j,k-1), D(i,j,k-1))`. 可以发现, 该算法采用的是动态规划, 该公式即为动态规划中的状态转移方程. 假设点到点的距离矩阵为`dist`, 算法步骤如下:
1. 将每个节点到自己的距离设为0: `dist[i][i] = 0`
2. 将每个边的权重值写入矩阵: `dist[i][j] = w(i, j)`; 若两点之间没有直连边, 则设为$+\infty$
3. 计算经过k的最短路径: `dist[k][i][j] = min(dist[k-1][i][j], dist[k-1][i][k] + dist[k-1][k][j])`

可以看到, `D[0][i][j]`即为原图的邻接矩阵. 该算法的时间复杂度为`$O(n^3)$`, 空间复杂度为`$O(n^2)$`(n为点数).



## 743. Network Delay Time
You are given a network of `n` nodes, labeled from `1` to `n`. You are also given times, a list of travel times as directed edges `$\text{times}[i] = (u_i, v_i, w_i)$`, where `$u_i$` is the source node, `$v_i$` is the target node, and `$w_i$` is the time it takes for a signal to travel from source to target.

We will send a signal from a given node `k`. Return the **minimum** time it takes for all the `n` nodes to receive the signal. If it is impossible for all the `n` nodes to receive the signal, return `-1`.

Example 1:
```
Input: times = [[2,1,1],[2,3,1],[3,4,1]], n = 4, k = 2
Output: 2
```

Example 2:
```
Input: times = [[1,2,1]], n = 2, k = 2
Output: -1
```

### Dijkstra
```java
class Solution {
    class Edge {
        public Node from;
        public Node to;
        public int time;
        public Edge(Node from, Node to, int time) {
            this.from = from;
            this.to = to;
            this.time = time;
        }
    }

    class Node {
        public int id;
        public List<Edge> next;
        public int time;
        public Node(int id) {
            this.id = id;
            this.time = Integer.MAX_VALUE;
            next = new ArrayList<>();
        }
    }

    public int networkDelayTime(int[][] times, int n, int k) {
        Node[] nodes = new Node[n+1];
        for (int i = 1; i <= n; i++) {
            nodes[i] = new Node(i);
        }
        nodes[k].time = 0;
        for (int[] t: times) {
            nodes[t[0]].next.add(new Edge(nodes[t[0]], nodes[t[1]], t[2]));
        }
        Set<Node> visited = new HashSet<>();
        Node min = nodes[k];
        while (min != null) {
            for (Edge edge: min.next) {
                if (min.time + edge.time < edge.to.time) {
                    edge.to.time = min.time + edge.time;
                }
            }
            visited.add(min);
            min = getMinimumAndUnvisitedNode(nodes, visited);
        }
        int res = 0;
        for (int i = 1; i <= n; i++) {
            if (nodes[i].time == Integer.MAX_VALUE) return -1;
            res = Math.max(res, nodes[i].time);
        }
        return res;
    }

    private Node getMinimumAndUnvisitedNode(Node[] nodes, Set<Node> visited) {
        Node res = null;
        int time = Integer.MAX_VALUE;
        for (int i = 1; i < nodes.length; i++) {
            if (visited.contains(nodes[i])) continue;
            if (nodes[i].time < time) {
                res = nodes[i];
                time = nodes[i].time;
            }
        }
        return res;
    }
}
```


## 399. Evaluate Division
You are given an array of variable pairs `equations` and an array of real numbers `values`, where `equations[i] = [$A_i$, $B_i$]` and `values[i]` represent the equation `$A_i / B_i = \text{values}[i]$`. Each Ai or Bi is a string that represents a single variable.

You are also given some `queries`, where `$\text{queries}[j] = [C_j, D_j]$` represents the `$j^{th}$` query where you must find the answer for `$C_j$ / $D_j$ = ?`.

Return the answers to all queries. If a single answer cannot be determined, return `-1.0`.

Example 1:
```
Input: equations = [["a","b"],["b","c"]], values = [2.0,3.0], queries = [["a","c"],["b","a"],["a","e"],["a","a"],["x","x"]]
Output: [6.00000,0.50000,-1.00000,1.00000,-1.00000]
Explanation: 
Given: a / b = 2.0, b / c = 3.0
queries are: a / c = ?, b / a = ?, a / e = ?, a / a = ?, x / x = ?
return: [6.0, 0.5, -1.0, 1.0, -1.0 ]
```

### Floyd-Warshall algorithm
假设方程为`A / B = C`, 可令A和B为节点, C为两点间边的权重. 计算`$\text{node}_i / \text{node}_j$`时, 只需将`$\text{node}_i$`到`$\text{node}_j$`的最短路径上的权值相乘.
```java
class Solution {
    public double[] calcEquation(List<List<String>> equations, double[] values, List<List<String>> queries) {
        int len = 0, n = equations.size();
        Map<String, Integer> map = new HashMap<>();
        for (List<String> eq: equations) {
            map.putIfAbsent(eq.get(0), len++);
            map.putIfAbsent(eq.get(1), len++);
        }
        double[][] matrix = new double[len][len];
        for (double[] line: matrix) {
            Arrays.fill(line, Double.MAX_VALUE);
        }
        for (int i = 0; i < n; i++) {
            List<String> eq = equations.get(i);
            int a = map.get(eq.get(0)), b = map.get(eq.get(1));
            matrix[a][b] = values[i];
            matrix[b][a] = 1 / values[i];
        }
        for (int k = 0; k < len; k++) {
            for (int i = 0; i < len; i++) {
                for (int j = 0; j < len; j++) {
                    if (matrix[i][k] == Double.MAX_VALUE || matrix[k][j] == Double.MAX_VALUE) continue;
                    matrix[i][j] = matrix[i][k] * matrix[k][j];
                }
            }
        }
        double[] res = new double[queries.size()];
        for (int i = 0; i < res.length; i++) {
            String a = queries.get(i).get(0), b = queries.get(i).get(1);
            Integer x = map.get(a), y = map.get(b);
            res[i] = (x == null || y == null || matrix[x][y] == Double.MAX_VALUE) ? -1 : matrix[x][y];
        }
        return res;
    }
}
```


## 882. Reachable Nodes In Subdivided Graph
You are given an undirected graph (the **"original graph"**) with `n` nodes labeled from `0` to `n - 1`. You decide to **subdivide** each edge in the graph into a chain of nodes, with the number of new nodes varying between each edge.

The graph is given as a 2D array of `edges` where `$\text{edges}[i] = [u_i, v_i, {cnt}_i]$` indicates that there is an edge between nodes `$u_i$` and `$v_i$` in the original graph, and `${cnt}_i$` is the total number of new nodes that you will **subdivide** the edge into. Note that `${cnt}_i == 0$` means you will not subdivide the edge.

To **subdivide** the edge `[$u_i$, $v_i$]`, replace it with (`${cnt}_i + 1$`) new edges and `${cnt}_i$` new nodes. The new nodes are `$x_1$`, `$x_2$`, ..., `$x_{\text{cnt}_i}$`, and the new edges are `$[u_i, x_1], [x_1, x_2], [x_2, x_3], ..., [x_{\text{cnt}_{i-1}}, x_{\text{cnt}_i}], [x_{\text{cnt}_i}, v_i]$`.

In this **new graph**, you want to know how many nodes are **reachable** from the node `0`, where a node is **reachable** if the distance is `maxMoves` or less.

Given the original graph and `maxMoves`, return the number of nodes that are **reachable** from node `0` in the new graph.

Example 1:
```
Input: edges = [[0,1,10],[0,2,1],[1,2,2]], maxMoves = 6, n = 3
Output: 13
Explanation: The edge subdivisions are shown in the image above.
The nodes that are reachable are highlighted in yellow.
```

### Dijkstra
**reachable node**包含两部分:
* node本身
* edge上可subdivide的node (cnt)

若想获得最多的node, 则需从`$\text{node}_0$`抵达更多节点, 因此采用Dijkstra算法. 假设结果为`reachable`, 每经过一个节点, 则`reachable`加一; 对于edge上的节点, 我们可假设一个场景: 
`$\text{edge}_i$`为`$\text{node}_a$`与`$\text{node}_b$`之间的edge, `$\text{edge}_i$`上可subdivide的节点数为`$\text{cnt}_i$`, 从`$\text{node}_0$`到`$\text{node}_a$`还剩余`$\text{move}_i$`移动数, 存在三种情况:
* `$\text{move}_i \lt \text{cnt}_i$`, 且从其他路径无法走到`$\text{node}_b$`: 通过的节点数为`$\text{move}_i$`
* `$\text{move}_i \lt \text{cnt}_i$`, 但从其他路径可以走到`$\text{node}_b$`: 假设走到`$\text{node}_b$`时还剩余`$\text{move}_j$`移动数, 则通过的节点数为`$\text{move}_i + \text{move}_j$`
* `$\text{move}_i \ge \text{cnt}_i$`: 通过的节点数为`$\text{cnt}_i$`

对于任意节点, 其`剩余移动数`为`maxMoves - 已经过的节点数`, Dijkstra算法遍历一个节点的相邻边时, 一个edge上可经过的节点数为`min(cnt, maxMoves - 已经过的节点数)`. 需要注意的是, 若maxMoves足够大, 一条边会被经过两次, 因此需比较`$\text{move}_{\text{edge}_{ab}} + \text{move}_{\text{edge}_{ab}}$`与`$\text{cnt}_i$`的大小.

```java
class Solution {
    public int reachableNodes(int[][] edges, int maxMoves, int n) {
        List<int[]>[] nodes = new List[n];
        for (int i = 0; i < n; i++) {
            nodes[i] = new ArrayList<>();
        }
        for (int[] e: edges) {
            int i = e[0], j = e[1], cnt = e[2];
            nodes[i].add(new int[]{j, cnt});
            nodes[j].add(new int[]{i, cnt});
        }
        boolean[] visited = new boolean[n];
        PriorityQueue<int[]> pq = new PriorityQueue<>((a,b)->a[1]-b[1]); // node, distance traveled
        pq.offer(new int[]{0, 0});
        int[][] matrix = new int[n][n]; // reachable nodes on each edge (i to j and j to i)
        int res = 0;
        while (!pq.isEmpty()) {
            int[] p = pq.poll();
            int i = p[0], dist = p[1]; // from node
            if (visited[i]) continue;
            res++;
            for (int[] edge: nodes[i]) {
                int j = edge[0], cnt = edge[1]; // to node
                if (dist + cnt + 1 <= maxMoves) { // whether or not move to next node
                    pq.offer(new int[]{j, dist + cnt + 1});
                }
                matrix[i][j] = Math.min(cnt, maxMoves - dist);
            }
            visited[i] = true;
        }
        for (int[] e: edges) {
            int i = e[0], j = e[1], cnt = e[2];
            res += Math.min(matrix[i][j] + matrix[j][i], cnt);
        }
        return res;
    }
}
```


## 2577. Minimum Time to Visit a Cell In a Grid
You are given a `m x n` matrix `grid` consisting of **non-negative** integers where `grid[row][col]` represents the **minimum** time required to be able to visit the cell `(row, col)`, which means you can visit the cell `(row, col)` only when the time you visit it is greater than or equal to `grid[row][col]`.

You are standing in the **top-left** cell of the matrix in the $0^{\text{th}}$ second, and you must move to **any** adjacent cell in the four directions: up, down, left, and right. Each move you make takes 1 second.

Return the **minimum** time required in which you can visit the bottom-right cell of the matrix. If you cannot visit the bottom-right cell, then return `-1`.

Example 1:
```
Input: grid = [[0,1,3,2],[5,1,2,5],[4,3,8,6]]
Output: 7
Explanation: One of the paths that we can take is the following:
- at t = 0, we are on the cell (0,0).
- at t = 1, we move to the cell (0,1). It is possible because grid[0][1] <= 1.
- at t = 2, we move to the cell (1,1). It is possible because grid[1][1] <= 2.
- at t = 3, we move to the cell (1,2). It is possible because grid[1][2] <= 3.
- at t = 4, we move to the cell (1,1). It is possible because grid[1][1] <= 4.
- at t = 5, we move to the cell (1,2). It is possible because grid[1][2] <= 5.
- at t = 6, we move to the cell (1,3). It is possible because grid[1][3] <= 6.
- at t = 7, we move to the cell (2,3). It is possible because grid[1][3] <= 7.
The final time is 7. It can be shown that it is the minimum time possible.
```

Example 2:
```
Input: grid = [[0,2,4],[3,2,1],[1,0,4]]
Output: -1
Explanation: There is no path from the top left to the bottom-right cell.
```

### Dijkstra
假设题目中矩阵大小为`m*n`, 要求用最短时间从(0,0)走到(m-1,n-1)位置, 因此使用Dijkstra算法, 需要注意的是, 我们无法在一个格子中等待一段时间后再前进, 因此存在几种情况:
* 从起始点(0,0)出发, 但(0,1)和(1,0)上的时间要求都大于1, 无法继续前进, 返回-1
* 从非(0,0)位置出发, 但目的位置要求的时间大于当前时间, 需要先回到之前的节点, 并返回该节点, 让时间+2. 若当前时间为$t_i$, 要求时间为$t_q$, 存在以下情况:
  * $t_i$和$t_q$同为奇数或偶数: $t_i$可增长到$t_q$
  * $t_i$和$t_q$互为奇偶数: $t_i$可增长到$t_q + 1$
* 若不满足上述条件, 且未抵达目的点(m-1, n-1), 则当前时间+1
* 抵达(m-1, n-1), 返回当前时间

算法的时间复杂度为`$O(mn\log{mn})$`

```java
class Solution {
    public int minimumTime(int[][] grid) {
        if (grid[1][0] > 1 && grid[0][1] > 1) return -1;
        PriorityQueue<int[]> pq = new PriorityQueue<>((a,b)->(a[2]-b[2]));
        pq.offer(new int[]{0, 0, 0});
        int m = grid.length, n = grid[0].length;
        boolean[][] visited = new boolean[m][n];
        int[][] dirs = {{0,1}, {1,0}, {0,-1}, {-1,0}};
        while (!pq.isEmpty()) {
            int[] p = pq.poll();
            int i = p[0], j = p[1], t = p[2] + 1;
            if (i == m-1 && j == n-1) return p[2];
            if (visited[i][j]) continue;
            for (int[] dir: dirs) {
                int x = i + dir[0], y = j + dir[1];
                if (x < 0 || x >= m || y < 0 || y >= n) continue;
                if (t < grid[x][y]) {
                    boolean isOdd1 = (grid[x][y] & 0x1) == 1, isOdd2 = (t & 0x1) == 1;
                    pq.offer(new int[]{x, y, grid[x][y] + ((isOdd1 ^ isOdd2) ? 1 : 0)});
                } else {
                    pq.offer(new int[]{x, y, t});
                }
            }
            visited[i][j] = true;
        }
        return -1;
    }
}
```


## 2699. Modify Graph Edge Weights
You are given an **undirected weighted connected** graph containing `n` nodes labeled from `0` to `n - 1`, and an integer array `edges` where `$\text{edges}[i] = [a_i, b_i, w_i]$` indicates that there is an edge between nodes `$a_i$` and `$b_i$` with weight `$w_i$`.

Some edges have a weight of `-1` (`$w_i = -1$`), while others have a **positive** weight (`$w_i > 0$`).

Your task is to modify **all edges** with a weight of -1 by assigning them **positive integer values** in the range `$[1, 2 * {10}^9]$` so that the **shortest distance** between the nodes `source` and `destination` becomes equal to an integer `target`. If there are **multiple modifications** that make the shortest distance between `source` and `destination` equal to `target`, any of them will be considered correct.

Return an array containing all edges (even unmodified ones) in any order if it is possible to make the shortest distance from `source` to `destination` equal to `target`, or an **empty array** if it's impossible.

### Binary Search + Dijkstra
假设图中节点i到j的最短路径为`D(i,j)`, 若图中任意一条边的权重加一, 则`D(i,j)`存在两种情况:
* `D(i,j)`不变: 添加权重的边并不组成i到j的最短路径
* `D(i,j)`加一: 添加权重的边为i到j的最短路径

反之, 若图中任意一条边的权重减一, 则`D(i,j)`要么不变, 要么减一, 因此`D(i,j)`保持着单调性. 对于题目中所有权重为-1的边, 其权重值的范围为$[1, \text{target}]$, 假设存在k条权重为-1的边, 则存在$k * (target - 1)$种权重情况, 如:
$$
[1,1,1, \ldots, 1] \\\\
[2,1,1, \ldots, 1] \\\\
[3,1,1, \ldots, 1] \\\\
\ldots \\\\
[target, 1, 1, \ldots, 1] \\\\
[target, 2, 1, \ldots, 1] \\\\
\ldots \\\\
[target, target, target, \ldots, target]
$$

假设source到destination的最短路径为D, 算法步骤如下:
1. 计算权重为$[1,1,1,\ldots,1]$时的最短路径D, 若大于target, 则无解
2. 计算权重为$[target, target, target, \ldots, target]$时的最短路径D, 若小于target, 则无解
3. 若不满足第一种和第二种情况, 说明存在解, 采用二分搜索查找符合条件的权重组合

```java
class Solution {
    public int[][] modifiedGraphEdges(int n, int[][] edges, int source, int destination, int target) {
        int k = 0;
        for (int[] edge: edges) {
            if (edge[2] == -1) ++k;
        }
        long l = 0, r = (target - 1) * (long)k;
        if (shortestPath(n, construct(n, edges, l, target), source, destination) > target
            || shortestPath(n, construct(n, edges, r, target), source, destination) < target) {
            return new int[0][0];
        }
        while (l <= r) {
            long m = l + (r - l) / 2;
            if (shortestPath(n, construct(n, edges, m, target), source, destination) > target) {
                r = m - 1;  
            } else {
                l = m + 1;
            }
        }
        for (int[] edge: edges) {
            if (edge[2] != -1) continue;
            if (r >= target - 1) {
                edge[2] = target;
                r -= target - 1;
            } else {
                edge[2] = (int)r + 1;
                r = 0;
            }
        }
        return edges;
    }

    private int shortestPath(int n, long[][] edges, int src, int dest) {
        boolean[] used = new boolean[n];
        long[] dist = new long[n];
        Arrays.fill(dist, Integer.MAX_VALUE);
        dist[src] = 0;
        for (int cnt = 0; cnt < n; cnt++) {
            int i = -1;
            for (int j = 0; j < n; j++) {
                if (!used[j] && (i == -1 || dist[j] < dist[i])) {
                    i = j;
                }
            }
            used[i] = true;
            for (int j = 0; j < n; j++) {
                if (used[j]) continue;
                dist[j] = Math.min(dist[j], dist[i] + edges[i][j]);
            }
        }
        return (int)dist[dest];
    }

    private long[][] construct(int n, int[][] edges, long index, int target) {
        long[][] res = new long[n][n];
        for (int i = 0; i < n; i++) {
            Arrays.fill(res[i], Integer.MAX_VALUE);
            res[i][i] = 0;
        }
        for (int[] edge: edges) {
            int a = edge[0], b = edge[1], d = edge[2];
            if (d == -1) {
                if (index >= target - 1) {
                    res[a][b] = res[b][a] = target;
                    index -= target - 1;
                } else {
                    res[a][b] = res[b][a] = index + 1;
                    index = 0;
                }
            } else {
                res[a][b] = res[b][a] = d;
            }
        }
        return res;
    }
}
```