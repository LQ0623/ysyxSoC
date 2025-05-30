module sdram(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [13:0] a,
  input [ 1:0] ba,
  input [ 3:0] dqm,
  inout [31:0] dq
);

  wire [2:0] command;
  reg ras_u0 ;
  reg cas_u0 ;
  reg we_u0  ;
  reg ras_u1 ;
  reg cas_u1 ;
  reg we_u1  ;

  assign command = {ras,cas,we};

  always @(*) begin
    case(command)
      // NOP指令或者设置Mode寄存器的指令
      3'b000,3'b111:begin
        {ras_u0,cas_u0,we_u0} = command;
        {ras_u1,cas_u1,we_u1} = command;
      end
      default:begin
        // a的最高位为0选择u0，为1选择u1
        {ras_u0,cas_u0,we_u0} = !a[13] ? command : 3'b111;
        {ras_u1,cas_u1,we_u1} =  a[13] ? command : 3'b111;
      end
    endcase
  end


  sdram_32mX32 u0_sdram_32mX32
  (
    .clk  (clk),   // SDRAM时钟（需与控制器相位对齐）
    .cke  (cke),   // 时钟使能
    .cs   (cs),    // 片选（低有效）
    .ras  (ras_u0),   // 行地址选通
    .cas  (cas_u0),   // 列地址选通
    .we   (we_u0),    // 写使能
    .a    (a[12:0]),  // 地址总线 [12:0]
    .ba   (ba),    // Bank地址 [1:0]
    .dqm  (dqm),   // 数据掩码 [1:0]
    .dq   (dq),     // 双向数据总线 [15:0]
    .id   (0)              // 确定这个sdram需要访问的是哪几个chip
  );

  sdram_32mX32 u1_sdram_32mX32
  (
    .clk  (clk),   // SDRAM时钟（需与控制器相位对齐）
    .cke  (cke),   // 时钟使能
    .cs   (cs),    // 片选（低有效）
    .ras  (ras_u1),   // 行地址选通
    .cas  (cas_u1),   // 列地址选通
    .we   (we_u1),    // 写使能
    .a    (a[12:0]),  // 地址总线 [12:0]
    .ba   (ba),    // Bank地址 [1:0]
    .dqm  (dqm),   // 数据掩码 [1:0]
    .dq   (dq),     // 双向数据总线 [15:0]
    .id   (2)              // 确定这个sdram需要访问的是哪几个chip
  );

endmodule