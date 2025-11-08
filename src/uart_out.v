module uart_out(
    input clk,
    input send_data,
    output reg debug_send
);

localparam DEBUG_DELAY_CYCLES = 592674;

localparam INIT_DEBUG = 0;
localparam WAIT_DEBUG = 1;
localparam SEND_DEBUG = 2;
localparam BLOCK_DEBUG = 3;

reg [17:0] debug_block_counter;

reg [1:0] DEBUG_STATE;

always @(posedge clk) begin
    case (DEBUG_STATE) 
        INIT_DEBUG: begin
            debug_send <= 1'b0;

            debug_block_counter <= 18'b0;

            DEBUG_STATE <= BLOCK_DEBUG;
        end

        WAIT_DEBUG: begin
            debug_block_counter <= 18'b0;

            if (send_data) begin
                DEBUG_STATE <= SEND_DEBUG;
            end
            else begin
                debug_send <= 1'b0;
            end
        end

        SEND_DEBUG: begin
            debug_send <= 1'b1;
            debug_block_counter <= 18'b0;
            DEBUG_STATE <= BLOCK_DEBUG;
        end

        BLOCK_DEBUG: begin
            debug_send <= 1'b0;

            if (debug_block_counter < DEBUG_DELAY_CYCLES) begin
                debug_block_counter <= debug_block_counter + 1'b1;
            end
            else begin
                debug_block_counter <= 18'b0;
                DEBUG_STATE <= WAIT_DEBUG;
            end 
        end

        default: begin
            DEBUG_STATE <= WAIT_DEBUG;
        end
    endcase
end

endmodule