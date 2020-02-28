//
// Vmicro16 cluster
//

`include "formal.v"
`include "vmicro16_soc_config.v"

module vmicro16_cluster #
(
  parameter BUS_WIDTH           = 32,
  parameter DATA_WIDTH          = 32,
  parameter NCORES              = 4,
  parameter CLUSTER_CACHE       = 1, // TODO: impl
  parameter CLUSTER_CACHE_WORDS = 64
) (
  input clk,
  input reset,

  // Driver to soc.IC_DMEM
  output  [1*BUS_WIDTH-1:0]                 M_PADDR,
  output  [0:0]                             M_PWRITE,
  output  [0:0]                             M_PSELx,
  output  [0:0]                             M_PENABLE,
  output  [1*DATA_WIDTH-1:0]                M_PWDATA,
  // transfer response from main IC
  input   [1*DATA_WIDTH-1:0]                M_PRDATA,
  input   [0:0]                             M_PREADY
);
  localparam IC_DMEM_SLAVES     = 2;
  localparam IC_DMEM_PSEL_CACHE = 0;
  localparam IC_DMEM_PSEL_DMEM  = 1;

  // Master drivers from cores to main IC
  wire [NCORES*BUS_WIDTH-1:0]            ic_dmem_S_PADDR;
  wire [NCORES-1:0]                      ic_dmem_S_PWRITE;
  wire [NCORES-1:0]                      ic_dmem_S_PSELx;
  wire [NCORES-1:0]                      ic_dmem_S_PENABLE;
  wire [NCORES*DATA_WIDTH-1:0]           ic_dmem_S_PWDATA;
  wire [NCORES*DATA_WIDTH-1:0]           ic_dmem_S_PRDATA;
  wire [NCORES-1:0]                      ic_dmem_S_PREADY;

  // Master drivers from cores to main IC
  wire [IC_DMEM_SLAVES*BUS_WIDTH-1:0]    ic_dmem_M_PADDR;
  wire [IC_DMEM_SLAVES-1:0]              ic_dmem_M_PWRITE;
  wire [IC_DMEM_SLAVES-1:0]              ic_dmem_M_PSELx;
  wire [IC_DMEM_SLAVES-1:0]              ic_dmem_M_PENABLE;
  wire [IC_DMEM_SLAVES*DATA_WIDTH-1:0]   ic_dmem_M_PWDATA;
  wire [IC_DMEM_SLAVES*DATA_WIDTH-1:0]   ic_dmem_M_PRDATA;
  wire [IC_DMEM_SLAVES-1:0]              ic_dmem_M_PREADY;

  // Interconnect interface from cluster block
  assign M_PADDR   = ic_dmem_M_PADDR;
  assign M_PWRITE  = ic_dmem_M_PWDATA;
  assign M_PSELx   = ic_dmem_M_PSELx[IC_DMEM_PSEL_DMEM];
  assign M_PENABLE = ic_dmem_M_PENABLE;
  assign M_PWDATA  = ic_dmem_M_PWDATA;
  assign M_PRDATA  = ic_dmem_M_PRDATA;
  assign M_PREADY  = ic_dmem_M_PREADY;

  // IC_DMEM
  apb_intercon_s # (
    .BUS_WIDTH    (BUS_WIDTH),
    .DATA_WIDTH   (DATA_WIDTH),
    .MASTER_PORTS (NCORES),
    .SLAVE_PORTS  (2), // IC_DMEM and cache
    .ADDR_MSB     (15),
    .ADDR_LSB     (15)
  ) ic_dmem (
    .clk          (clk),
    .reset        (reset),
    // Cores to IC_DMEM
    .S_PADDR      (ic_dmem_S_PADDR),
    .S_PWRITE     (ic_dmem_S_PWRITE),
    .S_PSELx      (ic_dmem_S_PSELx),
    .S_PENABLE    (ic_dmem_S_PENABLE),
    .S_PWDATA     (ic_dmem_S_PWDATA),
    .S_PRDATA     (ic_dmem_S_PRDATA),
    .S_PREADY     (ic_dmem_S_PREADY),
    // IC_DMEM to soc.IC_DMEM
    .M_PADDR      (ic_dmem_M_PADDR),
    .M_PWRITE     (ic_dmem_M_PWRITE),
    .M_PSELx      (ic_dmem_M_PSELx),
    .M_PENABLE    (ic_dmem_M_PENABLE),
    .M_PWDATA     (ic_dmem_M_PWDATA),
    .M_PRDATA     (ic_dmem_M_PRDATA),
    .M_PREADY     (ic_dmem_M_PREADY)
  );

  // register apb test peripheral
  //vmicro16_bram_apb # (
  //  .BUS_WIDTH  (BUS_WIDTH),
  //  .DATA_WIDTH (DATA_WIDTH),
  //  .NAME       ("cache"),
  //  .MEM_DEPTH  (64)
  //) cache_cluster (
  //  .clk        (clk),
  //  .reset      (reset),
  //  // apb slave to master interface
  //  .S_PADDR    (ic_dmem_M_PADDR),
  //  .S_PWRITE   (ic_dmem_M_PWRITE),
  //  .S_PSELx    (ic_dmem_M_PSELx[IC_DMEM_PSEL_CACHE]),
  //  .S_PENABLE  (ic_dmem_M_PENABLE),
  //  .S_PWDATA   (ic_dmem_M_PWDATA),
  //  .S_PRDATA   (ic_dmem_M_PRDATA[IC_DMEM_PSEL_CACHE*DATA_WIDTH +: DATA_WIDTH]),
  //  .S_PREADY   (ic_dmem_M_PREADY[IC_DMEM_PSEL_CACHE])
  //);

  genvar c;
  generate
    for (c = 0; c < NCORES; c = c + 1) begin
      vmicro16_core # (
        .CORE_ID           (c),
        .DATA_WIDTH        (DATA_WIDTH),
        .MEM_INSTR_DEPTH   (64),
        .MEM_SCRATCH_DEPTH (64),
        .MEM_WIDTH         (DATA_WIDTH)
      ) cpu (
        .clk        (clk),
        .reset      (reset),
        // debug
        .halt       (),

        // APB to ic_dmem
        .w_PADDR    (ic_dmem_S_PADDR  [BUS_WIDTH*c +: BUS_WIDTH]),
        .w_PWRITE   (ic_dmem_S_PWRITE [c]),
        .w_PSELx    (ic_dmem_S_PSELx  [c]),
        .w_PENABLE  (ic_dmem_S_PENABLE[c]),
        .w_PWDATA   (ic_dmem_S_PWDATA [DATA_WIDTH*c +: DATA_WIDTH]),
        .w_PRDATA   (ic_dmem_S_PRDATA [DATA_WIDTH*c +: DATA_WIDTH]),
        .w_PREADY   (ic_dmem_S_PREADY [c])
        // APB to ic_imem
        //,
        //.w2_PADDR   (ic_imem_W_PADDR   [`APB_WIDTH*i +: `APB_WIDTH]  ),
        //.w2_PWRITE  (0),
        //.w2_PSELx   (ic_imem_W_PSELx   [i]                           ),
        //.w2_PENABLE (ic_imem_W_PENABLE [i]                           ),
        //.w2_PWDATA  (0),
        //.w2_PRDATA  (ic_imem_W_PRDATA  [DATA_WIDTH*i +: DATA_WIDTH]),
        //.w2_PREADY  (ic_imem_W_PREADY  [i]                           )
      );
    end
  endgenerate

endmodule
