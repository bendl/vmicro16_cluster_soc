
`timescale 1ns / 1ps

`include "../formal.v"

module tb_arbiter # (
  parameter NUM_MASTERS = 4
) ();

  // Inputs
  reg                    clk;
  reg                    reset;
  reg  [NUM_MASTERS-1:0] reqs;
  wire [NUM_MASTERS-1:0] grants;


  apb_ic_arbiter_v2 # (
    .NUM_MASTERS  (NUM_MASTERS)
  ) dut (
    .clk          (clk),
    .reset        (reset),
    .reqs         (reqs),
    .grants       (grants)
  );

  always #10 clk = ~clk;

  // Nanosecond time format
  initial $timeformat(-9, 0, " ns", 10);

  initial begin
    $monitor($time, " reqs=%b grants=%b", reqs, grants);

    // Initialize Inputs
    clk   = 0;
    reset = 1;
    reqs  = 4'b0000;
    repeat (5) @(posedge clk);
    `rassert (grants == 4'b0001);

    reset = 0;
    repeat (5) @(posedge clk);
    `rassert (grants == 4'b0001);

    reqs = 4'b0001;
    repeat(5) @(posedge clk);
    `rassert (grants == 4'b00001);

    reqs = 4'b0110;
    repeat (5) @(posedge clk);

    reqs = 4'b0100;
    repeat (5) @(posedge clk);

    reqs = 4'b0010;
    repeat (5) @(posedge clk);



  end
endmodule
