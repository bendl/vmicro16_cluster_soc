


`timescale 1ns / 1ps

`include "../vmicro16_soc_config.v"
`include "../formal.v"

module tb_cluster # (
  parameter BUS_WIDTH          = 16,
  parameter DATA_WIDTH         = 16,
  parameter NUM_CLUSTERS       = 1,
  parameter NUM_CLUSTERS_CORES = 4,
  parameter NUM_MAIN_PERIPHS   = 2
);
  // Inputs
  reg clk;
  reg reset;

  // Main IC signals (drivers clusters)
  wire [NUM_CLUSTERS*BUS_WIDTH-1:0]      S_PADDR;
  wire [NUM_CLUSTERS-1:0]                S_PWRITE;
  wire [NUM_CLUSTERS-1:0]                S_PSELx;
  wire [NUM_CLUSTERS-1:0]                S_PENABLE;
  wire [NUM_CLUSTERS*DATA_WIDTH-1:0]     S_PWDATA;
  wire [NUM_CLUSTERS*DATA_WIDTH-1:0]     S_PRDATA;
  wire [NUM_CLUSTERS-1:0]                S_PREADY;
  // Main IC downstream
  wire [BUS_WIDTH-1:0]                   M_PADDR;
  wire [0:0]                             M_PWRITE;
  wire [NUM_MAIN_PERIPHS-1:0]            M_PSELx;
  wire [0:0]                             M_PENABLE;
  wire [DATA_WIDTH-1:0]                  M_PWDATA;
  wire [NUM_MAIN_PERIPHS*DATA_WIDTH-1:0] M_PRDATA; // from model
  wire [NUM_MAIN_PERIPHS-1:0]            M_PREADY; // from model

  apb_intercon_s # (
    .BUS_WIDTH          (BUS_WIDTH),
    .DATA_WIDTH         (DATA_WIDTH),
    .MASTER_PORTS       (NUM_CLUSTERS),
    .SLAVE_PORTS        (NUM_MAIN_PERIPHS),
    .ADDR_MSB           (12),
    .ADDR_LSB           (12)
  ) main_ic (
    .clk                (clk),
    .reset              (reset),
    .S_PADDR            (S_PADDR),
    .S_PWRITE           (S_PWRITE),
    .S_PSELx            (S_PSELx),
    .S_PENABLE          (S_PENABLE),
    .S_PWDATA           (S_PWDATA),
    .S_PRDATA           (S_PRDATA),
    .S_PREADY           (S_PREADY),

    // model peripheral
    .M_PADDR            (M_PADDR),
    .M_PWRITE           (M_PWRITE),
    .M_PSELx            (M_PSELx),
    .M_PENABLE          (M_PENABLE),
    .M_PWDATA           (M_PWDATA),
    .M_PRDATA           (M_PRDATA),
    .M_PREADY           (M_PREADY)
  );

  vmicro16_periph_sect # (
    .MASTERS            (1),
    .SLAVES             (8),
    .ADDR_MSB           (7),
    .ADDR_LSB           (4)
  ) periphs_sub_ic (
    .clk                (clk),
    .reset              (reset),
    .S_PADDR            (M_PADDR),
    .S_PWRITE           (M_PWRITE),
    .S_PSELx            (M_PSELx[0]),
    .S_PENABLE          (M_PENABLE),
    .S_PWDATA           (M_PWDATA),
    .S_PRDATA           (M_PRDATA[0*DATA_WIDTH +: DATA_WIDTH]),
    .S_PREADY           (M_PREADY[0])
  );

  // register apb test peripheral
  vmicro16_bram_apb # (
    .BUS_WIDTH         (BUS_WIDTH),
    .DATA_WIDTH        (DATA_WIDTH),
    .NAME              ("MAIN_DMEM"),
    .MEM_DEPTH         (4096)
  ) main_peripheral (
    .clk               (clk),
    .reset             (soft_reset),
    // apb slave to master interface
    .S_PADDR           (M_PADDR),
    .S_PWRITE          (M_PWRITE),
    .S_PSELx           (M_PSELx[1]),
    .S_PENABLE         (M_PENABLE),
    .S_PWDATA          (M_PWDATA),
    .S_PRDATA          (M_PRDATA[1*DATA_WIDTH +: DATA_WIDTH]),
    .S_PREADY          (M_PREADY[1])
  );

  genvar cluster;
  for (cluster = 0; cluster < NUM_CLUSTERS; cluster = cluster + 1) begin
    vmicro16_cluster # (
      .BUS_WIDTH          (BUS_WIDTH),
      .DATA_WIDTH         (DATA_WIDTH),
      .NCORES             (NUM_CLUSTERS_CORES),
      .CLUSTER_CACHE      (1),
      .CLUSTER_CACHE_WORDS(64)
    ) cluster_inst (
      .clk                (clk),
      .reset              (reset),
      .M_PADDR            (S_PADDR  [cluster*BUS_WIDTH +: BUS_WIDTH]),
      .M_PWRITE           (S_PWRITE [cluster]),
      .M_PSELx            (S_PSELx  [cluster]),
      .M_PENABLE          (S_PENABLE[cluster]),
      .M_PWDATA           (S_PWDATA [cluster*DATA_WIDTH +: DATA_WIDTH]),
      .M_PRDATA           (S_PRDATA [cluster*DATA_WIDTH +: DATA_WIDTH]),
      .M_PREADY           (S_PREADY [cluster])
    );
  end

  always #10 clk = ~clk;

  // Nanosecond time format
  initial $timeformat(-9, 0, " ns", 10);

  task apb_bfm_expect();
    input integer          who;
    input [DATA_WIDTH-1:0] expected;

    begin
      `rassert (S_PRDATA[who*DATA_WIDTH +: DATA_WIDTH] == expected);
    end
  endtask

  integer i;
  initial begin
    // Initialize Inputs
    clk   = 0;
    reset = 1;
    repeat (5) @(posedge clk);
    reset = 0;
    repeat (1) @(posedge clk);

  end
endmodule
