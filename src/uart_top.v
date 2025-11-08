module uart_test(
	input                        clk,
	input                        rst,
	input                        uart_rx,
    input                        send,
    input [255:0]                label,
    input [63:0]                 data,
    input [1023:0]               register_data,
	output                       uart_tx
);

parameter                        LABEL_LENGTH = 32;
parameter                        DATA_LENGTH = 8;
parameter                        REGISTER_LENGTH = 128;
parameter                        CLK_FRE  = 101; //Mhz
parameter                        UART_FRE = 115200; //hz
localparam                       IDLE =  0;
localparam                       SEND_LABEL =  1; //send 
localparam                       WAIT =  2; //wait 1 second and send uart received data
localparam                       SEND_DATA = 3;
localparam                       SEND_REGISTERS = 4;
reg [7:0]                        tx_data;
reg [7:0]                        tx_str;
reg                              tx_data_valid;
wire                             tx_data_ready;
reg [7:0]                        tx_cnt;
wire [7:0]                       rx_data;
wire                             rx_data_valid;
wire                             rx_data_ready;
reg [31:0]                       wait_cnt;
reg [3:0]                        state;

wire rst_n = !rst;

assign rx_data_ready = 1'b1; //always can receive data,

reg [7:0] counter;

always @(posedge clk or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		wait_cnt <= 32'd0;
		tx_data <= 8'd0;
		state <= IDLE;
		tx_cnt <= 8'd0;
		tx_data_valid <= 1'b0;
	end
	else
        case (state)
            IDLE: begin
                if (tx_data_ready) begin
                    state <= WAIT;
                    counter <= 0;
                end
            end
            SEND_REGISTERS: begin
                tx_data <= tx_str;

                if (tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < REGISTER_NUM - 1) begin
                    tx_cnt <= tx_cnt + 8'd1;
                end
                else if (tx_data_valid && tx_data_ready) begin
                    tx_cnt <= 8'd0;
                    tx_data_valid <= 1'b0;
                    state <= SEND_LABEL;
                end
                else if (~tx_data_valid) begin
                    tx_data_valid <= 1'b1;
                end
            end
            SEND_LABEL: begin
                tx_data <= tx_str;

                if (tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < LABEL_NUM - 1) begin
                    tx_cnt <= tx_cnt + 8'd1;
                end
                else if (tx_data_valid && tx_data_ready) begin
                    tx_cnt <= 8'd0;
                    tx_data_valid <= 1'b0;
                    state <= SEND_DATA;
                end
                else if (~tx_data_valid) begin
                    tx_data_valid <= 1'b1;
                end
            end
            SEND_DATA: begin
                tx_data <= tx_str;

                if (tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < DATA_NUM - 1) begin
                    tx_cnt <= tx_cnt + 8'd1;
                end
                else if (tx_data_valid && tx_data_ready) begin
                    tx_cnt <= 8'd0;
                    tx_data_valid <= 1'b0;
                    state <= WAIT;
                end
                else if (~tx_data_valid) begin
                    tx_data_valid <= 1'b1;
                end
            end
            WAIT: begin
                if (send) begin
                    state <= SEND_REGISTERS;
                    counter <= counter + 8'b1;
                end
            end
            default:
                state <= IDLE;
        endcase
end

parameter endl = 8'h0a;
parameter endlabel = 16'h3a20;
parameter errorlabel = "Invalid transmitter state";
parameter LABEL_NUM = LABEL_LENGTH + 0;
parameter DATA_NUM = DATA_LENGTH + 1;
parameter REGISTER_NUM = REGISTER_LENGTH + 0;

wire [LABEL_NUM * 8 - 1:0] send_label = {label}; // append endlabel to include colon
wire [DATA_NUM * 8 - 1:0] send_data = {data, endl};
wire [REGISTER_NUM * 8 - 1:0] send_register = {register_data};
wire [LABEL_NUM * 8 - 1:0] send_error = {errorlabel, endl};

always @(*) begin
    case (state)
        SEND_REGISTERS:
            tx_str <= send_register[(REGISTER_NUM - 1 - tx_cnt) * 8 +: 8];
        SEND_LABEL:
	        tx_str <= send_label[(LABEL_NUM - 1 - tx_cnt) * 8 +: 8];
        SEND_DATA:
            tx_str <= send_data[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
        default:
            tx_str <= send_error[(LABEL_NUM - 1 - tx_cnt) * 8 +: 8];
    endcase
end

uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.rx_data                    (rx_data                  ),
	.rx_data_valid              (rx_data_valid            ),
	.rx_data_ready              (rx_data_ready            ),
	.rx_pin                     (uart_rx                  )
);

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);
endmodule