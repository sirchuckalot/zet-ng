/*
 *  Testbench for Zet-ng decoder
 *  Copyright (C) 2013  Charley Picker <charleypicker@yahoo.com>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

`define ENABLE_VCD

module test_decode();

// Testbench regs and wires
reg clk;
initial clk = 1'b0;
always #1.5 clk = ~clk;
reg rst;

// Device Under Test regs and wires
reg [7:0] instruction;
reg instruction_valid;
wire instruction_next;
wire decoded_valid_o;
reg next_decoded_i;

// Storage for data.rtlrom
reg  [15:0] ram[0:2**19-1];

// Stimulus regs and wires
reg [19:0] count;
wire [15:0] do16;
assign do16 = ram[count[19:1]];

// Testbench task
task waitclock;
begin
	@(posedge clk);
	#1.5;
end
endtask

// Device Under Test module instantiation

zet_decode dut (
    .clk(clk),
    .rst_i(rst),
    .flush_i(1'b0),
    .instruction_i(instruction),
    .instruction_valid_i(instruction_valid),
    .next_instruction_o(instruction_next),

    // current cs and ip of instruction
    .instruction_cs_o(),
    .instruction_ip_o(),

    // {prefix_decoded, repe_repz, repne_repnz, lock}
    .inst_pr_o(),
    // {prefix_decoded, x, x, address size override}
    .adrs_pr_o(),
    // {prefix_decoded, x, x, operand size override}
    .oper_pr_o(),
    // {prefix_decoded, segment override register}
    .sovr_pr_o(),

    .opcode_o(),

    .need_modrm_o(),
    .modrm_o(),

    .need_off_o(),
    .off_size_o(),
    .offset_o(),

    .need_imm_o(),
    .imm_size_o(),
    .immediate_o(),

    // to sequencer
    .seq_addr_o(),
    .src_o(),
    .dst_o(),
    .base_o(),
    .index_o(),
    .seg_o(),

    .decoded_valid_o(decoded_valid_o),
    .next_decoded_i(next_decoded_i)

);

// Behaviour

always @(*) begin
  case(count[0])
    1'd0: instruction <= do16[7:0];
    1'd1: instruction <= do16[15:8];
  endcase
end

always @(posedge clk)
  if (rst)
    begin
      instruction_valid <= 1'b0;
      count <= 20'd0;
    end
  else
  begin
    instruction_valid <= 1'b1;
    if (instruction_next)
      begin
        $display("Address: %d   Data byte: %h", count, instruction);
        count <= count + 20'd1;
      end
    if (decoded_valid_o & !next_decoded_i)
      begin
        $display("Instruction Finished Decoding");
        $display(" ");
        $display("Sending next byte sequence:");
        next_decoded_i <= 1'b1;
      end
    else
      next_decoded_i <= 1'b0;
  end
  

always begin
`ifdef ENABLE_VCD
	$dumpfile("decode.vcd");
	$dumpvars(0, dut);
`endif

  clk <= 1'b1;
  rst <= 1'b0;
  #5 rst <= 1'b1;
  #2 rst <= 1'b0;
      
		
	waitclock;
	
	
	$display(" ");
	
	$display("Sending first byte sequence: ");
		
	#1000 rst <= 1'b1;
		
	//$stop;
end

initial
    begin
      //$readmemh("data.rtlrom", ram, 19'h78000);
      $readmemh("data.rtlrom", ram);
    end

endmodule
