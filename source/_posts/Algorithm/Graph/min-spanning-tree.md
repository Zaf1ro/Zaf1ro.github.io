---
title: Minimum Spanning Tree (MST)
abbrlink: afab
date: 2023-03-07 15:59:33
category:
  - Algorithm
  - Graph
tag:
  - Algorithm
keywords:
description:
---

## 1135. Connecting Cities With Minimum Cost
There are `n` cities labeled from `1` to `n`. You are given the integer `n` and an array `connections` where `$connections[i] = [x_i, y_i, {cost}_i]$` indicates that the cost of connecting city `$x_i$` and city `$y_i$` (bidirectional connection) is `${cost}_i$`.

Return the minimum **cost** to connect all the `n` cities such that there is at least one path between each pair of cities. If it is impossible to connect all the `n` cities, return `-1`,

The cost is the sum of the connections' costs used.

Example 1:
```
Input: n = 3, connections = [[1,2,5],[1,3,6],[2,3,1]]
Output: 6
Explanation: Choosing any 2 edges will connect all cities so we choose the minimum 2.
```

Example 2:
```
Input: n = 4, connections = [[1,2,3],[3,4,4]]
Output: -1
Explanation: There is no way to connect all cities even if all edges are used.
```

### 1. Prim’s Algorithm
Prim算法步骤如下:
1. 随机挑选一个vertex作为起点
2. 将该vertex连接的所有edge放入最小堆(min heap)
3. 若最小堆中仍有edge, 则一直执行以下步骤
    1. 从最小堆中取出权重最小的edge
    2. 查看该edge连接的vertex是否已被访问, 若之前访问过, 则重复上一步骤; 若vertex未被访问过:
        1. 记录该vertex, 防止重复访问
        2. 记录edge的权重
        3. 将该vertex连接的所有edge放入最小堆

由于tree不允许存在任何circle, 因此Prim需要记录每次访问的vertex, 避免形成circle. Prim算法的前提是无向图(Undirected graph), 不适用于有向图(Directed graph). 该算法的时间复杂度为$O(e\log{e})$(e为edge数).

```java
class Solution {    
    class Node {
        public int id;
        public List<Edge> edges;
        public Node(int id) {
            this.id = id;
            this.edges = new ArrayList<>();
        }
        public void addEdge(Edge e) {
            this.edges.add(e);
        }
    }

    class Edge {
        public int from;
        public int to;
        public int weight;
        public Edge(int from, int to, int weight) {
            this.from = from;
            this.to = to;
            this.weight = weight;
        }
    }

    public int minimumCost(int n, int[][] connections) {
        // build graph
        Node[] nodes = new Node[n+1];
        for (int[] conn: connections) {
            int n1 = conn[0], n2 = conn[1], w = conn[2];
            if (nodes[n1] == null) nodes[n1] = new Node(n1);
            if (nodes[n2] == null) nodes[n2] = new Node(n2);
            nodes[n1].addEdge(new Edge(n1, n2, w));
            nodes[n2].addEdge(new Edge(n2, n1, w));
        }
        int res = 0, count = 1;
        PriorityQueue<Edge> pq = new PriorityQueue<>((a,b)->a.weight-b.weight);
        // Find all edges connecting to the node
        for (Edge e: nodes[1].edges) {
            pq.offer(e);
        }
        boolean[] visited = new boolean[n+1];
        visited[1] = true;
        while (!pq.isEmpty()) {
            Edge edge = pq.poll(); // Find the minimum among these edges
            if (visited[edge.to]) continue; // Add the chosen edge to MST if it does not form any cycle
            visited[edge.to] = true;
            res += edge.weight;
            count++;
            for (Edge e: nodes[edge.to].edges) {
                pq.offer(e);
            }
        }
        return count == n ? res : -1;
    }
}
```

### 2. Kruskal's algorithm
Kruskal算法同样只适用于无向图, 算法思路如下:
1. 对graph中所有的edge按照权重从小到大排序
2. 假设graph中的每个vertex都是一个独立的tree, 从排序后的edge集合中不断取出最小值:
  1. 若取出的edge不会构成circle, 则将该edge加入结果, 并将edge两边的vertex连接为一颗tree
  2. 若取出的edge构成circle, 则忽略该edge

![Kruskal's algorithm on a complete graph with weights based on Euclidean distance](/images/Algorithm/Kruskal.gif)

该算法的时间复杂度为$O(e\log{e})$(e为edge数).
```java
class Solution {    
    public int minimumCost(int n, int[][] connections) {
        int[] parents = new int[n+1], ranks = new int[n+1];
        for (int i = 1; i <= n; i++) {
            parents[i] = i;
        }
        Arrays.sort(connections, (a,b)->a[2]-b[2]);
        int res = 0, count = 1;
        for (int[] conn: connections) {
            int p1 = find(parents, conn[0]), p2 = find(parents, conn[1]);
            if (p1 == p2) continue;
            res += conn[2];
            count++;
            union(parents, ranks, p1, p2);
        }
        return count == n ? res : -1;
    }

    private int find(int[] parents, int i) {
        if (parents[i] == i) return i;
        return find(parents, parents[i]);
    }

    private void union(int[] parents, int[] ranks, int i, int j) {
        if (ranks[i] < ranks[j]) {
            parents[i] = j;
        } else if (ranks[i] > ranks[j]) {
            parents[j] = i;
        } else {
            ranks[i]++;
            parents[j] = i;
        }
    }
}
```


## 1584. Min Cost to Connect All Points
You are given an array `points` representing integer coordinates of some points on a 2D-plane, where `points[i] = [$x_i$, $y_i$]`.

The cost of connecting two points `$[x_i, y_i]$` and `$[x_j, y_j]$` is the manhattan distance between them: `$|x_i - x_j| + |y_i - y_j|$`, where `|val|` denotes the absolute value of val.

Return the minimum cost to make all points connected. All points are connected if there is exactly one simple path between any two points.

Example 1:
```
Input: points = [[0,0],[2,2],[3,10],[5,2],[7,0]]
Output: 20
```

### 1. Kruskal's algorithm
与上一题相同, 该题可使用Kruskal寻找最小生成树, 该算法的时间复杂度为`$O(e\log(e))$`(e为edge数, n为vertex数, 则$e = n^2$)
```java
class Solution {
    public int minCostConnectPoints(int[][] points) {
        int n = points.length;
        int[][] edges = new int[n*n][3];
        for (int i = 0, k = 0; i < n; i++) {
            for (int j = i+1; j < n; j++) {
                edges[k][0] = i;
                edges[k][1] = j;
                edges[k++][2] = Math.abs(points[i][0] - points[j][0]) + Math.abs(points[i][1] - points[j][1]);
            }
        }
        Arrays.sort(edges, (a, b)->a[2]-b[2]);
        int[] parents = new int[n], ranks = new int[n];
        for (int i = 1; i < n; i++) {
            parents[i] = i;
        }
        int res = 0;
        for (int[] edge: edges) {
            int p1 = find(parents, edge[0]), p2 = find(parents, edge[1]);
            if (p1 == p2) continue;
            res += edge[2];
            union(parents, ranks, p1, p2);
        }
        return res;
    }

    private int find(int[] parents, int i) {
        if (parents[i] == i) return i;
        return find(parents, parents[i]);
    }

    private void union(int[] parents, int[] ranks, int i, int j) {
        if (ranks[i] <= ranks[j]) {
            parents[i] = j;
            if (ranks[i] == ranks[j]) ranks[j]++;
        } else {
            parents[j] = i;
        }
    }
}
```

### 2. Prim’s Algorithm
思路与上一题相同, 算法时间复杂度为`$O(n^2)$`(n为vertex数), 但由于该题每两个点组成一条边, 因此edge数远超vertex数, 导致Kruskal算法的耗时更长, 总结:
* Prim算法适合点与点连接稠密的图
* Kruskal算法适合点与点连接稀疏的图

```java
class Solution {
    public int minCostConnectPoints(int[][] points) {
        int n = points.length, res = 0, count = 1, i = 0;
        boolean[] visited = new boolean[n];
        visited[0] = true;
        PriorityQueue<int[]> pq = new PriorityQueue<>((a,b)->a[1]-b[1]);
        while (count++ < n) {
            // calculate manhattan distance
            for (int j = 1; j < n; j++) {
                if (visited[j]) continue;
                pq.offer(new int[]{j, Math.abs(points[i][0] - points[j][0]) + Math.abs(points[i][1] - points[j][1])});
            }
            while (visited[pq.peek()[0]]) pq.poll();
            int[] p = pq.poll();
            visited[p[0]] = true;
            res += p[1];
            i = p[0];
        }
        return res;
    }
}
```


## 1489. Find Critical and Pseudo-Critical Edges in Minimum Spanning Tree
Given a weighted undirected connected graph with `n` vertexs numbered from `0` to `n - 1`, and an array edges where `edges[i] = [$a_i$, $b_i$, $\text{weight}_i$]` represents a bidirectional and weighted edge between nodes `$a_i$` and `$b_i$`. A minimum spanning tree (MST) is a subset of the graph's edges that connects all vertexs without cycles and with the minimum possible total edge weight.

Find all the critical and pseudo-critical edges in the given graph's minimum spanning tree (MST). An MST edge whose deletion from the graph would cause the MST weight to increase is called a critical edge. On the other hand, a pseudo-critical edge is that which can appear in some MSTs but not all.

### Kruskal's algorithm
按照题目的描述, graph的edge分为三类:
* critial edge: 组成MST的必要边, 若去掉该edge, 会导致MST的weight变化
* pesudo-critial edge: 组成MST的可选边, 该边可被其他权重的路径替代, 因此剔除该边也不会影响MST的weight
* other edge: 不能作为MST的边

该解法的步骤如下:
1. 通过Kruskal计算MST的最小总权重值
2. 遍历所有edge, 计算排除该edge的情况下MST的总权重值, 若不相同, 则说明该边对于MST不可或缺, 也就是critical edge
3. 再次遍历所有edge, 跳过critical edge, 计算MST的总权重值前先加入该边:
  * 若MST的总权重值与最小总权重值相同: 说明该边不是other edge, 也就是pesudo-critical edge
  * 若不同: 说明该边是other edge

```java
class Solution {
    class Edge {
        public int from;
        public int to;
        public int weight;
        public int index;
        public boolean isSkip = false;
        public Edge(int from, int to, int weight, int index) {
            this.from = from;
            this.to = to;
            this.weight = weight;
            this.index = index;
        }
    }

    public List<List<Integer>> findCriticalAndPseudoCriticalEdges(int n, int[][] e) {
        Edge[] edges = new Edge[e.length];
        for (int i = 0; i < e.length; i++) {
            edges[i] = new Edge(e[i][0], e[i][1], e[i][2], i);
        }
        Arrays.sort(edges, (a,b)->a.weight-b.weight);
        int[] parents = new int[n];
        for (int i = 1; i < n; i++) {
            parents[i] = i;
        }
        List<List<Integer>> res = new ArrayList<>();
        res.add(new ArrayList<>());
        res.add(new ArrayList<>());
        int min = findMstWeight(Arrays.copyOf(parents, n), new int[n], edges);
        for (Edge edge: edges) {
            edge.isSkip = true;
            if (min != findMstWeight(Arrays.copyOf(parents, n), new int[n], edges)) {
                res.get(0).add(edge.index);
            }
            edge.isSkip = false;
        }
        for (Edge edge: edges) {
            if (res.get(0).contains(edge.index)) continue;
            int[] p = Arrays.copyOf(parents, n), r = new int[n];
            p[edge.from] = edge.to;
            r[edge.to]++;
            if (min == findMstWeight(p, r, edges) + edge.weight) {
                res.get(1).add(edge.index);
            }
        }
        return res;
    }

    private int findMstWeight(int[] parents, int[] ranks, Edge[] edges) {
        int res = 0;
        for (Edge e: edges) {
            if (e.isSkip) continue;
            int p1 = find(parents, e.from), p2 = find(parents, e.to);
            if (p1 == p2) continue;
            res += e.weight;
            union(parents, ranks, p1, p2);
        }
        return res;
    }

    private int find(int[] parents, int i) {
        if (parents[i] == i) return i;
        return find(parents, parents[i]);
    }

    private void union(int[] parents, int[] ranks, int i, int j) {
        if (ranks[i] <= ranks[j]) {
            parents[i] = j;
            if (ranks[i] == ranks[j]) ranks[j]++;
        } else {
            parents[j] = i;
        }
    }
}
```


## 1168. Optimize Water Distribution in a Village
There are `n` houses in a village. We want to supply water for all the houses by building wells and laying pipes.

For each house `i`, we can either build a well inside it directly with cost `wells[i - 1]` (note the -1 due to 0-indexing), or pipe in water from another well to it. The costs to lay pipes between houses are given by the array pipes where each `pipes[j] = [$\text{house1}_j$, $\text{house2}_j$, $\text{cost}_j$]` represents the cost to connect `$\text{house1}_j$` and `$\text{house2}_j$` together using a pipe. Connections are bidirectional, and there could be multiple valid connections between the same two houses with different costs.

Return the minimum total cost to supply water to all houses.

Example 1:
```
Input: n = 3, wells = [1,2,2], pipes = [[1,2,1],[2,3,1]]
Output: 3
Explanation: The image shows the costs of connecting houses using pipes.
The best strategy is to build a well in the first house with cost 1 and connect the other houses to it with cost 2 so the total cost is 3.
```

### Kruskal's algorithm
该题并不要求每个vertex连通, 因此看起来与MST无关; 但换一种思路, 假设不允许挖井, house只能从一个水库取水, 一个house连接到水库的pipe成本等同于自己挖井的成本, 那么整个图只存在edge的权重值, 不存在vertex的权重值, 使用Kruskal构成的MST包含两类vertex:
* 直接与水库相连的house
* 与其他house建立pipe的house, 换句话说, 该house与水库间接相连

```java
class Solution {
    public int minCostToSupplyWater(int n, int[] wells, int[][] pipes) {
        List<int[]> edges = new ArrayList<>();
        for (int[] pipe: pipes) { // cost of pipe to other house
            edges.add(pipe);
        }
        for (int i = 0; i < n; i++) { // cost of pipe to the reservoir
            edges.add(new int[]{0, i+1, wells[i]});
        }
        // Kruskal's algorithm
        Collections.sort(edges, (a,b)->a[2]-b[2]);
        int[] parents = new int[n+1], ranks = new int[n+1];
        for (int i = 1; i <= n; i++) {
            parents[i] = i;
        }
        int res = 0;
        for (int[] e: edges) {
            int p1 = find(parents, e[0]), p2 = find(parents, e[1]);
            if (p1 == p2) continue;
            res += e[2];
            union(parents, ranks, p1, p2);
        }
        return res;
    }

    private int find(int[] parents, int i) {
        if (parents[i] == i) return i;
        return find(parents, parents[i]);
    }

    private void union(int[] parents, int[] ranks, int i, int j) {
        if (ranks[i] <= ranks[j]) {
            parents[i] = j;
            if (ranks[i] == ranks[j]) ranks[j]++;
        } else {
            parents[j] = i;
        }
    }
}
```
