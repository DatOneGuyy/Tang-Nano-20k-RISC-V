module memory_controller(
    input clk,
    input rpll_clk,

    input [31:0] instruction,
    input [1:0] cpu_state,
    input [2:0] write_type,
    input [31:0] addr,
    input [31:0] write_data,

    output init_done,
    output reg operation_done,
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

localparam WAIT = 0;
localparam ACTIVATE = 1;
localparam PAUSE = 2;
localparam RW = 3;

localparam INIT = 0;
localparam FETCH = 1;
localparam EXEC = 2;
localparam FREEZE = 3;

reg [3:0] write_mask;
reg [1:0] state;

always @(*) begin
    case (write_type)
        0: write_mask <= 4'b0000;
        1: write_mask <= ~(4'b0011 << addr[1:0]);
        2: write_mask <= ~(4'b0001 << addr[1:0]);
        default: write_mask <= 4'b1111;
    endcase
end

reg operation_type;
reg send_cmd;
reg [2:0] cmd;
reg [31:0] data_hold;
reg [3:0] write_mask_hold;
reg [31:0] address_hold;

reg [3:0] pause_counter;

always @(posedge clk) begin
    case (state)
        WAIT: begin
            operation_done <= 1'b1;
            send_cmd <= 1'b0;
            
            if ((instruction[6:2] == 5'b00000 | instruction[6:2] == 5'b01000) & (cpu_state == FETCH)) begin
                operation_done <= 1'b0;
                send_cmd <= 1'b1;
                cmd <= 3'b011;

                operation_type <= ~instruction[5];
                data_hold <= write_data;
                write_mask_hold <= write_mask;
                address_hold <= addr;

                state <= ACTIVATE;
            end
        end

        ACTIVATE: begin
            operation_done <= 1'b0;
            send_cmd <= 1'b0;

            if (cmd_done) begin
                send_cmd <= 1'b1;
                cmd <= {2'b10, operation_type};
                
                state <= PAUSE;
            end
        end

        RW: begin
            operation_done <= 1'b0;
            send_cmd <= 1'b0;

            if (cmd_done) begin
                if (operation_type) begin 
                    state <= PAUSE;
                end
                else begin
                    operation_done <= 1'b1;
                    state <= WAIT;
                end
            end
        end

        PAUSE: begin
            send_cmd <= 1'b0;
            operation_done <= 1'b0;

            if (pause_counter < 3) begin
                pause_counter <= pause_counter + 4'b1;
            end
            else begin
                pause_counter <= 4'b0;
                operation_done <= 1'b1;
                state <= WAIT;
            end
        end

        default: state <= WAIT;
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
    .I_sdrc_addr(address_hold[22:2]),
    .I_sdrc_dqm(write_mask_hold),
    .I_sdrc_data(data_hold),
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