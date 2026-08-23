`timescale 1ns / 1ps

module system_control_unit(
    input             clk,
    input             rst,

    input             i_status_req,

    input      [3:0]  sw,

    input             btn_R,
    input             btn_L,
    input             btn_U,
    input             btn_D,

    output     [1:0]  c_mode,
    output            o_status_req,

    output     [2:0]  timer_sw,
    output     [3:0]  timer_btn,

    output            ultra_btn,
    output            dht_btn,

    output     [1:0]  fnd_sel
);

    wire w_watch_en;
    wire w_stopwatch_en;
    wire w_timer_en;
    wire w_ultra_en;
    wire w_dht_en;

    wire [3:0] w_btn_bus;

    assign w_btn_bus = {btn_D, btn_U, btn_L, btn_R};


    assign o_status_req = i_status_req;

    main_mode_decoder_sys U_MAIN_MODE_DECODER (
        .main_mode    (sw[1:0]),
        .watch_en     (w_watch_en),
        .stopwatch_en (w_stopwatch_en),
        .timer_en     (w_timer_en),
        .ultra_en     (w_ultra_en),
        .dht_en       (w_dht_en),
        .c_mode       (c_mode)
    );

    timer_switch_router_sys U_TIMER_SWITCH_ROUTER (
        .watch_en     (w_watch_en),
        .display_sel  (sw[2]),
        .watch_set    (sw[3]),
        .timer_sw     (timer_sw)
    );

    button_router_sys U_BUTTON_ROUTER (
        .btn_bus      (w_btn_bus),
        .timer_en     (w_timer_en),
        .ultra_en     (w_ultra_en),
        .dht_en       (w_dht_en),
        .timer_btn    (timer_btn),
        .ultra_btn    (ultra_btn),
        .dht_btn      (dht_btn)
    );

    fnd_sel_router_sys U_FND_SEL_ROUTER (
        .timer_en     (w_timer_en),
        .ultra_en     (w_ultra_en),
        .dht_en       (w_dht_en),
        .fnd_sel      (fnd_sel)
    );

endmodule

module main_mode_decoder_sys(
    input      [1:0] main_mode,
    output reg       watch_en,
    output reg       stopwatch_en,
    output           timer_en,
    output reg       ultra_en,
    output reg       dht_en,
    output     [1:0] c_mode
);

    localparam MODE_STW = 2'b00;
    localparam MODE_WTC = 2'b01;
    localparam MODE_ULT = 2'b10;
    localparam MODE_DHT = 2'b11;

    assign timer_en = stopwatch_en | watch_en;
    assign c_mode   = main_mode;

    always @(*) begin
        stopwatch_en = 1'b0;
        watch_en     = 1'b0;
        ultra_en     = 1'b0;
        dht_en       = 1'b0;

        case (main_mode)
            MODE_STW: stopwatch_en = 1'b1;
            MODE_WTC: watch_en     = 1'b1;
            MODE_ULT: ultra_en     = 1'b1;
            MODE_DHT: dht_en       = 1'b1;
            default : stopwatch_en = 1'b1;
        endcase
    end

endmodule

module timer_switch_router_sys(
    input        watch_en,
    input        display_sel,
    input        watch_set,
    output [2:0] timer_sw
);

    assign timer_sw[0] = display_sel;
    assign timer_sw[1] = watch_en;
    assign timer_sw[2] = watch_set;

endmodule

module button_router_sys(
    input      [3:0] btn_bus,
    input            timer_en,
    input            ultra_en,
    input            dht_en,

    output     [3:0] timer_btn,
    output           ultra_btn,
    output           dht_btn
);

    assign timer_btn = timer_en ? btn_bus : 4'b0000;

    assign ultra_btn = ultra_en ? btn_bus[0] : 1'b0;
    assign dht_btn   = dht_en   ? btn_bus[0] : 1'b0;

endmodule

module fnd_sel_router_sys(
    input        timer_en,
    input        ultra_en,
    input        dht_en,
    output [1:0] fnd_sel
);

    assign fnd_sel = timer_en ? 2'b00 :
                     ultra_en ? 2'b01 :
                     dht_en   ? 2'b10 :
                                2'b11;

endmodule
