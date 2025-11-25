module pg_generator(
    input [3:0] a,
    input [3:0] b,
    input carry_in,
    output [3:0] p,
    output [3:0] g
);

assign p[3:0] = ~(a ^ b);
assign g[3:0] = ~(a & b);

endmodule

module lookahead(
    input [3:0] p, 
    input [3:0] g,
    input carry_in,
    output [3:0] carry,
    output carry_out,
    output P,
    output G
);

assign G = g[3] & (p[3] | g[2]) & (p[3] | p[2] | g[1]) & (p[3] | p[2] | p[1] | g[0]);
assign P = |p;
assign carry[3:0] = {g[2] & (p[2] | g[1]) & (p[2] | p[1] | g[0]) & (p[2] | p[1] & p[0] | carry_in), g[1] & (p[1] | g[0]) & (p[1] | p[0] | carry_in), g[0] & (p[0] | carry_in), carry_in};
assign carry_out = G & (P | carry_in);

endmodule