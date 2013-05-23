
`include "def_ex3.v"

module vector_info (clk, com_ctl, update, vec_idx, interval, data);
    /// below 3 parameters should be redefined at module instantiation
    parameter port_id = 0;
    parameter vector_size = `INPUT_VECTOR_SIZE;
    parameter filename = "bogus_file";

    input         clk;
    input  [1:0]  com_ctl;
    input         update;
    output [15:0] vec_idx;
    output [15:0] interval;
    output [15:0] data;
    reg    [17:0] in_vector[0:vector_size - 1];
    reg    [15:0] vec_idx, interval, data;

    initial begin
        for(vec_idx = 0; vec_idx < vector_size; vec_idx = vec_idx + 1)
            in_vector[vec_idx] = 18'h3ffff;
        $readmemh(filename, in_vector);
    end

task update_idx;
    input  [15:0] cur_idx;
    reg    [15:0] i, ii, flag;
    reg    [17:0] vec, vec2;
    begin
       flag = 0;
       vec_idx <= cur_idx;
       interval <= 16'hffff;
       data     <= 0;
       for(i = 0; i < vector_size && !flag; i = i + 2) begin
           ii = cur_idx + i;
           if(ii >= vector_size) ii = ii - vector_size;
           vec = in_vector[ii];
           vec2 = in_vector[ii + 1];
           if(vec2[17:16] == {port_id, 1'b1} && vec2[15:0] != 16'hffff) begin
               vec_idx  <= ii;
               interval <= vec[15:0];
               data     <= vec2[15:0];
               flag = 1;
           end
       end
    end
endtask
    
    always @ (posedge clk) begin
        if(com_ctl == `COM_RST) update_idx(16'b0);
        else if(update)         update_idx(vec_idx + 2);
    end

endmodule


/*********************** generic input device model *************************/

module input_model (clk, com_ctl, fgi, fgi_bsy, inpr, sc_clr);

    input         clk;
    input  [1:0]  com_ctl;
    input         fgi;
    output        fgi_bsy;
    output [7:0]  inpr;
    input         sc_clr;
  
    reg    [7:0]  inpr;
    reg    [7:0]  interval;
    reg           pending;

    wire   [15:0] vec_interval, vec_data;
    wire   [15:0] vec_idx;

    wire          activate     = ~pending & ~fgi;
    wire          fgi_set_n    = ~((com_ctl == `COM_RUN) & ~fgi & (interval == 8'h0));

	assign        fgi_bsy      = ~pending | fgi_set_n;

    vector_info #(0, `INPUT_VECTOR_SIZE, `INPUT_VECTOR_FILE)
                IN_VEC (clk, com_ctl, ~fgi_set_n, vec_idx, vec_interval, vec_data);

    always @ (posedge clk) begin
        if(com_ctl == `COM_RST) begin
            inpr        <= 8'b0;
            pending     <= 1'b0;
            interval    <= 8'hff; // -1
        end
        else begin
            if(activate) begin
                interval <= vec_interval[7:0];
                pending  <= 1'b1;
                $display($stime, " [P_IN] in.interval = %d", vec_interval[7:0]);
            end
            if(~fgi_set_n) begin
                inpr     <= vec_data[7:0];
                pending  <= 1'b0;
                $display($stime, " [P_IN] in.data[%d] = %h", (vec_idx >> 1), vec_data[7:0]);
            end
            if(sc_clr && interval[7] == 1'b0) interval <= interval - 1'b1;
        end
    end

endmodule

/*********************** generic output device model *************************/

module output_model (clk, com_ctl, fgo, fgo_bsy, outr, sc_clr);

    input         clk;
    input  [1:0]  com_ctl;
    input         fgo;
    output        fgo_bsy;
    input [7:0]   outr;
    input         sc_clr;
	
    reg    [7:0]  interval;
    reg           pending;

    wire   [15:0] vec_interval, vec_data;
    wire   [15:0] vec_idx;

    wire          activate     = ~pending & ~fgo;
    wire          fgo_set_n    = ~((com_ctl == `COM_RUN) & ~fgo & pending & (interval == 8'h0));
	assign        fgo_bsy      = ~pending | fgo_set_n;

    vector_info #(0, `OUTPUT_VECTOR_SIZE, `OUTPUT_VECTOR_FILE)
                OUT_VEC (clk, com_ctl, ~fgo_set_n, vec_idx, vec_interval, vec_data);

    always @ (posedge clk) begin
        if(com_ctl == `COM_RST) begin
            pending    <= 1'b0;
            interval   <= 8'hff; // -1
        end
        else begin
            if(activate) begin
                interval <= vec_interval[7:0];
                pending  <= 1'b1;
                $display($stime, " [P_OUT] out.interval = %d", vec_interval[7:0]);
            end
            if(~fgo_set_n) begin
                pending  <= 1'b0;
                $display($stime, " [P_OUT] out.data = %h, vec_data[%d] = %h, check(%b)", 
                          outr, (vec_idx >> 1), vec_data[7:0], (outr == vec_data[7:0]));
            end
            if(sc_clr && interval[7] == 1'b0) interval <= interval - 1'b1;
        end
    end

endmodule

/*********************** UART input device model *************************/

module uart_input_model (clk, com_ctl, fgi, uart_rxd);

    input         clk;
    input  [1:0]  com_ctl;
    input         fgi;
    output        uart_rxd;
	
    reg           pending;

    wire   [15:0] vec_interval, vec_data, vec_idx;

    reg    [7:0]  tx_byte;
    wire          UART_TXD;
    assign        uart_rxd = UART_TXD;
    wire          tx_rdy;

    uart_tx #1 UART_TX (clk, (com_ctl == `COM_RST), UART_TXD, tx_byte, ~pending, tx_rdy);

    wire          activate = ~pending & ~fgi & tx_rdy;

    vector_info #(1, `INPUT_VECTOR_SIZE, `INPUT_VECTOR_FILE)
                IN_VEC (clk, com_ctl, activate, vec_idx, vec_interval, vec_data);

    always @ (posedge clk) begin
        if(com_ctl == `COM_RST)
            pending  <= 1'b0;
        else if(activate) begin
            pending  <= 1'b1;
            tx_byte  <= vec_data[7:0];
            $display($stime, " [S_IN] in.data[%d] = %h (%s)", (vec_idx >> 1), vec_data[7:0], `GET_CHAR(vec_data[7:0]));
        end
        if(pending) pending  <= 1'b0;
    end

endmodule

/*********************** UART output device model *************************/

module uart_output_model (clk, com_ctl, uart_txd);

    parameter output_vector_size = 256;	///	modify this if your program takes more inputs than this...
    parameter str_size = `OUTPUT_VECTOR_SIZE * 4 - 1;

    input         clk;
    input  [1:0]  com_ctl;
    input         uart_txd;
	
    wire   [15:0] vec_idx, vec_interval, vec_data;

    reg    [str_size:0]  str_vec;
    reg    [str_size:0]  str_rx;

    initial begin
        str_vec = 0;
        str_rx = 0;
    end

    wire   [14:0] str_idx      = vec_idx[15:1];

    wire   [7:0]  rx_byte;
    wire          UART_RXD = uart_txd;
    wire          rx_rdy, rx_error;

    reg           prev_rx_rdy;

    uart_rx #1 UART_RX (clk, (com_ctl == `COM_RST), UART_RXD, rx_byte, rx_error, rx_rdy);

    wire          activate = rx_rdy & ~prev_rx_rdy;

    vector_info #(1, `OUTPUT_VECTOR_SIZE, `OUTPUT_VECTOR_FILE)
                OUT_VEC (clk, com_ctl, activate, vec_idx, vec_interval, vec_data);

    always @ (posedge clk) begin
        if(com_ctl == `COM_RST) begin
            prev_rx_rdy <= 1'b0;
        end
        else begin
            prev_rx_rdy <= rx_rdy;
            if(activate) begin
                str_vec = {vec_data[7:0], str_vec[str_size : str_size - 8]};
                str_rx = {rx_byte[7:0], str_rx[str_size : str_size - 8]};
                $display($stime, " [S_OUT] out.data = %h (%s), vec_data[%d] = %h (%s), check(%b)",
                         rx_byte, `GET_CHAR(rx_byte), (vec_idx >> 1), 
                         vec_data[7:0], `GET_CHAR(vec_data[7:0]),
                         (rx_byte == vec_data[7:0]));
            end
        end
    end

endmodule

/*********************** instruction display helper module *************************/

module insn_string_gen(ir, intr_flg, ir_name, ir_addr, ir_flag);

    parameter ir_str_length_0 = 3;
    parameter ir_str_length_1 = 4;
    parameter ir_str_length_2 = 2;

    input  [15:0] ir;
    input         intr_flg;

    output [8 * ir_str_length_0 - 1 : 0] ir_name;
    output [8 * ir_str_length_1 - 1 : 0] ir_addr;
    output [8 * ir_str_length_2 - 1 : 0] ir_flag;

function [8 * ir_str_length_0 - 1 : 0] get_insn_name;
    input [15:0] ir;
    input        intr;
    if(intr)
        get_insn_name = "INT";
    else case(ir[14:12])
        3'h0 : get_insn_name = "AND";
        3'h1 : get_insn_name = "ADD";
        3'h2 : get_insn_name = "LDA";
        3'h3 : get_insn_name = "STA";
        3'h4 : get_insn_name = "BUN";
        3'h5 : get_insn_name = "BSA";
        3'h6 : get_insn_name = "ISZ";
        3'h7 :
            if(~ir[15]) case(ir[11:0])
                12'h800 : get_insn_name = "CLA";
                12'h400 : get_insn_name = "CLE";
                12'h200 : get_insn_name = "CMA";
                12'h100 : get_insn_name = "CME";
                12'h080 : get_insn_name = "CIR";
                12'h040 : get_insn_name = "CIL";
                12'h020 : get_insn_name = "INC";
                12'h010 : get_insn_name = "SPA";
                12'h008 : get_insn_name = "SNA";
                12'h004 : get_insn_name = "SZA";
                12'h002 : get_insn_name = "SZE";
                12'h001 : get_insn_name = "HLT";
                default : get_insn_name = "???";
            endcase
            else case(ir[11:0])
                12'h800 : get_insn_name = "INP";
                12'h400 : get_insn_name = "OUT";
                12'h200 : get_insn_name = "SKI";
                12'h100 : get_insn_name = "SKO";
                12'h080 : get_insn_name = "ION";
                12'h040 : get_insn_name = "IOF";
                12'h020 : get_insn_name = "SIO";
                12'h010 : get_insn_name = "PIO";
                12'h008 : get_insn_name = "IMK";
                default : get_insn_name = "???";
            endcase
        default : get_insn_name = "???";
    endcase
endfunction

function [7:0] get_hex_string;
input [3:0] val;
    if(val < 4'ha)  get_hex_string = 8'h30 + val;        ///  0x30 = '0'
    else            get_hex_string = 8'h61 + val - 4'ha; ///  0x61 = 'a'
endfunction

function [8 * ir_str_length_1 - 1 : 0] get_insn_addr;
input [15:0] ir;
input        intr;
    if(intr)                   get_insn_addr = "ERRU";
    else if(ir[14:12] == 3'h7) get_insn_addr = "    ";
    else begin
                               get_insn_addr[31:24] = 8'h20; /// 0x20 = ' ' (white-space)
                               get_insn_addr[23:16] = get_hex_string(ir[11:8]);
                               get_insn_addr[15:8]  = get_hex_string(ir[7:4]);
                               get_insn_addr[7:0]   = get_hex_string(ir[3:0]);
	end
endfunction

function [8 * ir_str_length_2 - 1 : 0] get_insn_flag;
input [15:0] ir;
input        intr;
	if(intr)                                     get_insn_flag = "PT";
	else if(ir[14:12] != 3'h7 && ir[15] == 1'b1) get_insn_flag = " I";
	else                                         get_insn_flag = "  ";
endfunction

    assign ir_name = get_insn_name(ir, intr_flg);
    assign ir_addr = get_insn_addr(ir, intr_flg);
    assign ir_flag = get_insn_flag(ir, intr_flg);

endmodule
