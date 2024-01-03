---
title: Input/Output on Streams
tags:
  - C/C++
category:
  - C/C++
abbrlink: 5e6b
date: 2020-09-19 23:27:15
keywords:
description:
---

## 1. Streams
由于历史原因, 表示stream的C data structure称为**FILE**而不是**stream**, 定义在**stdio.h**头文件中. FILE对象拥有与文件相关联的连接中的所有中间状态,例如file position indicator和buffering信息. 每个stream都拥有**error**和**EOF status indicator**.
FILE对象通过input/output library function来分配和管理, 不要尝试创造自己的FILE结构体, 只需要使用指针(FILE*).


## 2. Standard Streams
当main函数被调用时, 就会有三个streams被开启并可用:
* FILE *stdin: standard input stream, 作为程序的输入源
* FILE *stdout: standard output stream, 作为程序的正常输出
* FIEL *stderr: standard error stream, 作为程序的错误信息用于诊断

GNU系统中, 你可以使用shell提供的pipe或redirection facilities来指定文件或进程对应的stream. 以下是redirect stdout的例子:
```c
fclose (stdout);
stdout = fopen ("standard-output-file", "w");
```


## 3. Opening Streams
使用fopen()打开一个文件会创造一个stream, 并建立一个stream与file之间的连接, 也可能会创造一个新文件.
```c
/**
 * @brief open a stream for I/O to the file `filename`
 * @param opentype a string that controls how the file is opened and specifies attributes of the stream
 *        must begin with one of the following sequences of characters:
 *        r: open an existing file for reading only
 *        w: wirte only. If the file already exists, it is truncated to zero length. Otherwise a new file is created 
 *        r+: open an existing file for reading and writing. The initial contents of the file are unchanged and
 *            the initial file position is at the beginning of the file
 *        w+: open a file for reading and writing. If the file already exists, it is truncated to zero length.
 *            Otherwise, a new file is created
 *        a+: Open or create file for reading and appending. If the file exists, its initial content are unchanged.
 *            The initial file position is at the beginning of the file, but ouput is appended to the end of the file
 * @return a pointer to the stream. If the open fails, return a null pointer
 */
FILE *fopen (const char *filename, const char *opentype);

/**
 * @brief a combination of fclose() and fopen(). It first closes the stream referred to by stream, ignoring any errors
 *        that are detected in the process. The the file named `filename` is opened with mode `opentype` as for fopen(),
 *        and associated with the same stream object `stream`
 */
FILE *freopen (const char *filename, const char *opentype, FILE *stream);

/**
 * @brief determine whether the stream was opened to allow reading
 * @return return nonzero for readable, zero for write-only stream
 */
int __freadable (FILE *stream);

/**
 * @brief determine whether the stream was opened to allow writing
 * @return return nonzero for writable, zero for read-only stream
 */
int __fwritable (FILE *stream);

/**
 * @brief return nonzero if the stream is read-only, or if the last operation on the stream was a read operation;
 *        return zero otherwise
 */
int __freading (FILE *stream);

/**
 * @brief return nonzero if the stream is write-only, or if the last operation on the stream was a write operation;
 *        return zero otherwise
 */
int __fwriting (FILE *stream);
```
程序可以指定多个stream指向同一个文件. 


## 4. Close Streams
当调用fclose()关闭某个stream时, stream与file的连接会被取消. 程序可以在关闭stream后, 对stream进行其他操作.
```c
/**
 * @brief cause stream to be closed and the connection to the corresponding file to be broken.
 *        Any buffered output is written and any buffered input is discarded.
 * @return return zero if the file is closed successfully, and EOF if an error is detected
 */
int fclose (FILE *stream);

/**
 * @brief cause all open streams of the process to be closed and the connections to corresponding files to be broken.
 *        All buffered data is written and any buffered input is discarded.
 * @return return zero if all the files are closed successfully, and EOF if an error is detected
 */
int fcloseall (void);
```
当main()运行结束, 或调用exit()时, 所有开启的stream都会被正确地关闭. 若程序因为意外终止运行, 或调用abort(), 或被signal打断, 所有开启的stream可能不会被正确地关闭. Buffered iytput可能不会被flush, 文件也可能会不完整. 


## 5. Streams and Threads
Stream在单线程应用和多线程应用的使用相同. POSIX standard要求stream操作为atomic, 因此, 当同时对某个stream进行两次stream操作, 操作会依序进行. 每个stream都会有一个lock object, 只有获得了该lock object才能进行stream操作. 但stream内部的lock object并不足以让多个stream操作可以原子性地调用, 举个例子, 当程序需要调用多个stream操作来输入或输出时, 每个stream操作都可以保证自己是atomic, 但并不能保证这些操作整体上是atomic, 因此依然需要使用其他lock.
```c
/**
 * @brief acquire the internal locking object assoicated with the stream. This ensures that no other thread can lock
 *        the stream through flockfile/ftrylockfile or call a stream function
 */
void flockfile (FILE *stream);

/**
 * @brief try to acquire the internal locking object assoicated with the stream, but does not block if the lock is 
 *        not available
 * @return return zero if the lock is successfully acquired, nonzero if otherwise
 */
int ftrylockfile (FILE *stream);

/**
 * @brief release the internal locking object of the stream. The stream must have been locked before by a call of 
 *        flockfile() or ftryfilelock(), not including the locking performed by the stream operation
 */
void funlockfile (FILE *stream);
```
以下是原子性运行多个stream操作的例子:
```c
FILE *fp;
{
   flockfile (fp);
   fputs ("This is test number ", fp);
   fprintf (fp, "%d\n", test);
   funlockfile (fp)
}
```
如果没有调用flockfile(), fputs()和fprintf()之间可能有其他线程对**fp**进行stream操作. 但locking operation并不是毫无代价的, 每次尝试获得lock都需要内存操作, 因此应避免使用locking operation. 以下是两种避免lock的机制:
1. _unlocked stream operation: POSIX standard中定义了一些unlocked stream operation, 该类函数不会使用stream内部的lock, 因此速度上有很大提升. 并且, 该类函数使用macro实现, 也会比普通的stream函数快. 以下是_unlocked function的例子:
  ```c
  void foo (FILE *fp, char *buf)
  {
    flockfile (fp);
    while (*buf != '/')
      putc_unlocked (*buf++, fp);
    funlockfile (fp);
  }
  ```
2. 使用non-standard function来避免locking
  ```c
  /**
   * @brief select whether the steam operations will implicitly acquire the locking object of the stream
   * @param type must be one of the following values:
   *        FSETLOCKING_INTERNAL: use the default internal locking except _unlocked variants
   *        FSETLOCKING_BYCALLER: none of the stream will implicitly lock the stream
   *        FSETLOCKING_QUERY: query the current locking state of the stream
   */
  int __fsetlocking (FILE *stream, int type);
  ```


## 6. Simple Output by Characters or Lines
```c
/* convert the character `c` to type `unsigned char`, and write it to the stream */
int fputc (int c, FILE *stream);

/* write the wide character `wc` to the stream */
wint_t fputwc (wchar_t wc, FILE *stream);

/* equivalent to fputc() except that it does not implicitly lock the stream */
int fputc_unlocked (int c, FILE *stream);

/* equivalent to fputwc() except that it does not implicitly lock the stream */
wint_t fputwc_unlocked (wchar_t wc, FILE *stream);

/* just like fputc, except that the most systems implements it as a macro */
int putc (int c, FILE *stream);

/* just like fputwc, except that it can be implement as a macro  */
wint_t putwc (wchar_t wc, FILE *stream);

/* equivalent to the putc() except that it does not implicitly lock the stream  */
int putc_unlocked (int c, FILE *stream);

/* equivalent to the putwc() except that it does not implicitly lock the stream */
wint_t putwc_unlocked (wchar_t wc, FILE *stream);

/* equivalent to putc() with stdout as the value of `stream` */
int putchar (int c);

/* equivalent to putwc() with stdout as the value of `stream` */
wint_t putwchar (wchar_t wc);

/* equivalent to the putchar() except that it does not implicitly lock the stream */
int putchar_unlocked (int c);

/* equivalent to the putwchar() except that it does not implicitly lock the stream */
wint_t putwchar_unlocked (wchar_t wc);

/* write the string `s` to the stream. The terminating null character is not written */
int fputs (const char *s, FILE *stream);

/* write the wide character string `ws` to the stream. The terminating null character is not written */
int fputws (const wchar_t *ws, FILE *stream);

/* equivalent to the fputs() except that is does not implicitly lock the stream */
int fputs_unlocked (const char *s, FILE *stream);

/* equivalent to the fputws() except that is does not implicitly lock the stream  */
int fputws_unlocked (const wchar_t *ws, FILE *stream);

/* write the string `s` to the stream stdout followed by a newline */
int puts (const char *s);

/* write the word `w` to stream */
int putw (int w, FILE *stream);
```


## 7. Character Input
```c
/* read the next character as an unsigned char from the stream and return its value */
int fgetc (FILE *stream);

/* read the next wide chacter from the stream and return its value */
wint_t fgetwc (FILE *stream);

/* equivalent to the fgetc() except that it does not implicitly lock the stream */
int fgetc_unlocked (FILE *stream);

/* equivalent to the fgetwc() except that it does not implicitly lock the stream */
wint_t fgetwc_unlocked (FILE *stream);

/* just like fgetc(), except that it's implemented as a macro */
int getc (FILE *stream);

/* just like fgetwc(), except that it's implemented as a macro */
wint_t getwc (FILE *stream);

/* equivalent to getc() except that it does not implicitly lock the stream */
int getc_unlocked (FILE *stream);

/* equivalent to getwc() except that it does not implicitly lock the stream */
wint_t getwc_unlocked (FILE *stream);

/* equivalent to getc() with stdin as the value of stream argument */
int getchar (void);

/* equivalent to getwc() with stdin as the value of stream argument  */
wint_t getwchar (void);

/* equivalent to getchar() except that it does not implicitly lock the scream */
int getchar_unlocked (void);

/* equivalent to getwchar() except that it does not implicitly lock the scream */
wint_t getwchar_unlocked (void);
```


## 8. Line-Oriented Input
```c
/* read an entire line from stream, storing the text(including terminating null character) in a buffer starting in `*lineptr`
 * If *lineptr is null pointer and *n is zero, getline() will allocate the initial buffer by calling malloc
 */
ssize_t getline (char **lineptr, size_t *n, FILE *stream);

/* just like getline() except that the character which tells it to stop reading is not necessarily newline */
ssize_t getdelim (char **lineptr, size_t *n, int delimiter, FILE *stream);

/* read characters from the stream until:
 * 1. count-1 bytes are read
 * 2. newline is read
 * 3. EOF is read
 * A terminating null byte is stored after the last character in the buffer
 */
char * fgets (char *s, int count, FILE *stream);

/* wide-character equivalent of the fgets() */
wchar_t * fgetws (wchar_t *ws, int count, FILE *stream);

/* equivalent to fgets() except that it does not implicitly lock the stream */
char * fgets_unlocked (char *s, int count, FILE *stream);

/* equivalent to fgetws() except that it does not implicitly lock the stream */
wchar_t * fgetws_unlocked (wchar_t *ws, int count, FILE *stream);

/* read a line from the stdio into the buffer pointed to by s until a terminating newline or EOF */
char * gets (char *s);
```

## 9. Unreading
stream I/O的读取操作会直接将字符从stream中移除, 如果想将字符重新放回stream, 可调用unread函数, 下次调用fgetc()可获得该字符.

### 9.1 What Unreading Means
假设某一stream正在读取文件数据, 文件中包含6个字符`foobar`. 假设已经读取了3个字符, 如下图:
```code
f o o b a r
      $\uparrow$
```
下一个读取的字符为**b**, 这时可以unread字符**o**, 如下:
```code
f o o b a r
    o
    $\uparrow$ 
```
这时下一个字符为**o**而不是**b**. 如果unread **9**, 则如下:
```code
f o o b a r
    9
    $\uparrow$
```
下个读取的字符为**9**而不是**b**.

### 9.2 Using ungetc To Do Unreading
```c
/**
 * @brief push back the character `c` onto the input stream
 * @return the character put back is returned on success, EOF on failure
 */
int ungetc (int c, FILE *stream);

/**
 * @brief behave just like ungetc() that it pushed back a wide character
 */
wint_t ungetwc (wint_t wc, FILE *stream);
```
unread的字符不必为最近读取的字符, 但一般来说, unread会用于将刚读取的字符返回到stream中. unread的字符并不会改变文件, 只会改变stream的buffer. 当调用file positioning function时, 所有unread的字符都会被抛弃. 在文件末尾unread字符会清除EOF flag, 只有读取完该字符才能读取到EOF.


## 10. Block Input/Output
```c
/**
 * @brief read `count` objects of size `size` into the array `data` from the stream
 * @return return the numbers of objects actually read
 */
size_t fread (void *data, size_t size, size_t count, FILE *stream);

/**
 * @brief equivalent to fread() except that it does not implicitly lock the stream
 */
size_t fread_unlocked (void *data, size_t size, size_t count, FILE *stream);

/**
 * @brief write `count` objects of size `size` from the array `data` to the stream
 */
size_t fwrite (const void *data, size_t size, size_t count, FILE *stream);

/**
 * @brief equivalent to fwrite() except that it does not implicitly lock the stream 
 */
size_t fwrite_unlocked (const void *data, size_t size, size_t count, FILE *stream);
```


## 11. End-Of-File and Errors
大部分stream函数会返回EOF来表示操作失败. 由于EOF既表示文件末尾, 也表示操作失败, 因此需要使用**feof()**来区分.
```c
/**
 * @brief return nonzero if the EOF indicator for the stream is set
 *        The EOF flag is set when user attempts to read past the EOF
 */
int feof (FILE *stream);

/**
 * @brief equivalent to feof() except that it does not implicitly lock the stream
 */
int feof_unlocked (FILE *stream);

/**
 * @brief return nonzero if the error indicator for the stream is set
 */
int ferror (FILE *stream);

/**
 * @brief equivalent to ferror() except that it does not implicitly lock the stream
 */
int ferror_unlocked (FILE *stream);
```


## 12. Recover from errors
可通过以下函数来清楚EOF flag和error:
```c
/**
 * @brief clear the end-of-file and error indicator for the stream
 */
void clearerr (FILE *stream);

/**
 * @brief equivalent to clearerr() except that it does not implicitly lock the stream
 */
void clearerr_unlocked (FILE *stream);
```


## 13. Text Stream and Binary Stream
Text stream和binary stream的区别如下:
1. Text stream以line为单位进行读取, 每个line之间用newline chacter分开; 而binary stream中没有line这一概念, 只有一串字符. 在某些系统中, line的长度限制为254字符.
2. 在某些系统中, text stream只能将printable character, tab character和newline写入到文件中; 而binary stream则可以处理任意字符.
3. 在某些系统中, newline前面的space可能会被忽略, 导致下次读取时消失
4. 对于text stream, 输入和输出的字符并不一定为文件中的字符; 对于binary stream, 输入和输出的字符一定和文件相同

整体来说, binary stream比text stream更可靠和可预测, 那为什么不直接使用binary stream呢? 这是因为在某些系统中, text stream和binary stream使用不同的文件格式, 当读取和写入文本文件时, 只能使用text stream. 但对于GNU C Library和其他POSIX system, text stream和binary stream没有区别.


## 14. File Positioning
File positioning用于描述文件在stream中读取和写入的位置. I/O操作会让stream中的file position向前推进. 在GNU系统中, file position作为一个integer表示从文件头部到当前位置中间的字节数. 部分文件支持移动file position, 这类文件称为random-access file.
```c
/**
 * @brief return the current file position of the stream
 * @return -1 on failure if stream does not support file positioning
 */
long int ftell (FILE *stream);

/**
 * @brief similiar to ftell, except that it returns a value of type off_t
 */
off_t ftello (FILE *stream);

/**
 * @brief change the file position of stream
 * @param whence must be one of the following values:
 *        1. SEEK_SET: offset is relative to the beginning of the file
 *        2. SEEK_CUR: offset is relative to the current file position
 *        3. SEEK_END: offset is relative to the end of the file
 * @return zero on success, nonzero on failure
 */
int fseek (FILE *stream, long int offset, int whence);

/**
 * @brief similiar to fseek() but fix a problem with POSIX types. 
 *        Type long int for the offset is not compatible with POSIX.
 */
int fseeko (FILE *stream, off_t offset, int whence);

/**
 * @brief position the stream at the beginning of the file
 *        equivalent to fseek(stream, 0, SEEK_SET)
 */
void rewind (FILE *stream);
```


## 15. Portable File-Position Functions
在GNU系统中, file position表示字符数; 但在某些ISO C系统中, text stream和binary stream不同, 无法使用字符数来表示text stream中的file position. 举例: 在某些系统中, file position包含record在文件中的offset, 和record中的character offset. 因此如果想要实现可移植性, 需要遵循以下规定:
* ftell()的返回值与当前file position距离文件头部的字符数并无任何关系, 只能保证在fseek()和fseeko()中使用该返回值可以回到相同的file position.
* 当对text stream使用fseek()或fseeko()时, 要么保证offset为0, 要么保证在whence为**SEEK_SET**时, offset为该stream的ftell()返回值.
* 当使用ungetc()时, text stream中的file position变为undefined, 直到ungetc()的字符被读取.

但即使严格遵守以上规定, 面对超大文件时还是会遇到问题: 由于ftell()和fseeko()使用**long int**表示file position, 可能不足以表示超大文件中的file position. 但对于ftello()和fseeko(), 其使用**off_t**类型, 该类型可以确保可以覆盖所有file position. 如果想应对不同系统的不同编码, 可使用fgetpos()和fsetpos(), 这两个函数使用**fpos_t**来表示系统中的file position, 不同的系统会对该类型有不同的定义.
```c
/**
 * @brief store the value of file position indicator for the stream in the fpos_t object
 * @return zero on success; otherwise nonzero on failure
 */
int fgetpos (FILE *stream, fpos_t *position);

/**
 * @brief set the file position for the stream to the position
 * @return zero on success, clear the end-of-file indicator on the stream, discard any
 *         character that were pushed back by ungetc(); nonzero on failure
 */
int fsetpos (FILE *stream, const fpos_t *position);
```


## 16. Stream Buffering
被写入到stream中的字符会先在一个block中保存, 并异步传输到文件中, 而不是立即写入文件. 相同的, stream会将文件中的一块数据放入block, 而不是一个个字符读取. 这一策略称为buffering. 当程序中使用stream为用户做交互式输入和输出时, 需要了解buffering的工作流程. 

### 16.1 Buffering Concepts
以下是三种不同的buffering策略:
* unbuffered stream: 立即从文件中读取或写入字符
* line buffered stream: 只有遇到newline character才触发文件写入操作
* fully buffered stream: 当buffer满的时候再触发文件操作

除了连接到terminal的stream为line buffered stream, 其他stream几乎都是fully buffered stream. 

### 16.2 Flush Buffers
Flush a buffered stream意味着将所有字符写入到文件中, 以下是自动flush的几种情况:
* buffer已满, 程序执行output操作
* stream被关闭
* 程序调用exit()
* stream为line buffered且输入newline character
* 程序对该文件进行input操作

```c
/**
 * @brief cause any buffered output on stream to be delivered to the file,
 *        cause buffered output on all open output stream to be flushed if `stream` is null
 */
int fflush (FILE *stream);

/**
 * @brief equivalent to fflush() except that it does not implicitly lock the stream
 */
int fflush_unlocked (FILE *stream);

/**
 * @brief flush all line buffered streams currently opened
 */
void _flushlbf (void);

/**
 * @brief cause the buffer of stream to be emptied
 */
void __fpurge (FILE *stream);
```

### 16.3 Control Which Kind of Buffering
```c
/**
 * @brief specify that the stream should have the buffering mode
 * @param buf if buf argument is a null pointer, setvbuf() allocates a buffer itself using malloc()
 * @param mode must be one of the following values:
 *        1. _IOFBF: stream should be fully buffered
 *        2. _IOLBF: stream should be line buffered
 *        3. _IONBF: stream sbhould be unbuffered
 * @param size the size of buffer
 */
int setvbuf (FILE *stream, char *buf, int mode, size_t size);

/**
 * @brief if buf is a null pointer, this function is equivalent to setvbuf with a mode argument of _IONBF,
 *        otherwise it is equivalent to calling setvbuf with buf, and a mode of _IOFBF and a size argument of BUFSIZ
 */
void setbuf (FILE *stream, char *buf);

/**
 * @brief if buf is null pointer, this function makes stream unbuffered, 
 *        otherwise it makes stream fully buffered using buf
 */
void setbuffer (FILE *stream, char *buf, size_t size);

/**
 * @brief make stream be line buffered and allocate the buffer for you
 */
void setlinebuf (FILE *stream);

/**
 * @brief return a nonzero value in case the stream is line buffered, otherwise return zero
 */
int __flbf (FILE *stream);

/**
 * @brief return the size of the buffer in the stream
 */
size_t __fbufsize (FILE *stream);

/**
 * @brief return the number of bytes currently in the output buffer
 */
size_t __fpending (FILE *stream);
```


## 17. Other Kinds of Streams
### 17.1 String Streams
没有底层I/O操作, 所有I/O操作都通过buffer和内存之间传送数据. 
```c
/**
 * @brief open a stream that allows the access specified by opentype argument, and 
 *        read from or write to the buffer specified by buf argument, the buf must
 *        be at least size bytes long.
 *        When stream open for writing is closed or flushed, a null byte is written 
 *        at the end of the buffer if there is space.
 *        For a stream open for reading, null character in the buffer do not count 
 *        as end-of-file.
 */
FILE * fmemopen (void *buf, size_t size, const char *opentype);

/**
 * @brief open a stream for writing to a buffer. The buffer is allocated dynamically,
 *        and grown as necessary. The buffer will not be cleaned up automatically.
 *        When stream is closed or flushed, ptr and sizeloc are updated to contain
 *        the pointer to the buffer and is size. 
 *        
 */
FILE * open_memstream (char **ptr, size_t *sizeloc);
```
以下是fmemopen()和open_memstream()的例子:
```c
/* fmemopen() */
static char buffer[] = "foobar";
int main (void)
{
  int ch;
  FILE *stream;

  stream = fmemopen (buffer, strlen (buffer), "r");
  /* output: foobar */
  while ((ch = fgetc (stream)) != EOF)
    printf ("%c", ch);
  fclose (stream);

  return 0;
}

/* open_memstream() */
int main (void)
{
  char *bp;
  size_t size;
  FILE *stream;

  stream = open_memstream (&bp, &size);
  fprintf (stream, "hello");
  fflush (stream);
  printf ("buf = %s, size = %zu\n", bp, size); /* buf = hello, size = 5 */
  fprintf (stream, ", world");
  fclose (stream);
  printf ("buf = %s, size = %zu\n", bp, size); /* buf = hello, world, size = 12 */

  return 0;
}
```

### 17.2 Custom Streams and Cookies
在custom stream中有一个特殊的object称为**cookie**, 该对象记录了每一次存储和读取数据. stream function不会直接使用到该参数, 甚至都不知道cookie的类型. 为了实现custom stream, 需要指定如何在特定的位置读取或存储数据, 为此需要**hook function**实现读取, 写入, 改变file postion, 和关闭stream. 这四种操作都要经过stream cookie, 从而让cookie知道数据在哪里被读取或写入. 当创建custom stream时, 需要指定cookie pointer, 并且四个hook functions存储在**cookie_io_functions_t**中:
```c
typedef struct {
  cookie_read_function_t  *read;  /* read operations for the stream */
  cookie_write_function_t *write; /* write operations for the stream */
  cookie_seek_function_t  *seek;  /* seek operations on the stream */
  cookie_close_function_t *close; /* close the stream */
} cookie_io_functions_t;

/**
 * @brief create the stream for communicating with the cookie
 * @return the newly stream or a null pointer
 */
FILE * fopencookie (void *cookie, const char *opentype, cookie_io_functions_t io-functions);
```

### 17.3 Custom Stream Hook Functions
```c
/**
 * @brief read data from the cookie
 */
ssize_t reader (void *cookie, char *buffer, size_t size);

/**
 * @brief write data to the cookie
 */
ssize_t writer (void *cookie, const char *buffer, size_t size);

/**
 * @brief seek operation on the cookie
 */
int seeker (void *cookie, off64_t *position, int whence);

/**
 * @brief cleanup operation on the cookie for closing the stream
 */
int cleaner (void *cookie);
```
