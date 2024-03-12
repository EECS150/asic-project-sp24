# EECS 151/251A ASIC Project: RISC-V Processor Design

- Once you get the code, change <YOUR_LAB_ROOT_DIR> in the sim-*.yml files
to the path to your working directory

- Don't forget to clean up build/ folder in previous lab directories

- When you create new Verilog files, add them to the *.yml files

- Don't add SRAM behavioral models to syn.yml! The file is intended for simulation only,
not synthesis.

=== Run Simulation (sim-rtl)  ================================================

+ Set the name of the testbench you want to test in sim-rtl.yml, then run
make sim-rtl

+ When you test rocketTestHarness (riscv_test_harness.v), do "make" in tests/asm
and tests/bmark to generate the hex files for simulation

+ If you want to test the ASM test suite, run
make sim-rtl test_asm=all

+ If you want to test a single ASM test, run
make sim-rtl test_asm=add.out

or, to generate VPD file:
make sim-rtl test_asm=add.vpd

+ If you want to test the bmark test suite (C code -- intensive benchmarks), run
make sim-rtl test_bmark=all

+ If you want to run a single benchmark test,
make sim-rtl test_bmark=cachetest.out

+ If you want to run a shorter version of bmark test
make sim-rtl test_bmark_short=all

+ Or
make sim-rtl test_bmark_short=cachetest.out

=== Run Synthesis & PnR ======================================================

+ Set the target clock frequency in syn.yml

+ Include all the necessary Verilog source files to syn.yml

+ Set the placement constraints in par.yml. You'll likely need to change them
according to the SRAM configuration in your design

+ To run Synthesis, do
make syn

+ To run PnR, do
make par

- By default, if you do "make par", if will invoke Synthesis if not yet run. When you change
the target clock frequency (syn.yml), "make par" will rerun the Synthesis. When you change
the placement constraints (par.yml), "make par" will only run P&R.

- However, when you change the Verilog source files, you need to *rerun* the Synthesis, and P&R:
"make syn", followed by "make par" (or "make clean", then "make par")

- PAR usually takes a long time to complete. To make sure that your PAR result sane, when it is done,
open build/par-rundir/innovus.log, search for "opt_design Final SI Timing Summary", if the
summary table indicates no setup/hold time violation and no DRV, your design is good to go!

- Also search for the last "DRC violations" in the log file. Make sure you have no DRC violation.

- If you want to see the floorplan of your chip, do
cd build/par-rundir/generated_scripts
./generated_scripts/open_chip

to launch Innovus with the chip database

- Remove the layer obstruction (M8, V8, M9, V9) to have a clear view of the floorplan. You don't have
to wait until the whole PAR process finish to launch this. You can let the tool running and open
the floorplan for inspection. Floorplanning is done very early. You should check the floorplan
result to see if it meets your requirement.

- If you don't want to set placement constraints for your design, you can uncomment the line at the bottom
of par.yml to let the tool perform automatic floorplan exploration. However, this might lead to sub-optimal
results. Nonetheless, you can use this option to aid you at the beginning when you are unsure where to
place your SRAM hard macros (and the size of the chip). Take note the dimensions of the hard macros, since
you will need to do manual floorrplaning.

- A seemingly good practice of placing SRAMs is that the SRAMs are placed on the sides, and the standard
cells are placed in the middle (butterfly).

- The tool can do a lot for you. If you're done with PAR, and your design slightly violates some paths
in a very small margin, you can ask the tool to do more optimization (instead of modifying your source
or placement constraints)

+ cd build/par-rundir
+ innovus -common_ui                   # to launch Innovus shell

Type the following commands in your terminal (under Innovus shell)
+ read_db latest                       # load the final checkpoint of the previous run
+ opt_design -post_route -setup -hold  # invoke GigaOpt engine to optimize your design

if your design only have hold time violation, run this instead

+ opt_design -post_route -hold

if you are so lucky that all the violations are fixed, the next step is to generate new
SDF file for gate-level simulation

+ write_netlist riscv_top.sim.v        # to generate new Verilog netlist file for gate-level simulation
+ write_sdf riscv_top.par.sdf          # to generate new timing-annotated SDF file for gate-level simulation

(you can also run all the commands after "opt_design -post_route -setup -hold"
in build/par-rundir/par.tcl to generate other files, such as GDS layout)

- When done, check out the updated timing summary reports under build/par-rundir/timingReports/*

=== Run Gate-level Simulation (sim-gl-syn/par)  ==============================

- To run Post Synthesis gate-level simulation (no timing annotated, no clock tree), do

make sim-gl-syn test_asm=all
make sim-gl-syn test_bmark=all

This simulation uses the generated netlist from Synthesis: build/syn-rundir/riscv_top.mapped.v
instead of your original source files.

- To run Post PAR gate-level simulation (timing annotated), do

make sim-gl-par test_asm=all
make sim-gl-par test_bmark=all

This simulation uses the generated netlist from Synthesis: build/par-rundir/riscv_top.sim.v
instead of your original source files.

- You should change the simulation clock value in sim-gl-syn.yml and sim-gl-par.yml to the same clock
value in syn.yml

- sim-gl-par is a time-consuming process, especially when testing with bmark. Some might took half a day
to finish. You can track the current progress of the simulation by peeking at the simulation output file
under bmark_output/. Nonetheless, you can test with shorter bmark version (should take less than 15 minutes
to finish all of them). You are only required to pass the short bmark tests for the final checkoff.

- During gate-level simulation, if you see warnings related to setuphold, it might be that your design still
have setup/hold time violation. You need to fix all the violations (by changing your source files, or the placement
constraints, or target clock frequency) before running gate-level simulation.

- Again, when you make change to your Verilog code, be sure to run "make syn", and then "make par" to
get the latest Verilog netlist for gate-level simulation.

