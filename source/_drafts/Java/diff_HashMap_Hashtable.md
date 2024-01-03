---
abbrlink: 1
---
hashtable和hashmap的对比
1. Hashtable只有一个大小字母, HashMap有两个大写字母
2. hashmap的table长度必须为2<sup>n</sup>, hashtable的table长度随意
3. hashmap线程不安全, hashtable线程安全

5. hashmap中key和value可设置为null, hashtable不可以

6. 如何判断一对key/value是否存在: HashMap.containsKey(), Hashtable.get()/containsKey()
7. hashtable和hashmap的初始化大小不同, 理由