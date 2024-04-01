/* Standard include file for EECS151.

 The "no flip-flop inference" policy.  Instead of using flip-flop and
 register inference, all EECS151/251A Verilog specifications will use
 explicit instantiation of register modules (defined below).  This
 policy will apply to lecture, discussion, lab, project, and problem
 sets.  This way of specification matches our RTL model of circuit,
 i.e., all specifications are nothing but a set of interconnected
 combinational logic blocks and state elements.  The goal is to
 simplify the use of Verilog and avoid mistakes that arise from
 specifying sequential logic.  Also, we can eliminate the explicit use
 of the non-blocking assignment "<=", and the associated confusion
 about blocking versus non-blocking.

 Here is a draft set of standard registers for EECS151.  All are
 positive edge triggered.  R and CE represent synchronous reset and
 clock enable, respectively. Both are active high.

 REGISTER 
 REGISTER_CE
 REGISTER_R
 REGISTER_R_CE
*/

// Register of D-Type Flip-flops
module REGISTER(q, d, clk);
   parameter N = 1;
   output reg [N-1:0] q;
   input [N-1:0]      d;
   input         clk;
   always @(posedge clk)
	q <= d;
endmodule // REGISTER

// Register with clock enable
module REGISTER_CE(q, d, ce, clk);
   parameter N = 1;
   output reg [N-1:0] q;
   input [N-1:0]      d;
   input          ce, clk;
   always @(posedge clk)
	 if (ce) q <= d;
endmodule // REGISTER_CE

// Register with reset value
module REGISTER_R(q, d, rst, clk);
   parameter N = 1;
   parameter INIT = {N{1'b0}};
   output reg [N-1:0] q;
   input [N-1:0]      d;
   input          rst, clk;
   always @(posedge clk)
	 if (rst) q <= INIT;
	 else q <= d;
endmodule // REGISTER_R

// Register with reset and clock enable
//  Reset works independently of clock enable
module REGISTER_R_CE(q, d, rst, ce, clk);
   parameter N = 1;
   parameter INIT = {N{1'b0}};
   output reg [N-1:0] q;
   input [N-1:0]      d;
   input          rst, ce, clk;
   always @(posedge clk)
	 if (rst) q <= INIT;
	 else if (ce) q <= d;
endmodule // REGISTER_R_CE


/* 
 Memory Blocks.  These will simulate correctly and synthesize
 correctly to memory resources in the FPGA flow.  Eventually, will
 need to make an ASIC version.
*/

// Single-ported RAM with asynchronous read
module RAM(q, d, addr, we, clk);
   parameter DWIDTH = 8;               // Data width
   parameter AWIDTH = 8;               // Address width
   parameter DEPTH = 256;              // Memory depth
   input [DWIDTH-1:0] d;               // Data input
   input [AWIDTH-1:0] addr;            // Address input
   input          we, clk;
   reg [DWIDTH-1:0]   mem [DEPTH-1:0];
   output [DWIDTH-1:0] q;
   always @(posedge clk)
	  if (we) mem[addr] <= d;
   assign q = mem[addr];
endmodule // RAM

/*
   A asynchronous 2 reads, 1 write port RAM. Intended to be
   used for register file, but can have other uses
*/
module ASYNC_2R1WRAM_JWSTYLE
  #(  parameter DEPTH = 128,
	  parameter WIDTH = 32) (
	input wire clk,
	input wire rst, 
	input wire we,
	// Read port 1
	input [$clog2(DEPTH)-1:0] raddr0,
	output [WIDTH-1:0] rdata0,
	// Read port 2
	input [$clog2(DEPTH)-1:0] raddr1,
	output [WIDTH-1:0] rdata1,
	// Write port 1
	input [$clog2(DEPTH)-1:0] waddr0,
	input [WIDTH-1:0] wdata
  );

	genvar i;    // Generate variable
	reg [WIDTH-1:0] reg_d [DEPTH-1:0]; // Register din
	reg [WIDTH-1:0] reg_q [DEPTH-1:0]; // Register dout

	// Register file
	generate
		for (i = 0; i < DEPTH; i++) begin
			REGISTER #(.N(WIDTH)) reg_x (.clk(clk), .d(reg_d[i]), .q(reg_q[i]));

			// Write
			always @(posedge clk) begin 
				if (rst == 1'b1) begin
					reg_d[i] <= {WIDTH{1'b0}};
				end else begin
					if ((we == 1'b1) && (i == waddr0)) begin
					  reg_d[waddr0] <= wdata;
					end
				end
			end
		end
	endgenerate


  // Read
  assign rdata0 = reg_q[raddr0];
  assign rdata1 = reg_q[raddr1];

endmodule : ASYNC_2R1WRAM_JWSTYLE
/*
 To add: multiple ports, synchronous read, ASIC synthesis support.
 */
