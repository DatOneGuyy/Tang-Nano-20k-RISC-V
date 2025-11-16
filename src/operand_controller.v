module operand_controller(
    input [31:0] register_read1,
    input [31:0] register_read2,
    input [31:0] instruction,
    output reg [31:0] alu_op1,
    output reg [31:0] alu_op2,
    output reg [31:0] jump_immediate,
    output reg [31:0] memory_write_data
);

localparam I_TYPE = 7'b0010011;
localparam I_TYPE_LOAD = 7'b0000011;
localparam S_TYPE = 7'b0100011;
localparam B_TYPE = 7'b1100011;
localparam J_TYPE = 7'b1101111;
localparam J_TYPE_LINK = 7'b1100111;
localparam LUI_TYPE = 7'b0110111;
localparam AUIPC_TYPE = 7'b0010111;

wire [6:0] opcode = instruction[6:0];
wire [3:0] funct3 = instruction[14:12];
wire [6:0] funct7 = instruction[31:25];

always @(*) begin
    alu_op1 <= register_read1;
    alu_op2 <= register_read2;
    jump_immediate <= 32'b0;
    memory_write_data <= 32'b0;
    
    case (opcode)
        I_TYPE, I_TYPE_LOAD: begin
            alu_op2[11:0] <= instruction[31:20];
            alu_op2[31:12] <= (funct3 == 7'h3) ? (20'b0) : ({20{alu_op2[11]}});
        end

        S_TYPE: begin
            alu_op2 <= {instruction[31:25], instruction[11:7]};
            case (funct3)
                3'b001: memory_write_data <= register_read2[15:0];
                3'b010: memory_write_data <= register_read2[31:0];
                default: memory_write_data <= register_read2;
            endcase
        end

        LUI_TYPE, AUIPC_TYPE: begin
            alu_op2[20:0] <= {instruction[31:12]};
        end

        B_TYPE: begin
            jump_immediate <= {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        end

        J_TYPE, J_TYPE_LINK: begin
            alu_op2[11:0] <= instruction[31:20];
            jump_immediate <= {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        end
    endcase
end

endmodule