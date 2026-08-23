`timescale 1ns / 1ps

module INPUT_Merger_sw4(
    input             clk,
    input             rst,

    input      [3:0]  i_fpga_sw,

    input      [3:0]  i_virtual_sw,
    input             i_virtual_valid,
    input      [3:0]  i_virtual_sw_mask,

    output     [3:0]  o_merged_sw
);

    reg [3:0] sw_current_reg;
    reg [3:0] sw_current_next;

    reg [3:0] fpga_sw_prev_reg;

    wire [3:0] fpga_sw_changed_mask;

    wire       main_mode_changed;
    wire       display_sel_changed;
    wire       watch_mode_changed;

    assign fpga_sw_changed_mask = i_fpga_sw ^ fpga_sw_prev_reg;


    assign main_mode_changed   = |fpga_sw_changed_mask[1:0];


    assign display_sel_changed = fpga_sw_changed_mask[2];
    assign watch_mode_changed  = fpga_sw_changed_mask[3];

    assign o_merged_sw = sw_current_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sw_current_reg   <= 4'b0000;
            fpga_sw_prev_reg <= 4'b0000;
        end
        else begin
            sw_current_reg   <= sw_current_next;
            fpga_sw_prev_reg <= i_fpga_sw;
        end
    end

    always @(*) begin
        sw_current_next = sw_current_reg;






        if (main_mode_changed) begin
            sw_current_next[1:0] = i_fpga_sw[1:0];
        end


        if (display_sel_changed) begin
            sw_current_next[2] = i_fpga_sw[2];
        end


        if (watch_mode_changed) begin
            sw_current_next[3] = i_fpga_sw[3];
        end






        if (i_virtual_valid) begin
            sw_current_next = (sw_current_next & ~i_virtual_sw_mask) |
                              (i_virtual_sw   &  i_virtual_sw_mask);
        end
    end

endmodule