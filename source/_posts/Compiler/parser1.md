---
title: Parser (1)
abbrlink: 52ae
date: 2020-02-11 11:55:10
category:
- Compiler
tag:
- Compiler
keywords:
description:
---

## 1. Introduction
Parser作为front-end的第二部分, 负责判断输入的字符串是否为合法程序, 若不合法, 则向用户回报错误和诊断信息. 经过scanner的处理后, parser接收到的不光是一个个字符串, 还有每个字符串对应的词类. 为了分析任意语句是否符合有效, 需要一种形式化机制来做出明确判断, 这就需要将source language限制为context-free language(CFG, 上下文无关语言). 并存在两种解析CFG的算法: LL(1)和LR(1). 假设programming language定义的语法为**G**, 若某个字符串**s**属于**G**, 则说明可以用**G**推导出**s**. Parser的任务就是将**s**不断推导为**G**的合法语句.



## 2. Expressing Syntax
为检查语法, 需要一种符号表示法来描述描述语法. Scanner使用RE来表示来描述合法字符串, 但RE并不能用于描述语法.

### 2.1 Why Not Regulaer Expression?
假设现在需要识别由变量, $+, -, \times, /$组成的代数表达式, 可写作如下RE:
```code
$[a \cdots z]([a \cdots z]|[0 \cdots 9])^{*}((+|-|\times|\div)[a \cdots z]([a \cdots z]|[0 \cdots 9])^{*})^{*}$
```
该RE可以匹配$a + b \times c$和$fee \div fie \times \div$. 但RE没有注明操作符的优先级, 理论上$\times$和$\div$的优先级应比$+$和$-$优先级高. 并且, 该RE还未加入括号的显示, 这里使用$\underline{(}$和$\underline{)}$来表示括号符号. 加上括号后的RE如下:
```code
$(\underline{(}|\epsilon)[a \cdots z]([a \cdots z]|[0 \cdots 9])^{*}((+|-|\times|\div)[a \cdots z]([a \cdots z]|[0 \cdots 9])^{*})^{*}(\underline{)}|\epsilon)^{*}$
```
上述RE可以匹配任何正确的带括号的表达式, 例如: $(a + b) \times c$. 但它并不能匹配语法上不正确的表达式, 例如: $a + (b \times c$或$a + b) \times c$, 因为RE无法计数, 无法匹配成对结构的语法.

### 2.2 Context-Free Grammars
一般来说, parser使用CFG来表示语法. 假设一个CFG名为**G**作为一组语法规则, 描述语句是如何形成的. 从G导出的所有语句组成**G定义的语言**, 记作$L(G)$. 举个语法例子:
$$
\textit{SheepNoise} \rightarrow \text{baa} \ \textit{SheepNoise} \ | \ \text{baa}
$$

上述语法存在两条规则, 称为production(产生式):
1. $\textit{SheepNoise}$可推导出$\text{baa} \ \textit{SheepNoise}$
2. $\textit{SheepNoise}$可推导出$\text{baa}$

其中, $\textit{SheepNoise}$作为一个nonterminal symbol(非终止符), 因为该符号可推导出其他符号, 本文用$\textit{斜体}$样式表示. $\text{baa}$作为一个terminal symbol(终止符), 因为该符号无法推导出其他符号, 本文用$\text{正体}$样式表示. 当一个语句中全部都是terminal symbol时, 该语句即为$L(G)$中的合法语句. 在scanner的输出字符串中, 需要选择一个nonterminal symbol $\alpha$, 并选择一个语法规则$\alpha \rightarrow \beta$, 将字符串中的$\alpha$替换为$\beta$. 重复上述过程, 直到字符串中不包含nonterminal symbol为止. 重写后的字符串也就是$L(G)$中的一个语句. 
CFG在形式上是一个四元组$(T, NT, S, P)$, 各元素解释如下:
1. T: terminal symbol集合, 对应scanner返回的词类
2. NT: nonterminal symbol集合, 用于在表达式中提供抽象和结构
3. S: 一个特殊的nonterminal symbol, 称为start symbol或goal symbol, 用于表示进行推导的单词
4. P: G中所有规则的集合, 每个规则形如$NT \rightarrow (T \cup NT)^{+}$, 即每次推导都将一个nonterminal symbol替换为一个或多个语法符号构成的字符串

假设符号串为**SheepNoise**, 可用规则1或规则2重写SheepNoise:
1. 使用规则2重写SheepNoise后, 符号串替换为$\text{baa}$, 由于baa为terminal symbol, 因此没有再次重写的机会
2. 使用规则1重写SheepNoise后, 符号串替换为$\text{baa} \ \textit{SheepNoise}$, 这时符号串中仍有一个nonterminal symbol, 可再次用规则2替换, 得到$\text{baa baa}$

### 2.3 More Complex Examples
以括号表达式为例, 其语法规则如下:
```code
1 $\textit{Expr} \rightarrow \underline{(} \textit{Expr} \underline{)}$
2      $| \ \textit{Expr} \ \textit{Op} \ \text{name}$
3      $| \ \text{name}$
4 $\textit{Op} \rightarrow +$
5     $| \ -$
6     $| \ \times$
7     $| \ \div$
```
假设输入语句为$(a+b)\times c$, 可使用(2,6,1,2,4,3)的规则顺序来推导:

| Rule | Sentential Form |
|:----:|:----:|
|  | $\textit{Expr}$ |
| 2 | $\textit{Expr Op} \ \text{name}$ |
| 6 | $\textit{Expr} \times \text{name}$  |
| 1 | $\underline{(} \textit{Expr} \underline{)} \times \text{name}$|
| 2 | $\underline{(} \textit{Expr} + \text{name} \underline{)} \times \text{name}$|
| 4 | $\underline{(} \textit{Expr} + \text{name} \underline{)} \times \text{name}$ |
| 3 | $\underline{(} \text{name} + \text{name} \underline{)} \times \text{name}$ |

**name**并不是某个具体变量, 而表示一种词类, 可以表示a, b或c. 上述推导过程也可以表示为parse tree:
![Parse Tree for (a+b)×c](/images/Compiler/3-1.png)

这样生成的CFG语句不可能带有左右不平衡或嵌套关系错误的括号, 因为规则1会生成左右对称的括号. 在$(a+b)\times c$推导过程中, 每一次推导都根据最右端的nonterminal symbol, 称为rightmost derivation(最右推导); 也可以根据最左侧nonterminal symbol来推导, 称为leftmost derivation(最左推导):

| Rule | Sentential Form |
|:----:|:----:|
|  | $\textit{Expr}$ |
| 2 | $\textit{Expr Op} \ \text{name}$ |
| 1 | $\underline{(} \textit{Expr} \underline{)} \ \textit{Op} \ \text{name}$  |
| 2 | $\underline{(} \textit{Expr Op} \ \text{name} \underline{)} \ \textit{Op} \ \text{name}$ |
| 3 | $\underline{(} \text{name} \ \textit{Op} \ \text{name} \underline{)} \ \textit{Op} \ \text{name}$ |
| 4 | $\underline{(} \text{name} + \text{name} \underline{)} \ \textit{Op} \ \text{name}$ |
| 6 | $\underline{(} \text{name} + \text{name} \underline{)} \times \text{name}$ |

无论是最左还是最右, 都是使用同一组规则. 对最右端(或最左端)nonterminal symbol的推导存在多种重写结果时, 称为**ambiguous grammer**(二义性语法). 二义性语法会生成多个parse tree, 也就导致compiler无法肯定一个语句的语义, 也无法将其转换为一个确定的代码序列. 例如:
```code
1 $\textit{Statement} \rightarrow \text{if} \ \textit{Expr} \ \text{then} \ \textit{Statement} \ \text{else} \ \textit{Statement}$
2         $| \ \text{if} \ \textit{Expr} \ \text{then} \ \textit{Statement}$
3         $| \ \textit{Assignment}$
```
假设输入代码为$\text{if} \ \textit{Expr}_1 \ \text{then} \ \text{if} \ \textit{Expr}_2 \ \text{then} \ \textit{Assignment}_1 \ \text{else} \ \textit{Assignment}_2$, 最右推导有两种结果: 
1. 将$\textit{Assignment}_2$与内层的$\text{if}$配对, 当$\textit{Expr}_1$为true且$\textit{Expr}_2$为false时执行$\textit{Assignment}_2$
![rightmost derivation 1](/images/Compiler/3-2.png)

2. 将$\textit{Assignment}_2$与外层的$\text{if}$配对, 当$\textit{Expr}_1$为false时执行$\textit{Assignment}_2$
![rightmost derivation 2](/images/Compiler/3-3.png)

为消除这种二义性, 可引入一条新的规则来规定哪个if控制特定的else子句:
```code
1 $\textit{Statement} \rightarrow \text{if} \ \textit{Expr} \ \text{then} \ \textit{Statement}$
2         $| \ \text{if} \ \textit{Expr} \ \text{then} \ \textit{WithElse} \ \text{else} \ \textit{Statement}$
3         $| \ \textit{Assignment}$
4 $\textit{WithElse} \rightarrow \text{if} \ \textit{Expr} \ \text{then} \ \textit{WithElse} \ \text{else} \ \textit{WithElse}$
5         $| \ \textit{Assignment}$ 
```
上述语法限制了$\text{then}$后的语法结构, 确保每个$\text{else}$都匹配到唯一$\text{if}$. 也有一些语言重新设计了**if-then-else**结构, 引入**elseif**和**endif**.

### 2.4 Encode Meaning into Structure
Parser使用的语法结构与语言的语义有直接联系, 以$a + b \times c$为例, 其最右推导的parse tree为:
![parse tree of a+bxc](/images/Compiler/3-4.png)

表达式的求值可以看作是parse tree的后序遍历, 先计算$a+b$, 在将其结果乘以c. 为纠正运算优先级的问题, 可在语法中多添加几个层次, 优先处理$()$, 然后处理$\times \div$, 最后处理$+-$. 表达式语法如下:
```code
0 $\textit{Goal} \rightarrow \textit{Expr}$
1 $\textit{Expr} \rightarrow \textit{Expr} + \textit{Term}$
2      $| \ \textit{Expr} - \textit{Term}$
3      $| \ \textit{Term}$
4 $\textit{Term} \rightarrow \textit{Term} \times \textit{Factor}$
5      $| \ \textit{Term} \div \textit{Factor}$
6      $| \ \textit{Factor}$
7 $\textit{Factor} \rightarrow \underline{(} \textit{Expr} \underline{)}$
8      $| \ \text{num}$
9      $| \ \text{name}$
```

### 2.5 Discover a Derivation for an Input String
上述推导用CFG推导出$L(G)$中的语句, 与此相反, compiler必须为输入字符串给出一个推导, 这一过程被称为parsing(语法分析). Scanner会为输入字符串中的每个单词标注**词类**, 例如: $a + b \times c$, scanner会输出$\langle name, a \rangle + \langle name, b \rangle \times \langle name, c \rangle$. Parse tree的根节点是已知的, 而parse tree中的叶子节点就是每个输入单词, parser要做的就是找到叶子节点和根节点之间的语法关联, 以下是两种构建parse tree的方法:
1. Top-down parser(自顶向下语法分析器): 从根节点开始构造parse tree, 并向叶子节点方向增长. 每一步会从树的下边缘(当前叶子节点)选择一个nonterminal symbol, 并根据语法规则展开该节点, 子树表示nonterminal symbol的展开式.
2. Bottom-up parser(自底向上语法分析器): 从叶子节点开始构造parse tree, 并向根节点的方向增长. 每一步都从树的上边缘(当前根节点)选择一个连续的子串, 根据语法规则归纳该子串, 父节点表示一个nonterminal symbol.



## 3. Top-Down Parsing
从parse tree的角度来看, top-down parser从根节点开始, 选择一个nonterminal symbol并使用合适的production重写, 直到发生其中一种情况:
1. 所有叶子节点都为terminal symbol, 且输入流已耗尽
2. parse tree中叶子节点与输入流不匹配

第一种情况说明语法分析成功; 第二种情况则存在两种情况: 语法分析中选择了错误的production, 这时可回溯并选择不同的production; 也可能因为输入流不是有效语句, 需要向用户报告错误. Top-down parser之所以能高效地运行, 得益于CFG不需要回溯也可完成语法分析. 通过一些转换, 可将任意语法转换为适当的形式来进行无回溯的自顶向下语法分析. 以下是top-down parser使用最左推导的具体算法:
```code
root $\leftarrow$ node for the start symbol, S ;
focus $\leftarrow$ root;
push(null);
word $\leftarrow$ NextWord( );
while (true) do;
  if (focus is a nonterminal)
    pick rule to expand focus ($A \rightarrow {\beta}_1, {\beta}_2, \ldots, {\beta}_n$);
    build nodes for ${\beta}_1, {\beta}_2, \ldots, {\beta}_n$ as children of focus;
    push(${\beta}_n, {\beta}_{n-1}, \ldots, {\beta}_2$);
    focus $\leftarrow$ ${\beta}_1$;
  end;
  else if (word matches focus)
    word $\leftarrow$ NextWord( );
    focus $\leftarrow$ pop()
  end;
  else if (word = eof and focus = null)
    accept the input and return root;
  else 
    backtrack;
end;
```
该parser的主要部分是while循环, 遵循前序遍历规则, 不断对parse tree中的最左叶子节点进行判断:
1. 若最左叶子节点为nonterminal symbol, 则根据语法规则选择一个production展开
2. 若最左叶子节点为terminal symbol, 则与输入流中的单词匹配:
  1. 匹配成功: 继续判断下一个叶子节点
  2. 匹配失败: 向上回溯, 尝试使用其他production; 若规则都试过, 则再向上回溯.

### 3.1 Transgform a Grammar for Top-Down Parsing
Top-down parser的效率依赖于是否正确选择production, 如果parser总是能选择正确的production, 则十分高效. 一旦做出错误选择, 则效率直线下降. 甚至在某些情况下, parser会陷入死循环而无法终止. 

#### 3.1.1 A Top-Down Parser with Oracular Choice
以$a+b \times c$为例, 假设parser每次都能选择正确的production, 则语法分析过程如下:

| Rule | Sentential Form | Input |
|:-----:|:-----:|:-----:|
|  | $\textit{Expr}$ | $\uparrow \text{name} + \text{name} \times \text{name}$ |
| 1 | $\textit{Expr} + \textit{Term}$ | $\uparrow \text{name} + \text{name} \times \text{name}$ |
| 3 | $\textit{Term} + \textit{Term}$ | $\uparrow \text{name} + \text{name} \times \text{name}$ |
| 6 | $\textit{Factor} + \textit{Term}$ | $\uparrow \text{name} + \text{name} \times \text{name}$ |
| 9 | $\text{name} + \textit{Term}$ | $\uparrow \text{name} + \text{name} \times \text{name}$ |
| $\rightarrow$ | $\text{name} + \textit{Term}$ | $\text{name} \uparrow + \ \text{name} \times \text{name}$ |
| $\rightarrow$ | $\text{name} + \textit{Term}$ | $\text{name} \ + \uparrow \text{name} \times \text{name}$ |
| 4 | $\text{name} + \textit{Term} \times \textit{Factor}$ | $\text{name} \ + \uparrow \text{name} \times \text{name}$ |
| 6 | $\text{name} + \textit{Factor} \times \textit{Factor}$ | $\text{name} \ + \uparrow \text{name} \times \text{name}$ |
| 9 | $\text{name} + \text{name} \times \textit{Factor}$ | $\text{name} \ + \uparrow \text{name} \times \text{name}$ |
| $\rightarrow$ | $\text{name} + \text{name} \times \textit{Factor}$ | $\text{name} + \text{name} \uparrow \times \ \text{name}$ |
| $\rightarrow$ | $\text{name} + \text{name} \times \textit{Factor}$ | $\text{name} + \text{name} \ \times \uparrow \text{name}$ |
| 9 | $\text{name} + \text{name} \times \text{name}$ | $\text{name} + \text{name} \ \times \uparrow \text{name}$ |
| $\rightarrow$ | $\text{name} + \text{name} \times \text{name}$ | $\text{name} + \text{name} \times \text{name} \uparrow$ |

其中, Input中的$\uparrow$表示parser当前所处的位置, Rule中的$\rightarrow$表示parser的位置前进一位. 在production全部选择正确的情况下, parser花费的时间与输入流长度成正比. 

#### 3.1.2 Eliminate Left Recursion
上述语法分析过程中, 每一步都选择了正确的production, 例如: 第一步中使用了**Rule 1**, $\textit{Expr} \rightarrow \textit{Expr} + \textit{Term}$, 而第二步使用了**Rule 3**, $\textit{Expr} \rightarrow \textit{Term}$, 这样很难生成一个具有一致性的parser. 假设parser总是按照rule编号从小到大选择production, 语法分析如下:

| Rule | Sentential Form | Input |
|:-----:|:-----:|:-----:|
|  | $\textit{Expr}$ | $\uparrow \text{name} + \text{name} \times \text{name}$ |
| 1 | $\textit{Expr} + \textit{Term}$ | $\uparrow \text{name} + \text{name} \times \text{name}$ |
| 1 | $\textit{Expr} + \textit{Term} + \textit{Term}$ | $\uparrow \text{name} + \text{name} \times \text{name}$ |
| 1 | $\ldots$ | $\uparrow \text{name} + \text{name} \times \text{name}$ |

之所以出现这种问题, 因为语法规则中存在**直接左递归**, 也就是说, nonterminal symbol推导出的production中第一个符号为自身, 最左推导会不断自身循环. 可使用**右递归**重新表示. 以下面语法为例:
```code
$\textit{Fee} \rightarrow \textit{Fee} \ \alpha$
    $| \ \beta$
```
使用右递归重写后:
```code
$\textit{Fee} \rightarrow \beta \ \textit{Fee'}$
$\textit{Fee'} \rightarrow \alpha \ \textit{Fee'}$
     $| \ \epsilon$
```
这里引入了一个新的nonterminal symbol, 名为$\textit{Fee'}$, 不仅将递归转移到$\textit{Fee}'$上, 还添加了新语法规则$\textit{Fee}' \rightarrow \epsilon$. 其中$epsilon$表示空串, parser在遇到$\epsilon$后会直接前移到下一个节点. 算术运算符的语法规则使用右递归重写后如下:
```code
0  $\textit{Goal} \rightarrow \textit{Expr}$
1  $\textit{Expr} \rightarrow \textit{Term} \ \textit{Expr'}$
2  $\textit{Expr'} \rightarrow + \ \textit{Term} \ \textit{Expr'}$
3  $\textit{Expr'} \rightarrow - \ \textit{Term} \ \textit{Expr'}$
4       $| \ \epsilon$
5  $\textit{Term} \rightarrow \textit{Factor} \ \textit{Term'}$
6  $\textit{Term'} \rightarrow \times \ \textit{Factor} \ \textit{Term'}$
7  $\textit{Term'} \rightarrow \div \ \textit{Factor} \ \textit{Term'}$
8       $| \ \epsilon$
9  $\textit{Factor} \rightarrow \underline{(} \ \textit{Expr} \ \underline{)}$
10      $| \ \text{num}$
11      $| \ \text{name}$
```
重写后的语法规则避免了直接左递归, 但对于拥有大量规则的语法来说, 无法通过手动重写语法来避免**间接左递归**, 例如: $\alpha \rightarrow \beta, \beta \rightarrow \gamma, \gamma \rightarrow \alpha\delta$, 相当于$\alpha \rightarrow \alpha\delta$. 因此需要一种系统化的方法消除语法中所有左递归: forward substitution, 代码如下:
```code
impose an order on the nonterminals,$A_1, A_2, \cdots, A_n$
for i $\leftarrow$ 1 to n do;
  for j $\leftarrow$ 1 to i - 1 do;
    if $\exists$ a production $A_i \rightarrow A_j\gamma$
      replace $A_i \rightarrow A_j\gamma$ with one or more productions that expand $A_j$
  end;
  rewrite the productions to eliminate any direct left recursion on $A_i$
end;
```
该算法为所有nonterminal symbol规定了一个推导顺序, 并从外层循环开始遍历, 内存循环则寻找任何满足以下条件的production: 将$A_i$扩展为$A_j$开头的右侧句型. 假设$A_i \rightarrow A_j\gamma$, 且$A_j \rightarrow {\beta}_1|{\beta}_2|\cdots|{\beta}_k$, 则将$A_i \rightarrow A_j\gamma$替换为$A_i \rightarrow {\beta}_1|{\beta}_2|\cdots|{\beta}_k \gamma$. 这个过程会将**间接左递归**转换为**直接左递归**. 内层循环后, $A_i$相关的所有间接左递归都变为直接左递归, 用右递归消除即可.

#### 3.1.3 Backtrack-Free Parsing
为让parser每次都选择正确的production, 除了当前关注的符号外, 需要考虑下一个输入符号, 称为lookahead symbol(前瞻符号). 通过lookahead symbol, parser可以消除右递归表达式选择造成的不确定性, 也可以说是无回溯的. 从定义上来说, 对于每个语法符号$\alpha$, 定义一个集合$\text{FIRST}(\alpha)$: 从$\alpha$推导出的字符串中第一个terminal symbol的集合. $\text{FIRST}$的定义域为$\text{T} \cup \text{NT} \cup \\{\epsilon, \text{eof}\\}$, 值域为$\text{T} \cup \\{\epsilon, \text{eof}\\}$.

以算法运算符为例, terminal symbol, $epsilon$和eof的FIRST集合也就是符号本身:

|  | num | name | + | - | $\times$ | $\div$ | $\underline{(}$ | $\underline{)}$ | eof | $\epsilon$ |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| FIRST | num | name | + | - | $\times$ | $\div$ | $\underline{(}$ | $\underline{)}$ | eof | $\epsilon$ |

对于nonterminal symbol, 其FIRST集合如下:

|  | Expr | Expr' | Term | Term' | Factor |
|:---:|:---:|:---:|:---:|:---:|:---:|
| FIRST | $\underline{(}, name, num$ | $+, -, \epsilon$ | $\underline{(}, name, num$ | $\times, \div, \epsilon$ | $\underline{(}, name, num$ |

构建nonterminal symbol的FIRST集合的代码如下:
```code
for each $\alpha \in$ (T $\cup$ eof $\cup \epsilon$) do;
  $\text{FIRST}(\alpha) \leftarrow \alpha$;
end;
for each A ∈ N T do;
  $\text{FIRST}(A) \leftarrow \phi$;
end;

while ($\text{FIRST}$ sets are still changing) do;
  for each $p \in P$, where $p$ has the form $A \rightarrow \beta$ do;
    if $\beta$ is ${\beta}_1 {\beta}_2 \ldots {\beta}_k$, where ${\beta}_i \in \text{T} \cup \text{NT}$
      rhs $\leftarrow \text{FIRST}({\beta}_1) − {\epsilon}$;
      i $\leftarrow$ 1;
      while (i $\leq$ k-1 and $\epsilon \in \text{FIRST}({\beta}_i)$) do;
        rhs $\leftarrow$ rhs $\cup$ ($\text{FIRST}({\beta}_{i+1}) − {\epsilon}$);
        i $\leftarrow$ i + 1;
      end;
    end;
    if i = k and $\epsilon \in \text{FIRST}({\beta}_k)$
      rhs $\leftarrow$ rhs $\cup \ \epsilon$;
    $\text{FIRST}$(A) ← $\text{FIRST}$(A) $\cup$ rhs;
  end;
end;
```
对于每个production $A \rightarrow \beta$来说, $\beta$可以表示成多个符号的连接, 也就是${\beta}_1 {\beta}_2 \ldots {\beta}_k$, 其FIRST集合为$\text{FIRST}({\beta}_1) \cup \text{FIRST}({\beta}_2) \cup \ldots \cup \text{FIRST}({\beta}_n)$, 其中${\beta}_n$为$\beta$中首个$\text{FIRST}$不包含$\epsilon$的符号. 
但还存在一个问题: $\text{FIRST}(\epsilon)$为$\\{\epsilon\\}$, 导致无法匹配任何词类, 也可以说, 可以匹配任何词类. 因此需要定义一个新的集合$\text{FOLLOW(A)}$, 表示紧接nonterminal symbol A之后出现的符号集合. 以下是计算$\text{FOLLOW}$集合的算法:
```code
for each A $\in$ NT do;
  $\text{FOLLOW}$(A) $\leftarrow \phi$;
end;
$\text{FOLLOW}$(S) $\leftarrow$ {eof} ;
while ($\text{FOLLOW}$ sets are still changing) do;
  for each $p \in P$ of the form $A \rightarrow {\beta}_1 {\beta}_2 \cdots {\beta}_k$ do;
    $\text{TRAILER} \leftarrow \text{FOLLOW}$(A);
    for i $\leftarrow$ k down to 1 do;
      if ${\beta}_i \in \text{NT}$ then begin;
        $FOLLOW({\beta}_i) \leftarrow \text{FOLLOW}({\beta}_i) \ \cup \ \text{TRAILER}$;
        if $\epsilon \in \text{FIRST}({\beta}+i)$
          $\text{TRAILER} \leftarrow \text{TRAILER} \cup (\text{FIRST}({\beta}_i) −\epsilon)$;
        else
          $\text{TRAILER} \leftarrow \text{FIRST}({\beta}_i)$;
      else 
        $\text{TRAILER} \leftarrow \text{FIRST}({\beta}_i)$; // is {${\beta}_i$}
    end;
  end;
end;
```
该算法基于之前的$\text{FIRST}$集合. TRAILER表示前一个字符可能承接的符号集合. 假设production为$A \rightarrow \beta$, $\beta$可以表示为多个符号的连接${\beta}_1 {\beta}_2 \cdots {\beta}_k$. 每次处理production时都需初始化TRAILER为$\text{FOLLOW}(A)$, 表示$\text{FOLLOW}({\beta}_n)$, 然后从后向前遍历每个符号:
1. 若$\beta_i$为terminal symbol, 将TRAILER置为$\text{FIRST}(\beta_i)$集合, 表示$\text{FOLLOW}(\beta_{i-1})$
2. 若${\beta}_i$为nonterminal symbol, 则将TRAILER并入$\text{FOLLOW}(\beta_i)$, 并重新设置TRAILER:
  1. 若$\text{FIRST}({\beta}_i)$包含$\epsilon$: 将TRAILER置为除$\epsilon$的$\text{FIRST}({\beta}_i)$所有符号
  2. 若$\text{FIRST}({\beta}_i)$不包含$\epsilon$: 将TRAILER置为$\text{FIRST}({\beta}_i)$

算术表达式的FOLLOW集合如下:

|  | Expr | Expr' | Term | Term' | Factor |
|:----:|:----:|:----:|:----:|:----:|:----:|
| FOLLOW | eof, $\underline{)}$ | eof, $\underline{)}$ | eof, +, -, $\underline{)}$ | eof, +, -, $\underline{)}$ | eof, +, -, $\times$, $\div$, $\underline{)}$ |

使用FIRST和FOLLOW集合, 可以规定一个增强版FIRST: $\text{FIRST}^+$
$$
\text{FIRST}^+(A \rightarrow \beta) = 
\begin{cases}
\text{FIRST}(\beta), & \text{if} \\ \epsilon \notin \text{FIRST}(\beta)\\\\
\text{FIRST}(\beta) \cup \text{FOLLOW}(A), & \text{otherwise}
\end{cases}
$$

对于某个nonterminal symbol A, 存在多个production $A \rightarrow {\beta}_1 | {\beta}_2 | \cdots | {\beta}_n$, 无回溯的语法必定具有以下属性:
$$
\text{FIRST}^+(A \rightarrow {\beta}_i) \cap \text{FIRST}^+(A \rightarrow {\beta}_j) = \phi, \\ \forall \\ 1 \leq i, j \leq b, i \neq j 
$$

以下是算术表达式的全部$\text{FIRST}^+$:

| Production | $\text{FIRST}^+$ |
|:----:|:----:|
| Expr $\rightarrow$ Term Expr' | $\underline{(}$, name, num |
| Expr' $\rightarrow$ + Term Expr' | + |
| Expr' $\rightarrow$ - Term Expr' | - |
| Expr' $\rightarrow \epsilon$ | $\underline{)}$, eof, $\epsilon$ |
| Term $\rightarrow$ Factor Term' | $\underline{(}$, name, num |
| Term' $\rightarrow \times$ Factor Term' | $\times$ |
| Term' $\rightarrow \div$ Factor Term' | $\div$ |
| Term' $\rightarrow \epsilon$ | +, -, $\underline{)}$, eof, $\epsilon$ |
| Factor $rightarrow$ (Expr) | $\underline{(}$ |
| Factor $rightarrow$ num | num |
| Factor $rightarrow$ name | name |

#### 3.1.4 Left-Factoring to Eliminate Backtracking
并非所有语句都是无回溯的, 以下面的语法规则为例:
```code
11 $\textit{Factor} \rightarrow \text{name}$
12     $| \rightarrow \text{name}$
13     $| \rightarrow \text{name} \underline{[} \textit{ArgList} \underline{]}$
14     $| \rightarrow \text{name} \underline{(} \textit{ArgList} \underline{)}$
15 $\textit{ArgList} \rightarrow \ \textit{Expr} \ \textit{MoreArgs}$
16 $\textit{MoreArgs} \rightarrow \ , \ \textit{Expr} \ \textit{MoreArgs}$
17         $| \ \epsilon$
```
可以看到, 第11, 12, 13规则的$\text{FIRST}^+$集合是相同的, 都是name, 可能导致回溯. 可以转换production来生成不相交的$\text{FIRST}^+$集合:
```code
11 $\textit{Factor} \rightarrow \text{name} \textit{Arguments}$
12 $\textit{Arguments} \rightarrow \underline{[} ArgList \underline{]}$
13       $| \ \rightarrow \underline{(} ArgList \underline{)}$
14       $| \ \rightarrow \epsilon$
```
重写$\textit{Factor}$分为两个步骤, 称为left factoring(提取左因子):
1. 匹配规则中的公共前缀
2. 为不同的后缀添加一个新的nonterminal symbol: $\textit{Arguments}$

形式上描述: 对于production $A \rightarrow \alpha \beta_1 | \alpha \beta_2 | \cdots | \alpha \beta_n | \gamma_1 | \gamma_2 | \cdots | \gamma_j$, $\alpha$为公共前缀, $\gamma_i$表示不从$\alpha$开始右侧句型. 转换后用新的nonterminal symbol B来表示后缀:
```code
$A \rightarrow \alpha B | \gamma_1 | \gamma_2 | \cdots | \gamma_j$
$B \rightarrow \beta_1 | \beta_2 | \cdots | \beta_n$
```

### 3.2 Top-Down Recursive-Descent Parser
递归下降的无回溯parser在结构上呈现为一组相互递归的过程, 每个nonterminal symbol都对于一个**过程**. 例如: nonterminal symbol A的过程可以识别输入流中的A实例. 为识别A的产生式中的nonterminal symbol B, 需要调用B的**过程**. 以下是${Expr}'$的右递归表达式语法:

| Production | $\text{FIRST}^+$ |
|:----:|:----:|
| $\text{Expr}' \rightarrow + \\ \text{Term} \\ \text{Expr}'$ | $ + $ |
| $\qquad \\ \| \\ - \\ \text{Term} \\ \text{Expr}'$ | $ - $ |
| $\qquad \\ \| \\ \epsilon$ | $ \epsilon, \text{eof}, ) $ |

为识别$\text{Expr}'$, 需要创建一个函数名为EPrime(), 遵循一个简单的模式: 根据${\text{FIRST}^+}$集合和匹配输入流中的符号. 以下是EPrime的代码:
```code
EPrime()
  /* $\text{Expr}' \rightarrow + \ \text{Term} \ \text{Expr}' \ | - \text{Term} \ \text{Expr}'$ */
  if (word = + or word = -)
    word $\leftarrow$ NextWord();
    if (Term())
      return EPrime();
    else 
      return false;
  else if (word = $\underline{)}$ or word = eof) /* $\text{Expr}' \rightarrow \epsilon $ */
      return true;
  else /* no match */
    report a syntax error;
  return false;
```
构建top-Down recursive-descent parser的策略比较简单: 为每个nonterminal symbol构建一个**过程**来识别与之匹配的产生式. 直接过程彼此嵌套并互相调用, 并可在无法找到预期terminal symbol时生成错误信息:
```code
/* Goal $\rightarrow$ Expr */
Main( )
  word ${leftarrow}$ NextWord( );
  if (Expr( ))
    if (word = eof )
      report success;
    else
      Fail( );

Fail( )
  report syntax error;
  attempt error recovery or exit;

/* Expr $\rightarrow$ Term Expr'*/
Expr( )
  if (Term( ))
    return EPrime( );
  else
    Fail();

/* Expr' $\rightarrow$ + Term Expr' */
/* Expr' $\rightarrow$ - Term Expr' */
EPrime( )  
  if (word = + or word = - )
    word $\leftarrow$  NextWord( );
    if (Term())
      return EPrime( );
    else
      Fail();
  else if (word = ) or word = eof)
    return true; /* $\text{Expr}' \rightarrow \epsilon$ */
  else
    Fail();

/* Term $\rightarrow$ Factor Term' */
Term( )
  if (Factor())
    return TPrime( );
  else
    Fail();

/* Term' $\rightarrow \times$ Factor Term' */
/* Term' $\rightarrow \div$ Factor Term' */
TPrime( ) 
  if (word = $\times$ or word = $\div$)
    word $\leftarrow$ NextWord( );
    if (Factor( ))
      return TPrime( );
    else
      Fail();
  else if (word = + or word = - or word = ) or word = eof)
    return true; /* Term' $\rightarrow \epsilon$ */
  else
    Fail();

/* Factor $\rightarrow$ (Expr) */
Factor( )
  if (word = $\underline{(}$ )
    word $\leftarrow$ NextWord( );
    if (not Expr( ))
      Fail();
    if (word $\neq \underline{)}$)
      Fail();
    word $\leftarrow$ NextWord( );
    return true;
  /* Factor $\rightarrow$ num */
  /* Factor $\rightarrow$ name */
  else if (word = num or word = name)
    word $\leftarrow$ NextWord( );
    return true;
  else
    Fail();
```


### 3.3 Table-Driven LL(1) Parser
对于无回溯语法, 使用$\text{FIRST}^+$集合可以实现top-down parser, 称为**LL(1)**. 该语法分析器由左(Left)到右扫描输入, 构建一个最左推导(Leftmost), 其中仅使用一个前瞻符号(1). 以下是LL(1)的算法:
```code
word $\leftarrow$ NextWord( );
push eof onto Stack;
push the start symbol, S, onto Stack;
focus $\leftarrow$ top of Stack;
while (1)
  if (focus = eof and word = eof)
    report success and exit the loop;
  else if (focus $\in$ T or focus = eof)
    if focus matches word
      pop Stack;
      word $\leftarrow$ NextWord( );
    else
      report an error looking for symbol at top of stack;
  else /* focus is a nonterminal */
    if Table[focus, word] is $A \rightarrow B_1 B_2 \cdots B_k$
      pop Stack;
      for i $\leftarrow$ k to 1 by -1 do;
        if ($B_i \neq\epsilon$)
          push $B_i$ onto Stack;
    else
      report an error expanding focus;
  focus $\leftarrow$ top of Stack;
```
以下是LL(1)的右递归表达式语法表:

| | eof | + | - | $\times$ | $\div$ | $\underline{(}$ | $\underline{)}$ | name | num |
|:---:||:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:
| Goal  | - | - | - | - | - | 0 | - | 0 | 0 |
| Expr  | - | - | - | - | - | 1 | - | 1 | 1 |
| Expr' | 4 | 2 | 3 | - | - | - | 4 | - | - |
| Term  | - | - | - | - | - | 5 | - | 5 | 5 |
| Term' | 8 | 8 | 8 | 6 | 7 | - | 8 | - | - |
| Factor| - | - | - | - | - | 9 | - | 11| 10|

为构建LL(1)语法分析器, compiler需要一个右递归且无回溯的语法, 和一个parser generator来构造parser. LL(1) parser generator最常见的技术就是table-driven skeleton parser. 语法分析表将nonterminal symbol和前瞻符号映射到对应的产生式, 给定nonterminal symbol A和前瞻符号w, Table[A, w]指定用于扩展该语法树的产生式. 以下是构造Table的算法:
```code
build $\text{FIRST}$, $\text{FOLLOW}$ and $\text{FIRST}^+$ sets
for each nonterminal symbol A do:
  for each terminal w do;
    Table[A, w] $\leftarrow$ error;
  for each production p of the form $A \rightarrow \beta$ do;
    for each terminal w $\in \text{FIRST}^+(A \rightarrow \beta)$ do;
      Table[A, w] $\leftarrow$ p;
    if eof $\in \text{FIRST}^+(A \rightarrow \beta$)
      Table[A, eof] $\leftarrow$ p;
```
对于输入流$a + b \times c$, 以下是整个语法分析过程:

| Rule | Stack | Input |
|:----:|:----:|:----:|
| -             | eof Goal | $\uparrow$ name + name $\times$ name |
| 0             | eof Expr | $\uparrow$ name + name $\times$ name |
| 1             | eof Expr' Term | $\uparrow$ name + name $\times$ name |
| 5             | eof Expr' Term' Factor | $\uparrow$ name + name $\times$ name |
| 11            | eof Expr' Term' name | $\uparrow$ name + name $\times$ name |
| $\rightarrow$ | eof Expr' Term' | name $\uparrow$ + name $\times$ name |
| 8             | eof Expr' | name $\uparrow$ + name $\times$ name |
| 2             | eof Expr' Term + | name $\uparrow$ + name $\times$ name |
| $\rightarrow$ | eof Expr' Term | name + $\uparrow$ name $\times$ name |
| 5             | eof Expr' Term' Factor | name + $\uparrow$ name $\times$ name |
| 11            | eof Expr' Term' name | name + $\uparrow$ name $\times$ name |
| $\rightarrow$ | eof Expr' Term' | name + name $\uparrow$ $\times$ name |
| 6             | eof Expr' Term' Factor $\times$ | name + name $\uparrow$ $\times$ name |
| $\rightarrow$ | eof Expr' Term' Factor | name + name $\times$ $\uparrow$ name |
| 11            | eof Expr' Term' name | name + name $\times$ $\uparrow$ name |
| $\rightarrow$ | eof Expr' Term' | name + name $\times$ name $\uparrow$ |
| 8             | eof Expr' | name + name $\times$ name $\uparrow$ |
|               | eof | name + name $\times$ name $\uparrow$ |
