---
title: BitTorrent Protocol Specification
category:
  - Network
tag:
  - Network
abbrlink: 7f56
date: 2016-01-28 20:00:42
---

## 1. Introduction
BT是一个分布式文件协议, 它通过URL来识别内容并通过web来无缝整合. 它的优势在于能通过单纯的HTTP来实现对同一文件的同时多个下载, 下载者再上传给其他人, 这使得能在适度增加负载的同时使得文件源能支持大量下载者. 


## 2. BitTorent文件的分布包括以下实体
* 普通的web server
* 静态的metainfo(元信息)文件
* BitTorrent Tracker
* 原始的下载者
* 终端用户浏览器
* 终端用户下载器

理论上对于单个文件来说有许多终端用户


## 3. Host需要做以下步骤才能开启服务
1. 开启一个tracker(大部分情况下已经有运行的了)
2. 开启一个普通的web server, 例如apache
3. 在web server上关联MIME类型为application/x-bittorrent的.torrent拓展
4. 使用一个被服务的完整文件和tracker的URL来生成一个metainfo(.torrent)文件
5. 将metainfo(.torrent)文件放在web server上
6. 在其他web页面上链接上该metainfo文件
7. 开启一个已经拥有完整文件的下载器


## 4. 用户需要做以下操作才能开启下载
1. 安装BitTorrent
2. 上网
3. 点击.torrent文件的链接
4. 选择文件的存放位置, 或重新开始一个局部下载
5. 等待下载完成
6. 退出下载器(退出后会保持上传)


## 5. Bencoding
* 字符串(String): 长度作为前缀, 基于十进制, 中间用":"将长度和字符串间隔开. 例如: `4:spam`表示`spam`.
* 整数(Integer): 以`i`开始, 以`e`作为结束字符, 中间为十进制的整数信息. 举个例子: `i3e`表示`3` , `i-3e`表示`-3`. 整数没有大小限制, 但`i-0e`是不合法的, 所有以`0`开始的编码都是不合法的, 例如`i03e`, 除了`i0e`, 因为它表示`0`. 
* 列表(List): 以`l`开始, 以`e`结束, 中间为**Bencoding编码**. 例如: `l4:spam4:eggse`表示`['spam', 'eggs']`.
* 字典(Dictionary): 以`d`开始, 以`e`结束, 中间为key和value. 例如: `d3:cow3:moo4:spam4:eggse`表示`{'cow': 'moo', 'spam': 'eggs'}`, `d4:spaml1:a1:bee`表示`{'spam': ['a', 'b']}`. key必须为字符串(String), 且必须采用原始字符串方式排序, 不是字母数字的排序方式.


## 6. metainfo文件(metainfo file)
元信息文件是以Bencoding编码的字典, 其中的字符串均为UTF-8编码, key有以下内容: 
* announce: tracker的URL
* info: 对应的值是一个torrent文件的字典, key在下面有描述.torrent文件中的所有字符串包含的文本内容都必须为UTF-8编码


### 7. info字典(info dictionary)
info字典的key都是UTF-8编码的字符串
* piece length: 文件分隔后每一片的字节数量. 为了传输文件, 文件会被分隔成固定的片, 除了最后一片可能被截断. 片长度会一直保持2的次方大小, 大多数情况下为$2^{18}$, 也就是256KB
* pieces: 20或20的倍数长度的字符串, 可以分割成一个个20字节的字符串, 每一个字符串都是SHA1散列值计算出来的. 
* key长度 / key文件: 两者必有其一, 但不能一起存在. 如果key length存在那么只用下载单个文件; 如果是key file, 那么就是一个目录结构, 包含一系列文件. 在单个文件中, length指的就是文件的字节数. 
* files: 多文件情况的都将多个文件按照顺序连接成一个文件, 显示在文件列表中. files对应的就是文件列表, 是一个包含多个字典的list, 字典中的key包含以下内容: 
  * length: 文件的长度, 字节个数
  * path: 对应子目录名的UTF-8编码字符串, 最后一个是真正的文件名
  * name: 对于单个文件, name就是文件名; 对于多文件的情况, name为文件夹的名字


### 8. trackers
tracker的GET请求有以下keys: 
* info_hash: metainfo文件中info键对应的值的20字节SHA1散列值, 将被移除
* peer_id: 20字节长度的字符串, 是用户下载器的唯一标识, 每一个下载器都会在开始一个新的下载开始时生成一个随机的id, 将被移除. 
* ip: 可选选项, 代表客户端主机的IP地址. 只有当请求中的IP地址不是客户端的IP地址时才会使用该参数, 比如客户端开启代理. 
* port: 客户端正在监听的端口号, 下载器一般使用6881-6880, 如果不是该范围, 则客户端可能拒绝连接. 
* uploaded: 上传的字节数, 十进制. 
* downloaded: 下载的字节数, 十进制. 
* left: 客户端还需要下载的字节数, 十进制. 注意, 该值不能通过file length减去downloaded来计算获得, 因为可能用户进行的是一次继续下载, 并且已下载的数据有可能缺失完整性检查, 所以还需要重新下载. 
* event: 可选选项. 对应着started, completed或stopped(empty代表不存在). 当一个下载刚开始时, announcement使用started; 当下载完成时, 发送completed; 当停止下载时, 发送stopped. Tracker的response是bencoded编码的字典. 如果tracker的response中包含failure reason的键, 那么对应的值表示一个可读的字符串, 这段字符串解释了为什么查询失败. 否则必须还有两个key: 
  * interval: 下载器在两次查询之间需要等待的时间
  * peers: 包含多个字典的列表, 每个字典包含peer id, ip, 和port, 这对应着客户端的自选ID, IP地址, DNS名称, 和端口号. 如果下载器有event发生或需要更多的客户端, 那么需要向tracker重新发起不定期请求


## 9. Peer协议(Peer protocol)
BitTorrent的peer协议通过TCP或uTP操作.
Peer连接是对称的. 双向传输的信息是相同的, 数据库可以走任意方向. 
Peer协议适用于metainfo文件描述的由索引连接的多片文件, 以0为开始. 当一个peer下载了一片, 并且进行了hash匹配, 那么就可以将该片分享给其他peer. 
连接以两个bit的状态码结束: 是否choke, 是否interested. Choking意味着只有切换为unchoked状态才能传输数据. Choking背后的推导和原理将会在后面提到. 
当一端为interested, 另一端为not choking时进行数据传输. 每当下载器不对peer进行请求下载时, Interested状态必须随时保持更新, 尽管peer可能对本端choked, 也必须传递not interested. 尽管使用起来很困难, 但这能使得下载器只是哪些peer将开始下载, 如果是peer对本端是unchoked. 
连接开始的初始状态为choke和not interested
数据传输时, 下载器应保持片查询, 并按队列进行查询, 这样可以提升TCP性能. 另一方面, 不能写入TCP缓存的请求将会在内存中排队等候, 而不是存储在应用层的网络缓存中, 这样当发生choke时可以全部抛弃. 
Peer wire协议会包含一次握手, 随后就是以长度为前缀的信息组成的流传输. 握手以字符串19开始, 后面跟着"BitTorrent protocol". 开始的字符串为长度前缀, 把这个字符串放这里是希望其他新的协议也这么做, 并且可以通过这个来区分协议. 
协议中的后续传输的整数都以大端字节4bytes编码
固定头部后紧跟着8个保留bytes, 现在是用零填充. 如果你想拓展协议可以使用这些bytes. 
紧接着下的20bytes是metainfo文件的info value的bencode编码的sha1散列值(与tracker的GET中的info_hash相同), 如果两端传输的该值不相同, 将断开连接. 以下是一个例外: 如果下载器想通过一个端口进行多个下载, 将会在即将到来的连接中接受下载的hash, 如果hash在列表中, 将回复相同的hash. 
下载hash后为20bytes的peer id, 如果接收端的peer id和开始端不匹配也会中断连接. 
以上就是握手, 接下来是交互的以长度为前缀的流和信息. 长度为0的信息为keepalives和ignored. keepalives每隔两分钟发一次, 但当期望数据时超市可能会更快的完成. 


## 10. BitTorrent tracker
tracker的request和peer握手中的20字节的Peer ID不仅用于标记每个peer, 还用来标记client的实现和版本. 
传统client会将peer id中的第一个字母设置为"m", 紧接着主版本号, 副版本号和阶段版本号, 使用"-"隔开, 例如"M4-3-6-"或"M4-20-8-", 对应着4.3.6和4.20.8版本号. Peer id中剩下的字节都是随机分配的. 
许多client使用两个字符作为开端, 这样可以识别client的实现, 后面的四个ascii数字用来表示版本号. 和传统的client一样, 其他字节随机分配. 例如:"-AZ2060-". 


## 11. 已知client格式
* 'AG': Ares
* 'A~': Ares
* 'AR': Arctic
* 'AV': Avicora
* 'AX': BitPump
* 'AZ': Azureus
* 'BB': BitBuddy
* 'BC': BitComet
* 'BF': Bitflu
* 'BG': BTG (uses Rasterbar libtorrent)
* 'BR': BitRocket
* 'BS': BTSlave
* 'BX': ~Bittorrent X
* 'CD': Enhanced CTorrent
* 'CT': CTorrent
* 'DE': DelugeTorrent
* 'DP': Propagate Data Client
* 'EB': EBit
* 'ES': electric sheep
* 'FT': FoxTorrent
* 'GS': GSTorrent
* 'HL': Halite
* 'HN': Hydranode
* 'KG': KGet
* 'KT': KTorrent
* 'LH': LH-ABC
* 'LP': Lphant
* 'LT': libtorrent
* 'lt': libTorrent
* 'LW': LimeWire
* 'MO': MonoTorrent
* 'MP': MooPolice
* 'MR': Miro
* 'MT': MoonlightTorrent
* 'NX': Net Transport
* 'PD': Pando
* 'qB': qBittorrent
* 'QD': QQDownload
* 'QT': Qt 4 Torrent example
* 'RT': Retriever
* 'S~': Shareaza alpha/beta
* 'SB': ~Swiftbit
* 'SS': SwarmScope
* 'ST': SymTorrent
* 'st': sharktorrent
* 'SZ': Shareaza
* 'TN': TorrentDotNET
* 'TR': Transmission
* 'TS': Torrentstorm
* 'TT': TuoTu
* 'UL': uLeecher!
* 'UT': µTorrent
* 'VG': Vagaa
* 'WT': BitLet
* 'WY': FireTorrent
* 'XL': Xunlei
* 'XT': XanTorrent
* 'XX': Xtorrent
* 'ZT': ZipTorrent


## 13. 未知的client
以下client还没被标记, 需要确认:
* 'BD' (例如: -BD0300-)
* 'NP' (例如: -NP0201-)
* 'wF' (例如: -wF2200-)


## 14. 其他
Shad0w的实验性BitTorrent实现和BitTornado都将peer id的开头设为"T", BitTornado会紧接着5个ascii字符的版本号, 如果没有5个字节长, 则用"-"填充. 表示版本号的ascii字符只能使用以下字符:
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.-
例如:"S58B-----"表示5.8.11版本. 和其他的peer id格式一样, 其他的字符都是随机分配. 

已知的client使用以下编码格式:
* 'A': ABC
* 'O': Osprey Permaseed
* 'Q': BTQueue
* 'R': Tribler
* 'S': Shadow's client
* 'T': BitTornado
* 'U': UPnP NAT Bit Torrent

1. BitComet的peer id包含四个ASCII字符"exbc", 后面跟着两个字节x和y, 最后跟着随机字符. x为十进制的小数点前版本号, y为十进制的小数点后版本号. BitLord使用相同的格式, 但会在版本号后面添加LORD. BitComet的一个非官方补丁将"exbc"替换为"FUTB". 自BitComet版本更新为0.59后, Peer IDs的编码更改为Azureus风格
2. XBT客户端有自己的格式. 它的peer id包含三个大写字符:XBT, 之后是三个ASCII整数来表示版本号. 如果客户端是debug build, 那么第七位为小写字符d, 否则为"-". 之后就是随机的整数, 大小写字符. 例如:XBT054d-, 这说明是debug build 0.5.4版本
3. Opera 8预览版和Opera9.x发行版都使用以下peer_id格式:前两个字节是"OP", 后面四个字节为版本号. 剩下的是随机小写十六进制数
4. MLdonkey使用以下peer_id格式:首字符为"-ML", 紧接带点版本号, 然后是"-", 最后为随机字符, 例如: -ML2.7.2-kgjjfkd
5. Bits on Wheels使用"-BOWxxx-yyyyyyyyyyyy", y为随机大小字符, x为版本号, 例如:1.0.6等价于A0C
6. Queen Bee使用Bram的新风格: Q1-0-0--或Q1-10-0-后跟着随机字节
7. BitTyrant是Azureus的分支, 1.1版本中使用AZ2500BT + 随机字节作为peer ID
8. TorrenTopia的1.90版本是3.4.6版本主线的分支, 其peer ID以346------开头
9. BitSpirit对于其peer ID有不同的格式. 它的ID使用"\\\\0\\\\'3BS"作为前四个字节, 表示3.x版本号, "\\0\\2BS"表示2.x版本. 所有格式都以"UDP0"作为结尾
10. Rufus使用2字节的十进制ASCII数值作为版本号, 第三四字节是"RS", 以后跟着用户的昵称和一些随机字节
11. G3 Torrent以"G3"开头, 紧跟着9个字符的用户昵称
12. FlashGet使用Azureus风格, 以"FG"开头, 没有"-", 版本1.82.1002仍然使用数字"0180"
13. AllPeers使用用户相关字符的sha1哈希值, 并用"AP + 版本号 + -"替代了前几个字节
