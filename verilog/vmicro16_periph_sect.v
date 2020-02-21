//
//
//

`include "vmicro16_soc_config.v"
`include "clog2.v"
`include "formal.v"

module vmicro16_periph_sect # (
  parameter BUS_WIDTH = 16,
  parameter DATA_WIDTH = 16,
  parameter CORES    = 1,
  parameter SLAVES   = 8,
  parameter ADDR_MSB = 7,
  parameter ADDR_LSB = 4,
  parameter PERI_GPIO0_PINS = 8,
  parameter PERI_GPIO1_PINS = 8,
  parameter PERI_GPIO2_PINS = 8,

  parameter BUS_RESET = 1
) (
  input clk,
  input reset,

  // APB master interface (from cores)
  input      [BUS_WIDTH-1:0]  S_PADDR,
  input      [0:0]            S_PWRITE,
  input      [0:0]            S_PSELx,
  input      [0:0]            S_PENABLE,
  input      [DATA_WIDTH-1:0] S_PWDATA,
  output     [DATA_WIDTH-1:0] S_PRDATA,
  output     [0:0]            S_PREADY,

  // UART0
  input                           uart_rx,
  output                          uart_tx,
  //
  output [PERI_GPIO0_PINS-1:0]    gpio0,
  output [PERI_GPIO1_PINS-1:0]    gpio1,
  output [PERI_GPIO2_PINS-1:0]    gpio2,

  output [7:0] ints,
  output [16*8-1:0] ints_data
);
  // To slave outputs
  wire [BUS_WIDTH-1:0]           ic_pmem_M_PADDR;
  wire                           ic_pmem_M_PWRITE;
  wire [SLAVES-1:0]              ic_pmem_M_PSELx;  // not shared
  wire                           ic_pmem_M_PENABLE;
  wire [DATA_WIDTH-1:0]          ic_pmem_M_PWDATA;
  wire [SLAVES*DATA_WIDTH-1:0]   ic_pmem_M_PRDATA; // input to intercon
  wire [SLAVES-1:0]              ic_pmem_M_PREADY; // input

  apb_intercon_s # (
    .MASTER_PORTS   (1),
    .SLAVE_PORTS    (SLAVES),
    .BUS_WIDTH      (BUS_WIDTH),
    .DATA_WIDTH     (DATA_WIDTH),
    .ADDR_MSB       (ADDR_MSB),
    .ADDR_LSB       (ADDR_LSB)
  ) ic_pmem (
    .clk            (clk),
    .reset          (reset),
    // APB master to slave
    .S_PADDR        (S_PADDR),
    .S_PWRITE       (S_PWRITE),
    .S_PSELx        (S_PSELx),
    .S_PENABLE      (S_PENABLE),
    .S_PWDATA       (S_PWDATA),
    .S_PRDATA       (S_PRDATA),
    .S_PREADY       (S_PREADY),
    // shared bus
    .M_PADDR        (ic_pmem_M_PADDR),
    .M_PWRITE       (ic_pmem_M_PWRITE),
    .M_PSELx        (ic_pmem_M_PSELx),
    .M_PENABLE      (ic_pmem_M_PENABLE),
    .M_PWDATA       (ic_pmem_M_PWDATA),
    .M_PRDATA       (ic_pmem_M_PRDATA),
    .M_PREADY       (ic_pmem_M_PREADY)
  );

  generate
    if (BUS_RESET) begin
      wire bus_reset;
      vmicro16_psel_err_apb error_apb (
        .clk        (clk),
        .reset      (),
        // apb slave to master interface
        .S_PADDR    (),
        .S_PWRITE   (),
        .S_PSELx    (ic_pmem_M_PSELx[7]),
        .S_PENABLE  (ic_pmem_M_PENABLE),
        .S_PWDATA   (),
        .S_PRDATA   (),
        .S_PREADY   (ic_pmem_M_PREADY[7]),
        // Error interrupt to reset the bus
        .err_i      (bus_reset)
      );
    end
  endgenerate

  vmicro16_gpio_apb # (
    .BUS_WIDTH  (BUS_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .PORTS      (PERI_GPIO0_PINS),
    .NAME       ("GPIO0")
  ) gpio0_apb (
    .clk        (clk),
    .reset      (soft_reset),
    // apb slave to master interface
    .S_PADDR    (ic_pmem_M_PADDR),
    .S_PWRITE   (ic_pmem_M_PWRITE),
    .S_PSELx    (ic_pmem_M_PSELx[0]),
    .S_PENABLE  (ic_pmem_M_PENABLE),
    .S_PWDATA   (ic_pmem_M_PWDATA),
    .S_PRDATA   (ic_pmem_M_PRDATA[0*DATA_WIDTH +: DATA_WIDTH]),
    .S_PREADY   (ic_pmem_M_PREADY[0]),
    .gpio       (gpio0)
  );

  // GPIO1 for Seven segment displays (16 pin)
  vmicro16_gpio_apb # (
    .BUS_WIDTH  (BUS_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .PORTS      (PERI_GPIO1_PINS),
    .NAME       ("GPIO1")
  ) gpio1_apb (
      .clk        (clk),
      .reset      (soft_reset),
      // apb slave to master interface
      .S_PADDR    (ic_pmem_M_PADDR),
      .S_PWRITE   (ic_pmem_M_PWRITE),
      .S_PSELx    (ic_pmem_M_PSELx[1]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[1*DATA_WIDTH +: DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[1]),
      .gpio       (gpio1)
  );

  // GPI02 for Seven segment displays (8 pin)
  vmicro16_gpio_apb # (
      .BUS_WIDTH  (BUS_WIDTH),
      .DATA_WIDTH (DATA_WIDTH),
      .PORTS      (PERI_GPIO2_PINS),
      .NAME       ("GPI02")
  ) gpio2_apb (
      .clk        (clk),
      .reset      (soft_reset),
      // apb slave to master interface
      .S_PADDR    (ic_pmem_M_PADDR),
      .S_PWRITE   (ic_pmem_M_PWRITE),
      .S_PSELx    (ic_pmem_M_PSELx[2]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[2*DATA_WIDTH +: DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[2]),
      .gpio       (gpio2)
  );

  apb_uart_tx # (
      .DATA_WIDTH (8),
      .ADDR_EXP   (4) //2^^4 = 16 FIFO words
  ) uart0_apb (
      .clk        (clk),
      .reset      (soft_reset),
      // apb slave to master interface
      .S_PADDR    (ic_pmem_M_PADDR),
      .S_PWRITE   (ic_pmem_M_PWRITE),
      .S_PSELx    (ic_pmem_M_PSELx[3]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[3*DATA_WIDTH +: DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[3]),
      // uart wires
      .tx_wire    (uart_tx),
      .rx_wire    ()
  );

  timer_apb timr0 (
      .clk        (clk),
      .reset      (soft_reset),
      // apb slave to master interface
      .S_PADDR    (ic_pmem_M_PADDR),
      .S_PWRITE   (ic_pmem_M_PWRITE),
      .S_PSELx    (ic_pmem_M_PSELx[5]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[5*DATA_WIDTH +: DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[5]),
      //
      .out       (ints     [0]),
      .int_data  (ints_data[0*DATA_WIDTH +: DATA_WIDTH])
  );

  // Shared register set for system-on-chip info
  // R0 = number of cores
  vmicro16_regs_apb # (
      .BUS_WIDTH          (BUS_WIDTH),
      .DATA_WIDTH         (DATA_WIDTH),
      .CELL_DEPTH         (8),
      .PARAM_DEFAULTS_R0  (CORES),
      .PARAM_DEFAULTS_R1  (SLAVES)
  ) regs0_apb (
      .clk        (clk),
      .reset      (soft_reset),
      // apb slave to master interface
      .S_PADDR    (ic_pmem_M_PADDR),
      .S_PWRITE   (ic_pmem_M_PWRITE),
      .S_PSELx    (ic_pmem_M_PSELx[4]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[4*DATA_WIDTH +: DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[4])
  );

endmodule


