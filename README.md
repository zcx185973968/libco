Libco
===========
Libco is a c/c++ coroutine library that is widely used in WeChat services. It has been running on tens of thousands of machines since 2013.

Author: sunnyxu(sunnyxu@tencent.com), leiffyli(leiffyli@tencent.com), dengoswei@gmail.com(dengoswei@tencent.com), sarlmolchen(sarlmolchen@tencent.com)

By linking with libco, you can easily transform synchronous back-end service into coroutine service. The coroutine service will provide out-standing concurrency compare to multi-thread approach. With the system hook, You can easily coding in synchronous way but asynchronous executed.

You can also use co_create/co_resume/co_yield interfaces to create asynchronous back-end service. These interface will give you more control of coroutines.

By libco copy-stack mode, you can easily build a back-end service support tens of millions of tcp connection.
***
### 简介
libco是微信后台大规模使用的c/c++协程库，2013年至今稳定运行在微信后台的数万台机器上。  

libco通过仅有的几个函数接口 co_create/co_resume/co_yield 再配合 co_poll，可以支持同步或者异步的写法，如线程库一样轻松。同时库里面提供了socket族函数的hook，使得后台逻辑服务几乎不用修改逻辑代码就可以完成异步化改造。

作者: sunnyxu(sunnyxu@tencent.com), leiffyli(leiffyli@tencent.com), dengoswei@gmail.com(dengoswei@tencent.com), sarlmolchen(sarlmolchen@tencent.com)

PS: **近期将开源PaxosStore，敬请期待。**

### libco的特性
- 无需侵入业务逻辑，把多进程、多线程服务改造成协程服务，并发能力得到百倍提升;
- 支持CGI框架，轻松构建web服务(New);
- 支持gethostbyname、mysqlclient、ssl等常用第三库(New);
- 可选的共享栈模式，单机轻松接入千万连接(New);
- 完善简洁的协程编程接口
 * 类pthread接口设计，通过co_create、co_resume等简单清晰接口即可完成协程的创建与恢复；
 * __thread的协程私有变量、协程间通信的协程信号量co_signal (New);
 * 语言级别的lambda实现，结合协程原地编写并执行后台异步任务 (New);
 * 基于epoll/kqueue实现的小而轻的网络框架，基于时间轮盘实现的高性能定时器;

### Build

```bash
$ cd /path/to/libco
$ make
```

or use cmake

```bash
$ cd /path/to/libco
$ mkdir build
$ cd build
$ cmake ..
$ make
```


### 读源码的几个点：
    1、主进程（线程）（协程）的栈，是系统分配的，切换的时候，它的内存地址依赖系统，不变化
    2、其它协程的栈，都是自己分配的，在co_create_event里，会分配一个保存寄存器的co_ctx和栈的stackMem结构，stackMem是共享的，co_ctx是独占的。这个是为了减少stackMem之间的切换，可以多个co_ctx共享一个stackMem。
    3、协程第一次进入的时候，会调用coctx.cpp 里的coctx_make ,这里是协程的第一个栈的位置，然后给参数和下一条代码的地址设置好。参数pfn是下一条的地址，pfn是co_routine.cpp里定义的CoRoutineFunc,此函数的第一个参数就是要运行的协程的上下文环境。
    4、system_hook里给常用的函数做了封装，比如connect，write，read等，然后都加入了一个超时时间，当读取数据的时候，会自动调用poll，进行协程切换，并且根据时间进行超时判断，如果到达了时间，或者读写事件到达的时候，就会由主协程切换到本协程继续执行。
    5、运行过程是：在co_create创建协程的时候，会给主协程的栈初始化好，就是co_routine.cpp里的co_init_curr_thread_env,主协程的栈是系统分配的，只要注意保存寄存器状态和当前栈指针就好了。然后在co_resume的时候，切换到当前协程，执行当前协程里的函数，遇到pool的时候，则会自动切换回主协程，主协程里会根据超时和读写事件，将其他协程加入队列，然后切换到相应的协程。所有协程间的切换都是有主协程来调用的。也允许从当前协程切换到其它协程，直接调用co_swap,但是这样会导致主协程里的事件和超时无人处理。
