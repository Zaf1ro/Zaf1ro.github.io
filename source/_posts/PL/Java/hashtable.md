---
title: Hashtable
category:
  - Java
  - Collections
tag:
  - Java
abbrlink: ca38
date: 2018-01-23 13:41:20
---

## 1. Hashtable概述
Hashtable和HashMap解决Hash Collision的方法相同, 都使用Separate Chaining. 但Hashtable使用synchronized保证线程安全, 使得效率上插入删除效率上略低于HashMap


## 2. 重要参数
```java
/* Hashtable主体 */
private transient Entry<?,?>[] table;

/* hash table中entry的个数 */
private transient int count;

/* table容量的阈值, 超过这个值就需要rehash */
private int threshold;

/* 负载因子 threshold = loadFactor * table.length */
private float loadFactor;

/* Hashtable修改的次数 */
private transient int modCount = 0;

/* table的最大长度(部分VM会在Array前保留几个字节, 所以需要-8) */
private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;
```


## 3. 初始化函数
### 3.1 无参数初始化函数
Hashtable的默认大小为11, 而HashMap的默认大小为16. 因为HashMap获得table的index操作为 hash\_value & table.length - 1 . 这时就需要HashMap的长度始终保持在2<sup>n</sup>, 而Hashtable的长度则需要一个质数, 因为Hashtable获得table的index操作为 hash\_value % table.length, 这就需要 hash\_value 和 table.length 的GCD(Greatest Common Divisor, 最大公约数)为1, 这样才能保证index的分布平均, 证明如下:

index的求解公式: index = N \% M (N为hash\_value, M为table的长度, index为余数)
假设N = kn, M = km. k为N和M的GCD
所以index求解公式可转换为:  kn = km &times; q + r
这么看来, r的取值范围为[0, M - 1]
但当公式两边除k后: n = m &times; q + r / k
r的取值范围变为[0, k, 2k, 3k ... m*k], 缩小了k倍, 导致分布不平均.
所以简单的方法就是将M设置为质数, 保证N和M的GCD为1
```java
/* 默认table长度为11, load factor为0.75 */
public Hashtable() {
  this(11, 0.75f);
}
```

### 3.2 带参数初始化函数
```java
public Hashtable(int initialCapacity) {
  this(initialCapacity, 0.75f);
}

/* Hashtable中对table的长度没有要求 */
public Hashtable(int initialCapacity, float loadFactor) {
  if (initialCapacity < 0)
    throw new IllegalArgumentException("Illegal Capacity: "+ initialCapacity);
  if (loadFactor <= 0 || Float.isNaN(loadFactor))
    throw new IllegalArgumentException("Illegal Load: "+loadFactor);

  if (initialCapacity == 0)
    initialCapacity = 1;
  this.loadFactor = loadFactor;   /* 设置loadfactor */
  table = new Entry<?,?>[initialCapacity];  /* 初始化table */
  threshold = (int)Math.min(initialCapacity * loadFactor, MAX_ARRAY_SIZE + 1);
}
```


## 4. table的组成单元 - Entry
```java
/* Hashtable中table的组成单元 */
private static class Entry<K,V> implements Map.Entry<K,V> {
  final int hash;
  final K key;
  V value;
  Entry<K,V> next;

  protected Entry(int hash, K key, V value, Entry<K,V> next) {
    this.hash = hash;
    this.key =  key;
    this.value = value;
    this.next = next;
  }

  @SuppressWarnings("unchecked")
  protected Object clone() {
    return new Entry<>(hash, 
               key, 
               value,
               (next == null ? null : (Entry<K,V>) next.clone())
    );
  }

  public K getKey() { return key; }

  public V getValue() { return value; }

  public V setValue(V value) {
    if (value == null)    /* Hashtable中的key和value不可设置为null */
      throw new NullPointerException();

    V oldValue = this.value;
    this.value = value;
    return oldValue;
  }

  public boolean equals(Object o) {
    if (!(o instanceof Map.Entry))  /* 先判断类型是否正确 */
      return false;
    Map.Entry<?,?> e = (Map.Entry<?,?>)o;

    /* 再判断key和value是否匹配 */
    return (key==null ? e.getKey()==null : key.equals(e.getKey())) &&
      (value==null ? e.getValue()==null : value.equals(e.getValue()));
  }

  public int hashCode() {
    return hash ^ Objects.hashCode(value);
  }

  public String toString() {
    return key.toString() + "=" + value.toString();
  }
}
```


## 5. table扩容函数
table长度的增长规律为 n<sub>n+1</sub> = 2&times;n<sub>n</sub> + 1, 这样虽然不能保证n<sub>n</sub>为质数, 但可保证n<sub>n</sub>一直为odd number, 避免了n<sub>n</sub>与hash value的公约数为2.
```java
/* 扩容table, 并重新组织table中的Entry 
 * 该函数会在Entry数量达到threshold时自动调用
 */
@SuppressWarnings("unchecked")
protected void rehash() {
  int oldCapacity = table.length;
  Entry<?,?>[] oldMap = table;

  /* 以下几行代码是overflow-conscious code, 因为一共有以下几种情况:
   * 1. newCapacity > MAX_ARRAY_SIZE: oldCapacity位于[1073741820, 1073741823]
   * 2. newCapacity == MAX_ARRAY_SIZE: oldCapacity为1073741819
   * 3. newCapacity < MAX_ARRAY_SIZE: oldCapacity位于[1073741824, 2147483647]或[1, 1073741818]
   * 由于初始化函数中没有对initialCapacity做任何限制, 所以oldCapacity可能为[1, 2147483647]中的任意值
   * 所以唯一会导致溢出的oldCapacity区间为[1073741824, 2147483647]
   * 此时 newCapacity < 0 且 newCapacity > MAX_ARRAY_SIZE 不成立
   *
   * 但由于减法运算存在溢出情况, 所以oldCapacity位于区间[1073741824, 2147483642]时
   * newCapacity + MAX_ARRAY_SIZE > 0 就会成立, newCapacity被替换为MAX_ARRAY_SIZE
   *
   * 最后就剩下一种情况: oldCapacity位于区间[2147483643, 2147483647]
   * 此时 newCapacity + MAX_ARRAY_SIZE > 0 不成立, 且 newCapacity < 0, 溢出发生
   * 
   * 但其实并不会发生, 因为当你调用 new Hashtable(Integer.MAX_VALUE) 时, 会出现溢出(OutOfMemoryError)
   */
  int newCapacity = (oldCapacity << 1) + 1;
  if (newCapacity - MAX_ARRAY_SIZE > 0) {   /* 无溢出情况 */
    if (oldCapacity == MAX_ARRAY_SIZE)
      return;
    newCapacity = MAX_ARRAY_SIZE;
  }
  
  /* 初始化新的table
   * 并设置新的threshold和modCount
   */
  Entry<?,?>[] newMap = new Entry<?,?>[newCapacity];
  modCount++;
  threshold = (int)Math.min(newCapacity * loadFactor, MAX_ARRAY_SIZE + 1);
  table = newMap;
  
  /* 两层for循环将每个Entry都移动到了newMap中 
   * 第一层for针对table中的每条链表
   * 第二层for针对每条链表中的每个Entry
   */
  for (int i = oldCapacity ; i-- > 0 ;) {
    for (Entry<K,V> old = (Entry<K,V>)oldMap[i] ; old != null ; ) {
      Entry<K,V> e = old;
      old = old.next;

      int index = (e.hash & 0x7FFFFFFF) % newCapacity;
      e.next = (Entry<K,V>)newMap[index];
      newMap[index] = e;
    }
  }
}
```


## 6. put()
```java
/**
 * 往table中插入key和value, key和value都不能为null
 * @param key   key of Entry
 * @param value value of Entry
 * @return the previous value of key or null
 * @exception NullPointerException key is null
 */
public synchronized V put(K key, V value) {
  if (value == null) {
    throw new NullPointerException();
  }

  // 判断key是否已经存在
  Entry<?,?> tab[] = table;
  int hash = key.hashCode();
  int index = (hash & 0x7FFFFFFF) % tab.length;
  @SuppressWarnings("unchecked")
  Entry<K,V> entry = (Entry<K,V>)tab[index];
  for(; entry != null ; entry = entry.next) { /* 反复查询table, 直到entry为null */
    if ((entry.hash == hash) && entry.key.equals(key)) {  /* 替换entry的value */
      V old = entry.value;
      entry.value = value;
      return old;
    }
  }

  addEntry(hash, key, value, index);    /* 插入一个新的entry */
  return null;
}


private void addEntry(int hash, K key, V value, int index) {
  modCount++;

  Entry<?,?> tab[] = table;
  if (count >= threshold) {   /* 检查是否进行扩容 */
    rehash();

    /* 重新计算key的hash value */
    tab = table;
    hash = key.hashCode();
    index = (hash & 0x7FFFFFFF) % tab.length;
  }

  /* 将新建的Entry放入table中, 且指向之前的Entry */
  @SuppressWarnings("unchecked")
  Entry<K,V> e = (Entry<K,V>) tab[index];
  tab[index] = new Entry<>(hash, key, value, e);
  count++;
}
```



## 7. get() 查找元素
```java
/**
 * 查询并返回key所对应的value, 如果未找到则返回null
 * @param key the key whose associated value is to be returned
 * @return return the value to which the specified key is mapped, or null
 * @throws NullPointerException key == null
 */
public synchronized V get(Object key) {
  Entry<?,?> tab[] = table;
  int hash = key.hashCode();
  int index = (hash & 0x7FFFFFFF) % tab.length;
  
  /* 在tab[index]开头的链表上进行查找 */
  for (Entry<?,?> e = tab[index] ; e != null ; e = e.next) {
    if ((e.hash == hash) && e.key.equals(key)) {
      return (V)e.value;
    }
  }
  return null;
}
```


## 8. remove()
```java
/**
 * 删除与key匹配的Entry, 如果没找到key直接退出
 * @param key
 * @return 被删除Entry的value
 * @throws NullPointerException key == null
*/
public synchronized V remove(Object key) {
  /* 步骤与HashMap基本相同:
   * 1. 根据hash value找到table中的某个链表
   * 2. 根据key在链表中找到要被删除的Entry, 并删除
   */
  Entry<?,?> tab[] = table;
  int hash = key.hashCode();
  int index = (hash & 0x7FFFFFFF) % tab.length;
  @SuppressWarnings("unchecked")
  Entry<K,V> e = (Entry<K,V>)tab[index];
  for(Entry<K,V> prev = null ; e != null ; prev = e, e = e.next) {
    if ((e.hash == hash) && e.key.equals(key)) {
      modCount++;
      if (prev != null) {
        prev.next = e.next;
      } else {
        tab[index] = e.next;
      }
      count--;
      V oldValue = e.value;
      e.value = null;
      return oldValue;
    }
  }
  return null;  /* 未找到要被删除的元素 */
}
```
