# Project A | VLSI Lab Outstanding Project | Advanced Hardware Accelerator for GBDT-Based Classification

Repository for Students Project (contains SystemVerilog modules and simulation objects), developed in the VLSI lab, Technion.
<img width="636" height="637" alt="image" src="https://github.com/user-attachments/assets/27094c4c-62a5-4098-8a71-256589ebe1d8" />


**Authors**
Hadas Shifman, Shoham Marom

**Supervisor**
Shahar Gino

**Summary**
This project repo contains the SystemVerilog modules source files (including our tb), and auxiliary files used for the project. The repository is organized to support synthesis and verification of our implementation, and in addition to sv files it includes other objects such as: trees text file that we used in our verification, its documentation text file, and also a python notebook that demonstrates a proof of performance for our accelerator.

**Getting Started**
Verification requires a SystemVerilog-compatible simulator (we used Verdi).
In order to run our simulation, one needs to activate the gbdt_tb.sv file.

**Note**: for our simulation, please place the required tree input file (tree_nodesT1_updated.txt) into the directory that contains all source files.

**Base Article**
FPGA Accelerator for Gradient Boosting Decision Trees
link: https://www.mdpi.com/2079-9292/10/3/314
