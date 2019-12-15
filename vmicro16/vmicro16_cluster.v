//
// Vmicro16 cluster
//

`include "../formal.v"
`include "../vmicro16_soc_config.v"

module vmicro16_cluster #
(
  parameter NCORES    = 4
) (
  input clk,
  input reset
);

  // Peripherals (master to slave)
  wire [`APB_WIDTH-1:0]          ic_dmem_M_PADDR;
  wire                           ic_dmem_M_PWRITE;
  wire [0:0]                     ic_dmem_M_PSELx;  // not shared
  wire                           ic_dmem_M_PENABLE;
  wire [`DATA_WIDTH-1:0]         ic_dmem_M_PWDATA;
  wire [`DATA_WIDTH-1:0]         ic_dmem_M_PRDATA; // input to intercon
  wire [0:0]                     ic_dmem_M_PREADY; // input

  // Master apb interfaces
  wire [NCORES*`APB_WIDTH-1:0]   ic_dmem_W_PADDR;
  wire [NCORES-1:0]              ic_dmem_W_PWRITE;
  wire [NCORES-1:0]              ic_dmem_W_PSELx;
  wire [NCORES-1:0]              ic_dmem_W_PENABLE;
  wire [NCORES*`DATA_WIDTH-1:0]  ic_dmem_W_PWDATA;
  wire [NCORES*`DATA_WIDTH-1:0]  ic_dmem_W_PRDATA;
  wire [NCORES-1:0]              ic_dmem_W_PREADY;

  apb_intercon_s # (
    .MASTER_PORTS   (NCORES),
    .SLAVE_PORTS    (1),
    .BUS_WIDTH      (`APB_WIDTH),
    .DATA_WIDTH     (`DATA_WIDTH),
    .HAS_PSELX_ADDR (1)
  ) ic_dmem (
    .clk        (clk),
    .reset      (reset),
    // APB master to slave
    .S_PADDR    (ic_dmem_W_PADDR),
    .S_PWRITE   (ic_dmem_W_PWRITE),
    .S_PSELx    (ic_dmem_W_PSELx),
    .S_PENABLE  (ic_dmem_W_PENABLE),
    .S_PWDATA   (ic_dmem_W_PWDATA),
    .S_PRDATA   (ic_dmem_W_PRDATA),
    .S_PREADY   (ic_dmem_W_PREADY),
    // shared bus
    .M_PADDR    (ic_dmem_M_PADDR),
    .M_PWRITE   (ic_dmem_M_PWRITE),
    .M_PSELx    (ic_dmem_M_PSELx),
    .M_PENABLE  (ic_dmem_M_PENABLE),
    .M_PWDATA   (ic_dmem_M_PWDATA),
    .M_PRDATA   (ic_dmem_M_PRDATA),
    .M_PREADY   (ic_dmem_M_PREADY)
  );

  apb_intercon_s # (
    .MASTER_PORTS   (NCORES),
    .SLAVE_PORTS    (1),
    .BUS_WIDTH      (`APB_WIDTH),
    .DATA_WIDTH     (`DATA_WIDTH),
    .HAS_PSELX_ADDR (1)
  ) ic_imem (
    .clk        (clk),
    .reset      (reset),
    // APB master to slave
    .S_PADDR    (ic_imem_W_PADDR),
    .S_PWRITE   (ic_imem_W_PWRITE),
    .S_PSELx    (ic_imem_W_PSELx),
    .S_PENABLE  (ic_imem_W_PENABLE),
    .S_PWDATA   (ic_imem_W_PWDATA),
    .S_PRDATA   (ic_imem_W_PRDATA),
    .S_PREADY   (ic_imem_W_PREADY),
    // shared bus
    .M_PADDR    (ic_imem_M_PADDR),
    .M_PWRITE   (ic_imem_M_PWRITE),
    .M_PSELx    (ic_imem_M_PSELx),
    .M_PENABLE  (ic_imem_M_PENABLE),
    .M_PWDATA   (ic_imem_M_PWDATA),
    .M_PRDATA   (ic_imem_M_PRDATA),
    .M_PREADY   (ic_imem_M_PREADY)
  );


  genvar c;
  generate
    for (c = 0; c < NCLUSTERS; c = c + 1) begin
      vmicro16_core # (
        .CORE_ID    (c),
        .DATA_WITH  (16)
      ) cpu (
        .clk        (clk),
        .reset      (reset),
        // debug
        .halt       (w_halt[c]),

        // APB to ic_dmem
        .w_PADDR    (ic_dmem_W_PADDR   [`APB_WIDTH*c +: `APB_WIDTH]  ),
        .w_PWRITE   (ic_dmem_W_PWRITE  [c]                           ),
        .w_PSELx    (ic_dmem_W_PSELx   [c]                           ),
        .w_PENABLE  (ic_dmem_W_PENABLE [c]                           ),
        .w_PWDATA   (ic_dmem_W_PWDATA  [`DATA_WIDTH*c +: `DATA_WIDTH]),
        .w_PRDATA   (ic_dmem_W_PRDATA  [`DATA_WIDTH*c +: `DATA_WIDTH]),
        .w_PREADY   (ic_dmem_W_PREADY  [c]                           )
        // APB to ic_imem
        ,
        .w2_PADDR   (ic_imem_W_PADDR   [`APB_WIDTH*i +: `APB_WIDTH]  ),
        .w2_PWRITE  (0),
        .w2_PSELx   (ic_imem_W_PSELx   [i]                           ),
        .w2_PENABLE (ic_imem_W_PENABLE [i]                           ),
        .w2_PWDATA  (0),
        .w2_PRDATA  (ic_imem_W_PRDATA  [`DATA_WIDTH*i +: `DATA_WIDTH]),
        .w2_PREADY  (ic_imem_W_PREADY  [i]                           )
      );
    end
  endgenerate

endmodule
