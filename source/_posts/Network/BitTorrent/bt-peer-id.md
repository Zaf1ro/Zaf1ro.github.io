---
title: BitTorrent Peer ID Conventions
category:
  - Network
tag:
  - Network
abbrlink: ca71
date: 2016-03-01 18:00:28
---

## 1. 继续更新BitTorrent协议
tracker的request和peer握手中的20字节的Peer ID不仅用于标记每个peer, 还用来标记client的实现和版本. 
传统client会将peer id中的第一个字母设置为"m", 紧接着主版本号, 副版本号和阶段版本号, 使用"-"隔开, 例如"M4-3-6-"或"M4-20-8-", 对应着4.3.6和4.20.8版本号. Peer id中剩下的字节都是随机分配的. 
许多client使用两个字符作为开端, 这样可以识别client的实现, 后面的四个ascii数字用来表示版本号. 和传统的client一样, 其他字节随机分配. 例如:"-AZ2060-". 



## 2. 已知client格式
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



## 3. 未知的client
以下client还没被标记, 需要确认:
* 'BD' (例如: -BD0300-)
* 'NP' (例如: -NP0201-)
* 'wF' (例如: -wF2200-)



## 4. 其他
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
