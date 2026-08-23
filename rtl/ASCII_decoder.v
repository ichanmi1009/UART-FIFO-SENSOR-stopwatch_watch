`timescale 1ns / 1ps

module ASCII_decoder(
    input             clk,
    input             rst,
    input      [7:0]  i_ascii_data,
    input             i_rx_empty,
    output            o_rx_rd_en,

    output reg [3:0]  o_virtual_sw,
    output reg        o_virtual_sw_valid,
    output reg [3:0]  o_virtual_sw_mask,

    output reg        o_virtual_btn_R,
    output reg        o_virtual_btn_L,
    output reg        o_virtual_btn_U,
    output reg        o_virtual_btn_D,

    output reg        o_status_req,
    output reg        o_cmd_valid_pulse,
    output reg        o_cmd_error_pulse,
    output reg [4:0]  o_last_cmd_id
);

    localparam ASCII_LF = 8'h0A;
    localparam ASCII_CR = 8'h0D;

    localparam [23:0] CMD_STW = 24'h53_54_57;
    localparam [23:0] CMD_WTC = 24'h57_54_43;
    localparam [23:0] CMD_ULT = 24'h55_4C_54;
    localparam [23:0] CMD_DHT = 24'h44_48_54;

    localparam [23:0] CMD_D0  = 24'h44_30_5F;
    localparam [23:0] CMD_D1  = 24'h44_31_5F;
    localparam [23:0] CMD_RUN = 24'h52_55_4E;
    localparam [23:0] CMD_SET = 24'h53_45_54;

    localparam [23:0] CMD_STR = 24'h53_54_52;
    localparam [23:0] CMD_PAU = 24'h50_41_55;
    localparam [23:0] CMD_CLR = 24'h43_4C_52;
    localparam [23:0] CMD_REV = 24'h52_45_56;

    localparam [23:0] CMD_RGT = 24'h52_47_54;
    localparam [23:0] CMD_LFT = 24'h4C_46_54;
    localparam [23:0] CMD_UP  = 24'h55_50_5F;
    localparam [23:0] CMD_DWN = 24'h44_57_4E;

    localparam [23:0] CMD_TRG = 24'h54_52_47;
    localparam [23:0] CMD_MEA = 24'h4D_45_41;
    localparam [23:0] CMD_STS = 24'h53_54_53;


    reg [1:0] byte_cnt_reg;
    reg [7:0] cmd0_reg;
    reg [7:0] cmd1_reg;
    reg [7:0] cmd2_reg;
    reg       flush_reg;


    wire fifo_valid;
    assign fifo_valid = !i_rx_empty;

    assign o_rx_rd_en = fifo_valid;

    wire [7:0] ch_upper;
    assign ch_upper = ((i_ascii_data >= 8'h61) && (i_ascii_data <= 8'h7A)) ?
                      (i_ascii_data - 8'h20) :
                       i_ascii_data;


    wire ch_end;
    assign ch_end = (i_ascii_data == ASCII_LF) || (i_ascii_data == ASCII_CR);

    wire [23:0] cmd_word;
    assign cmd_word = {cmd0_reg, cmd1_reg, cmd2_reg};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_cnt_reg        <= 2'd0;
            cmd0_reg            <= 8'h00;
            cmd1_reg            <= 8'h00;
            cmd2_reg            <= 8'h00;
            flush_reg           <= 1'b0;

            o_virtual_sw        <= 4'b0000;
            o_virtual_sw_valid  <= 1'b0;
            o_virtual_sw_mask   <= 4'b0000;

            o_virtual_btn_R     <= 1'b0;
            o_virtual_btn_L     <= 1'b0;
            o_virtual_btn_U     <= 1'b0;
            o_virtual_btn_D     <= 1'b0;

            o_status_req        <= 1'b0;
            o_cmd_valid_pulse   <= 1'b0;
            o_cmd_error_pulse   <= 1'b0;
            o_last_cmd_id       <= 5'd0;
        end
        else begin

            o_virtual_sw_valid  <= 1'b0;
            o_virtual_sw_mask   <= 4'b0000;

            o_virtual_btn_R     <= 1'b0;
            o_virtual_btn_L     <= 1'b0;
            o_virtual_btn_U     <= 1'b0;
            o_virtual_btn_D     <= 1'b0;

            o_status_req        <= 1'b0;
            o_cmd_valid_pulse   <= 1'b0;
            o_cmd_error_pulse   <= 1'b0;

            if (fifo_valid) begin
                if (flush_reg) begin
                    if (ch_end) begin
                        flush_reg    <= 1'b0;
                        byte_cnt_reg <= 2'd0;
                    end
                end
                else begin
                    case (byte_cnt_reg)
                        2'd0: begin
                            if (ch_end) begin
                                byte_cnt_reg <= 2'd0;
                            end
                            else begin
                                cmd0_reg     <= ch_upper;
                                byte_cnt_reg <= 2'd1;
                            end
                        end
                        2'd1: begin
                            if (ch_end) begin
                                byte_cnt_reg      <= 2'd0;
                                o_cmd_error_pulse <= 1'b1;
                            end
                            else begin
                                cmd1_reg     <= ch_upper;
                                byte_cnt_reg <= 2'd2;
                            end
                        end
                        2'd2: begin
                            if (ch_end) begin

                                byte_cnt_reg      <= 2'd0;
                                o_cmd_error_pulse <= 1'b1;
                            end
                            else begin
                                cmd2_reg     <= ch_upper;
                                byte_cnt_reg <= 2'd3;
                            end
                        end
                        2'd3: begin
                            if (ch_end) begin
                                case (cmd_word)
                                    CMD_STW: begin
                                        o_virtual_sw        <= 4'b0000;
                                        o_virtual_sw_mask   <= 4'b0011;
                                        o_virtual_sw_valid  <= 1'b1;
                                        o_cmd_valid_pulse   <= 1'b1;
                                        o_last_cmd_id       <= 5'd1;
                                    end
                                    CMD_WTC: begin
                                        o_virtual_sw        <= 4'b0001;
                                        o_virtual_sw_mask   <= 4'b0011;
                                        o_virtual_sw_valid  <= 1'b1;
                                        o_cmd_valid_pulse   <= 1'b1;
                                        o_last_cmd_id       <= 5'd2;
                                    end
                                    CMD_ULT: begin
                                        o_virtual_sw        <= 4'b0010;
                                        o_virtual_sw_mask   <= 4'b0011;
                                        o_virtual_sw_valid  <= 1'b1;
                                        o_cmd_valid_pulse   <= 1'b1;
                                        o_last_cmd_id       <= 5'd3;
                                    end
                                    CMD_DHT: begin
                                        o_virtual_sw        <= 4'b0011;
                                        o_virtual_sw_mask   <= 4'b0011;
                                        o_virtual_sw_valid  <= 1'b1;
                                        o_cmd_valid_pulse   <= 1'b1;
                                        o_last_cmd_id       <= 5'd4;
                                    end
                                    CMD_D0: begin
                                        o_virtual_sw        <= 4'b0000;
                                        o_virtual_sw_mask   <= 4'b0100;
                                        o_virtual_sw_valid  <= 1'b1;
                                        o_cmd_valid_pulse   <= 1'b1;
                                        o_last_cmd_id       <= 5'd5;
                                    end
                                    CMD_D1: begin
                                        o_virtual_sw        <= 4'b0100;
                                        o_virtual_sw_mask   <= 4'b0100;
                                        o_virtual_sw_valid  <= 1'b1;
                                        o_cmd_valid_pulse   <= 1'b1;
                                        o_last_cmd_id       <= 5'd6;
                                    end
                                    CMD_RUN: begin
                                        o_virtual_sw        <= 4'b0000;
                                        o_virtual_sw_mask   <= 4'b1000;
                                        o_virtual_sw_valid  <= 1'b1;
                                        o_cmd_valid_pulse   <= 1'b1;
                                        o_last_cmd_id       <= 5'd7;
                                    end
                                    CMD_SET: begin
                                        o_virtual_sw        <= 4'b1000;
                                        o_virtual_sw_mask   <= 4'b1000;
                                        o_virtual_sw_valid  <= 1'b1;
                                        o_cmd_valid_pulse   <= 1'b1;
                                        o_last_cmd_id       <= 5'd8;
                                    end
                                    CMD_STR: begin
                                        o_virtual_btn_R    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd9;
                                    end
                                    CMD_PAU: begin
                                        o_virtual_btn_R    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd10;
                                    end
                                    CMD_RGT: begin
                                        o_virtual_btn_R    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd11;
                                    end
                                    CMD_TRG: begin
                                        o_virtual_btn_R    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd12;
                                    end
                                    CMD_MEA: begin
                                        o_virtual_btn_R    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd13;
                                    end
                                    CMD_CLR: begin
                                        o_virtual_btn_L    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd14;
                                    end
                                    CMD_LFT: begin
                                        o_virtual_btn_L    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd15;
                                    end
                                    CMD_UP: begin
                                        o_virtual_btn_U    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd16;
                                    end
                                    CMD_REV: begin
                                        o_virtual_btn_D    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd17;
                                    end
                                    CMD_DWN: begin
                                        o_virtual_btn_D    <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd18;
                                    end
                                    CMD_STS: begin
                                        o_status_req       <= 1'b1;
                                        o_cmd_valid_pulse  <= 1'b1;
                                        o_last_cmd_id      <= 5'd19;
                                    end
                                    default: begin
                                        o_cmd_error_pulse  <= 1'b1;
                                    end
                                endcase
                                byte_cnt_reg <= 2'd0;
                            end
                            else begin
                                flush_reg          <= 1'b1;
                                byte_cnt_reg       <= 2'd0;
                                o_cmd_error_pulse  <= 1'b1;
                            end
                        end
                        default: begin
                            byte_cnt_reg       <= 2'd0;
                            o_cmd_error_pulse  <= 1'b1;
                        end
                    endcase
                end
            end
        end
    end
endmodule
