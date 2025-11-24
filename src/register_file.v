module register_file(
    input clk,

    input read1_en,
    input read2_en,
    input write1_en,
    input regwrite_en,

    input [4:0] read1_dest,
    input [4:0] read2_dest,
    input [4:0] write1_dest,

    input [31:0] write_value,

    output reg [31:0] read_value1,
    output reg [31:0] read_value2,

    output reg [1023:0] full_file
);

reg [31:0] combined [0:31];

always @(posedge clk) begin
    read_value1 <= 32'b0;
    read_value2 <= 32'b0;

    if (read1_en) begin
        read_value1 <= combined[read1_dest];
    end

    if (read2_en) begin
        read_value2 <= combined[read2_dest];
    end

    if (write1_en & regwrite_en & write1_dest != 5'b0) begin
        combined[write1_dest] <= write_value;
    end

    full_file <= {combined[31], combined[30], combined[29], combined[28], combined[27], combined[26], combined[25], combined[24], combined[23], combined[22], combined[21], combined[20], combined[19], combined[18], combined[17], combined[16], combined[15], combined[14], combined[13], combined[12], combined[11], combined[10], combined[9], combined[8], combined[7], combined[6], combined[5], combined[4], combined[3], combined[2], combined[1], combined[0]};
end

endmodule