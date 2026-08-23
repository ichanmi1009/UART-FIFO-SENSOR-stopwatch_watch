`timescale 1ns / 1ps

module top_control_unit(
    input clk,
    input rst,
    input btnR, btnL, btnU, btnD,
    input [2:1] sw,

    output o_mode,
    output reg o_clear,
    output reg o_runstop,
    output reg o_set_mode,
    output reg [1:0] o_timesel,
    output reg o_digitsel,
    output reg [1:0] o_edit,








    output [6:0] led
);

    localparam INIT        = 4'b0000;
    localparam SW_STOP     = 4'b0001;
    localparam SW_RUN      = 4'b0010;
    localparam SW_CLEAR    = 4'b0011;
    localparam SW_MODE     = 4'b0100;

    localparam W_RUN       = 4'b0101;
    localparam W_SET_S1    = 4'b0110;
    localparam W_SET_S10   = 4'b0111;
    localparam W_SET_M1    = 4'b1000;
    localparam W_SET_M10   = 4'b1001;
    localparam W_SET_HOUR  = 4'b1010;

    reg [3:0] current_state, next_state;
    reg mode_reg;

    assign o_mode = mode_reg;



    assign led[0] = sw[1];
    assign led[1] = (current_state == W_RUN);
    assign led[2] = o_set_mode;











    assign led[3] = (current_state == W_SET_M1);
    assign led[4] = (current_state == W_SET_M10);
    assign led[5] = (current_state == W_SET_S1) || (current_state == W_SET_HOUR);
    assign led[6] = (current_state == W_SET_S10) || (current_state == W_SET_HOUR);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= INIT;
            mode_reg      <= 1'b0;
        end
        else begin
            current_state <= next_state;
            if (current_state == SW_MODE)
                mode_reg <= ~mode_reg;
        end
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            INIT: begin
                if ((sw[1] == 1'b1) && (sw[2] == 1'b0))
                    next_state = W_RUN;
                else if (sw[1] == 1'b0)
                    next_state = SW_STOP;
            end

            SW_STOP: begin
                if (sw[1])
                    next_state = W_RUN;
                else if (btnR)
                    next_state = SW_RUN;
                else if (btnL)
                    next_state = SW_CLEAR;
                else if (btnD)
                    next_state = SW_MODE;
            end

            SW_RUN: begin
                if (sw[1])
                    next_state = W_RUN;
                else if (btnR)
                    next_state = SW_STOP;
            end

            SW_CLEAR: begin
                next_state = SW_STOP;
            end

            SW_MODE: begin
                next_state = SW_STOP;
            end

            W_RUN: begin
                if (!sw[1])
                    next_state = SW_STOP;
                else if (sw[2])
                    next_state = W_SET_S1;
            end

            W_SET_S1: begin
                if (!sw[1])
                    next_state = SW_STOP;
                else if (!sw[2])
                    next_state = W_RUN;
                else if (btnL)
                    next_state = W_SET_S10;
                else if (btnR)
                    next_state = W_SET_HOUR;
            end

            W_SET_S10: begin
                if (!sw[1])
                    next_state = SW_STOP;
                else if (!sw[2])
                    next_state = W_RUN;
                else if (btnL)
                    next_state = W_SET_M1;
                else if (btnR)
                    next_state = W_SET_S1;
            end

            W_SET_M1: begin
                if (!sw[1])
                    next_state = SW_STOP;
                else if (!sw[2])
                    next_state = W_RUN;
                else if (btnL)
                    next_state = W_SET_M10;
                else if (btnR)
                    next_state = W_SET_S10;
            end

            W_SET_M10: begin
                if (!sw[1])
                    next_state = SW_STOP;
                else if (!sw[2])
                    next_state = W_RUN;
                else if (btnL)
                    next_state = W_SET_HOUR;
                else if (btnR)
                    next_state = W_SET_M1;
            end

            W_SET_HOUR: begin
                if (!sw[1])
                    next_state = SW_STOP;
                else if (!sw[2])
                    next_state = W_RUN;
                else if (btnL)
                    next_state = W_SET_S1;
                else if (btnR)
                    next_state = W_SET_M10;
            end

            default: begin
                next_state = INIT;
            end
        endcase
    end

    always @(*) begin
        o_runstop  = 1'b0;
        o_clear    = 1'b0;
        o_set_mode = 1'b0;
        o_timesel  = 2'b00;
        o_digitsel = 1'b0;
        o_edit     = 2'b00;

        case (current_state)
            SW_RUN: begin
                o_runstop = 1'b1;
            end

            SW_CLEAR: begin
                o_clear = 1'b1;
            end

            W_RUN: begin
                o_set_mode = 1'b0;
            end

            W_SET_S1: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b10;
                o_digitsel = 1'b1;
                if (btnU)
                    o_edit = 2'b01;
                else if (btnD)
                    o_edit = 2'b10;
            end

            W_SET_S10: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b10;
                o_digitsel = 1'b0;
                if (btnU)
                    o_edit = 2'b01;
                else if (btnD)
                    o_edit = 2'b10;
            end

            W_SET_M1: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b01;
                o_digitsel = 1'b1;
                if (btnU)
                    o_edit = 2'b01;
                else if (btnD)
                    o_edit = 2'b10;
            end

            W_SET_M10: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b01;
                o_digitsel = 1'b0;
                if (btnU)
                    o_edit = 2'b01;
                else if (btnD)
                    o_edit = 2'b10;
            end

            W_SET_HOUR: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b00;
                o_digitsel = 1'b0;
                if (btnU)
                    o_edit = 2'b01;
                else if (btnD)
                    o_edit = 2'b10;
            end

            default: begin
                o_runstop  = 1'b0;
                o_clear    = 1'b0;
                o_set_mode = 1'b0;
                o_timesel  = 2'b00;
                o_digitsel = 1'b0;
                o_edit     = 2'b00;
            end
        endcase
    end

endmodule
