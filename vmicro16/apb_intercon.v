//
//
//

`include "vmicro16_soc_config.v"
`include "clog2.v"
`include "formal.v"

module apb_ic_dec_v2 # (
  parameter MSB        = 7,
  parameter LSB        = 4,
  parameter MASK_RANGE = 2**(MSB-LSB+1), // do not set
  parameter ADDR_WIDTH = 16
) (
  input  [ADDR_WIDTH-1:0] addr,
  output [MASK_RANGE-1:0] pselx
);
  wire [MASK_RANGE-1:0] masked_addr = addr[MSB:LSB];

  genvar p;
  generate
    for (p = 0; p < MASK_RANGE; p = p + 1) begin
      assign pselx[p] = (masked_addr == p);
    end
  endgenerate

endmodule

module nxbar # (
  parameter N_MASTERS = 2,
  parameter N_SLAVES  = 4,
  parameter DWIDTH    = 16
) (
  input clk,
  input reset,

  input  [N_MASTERS*DWIDTH-1:0] m_addr,
  input  [N_MASTERS*DWIDTH-1:0] m_data,
  input  [N_MASTERS-1:0]        m_reqs,

  output [N_SLAVES*DWIDTH-1:0] s_addr,
  output [N_SLAVES*DWIDTH-1:0] s_data,
  output [N_SLAVES-1:0]        s_reqs

  input  [N_MASTERS-1:0] reqs,
  output [N_MASTERS-1:0] grants
);



endmodule

module apb_ic_arbiter_v2 # (
  parameter NUM_MASTERS = 4
) (
  input clk,
  input reset,

  input      [NUM_MASTERS-1:0] reqs,
  output reg [NUM_MASTERS-1:0] grants
);
  wire                   granted_finished = ~(reqs & grants);
  wire                   no_reqs          = ~(|reqs);
  wire [NUM_MASTERS-1:0] grants_nxt       = no_reqs
                                          ? 1
                                          : granted_finished
                                            ? {grants[NUM_MASTERS-2:1], grants[NUM_MASTERS-1]}
                                            : grants;

  always @(posedge clk) begin
    if (reset) grants <= 1;
    else       grants <= grants_nxt;
  end
endmodule

module apb_intercon_s # (
  parameter BUS_WIDTH    = 16,
  parameter DATA_WIDTH   = 16,
  parameter MASTER_PORTS = 1,
  parameter SLAVE_PORTS  = 16,
  parameter ADDR_MSB     = 7,
  parameter ADDR_LSB     = 4
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
  output  [SLAVE_PORTS-1:0]               M_PSELx,
  output                                  M_PENABLE,
  output  [DATA_WIDTH-1:0]                M_PWDATA,
  // inputs from each slave
  input   [SLAVE_PORTS*DATA_WIDTH-1:0]    M_PRDATA,
  input   [SLAVE_PORTS-1:0]               M_PREADY
);
  reg  [`clog2(MASTER_PORTS)-1:0] active_q = 0;
  wire [`clog2(MASTER_PORTS)-1:0] active_w;
  wire [MASTER_PORTS-1:0]         granted;

  // wires for current active_q master
  wire  [BUS_WIDTH-1:0]   a_S_PADDR   = S_PADDR  [active_q*BUS_WIDTH +: BUS_WIDTH];
  wire                    a_S_PWRITE  = S_PWRITE [active_q];
  wire                    a_S_PSELx   = S_PSELx  [active_q];
  wire                    a_S_PENABLE = S_PENABLE[active_q] & S_PENABLE_gate;
  wire  [DATA_WIDTH-1:0]  a_S_PWDATA  = S_PWDATA [active_q*DATA_WIDTH +: DATA_WIDTH];
  wire  [DATA_WIDTH-1:0]  a_S_PRDATA  = S_PRDATA [active_q*DATA_WIDTH +: DATA_WIDTH];
  wire                    a_S_PREADY  = S_PREADY [active_q];

  wire                            active_ended = !a_S_PSELx;
  wire [`clog2(MASTER_PORTS)-1:0] active_nxt   = (active_q == MASTER_PORTS-1)
                                               ? 0
                                               : active_q + 1;

  always @(posedge clk)
    if (|S_PSELx)
      if (active_ended)
        active_q <= active_nxt;

  always @(active_q) $display($time, "\tactive core: %h", active_q);

  reg S_PENABLE_gate = 0;
  always @(posedge clk)
    S_PENABLE_gate <= |a_S_PSELx;

  // Decode master PADDR to determine slave PSEL
  apb_addr_dec_v2 # (
    .MSB        (ADDR_MSB),
    .LSB        (ADDR_LSB),
    .ADDR_WIDTH (BUS_WIDTH)
  ) addr_dec (
    .addr       (a_S_PADDR),
    .pselx      (M_PSELx)
  );

  // Pass through
  assign M_PADDR   = a_S_PADDR;
  assign M_PWRITE  = a_S_PWRITE;
  assign M_PENABLE = a_S_PENABLE;
  assign M_PWDATA  = a_S_PWDATA;
  assign M_PWDATA  = a_S_PWDATA;

  reg M_PSELx_int = 1;

  // Demuxed transfer response back from slave to active_q master
  wire [BUS_WIDTH-1:0]    a_M_PRDATA = M_PRDATA[M_PSELx_int*DATA_WIDTH +: DATA_WIDTH];

  wire [BUS_WIDTH-1:0]    a_M_PRDATA = M_PRDATA[M_PSELx_int*DATA_WIDTH +: DATA_WIDTH];
  wire [SLAVE_PORTS-1:0]  a_M_PREADY = |(M_PSELx & M_PREADY);

  // transfer back to the active_q master
  always @(*) begin
    S_PREADY = 0;
    S_PRDATA = 0;
    S_PREADY[active_q]                          = a_M_PREADY;
    S_PRDATA[active_q*DATA_WIDTH +: DATA_WIDTH] = a_M_PRDATA;
  end
endmodule
