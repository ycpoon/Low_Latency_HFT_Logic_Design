# Low_Latency_HFT_Logic_Design

This project is not meant to introduce any revolutionary HFT FPGA algorithm, but rather as a project to get myself to learn about the application of FPGA in HFT settings. 
Many of the implementations are naively done to abstract from the complicated logic behind actual HFT designs.

At the current stage, there are two things implemented:


### Message Decoder and Parser

This module will receive the message from the Ethernet stack using AXI Stream interface.
The module is a N-way superscalar parser FSM that receives the message from the Ethernet stack using AXI Stream interface,
decodes messages based on Nasdaq ITCH protocol and parses into the Order Book.


### Binary Tree Order Book


The idea of this order book design is to reflect the best price as low latency as possible after it receives market data, so that the trading logic can operate on the best price information.
To do that, a binary tree based order book algorithm is implemented to binary search for best price from the order array, so that a latency of O(log2, N) is achieved. This process is done
combinationally even before the orders are updated in the order book memory BRAM to skip the memory latencies. This Order Book implementation allows fast best price retrieval while having orders
updated to the memory in the background.


### What is Next?

My next step is to implement out the trading logic based on some research out there as well as the order generation module from the trading logic. With time, I hope to implement my own Ethernet stack in and out
myself as well, rather than using Xilinx's Ethernet stack frame (which is what I am currently doing).

### Note

This Github repo is copied from my Vivado workspace for project display, hence, some files might be missing (ie. Ethernet stack), and it is only synthesizable with Xilinx FPGA. Currently, I am also working to make this logic synthesizable with Cadence Synopsys as well. 