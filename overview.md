# EECS 151/251A ASIC Project Specification RISC-V Processor Design: Overview
<p align="center">
Prof. John Wawrzynek
</p>
<p align="center">
TA: Kevin He, Kevin Anderson
</p>
<p align="center">
Department of Electrical Engineering and Computer Science
</p>
<p align="center">
College of Engineering, University of California, Berkeley
</p>

## 1. Introduction

For this project, you will design a simple 3-stage CPU that implements the RISC-V ISA. If you work in a team, all team members must have a complete understanding of the entire project code.

Your first and most important goal is to write a functional implementation of your processor. Once your processor is working, you should try to improve its performance.

We will provide with some testbenches to help you verify your design, but you will be responsible for creating additional testbenches to exercise your entire design. Your target implementation technology will be Skywater 130nm. The project will give you experience designing synthesizeable RTL, resolving hazards in a simple pipeline, building interfaces, and approaching system-level optimization.



### 1.1 RISC-V
You can skim the official [RISC-V Instruction Set Manual](https://riscv.org/technical/specifications/) (Volume 1, Unprivileged Spec) and explore [http://riscv.org](http://riscv.org) for more information on RISC-V.
- Read sections 2.2 and 2.3 to understand how the different types of instructions are encoded. 
- Read sections 2.4, 2.5, 2.6, and 9.1 and think about how each of the instructions will use the ALU

### 1.2 Project phases
Your project will consist of two different phases: front-end and back-end. Within each phase, you will have multiple checkpoints that will ensure you are making consistent progress. These checkpoints will contribute (although not significantly) to your final grade. You are free to make design changes after they have been checked off.

We highly recommend starting the checkpoints early so that you have time to debug and improve your design.

In the first phase (front-end), you will design and implement a 3-stage RISC-V processor in Verilog, and run simulations to test for functionality.

In the second phase (back-end), you will implement your front-end design in the SKY130 PDK using the VLSI tools you used in lab. When you have finished phase 2, you will have a design that could move onto fabrication if you wanted to manufacture your design.


### 1.3 General Project Tips
Be sure to use top-down design methodologies in this project. We began by taking the problem of designing a basic computer system, modularizing it into distinct parts, and then refining those parts into manageable checkpoints. You should take this scheme one step further; we have given you each checkpoint, so break each into smaller, manageable pieces.

As with many engineering disciplines, digital design has a normal development cycle. In the norm, after modularizing your design, your strategy should roughly resemble the following steps:

- **Design** your modules well, make sure you understand what you want before you begin to code.

- **Code** exactly what you designed; do not try to add features without redesigning.

- **Simulate** thoroughly; writing a good testbench is as much a part of creating a module as actually coding it.
- **Debug** completely; anything which can go wrong with your implementation will.

Some general tips when designing complex RTL modules:

* Document your project thoroughly as you go
  * comment your Verilog
  * before making any RTL changes, **modify your pipeline diagram first to visualize this change**, doing this:
    * may reveal the change is actually infeasible
    * ensures that you and your partner have the same view of your processor's operation
* Split the module operation into data/control paths and design each separately
  * Start with the simplest possible implementation
  * Make changes incrementally and always test your module after each change, no matter how small
  * Finish the required features first before attempting any extra features
* Use github version control features like commits, branches, etc.
* Save your work often and rely on redundancy (e.g. copy files from `/scratch` to your home directory often to ensure they're backed up)
* Parallelize work as much as possible (e.g. start writing CPU RTL as you finish your diagram, work on CPU and Cache in parallel, start physical design as you finish your cache)


**Commit and push your code often. The instructional machines sometimes crash. We are not responsible for lost work.**

The most important goal is to design a functional processor and you must have it **working completely** to receive any credit for performance optimizations.

---

## 2. Front-end design (Phase 1)

The first phase in this project is designed to guide the development of a three-stage pipelined RISC-V CPU that will be used as a base system for your back-end implementation.
Phase 1 will last for 6 weeks and has weekly checkpoints.

- Checkpoint 1: ALU design and pipeline diagram (1 week)
- Checkpoint 2: Core implementation (2 weeks)
- Checkpoint 3: Core + memory system implementation (2 weeks) 
- Checkpoint 4: Physical Design (1 week)

**You must check off each checkpoint with your lab TA to receive credit.
The checkoffs must be completed in order.**
For example, you cannot get checked off for checkpoint 3 until you get checked
off for checkpoint 2.

To start, create a team on [GitHub classroom](https://classroom.github.com/a/v4DM_v4Z), and add your teammates.
Then clone your GitHub classroom repository.
  ```shell
  cd /home/tmp/<your-eecs-username>
  git clone git@github.com:EECS151-sp24/asic-project-(GitHub username).git
  cd asic-project-<GitHub username>
  ```
### 2.2 Project Git Repo

Add the staff skeleton as a remote:
  ```shell
  git remote add skeleton https://github.com/EECS150/asic-project-sp24.git
  ```
Pull the project from the staff skeleton:
```shell
git pull skeleton main
```

To pull changes from your team repository you would run:
```shell
git pull origin main
```

To push changes to your team repository
(please do not attempt to push to the skeleton repository),
you would usually want to pull first (above) and then run:
```shell
git push origin main
```
Setup CAD tools environment:
```
source /home/ff/eecs151/asic/eecs151.bashrc
```
---

## 3. Grading

### EECS 151:
|                   |           |
|-------------------|---------|
|  **70%**          |   Functionality at project due date: Your design will be subjected to a comprehensive test suite and    your score will reflect how many of the tests your implementation passes.
|  **25%**          |   Final Report and Final Interview: If your design is not 100% functional, this is your opportunity  explain your bugs and recoup points.
|  **5%**           |   Checkpoints: Each check-off is worth 1.25%. If you accomplished all of your checkpoints on time, you will receive full credit in this category.

### EECS 251A:
|                 |           |
|-----------------|---------|
|   **60%**       |  Functionality at project due date: Your design will be subjected to a comprehensive test suite and your score will reflect how many of the tests your implementation passes.
|   **10%**       |  Set-Associative Cache: Implementation and performance of the configurable set-associative cache.
|   **25%**       |  Final Report and Final Interview: If your design is not 100% functional, this is your opportunity explain your bugs and recoup points.
|   **5%**        |  Checkpoints: Each check-off is worth 1.25%. If you accomplished all of your checkpoints on time, you will receive full credit in this category.

At our discretion, we may grant extra credit to projects demonstrating exceptional performance and/or creativity.
To receive any extra credit, your design must be fully functional.

## Acknowledgement

This project is the result of the work of many EECS151/251 GSIs over the years including:
Written By:
- Nathan Narevsky (2014, 2017)
- Brian Zimmer (2014)
Modified By:
- John Wright (2015,2016)
- Ali Moin (2018)
- Arya Reais-Parsi (2019)
- Cem Yalcin (2019)
- Tan Nguyen (2020)
- Harrison Liew (2020)
- Sean Huang (2021)
- Daniel Grubb, Nayiri Krzysztofowicz, Zhaokai Liu (2021)
- Dima Nikiforov (2022)
- Chengyi Zhang (2023)
- Hyeong-Seok Oh, Ken Ho, Rahul Kumar, Rohan Kumar, Chengyi Lux Zhang (2023)
- Kevin Anderson, Kevin He