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
reg [2:0] cmd, write_type;
reg [31:0] addr, write_data;
wire init_done, cmd_done;
wire [31:0] memory_read_out;

memory_controller system_memory(
    .clk(clk), 
    .rpll_clk(clkoutp),

    .send_cmd(send_cmd),
    .cmd(cmd),
    .write_type(write_type),
    .addr(addr),
    .write_data(write_data),

    .init_done(init_done),
    .cmd_done(cmd_done),
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

localparam INIT = 0;
localparam FETCH = 1;
localparam EXEC = 2;
localparam FREEZE = 3;

localparam CLOCK_REDUCTION = 25;

reg [63:0] counter;

reg [1:0] state;

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
debugger debug(.clk(clk), .rst(button0), .uart_rx(uart_rx), .debug_send(debug_send), .label(debug_label), .data(debug_data), .register_data(registers), .uart_tx(uart_tx));
uart_out debug_limiter(.clk(clk), .send_data(send_data), .debug_send(debug_send));

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

wire reg_write_from_mem;
wire mem_read_en;
wire mem_write_en;

wire jal;
wire jalr;

wire regwrite_en = ~clk & (state == FETCH);

register_file regs(.clk(clk), .read1_en(read1_en), .read2_en(read2_en), .write1_en(write1_en), .read1_dest(read1_dest), .read2_dest(read2_dest), .write1_dest(write1_dest), .write_value(write_value), .regwrite_en(regwrite_en), .read_value1(read_value1), .read_value2(read_value2), .full_file(registers));

alu ALU(.pc(pc), .op1(operand1), .op2(operand2), .instruction(instruction), .result(alu_result), .jalr(jalr_pc_assignment), .comparison_flag(comparison_flag));

operand_controller opcon(.register_read1(read_value1), .register_read2(read_value2), .instruction(instruction), .alu_op1(operand1), .alu_op2(operand2), .jump_immediate(jump_immediate));

control_unit controller(.instruction(instruction), .read1_en(read1_en), .read2_en(read2_en), .write1_en(write1_en), .read1_dest(read1_dest), .read2_dest(read2_dest), .write1_dest(write1_dest), .reg_write_from_mem(reg_write_from_mem), .mem_read_en(mem_read_en), .mem_write_en(mem_write_en), .jal(jal), .jalr(jalr));

wire byte_output;

reg [31:0] pc_increment;

assign led0 = 0;
assign led1 = 0;

wire [6:0] funct7 = instruction[31:25];

always @(posedge clk) begin
    if (counter[CLOCK_REDUCTION:0] == 0) begin
        counter <= counter + 64'b1;
        case (state)
            INIT: begin
                pc <= 0;
                state <= FETCH;
            end

            FETCH: begin
                send_data <= 1'b1;
                read_program <= 1'b1;
                
                debug_label <= "program counter: ";
                debug_data <= pc;
                send_data <= 1'b1;

                state <= EXEC;
            end
            
            EXEC: begin
                read_program <= 1'b0;

                debug_label <= "funct7: ";
                debug_data <= funct7[5];
                send_data <= 1'b1;

                if (comparison_flag | jal) begin
                    pc <= pc + jump_immediate;
                end
                else if (jalr) begin
                    pc <= jalr_pc_assignment;
                end
                else begin
                    pc <= pc + 4;
                end

                write_value <= (reg_write_from_mem ? 0 : alu_result);
                state <= FETCH;
            end
 
            default:
                state <= FETCH;
        endcase
    end
    else begin
        send_data <= 1'b0;
        counter <= counter + 1;
    end
end

GSR gsr_inst (
    .GSRI(~button0_filtered)
);

endmodule