module riscv_top(
    input                        clk,
	input                        uart_rx,
    input                        button0,
    input                        button1,

	output                       uart_tx,
    output                       led0,
    output                       led1,
    output                       led2, 
    output                       ws2812,

    output         O_sdram_clk,
    output         O_sdram_cke,
    output         O_sdram_cs_n,
    output         O_sdram_cas_n,
    output         O_sdram_ras_n,
    output         O_sdram_wen_n,
    output [3:0]   O_sdram_dqm,
    output [10:0]  O_sdram_addr,
    output [1:0]   O_sdram_ba,
    inout  [31:0]  IO_sdram_dq
);

wire memory_clk;
Gowin_rPLL rPLL_inst(
    .clkin(clk),
    .clkoutp(memory_clk)
);

localparam INIT = 0;
localparam FETCH = 1;
localparam EXEC = 2;
localparam WRITE = 3;
localparam MEMORY_OP_WAIT = 4;

localparam I_TYPE = 7'b0010011;
localparam I_TYPE_LOAD = 7'b0000011;
localparam S_TYPE = 7'b0100011;
localparam B_TYPE = 7'b1100011;
localparam J_TYPE = 7'b1101111;
localparam J_TYPE_LINK = 7'b1100111;
localparam LUI_TYPE = 7'b0110111;
localparam AUIPC_TYPE = 7'b0010111;

reg [2:0] state;

localparam DELAY = 15000000;
reg [31:0] counter;
reg [8:0] memory_refresh_counter;

reg read_program;
reg [31:0] pc;
wire [31:0] instruction;
instruction_fetch instruction_fetch_inst(
    .clk(read_program), 
    .pc(pc), 
    .instruction(instruction)
);

wire read1_en, read2_en, write1_en;
wire [4:0] read1_dest;
wire [4:0] read2_dest;
wire [4:0] write1_dest;
wire jal, jalr;
control_unit control_unit_inst(
    .instruction(instruction),
    .read1_en(read1_en),
    .read2_en(read2_en),
    .write1_en(write1_en),
    .read1_dest(read1_dest),
    .read2_dest(read2_dest),
    .write1_dest(write1_dest),
    .jal(jal),
    .jalr(jalr)
);

wire [31:0] read_value1;
wire [31:0] read_value2;
wire [1023:0] full_file;
reg [31:0] write_value;
reg regwrite_en;
register_file register_file_inst(
    .clk(clk),
    .read1_en(read1_en),
    .read2_en(read2_en),
    .write1_en(write1_en),
    .regwrite_en(regwrite_en),
    .read1_dest(read1_dest),
    .read2_dest(read2_dest),
    .write1_dest(write1_dest),
    .write_value(write_value),
    .read_value1(read_value1),
    .read_value2(read_value2),
    .full_file(full_file)
);
 
wire [31:0] alu_op1;
wire [31:0] alu_op2;
wire [31:0] jump_immediate;
wire [31:0] memory_write_data;
operand_controller operand_controller_inst(
    .register_read1(read_value1),
    .register_read2(read_value2),
    .instruction(instruction),
    .alu_op1(alu_op1),
    .alu_op2(alu_op2),
    .jump_immediate(jump_immediate),
    .memory_write_data(memory_write_data)
);

reg readmem_en;
reg writemem_en;
reg refresh;
wire [31:0] memory_read_data;
wire data_ready;
wire busy;
sdram sdram_inst(
    .SDRAM_DQ(IO_sdram_dq),
    .SDRAM_A(O_sdram_addr),
    .SDRAM_BA(O_sdram_ba),
    .SDRAM_nCS(O_sdram_cs_n),
    .SDRAM_nWE(O_sdram_wen_n),
    .SDRAM_nRAS(O_sdram_ras_n),
    .SDRAM_nCAS(O_sdram_cas_n),
    .SDRAM_CLK(O_sdram_clk),
    .SDRAM_CKE(O_sdram_cke),
    .SDRAM_DQM(O_sdram_dqm),

    .clk(clk),
    .clk_sdram(memory_clk),
    .resetn(~button1),
    .rd(readmem_en),
    .wr(writemem_en),
    .refresh(refresh),
    .access_type(instruction[14:12]),
    .addr(alu_result[22:0]),
    .din(read_value2),
    .dout32(memory_read_data),
    .data_ready(data_ready),
    .busy(busy)
);

wire [31:0] alu_result;
wire [31:0] jalr_result;
wire comparison_flag;
wire alu_clk = clk & (state == EXEC);
alu alu_inst(
    .clk(alu_clk),
    .pc(pc),
    .op1(alu_op1),
    .op2(alu_op2),
    .instruction(instruction),
    .result(alu_result),
    .jalr(jalr_result),
    .comparison_flag(comparison_flag)
);

wire button0_filtered;
debounce_filter button0_filter(
    .clk(clk),
    .button(button0),
    .filtered(button0_filtered)
);

reg send;
reg [255:0] label;
reg [63:0] data;
debugger debugger_inst(
    .clk(clk),
    .rst(button0_filtered),
    .uart_rx(uart_rx),
    .debug_send(send),
    .label(label),
    .data(data),
    .register_data(full_file),
    .uart_tx(uart_tx)
);

reg [2:0] leds_out;
assign led0 = ~leds_out[0];
assign led1 = ~leds_out[1];
assign led2 = ~leds_out[2];

always @(posedge clk) begin
    if (memory_refresh_counter < 400) begin
        memory_refresh_counter <= memory_refresh_counter + 9'b1;
        refresh <= 1'b0;
    end 
    else begin
        memory_refresh_counter <= 9'b0;
        refresh <= 1'b1;
    end

    if (counter < DELAY) begin
        counter <= counter + 1'b1;
        send <= 1'b0;
    end 
    else begin
        counter <= 1'b0;
        read_program <= 1'b0;
        send <= 1'b0;
        regwrite_en <= 1'b0;
        readmem_en <= 1'b0;
        writemem_en <= 1'b0;

        case (state)
            INIT: begin
                pc <= 32'b0;
                leds_out <= 3'd0;

                state <= FETCH;
            end

            FETCH: begin
                leds_out <= 3'd1;
                read_program <= 1'b1;

                send <= 1'b1;
                label <= "program counter: ";
                data <= pc;

                state <= EXEC;
            end

            EXEC: begin
                leds_out <= 3'd2;

                state <= WRITE;
            end

            WRITE: begin
                leds_out <= 3'd4;

                send <= 1'b1;
                label <= "alu result: ";
                data <= alu_result;

                write_value <= alu_result;

                state <= FETCH;
                if (comparison_flag | jal) begin
                    regwrite_en <= 1'b1;
                    pc <= pc + jump_immediate;
                end 
                else if (jalr) begin
                    regwrite_en <= 1'b1;
                    pc <= jalr_result;
                end 
                else if (instruction[6:0] == S_TYPE) begin
                    writemem_en <= 1'b1;

                    state <= MEMORY_OP_WAIT;
                end
                else if (instruction[6:0] == I_TYPE_LOAD) begin
                    readmem_en <= 1'b1;

                    state <= MEMORY_OP_WAIT;
                end
                else begin
                    regwrite_en <= 1'b1;
                    pc <= pc + 32'd4;
                end
            end

            MEMORY_OP_WAIT: begin
                if (~busy) begin
                    state <= FETCH;
                    regwrite_en <= 1'b1;
                    write_value <= memory_read_data;
                    pc <= pc + 32'd4;

                    label <= "memory op completed: ";
                    data <= memory_read_data;
                    send <= 1'b1;
                end
            end
        endcase
    end
end

GSR gsr_inst (
    .GSRI(~button0_filtered)
);

endmodule