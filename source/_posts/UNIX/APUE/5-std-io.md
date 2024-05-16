---
title: Standard I/O
tags:
  - Unix
category:
  - Unix
abbrlink: f946
date: 2019-08-20 08:35:26
---

## 1. Background
在UNIX出现前, 程序必须明确指出链接到哪些输入和输出, 因此, 执行任何I/O操作前, 程序需先获取一系列环境配置和硬件配置, 且每个系统的配置大不相同, 导致程序开发十分困难. UNIX的**一切皆文件**概念让程序执行I/O操作的成本大大降低, 程序可通过UNIX filesystem访问一切资源, 包括机器服务和外部设备; 借助简化的**文件**模型, 程序可从一个有序字节序列中读取数据, 直到文件结尾, 无需知道各个设备的底层信息.
UNIX并不是一个操作系统的名称, 而表示一系列操作系统, 当UNIX衍生出不同系统实现时, UNIX变体之间的代码移植变得愈发困难, 因此诞生了POSIX标准: 若程序遵循POSIX标准定义的接口, 则程序可在支持POSIX标准的不同UNIX变体之间移植.
C语言也需要自己的可移植性: ANSI C. 该标准规范了C语言的语法和语义, 还有其标准库, 让C语言适配不同操作系统, 当然包括UNIX.
![Layers of Abstraction](/images/UNIX/APUE/5-1-layer-of-stdio.png)


## 2. Introduction of Standard 
C语言并没有将I/O操作构建到语言中, 而是让其作为外部库. ANSI C将I/O函数统一放置在`stdio.h`, 称为**Standard I/O**; 与之相对, UNIX的I/O操作称为**File I/O**. 以下是两者的差别:
* File I/O由POSIX Standard制定; Standard I/O由ANSI C制定
* FIle I/O兼容遵循POSIX的UNIX系统实现; Standard I/O兼容主流操作系统, 包含UNIX之外的操作系统
* File I/O的所有操作都需要kernel参与, 因此涉及到user mode与kernel mode的切换; Standard I/O作为一个函数库, 在user mode执行, 必要时需调用File I/O
* Standard I/O引入了许多新概念和特性: Stream, line-by-line input, formatted output, buffered I/O, safe writing

大部分情况下, Standard I/O更适合开发程序, 但开发者仍需学习File I/O:
* 了解File I/O可帮助理解系统概念, 如进程如何管理文件
* 有时Standard I/O无法实现需求, 如获取文件的metadata


## 3. I/O Stream and FILE Objects
File I/O中, 程序通过**file descriptor**读取, 修改, 或删除文件; Standard I/O中, 程序通过**stream**操作文件. Stream不是一个设备或文件, 而是一个线性队列, 可从stream读取一个block的数据, 也可以向stream写入一个block的数据.
Standard I/O支持**wide character**(宽字符), 也就是说, 每个字符由一个或多byte组成, 而不是ASCII的单byte. 处理单字符的函数称为**normal character function**(如`fread`, `fwrite`, `fgetc`等), 处理宽字符的函数称为**wide character function**(如`fgetwc`, `fgetws`, `fputwc`等). normal character function不能与wide character function混用, 否则会发生编码错误.
**stream orientation**表示stream的字符类型, Standard I/O通过stream orientation判断当前stream的字符类型为normal character或wide character. stream一旦确定stream orientation就无法更改, 以下是指定orientation的三种方法:
* 若stream使用任意normal character function, 该stream确定为not wide  oriented
* 若stream使用任意wide character function, 该stream确定为wide oriented
* 使用`fwide`设置orientation

```c
/**
 * @brief set and determine the orientation of a FILE stream
 * @param mode if `mode` is zero, fwide() determines the current
 *        orientation of stream. If mode is non-zero, fwide() will
 *        attempt to set orientation(If not been set).
 *        * mode > 0: byte-character oriented
 *        * mode < 0: wide-character oriented
 * @return the orientation of stream after changing it.
 */
int fwide(FILE* stream, int mode);
```


## 4. Buffered I/O
对于File I/O, 读取数据的流程如下:
1. 用户进程通过`read()`向Kernel发送system call, 从user mode切换到kernel mode
2. CPU利用DMA(Direct Memory Access) controller将数据从硬盘读取到kernel mode的read buffer
3. CPU将数据从read buffer拷贝到user mode的user buffer
4. 切回user mode, `read()`执行完毕

若进程频繁调用`read()`, 需进行多次磁盘I/O操作, 根据局部性原理, 操作系统引入了**Page Cache**(页缓存)来减少磁盘访问: 当进程调用`read()`时, 会首先检查数据是否在page cache中, 若存在, 则直接从page cache读取; 若不在, 则从磁盘读取, 并将后面的几个页面一并读取到页缓存. 当进程调用`write()`时, 会先写入page cache, 由操作系统决定何时刷入磁盘.
Standard I/O的操作函数有自己的stdio buffer, 该buffer处于user mode, 这样避免在user mode和kernel mode之间频繁切换.
![Summary of I/O Buffering](/images/UNIX/APUE/5-4-io-buffering.png)

stdio buffer分为三种:
1. Block buffered: buffer空间耗尽, 进程调用`fflush()`, 或进程退出时执行I/O操作.
2. Line buffered: buffer空间耗尽, 遇到newline(`\n`), 进程调用`fflush()`, 或进程退出时执行I/O操作.
3. Unbuffered: 不缓存任何数据, 每次调用I/O函数都会执行I/O操作.

stdio buffer具有以下属性:
1. stdin和stdout都必须使用fully buffered, 除非他们对应的不是interactive device.
2. stderr永不使用fully buffered.

```c
/**
 * @param mode must be one of the following macros:
 *        * _IONBF: unbuffered
 *        * _IOLBF: line buffered
 *        * _IOFBF: fully buffered
 * @param buf should point to a buffer at least `size` bytes long
 *        if mode is _IOLBF or _IOFBF
 */
int setvbuf(FILE* stream, char* buf, int mode, size_t size);

/**
 * @brief stream buffering operations
 * @param buf if is not null, then use fully buffered; otherwise
 *        use unbuffered
 */
void setbuf(FILE* stream, char* buf);
```
![Summary of the setbuf and setvbuf functions](/images/UNIX/APUE/5-4-setbuf-and-setvbuf.jpg)

注意: buffer所能使用的空间小于`size`, 因为其中一部分空间要用于存放操作记录. 通常情况下不需要自己申请buffer, 关闭stream时会自动释放buffer. 任何时刻进程都可执行flush:
```c
/**
 * @brief forces a write of all user-space buffered data for the 
 *        given output or update stream via the stream's underlying 
 *        write function
 * @param stream if is NULL, fflush() flushes all open output streams
 */
int fflush(FILE* steam);
```
`setvbuf()`只有在打开stream后, 执行I/O操作前使用.


## 5. Open a Stream
```c
/**
 * @brief open the file pointed to by `pathname` and associates a 
 *        stream with it
 * @param mode points to a string beginning with one of the 
 *        following values:
 *        * r: Open text file for reading. The stream is positioned 
 *          at the beginning of the file.
 *        * r+: Open for reading and writing. The stream is positioned
 *          at the beginning of the file.
 *        * w: Truncate to zero length or create text file for writing.
 *          The stream is positioned at the beginning of the file.
 *        * w+: Open for reading and writing. Create new file if it 
 *          does not exist, otherwise it is truncated. The stream is
 *          positioned at the beginning of the file.
 *        * a: Open for appending. The file is created if it does not
 *          exist. The stream is positioned at the end of the file.
 *        * a+: Open for reading and appending. The file is created if 
 *          it does not exist. Output is always appended to the end of 
 *          the file.
 */
FILE* fopen(const char* pathname, const char* mode);

/**
 * @brief associates a stream with `fd`. This function can be used 
 *        for special types of files which cannot be open by fopen().
 */
FILE* fdopen(int fd, const char *mode);

/**
 * @brief open the file whose name is the string pointed to by 
 *        `pathname` and associate the stream pointed to by `stream`. 
 *        The original stream is closed if it exists.
 */
FILE* freopen(const char* pathname, const char* mode, FILE* stream);

/**
 * @brief flush the stream and close the underlying file descriptor.
 * @return 0 on success; EOF on error and errno is set.
 */
int fclose(FILE* stream);
```
以下是不同的`mode`参数:
![The type argument for opening a standard I/O stream](/images/UNIX/std-io-2.jpg)

若进程以**可读写**的方式打开文件, 由于stream使用buffer来缓存数据, 且input与output的切换会导致buffer内容被清空. 为避免数据丢失, 需遵守以下规则:
* 执行output操作(如`fwrite()`)后若进行input操作(如`fread()`), 需在两个操作之间执行`fflush`, `fseek`, `fsetpos`, 或`rewind`
* 执行`input`操作后若进行output操作, 需在两个操作之间运行`fseek`, `fsetpos`, `rewind`. 若input操作已经抵达EOF, 则无需该步骤.


## 6. Read and Write a Stream
stream有三种读写方式:
1. Character-at-a-time I/O: 一次读取或写入一个字符 
2. Line-at-a-time I/O: 一次读取或写入一行 
3. Direct I/O: 一次读取或写入固定长度的字符

### 6.1 Character-at-a-time
读取stream:
```c
/**
 * @brief read the next character from `stream`
 * @return character as an unsigned char on success; EOF on
 *         error
 */
int getc(FILE* stream);

/**
 * @brief obtain the next byte as an unsigned char converted to an
 *        int, from the input stream pointed to by `stream`, and 
 *        advance the file position indicator.
 *        But not like getc() working as a macro, fgetc() works as 
 *        a function, it would be slower than getc(). 
 */
int fgetc(FILE *stream);

/**
 * @brief get a byte from a stdin stream
 */
int getchar(void);
```
写入stream:
```c
/**
 * @brief push byte back specified by `c` back onto the input stream
 *        pointed to by `stream`. The Pushed-back character will be 
 *        returned by subsequent reads in reverse order of their
 *        pushing.
 * @param c if the value of `c` equals 
 EOF, the operation
       shall fail and the input stream shall be left unchanged.
 */
int ungetc(int c, FILE *stream);

/**
 * @brief put a byte on a stream
 */
int putc(int c, FILE *fp);

/**
 * @brief same as putc(), but not like putc() working as a macro, 
 *        fputc() works as a function
 */
int fputc(int c, FILE *fp);

/**
 * @brief put a byte on a stdout stream, same way as putc(c, stdout).
 */
int putchar(int c);
```

### 6.2 Line-at-a-Time I/O
读取stream:
```c
/**
 * @brief read bytes from stream into the array pointed to by `s`
 *        until `n-1` bytes are read, or a newline is read, or an
 *        end-of-file condition is encountered
 
 
 read in at most size-1 characters(The buffer is 
 *        terminated with a null byte) from fp and stores 
 *        them into the buffer pointed to by s.
 */
char* fgets(char* s, int n, FILE* fp);

/**
 * @brief read a line from stdin into the buffer pointed to by `s`
 *        until a terminating newline or EOF. No check for buffer
 *        overrun. Never use this function.
 */
char* gets(char* s);
```
写入stream:
```c
/**
 * @brief write the null-terminated string pointed to by `s` to the 
 *        stream pointed to by `stream`
 */
int fputs(const char* s, FILE* stream);

/**
 * @brief write string s and a trailing newline to stdout
 */
int puts(const char *s);
```


## 7. Binary I/O
有时要读取的数据太长, 导致`getc()`读取效率过低; 数据中含有大量null或newline, 导致`gets()`无法正确运行.
```c
/**
 * @brief read `nobj` items of data, each `size` bytes long, from the
 *        stream pointed to by `stream`, storing them at the location
 *        given by `ptr`.
 * @return the number of items read on success; short item 
 *         count or zero on error.
 */
size_t fread(void* ptr, size_t size, size_t nobj, FILE* stream);

/**
 * @brief write `nobj` items of data, each `size` bytes long, to the
 *        `stream` pointed to by `stream`, obtaining them from the
 *        location given by `ptr`.
 * @return the number of uitems write on success; short item count or
 *         zero on error.
 */
size_t fwrite(const void* ptr, size_t size, size_t nobj, FILE* stream);
```


## 8. Position a Stream
Standard I/O提供了`ftell()`和`fseek()`设置文件位置.
```c
/**
 * @brief obtain the current value of the file position indicator for
 *        the stream pointed to by `stream`.
 */
long ftell(FILE* stream);

/**
 * @brief set the file position indicator for the stream pointed to
 *        by `stream`. The new position(in bytes) is obtained by adding
 *        `offset` bytes to the position specified by `whence`.
 * @param whence must be one of the following values:
 *        * SEEK_SET: the start of the file
 *        * SEEK_CUR: the current position indicator
 *        * SEEK_END: send-of-file
 */
int fseek(FILE* stream, long offset, int whence);

/**
 * @brief reset the file position indicator in a stream, equivalent to 
 *        fseek(stream, 0, SEEK_SET);
 */
void rewind(FILE *fp);
```
若文件大小超过long最大值, 则`ftell()`和`fseek()`无法正确处理, 应避免使用`ftell()`和`fseek()`, 而使用`ftello()`和`fseeko()`.
```c
off_t ftello(FILE* stream);
int fseeko(FILE* stream, off_t offset, int whence);
```
有些系统的`off_t`和`long`都为32-bit, 但可通过设置`_FILE_OFFSET_BITS = 64`将`off_t`改为64-bit.
`ftello()`和`fseeko()`只适合处理ASCII编码的文件, 若文件使用其他编码, 需使用`fgetpos()`和`fsetpos()`.
```c
/**
 * @brief store file position indicator for the stream pointed to by 
 *        `stream` in the object pointed to by `pos`
 * @return 0 on success; -1 on error and errno is set.
 */
int fgetpos(FILE *fp, fpos_t *pos);

/**
 * @brief set file position indicators for the stream pointed to by
 *        `stream` according to the value of the object pointed to by
 *        `pos`, which the application shall ensure is a value obtained
 *        from an earlier call to fgetpos() on the same stream
 */
int fsetpos(FILE *fp, fpos_t *pos);
```


## 9. Formatted I/O
### 9.1 Formatted Output 
```c
/**
 * @brief produce output according to a `format` to stdout
 * @return the number of characters output on success; negative value 
 *         on error.
 */
int printf(const char* format, ...);

/**
 * @brief same as printf(), but write output to the given stream
 */
int fprintf(FILE *fp, const char *format, ...);

/**
 * @brief same as printf(), but write output to the given file 
 *        descriptor
 */
int dprintf(int fd, const char *format, ...);

/**
 * @brief same as printf(), but write to the character string `buf`.
 *        It's possible to overflow the buffer pointed to by `buf`
 *        that can lead to program instability and security violation.
 */
int sprintf(char *buf, const char *format, ...);

/**
 * @brief same as sprintf(), but explicit set the size of buffer.
 *        The part that exceed the size of buffer will be discarded.
 */
int snprintf(char *buf, size_t size, const char *format, ...);
```
以下5个函数与上述函数功能相同, 但使用`va_list`替代`...`
```c
int vprintf(const char *format, va_list ap);
int vfprintf(FILE *fp, const char *format, va_list ap);
int vdprintf(int fd, const char *format, va_list ap);
int vsprintf(char *str, const char *format, va_list ap);
int vsnprintf(char *str, size_t size, const char *format, 
              va_list ap);
```
所有printf函数都有一个`format`参数, 以`%`开始来描述输出的character的格式. 共有四个可选项
```text
%[flags][fldwidth][precision][lenmodifier]convtype
```

### 9.2 Formatted Input
```c
/**
 * @brief scan input according to `format` from stdin 
 * @return the number of input items matched and assigned on success; 
 *         EOF on error.
 */
int scanf(const char* format, ...);

/**
 * @brief same as scanf(), but read input from the stream.
 */
int fscanf(FILE* stream, const char* format, ...);

/**
 * @brief same as scanf(), but read input from the character string
 *        pointed to by str.
 */
int sscanf(const char* str, const char* format, ...);
```
以下3个函数与上述函数功能相同, 但使用`va_list`替代`...`
```c
int vscanf(const char *format, va_list ap);
int vsscanf(const char *str, const char *format, va_list ap);
int vfscanf(FILE *stream, const char *format, va_list ap);
```
Formatted Input也以`%`为起点来描述整个format参数. 共有三个可选项
```text
%[*][fldwidth][m][lenmodifier]convtype
```


## 10. Temporary Files
临时文件有三个用途:
* 内存不足时, 使用临时文件放置
* 写入数据大于系统的地址空间时, 使用临时文件放置
* 用于进程间的数据通信

```c
/**
 * @brief returns a pointer to a string that is a valid filename that
 *        does not exist at some point in time, so that programmers
 *        can use it as a suitable name for a temporary file. 
 * @param ptr If ptr is NULL, the generated pathname is stored in
 *        a static area, and a pointer to this  area is returned;
 *        If ptr is not NULL, and ptr is a array of at least L_tmpnam
 *        number of characters, the generated pathname is stored in 
 *        this array, and ptr is returned
 */
char* tmpnam(char* ptr);

/**
 * @brief create a temporary binary file that is automatically removed
 *        when it is closed or program termination.
 */
FILE* tmpfile(void);
```
需要注意的是, 如果我们使用`tmpnam()`后, 使用其返回的文件名调用`open()`创建文件, 可能有其他进程创建同名文件, 因此需设置为`open(filename, O_CREAT | O_EXCL | O_NOFOLLOW)`.
```c
/**
 * @brief generate a uniquely named temporary directory from template.
 * @param template the last six characters must be "XXXXXX" and these
 *        are replaced with a string that makes the directory name 
 *        unique.
 */
char* mkdtemp(char* template);

/**
 * @brief generate a unique temporary filename from `template`, create, 
 *        open the file, and return an open file descriptor for the file.
 * @param template The last six characters must be "XXXXXX" and these
 *        are replaced with a string that makes the filename unique.

 create a regular file with a unique name and 
 *        opens it. The temporary file will not be removed 
 *        automatically. The file created with access 
 *        permissions S_IRUSR | S_IWUSR.
 * @param template same as mkdtemp(), the last six 
 *        characters of template must be "XXXXXX".
 * @return The file descriptor for reading and writing.
 */
int mkstemp(char* template);
```
* `mkdtemp()`创建的文件夹的权限为`0700`
* `mkstemp`创建的文件的权限为`0600`


## 11. Memory Streams
Standard I/O会将数据缓存在buffer来加快处理速度, 且进程可创建自己的buffer. Single UNIX Specification Version 4后提供了memory streams来避免使用底层存储设备, 对于FILE stream的所有操作都在内存发生. 从而更快的处理数据.
```c
/**
 * @brief open a stream that permits the access specified 
 *        by type. The stream allows I/O to be performed on 
 *        the memory buffer pointed to by buf. This buffer 
 *        must be at least size bytes long.
 * @param buf if buf is NULL, the function allocates a 
 *        buffer of size bytes and the buffer will be freed 
 *        when the stream is closed.
 */
FILE* fmemopen(void *buf, size_t size, const char *type);
```
相对于file-based standard I/O streams, memrory stream有几点不同:
1. Memory stream的type设置为append后, file position会设置为buffer中的第一个NULL byte的位置. 若buffer中没有NULL byte, 则以buffer最后一个字节为file position.
2. 若buf为NULL, 则type不应设为只读或只写. 因为fmemopen()得到的stream无法获取buffer的地址, 所以写入的数据永远无法读取. 同理, buffer读取的内容永远无法修改或添加.
3. 当调用fclose(), fflush(), fseek(), fseeko()或fsetpos()时会在当前file position处添加一个NULL byte.

```c
/**
 * @brief open a stream for writing to a buffer. The buffer 
 *        is dynamically allocated, and automatically grows 
 *        as required. After closing the stream, the caller 
 *        should free this buffer.
 */
FILE *open_memstream(char **bufp, size_t *sizep);
FILE *open_wmemstream(wchar_t **bufp, size_t *sizep);
```