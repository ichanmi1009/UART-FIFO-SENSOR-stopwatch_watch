`timescale 1ns / 1ps

module TOP #(
    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5,
    parameter DIST_WIDTH = 9,
    parameter DHT_WIDTH  = 8
)(
    input               clk,
    input               btnC,
    input               btnR,
    input               btnL,
    input               btnU,
    input               btnD,
    input      [3:0]    sw,

    input               RsRx,
    output              RsTx,

    input               echo,
    output              trig,
    inout               dht11,

    output     [3:0]    an,
    output     [7:0]    seg,
    output     [15:0]   led
);

    localparam MODE_STW = 2'b00;
    localparam MODE_WTC = 2'b01;
    localparam MODE_ULT = 2'b10;
    localparam MODE_DHT = 2'b11;
    
    wire [7:0] w_uart_rx_data;
    wire       w_uart_rx_done;
    wire       w_uart_tx_busy;

    wire       w_uart_tx_start;
    wire [7:0] w_uart_tx_data;

    uart U_UART (
        .clk      (clk),
        .rst      (btnC),
        .tx_start (w_uart_tx_start),
        .tx_data  (w_uart_tx_data),
        .rx       (RsRx),
        .rx_data  (w_uart_rx_data),
        .rx_done  (w_uart_rx_done),
        .tx_busy  (w_uart_tx_busy),
        .tx       (RsTx)
    );


    wire [7:0] w_rx_fifo_pop_data;
    wire       w_rx_fifo_full;
    wire       w_rx_fifo_empty;
    wire       w_ascii_rd_en;

    fifo #(
        .DEPTH(16)
    ) U_RX_FIFO (
        .clk       (clk),
        .rst       (btnC),
        .push_data (w_uart_rx_data),
        .push      (w_uart_rx_done),
        .pop       (w_ascii_rd_en),
        .pop_data  (w_rx_fifo_pop_data),
        .full      (w_rx_fifo_full),
        .empty     (w_rx_fifo_empty)
    );


    wire [3:0] w_virtual_sw;
    wire       w_virtual_sw_valid;
    wire [3:0] w_virtual_sw_mask;

    wire       w_virtual_btn_R;
    wire       w_virtual_btn_L;
    wire       w_virtual_btn_U;
    wire       w_virtual_btn_D;

    wire       w_ascii_status_req;
    wire       w_cmd_valid_pulse;
    wire       w_cmd_error_pulse;
    wire [4:0] w_last_cmd_id;

    ASCII_decoder U_ASCII_DECODER (
        .clk                 (clk),
        .rst                 (btnC),
        .i_ascii_data        (w_rx_fifo_pop_data),
        .i_rx_empty          (w_rx_fifo_empty),
        .o_rx_rd_en          (w_ascii_rd_en),

        .o_virtual_sw        (w_virtual_sw),
        .o_virtual_sw_valid  (w_virtual_sw_valid),
        .o_virtual_sw_mask   (w_virtual_sw_mask),

        .o_virtual_btn_R     (w_virtual_btn_R),
        .o_virtual_btn_L     (w_virtual_btn_L),
        .o_virtual_btn_U     (w_virtual_btn_U),
        .o_virtual_btn_D     (w_virtual_btn_D),

        .o_status_req        (w_ascii_status_req),
        .o_cmd_valid_pulse   (w_cmd_valid_pulse),
        .o_cmd_error_pulse   (w_cmd_error_pulse),
        .o_last_cmd_id       (w_last_cmd_id)
    );

    wire w_btn_R;
    wire w_btn_L;
    wire w_btn_U;
    wire w_btn_D;

    button_debounce U_BTN_R (
        .clk   (clk),
        .rst   (btnC),
        .i_btn (btnR),
        .o_btn (w_btn_R)
    );

    button_debounce U_BTN_L (
        .clk   (clk),
        .rst   (btnC),
        .i_btn (btnL),
        .o_btn (w_btn_L)
    );

    button_debounce U_BTN_U (
        .clk   (clk),
        .rst   (btnC),
        .i_btn (btnU),
        .o_btn (w_btn_U)
    );

    button_debounce U_BTN_D (
        .clk   (clk),
        .rst   (btnC),
        .i_btn (btnD),
        .o_btn (w_btn_D)
    );

    wire [3:0] w_merged_sw;

    INPUT_Merger_sw4 U_INPUT_MERGER_SW4 (
        .clk               (clk),
        .rst               (btnC),
        .i_fpga_sw         (sw),
        .i_virtual_sw      (w_virtual_sw),
        .i_virtual_valid   (w_virtual_sw_valid),
        .i_virtual_sw_mask (w_virtual_sw_mask),
        .o_merged_sw       (w_merged_sw)
    );

    wire w_merged_btn_R;
    wire w_merged_btn_L;
    wire w_merged_btn_U;
    wire w_merged_btn_D;

    assign w_merged_btn_R = w_btn_R | w_virtual_btn_R;
    assign w_merged_btn_L = w_btn_L | w_virtual_btn_L;
    assign w_merged_btn_U = w_btn_U | w_virtual_btn_U;
    assign w_merged_btn_D = w_btn_D | w_virtual_btn_D;

    wire [1:0] w_c_mode;
    wire       w_status_req_to_sender;

    wire [2:0] w_timer_sw;
    wire [3:0] w_timer_btn;
    wire       w_ultra_btn;
    wire       w_dht_btn;
    wire [1:0] w_fnd_sel;

    system_control_unit U_SYSTEM_CONTROL_UNIT (
        .clk          (clk),
        .rst          (btnC),
        .i_status_req (w_ascii_status_req),
        .sw           (w_merged_sw),

        .btn_R        (w_merged_btn_R),
        .btn_L        (w_merged_btn_L),
        .btn_U        (w_merged_btn_U),
        .btn_D        (w_merged_btn_D),

        .c_mode       (w_c_mode),
        .o_status_req (w_status_req_to_sender),

        .timer_sw     (w_timer_sw),
        .timer_btn    (w_timer_btn),

        .ultra_btn    (w_ultra_btn),
        .dht_btn      (w_dht_btn),

        .fnd_sel      (w_fnd_sel)
    );


    wire [MSEC_WIDTH-1:0] w_timer_msec;
    wire [SEC_WIDTH -1:0] w_timer_sec;
    wire [MIN_WIDTH -1:0] w_timer_min;
    wire [HOUR_WIDTH-1:0] w_timer_hour;
    wire [7:0]            w_timer_led;

    top_stopwatch_watch #(
        .MSEC_WIDTH (MSEC_WIDTH),
        .SEC_WIDTH  (SEC_WIDTH),
        .MIN_WIDTH  (MIN_WIDTH),
        .HOUR_WIDTH (HOUR_WIDTH)
    ) U_TOP_STOPWATCH_WATCH (
        .clk      (clk),
        .rst      (btnC),
        .btnR     (w_timer_btn[0]),
        .btnL     (w_timer_btn[1]),
        .btnU     (w_timer_btn[2]),
        .btnD     (w_timer_btn[3]),
        .timer_sw (w_timer_sw),
        .led      (w_timer_led),
        .msec     (w_timer_msec),
        .sec      (w_timer_sec),
        .min      (w_timer_min),
        .hour     (w_timer_hour)
    );


    wire [DIST_WIDTH-1:0] w_distance;
    wire [DHT_WIDTH -1:0] w_humidity;
    wire [DHT_WIDTH -1:0] w_temperature;
    wire                  w_dht_valid_led;

    sr04 U_SR04 (
        .clk       (clk),
        .rst       (btnC),
        .ultra_btn (w_ultra_btn),
        .echo      (echo),
        .distance  (w_distance),
        .trig      (trig)
    );

    dht11 U_DHT11 (
        .clk     (clk),
        .rst     (btnC),
        .dht_btn (w_dht_btn),
        .led     (w_dht_valid_led),
        .hm      (w_humidity),
        .tm      (w_temperature),
        .dht11   (dht11)
    );

    fnd_controller #(
        .MSEC_WIDTH (MSEC_WIDTH),
        .SEC_WIDTH  (SEC_WIDTH),
        .MIN_WIDTH  (MIN_WIDTH),
        .HOUR_WIDTH (HOUR_WIDTH),
        .DIST_WIDTH (DIST_WIDTH),
        .DHT_WIDTH  (DHT_WIDTH)
    ) U_FND_CONTROLLER (
        .clk           (clk),
        .rst           (btnC),
        .i_main_mode   (w_c_mode),
        .i_display_sel (w_merged_sw[2]),

        .msec          (w_timer_msec),
        .sec           (w_timer_sec),
        .min           (w_timer_min),
        .hour          (w_timer_hour),

        .distance      (w_distance),
        .humidity      (w_humidity),
        .temperature   (w_temperature),

        .fnd_com       (an),
        .fnd_data      (seg)
    );

    wire       w_ascii_tx_wr_en;
    wire [7:0] w_ascii_tx_data;
    wire       w_ascii_sender_busy;

    wire [7:0] w_tx_fifo_pop_data;
    wire       w_tx_fifo_full;
    wire       w_tx_fifo_empty;
    wire       w_tx_fifo_pop;

    ASCII_sender U_ASCII_SENDER (
        .clk            (clk),
        .rst            (btnC),

        .i_status_req   (w_status_req_to_sender),
        .i_main_mode    (w_c_mode),

        .i_msec         (w_timer_msec),
        .i_sec          (w_timer_sec),
        .i_min          (w_timer_min),
        .i_hour         (w_timer_hour),

        .i_distance     (w_distance),
        .i_humidity     (w_humidity),
        .i_temperature  (w_temperature),

        .i_fifo_full    (w_tx_fifo_full),
        .o_fifo_wr_en   (w_ascii_tx_wr_en),
        .o_ascii_data   (w_ascii_tx_data),
        .o_busy         (w_ascii_sender_busy)
    );

    fifo #(
        .DEPTH(64)
    ) U_TX_FIFO (
        .clk       (clk),
        .rst       (btnC),
        .push_data (w_ascii_tx_data),
        .push      (w_ascii_tx_wr_en),
        .pop       (w_tx_fifo_pop),
        .pop_data  (w_tx_fifo_pop_data),
        .full      (w_tx_fifo_full),
        .empty     (w_tx_fifo_empty)
    );

    assign w_tx_fifo_pop   = (!w_tx_fifo_empty) && (!w_uart_tx_busy);
    assign w_uart_tx_start = w_tx_fifo_pop;
    assign w_uart_tx_data  = w_tx_fifo_pop_data;

    wire w_timer_mode;
    assign w_timer_mode = (w_c_mode == MODE_STW) || (w_c_mode == MODE_WTC);

    assign led[0]  = (w_timer_mode) ? w_timer_led[0] : 1'b0;
    assign led[1]  = (w_timer_mode) ? w_timer_led[1] : 1'b0;
    assign led[2]  = (w_timer_mode) ? w_timer_led[2] : 1'b0;
    assign led[3]  = (w_timer_mode) ? w_timer_led[3] : 1'b0;

    assign led[4]  = 1'b0;
    assign led[5]  = 1'b0;
    assign led[6]  = 1'b0;
    assign led[7]  = 1'b0;

    assign led[8]  = (w_c_mode == MODE_ULT);
    assign led[9]  = (w_c_mode == MODE_DHT);

    assign led[10] = (w_timer_mode) ? w_timer_led[4] : 1'b0;
    assign led[11] = (w_timer_mode) ? w_timer_led[5] : 1'b0;
    assign led[12] = (w_timer_mode) ? w_timer_led[6] : 1'b0;
    assign led[13] = (w_timer_mode) ? w_timer_led[7] : 1'b0;

    assign led[14] = trig;
    assign led[15] = w_dht_valid_led;

endmodule
