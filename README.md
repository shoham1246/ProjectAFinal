# Project A | VLSI Lab Outstanding Project | Advanced Hardware Accelerator for GBDT-Based Classification

Repository for Students Project (contains SystemVerilog modules and simulation objects), developed in the VLSI lab, Technion.

<img width="835" height="352" alt="image" src="https://github.com/user-attachments/assets/9d6d5376-0988-418e-bc8f-35462c305b6c" />

---

### **Authors**: Hadas Shifman, Shoham Marom

### **Supervisor**: Shahar Gino

---

### **Summary**

This project repo contains:

* ```SystemVerilog``` modules source files (including our tb).
* Auxiliary files used for the project.
* ```Python``` notebook that demonstrates a proof of performance for our accelerator.

The repository is organized to support synthesis and verification of our implementation, and in addition to sv files it includes other objects such as: trees text file that we used in our verification, its documentation text file, and also a notebook contains a proof of performance. Detailed explanation about the verification process and modules documentation is found inside our project report. 

---

### **Getting Started**

Verification requires a SystemVerilog-compatible simulator. we used ```Verdi``` app.

In order to run our simulation, one needs to activate the ```gbdt_tb.sv``` file - the test bench with all the tasks, including CPU and DMA's wires manipulating (that simulates the real classification process).

**Note**: for our simulation, please place the required tree input file (```tree_nodesT1_updated.txt```) into the directory that contains all source SV files.

---

### **SV Files Modular Hierarchy**

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
