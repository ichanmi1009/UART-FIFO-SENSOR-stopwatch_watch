`timescale 1ns / 1ps

module ASCII_sender(
    input             clk,
    input             rst,

    input             i_status_req,
    input      [1:0]  i_main_mode,

    input      [6:0]  i_msec,
    input      [5:0]  i_sec,
    input      [5:0]  i_min,
    input      [4:0]  i_hour,

    input      [8:0]  i_distance,
    input      [7:0]  i_humidity,
    input      [7:0]  i_temperature,

    input             i_fifo_full,
    output            o_fifo_wr_en,
    output reg [7:0]  o_ascii_data,
    output            o_busy
);

    localparam MODE_STW = 2'b00;
    localparam MODE_WTC = 2'b01;
    localparam MODE_ULT = 2'b10;
    localparam MODE_DHT = 2'b11;


    localparam S_IDLE = 2'd0;
    localparam S_SEND = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state_reg, state_next;

    reg [1:0] mode_reg, mode_next;

    reg [6:0] msec_reg, msec_next;
    reg [5:0] sec_reg, sec_next;
    reg [5:0] min_reg, min_next;
    reg [4:0] hour_reg, hour_next;

    reg [8:0] distance_reg, distance_next;
    reg [7:0] humidity_reg, humidity_next;
    reg [7:0] temperature_reg, temperature_next;

    reg [5:0] char_idx_reg, char_idx_next;
    reg [5:0] tx_len_reg, tx_len_next;

    assign o_busy       = (state_reg != S_IDLE);
    assign o_fifo_wr_en = (state_reg == S_SEND) && (!i_fifo_full);


    wire [3:0] msec_1;
    wire [3:0] msec_10;

    wire [3:0] sec_1;
    wire [3:0] sec_10;

    wire [3:0] min_1;
    wire [3:0] min_10;

    wire [3:0] hour_1;
    wire [3:0] hour_10;

    wire [3:0] dist_1;
    wire [3:0] dist_10;
    wire [3:0] dist_100;

    wire [3:0] hum_1;
    wire [3:0] hum_10;

    wire [3:0] tmp_1;
    wire [3:0] tmp_10;

    assign msec_1  =  msec_reg % 10;
    assign msec_10 = (msec_reg / 10) % 10;

    assign sec_1   =  sec_reg % 10;
    assign sec_10  = (sec_reg / 10) % 10;

    assign min_1   =  min_reg % 10;
    assign min_10  = (min_reg / 10) % 10;

    assign hour_1  =  hour_reg % 10;
    assign hour_10 = (hour_reg / 10) % 10;

    assign dist_1   =  distance_reg % 10;
    assign dist_10  = (distance_reg / 10) % 10;
    assign dist_100 = (distance_reg / 100) % 10;

    assign hum_1  =  humidity_reg % 10;
    assign hum_10 = (humidity_reg / 10) % 10;

    assign tmp_1  =  temperature_reg % 10;
    assign tmp_10 = (temperature_reg / 10) % 10;

    //SL current
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg       <= S_IDLE;

            mode_reg        <= MODE_STW;
            msec_reg        <= 7'd0;
            sec_reg         <= 6'd0;
            min_reg         <= 6'd0;
            hour_reg        <= 5'd0;

            distance_reg    <= 9'd0;
            humidity_reg    <= 8'd0;
            temperature_reg <= 8'd0;

            char_idx_reg    <= 6'd0;
            tx_len_reg      <= 6'd0;
        end
        else begin
            state_reg       <= state_next;

            mode_reg        <= mode_next;
            msec_reg        <= msec_next;
            sec_reg         <= sec_next;
            min_reg         <= min_next;
            hour_reg        <= hour_next;

            distance_reg    <= distance_next;
            humidity_reg    <= humidity_next;
            temperature_reg <= temperature_next;

            char_idx_reg    <= char_idx_next;
            tx_len_reg      <= tx_len_next;
        end
    end
    
    //CL next state
    always @(*) begin
        state_next       = state_reg;

        mode_next        = mode_reg;
        msec_next        = msec_reg;
        sec_next         = sec_reg;
        min_next         = min_reg;
        hour_next        = hour_reg;

        distance_next    = distance_reg;
        humidity_next    = humidity_reg;
        temperature_next = temperature_reg;

        char_idx_next    = char_idx_reg;
        tx_len_next      = tx_len_reg;

        case (state_reg)
            S_IDLE: begin
                char_idx_next = 6'd0;

                if (i_status_req) begin
                    mode_next        = i_main_mode;

                    msec_next        = i_msec;
                    sec_next         = i_sec;
                    min_next         = i_min;
                    hour_next        = i_hour;

                    distance_next    = i_distance;
                    humidity_next    = i_humidity;
                    temperature_next = i_temperature;

                    case (i_main_mode)
                        MODE_STW: tx_len_next = 6'd17;
                        MODE_WTC: tx_len_next = 6'd17;
                        MODE_ULT: tx_len_next = 6'd11;
                        MODE_DHT: tx_len_next = 6'd15;
                        default : tx_len_next = 6'd0;
                    endcase

                    state_next = S_SEND;
                end
            end
            S_SEND: begin
                if (!i_fifo_full) begin
                    if (char_idx_reg == (tx_len_reg - 1'b1)) begin
                        state_next = S_DONE;
                    end
                    else begin
                        char_idx_next = char_idx_reg + 1'b1;
                    end
                end
            end
            S_DONE: begin
                state_next = S_IDLE;
            end

            default: begin
                state_next = S_IDLE;
            end
        endcase
    end


    // CL output
    always @(*) begin
        o_ascii_data = 8'h00;
        case (mode_reg)
            MODE_STW: begin
                case (char_idx_reg)
                    6'd0 : o_ascii_data = "S";
                    6'd1 : o_ascii_data = "T";
                    6'd2 : o_ascii_data = "W";
                    6'd3 : o_ascii_data = " ";
                    6'd4 : o_ascii_data = hour_10 + 8'h30;
                    6'd5 : o_ascii_data = hour_1  + 8'h30;
                    6'd6 : o_ascii_data = ":";
                    6'd7 : o_ascii_data = min_10 + 8'h30;
                    6'd8 : o_ascii_data = min_1  + 8'h30;
                    6'd9 : o_ascii_data = ":";
                    6'd10: o_ascii_data = sec_10 + 8'h30;
                    6'd11: o_ascii_data = sec_1  + 8'h30;
                    6'd12: o_ascii_data = ".";
                    6'd13: o_ascii_data = msec_10 + 8'h30;
                    6'd14: o_ascii_data = msec_1  + 8'h30;
                    6'd15: o_ascii_data = 8'h0D;
                    6'd16: o_ascii_data = 8'h0A;
                    default: o_ascii_data = 8'h00;
                endcase
            end
            MODE_WTC: begin
                case (char_idx_reg)
                    6'd0 : o_ascii_data = "W";
                    6'd1 : o_ascii_data = "T";
                    6'd2 : o_ascii_data = "C";
                    6'd3 : o_ascii_data = " ";
                    6'd4 : o_ascii_data = hour_10 + 8'h30;
                    6'd5 : o_ascii_data = hour_1  + 8'h30;
                    6'd6 : o_ascii_data = ":";
                    6'd7 : o_ascii_data = min_10 + 8'h30;
                    6'd8 : o_ascii_data = min_1  + 8'h30;
                    6'd9 : o_ascii_data = ":";
                    6'd10: o_ascii_data = sec_10 + 8'h30;
                    6'd11: o_ascii_data = sec_1  + 8'h30;
                    6'd12: o_ascii_data = ".";
                    6'd13: o_ascii_data = msec_10 + 8'h30;
                    6'd14: o_ascii_data = msec_1  + 8'h30;
                    6'd15: o_ascii_data = 8'h0D;
                    6'd16: o_ascii_data = 8'h0A;
                    default: o_ascii_data = 8'h00;
                endcase
            end
            MODE_ULT: begin
                case (char_idx_reg)
                    6'd0 : o_ascii_data = "U";
                    6'd1 : o_ascii_data = "L";
                    6'd2 : o_ascii_data = "T";
                    6'd3 : o_ascii_data = " ";
                    6'd4 : o_ascii_data = dist_100 + 8'h30;
                    6'd5 : o_ascii_data = dist_10  + 8'h30;
                    6'd6 : o_ascii_data = dist_1   + 8'h30;
                    6'd7 : o_ascii_data = "c";
                    6'd8 : o_ascii_data = "m";
                    6'd9 : o_ascii_data = 8'h0D;
                    6'd10: o_ascii_data = 8'h0A;
                    default: o_ascii_data = 8'h00;
                endcase
            end
           MODE_DHT: begin
                case (char_idx_reg)
                    6'd0 : o_ascii_data = "D";
                    6'd1 : o_ascii_data = "H";
                    6'd2 : o_ascii_data = "T";
                    6'd3 : o_ascii_data = " ";
                    6'd4 : o_ascii_data = "H";
                    6'd5 : o_ascii_data = "=";
                    6'd6 : o_ascii_data = hum_10 + 8'h30;
                    6'd7 : o_ascii_data = hum_1  + 8'h30;
                    6'd8 : o_ascii_data = " ";
                    6'd9 : o_ascii_data = "T";
                    6'd10: o_ascii_data = "=";
                    6'd11: o_ascii_data = tmp_10 + 8'h30;
                    6'd12: o_ascii_data = tmp_1  + 8'h30;
                    6'd13: o_ascii_data = 8'h0D;
                    6'd14: o_ascii_data = 8'h0A;
                    default: o_ascii_data = 8'h00;
                endcase
            end
            default: begin
                o_ascii_data = 8'h00;
            end
        endcase
    end

endmodule
