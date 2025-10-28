module control_unit(
    input [31:0] instruction,

    output reg read1_en,
    output reg read2_en,
    output reg write1_en,

    output reg [4:0] read1_dest,
    output reg [4:0] read2_dest,
    output reg [4:0] write1_dest,

    output reg reg_write_from_mem,
    output reg mem_read_en,
    output reg mem_write_en,

    output reg jal,
    output reg jalr
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

wire [6:0] opcode = instruction[6:0];
wire [6:0] funct3 = instruction[14:12];
wire [6:0] funct7 = instruction[31:25];

always @(*) begin
    reg_write_from_mem <= 1'b0;
    mem_read_en <= 1'b0;
    mem_write_en <= 1'b0;

    jalr <= opcode == J_TYPE_LINK;
    jal <= opcode == J_TYPE;

    read1_dest <= instruction[19:15];
    read2_dest <= instruction[24:20];
    write1_dest <= instruction[11:7];

    read1_en <= 1'b1;
    read2_en <= 1'b1;
    write1_en <= 1'b1;

    case (opcode)
        I_TYPE, I_TYPE_LOAD, J_TYPE, J_TYPE_LINK: begin
            read2_dest <= 5'b0;
            read2_en <= 1'b0;
        end

        S_TYPE, B_TYPE: begin
            write1_dest <= 5'b0;
            write1_en <= 1'b0;
        end

        LUI_TYPE, AUIPC_TYPE: begin
            read1_dest <= 5'b0;
            read2_dest <= 5'b0;

            read1_en <= 1'b0;
            read2_en <= 1'b0;
        end
    endcase
end

endmodule