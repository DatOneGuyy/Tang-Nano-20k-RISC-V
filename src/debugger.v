module debugger(
	input                        clk,
	input                        rst,
	input                        uart_rx,
    input                        debug_send,
    input [1023:0]               label,
    input [63:0]                 data,
	output                       uart_tx
);

reg [1:0] state;
localparam WAIT = 0;
localparam SENDING = 1;
localparam INIT = 2;

reg filtered_send;

uart_test uart(
    .clk(clk), 
    .rst(rst), 
    .uart_rx(uart_rx), 
    .send(filtered_send), 
    .label(label), 
    .data(data), 
    .uart_tx(uart_tx)
);

always @(posedge clk) begin
    case (state)
        WAIT: begin
            filtered_send <= 1'b0;
            if (debug_send) begin
                state <= SENDING;
            end
        end
        SENDING: begin
            filtered_send <= 1'b1;
            state <= WAIT;
        end
        INIT: begin
            state <= WAIT;
        end
        default:
            state <= INIT;
    endcase
end

endmodule