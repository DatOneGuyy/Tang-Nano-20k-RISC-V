module instruction_fetch(
    input clk,
    input [31:0] pc,
    output reg [31:0] instruction
);

(* ram_style = "block" *)
reg [31:0] mem [0:16383];
wire [13:0] addr = pc[15:2];

initial begin
    $readmemh("programs/fib.mem", mem);
end

always @(posedge clk) begin
    instruction <= mem[addr];
end

endmodule