//
//
//

`include "vmicro16_soc_config.v"
`include "clog2.v"
`include "formal.v"

module vmicro16_periph_sect # (
  parameter MASTERS = 1,
  parameter SLAVES  = 4
) (
  input clk,
  input reset,

  // APB master interface (from cores)
  input      [MASTER_PORTS*BUS_WIDTH-1:0]  S_PADDR,
  input      [MASTER_PORTS-1:0]            S_PWRITE,
  input      [MASTER_PORTS-1:0]            S_PSELx,
  input      [MASTER_PORTS-1:0]            S_PENABLE,
  input      [MASTER_PORTS*DATA_WIDTH-1:0] S_PWDATA,
  output reg [MASTER_PORTS*DATA_WIDTH-1:0] S_PRDATA,
  output reg [MASTER_PORTS-1:0]            S_PREADY,

  // UART0
  input                           uart_rx,
  output                          uart_tx,
  //
  output [`APB_GPIO0_PINS-1:0]    gpio0,
  output [`APB_GPIO1_PINS-1:0]    gpio1,
  output [`APB_GPIO2_PINS-1:0]    gpio2,
  //
  output     [`CORES-1:0]         dbug0,
  output     [`CORES*8-1:0]       dbug1
);
  // To slave outputs
  wire [`APB_WIDTH-1:0]          ic_pmem_M_PADDR;
  wire                           ic_pmem_M_PWRITE;
  wire [SLAVES-1:0]              ic_pmem_M_PSELx;  // not shared
  wire                           ic_pmem_M_PENABLE;
  wire [`DATA_WIDTH-1:0]         ic_pmem_M_PWDATA;
  wire [SLAVES*`DATA_WIDTH-1:0]  ic_pmem_M_PRDATA; // input to intercon
  wire [SLAVES-1:0]              ic_pmem_M_PREADY; // input

  // Master drivers
  wire [MASTERS*`APB_WIDTH-1:0]   ic_pmem_W_PADDR;
  wire [MASTERS-1:0]              ic_pmem_W_PWRITE;
  wire [MASTERS-1:0]              ic_pmem_W_PSELx;
  wire [MASTERS-1:0]              ic_pmem_W_PENABLE;
  wire [MASTERS*`DATA_WIDTH-1:0]  ic_pmem_W_PWDATA;
  wire [MASTERS*`DATA_WIDTH-1:0]  ic_pmem_W_PRDATA;
  wire [MASTERS-1:0]              ic_pmem_W_PREADY;

  apb_intercon_s # (
    .MASTER_PORTS   (MASTERS),
    .SLAVE_PORTS    (SLAVES),
    .BUS_WIDTH      (`APB_WIDTH),
    .DATA_WIDTH     (`DATA_WIDTH),
    .HAS_PSELX_ADDR (1)
  ) ic_pmem (
    .clk        (clk),
    .reset      (reset),
    // APB master to slave
    .S_PADDR    (S_PADDR),
    .S_PWRITE   (S_PWRITE),
    .S_PSELx    (S_PSELx),
    .S_PENABLE  (S_PENABLE),
    .S_PWDATA   (S_PWDATA),
    .S_PRDATA   (S_PRDATA),
    .S_PREADY   (S_PREADY),
    // shared bus
    .M_PADDR    (ic_pmem_M_PADDR),
    .M_PWRITE   (ic_pmem_M_PWRITE),
    .M_PSELx    (ic_pmem_M_PSELx),
    .M_PENABLE  (ic_pmem_M_PENABLE),
    .M_PWDATA   (ic_pmem_M_PWDATA),
    .M_PRDATA   (ic_pmem_M_PRDATA),
    .M_PREADY   (ic_pmem_M_PREADY)
  );


`ifdef DEF_USE_BUS_RESET
  wire bus_reset;
  vmicro16_psel_err_apb error_apb (
    .clk        (clk),
    .reset      (),
    // apb slave to master interface
    .S_PADDR    (),
    .S_PWRITE   (),
    .S_PSELx    (ic_pmem_M_PSELx[`APB_PSELX_PERR0]),
    .S_PENABLE  (ic_pmem_M_PENABLE),
    .S_PWDATA   (),
    .S_PRDATA   (),
    .S_PREADY   (ic_pmem_M_PREADY[`APB_PSELX_PERR0]),
    // Error interrupt to reset the bus
    .err_i      (bus_reset)
  );
`endif

  vmicro16_gpio_apb # (
    .BUS_WIDTH  (`APB_WIDTH),
    .DATA_WIDTH (`DATA_WIDTH),
    .PORTS      (`APB_GPIO0_PINS),
    .NAME       ("GPIO0")
  ) gpio0_apb (
    .clk        (clk),
    .reset      (soft_reset),
    // apb slave to master interface
    .S_PADDR    (ic_pmem_M_PADDR),
    .S_PWRITE   (ic_pmem_M_PWRITE),
    .S_PSELx    (ic_pmem_M_PSELx[`APB_PSELX_GPIO0]),
    .S_PENABLE  (ic_pmem_M_PENABLE),
    .S_PWDATA   (ic_pmem_M_PWDATA),
    .S_PRDATA   (ic_pmem_M_PRDATA[`APB_PSELX_GPIO0*`DATA_WIDTH +: `DATA_WIDTH]),
    .S_PREADY   (ic_pmem_M_PREADY[`APB_PSELX_GPIO0]),
    .gpio       (gpio0)
  );

  // GPIO1 for Seven segment displays (16 pin)
  vmicro16_gpio_apb # (
    .BUS_WIDTH  (`APB_WIDTH),
    .DATA_WIDTH (`DATA_WIDTH),
    .PORTS      (`APB_GPIO1_PINS),
    .NAME       ("GPIO1")
  ) gpio1_apb (
      .clk        (clk),
      .reset      (soft_reset),
      // apb slave to master interface
      .S_PADDR    (ic_pmem_M_PADDR),
      .S_PWRITE   (ic_pmem_M_PWRITE),
      .S_PSELx    (ic_pmem_M_PSELx[`APB_PSELX_GPIO1]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[`APB_PSELX_GPIO1*`DATA_WIDTH +: `DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[`APB_PSELX_GPIO1]),
      .gpio       (gpio1)
  );

  // GPI02 for Seven segment displays (8 pin)
  vmicro16_gpio_apb # (
      .BUS_WIDTH  (`APB_WIDTH),
      .DATA_WIDTH (`DATA_WIDTH),
      .PORTS      (`APB_GPIO2_PINS),
      .NAME       ("GPI02")
  ) gpio2_apb (
      .clk        (clk),
      .reset      (soft_reset),
      // apb slave to master interface
      .S_PADDR    (ic_pmem_M_PADDR),
      .S_PWRITE   (ic_pmem_M_PWRITE),
      .S_PSELx    (ic_pmem_M_PSELx[`APB_PSELX_GPIO2]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[`APB_PSELX_GPIO2*`DATA_WIDTH +: `DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[`APB_PSELX_GPIO2]),
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
      .S_PSELx    (ic_pmem_M_PSELx[`APB_PSELX_UART0]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[`APB_PSELX_UART0*`DATA_WIDTH +: `DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[`APB_PSELX_UART0]),
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
      .S_PSELx    (ic_pmem_M_PSELx[`APB_PSELX_TIMR0]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[`APB_PSELX_TIMR0*`DATA_WIDTH +: `DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[`APB_PSELX_TIMR0])
      //
      `ifdef DEF_ENABLE_INT
      ,.out       (ints     [`DEF_INT_TIMR0]),
       .int_data  (ints_data[`DEF_INT_TIMR0*`DATA_WIDTH +: `DATA_WIDTH])
      `endif
  );

  // Shared register set for system-on-chip info
  // R0 = number of cores
  vmicro16_regs_apb # (
      .BUS_WIDTH          (`APB_WIDTH),
      .DATA_WIDTH         (`DATA_WIDTH),
      .CELL_DEPTH         (8),
      .PARAM_DEFAULTS_R0  (`CORES),
      .PARAM_DEFAULTS_R1  (`SLAVES)
  ) regs0_apb (
      .clk        (clk),
      .reset      (soft_reset),
      // apb slave to master interface
      .S_PADDR    (ic_pmem_M_PADDR),
      .S_PWRITE   (ic_pmem_M_PWRITE),
      .S_PSELx    (ic_pmem_M_PSELx[`APB_PSELX_REGS0]),
      .S_PENABLE  (ic_pmem_M_PENABLE),
      .S_PWDATA   (ic_pmem_M_PWDATA),
      .S_PRDATA   (ic_pmem_M_PRDATA[`APB_PSELX_REGS0*`DATA_WIDTH +: `DATA_WIDTH]),
      .S_PREADY   (ic_pmem_M_PREADY[`APB_PSELX_REGS0])
  );



endmodule
