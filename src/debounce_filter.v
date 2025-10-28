module debounce_filter(
    input clk,
    input button,
    output reg filtered
);

localparam CYCLES_BETWEEN_CHANGES = 100000;
localparam INIT = 0;
localparam ACTIVE = 1;

reg state;

reg [31:0] last_change;
wire previous_button;

dff button_dff(clk, button, previous_button);

always @(posedge clk) begin
    case (state)
        ACTIVE: begin
            if (button ^ previous_button) begin
                if (last_change > CYCLES_BETWEEN_CHANGES) begin
                    filtered <= button;
                    last_change <= 32'b0;
                end
            end
            else begin
                if (last_change > CYCLES_BETWEEN_CHANGES + 1) begin
                    last_change <= CYCLES_BETWEEN_CHANGES + 1;
                end
                else begin
                    last_change <= last_change + 32'b1;
                end
            end
        end
        INIT: begin
            last_change <= 0;
            state <= ACTIVE;
        end
    endcase
end

endmodule

module dff(input clk, input d, output reg q);

always @(posedge clk) begin
    q <= d;
end

endmodule