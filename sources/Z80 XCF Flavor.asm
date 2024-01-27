;------------------------------------------------------------------------------.
;                                                                              |
;  Z80 XCF Flavor v1.1                                                         |
;  Copyright (C) 2022-2024 Manuel Sainz de Baranda y Goñi.                     |
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

CLS          = $0DAF
OPEN_CHANNEL = $1601
PRINT        = $203C
UDG	     = $5C7B

	device zxspectrum48, $7FFF
	org $8000

	macro Q0_F0_A0
		xor a	     ; A = 0; YF, XF, YQ, XQ = 0
	endm

	macro Q0_F1_A0
		xor a	     ;
		dec a	     ; YF, XF = 1
		ld  a, 0     ; A = 0; Q = 0
	endm

	macro Q1_F1_A0
		xor a	     ; A = 0
		ld  e, a     ;
		dec e	     ; YF, XF, YQ, XQ = 1
	endm

	macro Q0_F0_A1
		xor a	     ; YF, XF = 0
		ld  a, $FF   ; A = FFh; Q = 0
	endm

	macro Q0_F1_A1
		xor a	     ;
		dec a	     ; A = FFh; YF, XF = 1
		nop	     ; Q = 0
	endm

	macro Q1_F1_A1
		xor a	     ;
		dec a	     ; A = FFh; YF, XF, YQ, XQ = 1
	endm


start:	di		     ; Disable interrupts.
	call CLS	     ; Clear the screen.
	ld   a, 2	     ; Open channel #2 for text output.
	call OPEN_CHANNEL    ;
	ld   bc, (UDG)	     ; Save the current UDG pointer.
	ld   de, udg	     ; Set custom UDG for "ñ".
	ld   (UDG), de	     ;
	ld   hl, screen_text ; Print the static text.
	call print	     ;
	ld   (UDG), bc       ; Restore the original UDG pointer.

	ld   bc, results     ; Set BC to the address of the results array.
	ld   hl, at_yx + 1   ; Configure the <AT><y><x> sequence:
	ld   (hl), 10	     ; <y> = 10
	inc  hl		     ;
	ld   (hl), 26	     ; <x> = 26

	; Test all factor combinations with `ccf` and
	; print the resulting values of YF and XF.
	Q0_F0_A0 : ccf : call keep_and_print_yxf
	Q0_F1_A0 : ccf : call keep_and_print_yxf
	Q1_F1_A0 : ccf : call keep_and_print_yxf
	Q0_F0_A1 : ccf : call keep_and_print_yxf
	Q0_F1_A1 : ccf : call keep_and_print_yxf
	Q1_F1_A1 : ccf : call keep_and_print_yxf

	ld   hl, at_yx + 1 ; Configure the <AT><y><x> sequence:
	ld   (hl), 10	   ; <y> = 10
	inc  hl		   ;
	ld   (hl), 30	   ; <x> = 30

	; Test all factor combinations with `scf` and
	; print the resulting values of YF and XF.
	Q0_F0_A0 : scf : call keep_and_print_yxf
	Q0_F1_A0 : scf : call keep_and_print_yxf
	Q1_F1_A0 : scf : call keep_and_print_yxf
	Q0_F0_A1 : scf : call keep_and_print_yxf
	Q0_F1_A1 : scf : call keep_and_print_yxf
	Q1_F1_A1 : scf : call keep_and_print_yxf

	ld   hl, at_yx + 2	      ; Configure the <AT><y><x> sequence:
	ld   (hl), 8		      ; <x> = 8
	dec  hl			      ;
	ld   (hl), 19		      ; <y> = 19
	dec  hl			      ; Print the sequence to move the cursor
	call print		      ;   after "Result: "

	ld   de, results	      ; Compare the values obtained with `ccf`,
	ld   hl, results + 6	      ;   against those obtained with `scf`.
	call compare_results	      ;   They should be the same; otherwise,
	cp   0			      ;   the behavior is unknown (or unstable)
	jr   nz, .unknown_flavor      ;   and we report it.

	ld   de, results	      ; Compare the values obtained with `ccf`
	ld   hl, results_on_zilog     ;   against the reference values for Zilog
	call compare_results	      ;   CPU models.
	ld   hl, zilog_flavor_text    ;
	cp   0			      ; If the values match, report "Zilog
	jr   z, .print_result	      ;   flavor" and exit.

	ld   de, results	      ; Compare the values obtained with `ccf`
	ld   hl, results_on_nec_nmos  ;   against the reference values for NEC
	call compare_results	      ;   NMOS CPU models.
	ld   hl, nec_nmos_flavor_text ;
	cp   0			      ; If the values match, report "NEC NMOS
	jr   z, .print_result	      ;   flavor" and exit.

	ld   de, results	      ; Compare the values obtained with `ccf`
	ld   hl, results_on_st_cmos   ;   against the reference values for ST
	call compare_results	      ;   CMOS CPU models.
	ld   hl, st_cmos_flavor_text  ;
	cp   0			      ; If the values match, report "ST CMOS
	jr   z, .print_result	      ;   flavor" and exit.

.unknown_flavor:
	ld   hl, unknown_flavor_text  ; Report "Unknown flavor".
.print_result:
	call print
	ei			      ; Re-enable interrupts.
	ret			      ; Exit to BASIC.


;--------------------------------------------------------------------.
; Keeps YF and XF into the results array, prints their value at the  |
; coordinates specified by the <AT><y><x> sequence stored in `at_yx` |
; and increments <y>.						     |
;								     |
; On Entry:							     |
;   * BC - Address of the element in the results array.		     |
; On Exit:							     |
;   * BC - Address of the next element in the results array.	     |
;===================================================================='

keep_and_print_yxf:
	push af		   ; Copy the flags in E and A.
	pop  de		   ;
	ld   a, e	   ;
	and  00101000b	   ; Clear all bits in the copy of A except YF and XF.
	ld   (bc), a	   ; Keep YF and XF into the results array.
	inc  bc		   ; Point BC to the next element of the array.
	ld   hl, at_yx	   ; Move the cursor to the column/row specified by HL
	call print	   ;   by printing the <AT><y><x> sequence.
	ld   hl, at_yx + 1 ; Increment <y> in the sequence so that next time we
	inc  (hl)	   ;   print at the next row of the screen.
	srl  e		   ; Shift the flags to the right until XF is at bit 0.
	srl  e		   ;
	srl  e		   ;
	ld   d, e	   ; Now copy the flags also in D, and shift this
	srl  d		   ;   register right until YF is at bit 0 (we need to
	srl  d		   ;   use 2 registers because YF is printed first).
	ld   a, d	   ; Print YF.
	and  1		   ;
	add  $30	   ;
	rst  $10	   ;
	ld   a, e	   ; Print XF.
	and  1		   ;
	add  $30	   ;
	rst  $10	   ;
	ret


;---------------------------------.
; Prints a 1Fh-terminated string. |
;				  |
; On Entry:			  |
;   * HL - String address.	  |
;================================='

print:	ld   a, (hl)
	cp   $1F
	ret  z
	rst  $10
	inc  hl
	jr   print


;-----------------------------------------------------------------.
; Compares 2 arrays of results.					  |
;								  |
; On Entry:							  |
;   * HL - Array 1 address.					  |
;   * DE - Array 2 address.					  |
; On Exit:							  |
;   * A - 0 if the arrays are equal; otherwise, a non-zero value. |
;================================================================='

compare_results:
	ld   c, 6
.compare:
	ld   a, (de)
	sub  (hl)
	ret  nz
	inc  de
	inc  hl
	dec  c
	jr   nz, .compare
	ret


results:
	block 12
results_on_zilog:
	db 00000000b, 00101000b, 00000000b, 00101000b, 00101000b, 00101000b
results_on_nec_nmos:
	db 00000000b, 00000000b, 00000000b, 00101000b, 00101000b, 00101000b
results_on_st_cmos:
	db 00000000b, 00100000b, 00000000b, 00101000b, 00101000b, 00101000b
at_yx:
	db 22, 10, 27, $1F
screen_text:
	db "Z80 XCF "
	db 19, 1, 17, 2, 16, 7, "F", 17, 3, "L", 17, 1, "A", 17, 5, 16, 8, "V"
	db 17, 4, "O", 17, 6, "R", 17, 8, 16, 8, 19, 8, " v1.1 (",__DATE__,")\r"
	db 127, " Manuel Sainz de Baranda y Go", $90, "i\r"
	db 16, 1, "https://zxe.io", 16, 8, "\r"
	db "\r"
	db "\r"
	db "\r"
	db "\r"
	db 19, 1, 17, 0, 16, 7,"  Case    Any  NEC   ST    HOST \r"
	db " Tested  Zilog NMOS CMOS   CPU  \r"
	db "(Q<>F)|A   YX   YX   YX   YX  YX", 17, 8, 16, 8, 19, 8, "\r"
	db "(0<>0)|0   00   00   00\r"
	db "(0<>1)|0   11   00   10\r"
	db "(1<>1)|0   00   00   00\r"
	db "(0<>0)|1   11   11   11\r"
	db "(0<>1)|1   11   11   11\r"
	db "(1<>1)|1   11   11   11\r"
	db 23, 25, 0, 19, 1, 17, 0, 16, 7, "ccf scf", 17, 8, 16, 8, 19, 8, "\r"
	db "\r"
	db "\r"
	db "Result:",$1F
zilog_flavor_text:
	db 19, 1, 17, 4, "Zilog", 19, 8, 17, 8, " flavor", $1F
nec_nmos_flavor_text:
	db 19, 1, 17, 4, "NEC NMOS", 19, 8, 17, 8, " flavor", $1F
st_cmos_flavor_text:
	db 19, 1, 17, 4, "ST CMOS", 19, 8, 17, 8, " flavor", $1F
unknown_flavor_text:
	db 19, 1, 18, 1, 17, 2, "Unknown", 19, 8, 18, 8, 17, 8, " flavor", $1F
udg:
	db 00000000b ; ñ
	db 00111000b
	db 00000000b
	db 01011000b
	db 01100100b
	db 01000100b
	db 01000100b
	db 00000000b

	macro MAKE_TAPE tape_file, prog_name, start_add, code_len, call_add

CLEAR	  = $FD
CODE	  = $AF
LOAD	  = $EF
RANDOMIZE = $F9
USR	  = $C0

	org $5C00
basic:	db  0, 1
	dw  line_1_size
line_1:	db  CLEAR, '8', $0E, 0, 0
	dw  start_add - 1
	db  0, ':'
	db  LOAD, '"'
name:	ds  10, 32
	org name
	db  prog_name
	org name + 10
	db  '"', CODE, $0D
line_1_size = $ - line_1
	db  0, 2
	dw  line_2_size
line_2:	db  RANDOMIZE, USR, '8', $0E, 0, 0
	dw  call_add
	db  0, $0D
line_2_size = $ - line_2
basic_size  = $ - basic

	EMPTYTAP tape_file
	SAVETAP  tape_file, BASIC, prog_name, basic, basic_size, 1
	SAVETAP  tape_file, CODE, prog_name, start_add, code_len, start_add
	ENDM

size = $ - start

	MAKE_TAPE "Z80 XCF Flavor.tap", "Z80 XCF", start, size, start

; EOF
