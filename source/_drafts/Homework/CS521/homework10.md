---
title: homework10
category:
  - Homework
tag:
  - Homework
abbrlink: 1484067458
date: 2017-11-30 18:40:25
---

#### Write the slides' link state algorithm and the Dijkstra’s algorithm
```python
# dijkstra algorithm implementation
def dijkstra(graph, src):
    if graph is None:   # whether gragh is None
        return None
    nodes = [i for i in range(len(graph))]  # get all node in graph
    visited=[]                              # record the nodes which have been visited
    if src in nodes:
        visited.append(src)
        nodes.remove(src)
    else:
        return None
    distance={src:0}                        # record the costs of each link
    for i in nodes:
        distance[i]=graph[src][i]
    path={src:{src:[]}}                     # 记录源节点到每个节点的路径
    k=pre=src
    while nodes:    # loop
        mid_distance=float('inf')
        for v in visited:
            for d in nodes:
                new_distance = graph[src][v]+graph[v][d]
                if new_distance < mid_distance: # get least cost link
                    mid_distance=new_distance
                    graph[src][d]=new_distance
                    k=d
                    pre=v
        distance[k]=mid_distance                # add the shortest node into list
        path[src][k]=[i for i in path[src][pre]]
        path[src][k].append(k)
        visited.append(k)
        nodes.remove(k)
        print(visited,nodes)  # print all nodes
    return distance,path
```


#### 1. P421 19
Due to the header of IP layer(20bytes), so the max size of udp is 700-20=680bytes. And the number of fragments should be 4, each fragment's Identification number is same as 422. The offset of four fragments will be 0, 85, 680/8=85, 680\*2/8=170, 680\*3/170=255. First three fragments' flag is 1, and the last fragment's flag is 0.


#### 2. P421 21
1. Assign addresses to all interfaces in the home network
router interface: 192.168.1.4
home address: 192.168.1.1, 192.168.1.2, 192.168.1.3
2. Suppose each host has two ongoing TCP connections, all to port 80 at host 128.119.40.86. Provide the six corresponding entries in the NAT translation table

WAN side | LAN side
-----|-----
24.34.112.235:1000 | 128.119.40.86:2000
24.34.112.235:1001 | 128.119.40.86:2001
24.34.112.235:1002 | 128.119.40.86:2002
24.34.112.235:1003 | 128.119.40.86:2003
24.34.112.235:1004 | 128.119.40.86:2004
24.34.112.235:1005 | 128.119.40.86:2005


#### 3. P422 22
Because the identification number of IP is randomly placed, we can make a cluster of consecutive incrementing ID as a host. And the number of clusters are the number of hosts.


#### 4. P422 26

Step | N' |D(t),p(t) | D(u),p(u) | D(v),p(v) | D(w),p(w) | D(y),p(y) | D(z),p(z)
-----|-----|-----|-----|-----|-----|-----|-----
0 | x | ∞ | ∞ | 3,x | 6,x | 6,x | 8,x
1 | xv | 7,v | 6,v | 3,x | 6,x | 6,x | 8,x
2 | xvu | 7,v | 6,v | 3,x | 6,x | 6,x | 8,x
3 | xvuw | 7,v | 6,v | 3,x | 6,x | 6,x | 8,x
4 | xvuwy | 7,v | 6,v | 3,x | 6,x | 6,x | 8,x
5 | xvuwyt | 7,v | 6,v | 3,x | 6,x | 6,x | 8,x
6 | xvuwytz | 7,v | 6,v | 3,x | 6,x | 6,x | 8,x



#### 5. P423 28

 | u | v | x | y | z
-----|-----|-----|-----|-----|------
v | ∞ | ∞ | ∞ | ∞ | ∞
x | ∞ | ∞ | ∞ | ∞ | ∞
z | ∞ | 6 | 2 | ∞ | 0

 | u | v | x | y | z
-----|-----|-----|-----|-----|------
v | 1 | 0 | 3 | ∞ | 6
x | ∞ | 3 | 0 | 3 | 2
z | 7 | 5 | 2 | 5 | 0

 | u | v | x | y | z
-----|-----|-----|-----|-----|------
v | 1 | 0 | 3 | 3 | 5
x | 4 | 3 | 0 | 3 | 2
z | 6 | 5 | 2 | 5 | 0

 | u | v | x | y | z
-----|-----|-----|-----|-----|------
v | 1 | 0 | 3 | 3 | 5
x | 4 | 3 | 0 | 3 | 2
z | 6 | 5 | 2 | 5 | 0


