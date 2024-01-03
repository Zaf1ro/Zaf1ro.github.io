---
title: String的基础操作
category:
  - Algorithm
  - String
tag:
  - Algorithm
abbrlink: dd7cced5
date: 2018-01-05 10:38:02
---

## 1. String, char[]和ArrayList的转换
* String和char[]之间的转换
```java
String s1 = "abcdef";
char[] arr = s1.toCharArray();  /* Convert String to Char Array */
String s2 = new String(arr);  /* Convert Char Array to String */
```
* String和ArrayList的转换
```java
/* Convert String to List */
String s1 = "abcdef";
List<Character> arr = new ArrayList<>();
for(char c: s1.toCharArray()){ arr.add(c); }

/* Convert List to String */
StringBuilder sb = new StringBuilder();
for (Character c: arr) sb.append(c);
String s2 = sb.toString();
```
* char[]和ArrayList的转换
```java
/* Convert Char Array to List */
char[] arr1 = {'a', 'b', 'c', 'd', 'e', 'f'};
List<Character> list = new ArrayList<>();
for (char c: arr1) list.add(c);

/* Convert List to Char Array */
char[] arr2 = new char[list.size()];
for (int i = 0; i < list.size(); i++) arr2[i]=list.get(i);
```



## 2. String内部排序
1. 考虑大小写按字母顺序排序
```java
String s1 = "AbCdaBcD";
char[] arr = s1.toCharArray();
Arrays.sort(arr);
String s2 = new String(arr);  /* s2="ABCDabcd" */
```
2. 不考虑大小写按字母排序
```java
String s1 = "AbCdaBcD";
Character[] arr = new Character[s1.length()];
int i = 0;
for (char c: s1.toCharArray()) arr[i++]=c;

Arrays.sort(arr, new Comparator<Character>() {
  @Override
  public int compare(Character c1, Character c2) {
    return Character.compare(
        Character.toLowerCase(c1), Character.toLowerCase(c2)
    );
  }
});

StringBuilder sb = new StringBuilder();
for(Character c: arr) sb.append(c);
String s2 = sb.toString();  /* s2="AabBCcdD" */
```



## 3. StringBuffer和StringBuilder
1. Synchronized
StringBuffer是Synchronized(线性安全的). StringBuilder是non-synchronized(非线性安全的).
2. Efficient
StringBuffer运行速度较慢, StringBuilder运行速度更快
3. Version
StringBuffer可兼容Java 1.5以下, StringBuilder只在Java 1.5及其以上版本支持



## 4. 字符串切割
1. split() - 操作简单, 但运行效率较低
```java
String s = "a,b,c,d"
String[] r1 = s.split(",");
```
2. StringTokenizer - 功能强大, 运行效率高
```java
String s = "a,b,c,d"
StringTokenizer token = new StringTokenizer(s, ",");
int count = token.countTokens();  // 分隔符拆分后的字符串个数

String[] r2 = new String[count];
int i = 0;
while (token.hasMoreTokens())
  r2[i++]=token.nextToken();
```



## 5. 字符串拼接
1. String相加 - 效率低
```java
public String StringConcat(String[] arr) {
  String result = "";
  for (String str: arr) result += str;
  return result;
}
```
2. concat() - 效率较高
```java
public void StringConcat(String[] arr) {
  String result = "";
  for (String str: arr) result = result.concat(str);
  return result;
}
```
3. StringBuilder
```java
public void StringConcat(String[] arr) {
  StringBuilder sb = new StringBuilder();
  for (String str: arr) sb.append(str);
  return sb.toString();
}
```
