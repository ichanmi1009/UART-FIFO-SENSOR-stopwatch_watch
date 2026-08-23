`timescale 1ns / 1ps

module uart(
    input               clk     ,
    input               rst     ,
    input               tx_start,
    input   [7:0]       tx_data ,
    input               rx      ,
    output  [7:0]       rx_data ,
    output              rx_done ,
    output              tx_busy ,
    output              tx
);

    wire  w_b_tick;

    uart_tx U_UART_TX(
        .clk     (clk)        ,
        .rst     (rst)        ,
        .tx_start(tx_start)    ,
        .tx_data (tx_data)    ,
        .b_tick  (w_b_tick)   ,
        .tx_busy (tx_busy)    ,
        .tx      (tx)
    );

    uart_rx U_UART_RX (
        .clk    (clk)       ,
        .rst    (rst)       ,
        .b_tick (w_b_tick)  ,
        .rx     (rx)        ,
        .rx_data(rx_data)   ,
        .rx_done(rx_done)
    );


    baud_tick_gen U_BAUD_TICK_GEN(
        .clk     (clk),
        .rst     (rst),
        .o_b_tick(w_b_tick)
    );


endmodule

module uart_rx (
    input               clk     ,
    input               rst     ,
    input               b_tick  ,
    input               rx      ,
    output  [7:0]       rx_data ,
    output              rx_done
);

    parameter   IDLE    = 0,
                START   = 1,
                DATA    = 2,
                STOP    = 3;

    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] data_reg, data_next;
    reg rx_done_reg, rx_done_next;

    assign rx_done = rx_done_reg;
    assign rx_data = data_reg;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            c_state         <= IDLE;
            b_tick_cnt_reg  <= 0;
            bit_cnt_reg     <= 0;
            data_reg        <= 8'h00;
            rx_done_reg     <= 0;
        end
        else begin
            c_state <= n_state;
            b_tick_cnt_reg  <= b_tick_cnt_next;
            bit_cnt_reg     <= bit_cnt_next;
            data_reg        <= data_next;
            rx_done_reg     <= rx_done_next;
        end

    end

    always @(*) begin
        n_state          = c_state;
        b_tick_cnt_next  = b_tick_cnt_reg;
        bit_cnt_next     = bit_cnt_reg;
        data_next        = data_reg;
        rx_done_next     = rx_done_reg;
        case (c_state)
            IDLE : begin
                rx_done_next = 1'b0;
                if(b_tick && (!rx)) begin
                    b_tick_cnt_next = 0;
                    n_state = START;
                end
            end
            START : begin
                if(b_tick) begin
                    if(b_tick_cnt_reg == 7) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next    = 0;
                        n_state         = DATA;
                    end
                    else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                    end
                end
            end
            DATA : begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        data_next = {rx,data_reg[7:1]};

                        b_tick_cnt_next = 0;
                        if(bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;
                            n_state         = STOP;
                        end
                        else begin
                            bit_cnt_next = bit_cnt_reg + 1'b1;
                        end
                    end
                    else begin
                       b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                    end
                end
            end
            STOP : begin
                if(b_tick) begin
                    if((b_tick_cnt_reg == 23) || ((b_tick_cnt_reg>16)&&!rx)) begin

                        rx_done_next = 1'b1;
                        n_state = IDLE;
                    end
                    else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                    end
                end
            end

        endcase

    end



endmodule



module uart_tx (
    input               clk         ,
    input               rst         ,
    input               tx_start    ,
    input   [7:0]       tx_data     ,
    input               b_tick      ,
    output              tx_busy     ,
    output              tx
);

    parameter   IDLE    = 0,
                START   = 1,
                DATA    = 2,
                STOP    = 3;


    reg [2:0]   c_state, n_state;
    reg tx_reg, tx_next;


    reg [7:0]   data_reg, data_next;
    reg [2:0]   bit_cnt_reg, bit_cnt_next;
    reg [3:0]   b_tick_cnt_reg,b_tick_cnt_next;
    reg tx_busy_reg, tx_busy_next;

    assign  tx = tx_reg;
    assign tx_busy = tx_busy_reg;



    always @(posedge clk or posedge rst) begin
        if(rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            data_reg        <= 8'h00;
            bit_cnt_reg     <= 3'b000;
            b_tick_cnt_reg  <= 4'h00;
            tx_busy_reg     <= 1'b0;
        end
        else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            data_reg        <= data_next;
            bit_cnt_reg     <= bit_cnt_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;
            tx_busy_reg     <= tx_busy_next;
        end
    end


    always@(*) begin
        n_state         = c_state;
        tx_next         = tx_reg;
        data_next       = data_reg;
        bit_cnt_next    = bit_cnt_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        tx_busy_next    = tx_busy_reg;

        case(c_state)
            IDLE    : begin
                tx_busy_next = 1'b0;
                tx_next = 1'b1;
                if(tx_start)begin
                    tx_busy_next = 1'b1;
                    n_state = START;
                    data_next = tx_data;
                    b_tick_cnt_next = 0;
                end
            end
            START    : begin
                tx_next = 1'b0;
                bit_cnt_next = 3'b000;
                if(b_tick) begin
                    if(b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next =3'b000;
                        n_state = DATA;
                    end
                    else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                    end
                end
            end
            DATA    : begin
                tx_next = data_reg[0];
                if(b_tick) begin
                    if(b_tick_cnt_reg == 15) begin
                        if(bit_cnt_reg == 3'd7) begin
                            b_tick_cnt_next = 0;
                            n_state         = STOP;
                        end
                        else begin
                            b_tick_cnt_next = 0;

                            data_next = {1'b0,data_reg[7:1]};
                            bit_cnt_next = bit_cnt_reg + 1'b1;
                            n_state      = DATA;
                        end
                    end
                    else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                    end
                end
            end
            STOP    : begin
                tx_next = 1'b1;
                if(b_tick) begin
                    if(b_tick_cnt_reg ==15) begin
                        b_tick_cnt_next = 0;
                        n_state = IDLE;
                        tx_busy_next = 1'b0;
                    end
                    else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1'b1;
                    end
                end
            end
        endcase
    end

endmodule



module baud_tick_gen(
    input           clk     ,
    input           rst     ,
    output reg      o_b_tick
);


    parameter CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 9600;
    parameter F_COUNT = CLK_FREQ / (BAUD_RATE * 16);
    parameter WIDTH = $clog2(F_COUNT)-1;

    reg [WIDTH : 0] counter_reg;


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            counter_reg   <= 0;
            o_b_tick    <= 1'b0;
        end
        else begin

            counter_reg   <= counter_reg + 1'b1;
            o_b_tick    <= 1'b0;
            if(counter_reg == F_COUNT - 1) begin
                counter_reg   <= 0;
                o_b_tick    <= 1'b1;
            end
            else begin
                o_b_tick    <= 1'b0;
            end
        end
    end

endmodule