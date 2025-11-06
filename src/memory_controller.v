module memory_controller(
    input clk,
    input rpll_clk,

    input send_cmd,
    input [2:0] cmd,
    input [2:0] write_type,
    input [31:0] addr,
    input [31:0] write_data,

    output init_done,
    output cmd_done,
    output [31:0] memory_read_out,

    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,
    output O_sdram_cas_n,
    output O_sdram_ras_n,
    output O_sdram_wen_n,
    output [3:0] O_sdram_dqm,
    output [10:0] O_sdram_addr,
    output [1:0] O_sdram_ba,
    inout [31:0] IO_sdram_dq
);

reg [3:0] write_mask;

always @(*) begin
    case (write_type)
        0: write_mask <= 4'b0000;
        1: write_mask <= ~(4'b0011 << addr[1:0]);
        2: write_mask <= ~(4'b0001 << addr[1:0]);
        default: write_mask <= 4'b1111;
    endcase
end

SDRAM_Controller_HS_Top sdram_controller(
    .I_sdrc_rst_n(1'b1),
    .I_sdrc_clk(clk),
    .I_sdram_clk(rpll_clk),
    .I_sdrc_cmd_en(send_cmd),
    .I_sdrc_cmd(cmd),
    .I_sdrc_precharge_ctrl(1'b1),
    .I_sdram_power_down(1'b0),
    .I_sdram_selfrefresh(1'b0),
    .I_sdrc_addr(addr[22:2]),
    .I_sdrc_dqm(write_mask),
    .I_sdrc_data(write_data),
    .I_sdrc_data_len(8'b0),

    .O_sdrc_data(memory_read_out),
    .O_sdrc_init_done(init_done),
    .O_sdrc_cmd_ack(cmd_done),

    .O_sdram_clk(O_sdram_clk),
    .O_sdram_cke(O_sdram_cke),
    .O_sdram_cs_n(O_sdram_cs_n),
    .O_sdram_cas_n(O_sdram_cas_n),
    .O_sdram_ras_n(O_sdram_ras_n),
    .O_sdram_wen_n(O_sdram_wen_n),
    .O_sdram_dqm(O_sdram_dqm),
    .O_sdram_addr(O_sdram_addr),
    .O_sdram_ba(O_sdram_ba),
    .IO_sdram_dq(IO_sdram_dq)
);

endmodule