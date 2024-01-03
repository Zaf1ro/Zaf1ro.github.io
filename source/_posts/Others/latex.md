---
title: LaTeX
category:
  - Others
  - LaTeX
tag:
  - Others
abbrlink: '4865'
date: 2018-02-03 15:36:00
---

## 1. Equation
* in-line delimiter
`\$a + b = c\$` $a + b = c$

* math delimiter
`\$\$a + b = c\$\$`
$$a + b = c$$

* automatic numbering
```md
\begin{equation}
E = mc^2 \text{, Description}
\label{eq:Sample}
\end
```
\begin{equation}
E = mc^2 \text{, Description}
\label{eq:Sample}
\end{equation}



## 2. Superscript, Subscript
`^`表示上标, `_`表示下标. 如果上下标内容多余一个字符, 则需要用`{}`将其变成一个整体.

1. Superscript
```md
\$\$ x^{y^z} = (1 + e^x)^{-2xy^w} \$\$
```
$$ x^{y^z} = (1 + e^x)^{-2xy^w} $$

2. Subscript
```md
\$\$ x_n = y_n + 1 \$\$
```
$$ x\_n = y\_n + 1 $$

3. Subscript and Superscript
```md
\$\$ x_1^2  x{_1}{^2} \$\$
```
$$ x_1^2 \quad x{_1}{^2} $$



## 3. Bracket and Delimiter
Input | Output | Input | Output
:-----:|:-----:|:-----:|:-----:
\langle   | $\langle$ | \rangle | $\rangle$
\lceil    | $\lceil$  | \rceil  | $\rceil$
\lfloor   | $\lfloor$ | \rfloor | $\rfloor$
\lbrace	  | $\lbrace$ | \rbrace | $\rbrace$

Sample:
```md
\$\$ f(x,y,z) = 3y^2z \left( 3 + \frac{7x + 5}{1 + y^2} \right) \$\$
```
$$ f(x,y,z) = 3y^2z \left( 3 + \frac{7x + 5}{1 + y^2} \right) $$



## 4. Space
1em, em, m表示当前字体下接近字母'M'的宽度(approximately the width of an "M" in the current font)

width | Input | Output
:-----:|:-----:|:-----:
两个m的宽度 | a \qquad b | $a \qquad b$
一个m的宽度 | a \quad b | $a \quad b$
1/3m的宽度  | a\ b | $a\ b$
2/7m的宽度  | a\;b | $a\;b$
1/6m的宽度  | a\,b | $a\,b$
无空格      | ab | $ab$
缩进1/6宽度 | a\\!b | $a\\!b$



## 5. Root
Sample:
```md
\$\$ \sqrt{2} \quad and \quad \sqrt[n]{3} \$\$
```
$$ \sqrt{2} \quad and \quad \sqrt[n]{3} $$



## 6. Ellipsis
Sample:
```md
\$\$ f{x_1, x_2, \underbrace{\ldots}_{\rm ldots}, x_n } = x{_1}{^2} + x{_2}{^2} + {\cdots} + x{_n}{^n} \$\$
```
$$ f(x\_1, x\_2, \underbrace{\ldots}\_{\rm ldots}, x\_n ) = x{\_1}{^2} + x{\_2}{^2} + \underbrace{\cdots}_{\rm cdots} + x{\_n}{^n} $$



## 7. Vector Arrow
* Sample 1
```md
\$\$ \vec{a} \cdot \vec{b} = 0 \$\$
```
$$\vec{a} \cdot \vec{b} = 0$$

* Sample 2
```md
\$\$ \overleftarrow{xy} \quad and \quad \overleftrightarrow{xy} \quad and \quad \overrightarrow{xy} \$\$
```
$$\overleftarrow{xy} \quad and \quad \overleftrightarrow{xy} \quad and \quad \overrightarrow{xy}$$



## 8. Integral
```md
\$\$ \int_0^1 {x^2} x \$\$
```
$$ \int_0^1 {x^2} dx $$



## 9. Limit
* Sample 1
```md
\$\$ \lim_{n \to +\infty} \frac{1}{n(n + 1)} \$\$
```
$$ \lim_{n \to +\infty} \frac{1}{n(n + 1)} $$

* Sample 2
```md
\$\$ \lim_{1 \leftarrow n} \frac{1}{n(n + 1)} \$\$
```
$$ \lim_{1 \leftarrow n} \frac{1}{n(n + 1)} $$



## 10. Sum and Product
* Sum
```md
\$\$ \sum_{i=1}^{n} \frac{1}{i^2} \$\$
```
$$ \sum_{i=1}^{n} \frac{1}{i^2} $$

* Product
```md
\$\$ \prod_{i=1}^{n} \frac{1}{i^2} \$\$
```
$$ \prod_{i=1}^{n} \frac{1}{i^2} $$



## 11. Font Styles
| Description | Input | Output |
|:---:|:---:|:---:|
| Normal Text | \text{abc} | $\text{abc}$ |
| Text Mode | \textrm{abc} | $\textrm{abc}$ |
| Italic Text | \textit{abc} | $\textit{abc}$ |
| Bold Text | \textbf{abc} | $\textbf{abc}$ |



## 12. Arrow
| Input | Output | Input | Output |
|:-----:|:------:|:-----:|:------:|
| \uparrow     | $\uparrow$     | \Uparrow          | $\Uparrow $         |
| \leftarrow   | $\leftarrow$   | \Leftarrow        | $\Leftarrow$        |
| \rightarrow  | $\rightarrow$  | \Rightarrow       | $\Rightarrow$       |
| \downarrow   | $\downarrow$   | \Downarrow        | $\Downarrow$        |
| \updownarrow | $\updownarrow$ | \rightrightarrows | $\rightrightarrows$ |
| \Updownarrow | $\Updownarrow$ | \rightleftarrows  |	$\rightleftarrows$  |
| \leftrightarrow   | $\leftrightarrow$   | \Leftrightarrow   | $\Leftrightarrow$  |
| \rightrightarrows | $\rightrightarrows$ | \rightleftarrows  | $\rightleftarrows$ |
| \nearrow | $\nearrow$ | \swarrow | $\swarrow$ |
| \searrow | $\searrow$ | \nwarrow | $\nwarrow$ |
| \Longleftarrow | $\Longleftarrow$ | \Longrightarrow | $\Longrightarrow$ |
| \hookleftarrow | $\hookleftarrow$ | \hookrightarrow | $\hookrightarrow$ |
| \leftharpoonup | $\leftharpoonup$ | \rightharpoonup | $\rightharpoonup$ |
 


## 13. Greek Letters
Input | Output | Input | Output | Input | Output | Input | Output
:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:
\alpha  | $\alpha$     | \beta	| $\beta$   | \gamma	| $\gamma$   | \delta  | $\delta$
\epsilon| $\epsilon$   | \zeta	| $\zeta$   | \eta		| $\eta$     | \theta	| $\theta$
\iota		| $\iota$      | \kappa	| $\kappa$  | \lambda | $\lambda$  | \mu     | $\mu$
\nu	    | $\nu$        | \xi    | $\xi$     | o		    | $o$        | \pi     | $\pi$
\rho		| $\rho$       | \sigma | $\sigma$  | \tau		| $\tau$     | \upsilon| $\upsilon$
\phi		| $\phi$       | \chi		| $\chi$    | \psi		| $\psi$     | \omega  | $\omega$



## 14. Set Symbols
Input | Output | Input | Output | Input | Output | Input | Output
:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:
\emptyset   | $\emptyset$   | \in       | $\in$         | \notin	| $\notin$      | \subset	| $\subset$
\supset		| $\supset$     | \subseteq	| $\subseteq$   | \supseteq	| $\supseteq$   | \bigcap   | $\bigcap$
\bigcup	    | $\bigcup$     | \bigvee	| $\bigvee$     | \bigwedge	| $\bigwedge$   | \biguplus	| $\biguplus$



## 15. Relation Symbols
Input | Output | Input | Output | Input | Output | Input | Output
:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:
\pm         | $\pm$      | \times     | $\times$     | \div      | $\div$      | \mid       | $\mid$ 	
\nmid		| $\nmid$        | \cdot		  | $\cdot$      | \circ		 | $\circ$     | \ast	    | $\ast$
\bigodot    | $\bigodot$ | \bigotimes	| $\bigotimes$ | \bigoplus | $\bigoplus$ | \leq	     | $\leq$
\geq        | $\geq$     | \neq		    | $\neq$       | \approx   | $\approx$   | \equiv	   | $\equiv$
\sum        | $\sum$     | \prod		  | $\prod$      | \coprod   | $\coprod$   | \backslash | $\backslash$



## 16. Integral Signs
Input | Output | Input | Output | Input | Output
:-----:|:-----:|:-----:|:-----:|:-----:|:-----:
\int	| $\int$    | \iint  | $\iint$  | \iiint | $\iiint$	
\iiiint | $\iiiint$ | \oint  | $\oint$   | \prime | $\prime$
\lim    | $\lim$    | \infty | $\infty$ | \nabla | $\nabla$



## 17. Logic Notations
Input | Output | Input | Output
:-----:|:-----:|:-----:|:-----:
\because    | $\because$    | \therefore | $\therefore$	
\forall     | $\forall$     | \exists    | $\exists$
\not\subset	| $\not\subset$ | \not<      | $\not<$
\not>		    | $\not>$       | \not=      | $\not=$



## 18. Dots
 Input | Output | Input | Output
:-----:|:------:|:-----:|:-----:
\cdots | $\cdots$ | \ddots | $\ddots$	
\ldots | $\ldots$  | \vdots | $\vdots$



## 19. Matrix
1. matrix
```md
\begin{matrix} 
1 & 2 \\ 3 & 4
\end{matrix}
```
\begin{matrix} 1 & 2 \\\\ 3 & 4 \\\\ \end{matrix}

2. pmatrix
```md
\begin{pmatrix}
1 & 2 \\ 3 & 4 
\end{pmatrix}
```
$$ \begin{pmatrix} 1 & 2 \\\\ 3 & 4 \end{pmatrix} $$

3. bmatrix
```md
\begin{bmatrix} 
1 & 2 \\ 3 & 4
\end{bmatrix}
```
\begin{bmatrix} 1 & 2 \\\\ 3 & 4 \end{bmatrix}

4. Bmatrix
```md
\begin{Bmatrix}
1 & 2 \\ 3 & 4
\end{Bmatrix}
```
\begin{Bmatrix} 1 & 2 \\\\ 3 & 4 \end{Bmatrix}

5. vmatrix
```md
\begin{vmatrix}
1 & 2 \\ 3 & 4
\end{vmatrix}
```
\begin{vmatrix} 1 & 2 \\\\ 3 & 4 \end{vmatrix}

6. Vmatrix
```md
\begin{Vmatrix} 
1 & 2 \\\\ 3 & 4 \\\\ 
\end{Vmatrix}
```
\begin{Vmatrix} 1 & 2 \\\\ 3 & 4 \end{Vmatrix}



## 20. Equation
### 20.1 Equation Numbering
方程式序列无需声明公式符号`$`和`$$`, `{align}`包括的语句自动编号, 序列的每一行都需要用`\\`分行
Sample: 
```md
\begin{align}
  \sqrt{37} = \sqrt{\frac{73^2 - 1}{12^2}} \\
  = \sqrt{\frac{73^2}{12^2} \cdot \frac{73^2 - 1}{73 ^ 2}} \\
  = \sqrt{\frac{73^2}{12^2}} \sqrt{\frac{73^2 - 1}{73^2}} \\
  = \frac{73}{12} \sqrt{1 - \frac{1}{73^2}} \\
  \approx \frac{73}{12} \left( 1 - \frac{1}{2 \cdot 73^2} \right)
\end{align}
```
\begin{align}
  \sqrt{37} = \sqrt{\frac{73^2 - 1}{12^2}} \\\\
  = \sqrt{\frac{73^2}{12^2} \cdot \frac{73^2 - 1}{73 ^ 2}} \\\\
  = \sqrt{\frac{73^2}{12^2}} \sqrt{\frac{73^2 - 1}{73^2}} \\\\
  = \frac{73}{12} \sqrt{1 - \frac{1}{73^2}} \\\\
  \approx \frac{73}{12} \left( 1 - \frac{1}{2 \cdot 73^2} \right)
\end{align}

### 20.2 Comment
在`{align}`中灵活组合`\text`和`\tag`语句可实现添加注解和手动编号
Sample:
```md
\begin{align}
  v + w = 0               && \text{Given} \tag 1 \\
  -w = -w + 0             && \text{additive identity} \tag 2 \\
  -w + 0 = -w + (v + w)   && \text{equations $(1)$ and $(2)$} \tag 3
\end{align}
```
\begin{align}
  v + w = 0               && \text{Given} \tag 1 \\\\
  -w = -w + 0             && \text{additive identity} \tag 2 \\\\
  -w + 0 = -w + (v + w)   && \text{equations $(1)$ and $(2)$} \tag 3
\end{align}



## 21. Conditional Expression
```md
$$
f(n) = 
\begin{cases}
\frac{n}{2}, & \text{if $n$ is even} \\[2ex]
3n + 1, & \text{if $n$ is odd}
\end{cases}
$$
```
$$
f(n) = 
\begin{cases}
\frac{n}{2}, & \text{if $n$ is even} \\\\[2ex]
3n + 1, & \text{if $n$ is odd}
\end{cases}
$$
