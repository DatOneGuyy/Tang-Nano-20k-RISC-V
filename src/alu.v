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

always @(*) begin
    result = 32'b0;
    jalr = 32'b0;
    comparison_flag = 1'b0;

    case (opcode)
        R_TYPE, I_TYPE: begin
            case (funct3)
                3'h0: begin
                    if (funct7[5] & opcode[5]) begin
                        result = op1 - op2;
                    end
                    else begin
                        result = op1 + op2;
                    end
                end

                3'h1: begin //shift left
                    result = uop1 << uop2[4:0];
                end

                3'h2: begin //less than
                    result = {31'b0, (op1 < op2)};
                end

                3'h3: begin //unsigned less than
                    result = {31'b0, (uop1 < uop2)};
                end

                3'h4: begin //xor
                    result = uop1 ^ uop2;
                end

                3'h5: begin
                    if (funct7[5]) begin
                        result = uop1 >>> uop2[4:0];
                    end
                    else begin
                        result = uop1 >> uop2[4:0];
                    end
                end

                3'h6: begin //or
                    result = uop1 | uop2;
                end

                3'h7: begin //and
                    result = uop1 & uop2;
                end
            endcase
        end

        I_TYPE_LOAD, S_TYPE: begin
            result = op1 + op2;
        end

        B_TYPE: begin
            comparison_flag = (funct3[2] ? ((funct3[1]) ? (uop1 < uop2) : (op1 < op2)) : (uop1 == uop2)) ^ funct3[0];
        end

        J_TYPE, J_TYPE_LINK: begin
            result = {16'b0, pc[15:2] + 14'b1, 2'b0};
            jalr = op1 + op2;
        end

        LUI_TYPE: begin
            result = uop2 << 12;
        end

        AUIPC_TYPE: begin
            result = pc + (uop2 << 12);
        end
    endcase
end

endmodule