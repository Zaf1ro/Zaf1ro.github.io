---
title: 剑指Offer(1)
category:
  - Algorithm
  - Interview
tag:
  - Algorithm
abbrlink: 1604134517
date: 2017-09-04 16:21:38
---

#### 1. 实现Singleton
1. single-thread implementation
单线程模式下正常运行, 但多线程下会创建多个instance
```cpp
class Singleton{
private:
    Singleton(){};
    static Singleton* instance = NULL;
public:
    static Singleton* getInstance(){
        if(instance==NULL)
            return new Singleton();
    }
};
```

2. multi-thread implementation
对于每个线程都进行lock处理, 退出时unlock
```cpp
class Singleton{
private:
    Singleton(){};
    static Singleton* instance = NULL;
public:
    static Singleton* getInstance(){
        lock();
        if(instance==NULL)
            instance = new Singleton();
        unlock();
        return instance;
    }
};
```

3. more effective multi-thread implementation
可防止线程阻塞, 如果instance不为NULL, 直接返回instance
```cpp
class Singleton{
private:
    Singleton(){};
    static Singleton* instance = NULL;
public:
    static Singleton* getInstance(){
        if(instance==NULL){
            lock();
            if(instance==NULL)
                instance = new Singleton();
            unlock();
        }
        return instance;
    }
};
```
