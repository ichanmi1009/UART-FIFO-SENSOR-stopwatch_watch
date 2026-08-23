`timescale 1ns / 1ps

module top_stopwatch_watch #(
    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5
)(
    input                        clk,
    input                        rst,

    input                        btnR,
    input                        btnL,
    input                        btnU,
    input                        btnD,

    input       [2:0]            timer_sw,

    output      [7:0]            led,

    output      [MSEC_WIDTH-1:0] msec,
    output      [SEC_WIDTH-1:0]  sec,
    output      [MIN_WIDTH-1:0]  min,
    output      [HOUR_WIDTH-1:0] hour
);

    wire [MSEC_WIDTH-1:0] w_msec_sw;
    wire [SEC_WIDTH -1:0] w_sec_sw;
    wire [MIN_WIDTH -1:0] w_min_sw;
    wire [HOUR_WIDTH-1:0] w_hour_sw;

    wire [MSEC_WIDTH-1:0] w_msec_wt;
    wire [SEC_WIDTH -1:0] w_sec_wt;
    wire [MIN_WIDTH -1:0] w_min_wt;
    wire [HOUR_WIDTH-1:0] w_hour_wt;

    wire [MSEC_WIDTH-1:0] w_msec_raw_wt;
    wire [3:0]            w_sec1_wt;
    wire [2:0]            w_sec10_wt;
    wire [3:0]            w_min1_wt;
    wire [2:0]            w_min10_wt;
    wire [HOUR_WIDTH-1:0] w_hour_raw_wt;

    wire                  w_runstop;
    wire                  w_clear;
    wire                  w_mode;
    wire                  w_set_mode;
    wire                  w_digit_sel;
    wire [1:0]            w_time_sel;
    wire [1:0]            w_edit_cmd;

    wire [6:0]            w_control_led;
    wire [23:0]           w_sw_data;
    wire [23:0]           w_wt_data;
    wire [23:0]           w_mux_out;

    assign msec = w_mux_out[6:0];
    assign sec  = w_mux_out[12:7];
    assign min  = w_mux_out[18:13];
    assign hour = w_mux_out[23:19];






    assign led[0]   = timer_sw[0];
    assign led[7:1] = w_control_led;

    top_control_unit U_TOP_CONTROL_UNIT (
        .clk        (clk),
        .rst        (rst),
        .sw         (timer_sw[2:1]),
        .btnD       (btnD),
        .btnL       (btnL),
        .btnR       (btnR),
        .btnU       (btnU),

        .o_mode     (w_mode),
        .o_clear    (w_clear),
        .o_runstop  (w_runstop),
        .o_set_mode (w_set_mode),
        .o_timesel  (w_time_sel),
        .o_digitsel (w_digit_sel),
        .o_edit     (w_edit_cmd),
        .led        (w_control_led)
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk       (clk),
        .rst       (rst),
        .i_runstop (w_runstop),
        .i_clear   (w_clear),
        .i_mode    (w_mode),
        .msec      (w_msec_sw),
        .sec       (w_sec_sw),
        .min       (w_min_sw),
        .hour      (w_hour_sw)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk         (clk),
        .rst         (rst),
        .i_set_mode  (w_set_mode),
        .i_digit_sel (w_digit_sel),
        .i_time_sel  (w_time_sel),
        .i_edit_cmd  (w_edit_cmd),
        .msec        (w_msec_raw_wt),
        .sec_d1      (w_sec1_wt),
        .sec_d10     (w_sec10_wt),
        .min_d1      (w_min1_wt),
        .min_d10     (w_min10_wt),
        .hour        (w_hour_raw_wt)
    );

    watch_fnd_adapter U_WATCH_FND_ADAPTER (
        .i_hour    (w_hour_raw_wt),
        .i_min_d10 (w_min10_wt),
        .i_min_d1  (w_min1_wt),
        .i_sec_d10 (w_sec10_wt),
        .i_sec_d1  (w_sec1_wt),
        .i_msec    (w_msec_raw_wt),
        .hour      (w_hour_wt),
        .min       (w_min_wt),
        .sec       (w_sec_wt),
        .msec      (w_msec_wt)
    );

    assign w_sw_data = {w_hour_sw, w_min_sw, w_sec_sw, w_msec_sw};
    assign w_wt_data = {w_hour_wt, w_min_wt, w_sec_wt, w_msec_wt};

    mux_2x1_nbit #(
        .WIDTH(24)
    ) U_TIMER_DATA_MUX (
        .in0 (w_sw_data),
        .in1 (w_wt_data),
        .sel (timer_sw[1]),
        .y   (w_mux_out)
    );

endmodule
