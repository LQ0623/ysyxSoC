module axi4_delayer #(
  parameter DELAY_CYCLES = 5,  // 延时周期数
  parameter BURST_MAX    = 8   // 最大突发长度
)(
  input         clock,
  input         reset,

  // 上游接口 (CPU侧)
  output        in_arready,
  input         in_arvalid,
  input  [3:0]  in_arid,
  input  [31:0] in_araddr,
  input  [7:0]  in_arlen,
  input  [2:0]  in_arsize,
  input  [1:0]  in_arburst,
  input         in_rready,
  output        in_rvalid,
  output [3:0]  in_rid,
  output [31:0] in_rdata,
  output [1:0]  in_rresp,
  output        in_rlast,
  output        in_awready,
  input         in_awvalid,
  input  [3:0]  in_awid,
  input  [31:0] in_awaddr,
  input  [7:0]  in_awlen,
  input  [2:0]  in_awsize,
  input  [1:0]  in_awburst,
  output        in_wready,
  input         in_wvalid,
  input  [31:0] in_wdata,
  input  [3:0]  in_wstrb,
  input         in_wlast,
                in_bready,
  output        in_bvalid,
  output [3:0]  in_bid,
  output [1:0]  in_bresp,

  // 下游接口 (设备侧)
  input         out_arready,
  output        out_arvalid,
  output [3:0]  out_arid,
  output [31:0] out_araddr,
  output [7:0]  out_arlen,
  output [2:0]  out_arsize,
  output [1:0]  out_arburst,
  output        out_rready,
  input         out_rvalid,
  input  [3:0]  out_rid,
  input  [31:0] out_rdata,
  input  [1:0]  out_rresp,
  input         out_rlast,
  input         out_awready,
  output        out_awvalid,
  output [3:0]  out_awid,
  output [31:0] out_awaddr,
  output [7:0]  out_awlen,
  output [2:0]  out_awsize,
  output [1:0]  out_awburst,
  input         out_wready,
  output        out_wvalid,
  output [31:0] out_wdata,
  output [3:0]  out_wstrb,
  output        out_wlast,
                out_bready,
  input         out_bvalid,
  input  [3:0]  out_bid,
  input  [1:0]  out_bresp
);

  assign in_arready = out_arready;
  assign out_arvalid = in_arvalid;
  assign out_arid = in_arid;
  assign out_araddr = in_araddr;
  assign out_arlen = in_arlen;
  assign out_arsize = in_arsize;
  assign out_arburst = in_arburst;
  assign out_rready = in_rready;
  assign in_rvalid = out_rvalid;
  assign in_rid = out_rid;
  assign in_rdata = out_rdata;
  assign in_rresp = out_rresp;
  assign in_rlast = out_rlast;
  assign in_awready = out_awready;
  assign out_awvalid = in_awvalid;
  assign out_awid = in_awid;
  assign out_awaddr = in_awaddr;
  assign out_awlen = in_awlen;
  assign out_awsize = in_awsize;
  assign out_awburst = in_awburst;
  assign in_wready = out_wready;
  assign out_wvalid = in_wvalid;
  assign out_wdata = in_wdata;
  assign out_wstrb = in_wstrb;
  assign out_wlast = in_wlast;
  assign out_bready = in_bready;
  assign in_bvalid = out_bvalid;
  assign in_bid = out_bid;
  assign in_bresp = out_bresp;

// ======================= 读通道 =======================

  // ================== 状态定义 ==================
//   localparam  R_IDLE       = 2'd0;
//   localparam  R_AR_DELAY   = 2'd1;    // AR通道延时
//   localparam  R_READ_DATA  = 2'd2;    // 等待数据返回
//   localparam  R_DATA_DELAY = 2'd3;    // 数据返回延时
//   reg [1:0]   r_state;

//   // ================== 控制信号 ==================
//   reg [31:0]  r_delay_count;        // 延时计数器
//   reg [7:0]   r_burst_count;        // 突发计数器
//   reg         r_saved_arready;      // 保存的ARREADY
//   reg [3:0]   r_saved_arid;         // 保存的ARID
//   reg [31:0]  r_saved_araddr;       // 保存的ARADDR
//   reg [7:0]   r_saved_arlen;        // 保存的ARLEN
//   reg [2:0]   r_saved_arsize;       // 保存的ARSIZE
//   reg [1:0]   r_saved_arburst;      // 保存的ARBURST
//   reg         r_last_data;          // 是否为最后一个数据 

//   // 数据FIFO，每一次传输的数据都记录下来，不像我最开始的想法只记录最后一个last
//   reg [31:0]  data_fifo [0:BURST_MAX-1];
//   reg [1:0]   resp_fifo [0:BURST_MAX-1];
//   reg [3:0]   id_fifo   [0:BURST_MAX-1];
//   reg         last_fifo [0:BURST_MAX-1];

//   reg [2:0]   fifo_wptr;           // FIFO写指针
//   reg [2:0]   fifo_rptr;           // FIFO读指针
//   reg [7:0]   fifo_count;          // FIFO数据计数，相当于是一个burst_count

//   // ================== 状态机 ==================
//   always @(posedge clock) begin
//     if(reset)begin
//       // 复位所有寄存器和状态
//       r_state         <= R_IDLE;
//       r_burst_count   <= 0;
//       fifo_wptr       <= 0;
//       fifo_rptr       <= 0;
//       fifo_count      <= 0;
//       r_last_data     <= 1'b0;
      
//       // 清空FIFO
//       for (integer i = 0; i < BURST_MAX; i = i + 1) begin
//         data_fifo[i]  <= 0;
//         resp_fifo[i]  <= 0;
//         id_fifo[i]    <= 0;
//         last_fifo[i]  <= 0;
//       end
//     end else begin
//       case(r_state)
//         R_IDLE: begin
//           // 等待AR握手
//           if (in_arvalid && out_arready) begin
//             // 保存AR信息
//             r_saved_arid    <= in_arid;
//             r_saved_araddr  <= in_araddr;
//             r_saved_arlen   <= in_arlen;
//             r_saved_arsize  <= in_arsize;
//             r_saved_arburst <= in_arburst;
//             r_saved_arready <= out_arready;
//             r_burst_count   <= in_arlen + 1;  // 突发长度 = arlen + 1
//             r_delay_count   <= DELAY_CYCLES;  // 设置AR延时
//             r_state         <= R_AR_DELAY;
//             r_last_data     <= 1'b0;
//           end
//         end

//         R_AR_DELAY: begin
//           // 等待AR延时结束
//           if (r_delay_count == 0) begin
//             r_state         <= R_READ_DATA;
//           end
//         end

//         R_READ_DATA: begin
//           // 等待并接收数据
//           if (out_rvalid == 1'b1 && fifo_count < BURST_MAX) begin
//             // 写入FIFO
//             data_fifo[fifo_wptr] <= out_rdata;
//             resp_fifo[fifo_wptr] <= out_rresp;
//             id_fifo[fifo_wptr]   <= out_rid;
//             last_fifo[fifo_wptr] <= out_rlast;
            
//             // 更新写指针和计数
//             fifo_wptr             <= ({1'b0, fifo_wptr} == BURST_MAX-1) ? 0 : fifo_wptr + 1;
//             fifo_count            <= fifo_count + 1;
            
//             // 设置数据延迟
//             r_delay_count         <= DELAY_CYCLES;
//             r_state               <= R_DATA_DELAY;
            
//             // 如果是最后一个数据，设置突发结束标志
//             if (out_rlast == 1'b1) begin
//               r_last_data         <= 1'b1; // 标记为最后一个数据
//             end
//           end
//         end

//         R_DATA_DELAY: begin
//           // 等待数据延迟结束
//           if (r_delay_count == 0) begin
//             // 可以发送数据
//             if (in_rready == 1'b1) begin
//               // 更新读指针和计数
//               fifo_rptr         <= ({1'b0, fifo_rptr} == BURST_MAX-1) ? 0 : fifo_rptr + 1;
//               fifo_count        <= fifo_count - 1;
              
//               // 判断下一个状态
//               // 这里使用大于1判断是因为上面的fifo_count减了1，但是在这个时钟上升沿不会体现出来
//               if (fifo_count > 1) begin
//                 // 还有更多数据要处理
//                 r_state         <= R_READ_DATA;
//                 r_burst_count   <= r_burst_count - 1;
//               end
//               else if (last_fifo[fifo_rptr] == 1'b1) begin
//                 // 最后一个数据了，突发结束了
//                 // TAG:这里可能需要跳转到R_WAIT_LAST
//                 r_state         <= R_IDLE;
//               end else begin
//                 // 等待更多数据到达
//                 r_state         <= R_READ_DATA;
//               end
//             end
//           end
//         end

//       endcase
//     end
//   end

//   // ================== 延迟计数器逻辑 ==================
//   always @(posedge clock) begin
//     if(reset)begin
//       r_delay_count   <= 0;
//     end else begin
//       if (r_delay_count > 0) begin
//         r_delay_count <= r_delay_count - 1;
//       end
//     end
//   end

//   // ================== 信号输出逻辑 ==================
//   // AR通道
//   assign in_arready  = (r_state == R_AR_DELAY && r_delay_count == 0) ? r_saved_arready : 1'b0;
//   assign out_arvalid = (r_state == R_IDLE) ? in_arvalid : 1'b0;
//   assign out_arid    = in_arid;
//   assign out_araddr  = in_araddr;
//   assign out_arlen   = in_arlen;
//   assign out_arsize  = in_arsize;
//   assign out_arburst = in_arburst;
  
//   // R通道
//   assign out_rready  = (r_state == R_READ_DATA) && 
//                       (fifo_count < BURST_MAX);
  
//   assign in_rvalid   = (r_state == R_DATA_DELAY && r_delay_count == 0);
  
//   assign in_rid      = id_fifo[fifo_rptr];
//   assign in_rdata    = (r_state == R_DATA_DELAY && r_delay_count == 0) ? data_fifo[fifo_rptr] : 32'b0;
//   assign in_rresp    = resp_fifo[fifo_rptr];
//   assign in_rlast    = (r_state == R_DATA_DELAY && r_last_data == 1);

// // ======================= 写通道 =======================

//   // ================== 状态定义 ==================
// localparam  W_IDLE      = 2'd0;
// localparam  AW_WAITING  = 2'd1;  // 等待内存返回awready/wready
// localparam  AW_DELAY    = 2'd2;  // AW/W通道响应延时
// localparam  B_DELAY     = 2'd3;  // B通道响应延时

// reg [1:0]   w_state;
// reg [31:0]  w_delay_count;

// // 锁存寄存器
// reg         awready_received, wready_received;
// reg [3:0]   w_saved_awid;
// reg [31:0]  w_saved_awaddr;
// reg [7:0]   w_saved_awlen;
// reg [2:0]   w_saved_awsize;
// reg [1:0]   w_saved_awburst;
// reg [31:0]  w_saved_wdata;
// reg [3:0]   w_saved_wstrb;

// // B响应控制
// reg         bvalid_received;
// reg [3:0]   w_saved_bid;
// reg [1:0]   w_saved_bresp;

// // ================== 状态机 ==================
// always @(posedge clock) begin
//   if (reset) begin
//     w_state           <= W_IDLE;
//     w_delay_count     <= 0;
//     awready_received  <= 0;
//     wready_received   <= 0;
//     bvalid_received   <= 0;
//     w_saved_awid      <= 0;
//     w_saved_awaddr    <= 0;
//     w_saved_wdata     <= 0;
//   end else begin
//     case (w_state)
//       W_IDLE: begin
//         // 当CPU发起写请求时
//         if (in_awvalid && in_wvalid) begin
//           // 立即将请求转发给内存（无延时）
//           // 锁存地址和数据（用于保持信号稳定）
//           w_saved_awid      <= in_awid;
//           w_saved_awaddr    <= in_awaddr;
//           w_saved_awlen     <= in_awlen;
//           w_saved_awsize    <= in_awsize;
//           w_saved_awburst   <= in_awburst;
//           w_saved_wdata     <= in_wdata;
//           w_saved_wstrb     <= in_wstrb;
          
//           // 重置标志
//           awready_received  <= 0;
//           wready_received   <= 0;
//           w_state           <= AW_WAITING;
//         end
//       end
      
//       AW_WAITING: begin
//         // 监控内存返回的ready信号
//         if (out_awready)begin
//           awready_received  <= 1;
//         end
//         if (out_wready)begin 
//           wready_received   <= 1;
//         end
        
//         // 当两个ready都收到后，开始延时
//         if (awready_received && wready_received) begin
//           // 这里减2是因为在这里耽误了两个周期
//           w_delay_count     <= DELAY_CYCLES - 2;
//           w_state           <= AW_DELAY;
//         end
//       end
      
//       AW_DELAY: begin
//         if (w_delay_count > 1) begin
//           w_delay_count     <= w_delay_count - 1;
//         end else begin
//           // 延时结束，准备响应CPU
//           awready_received  <= 0;
//           wready_received   <= 0;
//           w_state           <= B_DELAY;  // 直接进入等待B响应的状态
//         end
//       end
      
//       B_DELAY: begin
//         // 监控内存返回的bvalid
//         if (out_bvalid && out_bready) begin
//           w_saved_bid       <= out_bid;
//           w_saved_bresp     <= out_bresp;
//           bvalid_received   <= 1;
//           w_delay_count     <= DELAY_CYCLES - 1;  // 开始B响应延时
//         end
        
//         // 处理B响应延时
//         if (bvalid_received && w_delay_count > 1) begin
//           w_delay_count     <= w_delay_count - 1;
//         end
        
//         // 完成整个事务
//         if (bvalid_received && w_delay_count == 1 && in_bready) begin
//           bvalid_received   <= 0;
//           w_state           <= W_IDLE;
//         end
//       end
//     endcase
//   end
// end

// // ================== 输出逻辑 ==================
// // AW通道 - CPU到内存无延时
// assign in_awready  = (w_state == AW_DELAY && w_delay_count == 1);
// assign out_awvalid = (w_state == AW_WAITING) ? in_awvalid : 1'b0;
// assign out_awid    = (w_state == AW_WAITING) ? in_awid : w_saved_awid;
// assign out_awaddr  = (w_state == AW_WAITING) ? in_awaddr : w_saved_awaddr;
// assign out_awlen   = (w_state == AW_WAITING) ? in_awlen : w_saved_awlen;
// assign out_awsize  = (w_state == AW_WAITING) ? in_awsize : w_saved_awsize;
// assign out_awburst = (w_state == AW_WAITING) ? in_awburst : w_saved_awburst;

// // W通道 - CPU到内存无延时
// assign in_wready   = (w_state == AW_DELAY && w_delay_count == 1);
// assign out_wvalid  = (w_state == AW_WAITING) ? in_wvalid : 1'b0;
// assign out_wdata   = (w_state == AW_WAITING) ? in_wdata : w_saved_wdata;
// assign out_wstrb   = (w_state == AW_WAITING) ? in_wstrb : w_saved_wstrb;
// assign out_wlast   = 1'b1;  // 单次传输

// // B通道 - CPU到内存无延时
// assign out_bready  = (w_state == B_DELAY);  // 持续准备好接收响应
// assign in_bvalid   = bvalid_received && (w_state == B_DELAY) && (w_delay_count == 1);
// assign in_bid      = w_saved_bid;
// assign in_bresp    = w_saved_bresp;

endmodule
