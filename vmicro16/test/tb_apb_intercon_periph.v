


`timescale 1ns / 1ps

`include "../vmicro16_soc_config.v"
`include "../formal.v"

module tb_intercon_periph # (
  parameter NUM_MASTERS = 4,
  parameter NUM_SLAVES  = 2, // DMEM and PERI
  parameter BUS_WIDTH   = 16,
  parameter DATA_WIDTH  = 16
);
  // Inputs
  reg                    clk;
  reg                    reset;

  // APB master interface (from cores)
  reg      [NUM_MASTERS*BUS_WIDTH-1:0]  S_PADDR;
  reg      [NUM_MASTERS-1:0]            S_PWRITE;
  reg      [NUM_MASTERS-1:0]            S_PSELx;
  reg      [NUM_MASTERS-1:0]            S_PENABLE;
  reg      [NUM_MASTERS*DATA_WIDTH-1:0] S_PWDATA;
  wire     [NUM_MASTERS*DATA_WIDTH-1:0] S_PRDATA;
  wire     [NUM_MASTERS-1:0]            S_PREADY;

  // MASTER interface to a slave
  wire  [BUS_WIDTH-1:0]                 M_PADDR;
  wire                                  M_PWRITE;
  wire  [NUM_SLAVES-1:0]                M_PSELx;
  wire                                  M_PENABLE;
  wire  [DATA_WIDTH-1:0]                M_PWDATA;
  // inputs from each slave
  wire  [NUM_SLAVES*DATA_WIDTH-1:0]     M_PRDATA; // from model
  wire  [NUM_SLAVES-1:0]                M_PREADY; // from model

  apb_intercon_s # (
    .BUS_WIDTH          (BUS_WIDTH),
    .DATA_WIDTH         (DATA_WIDTH),
    .MASTER_PORTS       (NUM_MASTERS),
    .SLAVE_PORTS        (NUM_SLAVES),
    .ADDR_MSB           (`IC_DMEM_DEC_MSB),
    .ADDR_LSB           (`IC_DMEM_DEC_LSB)
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
    .SLAVES             (`IC_DMEM_PMEM_PSEL__NUM),
    .ADDR_MSB           (`IC_DMEM_PMEM_DEC_MSB),
    .ADDR_LSB           (`IC_DMEM_PMEM_DEC_LSB)
  ) periphs_sub_ic (
    .clk                (clk),
    .reset              (reset),
    .S_PADDR            (M_PADDR),
    .S_PWRITE           (M_PWRITE),
    .S_PSELx            (M_PSELx[`IC_DMEM_PSEL_PERI]),
    .S_PENABLE          (M_PENABLE),
    .S_PWDATA           (M_PWDATA),
    .S_PRDATA           (M_PRDATA[`IC_DMEM_PSEL_PERI*`DATA_WIDTH +: `DATA_WIDTH]),
    .S_PREADY           (M_PREADY[`IC_DMEM_PSEL_PERI])
  );

  // register apb test peripheral
  vmicro16_bram_apb # (
    .BUS_WIDTH  (`APB_WIDTH),
    .DATA_WIDTH (`DATA_WIDTH),
    .NAME       ("DMEM"),
    .MEM_DEPTH  (4096)
  ) main_peripheral (
    .clk        (clk),
    .reset      (soft_reset),
    // apb slave to master interface
    .S_PADDR    (M_PADDR),
    .S_PWRITE   (M_PWRITE),
    .S_PSELx    (M_PSELx[`IC_DMEM_PSEL_DMEM]),
    .S_PENABLE  (M_PENABLE),
    .S_PWDATA   (M_PWDATA),
    .S_PRDATA   (M_PRDATA[`IC_DMEM_PSEL_DMEM*`DATA_WIDTH +: `DATA_WIDTH]),
    .S_PREADY   (M_PREADY[`IC_DMEM_PSEL_DMEM])
  );

  always #10 clk = ~clk;

  // Nanosecond time format
  initial $timeformat(-9, 0, " ns", 10);


  // APB BFM
  task apb_bfm_send();
    input integer          who; // master model index
    input [BUS_WIDTH-1:0]  addr;
    input                  write;
    input [DATA_WIDTH-1:0] wdata;

    begin
      @(posedge clk);
      S_PADDR   [who*BUS_WIDTH +: BUS_WIDTH] = addr;
      S_PWRITE  [who] = write;
      S_PWDATA  [who*DATA_WIDTH +: DATA_WIDTH] = wdata;
      S_PSELx   [who] = 1'b1;
      @(posedge clk);
      S_PENABLE [who] = 1'b1;
      @(S_PREADY[who] == 1'b1);
      @(posedge clk);
      S_PSELx   [who] = 1'b0;
      S_PENABLE [who] = 1'b0;
    end
  endtask

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

    for (i = 0; i < NUM_MASTERS; i = i + 1) begin
      S_PADDR   [i*BUS_WIDTH +: BUS_WIDTH]   = 16'h0000;
      S_PWDATA  [i*DATA_WIDTH +: DATA_WIDTH] = 16'h0000;
      S_PWRITE  [i]                          = 1'b0;
      S_PENABLE [i]                          = 1'b0;
      S_PSELx   [i]                          = 1'b0;
    end

    repeat (5) @(posedge clk);
    reset = 0;
    repeat (1) @(posedge clk);

    apb_bfm_send(
      1,
      16'h0011,
      1'b1,
      16'h1111
    );

    repeat (5) @(posedge clk);

    apb_bfm_send(
      2,
      16'h0022,
      1'b1,
      16'h2222
    );

    apb_bfm_send(
      3,
      16'h1003,
      1'b1,
      16'h3333
    );

    apb_bfm_send(
      2,
      16'h0027,
      1'b1,
      16'h2277
    );

    apb_bfm_send(
      0,
      16'h1003,
      1'b0,
      16'h0000
    );
    `rassert (S_PRDATA[0*`DATA_WIDTH +: `DATA_WIDTH] == 16'h3333);





  end
endmodule
