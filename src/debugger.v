module debugger(
	input                        clk,
	input                        rst,
	input                        uart_rx,
    input                        debug_send,
    input [255:0]                label,
    input [63:0]                 data,
    input [1023:0]               register_data,
	output                       uart_tx
);

localparam DEBUG_DELAY_CYCLES = 592674;

reg [1:0] state;

localparam INIT = 0;
localparam WAIT = 1;
localparam SENDING = 2;

reg filtered_send;

reg [255:0] label_hold;
reg [63:0] data_hold;
reg [1023:0] registers_hold;

uart_test uart(
    .clk(clk), 
    .rst(rst), 
    .uart_rx(uart_rx), 
    .send(filtered_send), 
    .label(label_hold), 
    .data(data_hold), 
    .register_data(registers_hold),
    .uart_tx(uart_tx)
);

reg [19:0] delay_counter;

always @(posedge clk) begin
    case (state)
        WAIT: begin
            label_hold <= label;
            data_hold <= data;
            registers_hold <= register_data;

            if (debug_send) begin
                filtered_send <= 1'b1;

                state <= SENDING;
            end
            else begin
                filtered_send <= 1'b0;
            end
        end
        SENDING: begin
            filtered_send <= 1'b0;

            if (delay_counter < DEBUG_DELAY_CYCLES) begin
                delay_counter <= delay_counter + 20'b1;
            end
            else begin
                delay_counter <= 20'b0;
                state <= WAIT;
            end
        end
        INIT: begin
            state <= WAIT;
        end
        default:
            state <= INIT;
    endcase
end

endmodule