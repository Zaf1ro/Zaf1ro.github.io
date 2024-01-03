---
title: Reverse String
category:
  - Algorithm
  - String
tag:
  - Algorithm
abbrlink: aa022a1e
date: 2018-01-04 10:20:38
---

## 1. Reverse String
### 1.1 使用String的reverse()函数
注意点:
1. String为不可变, 没有reverse()函数
2. StringBuilder需调用toString()转为String

```java
class Solution {
  public String reverse(String s) {
    if (s == null) return null;
    StringBuilder sb = new StringBuilder(s);
    sb.reverse();
    return sb.toString();
  }
}
```

### 1.2 将String转换为char[]
注意点:
1. String调用toCharArray()转换为char[]
2. 调用String初始化函数将char[]转换为String

```java
class Solution {
  public String reverse(String s){
    if (s == null) return null;
    char[] arr = s.toCharArray();
    for (int i = 0, j = arr.length-1; i < j; i++, j--) {
      char tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
    }
    return new String(arr);
  }
}
```

### 1.3 将String转换为List
注意点:
1. 通过将String转换为char[]转换为List<Character>
2. List转换为String有两种方法:
  1. 先将List转换为StringBuilder, 再转换为String
  2. 使用Stream() API和map()将List转换为String

```java
class Solution {
  public String reverse(String s){
    if (s == null) return null;
    List<Character> arr = new ArrayList<>();
    for (char c: s.toCharArray()) arr.add(c);
    for (int i = 0, j = arr.size()-1; i < j; i++, j--) {
      Character c = arr.get(i);
      arr.set(i, arr.get(j));
      arr.set(j, c);
    }

    /* Java 7 or below */
    StringBuilder sb = new StringBuilder();
    for(Character c: arr){ sb.append(c); }
    return sb.toString();

    /* Java 8 */
    // return arr.stream().map(String::valueOf).collect(Collectors.joining());
  }
}
```



## 2. 反转句子中的每个单词
例如: 将"Let's play a game"反转为"s'teL yalp a game"
注意点:
1. 每次遇到空格反转之前的字符串[i, j-1]
2. 反完单个单词后更新i
3. 循环最后反转最后一个字符串

```java
class Solution {
  public void reverse(char[] arr, int i, int j) {
    while (i < j) {
      char tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
      i++;
      j--;
    }
  }

  public String reverseWords(String s) {
    char[] arr = s.toCharArray();
    int i = 0;
    for (int j = 0; j < arr.length; j++) {
      if(arr[j] == ' ') {
        reverse(arr, i, j - 1);
        i = j + 1;
      }
    }
    return new String(arr);
  }
}
```



## 3. 反转2k个字符中的前k个字符
例如: s="abcdefg", k=2, 输出"bacdfeg"
注意点:
1. 比较i+k-1和len-1的大小, 防止j超出边界
2. i每次跳过2k

```java
class Solution {
  public void reverse(char[] arr, int i, int j) {
    while (i < j) {
      char tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
      i++;
      j--;
    }
  }

  public String reverseStr(String s, int k) {
    char[] arr = s.toCharArray();
    int i = 0;
    int len = s.length();
    while (i < len) {
      int j = Math.min(i + k - 1, len - 1);
      reverse(arr, i, j);
      i += 2 * k;
    }
    return new String(arr);
  }
}
```



## 4. 反转字符串中的元音字母
例如: s="leetcode", 返回"leotcede"
注意点: 
1. 从左和右找到要交换的元音字母
2. 找元音字母时需要判断left和right的大小关系
3. String.contains()的参数为String

```java
class Solution {
  public static void swap(char[] arr, int i, int j) {
    char tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
  }

  public static String reverseVowels(String s) {
    if (s == null || s.length() == 0) return s;
    char[] arr = s.toCharArray();
    String vowels = "AEIOUaeiou";
    int left = 0, right = s.length()-1;
    while (left < right) {
      while (left < right && !vowels.contains(arr[left] + ""))
        left++;
      while(left < right && !vowels.contains(arr[right] + ""))
        right--;
      swap(arr, left, right);
      left++;
      right--;
    }
    return new String(arr);
  }
}
```
