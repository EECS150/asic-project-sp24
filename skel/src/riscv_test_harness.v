// Test harness for EECS151 RISC-V Processor
`include "const.vh"
`define INPUT_DELAY (`CLOCK_PERIOD / 5)

module rocketTestHarness;

  reg [31:0] seed;
  initial seed = $get_initial_random_seed();

  //-----------------------------------------------
  // Setup clocking and reset

  reg clk   = 0;
  reg reset = 1;
  reg r_reset;
  reg start = 0;

  always #(`CLOCK_PERIOD*0.5) clk = ~clk;

  wire mem_req_valid, mem_req_rw, mem_req_data_valid;
  wire [`MEM_TAG_BITS-1:0] mem_req_tag;
  wire [`MEM_ADDR_BITS-1:0] mem_req_addr;
  wire [`MEM_DATA_BITS-1:0] mem_req_data_bits;
  wire mem_req_ready, mem_req_data_ready, mem_resp_valid;
  wire #`INPUT_DELAY mem_req_ready_delay = mem_req_ready;
  wire #`INPUT_DELAY mem_req_data_ready_delay = mem_req_data_ready;
  wire #`INPUT_DELAY mem_resp_valid_delay = mem_resp_valid;
  wire [`MEM_TAG_BITS-1:0]  mem_resp_tag;
  wire [`MEM_TAG_BITS-1:0] #`INPUT_DELAY mem_resp_tag_delay = mem_resp_tag;
  wire [`MEM_DATA_BITS-1:0] mem_resp_data;
  wire [`MEM_DATA_BITS-1:0] #`INPUT_DELAY mem_resp_data_delay = mem_resp_data;
  wire [(`MEM_DATA_BITS/8)-1:0] mem_req_data_mask;
  wire [31:0] exit;

  //-----------------------------------------------
  // Instantiate the processor

  riscv_top dut
    (
      .clk(clk),
      .reset(r_reset),

      .mem_req_valid(mem_req_valid),
      .mem_req_ready(mem_req_ready_delay),
      .mem_req_rw(mem_req_rw),
      .mem_req_addr(mem_req_addr),
      .mem_req_tag(mem_req_tag),

      .mem_req_data_valid(mem_req_data_valid),
      .mem_req_data_ready(mem_req_data_ready_delay),
      .mem_req_data_bits(mem_req_data_bits),
      .mem_req_data_mask(mem_req_data_mask),

      .mem_resp_valid(mem_resp_valid_delay),
      .mem_resp_tag(mem_resp_tag_delay),
      .mem_resp_data(mem_resp_data_delay),
      .csr(exit)
    );

  
  //-----------------------------------------------
  // Memory interface

  always @(negedge clk)
  begin
    r_reset <= reset;
  end


  ExtMemModel mem
  (
    .clk(clk),
    .reset(r_reset),

    .mem_req_valid(mem_req_valid),
    .mem_req_ready(mem_req_ready),
    .mem_req_rw(mem_req_rw),
    .mem_req_addr(mem_req_addr),
    .mem_req_tag(mem_req_tag),

    .mem_req_data_valid(mem_req_data_valid),
    .mem_req_data_ready(mem_req_data_ready),
    .mem_req_data_bits(mem_req_data_bits),
    .mem_req_data_mask(mem_req_data_mask),

    .mem_resp_valid(mem_resp_valid),
    .mem_resp_data(mem_resp_data),
    .mem_resp_tag(mem_resp_tag)
  );


  // TODO: tohost/fromhost -> exit code (no longer through HTIF)

  //-----------------------------------------------
  // Start the simulation
  reg [  31:0] mem_width = `MEM_DATA_BITS;
  reg [  63:0] max_cycles = 0;
  reg [  63:0] trace_count = 0;
  reg [1023:0] loadmem = 0;
  reg [1023:0] vcdplusfile = 0;
  reg [1023:0] vcdfile = 0;
  reg          stats_active = 0;
  reg          stats_tracking = 0;
  reg          verbose = 0;
  integer      stderr = 32'h80000002;


  reg [31:0] clksel = 0;

  // Some helper functions for turning on, stopping, and finishing stat tracking
  task start_stats;
  begin
    if(!reset || !stats_active)
      begin
`ifdef DEBUG
      if(vcdplusfile)
      begin
        $vcdpluson(0);
        $vcdplusmemon(0);
      end
      if(vcdfile)
      begin
        $dumpon;
      end
`endif
      assign stats_tracking = 1;
    end
  end
  endtask
  task stop_stats;
  begin
`ifdef DEBUG
    $vcdplusoff; $dumpoff;
`endif
    assign stats_tracking = 0;
  end
  endtask
`ifdef DEBUG
`define VCDPLUSCLOSE $vcdplusclose; $dumpoff;
`else
`define VCDPLUSCLOSE
`endif

  // Read input arguments and initialize
  initial
  begin
    $value$plusargs("max-cycles=%d", max_cycles);
    $value$plusargs("loadmem=%s", loadmem);
    if (loadmem)
      `ifdef no_cache_mem
        #0.1 $readmemh(loadmem, dut.mem.icache.ram);
        #0.1 $readmemh(loadmem, dut.mem.dcache.ram);
      `else
        #0.1 $readmemh(loadmem, mem.ram);
       `endif
    verbose = $test$plusargs("verbose");
`ifdef DEBUG
    stats_active = $test$plusargs("stats");
    if ($value$plusargs("vcdplusfile=%s", vcdplusfile))
    begin
      $vcdplusfile(vcdplusfile);
    end
    if ($value$plusargs("vcdfile=%s", vcdfile))
    begin
      $dumpfile(vcdfile);
      $dumpvars(0, dut);
    end
    if (!stats_active)
    begin
      start_stats;
    end
    else
    begin
      if(vcdfile)
      begin
        $dumpoff;
      end
    end
`endif

    // Strobe reset
    #100 reset = 0;
  end


  reg [255:0] reason = 0;
  always @(posedge clk)
  begin
    //$fwrite(32'h80000002, "C%0d: csr: %d\n", trace_count, exit);
    //$fwrite(32'h80000002, "C%d: %d [%d] pc=[%h] W[r%d=%h][%d] R[r%d=%h] R[r%d=%h] inst=[%h] DASM(%h)\n", T135, T133, T132, T130, T128, T127, T126, T124, T97, T95, T9, T8, T1);

    if (reset == 0) begin
      #0.1;
      //$fwrite(32'h80000002, "C%0d: PC=%h W[r%d=%h] WE=%d DASM(%h)\n",trace_count,dut.cpu.dpath.pc_m,dut.cpu.dpath.wb_reg_m,dut.cpu.dpath.wb_value,dut.cpu.dpath.wb_reg_we,dut.cpu.dpath.inst_m);
      `ifndef GATELEVEL
      $fwrite(32'h80000002, "C%0d: \n", trace_count);
      `endif
      
      //$fwrite(32'h80000002, "C%0d: INST=%h PC_x=%h A=%h B=%h ALUout=%h\n",trace_count,dut.cpu.dpath.inst_x , dut.cpu.dpath.pc_x,dut.cpu.dpath.alu_a_input_x, dut.cpu.dpath.alu_b_input_x, dut.cpu.dpath.alu_out_x);
    end 

    if (max_cycles > 0 && trace_count > max_cycles) begin
      reason = "timeout";
    end
    if (exit > 1 && trace_count > 1)
      $sformat(reason, "tohost = %d", exit);

    if (reason)
    begin
      $fdisplay(stderr, "*** FAILED *** (%0s) after %0d simulation cycles", reason, trace_count);
      `VCDPLUSCLOSE
      $finish;
    end

    if (exit == 1)
    begin
      $fdisplay(stderr, "*** PASSED *** (%0s) after %0d simulation cycles", reason, trace_count);
      `VCDPLUSCLOSE
      $finish;
    end
  end

  //-----------------------------------------------
  // Tracing code

  always @(posedge clk)
  begin
    if(stats_active)
    begin
      if(!stats_tracking)
      begin
        start_stats;
      end
      if(stats_tracking)
      begin
        stop_stats;
      end
    end
  end

  always @(posedge clk)
  begin
    if (verbose && mem_req_valid && mem_req_ready)
    begin
      $fdisplay(stderr, "MB: rw=%d addr=%x", mem_req_rw, {mem_req_addr,4'd0});
    end
  end

  always @(posedge clk)
  begin
    trace_count = trace_count + 1;
`ifdef GATE_LEVEL
    if (verbose)
    begin
      $fdisplay(stderr, "C: %10d", trace_count-1);
    end
`endif
  end

endmodule
