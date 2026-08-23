`timescale 1ns / 1ps

module fnd_controller #(
    parameter DIV_COUNT     = 50_000,
    parameter DOT_THRESHOLD = 50,
    parameter MSEC_WIDTH    = 7,
    parameter SEC_WIDTH     = 6,
    parameter MIN_WIDTH     = 6,
    parameter HOUR_WIDTH    = 5,
    parameter DIST_WIDTH    = 9,
    parameter DHT_WIDTH     = 8
) (
    input       clk,
    input       rst,
    input [1:0] i_main_mode,
    input       i_display_sel,

    input [MSEC_WIDTH-1:0] msec,
    input [ SEC_WIDTH-1:0] sec,
    input [ MIN_WIDTH-1:0] min,
    input [HOUR_WIDTH-1:0] hour,

    input [DIST_WIDTH-1:0] distance,
    input [ DHT_WIDTH-1:0] humidity,
    input [ DHT_WIDTH-1:0] temperature,

    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    localparam MODE_STW = 2'b00;
    localparam MODE_WTC = 2'b01;
    localparam MODE_ULT = 2'b10;
    localparam MODE_DHT = 2'b11;

    localparam FONT_H = 4'hA;
    localparam FONT_C = 4'hB;
    localparam FONT_U = 4'hC;
    localparam FONT_DOT = 4'hE;
    localparam FONT_OFF = 4'hF;

    wire [3:0] w_out_mux;
    wire [3:0] w_out_mux_msec_sec;
    wire [3:0] w_out_mux_min_hour;
    wire [3:0] w_out_mux_timer;
    wire [3:0] w_out_mux_ult;
    wire [3:0] w_out_mux_dht;

    wire [3:0] w_msec_digit_1;
    wire [3:0] w_msec_digit_10;
    wire [3:0] w_sec_digit_1;
    wire [3:0] w_sec_digit_10;
    wire [3:0] w_min_digit_1;
    wire [3:0] w_min_digit_10;
    wire [3:0] w_hour_digit_1;
    wire [3:0] w_hour_digit_10;

    wire [3:0] w_dist_digit_1;
    wire [3:0] w_dist_digit_10;
    wire [3:0] w_dist_digit_100;

    wire [3:0] w_hum_digit_1;
    wire [3:0] w_hum_digit_10;
    wire [3:0] w_temp_digit_1;
    wire [3:0] w_temp_digit_10;

    wire [2:0] w_digit_sel;
    wire       w_1khz;

    wire [1:0] w_fnd_mode_sel;
    wire [1:0] w_decoder_sel;

    wire [3:0] w_dot_on;
    wire [3:0] w_dot_off;
    wire       w_dot_enable;

    assign w_dot_on = (w_dot_enable) ? FONT_DOT : FONT_OFF;
    assign w_dot_off = FONT_OFF;

    assign w_fnd_mode_sel = (i_main_mode == MODE_ULT) ? 2'd1 :
                            (i_main_mode == MODE_DHT) ? 2'd2 :
                                                         2'd0;




    assign w_decoder_sel = w_digit_sel[1:0];

    digit_splitter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_DS (
        .digit_in(msec),
        .digit_1 (w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_DS (
        .digit_in(sec),
        .digit_1 (w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_DS (
        .digit_in(min),
        .digit_1 (w_min_digit_1),
        .digit_10(w_min_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_DS (
        .digit_in(hour),
        .digit_1 (w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(DIST_WIDTH)
    ) U_DIST_DS_10 (
        .digit_in(distance),
        .digit_1 (w_dist_digit_1),
        .digit_10(w_dist_digit_10)
    );

    digit_splitter_100 #(
        .BIT_WIDTH(DIST_WIDTH)
    ) U_DIST_DS_100 (
        .digit_in (distance),
        .digit_100(w_dist_digit_100)
    );

    digit_splitter #(
        .BIT_WIDTH(DHT_WIDTH)
    ) U_HUM_DS (
        .digit_in(humidity),
        .digit_1 (w_hum_digit_1),
        .digit_10(w_hum_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(DHT_WIDTH)
    ) U_TEMP_DS (
        .digit_in(temperature),
        .digit_1 (w_temp_digit_1),
        .digit_10(w_temp_digit_10)
    );

    mux_8x1 U_MUX_MSEC_SEC (
        .in0    (w_msec_digit_1),
        .in1    (w_msec_digit_10),
        .in2    (w_sec_digit_1),
        .in3    (w_sec_digit_10),
        .in4    (w_dot_off),
        .in5    (w_dot_off),
        .in6    (w_dot_on),
        .in7    (w_dot_off),
        .sel    (w_digit_sel),
        .out_mux(w_out_mux_msec_sec)
    );

    mux_8x1 U_MUX_MIN_HOUR (
        .in0    (w_min_digit_1),
        .in1    (w_min_digit_10),
        .in2    (w_hour_digit_1),
        .in3    (w_hour_digit_10),
        .in4    (w_dot_off),
        .in5    (w_dot_off),
        .in6    (w_dot_on),
        .in7    (w_dot_off),
        .sel    (w_digit_sel),
        .out_mux(w_out_mux_min_hour)
    );

    mux_2x1 U_MUX_TIMER_SEL (
        .in0    (w_out_mux_msec_sec),
        .in1    (w_out_mux_min_hour),
        .sel    (i_display_sel),
        .out_mux(w_out_mux_timer)
    );


    mux_4x1 U_MUX_ULT (
        .in0    (w_dist_digit_1),
        .in1    (w_dist_digit_10),
        .in2    (w_dist_digit_100),
        .in3    (FONT_U),
        .sel    (w_digit_sel[1:0]),
        .out_mux(w_out_mux_ult)
    );


    mux_4x1 U_MUX_DHT (
        .in0    (i_display_sel ? w_temp_digit_1 : w_hum_digit_1),
        .in1    (i_display_sel ? w_temp_digit_10 : w_hum_digit_10),
        .in2    (FONT_OFF),
        .in3    (i_display_sel ? FONT_C : FONT_H),
        .sel    (w_digit_sel[1:0]),
        .out_mux(w_out_mux_dht)
    );

    mux_3x1 U_MUX_MODE_SEL (
        .in0    (w_out_mux_timer),
        .in1    (w_out_mux_ult),
        .in2    (w_out_mux_dht),
        .sel    (w_fnd_mode_sel),
        .out_mux(w_out_mux)
    );

    bcd U_BCD (
        .bin     (w_out_mux),
        .bcd_data(fnd_data)
    );

    clk_div_1khz #(
        .DIV_COUNT(DIV_COUNT)
    ) U_CLK_DIV_1KHZ (
        .clk   (clk),
        .rst   (rst),
        .o_1khz(w_1khz)
    );

    counter_8 U_COUNTER_8 (
        .clk      (w_1khz),
        .rst      (rst),
        .digit_sel(w_digit_sel)
    );

    dot_indicator #(
        .MSEC_WIDTH   (MSEC_WIDTH),
        .DOT_THRESHOLD(DOT_THRESHOLD)
    ) U_DOT_INDICATOR (
        .msec      (msec),
        .dot_enable(w_dot_enable)
    );

    decoder_2x4 U_DECODER_2X4 (
        .decoder_in(w_decoder_sel),
        .fnd_com   (fnd_com)
    );

endmodule


module mux_2x1 (
    input  [3:0] in0,
    input  [3:0] in1,
    input        sel,
    output [3:0] out_mux
);
    assign out_mux = (sel) ? in1 : in0;
endmodule


module mux_3x1 (
    input  [3:0] in0,
    input  [3:0] in1,
    input  [3:0] in2,
    input  [1:0] sel,
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;

    always @(*) begin
        case (sel)
            2'b00:   out_reg = in0;
            2'b01:   out_reg = in1;
            2'b10:   out_reg = in2;
            default: out_reg = 4'hF;
        endcase
    end
endmodule


module mux_4x1 (
    input  [3:0] in0,
    input  [3:0] in1,
    input  [3:0] in2,
    input  [3:0] in3,
    input  [1:0] sel,
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;

    always @(*) begin
        case (sel)
            2'b00:   out_reg = in0;
            2'b01:   out_reg = in1;
            2'b10:   out_reg = in2;
            2'b11:   out_reg = in3;
            default: out_reg = 4'hF;
        endcase
    end
endmodule


module mux_8x1 (
    input  [3:0] in0,
    input  [3:0] in1,
    input  [3:0] in2,
    input  [3:0] in3,
    input  [3:0] in4,
    input  [3:0] in5,
    input  [3:0] in6,
    input  [3:0] in7,
    input  [2:0] sel,
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;

    always @(*) begin
        case (sel)
            3'b000:  out_reg = in0;
            3'b001:  out_reg = in1;
            3'b010:  out_reg = in2;
            3'b011:  out_reg = in3;
            3'b100:  out_reg = in4;
            3'b101:  out_reg = in5;
            3'b110:  out_reg = in6;
            3'b111:  out_reg = in7;
            default: out_reg = 4'hF;
        endcase
    end
endmodule


module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH-1:0] digit_in,
    output [          3:0] digit_1,
    output [          3:0] digit_10
);
    assign digit_1  = digit_in % 10;
    assign digit_10 = (digit_in / 10) % 10;
endmodule


module digit_splitter_100 #(
    parameter BIT_WIDTH = 9
) (
    input  [BIT_WIDTH-1:0] digit_in,
    output [          3:0] digit_100
);
    assign digit_100 = (digit_in / 100) % 10;
endmodule


module bcd (
    input      [3:0] bin,
    output reg [7:0] bcd_data
);
    always @(bin) begin
        case (bin)
            4'h0   : bcd_data = 8'hC0;
            4'h1   : bcd_data = 8'hF9;
            4'h2   : bcd_data = 8'hA4;
            4'h3   : bcd_data = 8'hB0;
            4'h4   : bcd_data = 8'h99;
            4'h5   : bcd_data = 8'h92;
            4'h6   : bcd_data = 8'h82;
            4'h7   : bcd_data = 8'hF8;
            4'h8   : bcd_data = 8'h80;
            4'h9   : bcd_data = 8'h90;
            4'hA   : bcd_data = 8'h89;
            4'hB   : bcd_data = 8'hC6;
            4'hC   : bcd_data = 8'hC1;
            4'hE   : bcd_data = 8'h7F; // DOT ON
            4'hF   : bcd_data = 8'hFF; // DOT OFF
            default: bcd_data = 8'hFF;
        endcase
    end
endmodule


module clk_div_1khz #(
    parameter DIV_COUNT = 50_000
) (
    input  clk,
    input  rst,
    output o_1khz
);
    reg [$clog2(DIV_COUNT):0] counter_reg;
    reg o_1khz_reg;

    assign o_1khz = o_1khz_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_1khz_reg  <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1'b1;
            if (counter_reg == (DIV_COUNT - 1)) begin
                counter_reg <= 0;
                o_1khz_reg  <= ~o_1khz_reg;
            end
        end
    end
endmodule


module counter_8 (
    input        clk,
    input        rst,
    output [2:0] digit_sel
);
    reg [2:0] counter_reg;

    assign digit_sel = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 3'b000;
        end else begin
            counter_reg <= counter_reg + 1'b1;
        end
    end
endmodule


module decoder_2x4 (
    input      [1:0] decoder_in,
    output reg [3:0] fnd_com
);
    always @(*) begin
        case (decoder_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end
endmodule


module dot_indicator #(
    parameter MSEC_WIDTH    = 7,
    parameter DOT_THRESHOLD = 50
) (
    input  [MSEC_WIDTH-1:0] msec,
    output                  dot_enable
);




    assign dot_enable = (msec >= DOT_THRESHOLD) ? 1'b1 : 1'b0;

endmodule
