---
title: JVM (2)
category:
  - Java
  - JVM
tag:
  - Java
abbrlink: a4a2
date: 2017-11-08 08:58:48
---

## 1. Class文件与JDK的版本
JDK版本 | Class文件版本(major.minor)
-----|-----
1.0 | 45.3
1.1 | 45.3
1.2 | 46.0
1.3 | 47.0
1.4 | 48.0
5 | 49.0
6 | 50.0
7 | 51.0
8 | 52.0


## 2. Java虚拟机
1. 必须遵循Java虚拟机规范
2. 多种实现, 例如: HotSpot, J9, JRockit
  * 必须符合JVM规范
  * JVM规范之外的细节可自行实现
  * 必须通过JCK测试才能成为Java VM
3. 只有符合规范的Class文件才能执行, 否则报错
4. 可支持其他语言, 例如: Scala、Clojure、Groovy、Fantom、Fortress、Nice、Jython、JRuby、Rhino、Jaskel


## 3. Java虚拟机字节码
1. 相当于传统编译器的中间代码(例如C++编译器优化时生成的中间代码)
2. 基于栈的指令集体系结构
  * 代码紧凑
  * 方便实现高移植性的解释器
  * 相对于基于寄存器的体系结构来说速度上较慢
3. 指令不定长(1-4字节)
4. 设计目标
  * 易于校验
  * 易于编译
  * 易于解释执行
  * 易于移植
  * 包含大量类型信息
5. 指令类别
  * 局部变量读/写
  * 算数与类型转换
  * 条件/无条件跳转
  * 对象创建和操作
  * 数据创建和操作
  * 方法调用
  * 栈操作(操作数栈)


## 4. 基于栈 VS 基于寄存器
1. 保存临时值的位置不同
  * 基于栈: 将临时值保存在栈上
  * 基于寄存器: 将临时值保存在寄存器上
2. 代码所占的体积不同
  * 基于栈: 代码紧凑, 单个条目体积小, 但条目数多
  * 基于寄存器: 代码较大, 但条目数少
```java
/* 实现20+7 */
/* Stack-Based */
POP 20
POP 7
ADD 20, 7, result
PUSH result

/* Register-Based */
ADD R1, R2, R3
```
3. 栈的名称在不同的虚拟机中有所不同
  * HotSpot中成为"表达式栈"(expression stack)
  * JVM中称为"操作数栈"(operand stack)


## 5. Class文件结构
```java
ClassFile {
  u4 magic;                 /* 0xCAFEBABE, magic number */
  u2 minor_version;         /* 大版本号 */
  u2 major_version;         /* 小版本号 */
  u2 constant_pool_count;   /* constant_pool中的entry数量+1 */ 
  cp_info constant_pool [constant_pool_count-1];  /* 包含String, 类和接口名, field名称和其他constant. index范围: [1 - constant_pool_count-1] */
  u2 access_flags;          /* 标记该Class/Interface的访问权限, 如果为ACC_INTERFACE则说明是interface, 否则为class */
  u2 this_class;            /* 一个index, 表示constant_pool中的CONSTANT_Class_info */
  u2 super_class;           /* 0或者是constant_pool中的一个index */
  u2 interfaces_count;      /* 直接实现的interface数量(对于class和interface都有) */
  u2 interfaces[interfaces_count];  /* interface在constant_pool中的index */
  u2 fields_count;          /* fields中fields_count的数量 */
  field_info fields[fields_count];  /* 包含fields_count个field_info */
  u2 methods_count;         /* method_info的数量 */
  method_info methods[methods_count]; /* 包含methods_count个method_info */
  u2 attributes_count;      /* attribute_info的数量 */
  attribute_info attributes[attributes_count];  /* 包含attributes_count个attribute_info */
}
```

### 5.1 constant_pool结构
* constant_pool_count
* constant_pool
  * cp_info
    * tag - 类型
    * info - 具体内容

### 5.2 access_flags:
* access_flags占两字节(16位), 各个访问权限占其中的一位. 例如:
```java
/* access_flags: 0x0600 = ACC_INTERFACE(0x020) + ACC_ABSTRACT(0x0400) 
 * 由于ACC_INTERFACE表示这是一个interface, 所以必然有ACC_ABSTRACT.
 * 必然不能有ACC_FINAL, ACC_SUPER, ACC_ENUM
 */
interface TestInterface{}

/* access_flags: 0x0021 = ACC_PUBLIC(0x0001) + ACC_SUPER(0x0020) */
public class Test {
  public static void main(String[] args){}
}
/* ACC_SUPER只是为了向前兼容性, JVM并不处理该flag */
```

### 5.3 Constant Pool
* CONSTANT_Class_info
    * u1 tag: 7
    * u2 name_index: 指向constant_pool中的一个CONSTANT_Utf8_info
* CONSTANT_Fieldref_info, CONSTANT_Methodref_info和CONSTANT_InterfaceMethodref_info
    * CONSTANT_Fieldref_info
        * u1 tag: 9
        * u2 class_index: 指向constant_pool中的一个CONSTANT_Class_info
        * name_and_type_index: 指向constant_pool中的一个CONSTANT_NameAndType_info
    * CONSTANT_Methodref_info
        * u1 tag: 10
        * u2 class_index: 同上
        * u2 name_and_type_index: 同上
    * CONSTANT_InterfaceMethodref_info
        * u1 tag: 11
        * u2 class_index: 同上
        * u2 name_and_type_index: 同上
* CONSTANT_String_info
  * u1 tag: 8
  * u2 string_index: 指向constant_pool中的一个CONSTANT_Utf8_info
* CONSTANT_Integer_info和CONSTANT_Float_info
  * CONSTANT_Integer_info
    * u1 tag: 3
    * u4 bytes: 4字节的int
  * CONSTANT_Float_info
    * u1 tag: 4
    * u4 bytes: 4字节的float
* CONSTANT_Long_info和CONSTANT_Double_info
  * CONSTANT_Long_info
    * u1 tag: 5
    * u4 high_bytes
    * u4 low_bytes
  * CONSTANT_Double_info
    * u1 tag: 6
    * u4 high_bytes
    * u4 low_bytes
* CONSTANT_NameAndType_info
  * u1 tag: 12
  * u2 name_index: 指向constant_pool中的一个CONSTANT_Utf8_info, 代表类/接口的函数名
  * u2 descriptor_index: 指向constant_pool中的一个CONSTANT_Utf8_info, 代表类/接口的descriptor(descriptor=参数+返回值)
* CONSTANT_Utf8_info
  * u1 tag: 1
  * u2 length: 字节数
  * u1 bytes[length]: 包含length个字节的字符数组
* CONSTANT_MethodHandle_info
  * u1 tag: 15
  * u1 reference_kind: 范围是[1-9], 表示某个method handle
  * u2 reference_index: 指向constant_pool中的一个entry, 根据reference_kind来决定entry的类型
* CONSTANT_MethodType_info
  * u1 tag: 16
  * u2 descriptor: 指向constant_pool中的一个CONSTANT_Utf8_info, 表示一个method descriptor
* CONSTANT_InvokeDynamic_info
  * u1 tag: 18
  * u2 bootstrap_method_attr_index: 表示bootstrap_methods的一个index
  * u2 name_and_type_index: 指向constant_pool中的一个CONSTANT_NameAndType_info, 表示一个method name和method descriptor


## 6. Frames(栈帧)
### 6.1 功能
用于存储数据和临时结果, 也用来操作动态链接, 返回值和分派异常(对于method)

### 6.2 组合部分
* Local variable
* Operand stack
* 指向常量池中已解析的方法引用
* 其他信息:
  * Current method指针
  * Local variable指针
  * Constant pool指针
  * returnAddress指针
  * Operand Stack顶部指针
  * 等等

### 6.3 其他
1. 每次有方法被调用时就会创建一个frame, 当method运行完毕后就会销毁frame(无论method正常结束或异常结束). Frame在单个线程中的JVM stacks分配空间(保证线程独立), 每个frame有自己的local variable, operand stack和一个run-time constant pool的引用(当前线程的class)
2. local variable和operand stack的大小在编译时就确定了, frame的大小依赖于JVM的实现.
3. thread, method和frame有两种状态: current和非current. 如果当前thread的某个method运行中, 则当前class, method和所对应的frame被称为current class, current method和current frame


## 7. Local Variables
### 7.1 功能
位于Frame中. 将变量放在一个数组中, 数组单元称为slot(每个slot长度为32位), 数组的长度在编译时就固定下来. 变量通过数组索引访问(以0为初始索引值)

### 7.2 其他
1. boolean, byte, char, short, int, float, reference和returnAddress占一个slot. long和double占两个slot(连续分配, 如果某long值的索引值为n, 则占用数组中n和n+1)
2. 除了临时变量和参数, 还会存放临时返回值, ret指令的返回值
3. 一个slot在一个方法中可以分配给多个变量使用, 只要这些变量的作用域不重叠就可以, 与变量类型无关


## 8. Operand Stacks
### 8.1 功能
位于Frame中. 作为一个LIFO的栈, 用于实现opcode的操作用的栈. 在编译时深度就固定

### 8.2 其他
1. Operand Stack刚被创建时为空, opcode就会将local variable或fields中的局部变量或常量放入Operand Stack中. Operand Stack也用来将一个method的result传递给另一个method作为参数
2. Operand Stack的每一个entry能包含任意JVM type, 包括long和double
3. Operand Stack中的值必须使用正确的类型处理, 例如: 放入两个int值时, 不能将int值作为long或double类型放入. 但也有部分opcode(dup, swap)不以特定类型处理entry


## 9. Dynamic Linking
每个frame都有run-time constant pool中的一个引用. 该引用是为了支持method code的dynamic linking. Dynamic linking将symbolic method reference转换为concrete method reference, 将为解析某些符号而加载类, 并将变量的访问变为内存中的偏移量


## 10. 普通函数的调用
一共有五个指令能调用函数:
* invokevirtual: 根据对象的类型分派方法
* invokeinterface: 调用一个interface的方法
* invokespecial: 调用一个特殊的对象方法, 例如: 初始化方法, private方法, superclass方法
* invokestatic: 调用一个类方法(静态方法)
* invokdynamic: 执行invokedynamic call site时调用的指令, 将call site与某个bootstrap method关联, 有这个bootstrap method来返回一个对象(包含mehthod handle), 并指明该执行什么方法
当函数正常调用完毕后， current frame用来恢复invoker的状态, 包括invoker的local variables, operand stack, 跳过pc register执行过的指令. invoker会收到current frame的返回值, 并继续执行


## 11. Synchronization(同步)
* 功能: JVM支持method和一个method中instruction序列的同步操作. 这一功能主要由monitor实现
* method级别的同步很隐晦, 在调用方法和退出方法时就实现了. 当某个method的run-time constant pool中的method\_info的flag有ACC\_SYNCHRONIZED时, method invocation instruction将会检查到, 并将current thread放入monitor中.
* Strutured locking表示这样一个情况: 每一个从monitor退出的method都对应一次method invocation. 共有两条规则来保证structured locking:
  * 一次方法调用中, 进入的monitor次数必须和从monitor退出的次数一样(无论函数是否正常调用)
  * 一次方法调用中, 单个线程释放monitor的数量不能超过进入monitor的数量


## 12. 运行时数据区域
### 12.1 程序计数器(Program Counter Register)
* 功能: 对于非Native方法, 存储JVM指令的地址. 如果是Native方法, PC register的值不确定
* pc register范围足够大, 可以装下任意returnAddress或native pointer, 所以没有OutOfMemoryError
* JVM支持多线程执行, 所以每个线程的pc register独立运行

### 12.2 Java虚拟机栈(Java Virtual Machine Stacks)
* 功能: 防止局部变量和临时结果, 用于函数的调用和返回. 
* 线程私有, 线程创建时就会生成一个Stack, 生存周期与线程相同. 每当线程调用一个方法, 就会创建一个Frame(存放Local variables, Operand Stack, Dynamic linking). 方法的执行也就是frame入栈出栈的过程.
* JVM stack可使用固定或动态大小, 以下有几种异常情况:
  * 栈深度大于虚拟机所允许: StackOverflowError(单个线程的递归产生, 通过不断添加Stack Frame使得内存不足)
  * 无法申请到足够内存: OutOfMemoryError(通过产生大量线程, 新线程没有内存)

### 12.3 本地方法栈(Native Method Stack)
* 功能: 支持其他语言的栈空间. 不支持native method的JVM可不用创建Native method stack. 如果支持native method, 则每次创建线程时创建该区域
* 该区域可为固定大小或动态大小. 
* 异常情况:
  * 单个线程的native method stack不足, 抛出StackOverflowError
  * 大量线程导致native method stack不足, 抛出OutOfMemoryError

### 12.4 Heap(堆)
* 功能: 提供一块由全部线程共享的区域. 所有class对象和数组都分配在这里
* JVM启动时自动创建heap, 由GC来实现自动管理对象(对象无法显式释放). 从内存回收的角度, 现在收集器采用分代收集算法. Java堆分为新生代和老年代, 还可以细分为Eden空间, From Survivor空间和To Survivor空间等. 
* Heap可以是固定大小, 也可以根据需求增大或缩小. Heap的内存也不必是连续分配的.
* Java堆是GC管理的主要区域. 
* 异常情况: 如果堆上无法完成内存分配, 并且无法拓展, 则抛出OutOfMemoryError(大量申请类对象导致)

### 12.5 方法区(Method Area)
* 功能: 各线程共享的内存空间, 用来存储每个类的结构, 例如: run-time constant pool, field, method data和方法运行的指令
* JVM启动时生成Method Area. 虽然属于heap, 但JVM实现时倾向于不对Method Area进行GC和压缩. 可以是固定大小或动态大小
* 异常情况: 无法满足内存分配需求时抛出OutOfMemoryError(大量生成类导致类的相关信息过多, 最后方法区溢出)
* HotSpot的实现: 将Method Area成为**PermGen**(Permanent Generation, 永久代), 因为这样可像管理Java堆一样管理这部分内存. 目前HotSpot也放弃了PermGen, 并逐步采用Native Memory来实现方法区的管理(因为永久代可能导致内存溢出, 需要通过-XX:MaxPermSize重新设置上限)

### 12.6 运行时常量池(Run-time Constant Pool)
* 功能: 包含每个class和interface的run-time representation(class文件中的constant_pool), 这其中包含几种数据:
  * compile-time确定的数值常量
  * run-time确定的method和field
* Run-time constant pool分配在Method Area中, 当class或interface创建时会创建Run-time constant pool
* 异常情况: 当创建class或interface时, 生成的相关信息超过了Run-time Constant Pool的内存大小, 抛出OutOfMemoryError()

### 12.7 直接内存
* 功能: 直接内存不是运行时数据区的一部分, 它可以不占用堆空间直接分配到物理内存中, 但仍受操作系统最大内存的限制. 无法满足时抛出OutOfMemoryError
* 通过需要大内存空间且频繁访问时才需要直接内存, 因为这块区域读取速度更快, 且不受JVM垃圾回收管理. 可通过unsafe.allocateMemory()在直接内存中分配空间


## 13. JVM的数据类型
JVM中只有两种数据类型: Primitive type和Reference type

### 13.1 Primitive types
* numeric types
  * integral type: 默认为0
    * byte: 8位二进制补码
    * short: 16位二进制补码
    * int: 32位二进制补码
    * long: 64位二进制补码
  * floating-point type: 默认为+0
    * float: 32位float-extended-exponent值, 默认为+0
* boolean type: 32位(使用int表示boolean), 1表示true, 0表示false, 默认为0
* returnAddress type: 指向某个opcode的指针, Primitive type中唯一不能被程序员修改的值

### 13.2 reference types
* class type
* array type
一个array type包含一维的component type, 如果component type也是一个array type, 那么该array type也有一个component type. 如果array type的component type不是array type(可以是primitive type, class type或interface type), 则称作element type.
* interface type


## 14. 没有分配到堆的对象实例
1. 堆是由所有线程共享的, 而new操作会将对象分配到堆上, 这就导致每次分配操作必然伴随着锁操作. 而锁的使用时有一定开销, 当对象频繁分配时不免影响效率
2. JVM在Eden Space中开辟了一块区域用于线程私有, 被称为TLAB(Thread-local allocation buffer), 默认占Eden Space的1%. 这样就避免了小对象的分配需要锁, 也适合快速GC. 
3. 逃逸分析下, 如果某个对象只存在于某个方法和线程内, 那么说明该对象可分配在栈上. 因为该对象是局部性的


## 15. 四种引用类型
### 15.1 强引用(Strong Reference)
GC永不会回收的引用对象(即使内存不足报错), 除非引用改为null
```java
String r0 = new String("123");
System.gc();
System.out.println(r0);   // 123
r0 = null;
System.gc();
System.out.println(r0);   // null
```

### 15.2 软引用(Soft Reference)
用于描述有用但非必需的对象, 缓存不足时进行GC. 适合用于创建缓存, 例如网页缓存.
```java
SoftReference<String> r = new SoftReference(new String("bcd"));
System.gc();
System.out.println(r.get());  // bcd
```

### 15.3 弱引用(Weak Reference)
强度比软引用更弱, 只能生存到下一次GC之前. 但由于GC线程的优先级很低, 所以可以作为级别较低的缓存, 例如Tomcat的LRU缓存. 可被强引用拯救被GC的命运
```java
WeakReference<String> r = new WeakReference(new String("abc"));
String test = r.get();
System.gc();
System.out.println(r.get()); // 如果没有test引用则返回null, 但由于test强引用, 因而使得r所指向的对象躲过GC
```

### 15.4 虚引用(Phantom Reference)
最弱的引用关系. 无法通过虚引用得到一个对象实例, 且完全不会对生存时间构成影响, 也不会被强引用拯救被GC的命运. 可用于两点: 不用担心析构问题, 因为虚引用的对象在GC中必被销毁; 可知道对象何时被析构
```java
ReferenceQueue rq = new ReferenceQueue();
PhantomReference<String> r = new PhantomReference(new String("def"), rq);
System.out.println(r.get());  // null
```
