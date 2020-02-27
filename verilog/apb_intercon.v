//
//
//

`include "vmicro16_soc_config.v"
`include "clog2.v"
`include "formal.v"

module apb_ic_addr_dec # (
  parameter MSB        = 7,
  parameter LSB        = 4,
  parameter ADDR_WIDTH = 16,
  parameter MASK_RANGE = 2**(MSB-LSB+1) // do not set
) (
  input  [ADDR_WIDTH-1:0] addr,
  output [MASK_RANGE-1:0] pselx
);
  wire [MSB:LSB] masked_addr;
  assign masked_addr = addr[MSB:LSB];

  genvar p;
  generate
    for (p = 0; p < MASK_RANGE; p = p + 1) begin
      assign pselx[p] = (masked_addr == p);
    end
  endgenerate

endmodule

module apb_ic_arbiter # (
  parameter NUM_MASTERS = 4
) (
  input clk,
  input reset,

  input      [NUM_MASTERS-1:0] reqs,
  output reg [NUM_MASTERS-1:0] grants
);
  wire [NUM_MASTERS-1:0] grants_nxt;
  assign grants_nxt = (grants << 1) | grants[NUM_MASTERS-1];

  always @(posedge clk) begin
    if (reset) grants <= 1;
    else       grants <= grants_nxt;
  end

`ifdef FORMAL
`endif

endmodule

module apb_intercon_s # (
  parameter BUS_WIDTH    = 16,
  parameter DATA_WIDTH   = 16,
  parameter MASTER_PORTS = 1,
  parameter SLAVE_PORTS  = 16,
  parameter ADDR_MSB     = 7,
  parameter ADDR_LSB     = 4,
  // dont change
  parameter PSEL_RANGE   = 2**(ADDR_MSB-ADDR_LSB+1)
) (
  input clk,
  input reset,

  // APB master interface (from cores)
  input      [MASTER_PORTS*BUS_WIDTH-1:0]  S_PADDR,
  input      [MASTER_PORTS-1:0]            S_PWRITE,
  input      [MASTER_PORTS-1:0]            S_PSELx,
  input      [MASTER_PORTS-1:0]            S_PENABLE,
  input      [MASTER_PORTS*DATA_WIDTH-1:0] S_PWDATA,
  output reg [MASTER_PORTS*DATA_WIDTH-1:0] S_PRDATA,
  output reg [MASTER_PORTS-1:0]            S_PREADY,

  // MASTER interface to a slave
  output  [BUS_WIDTH-1:0]                 M_PADDR,
  output                                  M_PWRITE,
  output  [PSEL_RANGE-1:0]                M_PSELx,
  output                                  M_PENABLE,
  output  [DATA_WIDTH-1:0]                M_PWDATA,
  // inputs from each slave
  input   [PSEL_RANGE*DATA_WIDTH-1:0]    M_PRDATA,
  input   [PSEL_RANGE-1:0]               M_PREADY
);
  wire selected = |S_PSELx;

  wire [MASTER_PORTS-1:0] grants;
  localparam GRANTED_INT_BITS = (`clog2(MASTER_PORTS) == 0)
                              ? 1
                              : `clog2(MASTER_PORTS);
  reg [GRANTED_INT_BITS-1:0] granted_int;
  integer granted_bit;
  always @(*) begin
    granted_int = 0;
    for (granted_bit = 0; granted_bit < MASTER_PORTS; granted_bit = granted_bit + 1)
      if (grants[granted_bit])
        granted_int = granted_int | granted_bit;
  end

  // TODO: fix hack
  reg S_PENABLE_gate = 0;

  // wires for current active_q master
  wire  [BUS_WIDTH-1:0]   a_S_PADDR   = S_PADDR  [granted_int*BUS_WIDTH +: BUS_WIDTH];
  wire                    a_S_PWRITE  = S_PWRITE [granted_int];
  wire                    a_S_PSELx   = S_PSELx  [granted_int];
  wire                    a_S_PENABLE = S_PENABLE[granted_int] & S_PENABLE_gate;
  wire  [DATA_WIDTH-1:0]  a_S_PWDATA  = S_PWDATA [granted_int*DATA_WIDTH +: DATA_WIDTH];
  wire  [DATA_WIDTH-1:0]  a_S_PRDATA  = S_PRDATA [granted_int*DATA_WIDTH +: DATA_WIDTH];
  wire                    a_S_PREADY  = S_PREADY [granted_int];

  // Hacky fix to lower passthrough PENABLE for 1 clock in T2
  always @(posedge clk)
  //  S_PENABLE_gate <= |a_S_PSELx;
    S_PENABLE_gate <= 1'b1;

  // Arbitrate incoming master requests
  apb_ic_arbiter # (
    .NUM_MASTERS(MASTER_PORTS)
  ) arbiter (
    .clk        (clk),
    .reset      (reset),
    .reqs       (S_PSELx),
    .grants     (grants)
  );

  // Decode master PADDR to determine slave PSEL
  apb_ic_addr_dec # (
    .MSB        (ADDR_MSB),
    .LSB        (ADDR_LSB),
    .ADDR_WIDTH (BUS_WIDTH)
  ) addr_dec (
    .addr       (a_S_PADDR),
    .pselx      (M_PSELx)
  );

  // Pass through outputs to slaves
  assign M_PADDR   = a_S_PADDR;
  assign M_PWRITE  = a_S_PWRITE;
  assign M_PENABLE = a_S_PENABLE & selected;
  assign M_PWDATA  = a_S_PWDATA;
  assign M_PWDATA  = a_S_PWDATA;

  reg [GRANTED_INT_BITS-1:0] psel_int;
  integer psel_bit;
  always @(*) begin
    psel_int = 0;
    for (psel_bit = 0; psel_bit < MASTER_PORTS; psel_bit = psel_bit + 1)
      if (grants[psel_bit])
        psel_int = psel_int | grants[psel_bit];
  end

  // Demuxed transfer response back from slave to active_q master
  wire [BUS_WIDTH-1:0] a_M_PRDATA = M_PRDATA[psel_int*DATA_WIDTH +: DATA_WIDTH];
  wire                 a_M_PREADY = |(M_PSELx & M_PREADY);

  // transfer back to the active_q master
  // TODO: required?
  always @(*) begin
    S_PREADY = 0;
    S_PRDATA = 0;
    S_PREADY[granted_int]                          = a_M_PREADY;
    S_PRDATA[granted_int*DATA_WIDTH +: DATA_WIDTH] = a_M_PRDATA;
  end

endmodule

