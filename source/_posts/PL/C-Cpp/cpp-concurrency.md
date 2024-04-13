---
title: C++并发
category:
  - C/C++
tag:
  - C/C++
abbrlink: 412a
date: 2017-11-03 14:52:55
---

## 1. 进程并发和线程并发的比较
进程的缺点:
1. 进程之间的沟通十分复杂并且速度慢
2. 分配多进程需要占更多的资源

进程的优点:
1. 操作系统会给予进程很多保护, 例如保护数据不被其他数据修改
2. 线程的优点:
    1. 轻量级, 不需要太多资源
    2. 共享全局资源和内存
3. 线程的缺点
    1. 缺少保护数据的机制

总结: 虽然线程并发需要程序员自己统筹数据的一致性, 但它的优点也是很突出. 所以大部分语言都选用线程作为并发单位, 并且C++不提供内嵌的进程并发支持, 所以如果使用C++进行进程并发, 需要依赖平台特定的API.


## 2. 为什么使用并发
1. 开发工作的分离: 例如, 开发界面的工作可以和后端的工作分来处理, 并放入各自线程就好.
2. 运行速度的提升: 由于单一芯片速度的提升遇到瓶颈(摩尔定律失效), 多核更成为了趋势, 因此并发编程成为提高运行速度的首选. 并发提高运行速度有两种方法:
    1. 将单一task分成多个模块并平行运行
    2. 不分解task, 而是同时处理多个task


## 3. 何时不要使用并发
1. 开发时间过长: 过长时间的并发开发使得并发带来的性能提升不值一提
2. 线程运行时间过短: 每次线程切换时, 操作系统都要进行内核资源分配, 栈空间分配并添加新线程的调度器. 如果单个线程执行时间过短, 会导致频繁的线程切换. 这使得并发节省的运行时间小于切换线程的用时
3. 线程数量过多: 虽然线程是轻量级的进程, 但每个线程还是会占用一定的栈空间. Java中单个线程占512KB, 所以过多的线程会消耗过多栈空间. 如果线程数量太多, 可考虑使用threadpool
4. 代码复杂化: 如果并发导致bug大量增加, 代码逻辑混乱. 那么如果不那么重视运行效率的情况下, 可以不使用并发


## 4. thread object生成
```cpp
void func(){
    std::cout << "Hello, World!\n";
}

int main() {
    std::thread t1(func);
    // std::thread t2(func());  // 会被误认为是函数声明
    t1.join();
    return 0;
}
```


## 5. 如何防止线程未启动
```cpp
/* 第一种方法: 
 * 使用try/catch block来防止异常导致的thread未启动
 */
struct func;
void f()
{
    int some_local_state=0;
    func my_func(some_local_state);
    std::thread t(my_func);
    try
    {
        do_something_in_current_thread();
    }
    catch(...)
    {
        t.join();
        throw;
    }
t.join();
}
```

```cpp
/* 第二种方法:
* 使用class的destructor来自动启动thread
*/
class guard{
private:
    thread& t;
public:
    explicit guard(std::thread& t): t(t){}
    ~guard(){
        if(t.joinable()){ t.join(); }
    }

    guard(guard const&)=delete;
    guard& operator=(guard const&)=delete;
};

struct func;
void f()
{
    int some_local_state=0;
    func my_func(some_local_state);
    std::thread t(my_func);
    guard g(t);
    do_something_in_current_thread();
}
```


## 6. thread传参
thread中直接添加参数即可
```cpp
void f(int i,std::string const& s);

void oops(int some_param)
{
    char buffer[1024];
    sprintf(buffer, "%i",some_param);
    std::thread t(f,3,buffer);
    t.detach();
}
```
但上述传参会将buffer传递给thread t过去, 而t可能在oops运行完之前还未结束线程, 这会导致buffer处于未定义行为中. 解决方案就是传递一份copy给thread t
```cpp
void f(int i,std::string const& s);

void not_oops(int some_param)
{
    char buffer[1024];
    sprintf(buffer,"%i",some_param);
    std::thread t(f,3,std::string(buffer)); // 传递一份string, 这样就不影响buffer
    t.detach();
}
```
当然也可能是你想传递一份引用或指针给thread, 但却传递了一个copy
```cpp
void update_data_for_widget(widget_id w,widget_data data);

void oops_again(widget_id w)
{
    widget_data data;
    std::thread t(update_data_for_widget,w,data);   // thread t无法改变data
    display_status();
    t.join();
    process_widget_data(data);
}
```
这时需要传递一个引用来改变data
```cpp
void update_data_for_widget(widget_id w,widget_data& data);

void oops_again(widget_id w)
{
    widget_data data;
    std::thread t(update_data_for_widget,w,ref(data));
    display_status();
    t.join();
    process_widget_data(data);
}
```


## 7. 调用成员函数
thread通过输入成员函数的地址和类对象地址来操作成员函数
```cpp
class X{
private:
    int a;
public:
    X(int a){ this->a = a; }
    void do_something(int a){ this->a = a; }
    void show(){ cout<<a<<endl; }
};

int main(){
    int a = 1;
    X my_x(-1);
    my_x.show();    // -1
    thread t(&X::do_something, &my_x, a);
    t.join();
    my_x.show();    // 1
}
```


## 8. 转移thread的ownership
thread和std::unique_ptr一样, 是movable但不是copyable. 只能讲thread of execution转移到某个thread实例中, 而不能直接复制thread of execution.
但有以下几点需要注意:
1. thread转移ownership有两种方式:
    1. explicit转移: 用于thread对象之间的ownership转移
    2. implicit转移: 用于初始化thread对象时转移临时thread实例的ownership
2. thread对象的ownership被转移后不能使用, 否则报错
3. 被转移ownership的对象可被赋予新的ownership
4. 已有ownership的thread不能被赋予新的ownership, 否则报错. 但可在运行后再被赋予新的ownership

```cpp
void func(){ cout<<1<<endl; }
void another_func(){ cout<<2<<endl; }

int main() {
    thread t1(func);
    t1.join();                  // run thread
    t1 = thread(another_func);  // implicit move
    thread t2 = move(t1);       // explicit move
    // thread t3 = move(t1);    // error, t1 has no ownership to transfer
    // t1.join();               // error, t1 cannot run
    thread t3(func);
    // t2 = move(t1);           // error, t2 has an execution of thread
    t3.join();
    t2.join();
    return 0;
}
```

由于thread对象是movable, 所以thread可作为函数的参数类型和返回类型.
```cpp
class scoped_thread
{
    std::thread t;
public:
    explicit scoped_thread(std::thread t_): t(std::move(t_)) {
        if(!t.joinable())
            throw std::logic_error("No thread");
    }

    ~scoped_thread(){ t.join(); }   // 输出-1

    scoped_thread(scoped_thread const&)=delete;
    scoped_thread& operator=(scoped_thread const&)=delete;
};

void func(int state){
    cout<<state<<endl;
}

int main() {
    int some_local_state = -1;
    scoped_thread t(std::thread(func, some_local_state));
    // do_something_in_current_thread();
}
```
