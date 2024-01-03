---
title: word_break
category:
  - Algorithm
  - Dynamic Programming
tag:
  - Algorithm
abbrlink: 3536804636
date: 2018-01-28 14:46:42
---

#### 1. 问题1
##### 1.1 问题描述
Given a non-empty string s and a dictionary wordDict containing a list of non-empty words, determine if s can be segmented into a space-separated sequence of one or more dictionary words. You may assume the dictionary does not contain duplicate words.

For example, given
s = "leetcode",
dict = ["leet", "code"].

Return `true` because "leetcode" can be segmented as "leet code".

##### 1.2 Dynamic Programming
```java
class Solution {
    public boolean wordBreak(String s, List<String> wordDict) {
        boolean[] result = new boolean[s.length() + 1];
        result[0] = true;
        for(int i = 1; i <= s.length(); i++){
            for(int j = 0; j < i; j++){
                if(result[j] && wordDict.contains(s.substring(j, i))){
                    result[i] = true;
                    break;
                }
            }
        }
        return result[s.length()];
    }
}
```
