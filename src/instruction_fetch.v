module instruction_fetch(
    input clk,
    input [31:0] pc,
    output reg [31:0] instruction
);

(* syn_ramstyle = "block_ram" *)
reg [31:0] mem [0:16383];
wire [13:0] addr = pc[15:2];

initial begin
    $readmemh("programs/simple_mem.mem", mem);
end

always @(posedge clk) begin
    instruction <= mem[addr];
end

endmodule