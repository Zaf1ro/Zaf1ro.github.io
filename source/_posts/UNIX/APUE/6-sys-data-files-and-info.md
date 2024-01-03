---
title: System Data Files and Infomation
category:
  - UNIX
  - APUE
tags:
  - UNIX
abbrlink: 4ad7
date: 2019-08-25 17:58:41
---

## 1. Password File
UNIX中的密码为`passwd`结构体, 该struct至少包含以下field:
```c
struct passwd {
  char *pw_name;    // login username
  char *pw_passwd;  // encrypted password
  uid_t pw_uid;     // user ID
  gid_t pw_gid;     // group ID
  char *pw_gecos;   // user information, such as phone number
  char *pw_dir;     // initial working directory, might be a null pointer
  char *pw_shell;   // initial shell when user logs in
}; 
```
对于绝大多数UNIX系统, `/etc/passwd`会作为密码库, 每一行包含一个passwd, 每一个field由`:`分割, 例如:
```text
root:x:0:0:root:/root:/bin/bash
squid:x:23:23::/var/spool/squid:/dev/null
nobody:x:65534:65534:Nobody:/home:/bin/sh
sar:x:205:105:Stephen Rago:/home/sar:/bin/bash
```
* root用户为**superuser**, 因为UID为0
* 曾经的UNIX会将密码单向hash的密码放在`/etc/passwd`, 但现代UNIX会用一个placeholder替代, 真正的密码被放在shadow database中, 只有特定权限才能访问.
* 每个用户都有一个shell用于执行命令, 默认为`/bin/sh`. 若为`/dev/null`, 任何输入都会被抛弃, 因此无法执行任何命令.
* nobody用户占用最后一位UID和GID: 65534. 该用户没有任何权限, 只能访问一些普通文件, 一般服务于FTP或HTTP远程访问的用户.
* 部分UNIX系统提供了`finger`命令来查看更多的信息:
  ```sh
  $ finger -p root
  Login: root                     Name: System Administrator
  Directory: /var/root            Shell: /bin/sh
  Last login Wed Jul 31 16:26 (EDT) on console
  No Mail.
  ```
* 部分UNIX系统提供`vipw`命令, 允许administrator来修改password文件. 

以下函数用于获取`passwd`的entry:
```c
/**
 * @brief return a pointer to a struct passwd with a matching entry 
 *        if matches the user ID `uid`
 * @return a null pointer shall be returned if the request entry is not
 *         found, or an error occur.
 */
struct passwd *getpwuid(uid_t uid);

/**
 * @brief return a pointer to a struct passwd with a matching entry 
 *        if match the username `name`.
 */
struct passwd *getpwnam(const char *name);

/**
 * @brief return a pointer to a struct passwd from the password database.
 *        It returns the first entry if it is the first call;
 *        thereafter, it returns successive entries.
 * @return a pointer to a passwd structure on success; NULL 
 *         on error and errno is set.
 */
struct passwd *getpwent(void);

/**
 * @brief rewind to the beginning of the password database.
 */
void setpwent(void);

/**
 * @brief close the password database after all processing has been
 *        performed.
 */
void endpwent(void);
```
需要注意的是, `getpwuid()`返回的`passwd`指针可能会被后续`getpwent()`, `getpwnam()`, 或`getpwuid()`重写, 导致内部数据无效化, 也会因当前线程中止而无效化.


## 2. Shadow Passwords
加密后的密码存放在**shadow password file**中. 由于加密算法是单向的, 因此即使知道加密后的hash值也无法知道密码. shadow password file中包含`spwd struct`:
```c
struct spwd {
  char *sp_namp;  /* user login name */
  char *sp_pwdp;  /* encrypted password */
  long sp_lstchg; /* days since Epoch when last change,  */
  long sp_min;    /* days until change allowed */
  long sp_max;    /* days before change required */
  long sp_warn;   /* days before password expires to warn user to change */
  long sp_inact;  /* days after password expires until account is disabled */
  long sp_expire; /* days since Epoch when account expires */
  unsigned long sp_flag; /* Reserved */
};
```
该文件只能被特定程序访问, 如`login()`, `passwd()`, 和设置了`set-user-ID`且文件所有者为`root`的可执行文件; password file可被任何用户访问.
```c
/**
 * @brief return a pointer to spwd struct containing the borken-out
 *        fields of the record in the shadow password file that 
 *        matches the username `name`.
 * @return NULL if no available entries or an error occurs
 */
struct spwd *getspnam(const char *name);

/**
 * @brief return a pointer to the next entry in the shadow password file.
 */
struct spwd *getspent(void);

/**
 * @brief rewind to the beginning of shadow password file.
 */
void setspent(void);

/**
 * @brief close the shadow password file.
 */
void endspent(void);
```


## 3. Group File
UNIX使用**group**划分不同user, 多个user可属于同一group. 由于文件权限分为三部分, 因此可通过设置group权限来控制特定user群体的权限. 
UNIX的group信息存放于**group file**, POSIX.1称为**group database**. 该文件通常位于`/etc/group`, 包含一个或多个`group struct`:
```c
struct group {
  char *gr_name;    /* group name */
  char *gr_passwd;  /* encrypted password */
  gid_t gr_gid;     /* numerical group ID */
  char **gr_mem;    /* array of pointers to individual user names */
};
```
POSIX也提供函数访问group file.
```c
/**
 * @brief return a pointer to a group struct with a matching entry 
 *        that matches group id
 * @return NULL of requested entry is not found, or an error occurrs
 */
struct group *getgrgid(gid_t gid);

/**
 * @brief return a pointer to a group struct with a matching entry 
 *        that matches group name
 group name.
 */
struct group *getgrnam(const char *name);

/**
 * @brief return a pointer to a structure containing the 
 *        broken-out fields of the entry in the group file. 
 *        The first time getgrent() is called, it returns 
 *        the first entry.
 */
struct group *getgrent(void);

/**
 * @brief rewind to the beginning of the group file.
 */
void setgrent(void);

/**
 * @brief close the group file after all processing has 
 *        been performed
 */
void endgrent(void);
```
需要注意的是, `getgrgid()`返回的指向`group struct`的指针会被后续`getgrent()`, `getgrgid()`, 或`getgrnam()`无效化; 中止当前线程也会令该指针无效化.


## 4. Supplementary Group IDs
UNIX设计之初并没有supplementary group, 一个user只属于一个group, 用户需要其他group的权限时, 则需调用`newgrp()`改变当前user的real group ID. Kernel检查进程是否拥有文件访问权限时, 只需对比进程的EGID与文件的GID. 执行完毕后, 用户需再次调用`newgrp()`切换回原本的group.
但user和group之间的关系不应为**多对一**, 而是**多对多**, 每个group可包含多个user, user也可处于多个group中. 4.2BSD添加了**supplementary group ID**. user仍拥有一个GID, 称为**primary group ID**, 但还拥有多个**supplementary group ID**. Kernel检查进程是否拥有文件的访问权限时, 若进程的EGID不匹配, 则对比supplementary group ID.
```c
/**
 * @brief returns the supplementary group IDs of the calling process
 *        in `list`
 * @param size shoudl be set to the maximum number of items that can be
 *        stored in the buffer pointed to by `list`.
 * @return number of supplementary group IDs on success, −1 
 *         on error
 */
int getgroups(int size, gid_t list[]);

/**
 * @brief set the supplementary group IDs for the calling process
 * @param size specify the number of supplementary group IDs in the 
 *        buffer pointed to by `list`. Zero means drop all of its 
 *        supplementary group
 * @return 0 on success, -1 if an error occurs
 */
int setgroups(size_t size, const gid_t *list);

/**
 * @brief obtain the supplementary group membership of `user`, and sets
 *        the current process supplementary group IDs to that list. 
 *        `group` is also included in the supplementary group IDs.
 * @return 0 on success; -1 on error and errno is set.
 */
int initgroups(const char *user, gid_t group);
```


## 5. Other Data Files
除了password file和group file, UNIX系统还包括其他文件: network service(`/etc/services`), internet protocols(`/etc/protocols`). UNIX提供以下函数来访问这些文件:
1. `get`: read the next entry of file.
2. `set`: open file if not already open, and rewind the file
3. `end`: close the data file

| Description | File Localtion | Header | Structure | Additional keyed lookup functions |
| :-----: | :-----: | :-----: | :-----: | :-----: |
| password | /etc/passwd | <pwd.h> | passws | getpwnam, getpwuid |
| groups | /etc/group | <grp.h> | group | getgrnam, getgrgid |
| shadow | /etc/shadow | <shadow.h> | spwd | getspnam |
| hosts | /etc/hosts | <netdb.h> | hostent | getnameinfo, getaddrinfo |
| networks | /etc.networks | <netdb.h> | netent | getnetbyname, getnetbyaddr | 
| protocols | /etc/protocols | <netdb.h> | protoent | getprotobyname, getprotobynumber |
| services | /etc/services | <netdb.h> | servent | getservbyname, getservbyport |


## 6. Login Accounting
UNIX提供了两个data file:
* utmp: 记录所有当前登录的用户
* wtmp: 记录所有登录和登出动作

```c
struct utmp {
  char ut_line[8]; /* device name of tty */
  char ut_name[8]; /* login name */
  long ut_time;    /* seconds since Epoch */
};
```
用户登录时, `login`程序会向`utmp`和`wtmp`写入一个`utmp struct`; 用户登出时, `init`进程从`utmp`中删除该用户, 并向`wtmp`写入一个新的`utmp struct`, 用**null username**表示用户在关联terminal上注销.


## 7. System Identification
```c
struct utsname {
  char sysname[];   /* name of the operating system */
  char nodename[];  /* name of this node */
  char release[];   /* current release of operating system */
  char version[];   /* current version of this release */
  char machine[];   /* hardware identifier */
};

/**
 * @brief store system inforamtion in the structure pointed to by `buf`
 * @return 0 on success; -1 on error and errno is set
 */
int uname(struct utsname *buf);
```
由于历史原因, `nodename`并不能表示TCP/IP上的hostname, 如需则调用`gethostname()`.
```c
/**
 * @brief return the null-terminated hostname in the character array 
 *        name, which has a length of `len` bytes. If the hostname is 
 *        too large to fit, then name is truncated.
 */
int gethostname(char *name, int len);
```


## 8. Time and Date Routines
UNIX使用UTC(Coordinated Universal Time)存储时间信息, 数据类型为time_t, 并会自动处理time zone, daylight saving time等问题. 
```c
/**
 * @brief return the current time as the number of seconds since the
 *        Epoch, 1970-01-01 00:00:00 +0000 (UTC)
 * @param t the return value is stored at `t`
 * @return the value of time in seconds since the Epoch on 
 *         success; -1 on error and errno is set
 */
time_t time(time_t *t);
```
除了`time_t`, 其他类型也可表示时间戳:
![Relationship of the various time functions](/images/UNIX/APUE/6-7-time-func.png)

### 8.1 timespec struct
```c
struct timespec {
  time_t tv_sec;  // seconds
  long tv_nsec;   // nanoseconds
}

/**
 * @brief retrieve the time of the specified clock `clk_id`
 * @param clk_id the identifier of the particular clock, must be one 
 *        of the following clocks:
 *        * CLOCK_REALTIME: settable system-wide realtime clock
 *        * CLOCK_MONOTONIC: nonsettable system-wide clock derived 
 *          from wall-clock time but ignoring leap seconds
 *        * CLOCK_PROCESS_CPUTIME_ID: a clock that measures CPU time 
 *          consumed by this process
 *        * CLOCK_THREAD_CPUTIME_ID: a clock that measures CPU time 
 *          consumed by this thread
 * @return 0 on success; -1 on error and errno is set
 */
int clock_gettime(clockid_t clk_id, struct timespec *tsp);

/**
 * @brief set the time of the specified clock `clk_id`
 */
int clock_settime(clockid_t clk_id, const struct timespec *tsp);

/**
 * @brief find the resolution of the specified clock clk_id 
 *        If res is not NULL, stores it in `res`.
 */
int clock_getres(clockid_t clk_id, struct timespec *res);
```
* 任何物理时钟都存在偏差, 计算机运行的越久, 与实际时间的偏差越大, 因此需要管理员手动修改, 或NTP纠正, `CLOCK_REALTIME`则表示最接近实际的时间; 但该时间可能不连续, 例如, 第一次获取的时间小于第二次获取的时间, 给人一种时间回溯的感觉, 因此引入`CLOCK_MONOTONIC`, 该时间无法被修改, 可用于计算两个事件之间的时间差.
* UNIX支持多进程, 但进程并发受限于很多因素(如CPU数量), 因此进程可能处于等待队列, 计算一个程序的实际性能时, 我们只想知道程序的实际运行时间, 可使用`CLOCK_PROCESS_CPUTIME_ID`


### 8.2 tm structure
```c
struct tm {
  int tm_sec;   /* second [0, 60] */
  int tm_min;   /* minute [0, 59] */
  int tm_hour;  /* hour [0, 23] */
  int tm_mday;  /* day of month [1, 31] */
  int tm_mon;   /* month of year [0, 11] */
  int tm_year;  /* years since 1900 */
  int tm_wday;  /* day of week [0, 6] (Sunday = 0) */
  int tm_yday;  /* day of year [0, 365] */
  int tm_isdst; /* daylight savings flag */
};

/**
 * @brief convert the time in seconds since the Epoch to a 
 *        broken-down UTC time.
 */
struct tm *gmtime(const time_t *timep);

/**
 * @brief convert broken-down time into time since the Epoch
 */
time_t mktime(struct tm *tm);

/**
 * @brief convert the time in seconds since the Epoch into a 
 *        broken-down time. The function corrects for the timezone 
 *        and any seasonal time adjustments
 */
struct tm *localtime(const time_t *timep);

/**
 * @brief format the borken-down time `tm` according to the conversion
 *        specification `format` and place the result in the array 
 *        pointed to by `s` of size `max`.
 */
size_t strftime(char *s, size_t max, const char *format, const struct tm *tm);

/**
 * @brief convert the character string pointed to by `s` to values 
 *        which are stored in the broken-down time 
 *        structure pointed to by tm
 */
char *strptime(const char *s, const char *format, struct tm *tm);
```

Conversion sepcifier for `strftime()`:

Format | Description | Example
-----|-----|-----
%a | abbreviated weekday name | Thu
%A | full weekday name | Thursday
%b | abbreviated month name | Jan
%B | full month name | January
%c | date and time | Thu Jan 19 21:24:52 2012
%C | year/100: [00–99] | 20
%d | day of the month: [01–31] | 19
%D | date [MM/DD/YY] | 01/19/12
%e | day of month (single digit preceded by space) [1–31] | 19
%F | ISO 8601 date format [YYYY–MM–DD] | 2012-01-19
%g | last two digits of ISO 8601 week-based year [00–99] | 12
%G | ISO 8601 week-based year | 2012
%h | same as %b | Jan
%H | hour of the day (24-hour format): [00–23] | 21
%I | hour of the day (12-hour format): [01–12] | 09
%j | day of the year: [001–366] | 019
%m | month: [01–12] | 01
%M | minute: [00–59] | 24
%n | newline character | 
%p | AM/PM | PM
%r | locale’s time (12-hour format) | 09:24:52 PM
%R | same as %H:%M | 21:24
%S | second: [00–60] | 52
%t | horizontal tab character | 
%T | same as %H:%M:%S | 21:24:52
%u | ISO 8601 weekday [Monday = 1, 1–7] | 4
%U | Sunday week number: [00–53] | 03
%V | ISO 8601 week number: [01–53] | 03
%w | weekday: [0 = Sunday, 0–6] | 4
%W | Monday week number: [00–53] | 03
%x | locale’s date 01/19/ | 12
%X | locale’s time 21:24: | 52
%y | last two digits of year: [00–99] | 12
%Y | year | 2012
%z | offset from UTC in ISO 8601 format | -0500
%Z | time zone name | EST
%% | translates to a percent sign | %
