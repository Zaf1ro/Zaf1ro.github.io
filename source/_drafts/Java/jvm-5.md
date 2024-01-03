---
title: jvm-5
category:
  - Java
tag:
  - Java
abbrlink: 1835180302
date: 2017-11-20 13:39:57
---

#### 20. Synchronization(同步)
JVM通过monitor的进入和退出实现Synchronization
```java
int onlyMe(int i) {
    synchronized(this) {
        return i;
    }
}

/*
 0: aload_0         // this
 1: dup             // 复制this
 2: astore_2        // 将this放入local variable的第二位
 3: monitorenter
 4: iload_1         // 装入1
 5: aload_2         // 装入this
 6: monitorexit
 7: ireturn         // 返回i
 8: astore_3        
 9: aload_2
10: monitorexit
11: aload_3
12: athrow
*/
```


