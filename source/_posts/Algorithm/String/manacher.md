---
title: Longest Palindromic Substring
category:
  - Algorithm
  - String
tag:
  - Algorithm
abbrlink: 3b44
date: 2023-05-18 15:14:50
keywords:
description:
---

## 1. Introduction
**Longest palindromic substring**(最长回文子串)问题可描述为: 如何在给定字符串中寻找最大长度的连续回文子串. 假设回文子串的正序为$s_1$, 倒序为$s_2$, 则$s_1 = s_2$. 例如, `bananas`的最长回文子串为`anana`, `apple`的最长回文子串为`pp`.


## 2. Brute Force
最简单的实现方式是遍历所有字符, 将每个字符视为一个回文子串的中心, 然后以该中心点向外拓展, 直到不满足回文条件. 需要注意的是, 由于回文子串的长度可为偶数, 意味着中心点并不一定是单个字符, 因此需修改原字符串, 假设原字符串为`book`, 长度为4, 修改后为`#b#o#o#k#`, 长度为9; 假设原字符串长度为`N`, 则修改后长度为`2N+1`, 从而保证字符串的长度永远为奇数.
```java
char[] preprocess(String s) {
    char[] arr = new char[2 * s.length() + 1];
    arr[0] = '#';
    for (int i = 0; i < s.length(); i++) {
        arr[2 * i + 1] = s.charAt(i);
        arr[2 * i + 2] = '#';
    }
    return arr;
}

int longestPalSubstring(String s) {
    char[] arr = preprocess(s);
    int res = 0;
    for (int i = 0; i < arr.length; i++) {
        int l = i - 1, r = i + 1;
        while (l > -1 && r < arr.length && arr[l] == arr[r]) {
            l--;
            r++;
        }
        res = Math.max(res, (r - l - 1) / 2);
    }
    return res;
}
```
该算法的时间复杂度为$O(N^2)$(原字符串的长度为$N$).


## 3. Manacher's Algorithm
Brute force的问题在于, 从左向右遍历字符时, 当前字符没有利用之前找到的回文子串信息. 假设原字符串为`s`, 预处理后的字符串为`S`, 若当前字符($S[i]$)位于之前某个字符($S[j]$, $j < i$)为中心点的回文子串范围内, 则可找到以$S[j]$为中心, $S[i]$的镜像字符$S[i']$.
$$ 
\overbrace{S[l] \ldots S_{i'} \ldots S_{j} \ldots S_i \ldots S[r]}^{\text{palindrome}}
$$

介绍Manacher算法前, 需引入三个变量:
* 最右边界`r`: 已遍历的字符中, 其回文子串所能抵达的最大边界
* 中心点`c`: 最右边界`r`所在的回文子串的中心点位置
* 数组`p`, 其包含每个字符向外拓展所得的回文子串的半径: 该数组长度为$|S|$, 每处理一个字符, 将其回文子串的半径放入`p`中

以字符串`book`为例, 预处理后`S`为`$#b#o#o#k#@`, `S`的首字符为`$`, 尾字符为`@`, 这两个字符使得中心点向外拓展时无需检查边界. 数组`p`与`S`中每个字符的对应如下:

| index | character in S | radius of palindromic substring |
|:---:|:---:|:---:|
| 0 | $ | 0 |
| 1 | # | 0 |
| 2 | b | 1 |
| 3 | # | 0 |
| 4 | o | 1 |
| 5 | # | 2 |
| 6 | o | 1 |
| 7 | # | 0 |
| 8 | k | 1 |
| 9 | # | 0 |
| 10 | @ | 0 |

Manacher算法遍历字符时, 不处理`$`和`@`, 因此遍历范围为$[1,|S|-1]$. 假设当前遍历到坐标`i`, 可能遇到以下情况:

### 3.1 $i > r$
若$i > r$, 则中心点$c$与$S[i]$的位置关系如下:
$$
\overbrace{S[l] \ldots S_{c} \ldots S[r]}^{\text{palindrome}} \ldots S[i]
$$
$S[l]$表示中心点$c$所在回文子串的左边界. 由于$S[i]$没有位于任何先前遍历字符所在回文子串内, 因此无法使用回文字符串的对称性推断$S[i]$的情况, 只能采用brute force方式向左右拓展, 直到字符不匹配, 并更新最右边界$r$和中心点$c$.


### 3.2 $i \le r$
若$i \le r$, 则$S[i]$以$c$为轴, 可以找到镜像坐标`$i'$`($i - c = c - i'$):
$$
\overbrace{S[l] \ldots S[i'] \ldots S_{c} \ldots S[i] \ldots S[r]}^{\text{palindrome}}
$$
假设$S[i']$的半径为`k`, 存在以下几种情况:
1. `$i'-k > l$`: $S[i']$所在回文子串的左边界未超出$c$所在回文子串的左边界, 字符串如下:
    $$
    \overbrace{S[l] \ldots \underbrace{S[i'-k] \ldots S[i'] \ldots S[i'+k]}\_{\text{palindrome}} \ldots S_{c} \ldots S[i] \ldots S[r]}^{\text{palindrome}}
    $$

    上图可得出以下结论:
    * 由于$S[l:r]$为回文字符串, 且$S[i'-k:i'+k]$为回文字符串, 因此$S[i-k:i+k]$为回文字符串
    * 由于$S[i']$所在的回文子串的半径为`k`, 因此$S[i'-k-1] \ne S[i'+k+1] = S[i-k-1]$
    * 由于$S[l:r]$为回文字符串, 且$i'-k > l$, 因此$S[i'-k-1] = S[i+k+1]$

    综上所述, $S[i+k+1] = S[i'-k-1] \ne S[i'+k+1] = S[i-k-1]$, 因此$S[i]$所在回文子串的半径为`k`.

2. `$i'-k = l$`: $S[i']$所在回文子串的左边界等同`c`所在回文子串的左边界, 字符串如下:
    $$
    S[l-1] \quad \overbrace{\underbrace{S[l] (S[i'-k]) \ldots S[i'] \ldots S[i'+k]}\_{\text{palindrome}} \ldots S_{c} \ldots S[i] \ldots S[r] (S[i+k])}^{\text{palindrome}} \quad S[r+1]
    $$

    上图可得出以下结论:
    * 由于$S[l:r]$为回文字符串, 且$S[i'-k:i'+k]$为回文字符串, 因此$S[i-k:i+k]$为回文字符串
    * 由于$S[i']$所在回文子串的半径为`k`, 因此$S[i'-k-1] \ne S[i'+k+1] = S[i-k-1]$
    * 由于$l = i'-k-1$, 因此$S[i'-k-1]$与$S[i+k+1]$的关系不确定

    因此$S[i-k-1]$与$S[i+k+1]$的关系无法确定, 但$S[i]$所在回文子串的长度至少为`k`.
3. `$i-k < l$`: $S[i']$所在回文子串的左边界超出`c`所在回文子串的左边界, 字符串如下:
    $$
    \rlap{\underbrace{\phantom{S[i'-k] \ldots S[l] \ldots S[i'] \ldots S[i'+k]}}\_{\text{palindrome}}}
    S[i'-k] \ldots \overbrace{S[l] \ldots S[i'] \ldots S[i'+k] \ldots S_{c} \ldots S[i] \ldots S[r]}^{\text{palindrome}}
    $$
    
    该情况与第二种情况相同: $S[i]$所在回文子串的半径至少为`k`.


## 4. Implementation of Manacher
```java
char[] preprocess(String s) {
    char[] t = new char[s.length()*2 + 3];
    t[0] = '$';
    t[s.length()*2 + 2] = '@';
    for (int i = 0; i < s.length(); i++) {
        t[2*i + 1] = '#';
        t[2*i + 2] = s.charAt(i);
    }
    t[s.length()*2 + 1] = '#';
    return t;
}
    
int[] Manacher(String s) {
    char[] t = preprocess(s);
    int[] p = new int[t.length];
    int center = 0, right = 0;
    for (int i = 1; i < t.length-1; i++) {
        int mirror = 2*center - i;
        if (right > i) {
            p[i] = Math.min(right - i, p[mirror]);
        }
        while (t[i + (1 + p[i])] == t[i - (1 + p[i])]) {
            p[i]++;
        }
        if (i + p[i] > right) {
            center = i;
            right = i + p[i];
        }
    }
    return p;
}
```
上述代码中, `Manacher()`返回数组`p`, 若需要最长回文子串的长度, 可遍历`p`并找到最大值; 若需要最长回文子串, 可调用以下函数:
```java
String longestPalindromicSubstring(String s, int[] p) {
    int len = 0, c = 0;
    for (int i = 1; i < p.length-1; i++) {
        if (p[i] > len) {
            len = p[i];
            c = i;
        }
    }
    return s.substring((c - 1 - len) / 2, (c - 1 + len) / 2);
}
```
