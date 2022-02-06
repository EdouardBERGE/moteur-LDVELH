
include 'dico.asm'

links  defs MAXLINKS*2
nblink defb 0

; HL=source
; DE=destination
translate
push hl
call razscreen.from_translate
pop hl
ld de,buffer2
call huffman_decode
ld hl,buffer2
ld de,buffer
ld ix,links
xor a : ld (nblink),a

.reloop
ld a,(hl) : inc hl
or a : jp z,.poke_terminator
cp 1 : jr z,.process_link
cp DICO_START : jr nc,.process_key
ld (de),a
inc de
jr .reloop

.process_key
push hl
sub DICO_START
ld h,0 : ld l,a
add hl,hl
ld bc,dictionnaire
add hl,bc
ld a,(hl) : inc hl : ld h,(hl) : ld l,a
.copy_key ld a,(hl) : or a : jr z,.copy_end : ld (de),a : inc hl : inc de : jr .copy_key

.copy_end
pop hl
jr .reloop

.process_link
push hl
ld a,CHAR_A_CODE : ld (de),a : inc de
ld a,CHAR_U_CODE : ld (de),a : inc de
ld a,CHAR_SPACE_CODE : ld (de),a : inc de
ld a,CHAR_OPEN_CODE : ld (de),a : inc de
ld a,(hl) : inc hl : ld h,(hl) : ld l,a ; HL=raw code
dec h : ld a,h
jr z,.link_ok
.link_decode dec l : dec h : jr nz,.link_decode
.link_ok ld h,a : ld (ix+0),hl : inc ix : inc ix

ld a,(nblink) : inc a : ld (nblink),a
add CHAR_LINK_CODE : ld (de),a : inc de ; hyperlink
ld a,CHAR_CLOSE_CODE : ld (de),a : inc de

pop hl : inc hl : inc hl ; skip code
jr .reloop

.poke_terminator ld (de),a : ret

