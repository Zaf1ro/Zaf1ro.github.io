---
title: CS521-homework9
category:
  - Homework
tag:
  - Homework
abbrlink: 484075785
date: 2017-11-16 10:58:08
---

1. What's the subnet address if the destination address is "19.30.80.5" and the subnet mask is "255.255.90.0"
Subnet address: 19.30.80.5 & 255.255.90.0 = 19.30.80.0


2. If there needs 1000 subnets, please design the subnets for IP address is "181.56.0.0"
181.56.0.0 is a Class B network, and it needs 1000 subnets. We can divide it into 1024 subnets, and the subnet mask is 255.255.255.192 -> 181.56.0.0/26


3. Stevens given a block wait beginning address and prefix length 205.16.37.24/29. What is the range of block? How many address in the block
Subnet mask is 29, equals to 255.255.255.248. So the subnet should be 205.16.37.24 & 255.255.255.248 = 205.16.37.24. The range of block should be: 205.16.37.25-205.16.37.31(not including subnet address 205.16.37.24 and broadcast address 205.16.37.32). The number of addresses in this subnet is 2^3-2=6(not including subnet address and broadcast address)


4. Stevens given a block address 130.34.12.64/26 needs four subnets. What are the subnets addresses and the range of addresses for each subnets?
The subnet address of this block address is 130.34.12.64 & 255.255.255.192 = 130.34.12.64. If it is divided into four subnets. The subnet mask should be 255.255.255.112. And the range of address should be 130.34.12.65-130.34.12.78,
130.34.12.81-130.34.12.94,
130.34.12.97-130.34.12.110,
130.34.12.113-130.34.12.126
(all not include subnet address and broadcast address)
