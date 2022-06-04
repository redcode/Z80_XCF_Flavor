;------------------------------------------------------------------------------.
;  Z80 XCF Flavor                                                              |
;  Copyright (C) 2022 Manuel Sainz de Baranda y Goñi.                          |
;                                                                              |
;  This program is free software: you can redistribute it and/or modify it     |
;  under the terms of the GNU General Public License as published by the Free  |
;  Software Foundation, either version 3 of the License, or (at your option)   |
;  any later version.                                                          |
;                                                                              |
;  This program is distributed in the hope that it will be useful, but         |
;  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  |
;  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License     |
;  for more details.                                                           |
;                                                                              |
;  You should have received a copy of the GNU General Public License along     |
;  with this program. If not, see <http://www.gnu.org/licenses/>.              |
;                                                                              |
;=============================================================================='

	device zxspectrum48, $7FFE
	org $7FFF

	macro Q0_F0_A0
		xor a ; A = 0; YF, XF, YQ, XQ = 0
	endm

	macro Q0_F1_A0
		xor a
		dec a   ; YF, XF = 1
		ld  a,0 ; A = 0; Q = 0
	endm

	macro Q1_F1_A0
		xor a   ; A = 0
		ld  e,a
		dec e   ; YF, XF, YQ, XQ = 1
	endm

	macro Q0_F0_A1
		xor a      ; YF, XF = 0
		ld  a, $FF ; A = FFh; YQ, XQ = 0
	endm

	macro Q0_F1_A1
		xor a
		dec a ; A = FFh; YF, XF = 1
		nop   ; Q = 0
	endm

	macro Q1_F1_A1
		xor a
		dec a ; A = FFh; YF, XF, YQ, XQ = 1
	endm


start:	call $0DAF ; ROM CLS
	ld   a,2
	call $1601 ; ROM channel# open

	ld   hl,screen_text
	call print
	ld   bc,results

	Q0_F0_A0 : ccf : call keep_and_print_yxf
	Q0_F1_A0 : ccf : call keep_and_print_yxf
	Q1_F1_A0 : ccf : call keep_and_print_yxf
	Q0_F0_A1 : ccf : call keep_and_print_yxf
	Q0_F1_A1 : ccf : call keep_and_print_yxf
	Q1_F1_A1 : ccf : call keep_and_print_yxf

	ld   hl,at_yx+1
	ld   (hl),10
	inc  hl
	ld   (hl),30

	Q0_F0_A0 : scf : call keep_and_print_yxf
	Q0_F1_A0 : scf : call keep_and_print_yxf
	Q1_F1_A0 : scf : call keep_and_print_yxf
	Q0_F0_A1 : scf : call keep_and_print_yxf
	Q0_F1_A1 : scf : call keep_and_print_yxf
	Q1_F1_A1 : scf : call keep_and_print_yxf

	ld   hl,at_yx+2
	ld   (hl),8
	dec  hl
	ld   (hl),19
	dec  hl
	call print

	ld   de,results
	ld   hl,results+6
	call compare_results
	ld   hl,unknown_flavor_text
	cp   0
	jr   nz,.print_result

	ld   de,results
	ld   hl,results_on_zilog
	call compare_results
	ld   hl,zilog_flavor_text
	cp   0
	jr   z,.print_result

	ld   de,results
	ld   hl,results_on_nec_nmos
	call compare_results
	ld   hl,nec_nmos_flavor_text
	cp   0
	jr   z,.print_result

	ld   de,results
	ld   hl,results_on_st_cmos
	call compare_results
	ld   hl,st_cmos_flavor_text
	cp   0
	jr   z,.print_result

	ld   hl,st_cmos_flavor_text
.print_result:
	call print
	ret


keep_and_print_yxf:
	push af
	pop  de
	ld   a,e
	and  00101000b
	ld   (bc),a
	inc  bc
	ld   hl,at_yx
	call print
	ld   hl,at_yx+1
	inc  (hl)
	srl  e
	srl  e
	srl  e
	ld   d,e
	srl  d
	srl  d
	ld   a,d
	and  1
	add  $30
	rst  $10
	ld   a,e
	and  1
	add  $30
	rst  $10
	ret


; Prints a 1Fh terminated string.
;
; Input:
;   hl -> String address.

print:	ld   a,(hl)
	cp   $1F
	ret  z
	rst  $10
	inc  hl
	jr   print


; Compares 2 arrays of results.
;
; Input:
;   hl -> Address of array 1.
;   de -> Address of array 2.
; Output:
;   a -> 0 if both arrays are equal, or non-zero otherwise.

compare_results:
	ld   c,6
.compare:
	ld   a,(de)
	sub  (hl)
	ret  nz
	inc  de
	inc  hl
	dec  c
	jr   nz,.compare
	xor  a
	ret


results:
	block 12
results_on_zilog:
	db 000000b, 101000b, 000000b, 101000b, 101000b, 101000b
results_on_nec_nmos:
	db 000000b, 000000b, 000000b, 101000b, 101000b, 101000b
results_on_st_cmos:
	db 000000b, 100000b, 000000b, 101000b, 101000b, 101000b
at_yx:
	db 22,10,27,$1F
screen_text:
	db "Z80 XCF ",19,1,17,2,16,7,"F",17,3,"L",17,1,"A",17,5,16,8,"V",17,4,"O",17,6,"R",17,8,16,8,19,8," v0.1 (",__DATE__,")\r"
	db 127," 2022 Manuel Sainz de Baranda\r"
	db 16,1,"https://zxe.io",16,8,"\r"
	db "\r"
	db "\r"
	db "\r"
	db "\r"
	db 19,1,17,0,16,7,"                NEC   ST    HOST\r"
	db "         Zilog NMOS CMOS     CPU\r"
	db "(Q<>F)|A    YX   YX   YX  cYXsYX",17,8,16,8,19,8,"\r"
	db "(0<>0)|0    00   00   00\r"
	db "(0<>1)|0    11   00   10\r"
	db "(1<>1)|0    00   00   00\r"
	db "(0<>0)|1    11   11   11\r"
	db "(0<>1)|1    11   11   11\r"
	db "(1<>1)|1    11   11   11\r"
	db "\r"
	db "\r"
	db "\r"
	db "Result:",$1F
zilog_flavor_text:
	db 19,1,17,4,"Zilog",   19,8,17,8," flavor",$1F
nec_nmos_flavor_text:
	db 19,1,17,4,"NEC NMOS",19,8,17,8," flavor",$1F
st_cmos_flavor_text:
	db 19,1,17,4,"ST CMOS", 19,8,17,8," flavor",$1F
unknown_flavor_text:
	db 19,1,18,1,17,2,"Unknown",19,8,18,8,17,8," flavor",$1F


	MACRO MakeTape tape_file, prog_name, start_add, code_len, call_add

CODE	  = $AF
USR	  = $C0
LOAD	  = $EF
CLEAR	  = $FD
RANDOMIZE = $F9

	org	$5C00
baszac:	db	0,1    ; Line number
	dw	linlen ; Line length
linzac:
	db	CLEAR,'8',$0E,0,0
	dw	start_add-1
	db	0,':'
	db	LOAD,'"'
codnam:	ds	10,32
	org	codnam
	db	prog_name
	org	codnam+10
	db	'"',CODE,':'
	db	RANDOMIZE,USR,'8',$0E,0,0
	dw	call_add
	db	0,$0D

linlen = $-linzac
baslen = $-baszac

	EMPTYTAP tape_file
	SAVETAP  tape_file,BASIC,prog_name,baszac,baslen,1
	SAVETAP  tape_file,CODE,prog_name,start_add,code_len,start_add
	ENDM

size = $ - start

	MakeTape "Z80 XCF Flavor.tap", "Z80 XCF", start, size, start


; Z80 XCF Flavor.asm EOF
