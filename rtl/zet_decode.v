
/*
 *  Instruction Decode Stage
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

`include "defines.v"

module zet_decode (
  input clk,
  input rst_i,
  input flush_i,
  input [7:0] instruction_i,
  input instruction_valid_i,
  output reg next_instruction_o,

  // current cs and ip of instruction
  output reg [15:0] instruction_cs_o,
  output reg [15:0] instruction_ip_o,

  // {prefix_decoded, repe_repz, repne_repnz, lock}
  output reg [3:0] inst_pr_o,
  // {prefix_decoded, x, x, address size override}
  output reg [3:0] adrs_pr_o,
  // {prefix_decoded, x, x, operand size override}
  output reg [3:0] oper_pr_o,
  // {prefix_decoded, segment override register}
  output reg [3:0] sovr_pr_o,
  
  output reg [7:0] opcode_o,
  
  output need_modrm_o,
  output reg [7:0] modrm_o,
  
  output need_off_o,
  output off_size_o,
  output reg [15:0] offset_o,
  
  output need_imm_o,
  output imm_size_o,
  output reg [15:0] immediate_o,

  // to sequencer
  output [`MICRO_ADDR_WIDTH-1:0] seq_addr_o,
  output [3:0] src_o,
  output [3:0] dst_o,
  output [3:0] base_o,
  output [3:0] index_o,
  output [1:0] seg_o,
  
  output reg decoded_valid_o,
  input next_decoded_i

);

// Registers, nets and parameters

localparam [3:0]
  idle_st       = 4'd0,
  prefix_st     = 4'd1,
  opcode_st     = 4'd2,
  modrm_st      = 4'd3,
  offset_st     = 4'd4,
  offset2_st    = 4'd5,
  immediate_st  = 4'd6,
  immediate2_st = 4'd7,
  execute_st    = 4'd8;

reg [3:0] state;
reg [3:0] next_state;

reg decoder_flush;
wire dflush;

// Prefix decoder registers
reg [3:0] prefix_grp;
reg [2:0] prefix;
wire prefix_decoded;

// 8086 opcode decoder lookup table wires
wire rep;
wire [2:0] sop;

// FSM Registers
reg latch_prefix;
reg latch_opcode;
reg latch_modrm;

reg latch_offset_1;
reg latch_offset_2;

reg latch_immediate_1;
reg latch_immediate_2;


// Module instantiations
zet_opcode_deco opcode_deco (opcode_o, modrm_o, rep, sop, seq_addr_o, need_modrm_o,
                             need_off_o, need_imm_o, off_size_o, imm_size_o, src_o, dst_o,
                             base_o, index_o, seg_o);

// Continuous assignments

// flush decoded instruction or external flush event
assign dflush = decoder_flush | flush_i;

// Was any of the prefix groups decoded?
assign prefix_decoded = |prefix_grp;

// translate signals for 8086 decoder lookup table
assign rep = inst_pr_o[2] | inst_pr_o[1];
assign sop = { sovr_pr_o[3], sovr_pr_o[1:0] };

// Behaviour

// Prefix decoder
always @(*)
  case (instruction_i)
    // instruction prefix
    8'hf0: begin prefix_grp <= 4'b1000; prefix <= 3'b001; end // lock
    8'hf2: begin prefix_grp <= 4'b1000; prefix <= 3'b010; end // repne_repnz
    8'hf3: begin prefix_grp <= 4'b1000; prefix <= 3'b100; end // repe_repz
    // address size prefix
    8'h67: begin prefix_grp <= 4'b0100; prefix <= 3'b001; end
    // operand size prefix
    8'h66: begin prefix_grp <= 4'b0010; prefix <= 3'b001; end
    // segment override prefix    
    8'h26: begin prefix_grp <= 4'b0001; prefix <= 3'b000; end // es
    8'h2e: begin prefix_grp <= 4'b0001; prefix <= 3'b001; end // cs
    8'h36: begin prefix_grp <= 4'b0001; prefix <= 3'b010; end // ss
    8'h3e: begin prefix_grp <= 4'b0001; prefix <= 3'b011; end // ds
    8'h64: begin prefix_grp <= 4'b0001; prefix <= 3'b100; end // fs
    8'h65: begin prefix_grp <= 4'b0001; prefix <= 3'b101; end // gs
    // no prefix was decoded
    default: begin prefix_grp <= 4'b0000; prefix <= 3'b000; end
  endcase

// Latch decoded prefix
always @(posedge clk)
  if (rst_i) begin
    inst_pr_o <= 4'b0000;
    adrs_pr_o <= 4'b0000;
    oper_pr_o <= 4'b0000;
    sovr_pr_o <= 4'b0000;
  end
  else
  if (dflush) begin
    inst_pr_o <= 4'b0000;
    adrs_pr_o <= 4'b0000;
    oper_pr_o <= 4'b0000;
    sovr_pr_o <= 4'b0000;
  end
  else
  begin
    if (latch_prefix) begin
      inst_pr_o <= prefix_grp[3] ? {prefix_decoded, prefix} : inst_pr_o;
      adrs_pr_o <= prefix_grp[2] ? {prefix_decoded, prefix} : adrs_pr_o;
      oper_pr_o <= prefix_grp[1] ? {prefix_decoded, prefix} : oper_pr_o;
      sovr_pr_o <= prefix_grp[0] ? {prefix_decoded, prefix} : sovr_pr_o;
    end
  end

// Latch opcode
always @(posedge clk)
  if (rst_i)
    //opcode_o <= 'OP_NOP;
    opcode_o <= 8'h90;
  else
  if (dflush)
    //opcode_o <= 'OP_NOP;
    opcode_o <= 8'h90;
  else
  if (latch_opcode)
    opcode_o <= instruction_i;

// Latch modrm
always @(posedge clk)
  if (rst_i)
    modrm_o <= 8'b0;
  else
  if (dflush)
    modrm_o <= 8'b0;
  else
  if (latch_modrm)
    modrm_o <= instruction_i;

// Latch offset
always @(posedge clk)
  if (rst_i)
    offset_o <= 16'b0;
  else
  if (dflush)
    offset_o <= 16'b0;
  else
  if (latch_offset_1)
    offset_o[7:0] <= instruction_i;
  else
  if (latch_offset_2)
    offset_o[15:8] <= instruction_i;

// Latch immediate
always @(posedge clk)
  if (rst_i)
    immediate_o <= 16'b0;
  else
  if (dflush)
    immediate_o <= 16'b0;
  else
  if (latch_immediate_1)
    offset_o[7:0] <= instruction_i;
  else
  if (latch_immediate_2)
    offset_o[15:8] <= instruction_i;

// next state logic
always @(posedge clk)
  if (rst_i) state <= idle_st;
  else
  if (dflush) state <= idle_st;
  else
  state <= next_state;

// Decoder FSM
always @(*) begin
    next_state = state;

    next_instruction_o = 1'b0;
    //load_cs_ip = 1'b0;
    
    decoder_flush = 1'b0;

    latch_prefix = 1'b0;
    latch_opcode = 1'b0;
    latch_modrm = 1'b0;

    latch_offset_1 = 1'b0;
    latch_offset_2 = 1'b0;

    latch_immediate_1 = 1'b0;
    latch_immediate_2 = 1'b0;

    decoded_valid_o = 1'b0;

    case (state)
      idle_st: begin
          //load_instruction = 1'b1;
          //load_instruction_pointer = 1'b1;
          if (instruction_valid_i) begin
              next_state = prefix_st;
          end
      end
      prefix_st: begin
        if (instruction_valid_i) begin
          if (prefix_decoded) begin
            latch_prefix = 1'b1;
            next_state = prefix_st;
          end
          else begin
            latch_opcode = 1'b1;
            next_state = opcode_st;
          end
          next_instruction_o = 1'b1;
        end
      end
      opcode_st: begin
        if (need_modrm_o) begin
          if (instruction_valid_i) begin
            latch_modrm = 1'b1;
            next_instruction_o = 1'b1;
            next_state = modrm_st;
          end
        end
        else 
        if (need_off_o) next_state = offset_st;
        else
        if (need_imm_o) next_state = immediate_st;
        else
        next_state = execute_st;
      end
      modrm_st: begin
        if (need_off_o) next_state = offset_st;
        else
        if (need_imm_o) next_state = immediate_st;
        else
        next_state = execute_st;
      end
      offset_st: begin
        if (off_size_o) begin
          if (instruction_valid_i) begin
            latch_offset_1 = 1'b1;
            next_instruction_o = 1'b1;
            next_state = offset2_st;
          end
        end
        else
        if (instruction_valid_i) begin
          latch_offset_1 = 1'b1;
          next_instruction_o = 1'b1;
          if (need_imm_o) next_state = immediate_st;
          else next_state = execute_st;
        end
      end
      offset2_st: begin
        if (instruction_valid_i) begin
          latch_offset_2 = 1'b1;
          next_instruction_o = 1'b1;
          if (need_imm_o) next_state = immediate_st;
          else next_state = execute_st;
        end
      end
      immediate_st: begin
        if (imm_size_o) begin
          if (instruction_valid_i) begin
            latch_immediate_1 = 1'b1;
            next_instruction_o = 1'b1;
            next_state = immediate2_st;
          end
        end
        else
        if (instruction_valid_i) begin
          latch_immediate_1 = 1'b1;
          next_instruction_o = 1'b1;
          next_state = execute_st;
        end
      end
      immediate2_st: begin
        if (instruction_valid_i) begin
          latch_immediate_2 = 1'b1;
          next_instruction_o = 1'b1;
          next_state = execute_st;
        end
      end
      execute_st: begin
        decoded_valid_o = 1'b1;
        if (next_decoded_i) begin
          // flush the decoder to a known state
          decoder_flush = 1'b1;
          next_state = idle_st;
        end
      end
    endcase
end

endmodule
