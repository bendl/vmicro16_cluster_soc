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
  parameter NUM_CORES    = 4
) (
  input clk,
  input reset,

  // UART0
  input                           uart_rx,
  output                          uart_tx,
  //
  output [`APB_GPIO0_PINS-1:0]    gpio0,
  output [`APB_GPIO1_PINS-1:0]    gpio1,
  output [`APB_GPIO2_PINS-1:0]    gpio2,
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
  wire wdreset;
  wire prog_prog;
  // Set high if a bus stall or error occurs.
  // This will reset the whole SoC!
  wire bus_reset;

  // soft register reset hold for brams and registers
  wire soft_reset;
  `ifdef DEF_GLOBAL_RESET
      pow_reset # (
          .INIT       (1),
          .N          (8)
      ) por_inst (
          .clk        (clk),
          `ifdef DEF_USE_WATCHDOG
          .reset      (reset | wdreset | prog_prog
              `ifdef DEF_USE_BUS_RESET
                  | bus_reset),
              `else
                  ),
          `endif
          `else
          .reset      (reset),
          `endif
          .resethold  (soft_reset)
      );
  `else
      assign soft_reset = 0;
  `endif

  // SOC.IC_DMEM
  // IC_DMEM to peripherals
  wire [`APB_WIDTH-1:0]                      ic_dmem_M_PADDR;
  wire                                       ic_dmem_M_PWRITE;
  wire [SOC_IC_DMEM_PERIPHS-1:0]             ic_dmem_M_PSELx;
  wire                                       ic_dmem_M_PENABLE;
  wire [`DATA_WIDTH-1:0]                     ic_dmem_M_PWDATA;
  wire [SOC_IC_DMEM_PERIPHS*`DATA_WIDTH-1:0] ic_dmem_M_PRDATA;
  wire [SOC_IC_DMEM_PERIPHS-1:0]             ic_dmem_M_PREADY;

  // Clusters to soc.IC_DMEM
  wire [NUM_CLUSTERS*`APB_WIDTH-1:0]         ic_dmem_W_PADDR;
  wire [NUM_CLUSTERS-1:0]                    ic_dmem_W_PWRITE;
  wire [NUM_CLUSTERS-1:0]                    ic_dmem_W_PSELx;
  wire [NUM_CLUSTERS-1:0]                    ic_dmem_W_PENABLE;
  wire [NUM_CLUSTERS*`DATA_WIDTH-1:0]        ic_dmem_W_PWDATA;
  wire [NUM_CLUSTERS*`DATA_WIDTH-1:0]        ic_dmem_W_PRDATA;
  wire [NUM_CLUSTERS-1:0]                    ic_dmem_W_PREADY;

  apb_intercon_s # (
    .MASTER_PORTS   (NUM_CLUSTERS),
    .SLAVE_PORTS    (SOC_IC_DMEM_PERIPHS),
    .BUS_WIDTH      (`APB_WIDTH),
    .DATA_WIDTH     (`DATA_WIDTH),
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

  // APB wrapped vmicro16_bram
  vmicro16_bram_apb # (
      .BUS_WIDTH  (16),
      .BMEM_WIDTH (16),
      .BMEM_DEPTH (64),
      .BAPB_PADDR (0),
      .BUSE_INITS (0),
      .BNAME      ("BRAM"),
      .BCORE_ID   (0)
  ) (
      .clk        (clk)
      .reset      (soft_reset),

      // SOC.IC_DMEM to DMEM
      .S_PADDR    (ic_dmem_M_PADDR   [`APB_WIDTH*c +: `APB_WIDTH]  ),
      .S_PWRITE   (ic_dmem_M_PWRITE                                ),
      .S_PSELx    (ic_dmem_M_PSELx   [`APB_PSELX_IC_DMEM_DMEM]     ),),
      .S_PENABLE  (ic_dmem_M_PENABLE                               ),
      .S_PWDATA   (ic_dmem_M_PWDATA  [`DATA_WIDTH*c +: `DATA_WIDTH]),
      // DMEM to SOC.IC_DMEM
      .S_PRDATA   (ic_dmem_M_PRDATA  [`DATA_WIDTH*c +: `DATA_WIDTH]),
      .S_PREADY   (ic_dmem_M_PREADY                                )
  );

  // Peripherals
  vmicro16_bram_apb # (
    .MASTERS (1),
    .SLAVES  (`SLAVES)
  ) (
      .clk        (clk)
      .reset      (soft_reset),

      // SOC.IC_DMEM to PERI
      .S_PADDR    (ic_dmem_M_PADDR   [`APB_WIDTH*c +: `APB_WIDTH]  ),
      .S_PWRITE   (ic_dmem_M_PWRITE                                ),
      .S_PSELx    (ic_dmem_M_PSELx   [`APB_PSELX_IC_DMEM_PERI]     ),),
      .S_PENABLE  (ic_dmem_M_PENABLE                               ),
      .S_PWDATA   (ic_dmem_M_PWDATA  [`DATA_WIDTH*c +: `DATA_WIDTH]),
      // DMEM to SOC.IC_DMEM
      .S_PRDATA   (ic_dmem_M_PRDATA  [`DATA_WIDTH*c +: `DATA_WIDTH]),
      .S_PREADY   (ic_dmem_M_PREADY                                )
  );



  genvar c;
  generate for(c = 0; c < NUM_CLUSTERS; c = c + 1) begin : clusters
    vmicro16_cluster # (
      .NCORES (NUM_CORES)
    ) cl1 (
      .clk        (clk),
      .reset      (soft_reset),
      // IC_DMEM to soc.IC_DMEM
      .M_PADDR    (ic_dmem_W_PADDR   [`APB_WIDTH*c +: `APB_WIDTH]  ),
      .M_PWRITE   (ic_dmem_W_PWRITE  [c]                           ),
      .M_PSELx    (ic_dmem_W_PSELx   [c]                           ),
      .M_PENABLE  (ic_dmem_W_PENABLE [c]                           ),
      .M_PWDATA   (ic_dmem_W_PWDATA  [`DATA_WIDTH*c +: `DATA_WIDTH]),
      .M_PRDATA   (ic_dmem_W_PRDATA  [`DATA_WIDTH*c +: `DATA_WIDTH]),
      .M_PREADY   (ic_dmem_W_PREADY  [c]                           )
    );
  end
  endgenerate


  /////////////////////////////////////////////////////
  // Formal Verification
  /////////////////////////////////////////////////////
  `ifdef FORMAL
  wire all_halted = &w_halt;
  /////////////////////////////////////////////////////
  // Count number of clocks each core is spending on
  //   bus transactions
  /////////////////////////////////////////////////////
  reg [15:0] bus_core_times       [0:NUM_CORES-1]; // bus work
  reg [15:0] core_work_times      [0:NUM_CORES-1]; // serial work
  reg [15:0] instr_fetch_times    [0:NUM_CORES-1]; // instruction fetches
  integer i2;
  initial
      for(i2 = 0; i2 < NUM_CORES; i2 = i2 + 1) begin
          bus_core_times[i2] = 0;
          core_work_times[i2] = 0;
      end

  // total bus time
  generate
      genvar g2;
      for (g2 = 0; g2 < NUM_CORES; g2 = g2 + 1) begin : formal_for_times
            always @(posedge clk) begin
                  if (w_PSELx[g2])
                       bus_core_times[g2] <= bus_core_times[g2] + 1;

                  // Core working time
                  `ifndef DEF_CORE_HAS_INSTR_MEM
                       if (!w_PSELx[g2] && !instr_w_PSELx[g2])
                  `else
                       if (!w_PSELx[g2])
                  `endif
                            if (!w_halt[g2])
                                  core_work_times[g2] <= core_work_times[g2] + 1;

            end
        end
  endgenerate

  reg [15:0] bus_time_average = 0;
  reg [15:0] bus_reqs_average = 0;
  reg [15:0] fetch_time_average = 0;
  reg [15:0] work_time_average = 0;
  //
  always @(all_halted) begin
      for (i2 = 0; i2 < NUM_CORES; i2 = i2 + 1) begin
          bus_time_average   = bus_time_average   + bus_core_times[i2];
          bus_reqs_average   = bus_reqs_average   + bus_core_reqs_count[i2];
          work_time_average  = work_time_average  + core_work_times[i2];
          fetch_time_average = fetch_time_average + instr_fetch_times[i2];
      end

      bus_time_average   = bus_time_average   / NUM_CORES;
      bus_reqs_average   = bus_reqs_average   / NUM_CORES;
      work_time_average  = work_time_average  / NUM_CORES;
      fetch_time_average = fetch_time_average / NUM_CORES;
  end

  ////////////////////////////////////////////////////
  // Count number of bus requests per core
  ////////////////////////////////////////////////////
  // 1 clock delay of w_PSELx
  reg [NUM_CORES-1:0] bus_core_reqs_last;
  // rising edges of each
  wire [NUM_CORES-1:0] bus_core_reqs_real;
  // storage for counters for each core
  reg [15:0] bus_core_reqs_count [0:NUM_CORES-1];
  initial
      for(i2 = 0; i2 < NUM_CORES; i2 = i2 + 1)
          bus_core_reqs_count[i2] = 0;

  // 1 clk delay to detect rising edge
  always @(posedge clk)
      bus_core_reqs_last <= w_PSELx;

  generate
      genvar g3;
            for (g3 = 0; g3 < NUM_CORES; g3 = g3 + 1) begin : formal_for_reqs
            // Detect new reqs for each core
            assign bus_core_reqs_real[g3] = w_PSELx[g3] >
                                                      bus_core_reqs_last[g3];

            always @(posedge clk)
                  if (bus_core_reqs_real[g3])
                       bus_core_reqs_count[g3] <= bus_core_reqs_count[g3] + 1;

       end
  endgenerate


  `ifndef DEF_CORE_HAS_INSTR_MEM
      ////////////////////////////////////////////////////
      // Time waiting for instruction fetches
      //   from global  memory
      ////////////////////////////////////////////////////
      integer i3;
      initial
          for(i3 = 0; i3 < NUM_CORES; i3 = i3 + 1)
              instr_fetch_times[i3] = 0;

      // total bus time
      // Instruction fetches occur on the w2 master port
      generate
          genvar g4;
          for (g4 = 0; g4 < NUM_CORES; g4 = g4 + 1) begin : formal_for_fetch_times
              always @(posedge clk)
                  if (instr_w_PSELx[g4])
                      instr_fetch_times[g4] <= instr_fetch_times[g4] + 1;
          end
      endgenerate
  `endif


  `endif // end FORMAL

endmodule
