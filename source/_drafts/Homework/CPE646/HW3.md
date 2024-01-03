---
title: HW3
category:
  - Homework
tag:
  - Homework
abbrlink: 3420631023
date: 2018-04-07 13:48:55
---

#### 1. Problem 1
All we have is 100 samples from hw3_1. We assume that 50 of that comes from GMM1, and the other 50 samples comes from GMM2. So we got first 50 samples as GMM1, and calculate the $\mu\_1$ and $\sum\_1{}$
```matlab
>> len = size(hw3_1, 2) / 2;
>> gmm1 = hw3_1(:, 1:len);
>> gmm2 = hw3_1(:, len+1:100);
>> mean1 = mean(gmm1, 2)

mean1 =
    0.5656
   -0.6224

>> mean2 = mean(gmm2, 2)

mean2 =
    1.9066
   -1.4085

>> variance2 = zeros(2,2);
>> variance1 = zeros(2,2);
>> for i = 1:len
variance1 = variance1 + (gmm1(:,i)-mean1).^2;
variance2 = variance2 + (gmm2(:,i)-mean2).^2;
end
>> variance1 = variance1 / len

variance1 =
    3.3784    3.3784
    2.2895    2.2895

>> variance2 = variance2 / len

variance2 =
    6.3584    6.3584
    7.3799    7.3799
```
So we has a model parameters. In the next step, we have to calculate the conditional expectation by the current estimate of model parameters.
```matlab
function [R, llh] =
``` expectation(X, model)
    


end
main function:
```matlab
data = hw3_1;
len = size(x, 2);
tol = 1e-6;
maxiter = 6;
llh = -inf(1, maxiter); % loglikelihood
model.mu = [mean1, mean2];
model.Sigma(:,:,1) = variance1;
model.Sigma(:,:,2) = variance2;
model.w = [0.5, 0.5];

for iter = 2:maxiter
    % E-step
    nextData = expectation(Data, Param);
    
    % M-step
    nextParam = maximization(nextData, Param);
    
    % calculate the distance/error from the previous set of params
    shift = calc_distance(Param, nextParam);

    Data = nextData;
    Param = nextParam;
end
```