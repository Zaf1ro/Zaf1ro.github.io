---
title: Cookie
category:
  - Network
tag:
  - Network
abbrlink: '4958'
date: 2017-05-15 10:55:42
---

## 1. Cookie简介
由于HTTP奉行的无状态原则, 导致Server无法判断这一次请求的的Client和下一次请求的Client是否为同一Client. Cookie的诞生使得Server可根据Cookie值来区分Client. Cookie目前有两个版本:Version 0和Version 1, 通过"Set-Cookie"和"Set-Cookie2"来标示, 也可通过Version值来判断.


## 2. Version 0
### 2.1 Syntax
* `<cookie-name>=<cookie-value>`: 必填项. 状态信息的名字为name, 其对应的值为value. name不可与其他属性项的名字重复.
* `expires=<date>`: 可选项. Cookie过期的时间, 格式: Wdy, DD-Mon-YY HH:MM:SS GMT. 未设置则设为本次回话结束.
* `max-age=<non-zero-digit>`: 可选项. 与expires功能一样, 指定cookie的生存周期(单位为秒). 如果max-age和expires都设置, max-age优先级更高.
* `domain=<domain-value>`: 可选项. 指定Cookie将要发送给哪个域.
* `path=<path-value>`: 可选项. 指定请求URL中必须存在的路径, 未设置此项则默认为'/'
* `secure`: 可选项. 通过SSL创建时会有该项, 没有value值. 未设置此项则说明不是HTTPS.
* `HttpOnly`: 可选项. 使得Cookie的创建和修改只能通过Server发给Client的response中获得, 不可通过Javascript来操作Cookie. 此项可让网站免受XSS attacks. 未设置此项则允许Javascript操作Cookie.
* `SameSite=Strict/Lax`: 可选项. Google为阻止CSRF和XSSI所进行的实验性机制, 从Chrome Dev 51.0.2704.4开始实行.

### 2.2 Compatibility
Feature | Chrome | Edge | Firefox | IE | Opera | Safari
-----|-----|-----|-----|-----|-----|-----
Basic Support | YES | YES | YES | YES | YES | YES
Max-Age | YES | YES | YES | 8.0 | YES | YES
HttpOnly | 1.0 | YES | 3.0 | 9.0 | 11 | 5.0
Cookie prefixes | 49 | YES | 50 | ? | 36 | YES
SameSite | 51 | No support | No support | No support | 39 | No support



## 3. Version 1
### 3.1 Syntax
RFC6265中明确指出Set-Cookie2已被废弃.
* `<cookie-name>=<cookie-value>`
* `Comment=<value>`: 可选项. 标明此Cookie的用途, Client可通过此项决定是否使用该Cookie.
* `Discard`: 可选项. 是否在会话结束后丢弃此Cookie.
* `Domain=<domain-value>`
* `Max-Age=<non-zero-digit>`
* `Path=<path-value>`
* `Port=<port-number>`: 可选项. 决定某些端口下携带该Cookie的Request可以发送给Server. 可选择多个端口, 逗号分开.
* `Secure`
* `Version=<version-number>`

### 3.2 Compatibility
Feature | Chrome | Edge | Firefox | IE | Opera | Safari
-----|-----|-----|-----|-----|-----|-----
Set-Cookie2 | No support | No support | No support | No support | No support | No support


## 4. Cookie的注意事项
### 4.1 cookie-name和cookie-value的规则
1. cookie-name不能包含的字符: 控制字符(CTLs, 例如:`LF CR DEL BS BEL`)和分隔字符(separator character, 如`( ) < > @ , ; : \ " /  [ ] ? = { }`)
2. cookie-value需写在`""`中, 内容可为任何ASCII字符, 除了`CTLs whitespace "" , ; \`
3. RFC中并没有点明cookie-name和cookie-value是否需要经过URL编码, 但通常情况下都会对其进行URL编码
4. 一个Set-Cookie中只能有一对`cookie-name=cookie-value`, 一个Response中可有多个Set-Cookie

### 4.2 domain的匹配问题
1. 若cookie中domain没有包含Server的域名, 那么user agent会拒绝 该cookie
2. 若cookie中不含有domain, 则request的domain为cookie的domain
3. domain与request中的URL的匹配规则(RFC6265)如下:
   1. Request中的URL必须是一个host name(不能为ip地址)
   2. Domain应为request中URL的一个后缀
   3. Request中URL的最后一个字符可以为`.`, 但domain不能
   4. 若domain以`.`开头, 则匹配时将忽略这个`.`

### 4.3 Cookie prefixes: __Host-和__Secure-
在如下条件下, Set-Cookie的cookie-name的前缀可以设置为`__Host-`和`__Secure-`的前缀
* 连接方式为HTTPS, 且必须设置secure
* `__Host-`前缀必须包含`path=/`, 且不能有domain

以下是Set-Cookie样例:
```
Set-Cookie: __Secure-ID=123; Secure; Domain=example.com
Set-Cookie: __Host-ID=123; Secure; Path=/
```

### 4.4 SameSite机制
SameSite的value可二选一: Strict或Lax
* Strict
最严格的防护机制. 所有跨域的Request都将不会携带原本的cookie信息. 假设Client从a.com获得如下cookie:
```
Set-Cookie: id1=1; SameSite=Strict
Set-Cookie: id2=2
```
当Client在b.com发起对a.com的请求时, id1将不会包含在Cookie请求部分中.
* Lax
宽松模式. 在上述情况中, 如果跨域请求为GET请求, 则不会限制Cookie; 如果为POST请求则不会传递Cookie信息. 假设Client从a.com获得如下cookie:
```
Set-Cookie: id1=1; SameSite=Strict
Set-Cookie: id2=2; SameSite=Lax
Set-Cookie: id3=3
```
当Client在b.com发起对a.com的POST请求时, 只有id3会包含到Cookie的请求部分中; 如果发起的是GET请求, 则id2和id3都会包含到Cookie的请求部分中.

### 4.5 Cookie的个数限制和大小限制
各个浏览器对于单个domain下能存储多少个cookie和单个cookie的最大字节都有所不同, 以下是不权威统计:

Feature | Chrome8-* | Firefox24-* | IE6-7 | IE8-11 | Opera26 | Safari7-*
-----|-----|-----|-----|-----|-----|-----
Max Cookies | 180 | 150 | 50 | 50 | 180 | N/A
Max Size per Cookie(byte) | 4096 | 4097 | 4095 | 5117 | 4096 | 4096

可以发现Safari没有限制单个domain的cookie数量, 假设我们载入1k个cookie, 每个cookie大小为4k, 那么下一次对于该domain发送的request大小将大于`1k*4k`. 如此大的header size将导致溢出错误, Server将返回HTTP Status Code: 413.


## 5. 实例
打开一个小型网站,可以发现首次访问时就加载了7个Cookie文件
### 5.1 从网页加载完毕后domain归属来看:
* hm.baidu.com
    * HMACCOUNT
* yiibai.com
    * Hm_lpvt_424e222704e2274e37a8169110e6e00a
    * Hm_lvt_424e222704e2274e37a8169110e6e00a
    * UM_distinctid
* www.yiibai.com
    * CNZZDATA4255568
    * PHPSESSID
    * _cnzz_CV

### 5.2从加载顺序来看:
1. 通过请求`http://www.yiibai.com/`的Response中Set-Cookie创建
```
Set-Cookie:PHPSESSID=f3b6rccd299lkek5o4lk55lek4; path=/
```

2. 通过请求`https://hm.baidu.com/hm.js?424e222704e2274e37a8169110e6e00a`的Response中Set-Cookie项创建
```
Set-Cookie:HMACCOUNT=4EECAAF636090065; Path=/; Domain=hm.baidu.com; Expires=Sun, 18 Jan 2038 00:00:00 GMT
```

3. 通过上一步请求的hm.js创建
```
Hm_lpvt_424e222704e2274e37a8169110e6e00a
Hm_lvt_424e222704e2274e37a8169110e6e00a
```

```js
/*
  hm.baidu.com/hm.js中的简略代码
*/

// cookie的Name部分
c = {
    id: "424e222704e2274e37a8169110e6e00a",
    age: 31536000000,   //cookie的Expires部分, 一年
}
b.p = this.getData("Hm_lpvt_" + c.id)

// cookie的Content部分
h.w = {
    k: Math.round( + new Date / 1E3) // UNIX timestamp
}
b = h.w
e = b.k

// cookie载入的function
mt = {}
mt.cookie = {};
mt.cookie.set = function(a, d, g) {
    var e;
    g.J && (e = new Date, e.setTime(e.getTime() + g.J));
    document.cookie = a + "=" + d + (g.domain ? "; domain=" + g.domain: "") + (g.path ? "; path=" + g.path: "") + (e ? "; expires=" + e.toGMTString() : "") + (g.cb ? "; secure": "")
};

// cookie载入function的包装
K: function() {
    for (var a = document.location.hostname,
    b = 0,
    d = c.dm.length; b < d; b++) if (this.M(a, c.dm[b])) return c.dm[b].replace(/(:\d+)?[\/\?#].*/, "");
    return a
},

U: function() {
    for (var a = 0,
    b = c.dm.length; a < b; a++) {
        var d = c.dm[a];
        if ( - 1 < d.indexOf("/") && this.Z(document.location.href, d)) return d.replace(/^[^\/]+(\/.*)/, "$1") + "/"
    }
    return "/"
},

l = mt.cookie
setData: function(a, b, d) {
    try {
        l.set(a, b, {
            domain: this.K(),
            path: this.U(),
            J: d
        }),
        d ? p.set(a, b, d) : f.set(a, b)
    } catch(e) {}
},

// 运行setData
this.setData("Hm_lvt_" + c.id, e, c.age); // expires为一年
this.setData("Hm_lpvt_" + c.id, b.k); // 未设置expires, 默认生存周期为整个会话
```
4. 通过请求`http://s23.cnzz.com/stat.php?id=4255568`的Response中js创建CNZZDATA4255568, _cnzz_CV和UM_distinctid
```js
/*
  c.cnzz.com/core.php中的简略代码
*/

// Cookie的Name部分
function k() {
    this.c = "4255568";
    this.ca = "z";
    this.Z = "";
    this.W = "";
    this.Y = "";
    this.C = "1494887098";
    this.aa = "hzs23.cnzz.com";
    this.X = "";
    this.G = "CNZZDATA" + this.c;
    this.F = "_CNZZDbridge_" + this.c;
    this.P = "_cnzz_CV" + this.c;
    this.R = "CZ_UUID" + this.c;
    this.L = "UM_distinctid";
    this.H = "0";
    this.K = {};
    this.a = {};
    this.Aa()
}

// cookie载入的function
var h = document,
ba: function(a, b, c, d, e, g) {
    a = f(a) + "=" + f(b);
    c instanceof Date && (a += "; expires=" + c.toGMTString());
    d && (a += "; path=" + d);
    e && (a += "; domain=" + e);
    g && (a += "; secure");
    h.cookie = a
},

// CNZZDATA4255568的载入function
$: function() {
    try {
        var a = this.G + "=",
        b = [],
        c = new Date;
        c.setTime(c.getTime() + 157248E5);
        if (1E8 < this.c) {
            if ("none" !== this.a.l) 
                b.push(f(this.a.l));
            else {
                var d = Math.floor(2147483648 * Math.random()) + "-" + this.C + "-" + this.N(this.o());
                b.push(f(d))
            }
            b.push(this.C);
            0 < b.length ? (a += f(b.join("|")), a += "; expires=" + c.toUTCString(), a += "; path=/") : a += "; expires=" + (new Date(0)).toUTCString()
        } 
        else 
            "none" !== this.a.l ? b.push("cnzz_eid=" + f(this.a.l)) : (d = Math.floor(2147483648 * Math.random()) + "-" + this.C + "-" + this.N(this.o()), b.push("cnzz_eid=" + f(d))),
        b.push("ntime=" + this.C),
        0 < b.length ? (a += f(b.join("&")), a += "; expires=" + c.toUTCString(), a += "; path=/") : a += "; expires=" + (new Date(0)).toUTCString();
        h.cookie = a
    } catch(l) {
        g(l, "sS failed")
    }
},

// _cnzz_CV的载入function
I: function() {
    try {
        var a = [],
        b,
        c,
        d;
        for (d in this.a.b) {
            var l = [];
            l.push(d);
            l.push(this.a.b[d].da);
            l.push(this.a.b[d].h);
            b = l.join("|");
            a.push(b)
        }
        if (!a.length) return ! 0;
        var e = new Date;
        e.setTime(e.getTime() + 157248E5);
        c = this.P + "=";
        this.b = f(a.join("&"));
        c += this.b;
        c += "; expires=" + e.toUTCString();
        h.cookie = c + "; path=/"
    } catch(t) {
        g(t, "sCV failed")
    }
},

// UM_distinctid的载入function
za: function() {
    try {
        var a = this.a,
        b;
        if (! (b = this.m(this.L))) {
            var c = this.fa(),
            d = new Date;
            d.setTime(d.getTime() + 157248E5);
            var e = document.location.hostname.match(/[a-z0-9][a-z0-9\-]+\.[a-z\.]{2,6}$/i);
            this.ba(this.L, c, d, "/", e ? e[0] : "");
            b = c
        }
        a.S = b;
        return this.a.S
    } catch(n) {
        g(n, "gC failed")
    }
},
```



## 6. Chrome的Cookie存储
Chrome将Cookie信息存储到SQLite format 3的Database File Format, database的schema如下:
```sql
CREATE TABLE cookies (
    creation_utc INTEGER NOT NULL UNIQUE PRIMARY KEY,
    host_key TEXT NOT NULL,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    path TEXT NOT NULL,
    expires_utc INTEGER NOT NULL,
    secure INTEGER NOT NULL,
    httponly INTEGER NOT NULL,
    last_access_utc INTEGER NOT NULL, 
    has_expires INTEGER NOT NULL DEFAULT 1, 
    persistent INTEGER NOT NULL DEFAULT 1,
    priority INTEGER NOT NULL DEFAULT 1,
    encrypted_value BLOB DEFAULT '',
    firstpartyonly INTEGER NOT NULL DEFAULT 0
);
```
以下是浏览页面产生的Cookie内容
```sql
sqlite> select * from cookies where host_key=".yiibai.com";
13139364398577396|.yiibai.com|UM_distinctid||/|13155089198000000|0|0|13139367892467768|1|1|1| |0
13139364398726940|.yiibai.com|Hm_lvt_424e222704e2274e37a8169110e6e00a||/|13170900398000000|0|0|13139367892467768|1|1|1| |0
13139364398727344|.yiibai.com|Hm_lpvt_424e222704e2274e37a8169110e6e00a||/|0|0|0|13139367892467768|0|0|1| |0

sqlite> select * from cookies where host_key="www.yiibai.com";
13139364397109878|www.yiibai.com|PHPSESSID||/|0|0|0|13139367892467768|0|0|1| |0
13139364398579199|www.yiibai.com|CNZZDATA4255568||/|13155089198000000|0|0|13139367892467768|1|1|1| |0

sqlite> select * from cookies where host_key=".hm.baidu.com";
13139365567933820|.hm.baidu.com|HMACCOUNT||/|13791859272933820|0|0|13139379872902982|1|1|1| |0
```
