// 将PSRAM的实际存放位置放在C代码中，通过DPI-C进行调用
// 可以参考flash进行实现
// inout的处理可以参考psram_top_apb的实现，用一个信号来接dio当作输入端
module psram(
  input sck,
  input ce_n,   // ce_n的含义与SPI总线协议中的SS相同, 低电平有效
  inout [3:0] dio
);

  // assign dio = 4'bz;
  typedef enum [2:0] { 
    STANDBY,      // 待机状态
    CMD_PHASE, 
    ADDR_PHASE, 
    DUMMY_CYCLES, 
    DATA_PHASE, 
    WRITE_PHASE,
    ERR_T
  } state_t;

  reg [2:0]   state;
  reg [3:0]   counter;    // 用来计数使用
  reg [7:0]   cmd;        // 传入的指令
  reg [23:0]  addr;
  wire[3:0]   dio_input;  // 用于锁存输入数据
  wire[3:0]   dio_drive;  // 用于存储需要输出的数据
  reg         dio_oe;     // 判断dio是用于输出还是输入

  wire        r_valid;    // 读操作是否有效
  wire        w_valid;    // 写操作是否有效
  wire [31:0] rdata;
  wire [31:0] wdata;
  wire [3:0]  wstrb;

  // 判断是否进入QPI模式
  reg         QPI_MODE  = 0;    // TAG：这里的QPI_MODE的赋值方式后续看能不能改变一下，不可能就这样给个初值
  always @(posedge ce_n) begin
    if(cmd == 8'h35)begin
      QPI_MODE    <= 1'b1;
    end
  end


  // 输入数据锁存
  assign dio_input = dio; //  直接锁存，别管上升沿还是下降沿，一改变就变化


  assign dio        = dio_oe ? dio_drive : 4'bz;

  // 写数据是靠冲刷进去的
  assign r_valid = (state == DUMMY_CYCLES && counter == 0);
  assign w_valid = (state == WRITE_PHASE);

  psram_cmd psram_cmd_i (
    .clock(sck),
    .ce_n(ce_n),
    .r_valid(r_valid),
    .w_valid(w_valid),
    .cmd(cmd),
    .addr({8'b0,addr}),
    .wstrb(wstrb),    // 32-bit write data
    .wdata(wdata),    // 4-bit write strobe
    .rdata(rdata)     // 32-bit read data
  );

  //----------------------------------------------------------
  // 主状态机（上升沿触发状态迁移）
  //----------------------------------------------------------
  always @(posedge sck or posedge ce_n) begin
    if(ce_n) begin
      state     <= CMD_PHASE;
      dio_oe    <= 1'b0;
    end else begin
      case(state)
        CMD_PHASE: begin
          // if(counter == 4'd7)begin
          //   state   <= ADDR_PHASE;
          // end
          if(QPI_MODE == 1)begin
            // QPI模式下传输指令只需要两个周期
            if(counter == 4'd1)begin
              state   <= ADDR_PHASE;
            end
          end else begin
            if(counter == 4'd7)begin
              state   <= ADDR_PHASE;
            end
          end
        end

        ADDR_PHASE: begin
          // $display("cmd is %xh",cmd);
          if(counter == 4'd5)begin
            state   <= (cmd == 8'hEB) ? DUMMY_CYCLES : ( (cmd == 8'h38) ? WRITE_PHASE : ERR_T);
          end
        end

        DUMMY_CYCLES: begin //  读延时
          if(counter == 4'd6)begin
            dio_oe  <= 1'b1;
            state   <= DATA_PHASE;
          end
        end

        DATA_PHASE: begin
          // dio_oe等ce_n置为高时就会自动的变为0
          state   <= state;
        end

        WRITE_PHASE: begin
          // dio_oe等ce_n置为高时就会自动的变为0
          state   <= state;
        end
        ERR_T: begin
          state <= state;
          $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh`, only support `EBh,38H` read command\n", cmd);
          $fatal;
        end
        default:begin
          state <= state;
          $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh`, only support `EBh,38H` read command\n", cmd);
          $fatal;
        end
      endcase
    end
  end

  //----------------------------------------------------------
  // 计数器逻辑（上升沿更新）
  //----------------------------------------------------------
  always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      counter   <= 4'b0;
    end else begin
      case(state)
        // CMD_PHASE:    counter   <= (counter < 7)  ? counter + 1 : 4'b0;
        CMD_PHASE:    counter   <= (QPI_MODE == 1) ? ((counter < 1)  ? counter + 1 : 4'b0) : ((counter < 7)  ? counter + 1 : 4'b0); // QPI模式下只需要两个周期传输指令
        ADDR_PHASE:   counter   <= (counter < 5)  ? counter + 1 : 4'b0;
        DUMMY_CYCLES: counter   <= (counter < 6)  ? counter + 1 : 4'b0;
        DATA_PHASE:   counter   <= counter + 1;
        WRITE_PHASE:  counter   <= counter + 1;
        default:      counter   <= 0;
      endcase
    end
  end

  //----------------------------------------------------------
  // 命令接收（下降沿锁存的输入）
  //----------------------------------------------------------
  always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      cmd   <= 8'b0;
    end else if(state == CMD_PHASE) begin
      // cmd   <= {cmd[6:0],dio_input[0]};   // QSPI模式使用SIO0来传输指令
      if(QPI_MODE == 1)begin
        cmd   <= {cmd[3:0], dio_input[3:0]};   // QPI模式使用SIO0_3来传输指令
      end else begin
        cmd   <= {cmd[6:0],dio_input[0]};   // QSPI模式使用SIO0来传输指令
      end
    end
  end

  //----------------------------------------------------------
  // 地址接收（下降沿锁存的输入）
  //----------------------------------------------------------
  always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      addr  <= 24'b0;
    end else if (state == ADDR_PHASE)
      addr  <= {addr[19:0], dio_input}; // 四线并行输入
  end

  //----------------------------------------------------------
  // 数据输出（上升沿更新）
  //----------------------------------------------------------
  reg [31:0] data;
  wire [31:0] data_bswap = {rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]};
  always@(posedge sck or posedge ce_n) begin
    if (ce_n) data <= 32'd0;
    else if (state == DATA_PHASE) begin
      // 刚开始传输的时候，这里起始就已经将data_bswap赋值给了data变量，然后后续的输出的就是交换了字节序的值
      data <= { {counter == 4'd0 ? data_bswap : data}[27:0], 4'b0000 };
    end
  end
  assign dio_drive = {(state == DATA_PHASE && counter == 4'b0) ? data_bswap : data}[31:28];

  //----------------------------------------------------------
  // 写数据采集（上升沿锁存输入）
  //----------------------------------------------------------
  reg [31:0] write_buffer;
  always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      write_buffer  <= 32'b0;
    end else if (state == WRITE_PHASE) begin
      write_buffer  <= {write_buffer[27:0], dio_input};
    end
  end

  // 写入数据时的字节掩码
  assign wstrb =  (counter == 4'd2) ? 4'b0001 :           // 1字节
                  (counter == 4'd4) ? 4'b0011 :           // 2字节
                  (counter == 4'd8) ? 4'b1111 : 4'b1111;  // 4字节

  // 需要切换大小端序
  // assign wdata = {write_buffer[7:0], write_buffer[15:8], write_buffer[23:16], write_buffer[31:24]};
  assign wdata =  (counter == 4'd2) ? {24'b0,write_buffer[7:0]} :         // 1字节
                  (counter == 4'd4) ? {16'b0,write_buffer[7:0], write_buffer[15:8]} :         // 2字节
                  (counter == 4'd8) ? {write_buffer[7:0], write_buffer[15:8], write_buffer[23:16], write_buffer[31:24]} : 32'b0;  // 4字节


endmodule

import "DPI-C" function void psram_read(input int addr, output int data);
import "DPI-C" function void psram_write(input int addr, input int data, input int wstrb);

module psram_cmd(
  input             clock,
  input             ce_n,
  input             w_valid,
  input             r_valid,
  input       [7:0] cmd,
  input      [31:0] addr,
  input       [3:0] wstrb,
  input      [31:0] wdata,
  output reg [31:0] rdata
);

  // TAG:读和写不能使用同一个always块，因为写需要是ce_n上升沿的时候写入，表示所有的需要数据都已经完成了读取
  // 如果使用时钟上升沿的话，就需要冲刷的写入，而且写入的数据还不一定是正确的，因为可能在最后一个或者半个时钟周期内还有数据，只能等ce_n置高（表示这次传输结束）的时候写，这时候就没有数据会传输了

  always@(posedge clock) begin
    if (r_valid)begin
      case (cmd)
        8'hEB: psram_read(addr, rdata);
        default:begin
          $fwrite(32'h80000002, "Assertion failed: Unsupport command `%xh`, only support `EBh` read command and support `38h` write command\n", cmd);
          $fatal;
        end
      endcase
    end
  end
    
  always@(posedge ce_n) begin
    if (w_valid)begin
      case (cmd)
        8'h38: psram_write(addr, wdata, {28'b0,wstrb});
        default:begin
          $fwrite(32'h80000002, "Assertion failed: Unsupport command `%xh`, only support `EBh` read command and support `38h` write command\n", cmd);
          $fatal;
        end
      endcase
    end
  end


endmodule