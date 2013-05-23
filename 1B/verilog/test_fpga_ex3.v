
`include "def_ex3.v"

/*********************** fpga cpu tester *************************/

module test_fpga_ex3;

reg             clk;            //  27 MHz clock
reg     [3:0]   KEY;            //  Pushbutton[3:0]
reg     [9:0]   SW;             //  Toggle Switch[9:0]
wire    [6:0]   HEX0, HEX1, HEX2, HEX3;  //  Seven Segment Digit [3:0]
wire    [7:0]   LEDG;           //  LED Green[7:0]
wire    [9:0]   LEDR;           //  LED Red[9:0]
wire            UART_TXD;       //  UART Transmitter
wire            UART_RXD;       //  UART Receiver
wire    [35:0]  GPIO_0, GPIO_1;	//  GPIO

wire    [15:0]  LED_data = {LEDR[7:0], LEDG};

wire    [1:0]   cpu_state = LEDR[9:8];

fpga_ex3 FPGA_EX3
    (
        ////////////////////	Clock Input	 	////////////////////	 
        clk,                            //  27 MHz
        ////////////////////	Push Button		////////////////////
        KEY,                            //  Pushbutton[3:0]
        ////////////////////	DPDT Switch		////////////////////
        SW,                             //  Toggle Switch[9:0]
        ////////////////////	7-SEG Display	////////////////////
        HEX0,                           //  Seven Segment Digit 0
        HEX1,                           //  Seven Segment Digit 1
        HEX2,                           //  Seven Segment Digit 2
        HEX3,                           //  Seven Segment Digit 3
        ////////////////////////	LED		////////////////////////
        LEDG,                           //  LED Green[7:0]
        LEDR,                           //  LED Red[9:0]
        ////////////////////////	UART	////////////////////////
        UART_TXD,                       //  UART Transmitter
        UART_RXD,                       //  UART Receiver
        ////////////////////	GPIO	////////////////////////////
        GPIO_0,                         //  GPIO Connection 0
        GPIO_1                          //  GPIO Connection 1
    );

    wire    [4:0]   seg7_0, seg7_1, seg7_2, seg7_3;

    seg7_dec SEG7_D0 (HEX0, seg7_0);
    seg7_dec SEG7_D1 (HEX1, seg7_1);
    seg7_dec SEG7_D2 (HEX2, seg7_2);
    seg7_dec SEG7_D3 (HEX3, seg7_3);

    wire    [17:0]	GP_OUT, GP_IN;
    wire            p_fgi, p_fgo, p_fgi_bsy, p_fgo_bsy;
    wire    [7:0]   inpr, outr;

    wire            g1 = (SW[9:8] == `G1);
    wire            g2 = (SW[9:8] == `G2);

    assign GP_OUT           = (g1) ? GPIO_0[35:18] : (g2) ? GPIO_0[17:0] : 18'hfffff;
    assign GPIO_0           = (g1) ? {18'hzzzzz, GP_IN} : (g2) ? {GP_IN, 18'hzzzzz} : 36'hzzzzzzzzz;
    assign { p_fgi, p_fgo } = GP_OUT[9:8];
    assign GP_IN[9:8]       = { p_fgo_bsy, p_fgi_bsy };
    assign GP_IN[7:0]       = inpr;
    assign outr             = GP_OUT[7:0];

    wire    [15:0]  ir      = FPGA_EX3.ir;
    wire    [15:0]  ac      = FPGA_EX3.ac;
    wire    [15:0]  dr      = FPGA_EX3.dr;
    wire    [15:0]  ir      = FPGA_EX3.ir;
    wire    [11:0]  pc      = FPGA_EX3.pc;
    wire    [11:0]  ar      = FPGA_EX3.ar;
    wire    [7:0]   inpr    = FPGA_EX3.inpr;
    wire    [7:0]   outr    = FPGA_EX3.outr;
    wire    [2:0]   sc      = FPGA_EX3.sc;
    wire            sc_clr  = FPGA_EX3.sc_clr;
    wire            r       = FPGA_EX3.r;
    wire            ien     = FPGA_EX3.ien;
    wire            iot     = FPGA_EX3.iot;
    wire            s       = FPGA_EX3.s;
    wire            e       = FPGA_EX3.e;
    wire    [3:0]   imsk    = FPGA_EX3.imsk;
    wire    [1:0]   fgi     = FPGA_EX3.fgi;
    wire    [1:0]   fgo     = FPGA_EX3.fgo;

    input_model  P_IN  (clk, cpu_state, p_fgi, p_fgi_bsy, inpr, sc_clr);
    output_model P_OUT (clk, cpu_state, p_fgo, p_fgo_bsy, outr, sc_clr);

    uart_input_model  S_IN  (clk, cpu_state, FPGA_EX3.fgi[1] | ~FPGA_EX3.imsk[3], UART_RXD);
    uart_output_model S_OUT (clk, cpu_state, UART_TXD);

    always # 50 clk = ~clk;

    reg [31:0] prob[0:4096], cur_prob; /// prob size = 4096 + 1;

    initial $readmemh(`PROB_FILE, prob);

    reg [11:0] com_addr;

/// if these counters overflow, increase its bit widths
    reg  [19:0] insn_count, cycle_count, idx, max_data_addr;

    wire [15:0] i_count = insn_count[15:0];
	wire [15:0] c_count = cycle_count[15:0];

    parameter ir_str_length_0 = 3;
    parameter ir_str_length_1 = 4;
    parameter ir_str_length_2 = 2;

    wire [8 * ir_str_length_0 - 1 : 0] ir_name;
    wire [8 * ir_str_length_1 - 1 : 0] ir_addr;
    wire [8 * ir_str_length_2 - 1 : 0] ir_flag;

    insn_string_gen IR_STR (ir, r & (sc == 0), ir_name, ir_addr, ir_flag);

`ifdef ENABLE_CPU_MONITORING // this disables messages displayed every cycle
`else
    reg enable_intr_monitor;
    // if initialized to 1, CPU status is displayed at interrupt entry and exit
    initial enable_intr_monitor = 0;

`ifdef ENABLE_MONITOR_FILE
    reg [31:0] monitor_vector[0:`MONITOR_VECTOR_SIZE - 1], mon_idx, mon, mon_size;
    initial begin
        for(mon_idx = 0; mon_idx < `MONITOR_VECTOR_SIZE; mon_idx = mon_idx + 1)
            monitor_vector[mon_idx] = 32'hffffffff;
        $readmemh(`MONITOR_FILE, monitor_vector);
        for(mon_idx = 0; mon_idx < `MONITOR_VECTOR_SIZE; mon_idx = mon_idx + 1) begin
            mon = monitor_vector[mon_idx];
            if(mon[31:28] != 4'b1111) begin
                mon_size = mon_idx + 1;
                $display("mem-monitor[%d] : type = '%s', addr = %h, data = %h",
                         mon_idx[7:0], (mon[31:28] == 0) ? "prog" : "data", mon[27:16], mon[15:0]);
            end
        end
    end

function probe_addr; /// edit this function for probing your own program
    input [11:0] addr;
    reg [15:0] data;
    begin
        probe_addr = 0;
        for(mon_idx = 0; mon_idx < mon_size; mon_idx = mon_idx + 1) begin
            mon = monitor_vector[mon_idx];
            if(mon[27:16] == addr) probe_addr = 1;
            else if(mon[31:28] == 4'b1) begin /// data : check changes
                data = FPGA_EX3.CPU_EX3.MEM.mem[mon[27:16]];
                if(data != mon[15:0]) begin
                    probe_addr = 1;
                    $display("mem-monitor @ addr(%h), data : %h --> %h", mon[27:16], mon[15:0], data);
                    monitor_vector[mon_idx] = {mon[31:16], data};
                end
            end
        end
    end
endfunction
`else
function probe_addr;
    input [11:0] addr;
    probe_addr = 0;
endfunction
`endif
`endif

task LED_DISPLAY;
input	add_newline;
begin
    $write($stime, " (cpu_state:%h) [%s%h%s%h%s%h%s%h] %h (%b %b)",
        cpu_state,
        (seg7_3[4]) ? "*" : " ", seg7_3[3:0],
        (seg7_2[4]) ? "*" : " ", seg7_2[3:0],
        (seg7_1[4]) ? "*" : " ", seg7_1[3:0],
        (seg7_0[4]) ? "*" : " ", seg7_0[3:0],
        LED_data, LED_data[15:8], LED_data[7:0]);
    if(add_newline) $display();
end
endtask

task SHOW_CPU_STATUS;
input force_show;
@(negedge clk) if(cpu_state == `COM_RUN) begin
    if((sc == 0) | (insn_count == 0)) begin
`ifdef ENABLE_CPU_MONITORING // this enables messages displayed every cycle
        $display("----------------- new insn ---------------------");
`endif
        insn_count = insn_count + 1;
    end
    cycle_count = cycle_count + 1;
`ifdef ENABLE_CPU_MONITORING // this enables messages displayed every cycle
`else // 
    if(((sc == 0) & (enable_intr_monitor & (r | (ir == 16'hc000) & (pc != 1)) | probe_addr(pc))) | force_show)
`endif
    begin
        $display($stime, " [%d insns, %d clks] SC(%h),S(%b),R(%b),IO(%b:%b:%b|%h:%h|%h:%h),AR(%h),DR(%h),AC(%h),E(%b),PC(%h),IR(%h: %s%s%s)",
            i_count, c_count, sc, s, r, ien, imsk, iot, fgi, inpr, fgo, outr, 
            ar, dr, ac, e, pc, ir, ir_name, ir_addr, ir_flag);
/****
        LED_DISPLAY(0);
        $display(" [%d insns, %d clks] sc:%h s:%b r:%b ien:%b imsk:%b I:%b:%h O:%b:%h pc:%h ir:%h (%s%s%s)",
            insn_count, cycle_count, sc, s, r, ien, FPGA_EX3.imsk,
            fgi, inpr,
            fgo, outr, 
            pc, ir, ir_name, ir_addr, ir_flag);
*****/
    end
    if(pc > max_data_addr + 1) begin
        $display("pc(%h) > max_data_addr + 1(%h) !!! program is out of control....", pc, max_data_addr + 1);
        $finish;
    end
    if(cycle_count > `MAX_CYCLE) begin
        $display("cycle_count(%h) exceeds MAX_CYCLE!!! program is out of control....", cycle_count);
        $finish;
    end
    if(insn_count > `MAX_INSN_COUNT) begin
        $display("insn_count(%h) exceeds MAX_INSN_COUNT!!! program is out of control....", insn_count);
        $finish;
    end
end
endtask

task KEY_ACTION;    /// KEY[key_idx] : 1 -> 0 -> 1 pulse generation
input [1:0] key_idx;
begin
    SHOW_CPU_STATUS(0); KEY[key_idx] <= 0;
    $display($stime, " KEY[%d] : 1->0->1 pulse", key_idx);
    SHOW_CPU_STATUS(0); KEY[key_idx] <= 1;
    SHOW_CPU_STATUS(0);
    SHOW_CPU_STATUS(0);
end
endtask

/*********************** top-level control sequence *************************/

    initial begin
        clk = 0;
        KEY = 4'hf;
        SW  = {`G1,`M0,`P6, 2'b0}; /// 10'b01_00_0110_00 (LED: mem_dout)
//        SW[9:8] = `G0;
        insn_count = 0;
        cycle_count = 0;
        @(negedge clk);
        @(negedge clk);
        idx = 0;
        cur_prob = prob[idx];
        max_data_addr = 0;
        while(cur_prob[31:28] != `MEM_END) begin
            com_addr = cur_prob[27:16];
            if(cur_prob[31:28] == `MEM_DATA)
                max_data_addr = com_addr;
            idx = idx + 1;
            cur_prob = prob[idx];
        end
        KEY_ACTION(1);	///	reset state --> stop state
        for(com_addr = 0; com_addr <= max_data_addr; com_addr = com_addr + 1) begin
            LED_DISPLAY(1);
            KEY_ACTION(3);	///	increment probe address
        end

        SW[5:2]  = `P0; /// 0000 (LED: ac)

        KEY_ACTION(1);	///	stop state --> run state

        while (s | (|(~FPGA_EX3.fgo))) SHOW_CPU_STATUS(0);
		SHOW_CPU_STATUS(1);
        @(negedge clk);
        $display("-------------- program halt!! ------------------");
        KEY_ACTION(1);	///	run state --> stop state
        KEY_ACTION(2);	///	reset probe address register

        SW[5:2]  = `P6; /// 0110 (LED: mem_dout)
        @(negedge clk);

        idx = 0;
        cur_prob = prob[idx];
        while(cur_prob[31:28] != `MEM_END) begin
            if(cur_prob[31:28] == `MEM_DATA) begin
                com_addr = cur_prob[27:16];
                @(negedge clk);
                LED_DISPLAY(0);
                $display( ", data probe: com_addr(%h), from_probe(%h)", com_addr, cur_prob[15:0]);
                KEY_ACTION(3);
            end
            idx = idx + 1;
            cur_prob = prob[idx];
        end
        $display("------------------ bye bye ---------------------");
        $finish;
    end

endmodule
