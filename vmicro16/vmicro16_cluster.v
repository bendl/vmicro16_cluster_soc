//
// Vmicro16 cluster
//

`include "../formal.v"
`include "../vmicro16_soc_config.v"

module vmicro16_cluster #
(
  parameter BUS_WIDTH           = 16,
  parameter DATA_WIDTH          = 16,
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
  // Master drivers from cores to main IC
  wire [NCORES*BUS_WIDTH-1:0]    W_PADDR;
  wire [NCORES-1:0]              W_PWRITE;
  wire [NCORES-1:0]              W_PSELx;
  wire [NCORES-1:0]              W_PENABLE;
  wire [NCORES*DATA_WIDTH-1:0]   W_PWDATA;
  wire [NCORES*DATA_WIDTH-1:0]   W_PRDATA;
  wire [NCORES-1:0]              W_PREADY;

  apb_intercon_s # (
    .BUS_WIDTH      (BUS_WIDTH),
    .DATA_WIDTH     (DATA_WIDTH),
    .MASTER_PORTS   (NCORES),
    .SLAVE_PORTS    (2), // IC_DMEM and cache
    .ADDR_MSB       (`IC_CLUSTER_DEC_MSB),
    .ADDR_LSB       (`IC_CLUSTER_DEC_LSB)
  ) ic_dmem (
    .clk        (clk),
    .reset      (reset),
    // Cores to IC_DMEM
    .S_PADDR    (W_PADDR),
    .S_PWRITE   (W_PWRITE),
    .S_PSELx    (W_PSELx),
    .S_PENABLE  (W_PENABLE),
    .S_PWDATA   (W_PWDATA),
    .S_PRDATA   (W_PRDATA),
    .S_PREADY   (W_PREADY),
    // IC_DMEM to soc.IC_DMEM
    .M_PADDR    (M_PADDR),
    .M_PWRITE   (M_PWRITE),
    .M_PSELx    (M_PSELx),
    .M_PENABLE  (M_PENABLE),
    .M_PWDATA   (M_PWDATA),
    .M_PRDATA   (M_PRDATA),
    .M_PREADY   (M_PREADY)
  );

  // register apb test peripheral
  vmicro16_bram_apb # (
    .BUS_WIDTH  (BUS_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .NAME       ("cache"),
    .MEM_DEPTH  (64)
  ) cache_cluster (
    .clk        (clk),
    .reset      (reset),
    // apb slave to master interface
    .S_PADDR    (M_PADDR),
    .S_PWRITE   (M_PWRITE),
    .S_PSELx    (M_PSELx[0]),
    .S_PENABLE  (M_PENABLE),
    .S_PWDATA   (M_PWDATA),
    .S_PRDATA   (M_PRDATA[0*DATA_WIDTH +: DATA_WIDTH]),
    .S_PREADY   (M_PREADY[0])
  );

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
        .halt       (w_halt[c]),

        // APB to ic_dmem
        .w_PADDR    (W_PADDR   [BUS_WIDTH*c +: BUS_WIDTH]  ),
        .w_PWRITE   (W_PWRITE  [c]                           ),
        .w_PSELx    (W_PSELx   [c]                           ),
        .w_PENABLE  (W_PENABLE [c]                           ),
        .w_PWDATA   (W_PWDATA  [DATA_WIDTH*c +: DATA_WIDTH]),
        .w_PRDATA   (W_PRDATA  [DATA_WIDTH*c +: DATA_WIDTH]),
        .w_PREADY   (W_PREADY  [c]                           )
        // APB to ic_imem
        //,
        //.w2_PADDR   (ic_imem_W_PADDR   [`APB_WIDTH*i +: `APB_WIDTH]  ),
        //.w2_PWRITE  (0),
        //.w2_PSELx   (ic_imem_W_PSELx   [i]                           ),
        //.w2_PENABLE (ic_imem_W_PENABLE [i]                           ),
        //.w2_PWDATA  (0),
        //.w2_PRDATA  (ic_imem_W_PRDATA  [`DATA_WIDTH*i +: `DATA_WIDTH]),
        //.w2_PREADY  (ic_imem_W_PREADY  [i]                           )
      );
    end
  endgenerate

endmodule
