module register_file(
    input clk,

    input read1_en,
    input read2_en,
    input write1_en,

    input [4:0] read1_dest,
    input [4:0] read2_dest,
    input [4:0] write1_dest,

    input [31:0] write_value,

    output reg [31:0] read_value1,
    output reg [31:0] read_value2
);

reg [1023:0] combined;

always @(posedge clk) begin
    if (read1_en) begin
        read_value1 <= combined[({5'b0, read1_dest} << 5) +: 32];
    end

    if (read2_en) begin
        read_value2 <= combined[({5'b0, read2_dest} << 5) +: 32];
    end

    if (write1_en) begin
        combined[({5'b0, write1_dest} << 5) +: 32] <= write_value;
    end
end

endmodule