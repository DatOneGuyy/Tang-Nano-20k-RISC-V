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

module cla_16bits(
    input [15:0] a,
    input [15:0] b,
    input carry_in,
    output [15:0] sum,
    output carry_out
);

wire [15:0] p;
wire [15:0] g;
wire [3:0] top_carry;
pg_generator pg_4(
    .a(a[3:0]),
    .b(b[3:0]),
    .carry_in(carry_in),
    .p(p[3:0]),
    .g(g[3:0])
);
pg_generator pg_8(
    .a(a[7:4]),
    .b(b[7:4]),
    .carry_in(top_carry[1]),
    .p(p[7:4]),
    .g(g[7:4])
);
pg_generator pg_12(
    .a(a[11:8]),
    .b(b[11:8]),
    .carry_in(top_carry[2]),
    .p(p[11:8]),
    .g(g[11:8])
);
pg_generator pg_16(
    .a(a[15:12]),
    .b(b[15:12]),
    .carry_in(top_carry[3]),
    .p(p[15:12]),
    .g(g[15:12])
);

wire [15:0] carry;
wire [3:0] P;
wire [3:0] G;
lookahead lookahead4(
    .p(p[3:0]),
    .g(g[3:0]),
    .carry_in(carry_in),
    .carry(carry[3:0]),
    .P(P[0]),
    .G(G[0])
);
lookahead lookahead8(
    .p(p[7:4]),
    .g(g[7:4]),
    .carry_in(top_carry[1]),
    .carry(carry[7:4]),
    .P(P[1]),
    .G(G[1])
);
lookahead lookahead12(
    .p(p[11:8]),
    .g(g[11:8]),
    .carry_in(top_carry[2]),
    .carry(carry[11:8]),
    .P(P[2]),
    .G(G[2])
);
lookahead lookahead16(
    .p(p[15:12]),
    .g(g[15:12]),
    .carry_in(top_carry[3]),
    .carry(carry[15:12]),
    .P(P[3]),
    .G(G[3])
);
lookahead lookahead_combined(
    .p(P),
    .g(G),
    .carry_in(carry_in),
    .carry(top_carry),
    .carry_out(carry_out)
);

assign sum = carry ^ p;

endmodule

module cla_32bits(
    input [31:0] a,
    input [31:0] b,
    output [31:0] sum
);

wire lower_carry_out;
cla_16bits lower(
    .a(a[15:0]),
    .b(b[15:0]),
    .carry_in(1'b1),
    .sum(sum[15:0]),
    .carry_out(lower_carry_out)
);

wire [15:0] upper_sum0;
wire [15:0] upper_sum1;
wire carry_out0, carry_out1;
cla_16bits upper0(
    .a(a[31:16]),
    .b(b[31:16]),
    .carry_in(1'b0),
    .sum(upper_sum0)
);
cla_16bits upper1(
    .a(a[31:16]),
    .b(b[31:16]),
    .carry_in(1'b1),
    .sum(upper_sum1)
);

assign sum[31:16] = lower_carry_out ? upper_sum1 : upper_sum0;

endmodule