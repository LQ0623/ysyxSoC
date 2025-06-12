module vga_top_apb(
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

  output [7:0]  vga_r,
  output [7:0]  vga_g,
  output [7:0]  vga_b,
  output        vga_hsync,
  output        vga_vsync,
  output        vga_valid
);

  // 定义VGA时序参数（640x480@60Hz）
  // 行像素
  parameter h_frontporch = 96;
  parameter h_active     = 144;
  parameter h_backporch  = 784;
  parameter h_total      = 800;

  // 一帧的像素
  parameter v_frontporch = 2;
  parameter v_active     = 35;
  parameter v_backporch  = 515;
  parameter v_total      = 525;

  // 帧缓冲存储器（19位地址，32位数据，一共512KB）
  localparam N = 19;
  reg [31:0] frame_buffer[0 : (1 << N) - 1];   // 2 ^ 19 = 524288个条目

  // APB接口信号
  assign in_pready  = (in_psel == 1'b1 && in_penable == 1'b1);
  assign in_prdata  = 32'b0;
  assign in_pslverr = 1'b0;

  // APB 总线处理
  always @(posedge clock) begin
    if(in_psel == 1'b1 && in_penable == 1'b1 && in_pwrite == 1'b1)begin
      // 字节使能写入处理
      if (in_pstrb[0]) frame_buffer[in_paddr[20:2]][7:0]   <= in_pwdata[7:0];
      if (in_pstrb[1]) frame_buffer[in_paddr[20:2]][15:8]  <= in_pwdata[15:8];
      if (in_pstrb[2]) frame_buffer[in_paddr[20:2]][23:16] <= in_pwdata[23:16];
      if (in_pstrb[3]) frame_buffer[in_paddr[20:2]][31:24] <= in_pwdata[31:24];
    end
  end

  // vga 计数器
  // 像素计数值
  reg [9:0]    x_cnt;
  reg [9:0]    y_cnt;
  wire         h_valid;
  wire         v_valid;
  
  // 行像素计数
  always @(posedge clock) begin
    if(reset)begin
      x_cnt   <= 10'b1;
    end else begin
      if(x_cnt == h_total)begin
        x_cnt <= 10'b1;
      end else begin
        x_cnt <= x_cnt + 10'd1;
      end
    end
  end

  // 列像素计数
  always @(posedge clock) begin
    if(reset)begin
      y_cnt   <= 10'b1;
    end else begin
      if(y_cnt == v_total && x_cnt == h_total)begin
        y_cnt <= 10'b1;
      end else if(x_cnt == h_total)begin
        y_cnt <= y_cnt + 10'd1;
      end
    end
  end

  // 同步信号生成
  assign vga_hsync = (x_cnt > h_frontporch);  // 水平同步（低电平有效）
  assign vga_vsync = (y_cnt > v_frontporch);  // 垂直同步（低电平有效）

  // 有效区域判断
  assign h_valid    = (x_cnt > h_active) && (x_cnt <= h_backporch);
  assign v_valid    = (y_cnt > v_active) && (y_cnt <= v_backporch);
  assign vga_valid  = h_valid && v_valid;  // 有效像素区域

  // 像素地址计算
  wire [9:0] h_addr,v_addr;
  assign h_addr     = h_valid ? (x_cnt - 10'd145) : 10'd0;  // 水平像素坐标
  assign v_addr     = v_valid ? (y_cnt - 10'd36)  : 10'd0;  // 垂直像素坐标

  // 帧缓冲地址计算（优化乘法为移位加法）
  wire [18:0] pixel_addr;
  assign pixel_addr  = 
                      ({9'b0, v_addr} << 9) +  // v_addr * 512
                      ({9'b0, v_addr} << 7) +  // v_addr * 128 (总计 512+128=640)
                      {9'b0, h_addr};          // 加上水平偏移

  // 从帧缓冲读取像素数据
  wire [31:0] pixel_data;
  assign pixel_data   = frame_buffer[pixel_addr];

  // VGA输出（有效区域输出像素，非有效区域输出黑色）
  assign {vga_r, vga_g, vga_b} = vga_valid ? pixel_data[23:0] : 24'h0;

endmodule
