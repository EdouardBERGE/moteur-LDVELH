
assert MAX_REQUIRED_BYTE_KEY*8 >= MAX_KEY_BITS ; consistency check

;********************************************
              huffman_decode
; HL=source
; DE=destination
;********************************************
xor a ; init bit shifter
exa
.decrunch
exa
call .getchar : exx : ld (de),a : inc de
or a ; endmark?
jr nz,.decrunch
ret

.getchar
exx
ld hl,.currentcode
ld bc,(.currentcode_end-.currentcode)<<8
.raz ld (hl),c : inc hl : djnz .raz

ld ix,huffman_list

IF HUFFMAN_BITLEN_START<8
HUFFMAN_ENGINE_TYPE=0

; optimized search for 8 bits sequences or less
ld e,0
IF HUFFMAN_BITLEN_START>1
	ld c,9-HUFFMAN_BITLEN_START
	repeat HUFFMAN_BITLEN_START-1
		add a : call z,.getbyte : rl e
	rend
ELSE
	ld c,8
ENDIF

.optimized_8bit_search
add a : call z,.getbyte : rl e
exa
ld hl,(ix+0)
ld a,(hl) : inc hl : or a : jr z,.nokeyforthislength
ld b,a ; key count
.loopkeylength
ld a,(hl) : inc hl : cp e : ld a,(hl) : ret z ; A=decrunched value
inc hl
djnz .loopkeylength

.nokeyforthislength
exa
inc ix : inc ix
dec c
jr nz,.optimized_8bit_search
ELSE
	IF HUFFMAN_BITLEN_START<16

	ld b,HUFFMAN_BITLEN_START
.skipfirst
	add a : call z,.getbyte : rl e
	djnz .skipfirst
	ld c,17-HUFFMAN_BITLEN_START
	ELSE
		print 'unsupported case that will probably never exists'
		assert 1==0
	ENDIF
ENDIF


IF MAX_KEY_BITS-8>0
HUFFMAN_ENGINE_TYPE=1

ld c,8
ld d,0
.optimized_16bit_search
add a : call z,.getbyte : rl e : rl d
exa
ld hl,(ix+0)
ld a,(hl) : inc hl : or a : jr z,.nokeyforthislength2
ld b,a ; key count
.loopkeylength2
ld a,(hl) : inc hl : cp d : jr nz,.skip2
ld a,(hl) : inc hl : cp e
ld a,(hl) : ret z ; A=decrunched value
dec hl
.skip2
inc hl
inc hl
djnz .loopkeylength2

.nokeyforthislength2
exa
inc ix : inc ix
dec c
jr nz,.optimized_16bit_search

;*************************************************************************************************
;****************** this one is fully generic so slower than 2 optimised previous one ************
;*************************************************************************************************
IF MAX_KEY_BITS-16>0
HUFFMAN_ENGINE_TYPE=2

ld (.currentcode),de ; move current code from registers to RAM
ld c,MAX_KEY_BITS-16
.optimized_moar_bit_search
add a : call z,.getbyte : ld hl,.currentcode : ld b,MAX_REQUIRED_BYTE_KEY
.insertbit rl (hl) : inc hl : djnz .insertbit
exa
ld de,(ix+0)
ld a,(de) : inc de : or a : jr z,.nokeyforthislengthG
ld b,a ; key count

.loopkeylengthG
push de
ld hl,.currentcode

repeat MAX_REQUIRED_BYTE_KEY
ld a,(de) : cp (hl) : jr nz,.skipG : inc de : inc hl
rend
ld a,(de) : ret z ; A=decrunched value

.skipG
;*** very very generic skip **
pop de
repeat MAX_REQUIRED_BYTE_KEY+1
inc de
rend
djnz .loopkeylengthG

.nokeyforthislengthG
exa
inc ix : inc ix
dec c
jr nz,.optimized_16bit_search

ENDIF
ENDIF

print 'Huffman decoding engine use '
switch HUFFMAN_ENGINE_TYPE
case 0 : print '8 bits decoding' : break
case 1 : print '16 bits decoding' : break
case 2: print 'full bits decoding' : break
endswitch

; GURU?
brk
jr $

.getbyte
exx
ld a,(hl)
inc hl
sll a
exx
ret

.currentcode
defs MAX_REQUIRED_BYTE_KEY
.currentcode_end

print '; huffman decoding engine ',$-huffman_decode

