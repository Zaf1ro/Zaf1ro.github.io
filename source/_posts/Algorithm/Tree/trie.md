---
title: Trie
abbrlink: '9055'
date: 2023-08-02 13:03:18
tags:
  - Algorithm
category:
  - Algorithm
  - Tree
keywords:
description:
---

## 1. Introduction
Trie tree(字典树)也称为prefix tree或digital tree, 作为一种k元搜索树, 用于在集合中搜索特定键的树型结构. 使用trie时, 搜索的键通常为字符串, 但trie中节点内存储的并不是整个字符串, 而是单个字符, 因此访问键时需深度优先遍历多个节点. 与binary search tree(BST, 二叉搜索树)最大的区别就是节点内存储的数据:
* BST会将完整的单个键放入一个节点中
* Trie值会将每个键的值分布到整个数据结构中

Trie中所有子节点都与其父节点相关联, 且键不一定为字符串, 也可以是二进制或十进制数字. Trie的查找复杂度与键大小成正比, 以下是时间复杂度:
* Search: $O(n)$
* Insert: $O(n)$
* Delete: $O(n)$


## 440. K-th Smallest in Lexicographical Order
Given two integers `n` and `k`, return the `$k^{th}$` lexicographically smallest integer in the range `[1, n]`.

Example 1:
```
Input: n = 13, k = 2
Output: 10
Explanation: The lexicographical order is [1, 10, 11, 12, 13, 2, 3, 4, 5, 6, 7, 8, 9], so the second smallest number is 10.
```

### Trie
题目要求找到字典序第k小的数字, 因此可将所有数字转换为字符串, 并排序找到第k小的数字即可, 但这么做时间复杂度和空间复杂度都不符合要求, 因此可利用trie的特性对所有数字重建, 例如: 1的子节点代表`[10, 19]`中的所有数字, 而10的子节点代表`[100, 109]`中的所有数字. 可以发现, 字典序第k个数字即为trie中前序遍历的第k个节点. 假设第k小的节点及其子节点共有`$\text{step}_i$`个节点, 此时存在两种可能:
* $\text{step}_i \le k - i$: 第k小的节点一定不存在于第i小的节点及其子树
* $\text{step}_i \gt k - i$: 第k小的节点一定在第i小的节点及其子树中

```java
class Solution {
    public int findKthNumber(int n, int k) {
        --k;
        int num = 1;
        while (k > 0) {
            int step = helper(num, n);
            if (step <= k) {
                ++num;
                k -= step;
            } else {
                num *= 10;
                --k;
            }
        }
        return num;
    }

    private int helper(int num, int n) {
        long first = num, last = first, step = 0;
        while (first <= n) {
            step += Math.min(n, last) - first + 1;
            first *= 10;
            last = last * 10 + 9;
        }
        return (int)step;
    }
}
```


## 2227. Encrypt and Decrypt Strings
You are given a character array `keys` containing **unique** characters and a string array values containing strings of length 2. You are also given another string array `dictionary` that contains all permitted original strings after decryption. You should implement a data structure that can encrypt or decrypt a **0-indexed** string.

A string is encrypted with the following process:
1. For each character `c` in the string, we find the index `i` satisfying `keys[i] == c` in `keys`
2. Replace `c` with `values[i]` in the string

Note that in case a character of the string is **not present** in `keys`, the encryption process cannot be carried out, and an empty string `""` is returned.

A string is **decrypted** with the following process:
1. For each substring `s` of length 2 occurring at an even index in the string, we find an `i` such that `values[i] == s`. If there are multiple valid `i`, we choose **any** one of them. This means a string could have multiple possible strings it can decrypt to.
2. Replace s with `keys[i]` in the string.

Implement the `Encrypter` class:
* `Encrypter(char[] keys, String[] values, String[] dictionary)` Initializes the `Encrypter` class with `keys`, `values`, and `dictionary`.
* `String encrypt(String word1)` Encrypts `word1` with the encryption process described above and returns the encrypted string.
* `int decrypt(String word2)` Returns the number of possible strings `word2` could decrypt to that also appear in `dictionary`.

Example 1:
```
Input:
["Encrypter", "encrypt", "decrypt"]
[
    [['a', 'b', 'c', 'd'], ["ei", "zf", "ei", "am"], ["abcd", "acbd", "adbc", "badc", "dacb", "cadb", "cbda", "abad"]],
    ["abcd"],
    ["eizfeiam"]
]

Output:
[null, "eizfeiam", 2]

Explanation:
/** 
 * return "eizfeiam". 
 * 'a' maps to "ei", 'b' maps to "zf", 'c' maps to "ei", and 'd' maps to "am"
 */ 
encrypter.encrypt("abcd");
/** 
 * return 2. 
 * "ei" can map to 'a' or 'c', "zf" maps to 'b', and "am" maps to 'd'. 
 * Thus, the possible strings after decryption are "abad", "cbad", "abcd", and "cbcd". 
 * 2 of those strings, "abad" and "abcd", appear in dictionary, so the answer is 2.
 * /
encrypter.decrypt("eizfeiam");
```

### Trie
```java
class Encrypter {
    class Node {
        public Node[] next;
        public int count;
        private Node() {
            this.next = new Node[26];
        }
    }

    private Map<Character, String> map = new HashMap<>();
    private Node root;

    private void addString(String s) {
        if (s == null) return;
        Node t = root;
        for (char c: s.toCharArray()) {
            int m = c - 'a';
            if (t.next[m] == null) {
                t.next[m] = new Node();
            }
            t = t.next[m];
        }
        ++t.count;
    }

    public Encrypter(char[] keys, String[] values, String[] dictionary) {
        this.root = new Node();
        for (int i = 0; i < keys.length; i++) {
            map.put(keys[i], values[i]);
        }
        for (String s: dictionary) {
            addString(encrypt(s));
        }
    }
    
    public String encrypt(String word1) {
        StringBuilder sb = new StringBuilder();
        for (char c: word1.toCharArray()) {
            if (!map.containsKey(c)) return null;
            sb.append(map.get(c));
        }
        return sb.toString();
    }
    
    public int decrypt(String word2) {
        Node t = this.root;
        for (char c: word2.toCharArray()) {
            t = t.next[c - 'a'];
            if (t == null) return 0;
        }
        return t.count;
    }
}
```


## 1032. Stream of Characters
Design an algorithm that accepts a stream of characters and checks if a suffix of these characters is a string of a given array of strings `words`.
For example, if `words = ["abc", "xyz"]` and the stream added the four characters (one by one) `'a'`, `'x'`, `'y'`, and `'z'`, your algorithm should detect that the suffix `"xyz"` of the characters `"axyz"` matches `"xyz"` from `words`.
Implement the `StreamChecker` class:
* `StreamChecker(String[] words)` Initializes the object with the strings array `words`.
* `boolean query(char letter)` Accepts a new character from the stream and returns `true` if any non-empty suffix from the stream forms a word that is in `words`.

Example 1:
```
Input:
["StreamChecker", "query", "query", "query", "query", "query", "query", "query", "query", "query", "query", "query", "query"]
[
    [["cd", "f", "kl"]],
    ["a"], ["b"], ["c"], ["d"], ["e"], ["f"],
    ["g"], ["h"], ["i"], ["j"], ["k"], ["l"]
]

Output:
[null, false, false, false, true, false, true, false, false, false, false, false, true]

Explanation:
StreamChecker streamChecker = new StreamChecker(["cd", "f", "kl"]);
streamChecker.query("a"); // return False
streamChecker.query("b"); // return False
streamChecker.query("c"); // return False
streamChecker.query("d"); // return True, because 'cd' is in the wordlist
streamChecker.query("e"); // return False
streamChecker.query("f"); // return True, because 'f' is in the wordlist
streamChecker.query("g"); // return False
streamChecker.query("h"); // return False
streamChecker.query("i"); // return False
streamChecker.query("j"); // return False
streamChecker.query("k"); // return False
streamChecker.query("l"); // return True, because 'kl' is in the wordlist
```

### Trie
```java
class StreamChecker {
    class Node {
        public Node[] next;
        public boolean isEnd = false;
        public Node() {
            this.next = new Node[26];
        }
    }
    
    private Node root;
    private StringBuilder sb = new StringBuilder();

    public StreamChecker(String[] words) {
        this.root = new Node();
        this.curr = this.root;
        for (String word: words) {
            Node t = this.root;
            for (int i = word.length() - 1; i >= 0; i--) {
                int m = word.charAt(i) - 'a';
                if (t.next[m] == null) {
                    t.next[m] = new Node();
                }
                t = t.next[m];
            }
            t.isEnd = true;
        }
    }
    
    public boolean query(char letter) {
        sb.append(letter);
        Node t = this.root;
        for (int i = sb.length() - 1; i >= 0; i--) {
            t = t.next[sb.charAt(i) - 'a'];
            if (t == null) return false;
            if (t.isEnd) return true;
        }
        return false;
    }
}
```


## 588. Design In-Memory File System
Design a data structure that simulates an in-memory file system.

Implement the FileSystem class:
* `FileSystem()` Initializes the object of the system.
* `List<String> ls(String path)` The answer should in lexicographic order.
    * If `path` is a file path, returns a list that only contains this file's name.
    * If `path` is a directory path, returns the list of file and directory names **in this directory**.
* `void mkdir(String path)` Makes a new directory according to the given `path`. The given directory path does not exist. If the middle directories in the path do not exist, you should create them as well.
* `void addContentToFile(String filePath, String content)`
    * If `filePath` does not exist, creates that file containing given `content`.
    * If `filePath` already exists, appends the given `content` to original content.
* `String readContentFromFile(String filePath)` Returns the content in the file at `filePath`.

Example 1:
```
Input:
["FileSystem", "ls", "mkdir", "addContentToFile", "ls", "readContentFromFile"]
[[], ["/"], ["/a/b/c"], ["/a/b/c/d", "hello"], ["/"], ["/a/b/c/d"]]

Output:
[null, [], null, null, ["a"], "hello"]

Explanation:
FileSystem fileSystem = new FileSystem();
fileSystem.ls("/");                               // return []
fileSystem.mkdir("/a/b/c");
fileSystem.addContentToFile("/a/b/c/d", "hello");
fileSystem.ls("/");                               // return ["a"]
fileSystem.readContentFromFile("/a/b/c/d");       // return "hello"
```

### Trie
```java
class FileSystem {
    class Node {
        public Map<String, Node> map;
        public StringBuilder content;
        public String filename;
        public Node() {
            this.map = new HashMap<>();
            this.content = new StringBuilder();
        }
    }

    private Node root;

    public FileSystem() {
        this.root = new Node();
    }
    
    public List<String> ls(String path) {
        Node t = this.root;
        String[] arr = path.split("/");
        for (String s: arr) {
            if (s.length() == 0) continue;
            Node next = t.map.get(s);
            if (next == null) return new ArrayList<>();
            t = next;
        }
        List<String> res = new ArrayList<>();
        if (t.filename != null) {
            res.add(t.filename);
            return res;
        }
        for (String name: t.map.keySet()) {
            res.add(name);
        }
        Collections.sort(res, (a,b)->a.compareTo(b));
        return res;
    }
    
    public void mkdir(String path) {
        Node t = this.root;
        String[] arr = path.split("/");
        for (String s: arr) {
            if (s.length() == 0) continue;
            t.map.putIfAbsent(s, new Node());
            t = t.map.get(s);
        }
    }
    
    public void addContentToFile(String filePath, String content) {
        Node t = this.root;
        String[] arr = filePath.split("/");
        for (String s: arr) {
            if (s.length() == 0) continue;
            t.map.putIfAbsent(s, new Node());
            t = t.map.get(s);
        }
        t.content.append(content);
        t.filename = arr[arr.length - 1];
    }
    
    public String readContentFromFile(String filePath) {
        Node t = this.root;
        String[] arr = filePath.split("/");
        for (String s: arr) {
            if (s.length() == 0) continue;
            t = t.map.get(s);
        }
        return t.content.toString();
    }
}
```


## 140. Word Break II
Given a string `s` and a dictionary of strings `wordDict`, add spaces in `s` to construct a sentence where each word is a valid dictionary word. Return all such possible sentences in **any order**.

**Note** that the same word in the dictionary may be reused multiple times in the segmentation.

Example 1:
```
Input: s = "catsanddog", wordDict = ["cat","cats","and","sand","dog"]
Output: ["cats and dog","cat sand dog"]
```

Example 2:
```
Input: s = "pineapplepenapple", wordDict = ["apple","pen","applepen","pine","pineapple"]
Output: ["pine apple pen apple","pineapple pen apple","pine applepen apple"]
Explanation: Note that you are allowed to reuse a dictionary word.
```

### Trie
```java
class Solution {
    class Node {
        public Node[] next;
        public boolean isEnd;
        public Node() {
            next = new Node[26];
        }
    }
    
    private Node root = new Node();
    private List<String> res = new ArrayList<>();

    public List<String> wordBreak(String s, List<String> wordDict) {
        for (String word: wordDict) {
            Node t = root;
            for (char c: word.toCharArray()) {
                int m = c - 'a';
                if (t.next[m] == null) {
                    t.next[m] = new Node();
                }
                t = t.next[m];
            }
            t.isEnd = true;
        }
        backtracking(s, 0, "");
        return res;
    }

    private void backtracking(String s, int start, String prev) {
        if (start == s.length()) {
            res.add(prev.substring(0, prev.length()-1));
            return;
        }
        Node t = this.root;
        for (int i = start; i < s.length() && t != null; i++) {
            t = t.next[s.charAt(i) - 'a'];
            if (t != null && t.isEnd) {
                backtracking(s, i+1, prev + s.substring(start, i+1) + " ");
            }
        }
    }
}
```

