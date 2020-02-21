`timescale 1ns / 1ps

`define FORMAL

module tb_vmicro16_soc;

  // Inputs
  reg clk;
  reg reset;

  // Create clock signal
  always #10 clk = ~clk;

  // Instantiate the Unit Under Test (UUT)
  vmicro16_soc uut (
    .clk  (clk),
    .reset  (reset)
  );

  integer g;

  initial begin
    begin
      $dumpfile("tb_vmicro16_soc.vcd");
      $dumpvars(0,tb_vmicro16_soc);
    end
  end

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;

    for (g = 0; g < 10; g = g+1) begin
      $display("tb_vmicro16_soc %d", g);
    end

    // Assert reset for n clocks minumum
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    reset = 0;

    repeat (10) @(posedge clk);
    $finish;
  end
endmodule

