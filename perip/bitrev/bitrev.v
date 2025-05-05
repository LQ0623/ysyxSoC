// 重点在于实现串行转并行
// SPI总线需要接收和发送的电平不一样
// LSB传输
module bitrev (
  input  sck,
  input  ss,    // 低电平有效
  input  mosi,
  output miso   // slave空闲时, 将MISO信号设置为高电平
);
  // assign miso = 1'b1;
  
  // 先接收数据
  reg [7:0] data_reg;
  reg [3:0] data_cnt; //  需要计数读了8个数据位
  reg       miso_reg; //  miso端口输出需要使用

  always @(negedge sck or posedge ss) begin
    if(ss)begin // 片选信号无效
      data_cnt  <= 4'b0;
    end else begin
      data_cnt  <= data_cnt + 1'b1;
    end
  end

  always @(negedge sck or posedge ss) begin
    if(ss)begin
      data_reg  <= 8'b0;
    end else if(data_cnt[3] != 1'b1)begin // 这里的计数器只用根据最高位是否为1来判断是否写入data_reg,也就是判断是否全部写入完毕
      data_reg[data_cnt[2:0]] <= mosi;
    end
  end

  always @(posedge sck or posedge ss) begin
    if(ss)begin
      miso_reg  <= 1'b1;
    end else if(data_cnt[3] != 1'b1) begin // 这里的计数器只用根据最高位是否为1来判断是否可以写入miso_reg,因为只有当计数器的最高位为1时,才表示mosi的所有的数据都已经传输完毕,可以进行翻转了
      miso_reg  <= 1'b0;
    end else begin
      miso_reg  <= data_reg[7 - data_cnt[2:0]];
    end
  end

  assign miso = miso_reg;

endmodule
