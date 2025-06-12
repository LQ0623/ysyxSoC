module gpio_top_apb(
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

  output [15:0] gpio_out,   // LED灯
  input  [15:0] gpio_in,    // 拨码开关
  output [7:0]  gpio_seg_0,
  output [7:0]  gpio_seg_1,
  output [7:0]  gpio_seg_2,
  output [7:0]  gpio_seg_3,
  output [7:0]  gpio_seg_4,
  output [7:0]  gpio_seg_5,
  output [7:0]  gpio_seg_6,
  output [7:0]  gpio_seg_7
);

  wire          write_en;           // 判断是否为写操作
  wire          read_en;            // 判断是否为读操作
  wire  [31:0]  write_data;         // 根据in_pstrb来选择写入的数据（可能会有掩码）
  reg   [31:0]  store_data[3:0];    // 存储写入的数据，因为有些数据需要保持，不能一闪而过
  wire  [1:0]   addr;               // 是写入哪个寄存器

  assign write_en   = in_psel & in_penable & in_pwrite;
  assign read_en    = in_psel & in_penable & !in_pwrite;
  assign addr       = in_paddr[3:2];

  assign write_data = (in_pstrb == 4'b0001) ? {24'b0, in_pwdata[7:0]} : 
                      (in_pstrb == 4'b0010) ? {16'b0, in_pwdata[15:8], 8'b0} :
                      (in_pstrb == 4'b0100) ? {8'b0, in_pwdata[23:16], 16'b0} :
                      (in_pstrb == 4'b1000) ? {in_pwdata[31:24], 24'b0} :
                      (in_pstrb == 4'b0011) ? {16'b0, in_pwdata[15:0]} : 
                      (in_pstrb == 4'b0110) ? {8'b0, in_pwdata[23:8], 8'b0} : 
                      (in_pstrb == 4'b1100) ? {in_pwdata[31:16], 16'b0} : 
                      (in_pstrb == 4'b1111) ? in_pwdata : 32'b0;

  // assign gpio_out   = (write_en == 1'b1 && in_pwrite == 1'b1) ? store_data[15:0] : 16'b0;
  assign gpio_out   = store_data[0][15:0];

  always @(posedge clock) begin
    if(reset)begin
      store_data[0]     <= 32'b0;
      store_data[1]     <= 32'b0;
      store_data[2]     <= 32'b0;
      store_data[3]     <= 32'b0;
    end else if(write_en == 1'b1 && in_pwrite == 1'b1)begin
      store_data[addr]  <= write_data;
    end
    
    store_data[1]  <= {16'b0, gpio_in};   // 拨码开关的数据
  end

  // APB总线响应
  assign in_pready = in_psel & in_penable;
  assign in_pslverr = 1'b0; // 无错误

  // 读操作
  assign in_prdata = (read_en == 1'b1) ? store_data[addr] : 32'b0;   // 这里的地址没有减去基地址


  // TAG：注释掉的数码管实例化的部分是显示输入的，下面是显示学号的
  // 实例化数码管显示模块
  // seg u_seg (
  //   // 时钟输入 (通常连接系统主时钟)
  //   .clk(clock), 
    
  //   // 数码管显示数字输入 (每管显示一个4位BCD码)
  //   .num0(store_data[2][3:0]),  // 连接到数码管0的显示数据
  //   .num1(store_data[2][7:4]),  // 连接到数码管1的显示数据
  //   .num2(store_data[2][11:8]),  // 连接到数码管2的显示数据
  //   .num3(store_data[2][15:12]),  // 连接到数码管3的显示数据
  //   .num4(store_data[2][19:16]),  // 连接到数码管4的显示数据
  //   .num5(store_data[2][23:20]),  // 连接到数码管5的显示数据
  //   .num6(store_data[2][27:24]),  // 连接到数码管6的显示数据
  //   .num7(store_data[2][31:28]),  // 连接到数码管7的显示数据
    
  //   // 数码管段选信号输出 (低电平有效，顺序为dp-g-f-e-d-c-b-a)
  //   .seg0(gpio_seg_0),  // 数码管0的段选信号
  //   .seg1(gpio_seg_1),  // 数码管1的段选信号
  //   .seg2(gpio_seg_2),  // 数码管2的段选信号
  //   .seg3(gpio_seg_3),  // 数码管3的段选信号
  //   .seg4(gpio_seg_4),  // 数码管4的段选信号
  //   .seg5(gpio_seg_5),  // 数码管5的段选信号
  //   .seg6(gpio_seg_6),  // 数码管6的段选信号
  //   .seg7(gpio_seg_7)   // 数码管7的段选信号
  // );

  // 上面是显示输入的，下面是直接显示学号
  seg u_seg (
    // 时钟输入 (通常连接系统主时钟)
    .clk(clock), 
    
    // 数码管显示数字输入 (每管显示一个4位BCD码)
    .num0(4'd6),  // 个位: 6 (BCD)
    .num1(4'd0),  // 十位: 0 (BCD)
    .num2(4'd0),  // 百位: 0 (BCD)
    .num3(4'd0),  // 千位: 0 (BCD)
    .num4(4'd1),  // 万位: 1 (BCD)
    .num5(4'd0),  // 十万位: 0 (BCD)
    .num6(4'd4),  // 百万位: 4 (BCD)
    .num7(4'd2),  // 千万位: 2 (BCD)
    
    // 数码管段选信号输出 (低电平有效，顺序为dp-g-f-e-d-c-b-a)
    .seg0(gpio_seg_0),  // 数码管0的段选信号
    .seg1(gpio_seg_1),  // 数码管1的段选信号
    .seg2(gpio_seg_2),  // 数码管2的段选信号
    .seg3(gpio_seg_3),  // 数码管3的段选信号
    .seg4(gpio_seg_4),  // 数码管4的段选信号
    .seg5(gpio_seg_5),  // 数码管5的段选信号
    .seg6(gpio_seg_6),  // 数码管6的段选信号
    .seg7(gpio_seg_7)   // 数码管7的段选信号
  );

endmodule
