//
//

`include "vmicro16_soc_config.v"
`include "clog2.v"
`include "formal.v"

module pow_reset # (
    parameter INIT  = 1,
    parameter N     = 8
) (
    input       clk,
    input       reset,
    output reg  resethold
);
    initial resethold = INIT ? (N-1) : 0;

    always @(*)
        resethold = |hold;

    reg [`clog2(N)-1:0] hold = (N-1);
    always @(posedge clk)
        if (reset)
            hold <= N-1;
        else
            if (hold)
                hold <= hold - 1;
endmodule

// Vmicro16 multi-core SoC with various peripherals
// and interrupts
module vmicro16_soc # (
  parameter NUM_CLUSTERS = 1,
  parameter NUM_CORES    = 2,

  parameter DATA_WIDTH = 32,

  parameter GLOBAL_RESET = 1,
  parameter USE_BUS_RESET = 1,

  parameter APB_WIDTH = 32,
  parameter APB_GPIO0_PINS = 8,
  parameter APB_GPIO1_PINS = 8,
  parameter APB_GPIO2_PINS = 8
) (
  input clk,
  input reset,

  // UART0
  input                           uart_rx,
  output                          uart_tx,
  //
  output [APB_GPIO0_PINS-1:0]    gpio0,
  output [APB_GPIO1_PINS-1:0]    gpio1,
  output [APB_GPIO2_PINS-1:0]    gpio2,
  //
  output                          halt,
  //
  output     [NUM_CORES-1:0]      dbug0,
  output     [NUM_CORES*8-1:0]    dbug1
);
  localparam SOC_IC_DMEM_PERIPHS = 2;


  wire [NUM_CORES-1:0] w_halt;
  assign halt = &w_halt;

  assign dbug0 = w_halt;

  // Watchdog reset pulse signal.
  //   Passed to pow_reset to generate a longer reset pulse
  //wire wdreset;
  // Set high if a bus stall or error occurs.
  // This will reset the whole SoC!

  // soft register reset hold for brams and registers
  wire soft_reset;

  generate
    if (GLOBAL_RESET) begin
      wire reset_srcs  = reset;
      pow_reset # (
          .INIT       (1),
          .N          (8)
      ) por_inst (
          .clk        (clk),
          .reset      (reset_srcs),
          .resethold  (soft_reset)
      );
    end else begin
      assign soft_reset = 1'b0;
    end
  endgenerate

  // SOC.IC_DMEM
  // IC_DMEM to peripherals
  wire [APB_WIDTH-1:0]                      ic_dmem_M_PADDR;
  wire                                       ic_dmem_M_PWRITE;
  wire [SOC_IC_DMEM_PERIPHS-1:0]             ic_dmem_M_PSELx;
  wire                                       ic_dmem_M_PENABLE;
  wire [DATA_WIDTH-1:0]                     ic_dmem_M_PWDATA;
  wire [SOC_IC_DMEM_PERIPHS*DATA_WIDTH-1:0] ic_dmem_M_PRDATA;
  wire [SOC_IC_DMEM_PERIPHS-1:0]             ic_dmem_M_PREADY;

  // Clusters to soc.IC_DMEM
  wire [NUM_CLUSTERS*APB_WIDTH-1:0]         ic_dmem_W_PADDR;
  wire [NUM_CLUSTERS-1:0]                    ic_dmem_W_PWRITE;
  wire [NUM_CLUSTERS-1:0]                    ic_dmem_W_PSELx;
  wire [NUM_CLUSTERS-1:0]                    ic_dmem_W_PENABLE;
  wire [NUM_CLUSTERS*DATA_WIDTH-1:0]        ic_dmem_W_PWDATA;
  wire [NUM_CLUSTERS*DATA_WIDTH-1:0]        ic_dmem_W_PRDATA;
  wire [NUM_CLUSTERS-1:0]                    ic_dmem_W_PREADY;

  apb_intercon_s # (
    .MASTER_PORTS   (NUM_CLUSTERS),
    .SLAVE_PORTS    (SOC_IC_DMEM_PERIPHS),
    .BUS_WIDTH      (APB_WIDTH),
    .DATA_WIDTH     (DATA_WIDTH),
    .HAS_PSELX_ADDR (1)
  ) ic_dmem (
    .clk        (clk),
    .reset      (soft_reset),
    // from masters
    .S_PADDR    (ic_dmem_W_PADDR),
    .S_PWRITE   (ic_dmem_W_PWRITE),
    .S_PSELx    (ic_dmem_W_PSELx),
    .S_PENABLE  (ic_dmem_W_PENABLE),
    .S_PWDATA   (ic_dmem_W_PWDATA),
    .S_PRDATA   (ic_dmem_W_PRDATA),
    .S_PREADY   (ic_dmem_W_PREADY),
    // to slave
    .M_PADDR    (ic_dmem_M_PADDR),
    .M_PWRITE   (ic_dmem_M_PWRITE),
    .M_PSELx    (ic_dmem_M_PSELx),
    .M_PENABLE  (ic_dmem_M_PENABLE),
    .M_PWDATA   (ic_dmem_M_PWDATA),
    .M_PRDATA   (ic_dmem_M_PRDATA),
    .M_PREADY   (ic_dmem_M_PREADY)
  );

  //vmicro16_bram_apb # (
  //    .BUS_WIDTH  (16),
  //    .BMEM_WIDTH (16),
  //    .BMEM_DEPTH (64),
  //    .BAPB_PADDR (0),
  //    .BUSE_INITS (0),
  //    .BNAME      ("BRAM"),
  //    .BCORE_ID   (0)
  //) base_bram0 (
  //    .clk        (clk),
  //    .reset      (soft_reset),
  //
  //    // SOC.IC_DMEM to DMEM
  //    .S_PADDR    (ic_dmem_M_PADDR   [APB_WIDTH*c +: APB_WIDTH]   ),
  //    .S_PWRITE   (ic_dmem_M_PWRITE                               ),
  //    .S_PSELx    (ic_dmem_M_PSELx   [0]                          ),
  //    .S_PENABLE  (ic_dmem_M_PENABLE                              ),
  //    .S_PWDATA   (ic_dmem_M_PWDATA  [DATA_WIDTH*c +: DATA_WIDTH] ),
  //    // DMEM to SOC.IC_DMEM
  //    .S_PRDATA   (ic_dmem_M_PRDATA  [DATA_WIDTH*c +: DATA_WIDTH] ),
  //    .S_PREADY   (ic_dmem_M_PREADY                               )
  //);

  vmicro16_bram_apb # (
    .MASTERS (1),
    .SLAVES  (SLAVES)
  ) base_bram1 (
      .clk        (clk),
      .reset      (soft_reset),

      // SOC.IC_DMEM to PERI
      .S_PADDR    (ic_dmem_M_PADDR   [APB_WIDTH*0 +: APB_WIDTH]   ),
      .S_PWRITE   (ic_dmem_M_PWRITE                               ),
      .S_PSELx    (ic_dmem_M_PSELx   [0]                          ),
      .S_PENABLE  (ic_dmem_M_PENABLE                              ),
      .S_PWDATA   (ic_dmem_M_PWDATA  [DATA_WIDTH*0 +: DATA_WIDTH] ),
      // DMEM to SOC.IC_DMEM
      .S_PRDATA   (ic_dmem_M_PRDATA  [DATA_WIDTH*0 +: DATA_WIDTH] ),
      .S_PREADY   (ic_dmem_M_PREADY                               )
  );

  genvar c;
  generate for(c = 0; c < NUM_CLUSTERS; c = c + 1) begin : clusters
    vmicro16_cluster # (
      .NCORES (NUM_CORES)
    ) cl1 (
      .clk        (clk),
      .reset      (soft_reset),
      // IC_DMEM to soc.IC_DMEM
      .M_PADDR    (ic_dmem_W_PADDR   [APB_WIDTH*c +: APB_WIDTH]  ),
      .M_PWRITE   (ic_dmem_W_PWRITE  [c]                           ),
      .M_PSELx    (ic_dmem_W_PSELx   [c]                           ),
      .M_PENABLE  (ic_dmem_W_PENABLE [c]                           ),
      .M_PWDATA   (ic_dmem_W_PWDATA  [DATA_WIDTH*c +: DATA_WIDTH]),
      .M_PRDATA   (ic_dmem_W_PRDATA  [DATA_WIDTH*c +: DATA_WIDTH]),
      .M_PREADY   (ic_dmem_W_PREADY  [c]                           )
    );
  end
  endgenerate


  /////////////////////////////////////////////////////
  // Formal Verification
  /////////////////////////////////////////////////////
  `ifdef FORMAL
  `endif // end FORMAL

endmodule
