---
title: MATLAB
category:
  - Others
  - MATLAB
tag:
  - Others
abbrlink: '5452'
date: 2018-02-10 13:27:20
---

## 1. Variable
声明变量并赋值即可存储变量, 默认为ans
```matlab
>> a = 1
a =
    1

>> b = cos(a)
b =
    0.5403

>> e = a * b
e =
    0.5403

>> a + b
ans =
    1.5403

>> ans
ans =
    1.5403
```



## 2. Matrics and Arrays
### 2.1 Create Matrix and Array
1. row vector
```matlab
>> a = [1 2 3 4]
a =
     1     2     3     4
```

2. multiple rows
```matlab
>> a = [1 2 3; 4 5 6; 7 8 10]
a =
     1     2     3
     4     5     6
     7     8    10
```

3. create  matrix by function
rand(a, b, c)的参数说明: a表示矩阵行数, b表示矩阵列数, c表示矩阵个数, 矩阵的元素范围为[0, 1]的随机数
```matlab
>> a = zeros(3)
a =
     0     0     0
     0     0     0
     0     0     0

>> b = ones(3)
b =
     1     1     1
     1     1     1
     1     1     1

>> c = rand(3,3,1)
c =
    0.7952    0.4456    0.7547
    0.1869    0.6463    0.2760
    0.4898    0.7094    0.6797
```

### 2.2 Matrix and Array Operations
1. Array
```matlab
>> a = [1 2 3]
a =
     1     2     3

>> a + 10
ans =
    11    12    13


>> a * 10
ans =
    10    20    30
```

2. Matrix 
```matlab
>> a = [1 2 ; 3 4]
a =
     1     2
     3     4

>> a + 10
ans =
    11    12
    13    14

>> a'       %{transpose a matrix}%
ans =
     1     3
     2     4

>> inv(a)   %{inverse a matrix}%
ans =
   -2.0000    1.0000
    1.5000   -0.5000

>> a * inv(a)
ans =
    1.0000         0
    0.0000    1.0000

>> a .* a   %{element-wise multiplication}%
ans =
     1     4
     9    16

>> a^2
ans =
     7    10
    15    22

>> a.^2     %{element-wise power}%
ans =
     1     4
     9    16
```

### 2.3 Concatenation
```matlab
>> a = [1 2; 3 4]
a =
     1     2
     3     4

>> A = [a, a]
A =
     1     2     1     2
     3     4     3     4

>> A = [a; a]
A =
     1     2
     3     4
     1     2
     3     4
```



## 3. Complex Numbers
```matlab
>> sqrt(-1)
ans =
   0.0000 + 1.0000i

>> c = [3+4i, 4+3j; -i, 10j]
c =
   3.0000 + 4.0000i   4.0000 + 3.0000i
   0.0000 - 1.0000i   0.0000 +10.0000i
```



## 4. format
format函数用于控制输出的显示格式, 默认为short. MATLAB支持的格式有常用的以下几种:
* short: 5位字长定点数
* long: 15位字长定点数
* hex: 16进制
* compact: 压缩空格
* rat: 分数
```matlab
>> format short
>> a = 1.2
a =
    1.2000


>> format long
>> a = 1.2
a =
   1.200000000000000

>> format hex
>> a = 1.2
a =
   3ff3333333333333

>> format rat
>> a = 1.2
a =
       6/5
```



## 5. Indexing
magic(n)函数: 生成元素范围为$[1, n^2]$的矩阵, 每一行和每一列的和相同
```matlab
>> A = magic(3)
A =
       8              1              6       
       3              5              7       
       4              9              2  
```
MATLAB中的坐标必须为正整数, 越界报错
```matlab
>> A(3,1)   %{get the specify row and column subscript}%
ans =
       4 

>> A(0,0)
Subscript indices must either be real positive
integers or logicals. 

>> A(4,2)
Index exceeds matrix dimensions. 
```
也可通过元素的依次顺序获得元素(从左到右, 从上到下排序)
```matlab
>> A(9)
ans =
       2 
```
colon operator(冒号)可指定矩阵的一块区间
```matlab
>> A(1:3, 2)    %{first three rows and the second column}%
ans =
       1       
       5       
       9    
```
colon operator前后不标记start和end说明表示整个区间
```matlab
>> A(2, :)      %{all second row}%
ans =
     3     5     7
```
通过start:step:end可生成均匀分布的vector
```matlab
>> 0:2:10
ans =
     0     2     4     6     8    10
```
通过赋值空数组来实现删除行和列
```matlab
>> X = magic(4);
>> X(:,2) = []
X =
    16     3    13
     5    10     8
     9     6    12
     4    15     1

>> X = magic(4);
>> X(2,:) = []
X =
    16     2     3    13
     9     7     6    12
     4    14    15     1
```



## 6. Workspace Variable
### 6.1 View the contents of workspace
whos语句可查看当前workspace下有多少个variable和其属性. clear命令可清楚当前workspace下的所有variable
```matlab
>> A = magic(4);
>> B = rand(2,2,2);
>> whos
  Name      Size             Bytes  Class     Attributes
  A         4x4                128  double              
  B         2x2x2               64  double 

>> clear
```

### 6.2 Save and Load
```matlab
save myfile.mat
load myfile.mat
```



## 7. Text and Character
使用single quote(单引号)来包裹字符串
```matlab
>> myText = 'Hello, world'
myText =
Hello, world

>> whos myText
  Name        Size            Bytes  Class    Attributes
  myText      1x12               24  char  
```
也可用数组来连接两个或多个text
```matlab
>> longText = [myText ' - ', 'otherText']
longText =
Hello, world - otherText
```
数字转字符用num2str或int2str, semicolon用于不显示计算结果
```matlab
>> f = 71;
>> c = (f-32)/1.8;
>> tmpText = ['Temperature is ', num2str(c), 'C']
tmpText =
Temperature is 21.6667C
```



## 8. Calling Function
max()可返回vector中最大元素值
```matlab
>> A = [1 2 3];
>> max(A)
ans =
     3
```
max()也可找出两个matrix中每个位置上最大的元素, 不同行数或不同列数的两个matrix进行max操作时报错
```matlab
>> A = [1 1 6];
>> B = [3 3 3];
>> max(A, B)
ans =
     3     3     6

>> A = [0 0 0; 1 1 1; 2 2 2];
>> B = [1 1 1; 0 0 0; 3 3 3];
>> max(A, B)
ans =
     1     1     1
     1     1     1
     3     3     3
```
max()也可返回最大元素的位置
```matlab
>> [maxA, loc] = max(A)
maxA =
     8     9     5  %{max value of each column}%
loc =
     2     2     3  %{which row of the max value in each column}%
```
clc命令可清空Command Window中所有输入的指令



## 9. 2D and 3D Plots
### 9.1 Line Plots
```matlab
>> x = 0: pi/100: 2*pi;
>> y = sin(x);
>> plot(x, y)
>> xlabel('x')
>> ylabel('sin(x)')
>> title('Plot of the Sin Function')
```
![sin](/images/Others/matlab/sin.png)

### 9.2 Different Line
MATLAB支持多种格式和颜色的线段表示, 以下是常用的几种格式:

Specifier   | LineStyle
:-----:|:-----:
'-'         | Solid Line
'--'        | Dashed Line
':'         | Dotted Line
'-.'        | Dashed-dot Line

Specifier   | Color     | Specifier   | Color
:-----:|:-----:|:-----:|:-----:
r           | Red       | g           | Green
b           | Blue      | c           | Cyan
m           | Magenta   | y           | Yellow
k           | Black     | w           | White 

例如:
```matlab
>> x = 0: pi/100: 2*pi;
>> y = sin(x);
>> plot(x, y, 'r--')
```
![red dashed line sin](/images/Others/matlab/red-dash-line-sin.png) 

### 9.3 Add plots to an existing figure
hold on可在不删除之前Plot的情况下添加图像, hold off可删除之前添加的图像
```matlab
x = 0: pi/100: 2*pi;
y = sin(x);
plot(x, y)
hold on
y2 = cos(x)
plot(x, y, ':')
legend('sin','cos')
```
![sin and cos](/images/Others/matlab/sin-and-cos.png)




## 10. Plots
三维的plot由两个变量组成, 函数可表示为 $z = f(x, y)$. 使用meshgrid创建 $(x,y)$ 的集合, 再使用surf展示
```matlab
>> [x, y] = meshgrid(-2:0.2:2, -2:0.2:2);
>> z = x .* exp(-x.^2 - y.^2);
>> surf(x, y, z);
```
![3-D Plot](/images/Others/matlab/surface-plot.png)



## 11. Subplots
可使用subplot函数实现在一个window中显示多个plot. subplot(a, b, c)中a表示plot的行数, b表示plot的列数, c表示该plot在window中的位置.
```matlab
>> t = 0: pi/10: 2*pi;
>> [x, y, z] = cylinder(4*cos(t));
>> subplot(2,2,1); mesh(x); title('X');
>> subplot(2,2,2); mesh(y); title('Y');
>> subplot(2,2,3); mesh(z); title('Z');
>> subplot(2,2,4); mesh(x,y,z); title('X,Y,Z');
```
![subplots](/images/Others/matlab/subplots.png)



## 12. Programming and Scripts
MATLAB中最简单的程序形式为script, script以**.m**为拓展名, 其中可包含MATLAB命令和函数调用.

### 12.1 Create a script
```matlab
edit plotrand   % create a script named 'plotrand.m'
```

### 12.2 Run a script
在Editor中写入代码, 之后点击Run即可运行script
```matlab
n = 50;
r = rand(n, 1); % generate 50 random data ranging from 0 to 1
plot(r)

m = mean(r);    % get the mean of random data
hold on
plot([0,n], [m,m]) % draw a mean line from 0 t0 50
hold off
title('Mean of Random Uniform Data')
```
![subplots](/images/Others/matlab/sample-script.png)

### 12.3 Loops and Conditional Statements
使用for实现循环, 每一个for循环都需要end来结束循环
```matlab
nsamples = 5;
npoints = 50;

for k = 1: nsamples     % use loop to calculate the mean of random value
    iterationString = ['Iteration #', int2str(k)];
    disp(iterationString)
    currentData = rand(npoints, 1);
    sampleMean(k) = mean(currentData)   % diplay the result of each loop
end

overallMean = mean(sampleMean)
if overallMean < 0.49
    disp('Mean is less than expected')
elseif overallMean > 0.51
    disp('Mean is greater than expected')
else
    disp('Mean is within the expected range')
end
```
Output:
```matlab
Iteration #1
sampleMean =
    0.5156

Iteration #2
sampleMean =
    0.5156    0.5385

Iteration #3
sampleMean =
    0.5156    0.5385    0.4572

Iteration #4
sampleMean =
    0.5156    0.5385    0.4572    0.5364

Iteration #5
sampleMean =
    0.5156    0.5385    0.4572    0.5364    0.5096

overallMean =
    0.5114

Mean is greater than expected
```



## 13. Help and Documentation
1. Open the function documentation in a separate window
```matlab
doc mean
```

2. View an abbreviated text version of function documentation in the Command Window
```matlab
help mean
```



## 14. Matrices and Magic Squares
### 14.1 Sum, Transpose and Diag
1. sum: 求每一列的和
```matlab
>> A = magic(4)
A =
    16     2     3    13
     5    11    10     8
     9     7     6    12
     4    14    15     1

>> sum(A)       % compute the sum of each column
ans =
    34    34    34    34

>> sum(A, 2)    % compute the sum of each row
ans =
    34
    34
    34
    34
```

2. transpose: 共轭转置和非共轭转置
    1. conjugare transpose($'$)
    ```matlab
    A'
    ```
    2. nonconjugate transpose($.'$)
    ```matlab
    A.'
    ```

3. diag: 求矩阵对角线
```matlab
>> diag(A)
ans =
    16
    11
     6
     1
```

### 14.2 Generating Matrices
```matlab
>> Z = zeros(2,4)
Z =
     0     0     0     0
     0     0     0     0

>> F = 5 * ones(3,3)
F =
     5     5     5
     5     5     5
     5     5     5

>> N = fix(10*randn(4,4))   % fix(): round number to the nearest integer
N =
     4   -11     6   -13
     9     0     5   -12
   -17    -4    -6   -11
    -1   -16     5    -1
```



## 15. Expressions
### 15.1 Float
Float 精确度为 16 个十进制数值, 超过16位则进行截断. float的数值范围为 $[10^{-308} - 10^{+308}]$
```matlab
>> x = 12345678901234567;
>> y = 12345678901234568;
>> x == y
ans =
   1    % x == y 成立因为x和y都为 1.234567890123457e+16
```

### 15.2 Integer
Integer有不同的精度: 8bits, 32bits和64bits:
```matlab
>> x = uint64(12345678901234567);
>> y = uint64(12345678901234568);
>> x == y
ans =
   0
```

### 15.3. Complex number
Complex number大小的比较根据phase angle来决定:
```matlab
>> sort([3+4i, 4+3i])
ans =
   4.0000 + 3.0000i   3.0000 + 4.0000i

%{
because:
>> angle(3+4i)
ans =
    0.9273

>> angle(4+3i)
ans =
    0.6435
%}
```

### 15.4 Matrix Operators
Specifier   | Arithmetic Operator
:-----:|:-----:
\+          | Addition
\-          | Subtraction
\*          | Multiplication
/           | Division
\           | Left division
^           | Power
'           | Complex conjugate transpose
()          | Specify evaluation order

### 15.5 Array Operator
Specifier   | Array Operator
:-----:|:-----:
\+          | Addition
\-          | Subtraction
.*          | Element-by-element multiplication
./          | Element-by-element division
.\          | Element-by-element left division
.^          | Element-by-element power
.'          | Unconjugated array transpose

### 15.6 Building Tables
```matlab
>> n = (0:9)';
>> pows = [n, n.^2, 2.^n]
pows =
     0     0     1
     1     1     2
     2     4     4
     3     9     8
     4    16    16
     5    25    32
     6    36    64
     7    49   128
     8    64   256
     9    81   512
```

### 15.7 Functions
Several special functions privode values of constants

Function | Constant
:-----:|:-----:
pi      | 3.14159265...
i       | Imaginary unit, -1
j       | Same as i
eps     | Floating-point relative precision, $\xi = 2^{-52}$
realmin | Smallest floating-point number, $2^{-1023}$
realmax | Largest floating-point number, $(2-\xi)2^{1023}$
Inf     | Infinity
NaN     | Not-a-number



## 16 Special function
### 16.1 isfinite()
NaN一般用来表示丢失的数据, 可用isfinite(x)来移除这些数据. isfinite()还可用于移除Inf:
```matlab
>> x = [2.1 1.7 1.6 1.5 NaN 1.9 1.8 Inf];
>> x = x(isfinite(x))
x =
    2.1000    1.7000    1.6000    1.5000    1.9000    1.8000
```

### 16.2 std(), mean()
std()用于求standard deviation(标准方差), mean()用于求平均数
```matlab
>> x = [1 2 3 4 5 6 7 8 9 10]
>> std(x)
ans =
    3.0277

>> mean(x)
ans =
    5.5000
```

### 16.3 isprime()
isprime()用于判断质数
```matlab
>> X = magic(4);
>> X(isprime(X)) = 0    % find all prime number and set them to 0
X =
    16     0     0     0
     0     0    10     8
     9     0     6    12
     4    14    15     1
```

### 16.4 find()
find()根据条件返回一列索引的向量
```matlab
>> X = magic(4)
X =
    16     2     3    13
     5    11    10     8
     9     7     6    12
     4    14    15     1

>> primes = find(isprime(X))
primes =
     2      % row 2, col 1 - 5
     5      % row 1, col 2 - 2
     6      % row 2, col 2 - 11
     7      % row 3, col 2 - 7
     9      % row 1, col 3 - 3
    13      % row 1, col 4 - 13
```

