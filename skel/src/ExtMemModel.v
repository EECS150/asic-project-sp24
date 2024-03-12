`include "util.vh"
`include "const.vh"

module ExtMemModel
(
  input         clk,
  input         reset,

  // Read/Write Address request from CPU
  input                      mem_req_valid,
  output                     mem_req_ready,
  input                      mem_req_rw, // HIGH: Write, LOW: Read
  input [`MEM_ADDR_BITS-1:0] mem_req_addr,
  input [`MEM_TAG_BITS-1:0]  mem_req_tag,

  // Write data request from CPU
  input                          mem_req_data_valid,
  output                         mem_req_data_ready,
  input [`MEM_DATA_BITS-1:0]     mem_req_data_bits,
  input [(`MEM_DATA_BITS/8)-1:0] mem_req_data_mask,

  // Read data response to CPU
  output reg                      mem_resp_valid,
  output reg [`MEM_DATA_BITS-1:0] mem_resp_data,
  output reg [`MEM_TAG_BITS-1:0]  mem_resp_tag
);

  // Memory read takes 4 consecutive cycles of 128-bit each
  localparam DATA_CYCLES = 4;
  localparam DEPTH = 2*1024*1024; // 2*1024*1024 entries of 128-bit (2M x 16B)

  reg [`ceilLog2(DATA_CYCLES)-1:0] cnt;
  reg [`MEM_TAG_BITS-1:0] tag;
  reg state_busy, state_rw;
  reg [`MEM_ADDR_BITS-1:0] addr;

  reg [`MEM_DATA_BITS-1:0] ram [DEPTH-1:0];
  // Ignore lower 2 bits and count ourselves if read, otherwise if write use the 
  wire do_write = mem_req_data_valid && mem_req_data_ready;
  // exact address delivered
  wire [`ceilLog2(DEPTH)-1:0] ram_addr = state_busy  ? ( do_write ? addr[`ceilLog2(DEPTH)-1:0] :  {addr[`ceilLog2(DEPTH)-1:`ceilLog2(DATA_CYCLES)], cnt} )
                                                     : {mem_req_addr[`ceilLog2(DEPTH)-1:`ceilLog2(DATA_CYCLES)], cnt};
  wire do_read = mem_req_valid && mem_req_ready && !mem_req_rw || state_busy && !state_rw;

  initial
  begin : zero
    integer i;
    for (i = 0; i < DEPTH; i = i+1)
      ram[i] = 1'b0;
  end

  wire [`MEM_DATA_BITS-1:0] masked_din;

  generate
    genvar i;
    for (i = 0; i < `MEM_DATA_BITS; i=i+1) begin: MASKED_DIN
      assign masked_din[i] = mem_req_data_mask[i/8] ? mem_req_data_bits[i] : ram[ram_addr][i];
    end
  endgenerate

  always @(posedge clk)
  begin
    if (reset)
      state_busy <= 1'b0;
    else if ((do_read && cnt == DATA_CYCLES-1 || do_write))
      state_busy <= 1'b0;
    else if (mem_req_valid && mem_req_ready)
      state_busy <= 1'b1;

    if (!state_busy && mem_req_valid)
    begin
      state_rw <= mem_req_rw;
      tag <= mem_req_tag;
      addr <= mem_req_addr;
    end

    if (reset)
      cnt <= 1'b0;
    else if(do_read)
      cnt <= cnt + 1'b1;

    if (do_write)
      ram[ram_addr] <= masked_din;
    else
      mem_resp_data <= ram[ram_addr];

    if (reset)
      mem_resp_valid <= 1'b0;
    else
      mem_resp_valid <= do_read;

    mem_resp_tag <= state_busy ? tag : mem_req_tag;
  end

  assign mem_req_ready = !state_busy;
  assign mem_req_data_ready = state_busy && state_rw;

endmodule
