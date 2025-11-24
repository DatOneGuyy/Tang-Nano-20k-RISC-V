module alu(
    input [31:0] pc,
    input signed [31:0] op1,
    input signed [31:0] op2,
    input [31:0] instruction,
    output reg signed [31:0] result,
    output reg [31:0] jalr,
    output reg comparison_flag
);

localparam R_TYPE = 7'b0110011;
localparam I_TYPE = 7'b0010011;
localparam I_TYPE_LOAD = 7'b0000011;
localparam S_TYPE = 7'b0100011;
localparam B_TYPE = 7'b1100011;
localparam J_TYPE = 7'b1101111;
localparam J_TYPE_LINK = 7'b1100111;
localparam LUI_TYPE = 7'b0110111;
localparam AUIPC_TYPE = 7'b0010111;

wire [31:0] uop1 = op1;
wire [31:0] uop2 = op2;

wire [6:0] opcode = instruction[6:0];
wire [3:0] funct3 = instruction[14:12];
wire [6:0] funct7 = instruction[31:25];

wire [31:0] upper_imm = {uop2[19:0], 12'b0};

reg lower_carry;
reg lower_borrow;
reg [15:0] lower_sum;
reg [15:0] lower_difference;
reg [31:0] sum;
reg [31:0] difference;

always @(*) begin
    {lower_carry, lower_sum} = op1[15:0] + op2[15:0];
    {lower_borrow, lower_difference} = op1[15:0] - op2[15:0];

    sum[31:16] = op1[31:16] + op2[31:16] + lower_carry;
    sum[15:0] = lower_sum;

    difference[31:16] = op1[31:16] - op2[31:16] - lower_borrow;
    difference[15:0] = lower_difference;
end

reg auipc_carry;
reg [15:0] auipc_lower_sum;
reg [31:0] auipc_sum;

always @(*) begin
    {auipc_carry, auipc_lower_sum} = pc[15:0] + upper_imm[15:0];
    auipc_sum[31:16] = pc[31:16] + upper_imm[31:16] + auipc_carry;
    auipc_sum[15:0] = auipc_lower_sum;
end

always @(*) begin
    result = 32'b0;
    jalr = 32'b0;
    comparison_flag = 1'b0;

    case (opcode)
        R_TYPE, I_TYPE: begin
            case (funct3)
                3'h0: result = (funct7[5] & opcode[5]) ? difference : sum;
                3'h1: result = uop1 << uop2[4:0];
                3'h2: result = {31'b0, (op1 < op2)};
                3'h3: result = {31'b0, (uop1 < uop2)};
                3'h4: result = uop1 ^ uop2;
                3'h5: result = funct7[5] ? (uop1 >>> uop2[4:0]) : (uop1 >> uop2[4:0]);
                3'h6: result = uop1 | uop2;
                3'h7: result = uop1 & uop2;
                default: result = 32'b0;
            endcase
        end

        I_TYPE_LOAD, S_TYPE: result = sum;

        B_TYPE: comparison_flag = (funct3[2] ? ((funct3[1]) ? (uop1 < uop2) : (op1 < op2)) : (uop1 == uop2)) ^ funct3[0];

        J_TYPE, J_TYPE_LINK: begin
            result = {16'b0, pc[15:2] + 14'b1, 2'b0}; // PC+4
            jalr = sum;
        end

        LUI_TYPE: result = upper_imm;
        AUIPC_TYPE: result = auipc_sum;
        
        default: result = 32'b0;
    endcase
end

endmodule