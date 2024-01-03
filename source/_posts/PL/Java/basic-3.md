---
title: Java Basic (3)
category:
  - Java
  - Basic
tag:
  - Java
abbrlink: '2092'
date: 2017-11-02 15:48:55
---

## 1. character encoding
1. Java一律采用UTF-16(2字节)编码方式保存字符, 无论什么语言的字符都占用两个字节
2. 任何字符串都可以其自身编码方式分解
```java
String newUTF8Str = new String(oldGBKStr.getBytes("GBK"), "UTF8");
```


## 2. substring()
substring()函数返回的是一个new的String, 分配在堆上. 并且substring(start, end)返回从start开始到最后(不包括end)的子字符串
```java
static String str1 = "0123456789";
String str2 = str1.substring(5);  // str2是一个对象引用, 指向堆上的String对象
```


## 3. wait()
`Object.wait()`要以try/catch包裹, 或抛出`InterruptedException`. `Thread.sleep()`也会抛出`InterruptedException`, 也必须用try/catch包裹


## 4. Collection and Collections
1. java.util.Collection是一个集合接口. 它提供了对集合对象进行基本操作的通用接口方法. Collection接口在Java类库中有很多具体的实现, Collection接口的意义是为各种具体的集合提供了最大化的统一操作方式
2. java.util.Collections是一个包装类. 它包含有各种有关集合操作的静态多态方法,  n此类不能实例化, 就像一个工具类, 服务于Java的Collection框架


## 5. override
方法重写应遵循**三同一小一大**原则:
1. 三同: 即方法名相同, 形参列表相同, 返回值类型相同或小于(double和int并没有比较关系, 必须是父类和子类)
2. 一小: 子类方法声明抛出的异常比父类方法声明抛出的异常更小或者相等
3. 一大: 子类方法的访问修饰符应比父类方法更大或相等
变量不能重写, 重写只针对方法. 重写父类变量会报错.


## 6. super() and this()
1. `super()`或者`this()`必须放在构造函数的第一行
2. 由于this函数指向的构造函数默认有`super()`方法, 所以`this()`和`super()`不能同时出现在一个构造函数中
3. 由于staic方法或者语句块可脱离实例使用, 因此不能使用`this()`和`super()`


## 7. classloader
一个jvm中默认的三个classloader
1. Bootstrap ClassLoader: 负责加载java基础类，主要是`%JRE_HOME/lib/`目录下的rt.jar, resources.jar, charsets.jar和class等
2. Extension ClassLoader: 负责加载java扩展类, 主要是`%JRE_HOME/lib/ext`目录下的jar和class
3. App ClassLoader: 负责加载当前java应用的classpath中的所有类

类加载器的双亲委派模型: 应用程序由以上三种类加载器互相配合进行加载的, 还可以加入自己定义的类加载器


## 8. String and char[]
无法使用equals()对比String和char[], 因为`equals()`会先使用`instanceof`判断char[]和String的包含关系, 并回到false
```java
String s1 = "123";
char[] s2 = {'1','2','3'};
System.out.println(s1.equals(s2));  // false
System.out.println(s1.equals(new String(s2)));  // true
```
以下是String, char, 和char[]之间的转换:
```java
String string = "123";
char[] char_array = {'1','2','3'};
char c = '1';

/* convert char to String*/
String s1 = Character.toString(c);
String s2 = String.valueOf(c);

/* convert char[] to String */
String s3 = new String(char_array);

/* convert String to char */
char c1 = string.charAt(0);

/* convert String to char[] */
char[] char_array1 = string.toCharArray();
```


## 9. LinkedBlockingQueue and PriorityQueue
1. LinkedBlockingQueue
    1. 基于链接节点的可选限定的blocking queue
    2. 排列元素FIFO(先进先出), 队列的头部是队列中最长的元素, 队列的尾部是队列中最短时间的元素
    3. 新元素插入队列的尾部, 队列检索操作获取队列头部的元素
    4. 不接受null元素, 线程安全但效率低
2. PriorityQueue
    1. 基于优先级堆的无限优先级queue, 优先级队列的元素根据它们的有序natural ordering, 或由一个Comparator在队列构造的时候提供
    2. 优先队列不允许null元素, 依靠自然排序的优先级队列也不允许插入不可比较的对象(这样做可能导致ClassCastException)
    3. 该队列的头部是相对于指定顺序的最小元素. 如果多个元素被绑定到最小值, 那么头就是这些元素之一
    4. 无限长度. 但是有队列上存储元素的数组的大小的内部容量. 它始终至少与队列大小一样大, 当元素被添加到优先级队列中时其容量会自动增加
    5. 该类及其迭代器实现Collection和Iterator接口的所有可选方法. 方法iterator()中提供的迭代器不能保证以任何特定顺序遍历优先级队列的元素. 如果需要有序遍历, 请考虑使用Arrays.sort
    6. 此实现不同步. 如果任何线程修改队列, 多线程不应同时访问PriorityQueue实例, 而是使用线程安全的PriorityBlockingQueue


## 10. singleton
有两种实现单例模式的方法:
1. 懒汉式
```java
public class Singleton {
  private static Singleton instance;
  private Singleton (){}
  public static Singleton getInstance() {
    if (instance == null) {
      instance = new Singleton();
    }
    return instance;
  }
}
```
2. 饿汉式
```java
public class Singleton{
  // 类加载时就初始化
  private static final Singleton instance = new Singleton();
  
  private Singleton(){}
  public static Singleton getInstance(){
    return instance;
  }
}
```


## 11. 方法分配
1. 静态分配
根据参数的静态类型来决定重载版本. 重载是依赖于静态分派的
```java
public class StaticDispatch {
  static abstract class Human{ }  
  static class Man extends Human{ }  
  static class Woman extends Human{ }  
  
  public void sayHello(Human human){  
    System.out.println("human say hello");
  }  
    
  public void sayHello(Man man){  
    System.out.println("man say hello");  
  }  
    
  public void sayHello(Woman woman){  
    System.out.println("woman say hello");
  } 
    
  public static void main(String[] args) {  
    Human man = new Man();  
    Human woman = new Woman();  
    StaticDispatch sd = new StaticDispatch();  
    sd.sayHello(man);   // human say hello 
    sd.sayHello(woman); // human say hello   
  }  
} 
```

2. 动态分派
在运行期，根据方法接收者的实际类型. 重写就依赖动态分派
```java
public class DynamicDispatch {
  static abstract class Human{  
    protected abstract void sayHello();  
  }  
    
  static class Man extends Human{  
    @Override  
    protected void sayHello() {  
      System.out.println("man say hello");  
    }   
  }  
    
  static class Woman extends Human{  
    @Override  
    protected void sayHello() {  
      System.out.println("woman say hello");  
    }  
  }  
  
  public static void main(String[] args) {  
    Human man = new Man();  
    Human woman = new Woman();  
    man.sayHello();   // man say hello 
    woman.sayHello();   // woman say hello 
  }
}  
```

3. 动态分配与虚函数的关系
```java
class Super {  
  private void interestingMethod() {  
    System.out.println("Super's interestingMethod");  
  }  
  
  void exampleMethod() {  
    interestingMethod();  
  }  
}  
  
class Sub extends Super {  
  void interestingMethod() {  
    System.out.println("Sub's interestingMethod");  
  }  
}  

public class SuperTest {  
  public static void main(String[] args) {  
    new Sub().exampleMethod();  // Super's interestingMethod
  }  
}  
```
上述代码并没有显示出动态分派, 因为Super的interestingMethod是私有的. 只有非虚函数才能展现出动态分派, 而虚函数是static方法+final方法+private方法. 所以interestingMethod为虚函数, 不能呈现出动态分派

4. 字节码指令对于方法分派的作用
1. 如果为private方法导致的静态分派, 使用的是invokespecial指令
2. 如果为重载导致的静态分派, 使用的是invokevirtual
3. 如果为重写导致的动态分派, 使用的是invokevirtual
因此可见, invokespecial导致的必然是静态分派, 而invokevirtual则不确定, 可能是静态, 也可能是动态


## 12. Throwable
* Throwable
  * Error
    * VirtualMachineError
      * StackOverFlowError
      * OutOfMemoryError
    * AWTError
  * Exception
    * IOException
      * EOFException
      * FileNotFoundException
    * RuntimeException
      * ArithmeticException
      * MissingResourceException
      * ClassNotFoundException
      * NullPointException
      * IllegalArgumentException
      * ArrayIndexOutOfBoundsException
      * UnknownTypeException

1. Exception(异常): 程序本身可以处理的异常 
2. Error(错误): 是程序无法处理的错误这些错误表示故障发生于虚拟机自身, 或者发生在虚拟机试图执行应用时, 一般不需要程序处理
3. 检查异常(编译器要求必须处置的异常): 除了Error, RuntimeException及其子类以外, 其他的Exception类及其子类都属于可查异常这种异常的特点是Java编译器会检查它. 当程序中可能出现这类异常, 要么用try-catch语句捕获它, 要么用throws子句声明抛出它, 否则编译不会通过
4. 非检查异常(编译器不要求处置的异常): 包括运行时异常(RuntimeException与其子类)和错误(Error)


## 13. reflection
1. `getDeclaredMethods()`返回类或接口声明的所有方法, 但不包括继承的方法
2. `getMethods()`返回类的所有public方法, 包括父类和接口的公用方法


## 14. JVM memory options
* -XX:+HeapDumpOnOutOfMemoryError: 设置堆溢出异常的条件
* -Xmx: Java heap的最大值
* -Xms: Java heap的初始值
* -XX:MinHeapFreeRatio: heap中空闲空间与已占用空间的最小比
* -XX:MaxHeapFreeRatio: heap中空闲空间与已占用空间的最大比
* -Xss: Java stack的最大值
* -Xmn: young generation的heap大小
* -XX:PermSize: 方法区最小值(只应用于JDK 1.6及之前版本, 可用于调整方法区)
* -XX:MaxPermSize: 方法区最大值(只应用于JDK 1.6及之前版本, 可用于调整方法区)
* -XX:SurvivorRatio: survivor space与eden的大小比例
* -XX:MaxDirectMemorySize: 直接内存的最大值


## 15. Rule for naming variable
1. 标识符是以`0~9`, `a-z`, `A-Z`, `_`, 和`$`, 也可以是Unicode字符集中的字符(例如: 汉字), 不能包含`+`, `-`, `*`等字符, 不可以数字开头. 


## 16. TLS (Thread Local Storage)
同一全局变量或者静态变量每个线程访问的是同一变量, 多个线程同时访存同一全局变量或者静态变量时会导致冲突, 尤其是多个线程同时需要修改这一变量时, 通过TLS机制(ThreadLocal是其中一个实现方式), 为每一个使用该全局变量的线程都提供一个变量值的副本, 每一个线程均可以独立地改变自己的副本, 而不会和其他线程的副本冲突


## 17. Extend interface
interface可以有通过extends关键值继承一个或多个interface
```java
interface inter1{}
interface inter2 extends inter1{}
interface inter3 extends inter1, inter2{}
```


## 18. Constant Expression
常量表达式是一种表达式, 但会在代码编译期间计算包含的常量和特定运算符, 常量表达式只能由以下运算符和表达式组成:
* 一元操作符: `+`, `-`, `~`, `!`
* 乘法操作符: `*`, `/`, `%`
* 加法操作符: `+`, `–`
* 移位操作符: `<<`, `>>`, `>>>`
* 关系操作符: `<`, `<=`, `>`, `>=`
* 相等操作符: `==`, `!=`
* 位和逻辑操作符: `&`, `^`, `|`
* 条件或和条件与操作符: `&&`, `||`
* 三元操作符: `?:`
* 带括号的表达式, 其中包含常量表达式
* 常量名
