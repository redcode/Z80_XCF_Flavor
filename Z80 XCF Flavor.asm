; Z80 XCF Flavor v1.4
; Copyright (C) 2022-2024 Manuel Sainz de Baranda y Goñi.
;
; This program is free software: you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation, either version 3 of the License, or (at your option) any later
; version.
;
; This program is distributed in the hope that it will be useful, but WITHOUT
; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along with
; this program. If not, see <http://www.gnu.org/licenses/>.

	device zxspectrum48, $7FFF

CLS	     = $0DAF
OPEN_CHANNEL = $1601
PRINT	     = $203C
UDG	     = $5C7B

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

	org $8000


start:	di		     ; Disable interrupts.
	call CLS	     ; Clear the screen.
	ld   a, 2	     ; Open channel #2 for text output.
	call OPEN_CHANNEL    ;
	ld   bc, (UDG)	     ; Save the current UDG pointer.
	ld   de, nn	     ; Set custom UDG for "ñ".
	ld   (UDG), de	     ;
	ld   hl, header_text ; Print the header.
	call print	     ;
	ld   (UDG), bc	     ; Restore the original UDG pointer.
	ld   bc, results     ; Set BC to the address of the results array.

	; Test all factor combinations with `ccf` and
	; keep the resulting values of YF and XF.
	Q0_F0_A0 : ccf : call keep_yxf
	Q0_F1_A0 : ccf : call keep_yxf
	Q1_F1_A0 : ccf : call keep_yxf
	Q0_F0_A1 : ccf : call keep_yxf
	Q0_F1_A1 : ccf : call keep_yxf
	Q1_F1_A1 : ccf : call keep_yxf

	; Test all factor combinations with `scf` and
	; keep the resulting values of YF and XF.
	Q0_F0_A0 : scf : call keep_yxf
	Q0_F1_A0 : scf : call keep_yxf
	Q1_F1_A0 : scf : call keep_yxf
	Q0_F0_A1 : scf : call keep_yxf
	Q0_F1_A1 : scf : call keep_yxf
	Q1_F1_A1 : scf : call keep_yxf

	ld   c, 6		     ; C = number of rows to print.
	ld   hl, rows_text	     ; (HL) = Static text of the row.
	ld   de, results	     ; (DE) = `ccf` results.
	ld   ix, results + 6	     ; (IX) = `scf` results.
.print_table_row:
	call print		     ; Print the static text of the row.
	ld   a, (de)		     ; Print the results for `ccf` and point DE
	call print_yxf		     ;   to the next element in the results
	inc  de			     ;   array.
	dec  hl			     ; Point HL to the last two spaces in the
	dec  hl			     ;   static text of the row, and print those
	call print		     ;   spaces (column gap). Next, point HL to
	inc  hl			     ;   the static text of the next row.
	ld   a, (ix)		     ; Print the results for `scf` and point IX
	call print_yxf		     ;   to the next element in the results
	inc  ix			     ;   array.
	dec  c			     ;
	jr   nz, .print_table_row    ; Repeat until all rows have been printed.

	call print		     ; Now HL points to the footer; print it.

	ld   de, results	     ; Compare the values obtained with `ccf`,
	ld   hl, results + 6	     ;   against those obtained with `scf`.
	call compare_results	     ;   They should be the same; otherwise,
	cp   0			     ;   the behavior is unknown (or unstable)
	jr   nz, .unknown_flavor     ;   and we report it.

	ld   de, results	     ; Compare the values obtained with `ccf`
	ld   hl, results_on_zilog    ;   against the reference values for Zilog
	call compare_results	     ;   CPU models.
	ld   hl, zilog_text	     ;
	cp   0			     ; If the values match, report "Zilog
	jr   z, .print_result	     ;   flavor" and exit.

	ld   de, results	     ; Compare the values obtained with `ccf`
	ld   hl, results_on_nec_nmos ;   against the reference values for NEC
	call compare_results	     ;   NMOS CPU models.
	ld   hl, nec_nmos_text	     ;
	cp   0			     ; If the values match, report "NEC NMOS
	jr   z, .print_result	     ;   flavor" and exit.

	ld   de, results	     ; Compare the values obtained with `ccf`
	ld   hl, results_on_st_cmos  ;   against the reference values for ST
	call compare_results	     ;   CMOS CPU models.
	ld   hl, st_cmos_text	     ;
	cp   0			     ; If the values match, report "ST CMOS
	jr   z, .print_result	     ;   flavor" and exit.

.unknown_flavor:
	ld   hl, unknown_text	     ; Report "Unknown flavor".
.print_result:
	call print
	ld   hl, flavor_text
	call print
	ei			     ; Re-enable interrupts.
	ret			     ; Exit to BASIC.


; Keeps YF and XF into the results array.
;
; On entry:
;   BC - Address of the element in the results array.
; On exit:
;   BC - Address of the next element in the results array.
; Destroys:
;   A and DE.

keep_yxf:
	push af	       ; Transfer F to A.
	pop  de	       ;
	ld   a, e      ;
	and  00101000b ; Clear all flags except YF and XF.
	ld   (bc), a   ; Keep YF and XF into the results array.
	inc  bc	       ; Point BC to the next element of the array.
	ret


; Prints YF and XF.
;
; On entry:
;   A - Flags.
; Destroys:
;   A and B.

print_yxf:
	ld   b, a ; Copy the flags to B.
	srl  b	  ; Shift the flags to the right until XF is at bit 0.
	srl  b	  ;
	srl  b	  ;
	ld   a, b ; Copy the shifted flags back to A, and shift this register to
	srl  a	  ;   the right until YF is at bit 0 (we need to use 2 registers
	srl  a	  ;   because YF is printed first).
	and  1	  ; Clear all bits except bit 0.
	add  $30  ; Translate the value of YF to ASCII.
	rst  $10  ; Print the value of YF.
	ld   a, b ; Copy B to A. Now bit 0 of A contains XF.
	and  1	  ; Clear all bits except bit 0.
	add  $30  ; Translate the value of XF to ASCII.
	rst  $10  ; Print the value of XF.
	ret


; Prints a 1Fh-terminated string.
;
; On entry:
;   HL - String address.
; On exit:
;   HL - Address of the termination byte.
; Destroys:
;   A.

print:	ld   a, (hl)
	cp   $1F
	ret  z
	rst  $10
	inc  hl
	jr   print


; Compares 2 arrays of results.
;
; On entry:
;   HL - Array 1 address.
;   DE - Array 2 address.
; On exit:
;   A - 0 if the arrays are equal; otherwise, a non-zero value.
; Destroys:
;   C, DE and HL.

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
header_text:
	db 'Z80 XCF '
	db 19, 1, 17, 2, 16, 7, 'F', 17, 3, 'L', 17, 1, 'A', 17, 5, 16, 8, 'V'
	db 17, 4, 'O', 17, 6, 'R', 17, 8, 16, 8, 19, 8, ' v1.4 (',__DATE__,")\r"
	db 127, ' Manuel Sainz de Baranda y Go', $90, "i\r"
	db 16, 1, 'https://zxe.io', 16, 8, "\r"
	db "\r"
	db "This program checks the behavior\r"
	db "of the undocumented flags during\r"
	db "the CCF and SCF instructions and\r"
	db "detects the Z80 CPU type of your\r"
	db "ZX Spectrum.\r"
	db "\r"
	db 19, 1, 17, 0, 16, 7,"  Case    Any  NEC   ST    HOST \r"
	db " Tested  Zilog NMOS CMOS   CPU  \r"
	db '(Q<>F)|A   YX   YX   YX   YX  YX', 17, 8, 16, 8, 19, 8, $1F
rows_text:
	db "\r(0<>0)|0   00   00   00   ", $1F
	db "\r(0<>1)|0   11   00   10   ", $1F
	db "\r(1<>1)|0   00   00   00   ", $1F
	db "\r(0<>0)|1   11   11   11   ", $1F
	db "\r(0<>1)|1   11   11   11   ", $1F
	db "\r(1<>1)|1   11   11   11   ", $1F
footer_text:
	db 17, 0, 16, 7, 23, 25, 0, 19, 1, 'ccf scf', 17, 8, 16, 8, 19, 8, "\r"
	db "\r"
	db 'Result: ', $1F
zilog_text:
	db 19, 1, 17, 4, 'Zilog', $1F
nec_nmos_text:
	db 19, 1, 17, 4, 'NEC NMOS', $1F
st_cmos_text:
	db 19, 1, 17, 4, 'ST CMOS', $1F
unknown_text:
	db 19, 1, 17, 2, 18, 1, 'Unknown', 18, 8, $1F
flavor_text:
	db 17, 8, 19, 8, ' flavor', $1F
nn:
	db 00000000b ; ñ
	db 00111000b
	db 00000000b
	db 01011000b
	db 01100100b
	db 01000100b
	db 01000100b
	db 00000000b

PROGRAM_SIZE = $ - start


	savesna 'Z80 XCF Flavor.sna', start


CLEAR	  = $FD
CODE	  = $AF
LOAD	  = $EF
RANDOMIZE = $F9
USR	  = $C0

	org $5C00
basic:	db  0, 1
	dw  LINE_1_SIZE
line_1:	db  CLEAR, '8', $0E, 0, 0
	dw  start - 1
	db  0, ':'
	db  LOAD, '"'
name:	ds  10, 32
	org name
	db  'XCF Flavor'
	org name + 10
	db  '"', CODE, $0D
LINE_1_SIZE = $ - line_1
	db  0, 2
	dw  LINE_2_SIZE
line_2:	db  RANDOMIZE, USR, '8', $0E, 0, 0
	dw  start
	db  0, $0D
LINE_2_SIZE = $ - line_2
BASIC_SIZE  = $ - basic

	macro MAKE_TAPE tap_name, file_name
		emptytap tap_name
		savetap  tap_name, BASIC, file_name, basic, BASIC_SIZE, 1
		savetap  tap_name, CODE, file_name, start, PROGRAM_SIZE, start
	endm

	MAKE_TAPE 'Z80 XCF Flavor.tap', 'XCF Flavor'

; EOF
