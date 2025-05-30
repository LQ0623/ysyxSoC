// 32M的MT48LC16M16A2颗粒，一次读取32bit
module sdram_32mX32(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,
  input [ 1:0] ba,
  input [ 3:0] dqm,
  inout [31:0] dq,
  input [1:0]  id
);

  sdram_32mX16 u0_sdram_32mX16
  (
    .clk  (clk),   // SDRAM时钟（需与控制器相位对齐）
    .cke  (cke),   // 时钟使能
    .cs   (cs),    // 片选（低有效）
    .ras  (ras),   // 行地址选通
    .cas  (cas),   // 列地址选通
    .we   (we),    // 写使能
    .a    (a),  // 地址总线 [12:0]
    .ba   (ba),    // Bank地址 [1:0]
    .dqm  (dqm[1:0]),   // 数据掩码 [1:0]
    .dq   (dq[15:0]),     // 双向数据总线 [15:0]
    .id   (id)          // 表示使用的SDRAM的颗粒属于哪一个chip
  );

  sdram_32mX16 u1_sdram_32mX16
  (
    .clk  (clk),   // SDRAM时钟（需与控制器相位对齐）
    .cke  (cke),   // 时钟使能
    .cs   (cs),    // 片选（低有效）
    .ras  (ras),   // 行地址选通
    .cas  (cas),   // 列地址选通
    .we   (we),    // 写使能
    .a    (a),  // 地址总线 [12:0]
    .ba   (ba),    // Bank地址 [1:0]
    .dqm  (dqm[3:2]),   // 数据掩码 [1:0]
    .dq   (dq[31:16]),     // 双向数据总线 [15:0]
    .id   (id + 1'b1)          // 表示使用的SDRAM的颗粒属于哪一个chip
  );

endmodule