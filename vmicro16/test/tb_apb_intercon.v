

`timescale 1ns / 1ps

`include "../formal.v"

module tb_intercon # (
  parameter NUM_MASTERS = 4,
  parameter NUM_SLAVES  = 4,
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
  reg   [NUM_SLAVES*DATA_WIDTH-1:0]    M_PRDATA; // from model
  reg   [NUM_SLAVES-1:0]               M_PREADY; // from model

  apb_intercon_s # (
    .MASTER_PORTS       (NUM_MASTERS),
    .SLAVE_PORTS        (NUM_SLAVES),
    .ADDR_MSB           (7),
    .ADDR_LSB           (4)
  ) dut (
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

  always #10 clk = ~clk;

  // Nanosecond time format
  initial $timeformat(-9, 0, " ns", 10);

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

    S_PADDR[2*BUS_WIDTH +: BUS_WIDTH] = 16'h0025;
    S_PSELx[2]                        = 1'b1;
    S_PENABLE[2]                      = 1'b1;

  end
endmodule
