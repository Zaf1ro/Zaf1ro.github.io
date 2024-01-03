---
title: JVM (3)
category:
  - Java
  - JVM
tag:
  - Java
abbrlink: 94a0
date: 2017-11-09 08:58:48
---

## 1. 调用函数
### 1.1 调用成员函数
```java
public class Test {
  int addTwo(int i, int j){
    return i+j;
  }
  /**
   * int addTwo(int, int);
   * Code: stack=2, locals=3, args_size=3
   * 0: iload_1  // 从local variable array[1]取值, [0]为this
   * 1: iload_2
   * 2: iadd
   * 3: ireturn
   */

  public static void main(String[] args){
    Test t = new Test();
    t.addTwo(10,11);
    addTwoStatic(11,12);
  }
  /**
   * public static void main
   * Code: stack=3, locals=2, args_size=1
   * 0: new #2    // 在heap上创建于一个class对象, 并将objectref放入operand stack中
   * 3: dup       // 复制栈顶元素并放入栈顶
   * 4: invokespecial #3  // 调用Test的初始化函数init()
   *                      // 由于init无参数, 只将operand stack中的objectref取出并赋给init
   * 7: astore_1          // 将operand stack顶部元素取出并存入到local variable的索引1位置上
   * 8: aload_1           // 将local variable索引1位置上的元素放入operand stack顶部
   * 9: bipush 10         // 将常量10放入operand stack
   * 11: bipush 11        // 将常量11放入operand stack
   * 13: invokevirtual #4 // 调用函数int addTwo(int, int)
   *                      // 由于是成员函数, 所以将this, 10, 11都作为参数传给addTwo
   * 16: pop              // 得到结果并弹出
   * 25: return
   */
}
```

### 1.2 调用父类函数
```java
class SuperTest{
  public int getInfo(){
    return 1;
  }
}

public class Test extends SuperTest {
  public int get(){
    return super.getInfo();
  }
  /**
   * 0: aload_0          // 将this装入operand stack
   * 1: invokespecial #2 // 调用SuperTest.getinfo()
   *                     // 因为使用super指明是父类函数, 所以调用invokespecial
   * 4: ireturn
  */
}
```

### 1.3 调用静态函数
```java
static int addTwoStatic(int i, int j){
  return i+j;
}
/**
 * static int addTwoStatic(int, int);
 * Code: stack=2, locals=2, args_size=2
 * 0: iload_0  // 直接从索引0开始从local variable array中取值
 * 1: iload_1
 * 2: iadd
 * 3: ireturn
 */

public static void main(String[] args){
  addTwoStatic(11,12);
}
/*
 * 0: bipush 11
 * 2: bipush 12
 * 4: invokestatic #2 // 调用addTwoStatic(int, int)
 *                    // 由于是静态函数所以不需要传入this
 * 7: pop
 * 8: return
 */
```


## 2. Constant, Local Variable和Control Construct的使用
### 2.1 int类型变量的操作
```java
void spin() {
  int i;
  for (i = 0; i < 100; i++) {
    // Loop body is empty
  }
}

/*
 * 0: iconst_0      // 将constant 0放入operand stack中
 * 1: istore_0      // 将operand stack的顶端元素取出, 并赋值给local variable array中索引为0的元素(也就是i)
 * 2: iload_0       // 将local variable array中index为0的元素值(也就是i的值)放入operand stack中
 * 3: bipush 100    // 将要一个byte大小(因为100只用8位就能表示)的立即数放入operand stack
 * 5: if_icmpge 14  // 将operand stack顶部的两个值取出(例如v1和v2), 如果v1>=v2, 跳至14
 * 8: iinc 0, 1     // 将local variable array中索引为0的值自加1(自加的值必须为signed int)
 * 11: goto 2       // 跳转到2
 * 14: return       // 返回void
*/
```

### 2.2 short类型变量操作
由于operand stack和local variable的实现原因, Java指令支持int的store, load, add操作(也因为int使用最为频繁). 但对于其他Integer(byte, char, short)就没有相应的指令, 例如:
```java
void sspin() {
  short i;
  for (i = 0; i < 100; i++) {
    ; // Loop body is empty
  }
}

/*
 * 0: iconst_0
 * 1: istore_0      // 使用int的方法存取
 * 2: iload_0
 * 3: bipush 100
 * 5: if_icmpge 16  // 使用int的比较方法来比较short类型
 * 8: iload_0
 * 9: iconst_1
 * 10: iadd
 * 11: i2s
 * 12: istore_0
 * 13: goto 2
 * 16: return
 */
```

### 2.3 double类型变量操作
由于缺乏byte, char和short的操作指令, 所以用int的指令代替. 但这并没有什么不妥, 只不过int操作会导致值的截断
对于long和float类型来说, 有store和load指令, 但没有比较指令. 下面只以double为例:
```java
void dspin() {
  double i;
  for (i = 0.0; i < 100.0; i++) {
    ; // Loop body is empty
  }
}

/*
 * 0: dconst_0
 * 1: dstore_0
 * 2: dload_0
 * 3: ldc2_w #2 // double 100.0d
 * 6: dcmpg     // 从operand stack取出两个double值, v1,v2(v2在v1之上)
 *              // 如果v1>v2, 将int 1放入operand stack
 *              // 如果v1==v2, 将int 0放入operand stack
 *              // 如果v1<v2, 将int -1放入operand stack
 *              // 如果v1或v2其中一个为NaN, dcmpg将1放入operand stack, dcmpl将-1放入operand stack
 * 7: ifge 17   // 从operand stack顶部取出一个int值, 如果该值>=0, 则跳转至17
 * 10: dload_0
 * 11: dconst_1
 * 12: dadd
 * 13: dstore_0
 * 14: goto 2
 * 17: return
 */
```



## 3. Arithmetic
JVM通常会在operand stack上做算术运算(iinc是个例外, 它直接针对local variable), 例如:
```java
int align2grain(int i, int grain) {
  return ((i + grain-1) & ~(grain-1));
}
/**
 * 0: iload_0   // 将local variable中第一个值(i)放入operand stack
 * 1: iload_1   // 将local variable中第二个值(grain)放入operand stack 
 * 2: iadd      // 从operand stack中取出两个值, 相加(i+grain)并将结果放入operand stack
 * 3: iconst_1  // 将1放入operand stack
 * 4: isub      // 从operand stack中取出两个int值, 相减并将结果放入operand stack
 * 5: iload_1   // 将grain放入operand stack
 * 6: iconst_1  // 将1放入operand stack
 * 7: isub      // 取出两个int值相减并放回结果
 * 8: iconst_m1 // 放入-1(~x==-1^x)
 * 9: ixor      // 取出两个int, 异或操作后放入结果
 * 10: iand     // 取出两个int, and操作后放入结果
 * 11: ireturn
 */
```


## 4. Run-time Constant Pool
### 4.1 -1 ~ 5
使用`iconst_<i>`指令
```java
int i = 5;
/**
 * 0: iconst_5 
 * 1: istore_1
 */
```

### 4.2 -128 ~ 127
使用`bipush`指令
```java
int i1 = 127;
int i2 = -128;
/**
 * 0: bipush    127
 * 2: istore_1
 * 3: bipush    -128
 * 5: istore_2
 */
```

### 4.3 -32768 ~ 32767
使用**sipush**指令
```java
int i1 = -32768;
int i2 = 32767;
/*
 * 0: sipush -32768
 * 3: istore_1
 * 4: sipush 32767
 * 7: istore_2
 */
```

### 4.4 -2147483648 ~ 2147483647
使用`ldc`指令
```java
int i1 = -32769;
int i2 = 32768;
/**
 * 0: ldc #2   // int -32769
 * 2: istore_1
 * 3: ldc #3   // int 32768
 * 5: istore_2
 */
```

### 4.5 long and double
如果分配0或1, 则用`lconst_<l>`和`dconst_<d>`
```java
long l1 = 0;
long l2 = 1;
long l3 = 2;
/**
 * 0: lconst_0
 * 1: lstore_1
 * 2: lconst_1
 * 3: lstore_3
 * 4: ldc2_w #2  // long 2l
 * 7: lstore 5
 */

double d1 = 0.0;
double d2 = 1.0;
double d3 = 3.0;
/**
 * 9: dconst_0
 * 10: dstore 7
 * 12: dconst_1
 * 13: dstore 9
 * 15: ldc2_w #4  // double 3.0d
 * 18: dstore 11
 */
```


## 5. 条件控制
### 5.1 int
```java
void whileInt() {
  int i = 0;
  while (i < 100) {
    i++;
}
/**
 * 0: iconst_0      // 将0放入operand stack
 * 1: istore_0      // 将0从operand stack取出, 放入i
 * 2: iload_0       // 把i的值加载到operand stack中
 * 3: bipush 100    // 将100放入operand stack
 * 5: if_icmpge 14  // 取出并对比, i>=100则跳转至14
 * 8: iinc 0, 1     // i自加1
 * 11: goto 2       // 跳转至2
 * 14: return
*/
```

### 5.2 float/double
对于float和double类型来说, 有两种对比方式
* fcmpl和fcmpg
* dcmpl和dcmpg

当遇到NaN时会做出不同的行为, 以下以double为例:
```java
int lessThan100(double d) { // 输入d为Double.NaN
  if (d < 100.0) {
    return 1;
  } else {
    return -1;
  }
}

/**
 * 0: dload_0
 * 1: ldc2_w #2   // double 100.0d
 * 4: dcmpg       // 由于v1和v2中有NaN, 将1装入operand stack中
 * 5: ifge 10     // 1>0, 跳转到10
 * 8: iconst_1
 * 9: ireturn
 * 10: iconst_m1  // 将-1放入operand stack
 * 11: ireturn    // 返回operand stack
 */
```

### 5.3 break
```java
void breakTest(int i) { // i=10
  while(i<10){
    if(i>5)
      break;
    i++;
  }
}

/**
 * 0: iload_0
 * 1: bipush 10
 * 3: if_icmpge 20
 * 6: iload_0
 * 7: iconst_5
 * 8: if_icmple 14
 * 11: goto 20
 * 14: iinc 0, 1
 * 17: goto 0
 * 20: return
 */
```


## 6. function parameter
非成员函数将参数从0开始添加, 成员函数从1开始添加
```java
static int addTwo(int i, int j){
  return i+j;
}
/**
 * static int addTwo(int, int);
 * flags: ACC_STATIC
 * Code:
 * stack=2, locals=2, args_size=2
 * 0: iload_0  // 从current frame的local variable array中获得索引为0的int值
 * 1: iload_1  // 从索引1上获得int值
 * 2: iadd   // 从operand stack中取出2个int相加
 * 3: ireturn  // 取出operand stack中所有值放入local variable array, 返回local variable array
 */

public static void main(String[] args){
  addTwo(1,2);
}
/**
 * public static void main(java.lang.String[]);
 * flags: ACC_PUBLIC, ACC_STATIC
 * Code:
 * stack=2, locals=1, args_size=1
 * 0: iconst_1        // 将1放入operand stack
 * 1: iconst_2        // 将2放入operand stack
 * 2: invokestatic #2 // Method addTwo:(II)I
 * 5: pop             // 将operand stack顶部的值移出
 * 6: return
 */
```


## 7. Class Object
### 7.1 object as parameter
```java
Test getTest() {
  Test t = new Test();
  return processTest(t);
}

/**
 * 0: new #2            // new Test(), 将objectref装入operand stack
 * 3: dup               // 复制objectref
 * 4: invokespecial #3  // 移出一个objectref, 调用初始化函数init() 
 * 7: astore_0          // 移出一个objectref, 赋值给Local variable array索引为0的元素(t)
 * 8: aload_0           // 将local variable array索引为0的元素装入operand stack
 * 9: invokestatic #4   // 从operand stack中移出t, 并调用process Test
 * 12: areturn          // 从operand stack取出并返回objectref
 */

static Test processTest(Test t) {
  if (t != null)
    return t;
  else
    return null;
}

/**
 * 0: aload_0     // 将local variable array中索引为0的元素(参数t)装入operand stack
 * 1: ifnull 6    // 取出t, 并对比null. 如果t==null则跳转到6
 * 4: aload_0     // 将t装入operand stack
 * 5: areturn     // 从operand stack中取出t, 并返回
 * 6: aconst_null // 将null放入operand stack
 * 7: areturn     // 从operand stack中取出null, 并返回
 */
```

### 7.2 call member function
```java
public class Test {
  int i = 1;
  
  void set(int i) {
    this.i = i;
  }
  /**
   * 0: aload_0     // 将this装入operand stack
   * 1: iload_1     // 将常量1装入operand stack
   * 2: putfield #2 // 取出this和1, 通过this(objectref)找到堆上的t对象
   *                // 并通过#2(Fieldref)确定修改的值(i), 最后将1赋值给i
   * 5: return
  */
  
  public static void main(String[] args){
    Test t = new Test();
    t.set(2);
  }
  /**
   * 0: new #3            // new Test, 将objectref放入operand stack
   * 3: dup               // 复制objectref
   * 4: invokespecial #4  // 取出一个objectref, 进行init初始化
   * 7: astore_1          // 取出一个objectref, 赋值给local variable array中index为1的元素(t)
   *                      // local variable array索引为0的元素是main函数的参数String[]
   * 8: aload_1           // 将t装入operand stack
   * 9: iconst_2          // 将常量2装入operand stack
   * 10: invokevirtual #5 // 取出t(this)和2, 调用成员函数set(int)
   * 13: return
  */
}
```


## 8. Array
### 8.1 one-dimensional array of primitive type
```java
int buffer[];
buffer = new int[100];
int value = 12;
buffer[10] = value;
value = buffer[11];

/**
 * 0: bipush 100
 * 2: newarray int  // 取出100, 创建于一个int[100]数组
 *                  // 将arrayref装入operand stack
 * 4: astore_1      // 取出arrayref并赋值给buffer
 * 5: bipush 12
 * 7: istore_2      // 赋值value
 * 8: aload_1       // 装入buffer
 * 9: bipush 10
 * 11: iload_2      // 装入value
 * 12: iastore      // 将buffer, 10, value取出并赋值: buffer[10]=value
 * 13: aload_1      // 装入buffer
 * 14: bipush 11
 * 16: iaload       // 取出buffer和11, 装入buffer[11]的值
 * 17: istore_2     // 取出buffer[11], 赋值给value
 * 18: return
 */
```

### 8.2 one-dimensional array with of reference
```java
Test buffer[];
buffer = new Test[100];

Test value = new Test();
buffer[10] = value;
value = buffer[11];

/**
 * 0: bipush 100
 * 2: anewarray #2      // 不一样的指令来创建引用数组
 * 5: astore_1
 * 6: new #2            // 创建Test对象
 * 9: dup
 * 10: invokespecial #3 // init()
 * 13: astore_2
 * 14: aload_1
 * 15: bipush 10
 * 17: aload_2
 * 18: aastore          // 不一样的数组赋值指令
 * 19: aload_1
 * 20: bipush 11
 * 22: aaload           // 不一样的数组取值指令
 * 23: astore_2
 * 24: return
 */
```

### 8.3 multi-dimensional array
```java
int buffer[][][];
buffer = new int[2][3][4];

int value = 10;
buffer[1][1][1] = value;
value = buffer[1][1][1];

/**
 * 0: iconst_2
 * 1: iconst_3
 * 2: iconst_4
 * 3: multianewarray #2,3 // 从operand stack中取出2,3,4作为数组长度
 *                        // #2作为array的符号引用("[[[I"), 3作为数组的维度
 * 7: astore_1    // 赋值给buffer
 * 8: bipush 10
 * 10: istore_2   // 赋值给value
 * 11: aload_1
 * 12: iconst_1
 * 13: aaload     // 获得buffer[1]
 * 14: iconst_1
 * 15: aaload     // 获得buffer[1][1]
 * 16: iconst_1
 * 17: iload_2
 * 18: iastore    // 将value存入buffer[1][1][1]中
 * 19: aload_1    // 获得buffer
 * 20: iconst_1
 * 21: aaload     // 获得buffer[1]
 * 22: iconst_1
 * 23: aaload     // 获得buffer[1][1]
 * 24: iconst_1
 * 25: iaload     // 获得buffer[1][1][1]
 * 26: istore_2   // 将buffer[1][1][1]赋值给value
 * 27: return
 */
```



## 9. switch
Java有两条指令来处理int类型的switch: `tableswitch`和`lookupswitch`. 如果数据类型为byte, char或short, 则先将类型提升至int然后再做处理. tableswitch针对连续case值, lookupswitch针对不连续case值:

### 9.1 table
```java
int chooseNear(int i) {
  switch (i) {
    case 0: return 0;
    case 1: return 1;
    case 2: return 2;
    default: return -1;
  }
}

/**
 * 0: iload_0
 * 1: tableswitch { // 0 to 2
 *      0: 28       // 跳转至28
 *      1: 30       // 跳转至30
 *      2: 32       // 跳转至32
 *      default: 34
 *    }
 * 28: iconst_0
 * 29: ireturn
 * 30: iconst_1
 * 31: ireturn
 * 32: iconst_2
 * 33: ireturn
 * 34: iconst_m1
 * 35: ireturn
 */
```

### 9.2 lookupswitch
```java
int chooseFar(int i) {
  switch (i) {
    case -10: return 0;
    case 10: return 1;
    case 20: return 2;
    default: return -1;
  }
}

/**
 * 0: iload_0
 * 1: lookupswitch { // 3
 *      -10: 36
 *      10: 38
 *      20: 40
 *      default: 42
 *    }
 * 36: iconst_0
 * 37: ireturn
 * 38: iconst_1
 * 39: ireturn
 * 40: iconst_2
 * 41: ireturn
 * 42: iconst_m1
 * 43: ireturn
 */
```


## 10. Member Variable
```java
private long index = 0;

long nextIndex() {
  return index++;
}

/*
 0: aload_0     // 装入this
 1: dup
 2: getfield #2   // 通过this(objectref)和#2(Fieldref)获得index的值, 并装入operand stack
 5: dup2_x1     // 复制index的值
 6: lconst_1
 7: ladd      // 取出index和1, 装入求和后的数值(1)
 8: putfield #2   // 通过this, #2将和数(1)放回index
11: lreturn     // 返回index未改变的值(0)
*/
```


## 11. Declaring Member Variable
### 11.1 throw
当用athrow时, 则在exception_table中寻找这个objectref的handler, 如果找到对应的handler, pc重置到handler的位置, 并将frame的operand stack清空, objectref装入operand stack中. 
如果没有handler, 则将当前frame弹出, 并将objectref抛给该frame的调用者.
```java
int dosomething() throws ArithmeticException {
  int a =0, b = 1;
  if(a == 0){
    throw new ArithmeticException();
  }
  return b/a;
}

/*
 0: iconst_0
 1: istore_0      // a=0
 2: iconst_1
 3: istore_1      // b=0
 4: iload_0
 5: ifne 16       // 如果a!=0, 跳转到16
 8: new #2        // 创建一个ArithmeticException对象, objectref入栈
11: dup
12: invokespecial #3  // 调用ArithmeticException的初始化函数<init>
15: athrow        // 抛出一个objectref
16: iload_1
17: iload_0
18: idiv
19: ireturn
*/
```

### 11.2 catch
```java
void dosomething() throws ArithmeticException {
  try {
    int a = 1 / 0;
  } catch (ArithmeticException e) {
    System.out.println("an error");
  }
}

/*
 0: iconst_1        // 装入1
 1: iconst_0        // 装入0
 2: idiv
 3: istore_0        // 存入a
 4: goto 16
 7: astore_0        // 取出objectref
 8: getstatic #3      // 获得PrintStream
11: ldc #4          // "an error"
13: invokevirtual #5    // 调用println
16: return
*/
```

### 11.3 finally
```java
void dosomething() {
  int a = 1;
  int b = 3;
  try {
    b = a + b;
  } catch (RuntimeException e1) {
    b = a - b;
  } catch (Exception e2) {
    b = a * b;
  } finally {
    a = 0;
  }
}

/*
 0: iconst_1
 1: istore_0    // a=1
 2: iconst_3
 3: istore_1    // b=3
 4: iload_0
 5: iload_1
 6: iadd      // a+b
 7: istore_1    // b=a+b
 8: iconst_0    // finally
 9: istore_0    
10: goto 38
13: astore_2    // 异常对象引用在operand stack栈顶, 放入local variable
14: iload_0
15: iload_1
16: isub      // a-b
17: istore_1    
18: iconst_0    // finally
19: istore_0
20: goto 38
23: astore_2    // 异常对象引用在operand stack栈顶, 放入local variable
24: iload_0
25: iload_1
26: imul      // a*b
27: istore_1
28: iconst_0    // finally
29: istore_0
30: goto 38
33: astore_3    // 异常对象引用在operand stack栈顶, 放入local variable
34: iconst_0    // finally
35: istore_0
36: aload_3
37: athrow      // 抛出异常
38: return
*/
```
