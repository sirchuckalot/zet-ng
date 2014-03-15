/*
 *  Zero delay memory module with two slave ports for Zet
 *  Copyright (C) 2008-2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *  adjusted to include second port by Charley Picker <charleypicker@yahoo.com>
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

module memory2prt (
    // Wishbone slave 1 interface
    input         wb1_clk_i,
    input         wb1_rst_i,
    input  [15:0] wb1_dat_i,
    output [15:0] wb1_dat_o,
    input  [19:1] wb1_adr_i,
    input         wb1_we_i,
    input  [ 1:0] wb1_sel_i,
    input         wb1_stb_i,
    input         wb1_cyc_i,
    output        wb1_ack_o,
    
    // Wishbone slave 2 interface
    input         wb2_clk_i,
    input         wb2_rst_i,
    input  [15:0] wb2_dat_i,
    output [15:0] wb2_dat_o,
    input  [19:1] wb2_adr_i,
    input         wb2_we_i,
    input  [ 1:0] wb2_sel_i,
    input         wb2_stb_i,
    input         wb2_cyc_i,
    output        wb2_ack_o
  );

  // Registers and nets
  reg  [15:0] ram1[0:2**19-1];
  reg  [15:0] ram2[0:2**19-1];

  wire       we1;
  wire [7:0] bhw1, blw1;
  
  wire       we2;
  wire [7:0] bhw2, blw2;

  // Assignments
  assign wb1_dat_o = ram1[wb1_adr_i];
  assign wb1_ack_o = wb1_stb_i;
  assign we1       = wb1_we_i & wb1_stb_i & wb1_cyc_i;
  
  assign wb2_dat_o = ram2[wb2_adr_i];
  assign wb2_ack_o = wb2_stb_i;
  assign we2       = wb2_we_i & wb2_stb_i & wb2_cyc_i;

  assign bhw1 = wb1_sel_i[1] ? wb1_dat_i[15:8]
                           : ram1[wb1_adr_i][15:8];
  assign blw1 = wb1_sel_i[0] ? wb1_dat_i[7:0]
                           : ram1[wb1_adr_i][7:0];

  assign bhw2 = wb2_sel_i[1] ? wb2_dat_i[15:8]
                           : ram2[wb2_adr_i][15:8];
  assign blw2 = wb2_sel_i[0] ? wb2_dat_i[7:0]
                           : ram2[wb2_adr_i][7:0];

  // Behaviour
  always @(posedge wb1_clk_i)
    begin
      if (we1) ram1[wb1_adr_i] <= { bhw1, blw1 };
      if (we1) ram2[wb1_adr_i] <= { bhw1, blw1 };
    end

  always @(posedge wb2_clk_i)
    begin
      if (we2) ram1[wb2_adr_i] <= { bhw2, blw2 };
      if (we2) ram2[wb2_adr_i] <= { bhw2, blw2 };
    end

endmodule
