---
title: Java Basic (1)
category:
  - Java
  - Basic
tag:
  - Java
abbrlink: '4093'
date: 2017-10-22 16:00:16
---

## 1. Type Conversion
以下类型转换可能导致的数据丢失:
1. int -> float
2. long -> float
3. long -> double

以下为不丢失数据的类型转换:

被转换类型 | 转换类型 | 转换后类型
----|----|----
byte, short, char | int | int
byte, short, char, int | long | long
byte, short, char, int, long | float | float
byte, short, char, int, long, float | double | double


## 2. String Concatenation
1. 拼接静态字符串时, 尽量使用`+`, 因为编译器会自动优化为长字符串
  ```java
  String test = "this " + "is " + "a " + "test " + "string"
  /* 编译器优化为: String test = "this is a test string" */
  ```
2. 拼接动态字符串时, 可使用`StrinBuilder.append()`, 避免使用`+`.
  ```java
  StringBuilder test = new StringBuilder();
  test.append("this ");
  test.append("is ");
  test.append("a ");
  test.append("test ");
  test.append("string");
  ```


## 3. Iterate over an array
1. for
  ```java
  /* 需要知道数组大小 */
  for(int i = 0; i < arr.length; i++){ }
  ```
2. for-each
  ```java
  /* 需要知道数组的元素类型 */
  for(double val: arr){ }
  ```
3. iterator
  ```java
  /* 避免了不同Collections取出元素方式的不同 */
  Iterator iter = arr.iterator();
  while (iter.hasNext())
  {
    Integer i = itr.next();
  }
  ```


## 4. Static Block
static block内的变量或语句与类对象无关, 并在加载类时初始化static block, 所有static variable和static block按照定义顺序执行, 默认初始值为0, false, 或null. static block与classloader绑定, 如果两个程序使用不同的classloader, 则他们拥有两个互相独立的静态域.
```java
public class Hello{
  static {
    System.out.println("hello, world");
  }
}
```


## 5. toString()
1. 调用`toString()`可获得对象的字符串
  ```java
  public String toString() {  /* Object中toString()的定义 */
      return getClass().getName() + "@" + Integer.toHexString(hashCode());
    }
  ```
2. `toString()`会在某些情况下隐式调用(类对象与字符串用`+`连接, 或`System.out.print()`参数为类对象)
  ```java
  public void println(Object x) {     /* System.out.println()的定义 */
    String s = String.valueOf(x);
    synchronized (this) {
      print(s);
      newLine();
    }
  }

  public static String valueOf(Object obj) {  /* String.valueOf()的定义 */
      return (obj == null) ? "null" : obj.toString(); /* 使用了toString() */
    }
  ```
3. 对象可重载Object的`toString()`, 例如`StringBuilder.toString()`
  ```java
  @Override
    public String toString() {
      // Create a copy, don't share the array
      return new String(value, 0, count);
    }

  ```
4. 数组不支持toString(), 必须调用静态函数Arrays.toString()
  ```java
  /* Arrays.toString()的定义 */
  public static String toString(int[] a) { /* 通过重载实现数组的所有元素类型 */
    if (a == null) /* 检查null和空数组 */
      return "null";
    int iMax = a.length - 1;
    if (iMax == -1)
      return "[]";

    StringBuilder b = new StringBuilder(); /* 使用StringBuilder */
    b.append('[');
    for (int i = 0; ; i++) {
      b.append(a[i]); /* 数组元素类型为Object时改为: b.append(String.valueOf(a[i])); */
      if (i == iMax)
        return b.append(']').toString();
      b.append(", ");
    }
  }
  ```


## 6. Wrapper
### 6.1 primitive type and wrapper class
Primitive Data Type | Wrapper Class
----|----
char | Character
byte | Byte
short | Short
long | Long
float | Float
double | Double
boolean | Boolean

### 6.2 autoboxing and unboxing
```java
char c1 = 'a';
/* Autoboxing: primitive to Character object conversion */
Character c2 = c1;
```
wrapper class不能进行`==`操作, 因为比较的是两个对象的内存地址
```java
/* [-128 - 127]内的数字相同, 区间之外的数字不相同, 这与Java的内存管理有关 */
Integer a = 200;
Integer b = 200;
System.out.println(a == b); /* false */
```


## 7. Type Erasure
`List<Integer>`和`List<String>`编译后都会成为`List`, JVM只会看到List, 并不会看到类型信息, 因为所有元素类型都会擦除为`Object`
```java
ArrayList<String> arr1 = new ArrayList<>();
arr1.add("abc");
ArrayList<Integer> arr2 = new ArrayList<>();
arr2.add(123);
arr1.getClass() == arr2.getClass(); /* true */
```
定义元素类型是为了向Collection中加入元素时检查类型. 若定义Collection时不标明元素类型, 则编译器不会进行类型检查
```java
ArrayList arr = new ArrayList<>();
arr.add("abc"); /* unchecked call to add(E) */
arr.add(123);
```


## 8. Thread-Safe Collections
1. Vector(ArrayList线程不安全)
2. Stack
3. HashTable(HashMap线程不安全)
4. Enumeration
5. StringBuffer(StringBuilder线程不安全)
6. Properties


## 9. Postfix Increment
```java
int i = 0;
i = i++;
System.out.println(i); // 0
```
其中, `i = i++`相当于以下代码:
```java
int tmp = i;
i++;
i = tmp;
```


## 10. final
使用`final`关键字修饰引用时, 是指引用变量不可变, 引用所指向的对象中还是可变的.
```java
final char[] a = {'a','b','c'};
char[] b = {'c','d','e'};
// a = b;   // error, 引用不可改
a[0] = 'd'; // 引用指向的内容可改
```


## 11. parameter and argument
函数传递的是参数的拷贝:
```java
/* 形参x和y为a和b的引用拷贝 */
void operate(StringBuffer x, StringBuffer y) {
  x.append(y); /* x指向的StringBuffer变为"AB" */
  y = x;       /* 改变了y, 未改变b */
}

StringBuffer a = new StringBuffer("A");
StringBuffer b = new StringBuffer("B");
operate(a, b);
// a: AB, b: B
```


## 12. Round Number
Java有三种取整方式:
* `Math.floor(double d)`: 小于或等于d的最大整数
* `Math.ceil(double d)`: 大于或等于d的最小整数
* `Math.round(double d)`: 最接近d的整数

`round()`需注意正负值:
* `d > 0`: 
    * 小数点后一位的值为`[0, 4]`, d向下取整
    * 小数点后一位的值为`[5, 9]`, d向上取整
* `d < 0`: 
    * 小数点后一位的值为`[0, 5]`, d向上取整
    * 小数点后一位的值为`[6, 9]`, d向下取整

```java
Math.floor(-4.2);   // -5.0
Math.floor(4.6);    // 4.0
Math.ceil(-4.6);    // -4.0
Math.ceil(4.2);     // 5.0
Math.round(0.4);    // 0
Math.round(0.5);    // 1
Math.round(-0.5);   // 0
Math.round(-0.6);   // -1
```


## 13. Synchronizer
* Semaphore: 完成信号量控制, 可控制某个资源同事被访问的个数, 并通过`acquire()`获得一个访问许可. 如果没有则等待, `release()`释放许可
* CyclicBarrier: 只有`await()`方法, 每调用一次计数则减1, 并阻塞当前进程. 当计数器归0时阻塞解除, 所有阻塞的线程都开始运行.
* CountDown: 在`CountDown.await()`归0之前阻塞当前线程


## 14. monitor
* Java使用monitor来保证同一时间只有一个线程可以访问一段代码或数据
* 同时只能有一个线程获得某个对象的monitor
* 只有拥有了该对象的monitor才能调用对象的`notify()`和`notifyAll()`, 否则会抛出`java.lang.IllegalMonitorStateException`
* 一个线程想拥有一个对象的monitor的方法有三种:
    * `public synchronize a(){}`
    * `synchronize(obj){}`
    * `public static synchronize b(){}`


## 15. try-catch
try可以对应多个catch, 但只会匹配第一个相符的catch. 且从上向下依次匹配, 所以应将异常范围小的放在前面.
```java
try {
  //
} catch (Exception e) { /* 由于IOException extends Exception, 所以覆盖了IOException */
  // ...
} catch (IOException e) { /* compile error, IOException has already be caught */
  // ...
}
```


## 16. finally
finally块内的语句会在try结束前被执行, 所以finally中不应return. try-catch-finally的执行流程如下:
* try中出现的异常catch能捕获到, 转由catch处理
* try中出现的异常catch无法捕获, 转到finally
* catch中无论是否出现异常, 都会结束后转到finally

```java
public boolean returnTest() /* return false */
{
  try {
    return true;
  } catch (Exception e) {
    //
  } finally {
    return false;
  }
}
```


## 17. ThreadLocal
ThreadLocal的作用是为线程提供一个可共享的局部变量. "可共享"是因为该线程的所有函数都可以访问该变量; "局部变量"是因为其他线程无法访问和修改该变量. 所以ThreadLocal避免了全局变量的一个缺点: 所有线程都可访问. 并且减少了同一个线程内多个函数使用公共变量传递的不便.


## 18. Method Signature
当同一类中两个函数同名时, 会出现重载问题. Java通过**方法签名**保证函数唯一. 由于重载只与参数类型, 参数个数, 和参数顺序有关, 因此签名必须包含这些信息.
```java
public void test1(){}       // test1()V
public void test2(String str) // test2(Ljava/lang/String;)V
public int test3(){}        // test3()I
```
以下是方法签名中特殊字符的含义

特殊字符 | 数据类型 | 特殊说明
----|----|----
V | void | 一般用于表示方法的返回值
Z | boolean	 
B | byte	 
C | char	 
S | short	 
I | int	 
J | long	 
F | float	 
D | double	 
[ | 数组 | 以`[`开头, 配合其他的特殊字符, 表示对应数据类型的数组, 几个`[`表示几维数组
L | 引用类型 | 以`L`开头 以`;`结尾, 中间是引用类型的全类名


## 19. >> and >>>
`>>`表示符号右移, `>>>`表示无符号右移
```java
int a = -1 >> 2;
int b = -1 >>> 2;
System.out.printf("%d 0x%x\n", a, a); // -1         0xffffffff 
System.out.printf("%d 0x%x\n", b, b); // 1073741823 0x3fffffff
```


## 20. Implicit Type Casting
从小到大, 可隐式转换, 数据类型自动提升: byte, short, char -> int -> long -> float -> double. Java在以下情况下会进行隐式转换:
* 算数运算
* 赋值表达式
* 函数调用中参数传递
* 返回表达式类型

但从大到小只能强制转换
```java
byte a = 1;
byte b = 2;
// byte c = a+b; // error, a+b返回int类型, 与c类型不符
byte c = (byte)(a + b);
```
final修饰的变量不能自动隐式转换


## 21. Integer and ==
当赋予Integer一个整数值时, 会调用`Integer.valueOf()`来将int转换为Integer. 但`valueOf()`会将`[-128, 127]`之间的int数字放入IntegerCache中, 而范围之外的int数字会赋予一个新的内存空间.
```java
Integer f1 = 100, f2 = 100, f3 = 150, f4 = 150;
System.out.println( f1 == f2); // 地址相同, 输出true
System.out.println( f3 == f4); // 地址不同, 输出false
```


## 22. volatile
Java内存模型规定, 所有变量都要存在主存(物理内存)当中. 每个线程都有自己的工作内存(类似于告诉告诉缓存). 线程对变量的所有操作都必须在工作内存中进行.
```java
i = 10;
```
上述语句需要先将10写入工作内存中, 然后再写入主存中. 这样就会导致各个线程中的工作内存放置的数据不相同. volatile用来修饰被不同线程访问和修改的变量, 能保证共享变量能立即刷新到主存中. 当其他线程需要读取时, 会从主存中读取新值. 
volatile也能禁止指令重排序优化. 因为编译器对指令顺序的重新排序可能导致程序错误.
Volatile 变量具有synchronized的可见性特性, 但是不具备原子特性


## 23. Collection and Map
Collection:
* List:
    * ArrayList
    * Vector
    * LinkedList
* Set
* Queue
* sortedSet

Map:
* HashMap
* HashTable
* TreeMap
* IdentityHashMap
* WeakHashMap
