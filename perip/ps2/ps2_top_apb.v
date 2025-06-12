module ps2_top_apb(
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

  input         ps2_clk,
  input         ps2_data
);

  // ps2_clk为低电平的时候禁止通信
  // 检测低电平到高电平转换，打两拍，跨时钟域避免亚稳态问题
  reg [2:0] ps2_clk_sync;
  always @(posedge clock) begin
    ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
  end

  wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

  reg [9:0] buffer;         // ps2_data bits
  reg [3:0] count;          // count ps2_data bits
  reg [7:0] fifo[7:0];      // data fifo
  reg [2:0] w_ptr,r_ptr;    // fifo write and read pointers
  reg is_empty;             // fifo是否为空

  parameter IDLE = 0,
            READ = 1;
  reg state;

  always @(posedge clock) begin
    if(reset)begin
      state   <= IDLE;
    end else begin
      case (state)
        IDLE : begin
          // 不能在写入的时候读取
          if(in_psel == 1'b1 && in_penable == 1'b1 && in_pwrite == 1'b0)begin
            state <= READ;
          end
        end
        READ : begin
          state   <= IDLE;
        end
      endcase
    end
  end

  always @(posedge clock) begin
    if(reset)begin
      buffer    <= 10'b0;
      count     <= 4'b0;
      w_ptr     <= 3'b0;
      r_ptr     <= 3'b0;
      is_empty  <= 1'b1;
      fifo[0]   <= 8'b0;
      fifo[1]   <= 8'b0;
      fifo[2]   <= 8'b0;
      fifo[3]   <= 8'b0;
      fifo[4]   <= 8'b0;
      fifo[5]   <= 8'b0;
      fifo[6]   <= 8'b0;
      fifo[7]   <= 8'b0;
    end
    else begin
      if(sampling)begin
        if(count == 4'd10)begin
          if((buffer[0] == 0) &&            // start bit
            (ps2_data)      &&              // stop bit
            (^buffer[9:1])) begin           // odd  parity
              // $display("receive %x", buffer[8:1]);
              fifo[w_ptr] <= buffer[8:1];   // kbd scan code
              w_ptr       <= w_ptr + 3'b1;
              is_empty    <= 1'b0;
            end
            count         <= 4'b0;
        end
        else begin
          buffer[count]     <= ps2_data;    // store ps2_data
          count             <= count + 3'b1;
        end
      end
      
      // 读指针的变化以及is_empty的变化
      // 当要输出数据的时候才变化读指针和is_empty变量
      if(in_psel == 1'b1 && in_penable == 1'b1 && in_pready == 1'b1 && is_empty == 1'b0)begin
        r_ptr             <= r_ptr + 3'b1;
        if(w_ptr == (r_ptr + 1'b1))begin
          is_empty        <= 1'b1;
        end
      end
    end
  end

  assign in_pready  = (state == READ) ? 1'b1 : 1'b0;
  assign in_prdata  = (state == READ) ? ((is_empty == 1'b0) ? {24'b0, fifo[r_ptr]} : 32'b0) : 32'b0;
  assign in_pslverr = 1'b0;

endmodule
