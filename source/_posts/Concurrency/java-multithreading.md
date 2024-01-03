---
title: Multithreading in Java
category:
  - Concurrency
  - Java
tag:
  - Concurrency
abbrlink: f54a
date: 2018-03-15 08:00:06
---

## 1. 多线程的优点
* 资源利用率更好: CPU能够在等待IO的时候做一些其他的事情. 这个不一定就是磁盘IO. 它也可以是网络的IO, 或者用户输入. 通常情况下, 网络和磁盘的IO比CPU和内存的IO慢的多
* 程序设计在某些情况下更简单: 单线程应用程序中, 如果你想编写程序手动处理上面所提到的读取和处理的顺序, 你必须记录每个文件读取和处理的状态. 相反, 你可以启动两个线程, 每个线程处理一个文件的读取和操作. 线程会在等待磁盘读取文件的过程中被阻塞. 在等待的时候, 其他的线程能够使用CPU去处理已经读取完的文件
* 程序响应更快: 将一个单线程应用程序变成多线程应用程序的另一个常见的目的是实现一个响应更快的应用程序. 设想一个服务器应用, 它在某一个端口监听进来的请求. 当一个请求到来时, 它去处理这个请求, 然后再返回去监听


## 2. 多线程代价
* 设计更复杂: 在多线程访问共享数据的时候, 这部分代码需要特别的注意. 线程之间的交互往往非常复杂. 不正确的线程同步产生的错误非常难以被发现, 并且重现以修复
* 上下文切换的开销: 当CPU从执行一个线程切换到执行另外一个线程的时候, 它需要先存储当前线程的本地的数据, 程序指针等, 然后载入另一个线程的本地数据, 程序指针等, 最后才开始执行. 这种切换称为**context switch**(上下文切换). CPU会在一个上下文中执行一个线程, 然后切换到另外一个上下文中执行另外一个线程
* 增加资源消耗: 线程在运行的时候需要从计算机里面得到一些资源. 除了CPU, 线程还需要一些内存来维持它本地的堆栈. 它也需要占用操作系统中一些资源来管理线程


## 3. 并发编程模型
### 3.1. Parallel Workers
委派者(Delegator)将传入的作业分配给不同的工作者. 每个工作者完成整个任务. 工作者们并行运作在不同的线程上, 甚至可能在不同的CPU上.
![Parallel worker concurrency model](/images/multithreading/Java/1-1.png)

* 优点
容易理解: 你只需添加更多的工作者来提高系统的并行度
* 缺点
  * 共享状态可能会很复杂
  共享的工作者(worker)经常需要访问一些共享数据, 无论是内存中的或者共享的数据库中的. 线程需要以某种方式存取共享数据, 以确保某个线程的修改能够对其他线程可见(数据修改需要同步到主存中, 不仅仅将数据保存在执行这个线程的CPU的缓存中).线程需要避免竞态, 死锁以及很多其他共享状态的并发性问题. 
  补: 可持久化的数据结构是另一种选择. 在修改的时候, 可持久化的数据结构总是保护它的前一个版本不受影响
  虽然可持久化的数据结构在解决共享数据结构的并发修改时显得很优雅, 但是可持久化的数据结构的表现往往不尽人意. 
  比如说, 一个可持久化的链表需要在头部插入一个新的节点, 并且返回指向这个新加入的节点的一个引用(这个节点指向了链表的剩余部分). 所有其他现场仍然保留了这个链表之前的第一个节点, 对于这些线程来说链表仍然是为改变的. 它们无法看到新加入的元素. 
  * 无状态的工作者
  共享状态能够被系统中得其他线程修改. 所以工作者在每次需要的时候必须重读状态, 以确保每次都能访问到最新的副本, 不管共享状态是保存在内存中的还是在外部数据库中. 工作者无法在内部保存这个状态(但是每次需要的时候可以重读)称为无状态的. 
  * 任务顺序是不确定的
  并行工作者模式的这种非确定性的特性, 使得很难在任何特定的时间点推断系统的状态. 这也使得它也更难(如果不是不可能的话)保证一个作业在其他作业之前被执行. 

### 3.2 Assembly Line
![Assembly line concurrency model](/images/multithreading/Java/1-2.png)

类似于工厂中生产线上的工人们那样组织工作者. 每个工作者只负责作业中的部分工作. 当完成了自己的这部分工作时工作者会将作业转发给下一个工作者. 每个工作者在自己的线程中运行, 并且不会和其他工作者共享状态. 有时也被成为无共享并行模型. 
通常使用非阻塞的IO来设计使用流水线并发模型的系统, 因为等待IO操作结束很浪费CPU时间. 此时CPU可以做一些其他事情. 当IO操作完成的时候, IO操作的结果(比如读出的数据或者数据写完的状态)被传递给下一个工作者

* 优点
  * 无需共享的状态: 工作者之间无需共享状态, 意味着无需考虑因共享对象而产生的并发性问题. 这使得在实现worker非常容易. worker的实现与单线程上的worker无异
  * 有状态的工作者: 当工作者知道了没有其他线程可以修改它们的数据, 工作者可以变成有状态的. 因此省去了重读时间, 提高了性能
  * 较好的硬件整合: 由于每个worker的运行近似于单线程运行, 且单线程代码在整合底层硬件的时候往往具有更好的优势(通常能够创建更优化的数据结构和算法). 因此能够更好地整合硬件. 例如: 单线程有状态的工作者能够在内存中缓存数据. 在内存中缓存数据的同时, 也意味着数据很有可能也缓存在执行这个线程的CPU的缓存中. 这使得访问缓存的数据变得更快
  * 合理的作业顺序: 基于流水线并发模型实现的并发系统, 在某种程度上是有可能保证作业的顺序的. 作业的有序性使得它更容易地推出系统在某个特定时间点的状态. 因此备份、数据恢复、数据复制也就变得简单
* 缺点
流水线并发模型最大的缺点是作业的执行往往分布到多个工作者上, 并因此分布到项目中的多个类上. 这样导致在追踪某个作业到底被什么代码执行时变得困难. 并行工作者模式的代码也可能同样分布在不同的类中, 但往往也能够很容易的从代码中分析执行的顺序
 
### 3.3 Functional Parallelism
函数式并行的基本思想是采用函数调用实现程序. 函数都是通过拷贝来传递参数的, 所以除了接收函数外没有实体可以操作数据. 这对于避免共享数据的竞态来说是很有必要的. 同样也使得函数的执行类似于原子操作. 每个函数调用的执行独立于任何其他函数的调用. 
一旦每个函数调用都可以独立的执行, 它们就可以分散在不同的CPU上执行了. 这也就意味着能够在多处理器上并行的执行使用函数式实现的算法. 


## 4. 创建并运行java线程
Java线程类也是一个`Object`类, 继承自`java.lang.Thread`:
```java
Thread thread = new Thread();
thread.start();     /* 执行线程 */
```
编写线程运行时执行的代码有两种方式:
* 创建Thread子类的一个实例并重写`run()`
  ```java
  public class MyThread extends Thread {
    public void run(){
      System.out.println("MyThread running");
    }
  }

  Thread thread = new Thread(){
    public void run(){
      System.out.println("Thread Running");
    }
  };
  thread.start();
  ```
* 创建类的时候实现Interface Runnable
  ```java
  public class MyRunnable implements Runnable {
    public void run(){
      System.out.println("MyRunnable running");
    }
  }

  Thread thread = new Thread(new MyRunnable());
  thread.start();
  ```


## 5. 竞态条件
在同一程序中运行多个线程本身不会导致问题, 问题在于多个线程访问了相同的资源. 如, 同一内存区(变量, 数组, 或对象)、系统(数据库, web services等)或文件. 且这些问题只有在一或多个线程进行写操作时才有可能发生, 只要资源没有发生变化, 多个线程读取相同的资源就是安全的. 
原因在于: 操作系统何时会在两个线程之间切换, JVM并不是将一段代码视为单条指令来执行
```java
public class Counter {
  protected long count = 0;
  public void add(long value) {
    /* 下面一行代码的运行如下:
     * 1. 从内存获取 this.count 的值放到寄存器
     * 2. 将寄存器中的值增加value
     * 3. 将寄存器中的值写回内存
     */
    this.count = this.count + value;
  }
}
```
当两个线程分别加了2和3到count变量上, 两个线程执行结束后count变量的值应该等于5. 然而由于两个线程是交叉执行的, 两个线程从内存中读出的初始值都是0. 然后各自加了2和3, 并分别写回内存. 最终的值并不是期望的5
当两个线程竞争同一资源时, 如果对资源的访问顺序敏感, 就称存在竞态条件. 导致竞态条件发生的代码区称作临界区. 上述代码的`add()`即为临界区


## 6. 共享资源
允许被多个线程同时执行的代码称作线程安全的代码, 线程安全的代码充分条件就是不包含竞态条件. 竞态条件是一种共享资源, 并不是所有的共享资源都是共享资源, 以下是几种资源:

### 6.1 局部变量
局部变量存储在线程自己的栈中. 也就是说, 局部变量永远也不会被多个线程共享. 所以, 基础类型的局部变量是线程安全的

### 6.2 局部的对象引用
对象的局部引用和基础类型的局部变量不太一样. 尽管引用本身没有被共享, 但引用所指的对象并没有存储在线程的栈内. 所有的对象都存在共享堆中. 如果该对象不会被其它方法获得, 也不会被非局部变量引用到, 那么它就是线程安全的, 例如:
```java
public void someMethod() {
  LocalObject localObject = new LocalObject();
  localObject.callMethod();   /* still safe */
  method2(localObject);
}

public void method2(LocalObject localObject) {
  localObject.setValue("value");
}
```

### 6.3 对象成员
对象成员存储在堆上. 如果两个线程同时更新同一个对象的同一个成员, 那这个代码就不是线程安全的, 例如:
```java
public class NotThreadSafe {
  StringBuilder builder = new StringBuilder();
  
  public add(String text) {    /* 如果两个线程同时调用add()方法, 就会有竞态条件 */
    this.builder.append(text);
  }	
}
```
由此可总结出一个线程控制逃逸规则: 如果一个资源的创建, 使用, 销毁都在同一个线程内完成, 且永远不会脱离该线程的控制, 则该资源的使用就是线程安全的. 


## 7. 不可变性
我们可以通过创建不可变的共享对象来保证对象在线程间共享时不会被修改, 从而实现线程安全
```java
public class ImmutableValue {    /* no way to change value */
  private int value = 0;

  public ImmutableValue(int value) {
    this.value = value;
  }

  public int getValue() {
    return this.value;
  }
}
```
如果你需要对ImmutableValue类的实例进行操作, 可以通过得到value变量后创建一个新的实例来实现
```java
public class ImmutableValue {
  private int value = 0;

  public ImmutableValue(int value) {
    this.value = value;
  }

  public int getValue() {
    return this.value;
  }

  public ImmutableValue add(int valueToAdd) {
    return new ImmutableValue(this.value + valueToAdd);
  }
}
```


## 8. Monitor
### 8.1 monitor简介
Monitor是一种并发处理机制. 当某个线程进入monitor后, 先会被分配到等待区, 并基于某些标准从等待区选择一个线程进行运行区, 运行区有且只有一个线程获得数据和CPU时间

### 8.2 Java的monitor
JVM中每个对象(Object或class)通过某种逻辑关联monitor, 为实现互斥功能, 每个对象都关联一个锁. 一旦一段代码嵌入synchronized关键字中, 则意味着放入了monitor的监视区中, JVM会自动为这段代码实现锁功能
为了使线程协作, JAVA为提供了wait()和notifyAll以及notify()实现挂起线程, 并且唤醒另外一个等待的线程


## 9. Java同步块
同步块用synchronized标记. 同步块在Java中是同步在某个对象上. 同一个对象上的同步块在同时只能被一个线程执行. 所有其他等待进入该同步块的线程将被阻塞, 直到执行该同步块中的线程退出. 共有四种不同的同步块：

### 9.1 实例方法
只有一个线程能够在实例方法同步块中运行. 如果有多个实例存在, 那么一个线程一次可以在一个实例同步块中执行操作
```java
public synchronized void add(int value) {
  this.count += value;
}
```

### 9.2 静态方法
静态方法的同步是同步在该方法所在的类对象上. 因为在Java虚拟机中一个类只能对应一个类对象, 所以同时只允许一个线程执行同一个类中的静态同步方法
```java
public static synchronized void add(int value) {
  count += value;
}
```

### 9.3 实例方法中的同步块
一次只有一个线程能够在同步于同一个监视器对象的Java方法内执行
```java
public void add(int value) {
  synchronized(this) {
    this.count += value;
  }
}
```

### 9.4 静态方法中的同步块
方法同步在该方法所属的类对象上
```java
public class MyClass {
  public static void add(int value) {
    synchronized(MyClass.class) {
      count += value;
    }
  }
}
```


## 10. 线程通信
线程通信的目标是使线程间能够互相发送信号. 另一方面, 线程通信使线程能够等待其他线程的信号. 

### 10.1 通过共享对象通信
线程间发送信号的一个简单方式是在共享对象的变量里设置信号值. 线程A在一个同步块里设置boolean型成员变量, 线程B也在同步块里读取该成员变量
```java
public class MySignal{
  protected boolean hasDataToProcess = false;

  public synchronized boolean hasDataToProcess() {
    return this.hasDataToProcess;
  }

  public synchronized void setHasDataToProcess(boolean hasData) {
    this.hasDataToProcess = hasData;
  }
}
```

### 10.2 Busy Wait
线程B运行在一个循环里, 以等待这个信号: 
```java
protected MySignal sharedSignal = ...

while (!sharedSignal.hasDataToProcess()) {
  //do nothing... busy waiting
}
```

### 10.3 wait(), notify() and notifyAll()
忙等待没有对运行等待线程的CPU进行有效的利用, 除非平均等待时间非常短. 否则, 让等待线程进入睡眠或者非运行状态更为明智, 直到它接收到它等待的信号
`java.lang.Object`类定义了三个方法:
* wait(): 将调用wait()的线程变为非运行状态
* notify(): 从所有等待的线程中随机挑选一个唤醒并允许继续执行
* notifyAll(): 唤醒正在等待一个给定对象的所有线程

一个线程如果没有持有对象锁, 将不能调用`wait()`, `notify()`或者`notifyAll()`. 否则, 会抛出`IllegalMonitorStateException`异常. 一旦线程调用了`wait()`方法, 该线程就释放了所持有的monitor对象上的锁, 因为这才能允许其他线程调用`wait()`或`notify()`

```java
public class MonitorObject {}

public class MyWaitNotify {
  MonitorObject myMonitorObject = new MonitorObject();

  public void doWait() {
    synchronized(myMonitorObject) {
      try {
        myMonitorObject.wait();
      } catch (InterruptedException e) {
        /* ... */
      }
    }
  }
}
```

### 10.4 丢失的信号(Missed Signals)
如果一个线程先调用了`notify()`, 再调用`wait()`, 那么该线程将会永远等待. 为了避免丢失信号, 需要记录线程的状态
```java
public class MyWaitNotify2 {

  MonitorObject myMonitorObject = new MonitorObject();
  boolean wasSignalled = false;

  public void doWait() {
    synchronized(myMonitorObject) {
      if (!wasSignalled) {
        try {
          myMonitorObject.wait();
        } catch(InterruptedException e) { 
          /* ... */ 
        }
      }
      wasSignalled = false;   /* clear signal and continue running */
    }
  }

  public void doNotify() {
    synchronized(myMonitorObject) {
      wasSignalled = true;
      myMonitorObject.notify();
    }
  }
}
```

### 10.5 假唤醒
由于莫名其妙的原因, 线程有可能在没有调用过`notify()`和`notifyAll()`的情况下醒来. 这就是所谓的假唤醒(spurious wakeups). 为了防止假唤醒, 保存信号的成员变量将在一个while循环里接受检查, 而不是在if表达式里. 这样的一个while循环叫做自旋锁
```java
public class MyWaitNotify3 {
  MonitorObject myMonitorObject = new MonitorObject();
  boolean wasSignalled = false;

  public void doWait() {
    synchronized(myMonitorObject) {
      while (!wasSignalled) {
        try {
          myMonitorObject.wait();
        } catch(InterruptedException e) { /* ... */ }
      }
      wasSignalled = false;   /* clear signal and continue running */
    }
  }

  public void doNotify(){
    synchronized(myMonitorObject){
      wasSignalled = true;
      myMonitorObject.notify();
    }
  }
}
```

### 10.6 不要在字符串常量或全局对象中调用wait()
假设MyWaitNotify如下定义:
```java
public class MyWaitNotify {
  String myMonitorObject = "";
  boolean wasSignalled = false;

  public void doWait() {
    synchronized(myMonitorObject) {
      while(!wasSignalled) {
        try{
          myMonitorObject.wait();
        } catch(InterruptedException e){ 
          /* ... */ 
        }
      }
      wasSignalled = false;   /* clear signal and continue running */
    }
  }

  public void doNotify() {
    synchronized(myMonitorObject) {
      wasSignalled = true;
      myMonitorObject.notify();
    }
  }
}
```
不同MyWaitNotify对象中的myMonitorObject将会指向同一块内存, 也就是同一个对象, 这会导致错误的线程唤醒.


## 11. ThreadLocal
Java的ThreadLocal类可以让你创建的变量只被同一个线程进行读和写操作, 其他线程看不到该线程的ThreadLocal.

### 11.1 创建并访问ThreadLocal对象
get()方法会返回一个Object对象, 而set()方法则依赖一个Object对象参数
```java
private ThreadLocal myThreadLocal = new ThreadLocal();
myThreadLocal.set("A thread local value");
String threadLocalValue = (String) myThreadLocal.get();
```

### 11.2 ThreadLocal泛型
为了使get()方法返回值不用做强制类型转换, 通常可以创建一个泛型化的ThreadLocal对象
```java
ThreadLocal<String> myThreadLocal = new ThreadLocal();
myThreadLocal.set("Hello ThreadLocal");
String threadLocalValues = myThreadLocal.get();
```

### 11.3 初始化ThreadLocal
set()方法设置的值只对当前线程可见, 所以需通过ThreadLocal子类的实现, 并覆写initialValue()方法, 就可以为ThreadLocal对象指定一个初始化值
```java
private ThreadLocal myThreadLocal = new ThreadLocal<String>() {
  @Override protected String initialValue() {
    return "This is the initial value";
  }
};
```

### 11.4 完整代码
```java
public static class MyRunnable implements Runnable {
  private ThreadLocal<Integer> threadLocal = new ThreadLocal<>();

  @Override
  public void run() {
    threadLocal.set((int)(Math.random() * 100D));
    try {
        Thread.sleep(2000);
    } catch (InterruptedException e) { }

    System.out.println(threadLocal.get());
  }
}
```


## 12. Deadlock
### 12.1 死锁的发生
锁机制虽然避免了竞态条件, 但引发了其他问题: 死锁, 两个线程都在等待对方停止运行, 以获取对方持有的锁, 但是没有一方提前退出时, 就称为死锁. 
死锁不仅仅局限于两个线程, 也可能是多线程之间的死锁:
```text
Thread 1  locks A, waits for B
Thread 2  locks B, waits for C
Thread 3  locks C, waits for D
Thread 4  locks D, waits for A
```
当然也不仅限于线程的死锁, 可会发生在数据库连接中:
```text
Transaction 1 locks record 1 for update
Transaction 2 locks record 2 for update
Transaction 1 requests 2 for update, tries to lock record 2 for update.
Transaction 2 requests 2 for update, tries to lock record 1 for update.
```

### 12.2 避免死锁
* 加锁顺序: 死锁的导致原因就在于线程对锁的无序请求, 所以如果能确保所有的线程都是按照相同的顺序获得锁, 那么死锁就不会发生. 缺点也十分明显: 需要知道加锁顺序
* 加锁时限: 尝试获取锁的时候加一个超时时间也可作为解决死锁的方法. 若尝试获取锁的时间超过了时限, 则该线程放弃对该锁请求. 虽然实现简单, 但如果十分多的线程同一时间去竞争, 就算有超时和回退机制, 还是会导致部分线程重复地尝试却得不到锁
* 死锁检测: 该主要是针对那些不可能实现按序加锁并且锁超时也不可行的场景. 由于线程在获取到锁后会在相关数据结构中记录锁的情况, 所以当一个线程请求锁失败时, 这个线程可以遍历该数据结构, 通过构建一个锁的关系图来判断是否发生死锁. 如果检测的结果为发生死锁, 可以释放所有锁, 但这样又会再次引起死锁, 所以最好设置优先级, 让优先级较高的线程先获取锁并释放锁


## 13. 饥饿
如果一个线程因为被其他线程抢走锁而导致长时间无法执行, 则处于"饥饿"状态. 解决饥饿的方法被称为"公平性"

### 13.1 导致饥饿的原因
1. 高优先级线程吞噬低优先级线程的CPU时间: 优先级越高的线程获得的CPU时间越多, 而优先级低的进程饥饿的概率就越大
2. 线程因死锁而无法获得CPU时间: Java的同步代码区也是一个导致饥饿的因素. 只要线程中有同步区, 则线程就有可能因无法进入同步区而饥饿
3. 等待状态的线程: 如果多个线程处于等待状态, notify()又不能保证哪一个线程会被唤醒, 则任何线程都有可能因无法被唤醒而导致饥饿

### 13.2 实现公平性
1. 使用锁方式替代同步块
使用同步块时, 若有多个线程被阻塞, 则下一个解除阻塞的线程是无法保证的. 所以需要用锁替换同步块
```java
public class Lock{
  private boolean isLocked = false;
  private Thread lockingThread = null;

  /* 锁的实现依然靠同步块 */
  public synchronized void lock() throws InterruptedException{
    while(isLocked){
      wait();
    }
    isLocked = true;
    lockingThread = Thread.currentThread();
  }

  public synchronized void unlock(){
    if(this.lockingThread != Thread.currentThread()){   /* 不同锁不可互相使用 */
      throw new IllegalMonitorStateException("Calling thread has not locked this lock");
    }
    isLocked = false;
    lockingThread = null;
    notify();
  }
}

public class Synchronizer{
  Lock lock = new Lock();
  public void doSynchronized() throws InterruptedException{
    this.lock.lock();
    /* critical section, do a lot of work which takes a long time */
    this.lock.unlock();
  }
}
```

2. 公平锁
将上面Lock类转变为公平锁FairLock, 主要修改了wait()和notify()部分
```java
/* QueueObject作为一个Semaphore
 * 每个线程独占一个QueueObject对象, 用于有序的加锁
 */
public class QueueObject {
  private boolean isNotified = false;

  public synchronized void doWait() throws InterruptedException {
    while (!isNotified){
      this.wait();
    }
    this.isNotified = false;
  }

  public synchronized void doNotify() {
    this.isNotified = true;
    this.notify();
  }

  public boolean equals(Object obj) {
    return this == obj;
  }
}

public class FairLock {
    private boolean isLocked = false;       /* 该锁是否使用 */
    private Thread lockingThread = null;    /* 正在使用锁的线程 */
    /* 通过队列依次加锁, 这样线程可依次争夺锁, 做到公平性 */
    private List<QueueObject> waitingThreads = new ArrayList<>();

  public void lock() throws InterruptedException{
    QueueObject queueObject = new QueueObject();
    boolean isLockedForThisThread = true;   /* 是否需要加锁 */
    synchronized(this) {
      waitingThreads.add(queueObject);
    }

    while (isLockedForThisThread) {   /* 是否需要加锁 */
      synchronized(this){
        isLockedForThisThread = /* 该lock是否已使用 或 是否轮到该线程加锁 */
          isLocked || waitingThreads.get(0) != queueObject;
        if (!isLockedForThisThread) { /* 切换到不需要加锁, 因为即将要加锁 */
          isLocked = true;    
          waitingThreads.remove(queueObject);     /* 从等待加锁的队列中移出 */
          lockingThread = Thread.currentThread();
          return;
        }
      }

      try {
        queueObject.doWait();   /* 等待加锁 */
      } catch(InterruptedException e) { 
        synchronized(this) { 
          waitingThreads.remove(queueObject); 
        }
        throw e;
      }
    }
  }

  public synchronized void unlock() {
    if (this.lockingThread != Thread.currentThread()) {   /* 不匹配的lock */
      throw new IllegalMonitorStateException("Calling thread has not locked this lock");
    }
    isLocked = false;
    lockingThread = null;
    if (waitingThreads.size() > 0) {
      waitingThreads.get(0).doNotify();   /* 仅有一个线程被唤醒 */
    }
  }
}
```


## 14. Nested Monitor Lockout(嵌套管程锁死)
### 14.1 可能导致的情况
当我们使用两个嵌套的同步块时应小心Nested Monitor Lockout, 下面是一个可能发生的情况:
```java
/* Implementation of Lock */
public class Lock {
  protected MonitorObject monitorObject = new MonitorObject();
  protected boolean isLocked = false;

  public void lock() throws InterruptedException {
    synchronized(this) {
      while(isLocked) {
        synchronized(this.monitorObject) {
          this.monitorObject.wait();
        }
      }
      isLocked = true;
    }
  }

  public void unlock() {
    synchronized(this) {
      this.isLocked = false;
      synchronized(this.monitorObject) {
        this.monitorObject.notify();
      }
    }
  }
}
```
当线程A获得this的锁, 想要获得monitorObject的锁, 但线程B拥有monitorObject的锁, 所以需要等待线程B释放monitorObject; 线程B想要释放monitorObject, 但需要先获得线程A拥有的this的锁. 从而陷入锁死

### 14.2 Nested Monitor Lockout VS Deadlock
* 共同点: 线程都进入一直阻塞的状态
* 不同点: 死锁是由于多线程获取锁的顺序不同导致; 嵌套管程锁死获取锁的顺序一致, 但由于一个线程等待唤醒, 而另一个等待锁释放, 所以导致锁死


## 15. Slipped Conditions(丢失的条件)
Slipped conditions的意思是, 当一个线程从检查某一特定条件到该线程执行该条件下的语句时, 该条件已经被其他线程修改, 导致线程进行错误操作, 以下是一个例子:
```java
public class Lock {
  private boolean isLocked = true;

  public void lock() {
    synchronized(this) {   /* (1) */
      while(isLocked) {
        try {
          this.wait();
        } catch (InterruptedException e) {
          //do nothing, keep waiting
        }
      }
    }
    synchronized(this) {   /* (2) */
      isLocked = true;
    }
  }

  public synchronized void unlock() {
    isLocked = false;
    this.notify();
  }
}
```
上述`lock()`的实现中有两个同步块, 分别名为同步块1和同步块2. 线程A首先进入同步块1中, 由于isLocked此时为false, 所以线程A无需进入等待状态. 在线程A进入同步块2之前, 线程B抢先拿到了this锁, 进入同步块1. 由于线程A还未修改isLocked参数, 所以线程B也未进入等待状态, 这样导致Lock的互斥功能失效, 发生了Slipped conditions.
修改方法很简单, 只需要将两个同步块合并为一个即可, 这样就杜绝了条件修改前有其他线程获得锁:
```java
public class Lock {
  private boolean isLocked = true;

  public void lock() {
    synchronized(this) {
      while(isLocked) {
        try {
          this.wait();
        } catch (InterruptedException e) {
          //do nothing, keep waiting
        }
      }
      isLocked = true;
    }
  }

  public synchronized void unlock() {
    isLocked = false;
    this.notify();
  }
}
```



## 16. Java中的Lock
锁与synchronized同步块作用相同, 都是一种线程同步机制. 从Java 5后, **java.util.concurrent.locks**包中包含了很多锁的实现, 所以不必再使用synchronized同步块来实现自己的锁

### 16.1 Lock和Synchronized Block的区别
* 同步块必须以函数的形式包裹代码; Lock调用`lock()`和`unlock()`来包裹代码
* 同步块不支持公平性, 无法确定下一个进入同步块的线程是哪一个; 但Lock包含很多提供公平性的属性, 可通过设置这些属性来达到公平性
* 当线程无法进入同步块时会被阻塞; Lock提供了一个非阻塞的函数`tryLock()`, 可使用该函数询问锁当前是否可用: 如果可用则返回true, 不可用则返回false. 这样减少了许多阻塞时间
* 当线程处于等待进入同步块的阻塞状态时无法被中断; Lock提供了`lockInterruptibly()`来中断阻塞
* 同步块在任何异常的情况下都会解除monitor上的锁; Lock在发生异常时不会自动调用`unlock()`, 需手动调用

### 16.2 使用Java锁
以下为同步块和lock实现线程同步的代码:
```java
/* Synchronized Block */
public class Counter {
  private int count = 0;

  public int inc() {
    synchronized(this) {
      return ++count;
    }
  }
}

/* Lock */
public class Counter {
  private Lock lock = new Lock();
  private int count = 0;

  public int inc(){
    lock.lock();
    int newCount = ++count;
    lock.unlock();
    return newCount;
  }
}
```

### 16.3 锁的可重入性
Java的同步块时可重入的. 重入性: 当一个线程进入同步块后, 可以再次进入由同一monitor同步的另一个同步块中. 例如:
```java
public class Reentrant{
  public synchronized void f1() {
    f2();
  }

  public synchronized void f2() { 
    /* do something */ 
  }
}
```
`f1()`和`f2()`都由this的monitor同步, 当某线程进入`f1()`后, 说明该线程获得了this的monitor上的锁, 则进入`f2()`时不被阻塞
```java
public class Reentrant2{
  Lock lock = new Lock();

  public void f1(){
    lock.lock();
    f2();
    lock.unlock();
  }

  public void f2(){
    lock.lock();
    //do something
    lock.unlock();
  }
}
```
如果是简单的Lock实现, 则上述代码会被阻塞. 因为在`f1()`函数中`lock()`会将lock.isLocked设置为true, `f2()`的`lock()`则会阻塞. 为了实现可重入性, 需要对Lock实现进行一些改动:
```java
public class Lock{
  boolean isLocked = false;
  Thread  lockedBy = null;    /* 记录锁的持有者, 实现可重入性的关键 */
  int lockedCount = 0;

  public synchronized void lock() throws InterruptedException{
    Thread callingThread = Thread.currentThread();
    while (isLocked && lockedBy != callingThread) {   /* 可重入性检测 */
      wait();
    }
    isLocked = true;
    lockedCount++;
    lockedBy = callingThread;
  }

  public synchronized void unlock() {
    if (Thread.currentThread() == this.lockedBy) {
      lockedCount--;

      if(lockedCount == 0){
        isLocked = false;
        notify();
      }
    }
  }
}
```

### 16.4 finally中调用unlock()
如果Lock保护的临界区可能抛出异常, 那么必须在finally中调用`unlock()`, 否则该Lock对象永远无法解锁
```java
lock.lock();

try {
  //do critical section code which may throw exception
} finally {
  lock.unlock();
}
```


## 17. 读写锁
Java的Lock虽然能实现多线程的同步, 但有时写操作没有读操作那么频繁, 所以需要多个线程同时读取资源, 但写操作不能和其他操作同时进行. 因此需要引入读写锁

### 17.1 读写锁的简单实现
读写锁的访问资源有两个方面:
* 读取: 当前没有写操作进行, 且没有写操作的请求
* 写入: 没有线程进行读写操作

由于读操作较为频繁, 所以需要提高写操作的优先级. 一旦出现写操作的锁申请, 则不能给读操作分配锁
```java
public class ReadWriteLock {
  private int readers = 0;
  private int writers = 0;
  private int writeRequests = 0;

  /* 无写操作和写操作请求时可申请读操作锁 */
  public synchronized void lockRead() throws InterruptedException{
    while(writers > 0 || writeRequests > 0) {
      wait();
    }
    readers++;
  }
  
  public synchronized void unlockRead() {
    readers--;
    notifyAll();  /* 唤醒所有线程, 这样能使得所有读操作立即获得读锁 */
  }
    
  /* 无其他读写操作时可申请写操作锁, 否则增加一个写操作申请 */
  public synchronized void lockWrite() throws InterruptedException {
    writeRequests++;

    while(readers > 0 || writers > 0) {
      wait();
    }
    writeRequests--;
    writers++;
  }

  public synchronized void unlockWrite() throws InterruptedException {
    writers--;
    notifyAll();
  }
}
```

### 17.2 读锁的重入
上述的读写锁并不是可重入的, 对于一个已经持有写锁的线程来说, 如果该线程再次申请写锁时会被阻塞. 而且读写锁的重入性可能导致锁死, 如下:
1. 线程A持有读锁
2. 线程B请求写锁, 但由于线程A持有读锁, 所以写锁被阻塞
3. 线程A再次请求读锁, 但由于线程B的写锁请求, 导致读锁重入失败, 被阻塞

解决这种锁死的思路很简单: 提高重入性的优先级. 在上一节中, 写锁的申请优先级高于读锁的优先级, 在引入重入性后, 写锁和重入的优先级比较没有确定. 为了打破死锁, 需要让读锁的申请规则改变, 让读锁重入性的优先级高于写锁的优先级:
1. 若没有写锁或没有写锁的申请, 则分配读锁
2. 若已有读锁, 则无视写请求, 直接分配读锁

```java
/*
 * 利用map记录该线程是否持有锁和获取锁的次数
 */
public class ReadWriteLock{
  private Map<Thread, Integer> readingThreads = new HashMap<>();
  private int writers = 0;
  private int writeRequests = 0;

  public synchronized void lockRead() throws InterruptedException{
    Thread callingThread = Thread.currentThread();
    /* 检测获取读锁的条件是否符合 */
    while (!canGrantReadAccess(callingThread)) {  
      wait();
    }

    readingThreads.put(callingThread, 
      (readingThreads.getOrDefault(callingThread, 0) + 1));
  }

  public synchronized void unlockRead() {
    Thread callingThread = Thread.currentThread();
    int accessCount = readingThreads.getOrDefault(callingThread, 0);
    if (accessCount == 1) {
      readingThreads.remove(callingThread);
    } else {
      readingThreads.put(callingThread, accessCount - 1);
    }
    notifyAll();
  }

  private boolean canGrantReadAccess(Thread callingThread){
    /* 无写入操作 - 基本条件 */
    if (writers > 0) return false;
    
    /* 重入检测 - 高优先级防死锁 */
    if (readingThreads.get(callingThread) != null) 
      return true;
    
    /* 非重入时 - 先让给写操作 */
    return !(writeRequests > 0);                
  }
}
```

### 17.3 写锁的重入性
写锁的重入性实现比较简单, 因为重入写锁时并没有阻塞, 只需要记录写锁和当前线程的关系即可
```java
public class ReadWriteLock{
  private Map<Thread, Integer> readingThreads = new HashMap<Thread, Integer>();
  private int writeAccesses = 0;
  private int writeRequests = 0;
  private Thread writingThread = null;    /* 写锁和当前线程的关系 */

  public synchronized void lockWrite() throws InterruptedException{
    writeRequests++;
    Thread callingThread = Thread.currentThread();
    while(!canGrantWriteAccess(callingThread)){ /* 判断是否可获取写锁 */
      wait();
    }
    writeRequests--;
    writeAccesses++;
    writingThread = callingThread;
  }

  public synchronized void unlockWrite() throws InterruptedException{
    writeAccesses--;
    if(writeAccesses == 0){
      writingThread = null;
    }
    notifyAll();
  }

  private boolean canGrantWriteAccess(Thread callingThread){
    /* 无读锁存在 - 基本条件 */
    if(readingThreads.size() > 0) 
      return false;

    /* 无读锁也没写锁 */
    if(writingThread == null)
      return true;

    /* 实现重写性 */
    return writingThread == callingThread;
  }
}
```

### 17.4 读锁升级到写锁
读锁升级为写锁的唯一条件: 该线程是唯一一个拥有读锁的线程. 因为此时:
1. 没有线程拥有写锁, 因为有读锁存在, 可升级写锁
2. 该线程的读锁升级完写锁后, 不存在其他读锁, 实现写锁的排他性

```java
public class ReadWriteLock{
  private Map<Thread, Integer> readingThreads = new HashMap<Thread, Integer>();
  private int writeAccesses    = 0;
  private int writeRequests    = 0;
  private Thread writingThread = null;

  public synchronized void lockWrite() throws InterruptedException {
    writeRequests++;
    Thread callingThread = Thread.currentThread();
    while (!canGrantWriteAccess(callingThread)) {
      wait();
    }
    writeRequests--;
    writeAccesses++;
    writingThread = callingThread;
  }

  public synchronized void unlockWrite() throws InterruptedException {
    writeAccesses--;
    if (writeAccesses == 0) {
      writingThread = null;
    }
    notifyAll();
  }

  private boolean canGrantWriteAccess(Thread callingThread) {
    if (isOnlyReader(callingThread)) return true;    /* 读锁升级为写锁 */
    if (readingThreads.size() > 0) return false;     /* 读锁数量大于等于1 */
    if (writingThread == null) return true;          /* 无读锁的情况下申请写锁 */
    return writingThread == callingThread;          /* 重入性 */
  }

  private boolean isOnlyReader(Thread callingThread) {
    return readingThreads.size() == 1 && readingThreads.get(callingThread) != null;
  }
}
```

### 17.5 写锁降级为读锁
写锁降为读锁没有任何风险, 只要修改一下判断条件即可
```java
public class ReadWriteLock{
  private boolean canGrantReadAccess(Thread callingThread) {
    /* 写锁降级为读锁 */
    if (writingThread == callingThread) 
      return true;

    /* 已有写锁 */
    if (writingThread != null) 
      return false;
    
    /* 重入性 */  
    if (isReader(callingThread))
      return true;

    /* 写锁请求 */
    return writeRequests == 0;
  }
}
```

### 17.6 在finally中调用unlock()
由于临界区可能发生异常导致没有解锁, 所以需要在finally中调用`unlock()`
```java
lock.lockWrite();

try {
  //do critical section code, which may throw exception
} finally {
  lock.unlockWrite();
}
```
