`timescale              1ns/1ps
`default_nettype        none

module PSRAM_INIT(
    input   wire            clk,
    input   wire            rst_n,
    input                   start,  // 判断是否处于QPI模式
    output  wire            init_done,   
    output  reg             sck,
    output  reg             ce_n,
    output  wire [3:0]      dout,
    output  wire            douten
);

    wire [7:0] CMD_35H = 8'h35;

    reg [3:0] counter;

    // 输出时钟
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            sck     <= 1'b0;
        // end else if(start == 1'b1)begin      // 直接使用start对于sck不一定正确
        end else if(ce_n == 1'b0)begin
            sck     <= ~sck;
        end else begin
            sck     <= 1'b0;
        end
    end

    // 输出ce_n
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            ce_n    <= 1'b1;
        end else if(start == 1'b1)begin
            ce_n    <= 1'b0;
        end else begin
            ce_n    <= 1'b1;
        end
    end

    // 计数counter
    always @(posedge sck or negedge rst_n) begin
        if(~rst_n)begin
            counter <= 4'b0;
        end else if(sck & ~init_done) begin
            counter <= counter + 1'b1;
        end else begin
            counter <= 4'b0;
        end
    end

    // 输出dout,douten,init_done
    assign dout         = (counter < 4'd8) ? {3'b0, CMD_35H[7 - counter]} : 4'b0;   // 在进入QPI模式之前，命令只在SPI0位进行输入
    assign douten       = 1;
    assign init_done    = (counter == 4'd8);

endmodule   