// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
//`define FAST_FLASH


// 对于apb，读写之前的penable必须先置为0,也就是一个建立时间
// 所以对于apb协议,需要两个周期进行访问.
`define SPI_RX_0                0
`define SPI_RX_1                1
`define SPI_RX_2                2
`define SPI_RX_3                3
`define SPI_TX_0                0
`define SPI_TX_1                1
`define SPI_TX_2                2
`define SPI_TX_3                3
`define SPI_CTRL                4
`define SPI_DEVIDE              5
`define SPI_SS                  6

module spi_top_apb #(
  parameter SPI_BASE_ADDR    = 32'h10001000,  // SPI寄存器基地址
  parameter SPI_ADDR_MASK    = 32'hFFFFF000,  // SPI地址掩码（4KB空间）
  parameter flash_addr_start = 32'h30000000,
  parameter flash_addr_end   = 32'h3fffffff,
  parameter spi_ss_num       = 8
) (
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else

  // TODO：加入XIP模式
  // ------------------- 内部信号定义 -------------------
  wire        spi_master_psel;
  wire [31:0] apb_paddr;
  wire        apb_psel;
  wire        apb_penable;
  wire [ 2:0] apb_pprot;
  wire        apb_pwrite;
  wire [31:0] apb_pwdata;
  wire [ 3:0] apb_pstrb;
  wire        apb_pready;
  wire [31:0] apb_prdata;
  wire        apb_pslverr;
  wire        flash_xip_sel;  //sel xip
  reg  [31:0] flash_xip_paddr;
  reg         flash_xip_psel;  // to apb
  reg         flash_xip_penable;
  wire [ 2:0] flash_xip_pprot;
  reg         flash_xip_pwrite;
  reg  [31:0] flash_xip_pwdata;
  wire [ 3:0] flash_xip_pstrb;
  reg         flash_xip_pready;
  reg  [31:0] flash_xip_prdata;
  wire        flash_xip_pslverr;

  wire        spi_ctrl_ass;
  wire        spi_ctrl_ie;
  wire [ 7:0] spi_ctrl_char_len;
  wire        spi_ctrl_tx_neg;
  wire        spi_ctrl_rx_neg;
  wire        spi_ctrl_lsb;
  wire [31:0] spi_ctrl_data;
  wire        spi_ctrl_go_busy;

  reg  [3:0] flash_xip_state;

  assign spi_master_psel    = (in_paddr[31:12] == 20'h10001) && in_psel;
  assign flash_xip_sel      = (in_paddr[31:28] == 4'h3) && in_psel;
  assign apb_paddr          = spi_master_psel ? in_paddr : flash_xip_sel ? flash_xip_paddr : 32'b0;
  assign apb_psel           = spi_master_psel | flash_xip_psel;
  assign apb_penable        = spi_master_psel ? in_penable : flash_xip_sel ? flash_xip_penable : 1'b0;
  assign apb_pprot          = spi_master_psel ? in_pprot : flash_xip_sel ? flash_xip_pprot : 3'b0;
  assign apb_pwrite         = spi_master_psel ? in_pwrite : flash_xip_sel ? flash_xip_pwrite : 1'b0;
  assign apb_pwdata         = spi_master_psel ? in_pwdata : flash_xip_sel ? flash_xip_pwdata : 32'b0;
  assign apb_pstrb          = spi_master_psel ? in_pstrb : flash_xip_sel ? flash_xip_pstrb : 4'b0;
  assign in_pready          = spi_master_psel ? apb_pready : flash_xip_sel ? flash_xip_pready : 1'b0;
  assign in_prdata          = spi_master_psel ? apb_prdata : flash_xip_sel ? flash_xip_prdata : 32'b0;
  assign in_pslverr         = spi_master_psel ? apb_pslverr : flash_xip_sel ? flash_xip_pslverr : 1'b0;

  assign flash_xip_pstrb    = (flash_xip_psel == 1'b1 && apb_pwrite == 1'b1)? 4'b1111 : 4'b0;    // 读取的时候必须为0
  assign flash_xip_pprot    = 3'b001;
  assign flash_xip_pslverr  = 1'b0;


  assign spi_ctrl_ass       = 1'b1;
  assign spi_ctrl_ie        = 1'b1;
  assign spi_ctrl_char_len  = 8'd64;
  assign spi_ctrl_tx_neg    = 1'b1;
  assign spi_ctrl_rx_neg    = 1'b0;
  assign spi_ctrl_lsb       = 1'b0;

  // TODO：go_busy位现在有点问题
  // go_busy位传输开始置为1,结束就清零
  assign spi_ctrl_go_busy = (flash_xip_state == SEND_CMD) && flash_xip_penable && apb_pready;

  assign spi_ctrl_data = {
    18'b0,
    spi_ctrl_ass,
    spi_ctrl_ie,
    spi_ctrl_lsb,
    spi_ctrl_tx_neg,
    spi_ctrl_rx_neg,
    spi_ctrl_go_busy,
    spi_ctrl_char_len
  };

spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(apb_paddr[4:0]),
  .wb_dat_i(apb_pwdata),
  .wb_dat_o(apb_prdata),
  .wb_sel_i(apb_pstrb),
  .wb_we_i (apb_pwrite),
  .wb_stb_i(apb_psel),
  .wb_cyc_i(apb_penable),
  .wb_ack_o(apb_pready),
  .wb_err_o(apb_pslverr),
  .wb_int_o(spi_irq_out),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

  // 状态机状态定义
  localparam INIT_DIV_SET = 4'b0111;  //  设置数据
  localparam IDLE         = 4'b1000;  // 发送flash读取指令的提前设置
  localparam INIT_DIV     = 4'b0000;
  localparam INIT_SS      = 4'b0001;
  localparam INIT_CTRL    = 4'b0010;
  localparam SEND_CMD     = 4'b0011;
  localparam START_TRANS  = 4'b0100;
  localparam WAIT_TRANS   = 4'b0101;
  localparam READ_DATA    = 4'b0110;

  reg flag = 0;

  // ------------------- XIP模式状态机 -------------------
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      flash_xip_state     <= INIT_DIV_SET;
      flash_xip_psel      <= 1'b0;    // 表示最开始没有选中flash作为completer
      flash_xip_pwrite    <= 1'b0;
      flash_xip_pwdata    <= 32'b0;
      flash_xip_paddr     <= 32'b0;
      flash_xip_pready    <= 1'b0;
      flash_xip_prdata    <= 32'b0;
    end else begin
      case(flash_xip_state)
        INIT_DIV_SET: begin
          flash_xip_psel        <= 1'b1;
          flash_xip_pwrite      <= 1'b1;
          flash_xip_pwdata      <= 50000000 / (2 * 2500000) - 1;
          flash_xip_paddr       <= (`SPI_DEVIDE << 2);
          flash_xip_state       <= INIT_DIV;
        end

        // 设置除数寄存器
        INIT_DIV:begin
          flash_xip_penable     <= 1'b1;
          // 当penable和pready同时为1时，表示是最后一个传输周期
          if(flash_xip_penable == 1'b1 && apb_pready == 1'b1)begin
            flash_xip_penable   <= 1'b0;
            flash_xip_state     <= INIT_SS;

            // 下一个状态的数据，提前设置
            flash_xip_pwdata    <= 32'b1;
            flash_xip_paddr     <= (`SPI_SS << 2);
          end
        end

        // 写SS寄存器，选择不同的Slave
        INIT_SS: begin
          flash_xip_penable     <= 1'b1;
          if(flash_xip_penable == 1'b1 && apb_pready == 1'b1)begin
            flash_xip_penable   <= 1'b0;
            flash_xip_state     <= INIT_CTRL;

            // 下一个状态的数据，提前设置
            flash_xip_pwdata    <= spi_ctrl_data;
            flash_xip_paddr     <= (`SPI_CTRL << 2);
          end
        end

        // 写CTRL寄存器
        INIT_CTRL: begin
          flash_xip_penable     <= 1'b1;
          if(flash_xip_penable == 1'b1 && apb_pready == 1'b1)begin
            flash_xip_psel      <= 1'b0;
            flash_xip_penable   <= 1'b0;
            flash_xip_pwrite    <= 1'b0;
            flash_xip_state     <= IDLE;
          end
        end

        IDLE: begin
          if(in_penable == 1'b1 && flash_xip_pready == 1'b1)begin
            flash_xip_pready    <= 1'b0;
            flash_xip_prdata    <= 32'b0;
          end else if(flash_xip_sel == 1'b1 && in_penable == 1'b1)begin
            flash_xip_psel      <= 1'b1;
            flash_xip_pwrite    <= 1'b1;
            // flash_xip_pwdata    <= {8'h3, in_paddr[23:2], 2'b0};
            flash_xip_pwdata    <= {8'h03, in_paddr[23:0]};
            flash_xip_paddr     <= (`SPI_TX_1 << 2);  //upper 32bits
            flash_xip_state     <= SEND_CMD;
          end
        end

        // TAG：给flash发送读取指令
        SEND_CMD: begin
          flash_xip_penable     <= 1'b1;
          if(flash_xip_penable == 1'b1 && apb_pready == 1'b1)begin
            flash_xip_penable   <= 1'b0;
            flash_xip_state     <= START_TRANS;

            flash_xip_pwdata    <= spi_ctrl_data;  // start transfer
            flash_xip_paddr     <= (`SPI_CTRL << 2);
          end
        end

        // 设置CTRL的go_busy位为1,表示开始传输
        START_TRANS: begin
          flash_xip_penable     <= 1'b1;
          if (flash_xip_penable == 1'b1 && apb_pready == 1'b1) begin
            flash_xip_penable   <= 1'b0;
            flash_xip_state     <= WAIT_TRANS;

            flash_xip_pwrite    <= 1'b0;  // 表示开始读取数据
          end
        end

        // 等待go_busy位被置为0,表示传输完毕，然后重新读取数据
        WAIT_TRANS: begin
          flash_xip_penable     <= 1'b1;
          flag <= 1;
          if(flash_xip_penable == 1'b1 && apb_pready == 1'b1)begin
            flag <= 0;
            if(apb_prdata[8] == 1'b0)begin    // ctrl.go_busy == 0
              flash_xip_penable <= 1'b0;
              flash_xip_state   <= READ_DATA;

              flash_xip_paddr   <= (`SPI_RX_0 << 2);    // lower 32 bits
            end
          end
        end

        // 真实读取数据
        READ_DATA: begin
          flash_xip_penable     <= 1'b1;
          if(flash_xip_penable == 1'b1 && apb_pready == 1'b1)begin
            flash_xip_psel      <= 1'b0;
            flash_xip_pready    <= 1'b1;
            flash_xip_prdata    <= apb_prdata;
            flash_xip_state     <= IDLE;
          end
        end
        default: ;
      endcase
    end
  end



`endif // FAST_FLASH

endmodule
