// out_为前缀的信号是连接sdram这些外设的
// in_为前缀的信号是连接到CPU的，通过AXI4ToAPB模块将AXI的请求转化为APB请求
module apb_delayer(
  input         clock,
  input         reset,
  // 连接到CPU的
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

  // 连接到外设的
  output [31:0] out_paddr,
  output        out_psel,
  output        out_penable,
  output [2:0]  out_pprot,
  output        out_pwrite,
  output [31:0] out_pwdata,
  output [3:0]  out_pstrb,
  input         out_pready,
  input  [31:0] out_prdata,
  input         out_pslverr
);

  // assign out_paddr   = in_paddr;
  // assign out_psel    = in_psel;
  // assign out_penable = in_penable;
  // assign out_pprot   = in_pprot;
  // assign out_pwrite  = in_pwrite;
  // assign out_pwdata  = in_pwdata;
  // assign out_pstrb   = in_pstrb;
  // assign in_pready   = out_pready;
  // assign in_prdata   = out_prdata;
  // assign in_pslverr  = out_pslverr;

  // 参数定义
  // Fmax: 430MHz, Perip: 100MHz, r = 4.3
  // set s = 1024, r*s = 3379.2 -> 3379
  // wait perip resp: counter 每周期加(r-1)*s=3379，直到(r-1)*s*k=3379*k
  // wait apb delayer done: counter先/s = (3379/1024)*k, 每周期-1
  
  parameter R_SCALED      = 3379;   // (r - 1) * s = 3.3 * 1024 = 3379.2 ≈ 3379
  parameter SCALE_SHIFT   = 10;     // log2(1024) = 10
  parameter IDLE          = 2'b00,  // 空闲状态
            Access_Perip  = 2'b01,  // 访问外设/存储体
            Delay         = 2'b11;  // 访存延时

  // 信号定义
  reg [1:0]   state;              // 状态机状态
  reg [31:0]  delay_count;        // 延迟计数器

  reg [31:0]  save_data;          // 存储从外设读取出来的数据
  reg         save_pslverr;       // 存储从外设读取出来的pslverr的状态

  always @(posedge clock) begin
    if(reset)begin
      state             <= IDLE;
      delay_count       <= 32'b0;
    end else begin
      case (state)
        IDLE: begin
          if(in_psel == 1'b1) begin
            state       <= Access_Perip;
            delay_count <= delay_count + 32'd3379;
          end
        end
        Access_Perip: begin
          if(out_pready == 1'b1) begin
            state       <= Delay;
            // 最后返回pready信号的时候,还需要一个延时.然后需要除上一个放大系数
            delay_count <= (delay_count + 32'd3379) >> SCALE_SHIFT;
          end else begin
            delay_count <= delay_count + 32'd3379;
          end
        end
        Delay: begin
          // 这里计数到1的时候,延迟就刚好了
          if(delay_count == 32'b1)begin
            state       <= IDLE;
            delay_count <= 32'b0;
          end else begin
            delay_count <= delay_count - 1'b1;
          end
        end
        default: begin
          state         <= IDLE;
          delay_count   <= 32'b0;
        end
      endcase
    end
  end

  always @(posedge clock) begin
    if(reset)begin
      save_data         <= 32'b0;
      save_pslverr      <= 1'b0;
    end else begin
      if(out_pready) begin
        save_data       <= out_prdata;
        save_pslverr    <= out_pslverr;
      end
    end
  end

  // 给CPU的信号
  assign in_pready    = (state == Delay) && (delay_count == 32'd1);
  assign in_prdata    = save_data;
  assign in_pslverr   = save_pslverr;

  // 给外设的信号
  assign out_paddr    = in_paddr;
  assign out_psel     = in_psel && state != Delay;  // psel 信号不能一直置为高
  assign out_penable  = in_penable;
  assign out_pprot    = in_pprot;
  assign out_pwrite   = in_pwrite;
  assign out_pwdata   = in_pwdata;
  assign out_pstrb    = in_pstrb;
  

endmodule
