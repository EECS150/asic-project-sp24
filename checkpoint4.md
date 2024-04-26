# EECS 151/251A ASIC Project Specification: Checkpoint 4
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

---

## Checkpoint 4: Synthesis and PAR

### Running synthesis and PAR

The setup for synthesis and PAR is the similar to what we have used in the labs during the class,
with some formatting differences.  In `par.yml`, there is extra guidance 
for how to do placement constraints. Based on how you implemented the caches from the previous
checkpoint, you will need to modify these constraints to match the path to the SRAMs you used. Now you should be ready to proceed to Synthesis and PAR by running the following:

```
make clean
make srams
make syn
make par
```

If everything went smoothly, you should now have a circuit laid out. To view the layout, go to
`build/par-rundir/` directory and type

```
./generated_scripts/open_chip
```

You are expected to record your cycle count for all of the assembly and benchmark tests as well as your clock frequency performance (as
determined by your post-PAR critical path). Your final design must meet setup time constraints. PAR and benchmark simulations will take a long time to run on the `eda` servers. The lab machines `c111-[1-20]` will likely be much faster.

If you need to change the clock frequency, you should do so in `syn.yml`.
There is a new constraint added to `syn.yml` under the key `vlsi.inputs.delays`. 
The external memory model in `riscv_test_harness.v` generates a delayed version of the signals
going into your CPU (see the parameter `INPUT_DELAY`). Annotating these delays for synthesis/PR 
is necessary in order capture this effect when the tools perform timing analysis. If you are
curious, this gets translated into `build/syn-rundir/pin_constraints_fragment.sdc`
as input to synthesis. After synthesis, the relevant pin delays are encoded in
`build/syn-rundir/riscv_top.mapped.sdc`. These are Synopsys Design Constraint
format files. Do not touch this delay constraint except to update the value as your clock period
divided by 5.

### Floorplanning

You will notice that Innovus will either fail or place SRAMs in strange ways if you do not 
specify manual placement constraints in `par.yml`. Poor floorplanning may cause DRC and routing errors
as well as significantly increase your critical path.

You will need to modify `par.yml` to place your SRAMs in sensible locations. We will check that your
layout in Innovus looks reasonable and does not have an excessive amount of DRC errors (which will
show up as white X's when you run `./generated_scripts/open_chip`).

The provided SRAMs are intended to be rotated 90 degrees such that their power straps and pins line up
with the routing direction conventions for SKY130. As such, your placement constraints should use
one of the following orientation:

- "r90"  (rotated 90 degrees clockwise)
- "r270" (rotated 270 degrees clockwise; equivalent to 90 degrees counterclockwise)
- "mx90" (mirrored about the x-axis, then rotated 90 degrees clockwise)
- "my90" (mirrored about the y-axis, then rotated 90 degrees clockwise)

Things to consider:
- Where are the pins of each SRAM? Without any rotation, they are placed at the bottom of the SRAM.
- Is there enough space to route the necessary signals to the SRAMs and pins of the chip at the bottom?
- Is there enough space between the SRAMS to place the digital logic?
- How far away are the SRAMs from the digital logic they interact with?

### (Optional) Post-Syn and Post-PAR simulation

You can optionally verify your design works after synthesis and PAR, use the following commands:

```
make sim-gl-syn test_asm=all
make sim-gl-par test_asm=all
```
Only RTL simulation will be required for full credit on the project.

Since there are a couple timing issues that still need to be ironed out in the SKY130 PDK, it is acceptable for your design to pass RTL simulation but fail post-PAR simulation. Feel free to try to get post-PAR simulation to work, potentially by fixing your logic or increasing the post-PAR simulation clock period.

If you would like to debug post-PAR simulation, you may also want to make sure that the post-synthesis netlist passes tests before moving onto post-PAR simulation, because the latter can be slower and will complicate your debugging with any PAR-related failures you may have (e.g. incomplete wiring of signal or clock nets
due to a bad floorplan).
Some of the SRAM22 SRAMs do not have complete timing information.
This is most apparent in gate-level simulations because the SRAMs do not provide any SDF
timing annotation. You may find that despite meeting timing in synthesis and PAR, you will
likely need to increase the gate-level simulation clock period for the benchmarks to pass.

### Deliverables

Please answer the following questions to be checked off by a TA.
1. Show your layout in Innovus, and explain your design considerations when creating the floorplan.
2. Show your recorded cycle counts and explain how you arrived at your highest post-PAR clock frequency.
3. Show your post-PAR timing reports that demonstrate that setup time constraints are met.
2. Show your final pipeline diagram, updated to match the code.
3. (Optional) Show that all of the assembly tests and final pass using the cache in a post-par simulation.

---

### Beyond Checkpoint 4: CPU Optimization

Everything in this section is optional, though there will be extra credit given for exceptional teams. Performance will be rated on the `sum.c` benchmark based off of cycle count, post-PAR clock period, and area of the `cpu` (not including `mem`) as reported by the `report_area` command on Innovus using this equation:

$$
Score = {ClockPeriod * Cycles }*{Area^{\frac{1}{2}}}
$$

Use um^2 for Area (the unit for score will be $s\cdot{um}$). For example, a design that has a clock period of 20ns that takes 50,000,000 cycles to complete sum and has a cpu area of 50,000um^2 will have a score of 

$$
Score = {{20 \times 10^{-9} * 50\times10^6 }} * {{({50000})^{\frac{1}{2}}}} = {224} {s\cdot{um}}
$$

Note that area is weighted less than performance. Lower scores are better.
#### Optimizing for frequency

Part of optimizing execution time is minimizing your critical path and
allowing your processor to run at a higher frequency. The critical path will
be dependent on how aggressively you ask the tools to optimize the design, by changing the target clock
period in the `syn.yml` file.

When Innovus is finished, look at the timing report for the critical path. In some cases, it is possible
to modify your Verilog to improve the critical path by moving pipeline stage registers. However in other
cases, timing can only be improved by tweaking settings in `syn.yml` and `par.yml`.

Be sure to backup (meaning check in or branch) your working design before attempting to move
logic, because functionality is worth much more of your grade than maximum frequency.

You are allowed to add additional pipeline stages, but remember that you will need to deal with the additional hazards that accompany them.
Be careful that adding additional stages does not increase the overall execution time.
Your final performance metric is not only based on the clock speed at which your design will run, so keep
that in mind before heavily modifying your design.

Note for the competition: the maximum frequency
you achieved in PAR is most accurate and should be what you report for
frequency.

#### Optimizing for number of cycles
We are providing you tests that are the output of example C programs to run for your processor. They
are meant to be a representative example of different types of programs that each have different reasons
why they may take extra cycles to execute, for a variety of reasons including, but not limited to cache
misses, and branch/jump stalls. A more complicated cache structure may be able to reduce some of the
time spent waiting for memory accesses, but it may not be optimal for all cases. If you implement a
configurable cache you are allowed to set the cache settings differently on a per test basis, you will need
to add those pins to the top level Riscv151 file as well as the testbench with compile flags for VCS. In
terms of dealing with branching and jumping, you can implement any type of branch predictor that you
want to. A branch predictor in its simplest form will always choose to take (or not take) the branch and
then figure out if it was incorrect, and if so go back to where the instruction memory should have gone,
making sure that any additional instructions that were started do not change the state of the CPU. This
means that there should be no writes to memory or any registers for those instructions.

The list of final tests are contained within the Makefile under the variable `bmark_tests`, which
include a few tests that are meant to actually test the performance of your design. These tests are longer
C programs that are meant to test different aspects of your design and how you handle different types
of hazards. To run these longer tests you can run the following commands, like in checkpoint #3:
```
make sim-rtl test_bmark=all
```
You may need to increase the number of cycles for timeout for some of the longer tests (like sum,
replace and cachetest) to pass.
