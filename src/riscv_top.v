module riscv_top(
    input                        clkin,
	input                        uart_rx,
    input                        button0,
    input                        button1,

	output                       uart_tx,
    output                       led0,
    output                       led1,
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

wire clkoutp, clk;

Gowin_rPLL rpll_clk(.clkin(clkin), .clkoutp(clkoutp), .clkout(clk));

reg send_cmd;
reg [2:0] cmd;
reg [2:0] write_type;
reg [31:0] addr; 
wire [31:0] memory_write_data;
wire init_done, mem_op_done;
wire [31:0] memory_read_out;

localparam INIT = 0;
localparam FETCH = 1;
localparam EXEC = 2;
localparam MEMORY_OP_WAIT = 3;
localparam HALT = 4;

reg [29:0] counter;

reg [2:0] state;

wire debug_send;
reg [255:0] debug_label;
reg [63:0] debug_data;

reg send_data;

wire button0_filtered, button0_filtered_p;
wire button1_filtered, button1_filtered_p;

wire [31:0] instruction;
reg [31:0] pc;
reg read_program;

wire [1023:0] registers;

debounce_filter button0_f(.clk(clk), .button(button0), .filtered(button0_filtered));
debounce_filter button1_f(.clk(clk), .button(button1), .filtered(button1_filtered));
debugger debug(.clk(clk), .rst(button0), .uart_rx(uart_rx), .debug_send(send_data), .label(debug_label), .data(debug_data), .register_data(registers), .uart_tx(uart_tx));

instruction_fetch instruction_reader(.clk(read_program), .pc(pc), .instruction(instruction));

wire read1_en;
wire read2_en;
wire write1_en;

wire [4:0] read1_dest;
wire [4:0] read2_dest;
wire [4:0] write1_dest;

reg [31:0] write_value;

wire [31:0] read_value1;
wire [31:0] read_value2;

wire [31:0] operand1;
wire [31:0] operand2;
wire [31:0] alu_result;
wire comparison_flag;

wire [31:0] jalr_pc_assignment;
wire [31:0] jump_immediate;

reg reg_write_from_mem;

wire jal;
wire jalr;

wire regwrite_en = (~clk & (state == FETCH)) | (reg_write_from_mem);

register_file regs(.clk(clk), .read1_en(read1_en), .read2_en(read2_en), .write1_en(write1_en), .read1_dest(read1_dest), .read2_dest(read2_dest), .write1_dest(write1_dest), .write_value(write_value), .regwrite_en(regwrite_en), .read_value1(read_value1), .read_value2(read_value2), .full_file(registers));

alu ALU(.pc(pc), .op1(operand1), .op2(operand2), .instruction(instruction), .result(alu_result), .jalr(jalr_pc_assignment), .comparison_flag(comparison_flag));

operand_controller opcon(.register_read1(read_value1), .register_read2(read_value2), .instruction(instruction), .alu_op1(operand1), .alu_op2(operand2), .jump_immediate(jump_immediate), .memory_write_data(memory_write_data));

control_unit controller(.instruction(instruction), .read1_en(read1_en), .read2_en(read2_en), .write1_en(write1_en), .read1_dest(read1_dest), .read2_dest(read2_dest), .write1_dest(write1_dest), .jal(jal), .jalr(jalr));

memory_controller system_memory(
    .clk(clk), 
    .rpll_clk(clkoutp),

    .instruction(instruction),
    .cpu_state(state),
    .write_type(instruction[14:12]),
    .addr(alu_result),
    .write_data(memory_write_data),

    .init_done(init_done),
    .operation_done(mem_op_done),
    .memory_read_out(memory_read_out),

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

wire byte_output;

reg [31:0] pc_increment;

reg memory_indicator;

assign led0 = memory_indicator;
assign led1 = 0;

wire [6:0] funct7 = instruction[31:25];
reg [31:0] read_cycles;
reg [31:0] write_cycles;

localparam CYCLE_DELAY = 0;

always @(posedge clk) begin
    if (counter < CYCLE_DELAY) begin
        counter <= counter + 30'b1;
        send_data <= 1'b0;
    end
    else begin
        counter <= 30'b0;
        case (state)
            INIT: begin
                send_data <= 1'b0;
                memory_indicator <= 1'b1;
                reg_write_from_mem <= 1'b0;
                pc <= 0;

                if (init_done) begin
                    state <= FETCH;
                end
            end

            FETCH: begin
                read_program <= 1'b1;
                memory_indicator <= 1'b1;
                reg_write_from_mem <= 1'b0;
                send_data <= 1'b0;

                state <= EXEC;
            end
            
            EXEC: begin
                read_program <= 1'b0;
                memory_indicator <= 1'b1;
                reg_write_from_mem <= 1'b0;
                send_data <= 1'b0;

                if (pc == 400) begin
                    send_data <= 1'b1;
                    debug_label <= "[operand1]: ";
                    debug_data <= registers[{read1_dest, 5'b0} +: 32] & {32{read1_en}};
                end

                if (comparison_flag | jal) begin
                    pc <= pc + jump_immediate;
                    state <= FETCH;
                end
                else if (jalr) begin
                    pc <= jalr_pc_assignment;
                    state <= FETCH;
                end
                else if (instruction[6:2] == 5'b00000 | instruction[6:2] == 5'b01000) begin
                    state <= MEMORY_OP_WAIT;
                end
                else begin
                    pc <= pc + 4;
                    state <= FETCH;
                end

                write_value <= alu_result;
            end

            MEMORY_OP_WAIT: begin
                memory_indicator <= 1'b0;
                send_data <= 1'b0;

                if (~instruction[5]) 
                    read_cycles <= read_cycles + 1;
                else
                    write_cycles <= write_cycles + 1;
                
                if (mem_op_done) begin
                    reg_write_from_mem <= 1'b1;
                    write_value <= memory_read_out;

                    pc <= pc + 4;
                    state <= FETCH;
                end
            end

            HALT: begin

            end

            default:
                state <= FETCH;
        endcase
    end
end

GSR gsr_inst (
    .GSRI(~button0_filtered)
);

endmodule