# Project A | VLSI Lab Outstanding Project | Advanced Hardware Accelerator for GBDT-Based Classification

Repository for Students Project (contains SystemVerilog modules and simulation objects), developed in the VLSI lab, Technion.

<img width="835" height="352" alt="image" src="https://github.com/user-attachments/assets/9d6d5376-0988-418e-bc8f-35462c305b6c" />

---

### **Authors**: Hadas Shifman, Shoham Marom

### **Supervisor**: Shahar Gino

---
### Project Description

This project presents the development of a hardware accelerator designed to solve classification problems, utilizing a ML
algorithm called Gradient Boosting Decision Trees (GBDT). This work addresses classification tasks - one of the most relevant
challenges and a key enabler for modern automation processes. The primary objective was to design and implement a
hardware IP core capable of accelerating GBDT performance, utilizing the APB protocol for integration with a processor
system. The development workflow encompassed architectural design and theoretical analysis, SV implementation and
functional verification , logic synthesis and physical layout. The results demonstrate correct functionality of the accelerator
and a high-speed performance.​

<img width="242" height="347" alt="image" src="https://github.com/user-attachments/assets/89502283-4fd9-45ef-9fed-bd782530775d" />

This repo embodies the implementation and verification phases.

---

### **Repository Contents**

This project repo contains:

* ```SystemVerilog``` modules source files (including our tb).
* Auxiliary files used for the project.
* ```Python``` notebook that demonstrates a proof of performance for our accelerator.

The repository is organized to support synthesis and verification of our implementation, and in addition to sv files it includes other objects such as: trees text file that we used in our verification, its documentation text file, and also a code notebook that contains a proof of performance (and can be run in Google Colab or VS Code). Detailed explanation about the verification process + results, and modules documentation is found inside our project report. 

---

### **Getting Started**

Verification requires a SystemVerilog-compatible simulator. we used ```Verdi``` app.

In order to run our simulation, one needs to activate the ```gbdt_tb.sv``` file - the test bench with all the tasks, including CPU and DMA's wires manipulating (that simulates the real classification process).

**Note**: for our simulation, please place the required tree input file (```tree_nodesT1_updated.txt```) into the directory that contains all source SV files. this file is inside this repo.

---

### **SV Files Modular Hierarchy**
> Location Hierarchy: all the files should be found in the same directory.

1. Accelerator Internal SV Modules Structure (*)
 
```text
gbdt_tb
  └── gbdt_top
        ├── gbdt_regfile(/_LABRAMS)
        │     ├── behavioral: ram_sp_sr_sw.sv
        │     └── real: spram32x4096_cb (**)
        └── gbdt_core
              ├── classification (x8)
              │     ├── leaves_acc
              │     ├── node_processing
              │     └── ram_communication
              ├── gbdt_control
              ├── input_features
              └── max_result
```
2. External/Auixiliary Files
```text
* gbdt_define.sv (macros)
* tree_nodesT1_updated.txt
* trees_gen_doc.txt
* Light_GBM_Python_Simulation.ipynb
```
(*) Full documentation regarding each and every module is found inside the project report, in the corresponding chapter.

(**) **Note**: this ram file is not in the repo, as it a copyrighted file of ```Tower Semiconductor```.

---

### **Base Article**

> FPGA Accelerator for Gradient Boosting Decision Trees

Link: https://www.mdpi.com/2079-9292/10/3/314
