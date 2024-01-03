---
title: Java Basic (2)
category:
  - Java
  - Basic
tag:
  - Java
abbrlink: b093
date: 2017-10-30 15:51:18
---

## 1. Nested Class
```java
class OuterClass{
  class InnerClass{}
  static class InnerClass2{}
}

public class test {
  public static void main(String[] args){
  OuterClass outer = new OuterClass();
  OuterClass.InnerClass inner = outer.new InnerClass();
  OuterClass.InnerClass2 inner2 = new OuterClass.InnerClass2();
}
```
内部类可以为private或protected, 若不想让对象访问内部类, 可将内部类声明为private.


## 2. Access of derived class method
derived class覆盖(override)方法时, 不能降低方法的访问权限:
* 若base class中方法为`public`, 则derived class中方法必须为`public`
* 若base class中方法为`protected`, 则derived class中方法可为`public`或`protected`
* 若base class中方法为`private`, 则derived class无法覆盖该方法


## 3. Order for Initialization
以下为类成员初始化顺序:
1. base class中的static block
2. derived class中的static block 
3. base class中的initializer block
4. base class中的constructor
5. derived class中的initializer block
6. derived class中的constructor

```java
class B extends Object
{
  static {
    System.out.println("Load B");
  }
  public B() { System.out.println("Create B"); }
}
class A extends B
{
  static {
    System.out.println("Load A");
  }
  public A() { System.out.println("Create A"); }
}
 
public class Testclass
{
  public static void main(String[] args){
    new A();    
    /* Load B 
     * Load A
     * Create B
     * Create A
     */
  }
}
```


## 4. constructor of enum
枚举的constructor默认为private, 只接受一个字符串值, 因此无法显式调用.
```java
enum AccountType
{
  SAVING, FIXED, CURRENT;
  private AccountType()
  {
    System.out.println("It is a account type");
  }
}

class EnumOne
{
  public static void main(String[]args)
  {
    System.out.println(AccountType.FIXED);
    /* 枚举类有三个实例, 故调用三次构造方法
     * It is a account type
     * It is a account type
     * It is a account type
     * FIEXED
     */
  }
}
```


## 5. HashTable and HashMap
以下是Hashtable和Hashmap的不同:
* 父类不同: Hashtable是Dictionary的子类; Hashmap是AbstructMap的子类
* 是否并发: HashTable支持并发, Hashmap不支持并发
* key和value: Hashtable不允许key和value为null; Hashmap允许key为null, 但只能存在一个, value可为null. 
* 遍历方式: Hashtable和Hashmap都可使用Iterator, 但Hashtable还是用Enumeration的方式遍历
* 哈希值: Hashtable使用对象的`hashCode()`; Hashmmap需重新计算hash值
6. 默认大小和扩容方式: Hashtable默认大小为11, 扩容方式为`2*old+1`; Hashmap默认为16, 扩容方式为2的指数大小


## 6. Thread Notification
* Object
    * wait()
    * notify()
    * notifyAll()
* Condition
    * wait()
    * signal()
    * signalAll()


## 7. Static Method/Instance Method
* static method是属于整个类的, 可直接调用
* instance method属于某个对象, 所以instance method中不能调用static method


## 8. call derived class's method from base class
```java
public class Test {  
  public static void main(String [] args) {  
    System.out.println(new B().getValue());  
  }

  static class A {  
    protected int value;  
    public A(int v) {  
      setValue(v);  
    }

    public void setValue(int value) {  
      this.value = value;  
    }

    public int getValue() {  
      try{  
        value++;  
        return value;  
      } catch(Exception e){  
        System.out.println(e.toString());  
      } finally {  
        this.setValue(value); // 调用B.setValue()
        System.out.println(value);  
      }  
      return value;  
    }  
  }

  static class B extends A {  
    public B() {  
      super(5);  
      setValue(getValue() - 3); // 调用B.setValue()
    }

    public void setValue(int value){  
      super.setValue(2 * value);  
    }  
  }  
}  
```


## 9. abstract class
抽象类并不是只能有抽象方法, 也可以有成员变量和普通的类方法. 但有三点和普通类不同:
1. 抽象方法必须是public或protected
     1. JDK 1.8之前默认为public
     2. JDK 1.8之后默认为default
2. 抽象类不能创建对象
3. 子类必须实现父类的抽象方法, 否则必须声明为抽象类
4. 抽象类中也可以没有抽象方法


## 10. 方法访问权限
修饰符 | class | Package | Subclass | other
-----|-----|-----|-----|-----
public | Y  | Y | Y | Y
protected | Y | Y | Y | N
无修饰符 | Y | Y | N | N
private | Y | N | N | N


## 11. String Comparsion
```java
public class StringDemo{
  private static final String s1 = "abcd";
  public static void main(String [] args{
    String s2 = "abcd";
    String s3 = "ab";
    String s4 = "cd";
    System.out.println(s1==s2);     // true, 都是常量
    System.out.println("ab"+"cd"==s1);  // true, 会自动将=左边优化为String常量
    System.out.println(s3+s4==s1);  // false, s3+s4不会被优化, 而是在堆上生成String
  }
}
```


## 12. wrapper
1. wrapper在不遇到算数运算时不会自动拆箱
2. wrapper的`equals()`不进行类型转换
  ```java
  Integer i = 42;
  Double d = 42.0;
  System.out.println(i==d); // false
  System.out.println(i.equals(d)); // false
  ```


## 13. base class reference refer to derived class object
指向子类的父类引用不能调用子类的函数
```java
class Base{}

class Son extends Base {
  public void method(){}
}

public class Test {
  public static void main(String[] args){
    Base base = new Son();
    base.method(); // error, 因为base为父类引用, 无法调用子类的函数
  }
}
```
有时多态会导致输出结果异常
```java
public class Base {
  private String baseName = "base";

  public Base() {
    callName(); // 调用Sub的callName()
  }

  public void callName() {
    System.out.println(baseName);
  }

  static class Sub extends Base { // 先初始化Base, 再初始化Sub
    private String baseName = "sub";
    public void callName() {
      System.out.println(baseName); // 由于basename还没初始化, 输出null
    }
  }

  public static void main(String[] args){
    Base b = new Sub(); // 输出null
  }
}
```


## 14. interface access modifiers
1. JDK 1.8之前, 接口方法只能被public修饰
2. JDK 1.8时, 接口方法可被public和default修饰
3. JDK 1.9时, 接口方法可被public, default, private

内部接口的方法只能为public, default, protected, private, abstract, static


## 15. abstract class vs. interface
以下是抽象类和接口的不同之处:
1. 抽象类可有构造方法, 接口不能
2. 抽象类可包含非抽象的普通方法, 接口不能
3. 抽象类可有普通成员变量, 接口不能
4. 抽象类中抽象方法的访问类型可为public, protected和默认类型, 接口的方法只能为public
5. 抽象类可有静态方法, 接口不能
6. 一个类可实现多个接口, 只能继承一个抽象类

以下为相同之处:
1. 抽象类和接口都可包含静态成员变量
2. Java8中的接口可有default方法


## 16. Byte Stream and Character Stream
Byte Stream: 以**stream**结尾
* InputStream:
* FileInputStream
* BufferInputStream
* DataInputStream
* ObjectInputStream

Character Stream(根据编码集解析获得的字节流): 以**reader**或**writer**结尾
* InputStreamReader
* BufferedReader
* OutputStreamWriter
* BufferedWriter
* PrintWriter


## 17. create thread
1. class A继承Thread类, 重写`run()` 
  ```java
  new A().start() // 执行线程
  ```
2. class A实现Runnable接口, 实现`run()`
  ```java
  new Thread(new A()).start() // 执行线程
  ```


## 18. default initialization
1. 基础类型, 0
2. 布尔类型, false
3. 引用类型, null


## 19. Object Methods
1. public:
    1. Object()
    2. getClass()
    3. equals()
    4. hashCode()
    5. toString()
    6. notify()
    7. notifyAll()
    8. wait()
2. protected:
    1. finalize()
    2. protected
3. private:
    1. registerNatives()


## 20. primitive data type
1. byte
2. short
3. int
4. long
5. float
6. double
7. boolean
8. char


## 21. class file
Java会为`.java`文件中的每个类和接口生成一个`.class`文件, 包括内部类和静态类.


## 22. Nested Class
1. 外部类不能用static来修饰, 内部类可用static修饰
2. 外部类只能用public和默认访问权限来修饰, 内部类可用public, private, protected和默认访问权限
3. 局部内部类
    ```java
    public class Test1 {
      private final int a = 1;
      private static int b = 2;
      private int c = 3;

      void func() {
        class Test2 {
          Test2() {
            System.out.println(a+" "+b+""+c);
            b = 2;
            c = 3;
          }
        }
      }

      void func2() {
        // Test2 t2 = new Test2();      // 方法外不能生成类实例
      }
    }
    ```
    1. 不能从方法外部调用
    2. 不能访问非final局部变量(jdk1.8可以访问非final局部变量)
    3. 不能设置任何访问权限(public, protected, private和static都不可以), 但可以设置为final
4. non-static内部类
    ```java
    public class Test1 {
      private final int a = 1;
      private static int b = 2;
      private int c = 3;
      private Test3 t3 = new Test3();
      private int d = t3.a1;

      class Test3{
        private int a1 = 1;
        public void show(){
          System.out.println(a+" "+b+" "+c);
        }
      }

      public static void main(String[] args){
        Test1 t1 = new Test1();
        Test3 t3 = t1.new Test3();
      }
    }
    ```
    1. 内部类可设置访问权限(public, protected,private都可以)
    2. 内部类可访问外部类的变量和方法
    3. 内部类在外部类中留下一个引用, 外部类可引用内部类
    4. 创建内部类对象需要外部类对象
5. static内部类
    ```java
    public class Test1 {
      private final int a = 1;
      private static int b = 2;
      private int c = 3;
      private Test3 t3 = new Test3();
      private int d = t3.a1;

      static class Test3{
        private int a1 = 1;
        public void show(){
          // System.out.println(a);   // error, 不能调用外部类的成员变量
          System.out.println(b);
          // func();                  // error, 不能调用外部类的成员函数
        }
      }
      
      void func(){};

      public static void main(String[] args){
        Test3 t3 = new Test3();
      }
    }
    ```
    1. 内部类可设置访问权限
    2. 不能使用外部类的non-static成员变量和方法
    3. 创建不需要依赖外部类
    4. 外部类可创建内部类实例并访问变量和方法
6. 匿名内部类
    ```java
    interface inter{
      void get_number(int i);
    }

    public class Test1 {
      private final int a = 1;
      private static int b = 2;
      private int c = 3;

      inter func(int num){
        return new inter(){
          public void get_number(int i){
            System.out.println(i+num);
            System.out.println(a+b+c);
          }
        };
      }

      public static void main(String[] args){
        Test1 t1 = new Test1();
        inter i1 = t1.func(1);
        i1.get_number(1);
      }
    }
    ```
    1. 可访问外部类的变量和方法
    2. 没有构造方法
    3. 没有访问修饰符
