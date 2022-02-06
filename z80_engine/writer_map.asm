USEMAP=0

buildsna
bankset 0

nop

org #100
ld bc,#7FC7 : out (c),c
ld hl,#7FFF : ld e,4 : ld bc,#7F03
.setpal out (c),c : ld a,(hl) : or #40 : out (c),a : dec hl : dec c : dec e : jr nz,.setpal
ld c,#10 : out (c),c : out (c),a
ld bc,#7FC0 : out (c),c
jp zi_entry

include 'translate.asm'

WRITER_SPACE_IDX   equ CHAR_SPACE_CODE
WRITER_CR_IDX      equ CHAR_PIPE_CODE
WRITER_MAX_LINE    equ 15
WRITER_PIXEL_WIDTH equ 348-134 ; small margin'
WRITER_BYTE_WIDTH  equ 88


zi_entry

di
ld hl,#C9FB
ld (#38),hl
ei

ld bc,#BC01 : out (c),c : ld bc,#BD00+44 : out (c),c
ld bc,#BC02 : out (c),c : ld bc,#BD00+48 : out (c),c
ld bc,#BC06 : out (c),c : ld bc,#BD00+23 : out (c),c
ld bc,#BC0C : out (c),c : ld bc,#BD30    : out (c),c
ld bc,#BC0D : out (c),c : ld bc,#BD00    : out (c),c

ld bc,#7F10 : out (c),c : ld a,64+3  : out (c),a
ld bc,#7F00 : out (c),c : ld a,64+3  : out (c),a
ld bc,#7F01 : out (c),c : ld a,64+20 : out (c),a
ld bc,#7F02 : out (c),c : ld a,64+30 : out (c),a
ld bc,#7F03 : out (c),c : ld a,64+28 : out (c),a


;*******************************
          reboot
;*******************************
call init_personnage
xor a
ld (rollbackidx),a ; reset rollback
ld hl,401
;*******************************
         change_place
;*******************************
ld sp,#100
call load_place

;*******************************
          main_loop
;*******************************
ld hl,buffer
call writer

.waitkey
call scankeyboard
call writer.test_place
ld a,(KEY_SPACE_BYTE) : and KEY_SPACE_BIT : jr nz,main_loop
jr .waitkey



;*******************************
          load_place
; HL=numplace
;*******************************
; save history up to 128 places
push hl

ld a,(rollbackidx)
cp 254
jr nz,.firstroll
ld hl,rollback+2
ld de,rollback
ld bc,766 ; shift all buffers
ldir
ld a,254
.firstroll

ld h,hi(rollback) : ld l,a
pop de
ld (hl),e : inc l : ld (hl),d
; extended historisation
ld a,(habilete) : inc h : ld (hl),a : dec l
ld a,(endurance) : ld (hl),a
ld a,(chance) : inc h : ld (hl),a
ld a,(chance_depart) : inc l : ld (hl),a ; La chance peut être influencée

ex hl,de

ld a,(rollbackidx)
cp 254
jr z,.from_rollback
add 2
ld (rollbackidx),a

.from_rollback

;***********************************************************************************
;***********************************************************************************
;                  evenements specifiques au deblocage de la fin
;***********************************************************************************
;***********************************************************************************
;include 'conditions.asm'

call PlaceHasGFX ; GFX ?
call engine_prep ; bonus? combat?

dec hl ; numéro interne commence à zéro
ld bc,hl : add hl,hl : add hl,bc : ld bc,zeplaces : add hl,bc
ld b,#7F : ld c,(hl) : inc hl : out (c),c
ld a,(hl) : inc hl : ld h,(hl) : ld l,a
jp translate


;************************************************************
                        make_rollback
;************************************************************
ld a,(rollbackidx)
cp 2 : jp z,writer.retest_place ; on ne revient jamais sur zéro
sub 4
ld (rollbackidx),a
.nomoar
ld h,hi(rollback) : ld l,a
ld e,(hl) : inc l : ld d,(hl)
inc h : ld a,(hl) : ld (habilete),a
dec l : ld a,(hl) : ld (endurance),a
inc h : ld a,(hl) : ld (chance),a
inc l : ld a,(hl) : ld (chance_depart),a
ex hl,de
jp change_place

;***************************************************
;***************************************************
                         writer
;***************************************************
;***************************************************
.init
exx
xor a
ld (.current_y),a
ld hl,#C000
ld (.current_addr),hl
call razscreen
exx

.print ; HL=string
push hl
exx
ld hl,0 ; minimal number of pixel used for the current string
ld (.current_x),hl
exx

.print_compute
; overflowing screen width?
exx
xor a
ex hl,de
ld hl,de
.dynamicwidth_001 ld bc,WRITER_PIXEL_WIDTH
sbc hl,bc
jp p,.justify ; soit on tombe juste, soit on dépasse, GOTO justify
;addchar
ex hl,de
exx

ld a,(hl)
or a
jp z,.on_screen
cp WRITER_CR_IDX
jp z,.on_screen

; count space usage and save last valid space position
cp WRITER_SPACE_IDX
jr nz,.getwidth
exx
ld (.last_space_width),hl
exx
ld (.last_space_char),hl

.getwidth
; getstruct of the char
ld bc,fontdefinition
sub 2 : ld xh,0 : ld xl,a
add ix,ix : add ix,ix : add ix,bc
ld a,(ix+3) ; pixel width
call .adjust_spaces ; exceptions / modify A / preserve HL
exx
ld b,0
ld c,a
add hl,bc
exx
inc hl
jr .print_compute

;**************************************************
; now we must compute precise spacing
;**************************************************
.justify
; count spaces in the string to print
ld hl,(.last_space_char)
ld a,l : ld (.countspaces_L+1),a
         ld (.cmpend_L+1),a
ld a,h : ld (.countspaces_H+1),a
         ld (.cmpend_H+1),a
ld e,0
pop hl : push hl

.countreloop
ld a,l
.countspaces_L cp 0 : jr nz,.countnext
ld a,h
.countspaces_H cp 0 : jr z,.countdone
.countnext
ld a,(hl) : inc hl : cp WRITER_SPACE_IDX : jr nz,.countreloop
inc e : jp .countreloop

.countdone
; at this point we have the number of spaces and the raw size of the string
exx : ld hl,.space_bonus : ld de,.space_bonus+1 : ld bc,31 : ld (hl),0 : ldir : exx ; RAZ

.dynamicwidth_002 ld hl,WRITER_PIXEL_WIDTH
ld bc,(.last_space_width)
sbc hl,bc ; C always zero here
jr z,.from_justify ; line is always FULL of pixels
.space_distribution
ld d,e
ld iy,.space_bonus
.space_reloop
inc (iy+0)
dec hl : ld a,h : or l : jr z,.from_justify
inc iy : dec d : jr nz,.space_reloop
jr .space_distribution


;***************************************************************
; display all char until the end => (HL) char wont be displayed
; HL => EOS
; stack contains HL start
;***************************************************************
.on_screen
exx : ld hl,.space_bonus : ld de,.space_bonus+1 : ld bc,31 : ld (hl),0 : ldir : exx ; RAZ

ld a,l : ld (.cmpend_L+1),a
ld a,h : ld (.cmpend_H+1),a
.from_justify
ld iy,.space_bonus
pop hl ; retrieve beginning of the string

.next_char
; is it the end?
ld a,l : .cmpend_L cp 0 : jr nz,.cmpend
ld a,h : .cmpend_H cp 0 : jp .carriage_return
.cmpend

xor a
call .adjust_spaces ; exceptions / modify A / preserve HL
ld e,a : ld d,a : xor a : sra d : ld (.modifier+1),de
ld a,(hl)
inc hl : push hl


ld bc,fontdefinition
sub 2 : ld xh,0 : ld xl,a
add ix,ix : add ix,ix : add ix,bc

cp WRITER_SPACE_IDX-2
jp z,.apply_justif


;ld c,(ix+2)
; determiner le decalage 0->0 3->1 2->2 1->3
ld a,(.current_x) : and 3
add a : ld hl,.jumptable : add l : ld l,a : ld a,(hl) : inc l : ld h,(hl) : ld l,a : ld (.zecall+1),hl

ld hl,(.current_addr)
ld de,(.current_x) : srl de : srl de
add hl,de
ld de,(ix+0)
.zecall call #1234

;repeat 10 : halt : rend : brk

ld hl,(.current_x)
ld b,0 : ld c,(ix+3)
add hl,bc
.modifier ld bc,#1234 ; 0 ou -1
add hl,bc
ld (.current_x),hl
pop hl
jp .next_char

;*** space has variable length ***
.apply_justif
ld hl,(.current_x)
ld b,0 : ld c,(ix+3)
add hl,bc
ld c,(iy+0) : inc iy
add hl,bc
ld (.current_x),hl
pop hl
jp .next_char

;*** CR or EOL ***
.carriage_return
push hl
ld hl,(.current_addr)
ld de,WRITER_BYTE_WIDTH
add hl,de ; line+=8
ld de,2048 : ld b,4
.carriage_next add hl,de : djnz .carriage_next : jp nc,.carriage_ok : ld de,WRITER_BYTE_WIDTH-16384 : add hl,de
.carriage_ok
ld (.current_addr),hl

pop hl
ld a,(hl) : or a : ret z ; touche inutile si fin du texte sur la derniere ligne
push hl

ld hl,.current_y
inc (hl) : ld a,(hl) : cp WRITER_MAX_LINE : jp z,.waitkey_entry

.before_new_line
pop hl
inc hl
jp .print ; @@TOCHECK


.inner_noshift
ld a,(ix+2) : ld (.bytewidth_noshift+1),a ; 5+4 rentabilisé en 3 lignes (sur 12)
ld c,12
.draw_char_noshift
push hl
.bytewidth_noshift ld b,#12
.inner0
ld a,(de) : ld (hl),a : inc hl : inc de
djnz .inner0
pop hl
ld a,8 : add h : ld h,a
jr nc,.next_line_noshift
ld a,l : add WRITER_BYTE_WIDTH : ld l,a
ld a,h : adc #C0 : ld h,a
.next_line_noshift
dec c : jr nz,.draw_char_noshift
ret

.inner_shift1
ld a,(ix+2) : ld (.bytewidth_shift1+1),a ; 5+4 rentabilisé en 3 lignes (sur 12)
ld c,12
.draw_char_shift1
push hl
.bytewidth_shift1 ld b,#12
.inner1
ld a,(de) : srl a : and %1110111 : or (hl) : ld (hl),a : inc hl
ld a,(de) : add a : add a : add a : and %10001000 : or (hl) : ld (hl),a : inc de
djnz .inner1
pop hl
ld a,8 : add h : ld h,a
jr nc,.next_line_shift1
ld a,l : add WRITER_BYTE_WIDTH : ld l,a
ld a,h : adc #C0 : ld h,a
.next_line_shift1
dec c : jr nz,.draw_char_shift1
ret

.inner_shift2
ld a,(ix+2) : ld (.bytewidth_shift2+1),a ; 5+4 rentabilisé en 3 lignes (sur 12)
ld c,12
.draw_char_shift2
push hl
.bytewidth_shift2 ld b,#12
.inner2
ld a,(de) : srl a : srl a : and %110011   : or (hl) : ld (hl),a : inc hl
ld a,(de) : add a : add a : and %11001100 : or (hl) : ld (hl),a : inc de
djnz .inner2
pop hl
ld a,8 : add h : ld h,a
jr nc,.next_line_shift2
ld a,l : add WRITER_BYTE_WIDTH : ld l,a
ld a,h : adc #C0 : ld h,a
.next_line_shift2
dec c : jr nz,.draw_char_shift2
ret

.inner_shift3
ld a,(ix+2) : ld (.bytewidth_shift3+1),a ; 5+4 rentabilisé en 3 lignes (sur 12)
ld c,12
.draw_char_shift3
push hl
.bytewidth_shift3 ld b,#12
.inner3
ld a,(de) : srl a : srl a : srl a : and %10001  : or (hl) : ld (hl),a : inc hl
ld a,(de) : add a : and %11101110 : or (hl) : ld (hl),a : inc de
djnz .inner3
pop hl
ld a,8 : add h : ld h,a
jr nc,.next_line_shift3
ld a,l : add WRITER_BYTE_WIDTH : ld l,a
ld a,h : adc #C0 : ld h,a
.next_line_shift3
dec c : jr nz,.draw_char_shift3
ret

.current_y        defb 0
.current_x        defw 0
.current_addr     defw #C000
.last_space_char  defw 0
confine 8
.last_space_width defw 0

confine 8
.jumptable
defw .inner_noshift
defw .inner_shift1
defw .inner_shift2
defw .inner_shift3

.space_bonus defs 32 ; seems to be enough

.changeplace
ld hl,nblink
cp (hl)
ret nc ; retourne au writer ou au main
add a : ld c,a : ld b,0 : ld hl,links : add hl,bc
ld a,(hl) : inc hl : ld h,(hl) : ld l,a
jp change_place
.test_place
ld hl,(gestion_combat.addr+2) : ld a,h : or l : jr z,.nocombat
ld a,(KEY_C_BYTE) : and KEY_C_BIT : jp nz,gestion_combat
.nocombat
ld a,(KEY_T_BYTE) : and KEY_T_BIT : call nz,gestion_test ; au pire on revient si rien à faire
ld a,(KEY_J_BYTE) : and KEY_J_BIT : call nz,gestion_test ; au pire on revient si rien à faire
ld a,(KEY_F_BYTE) : and KEY_F_BIT : jp nz,fiche_personnage
ld a,(KEY_MA_BYTE) : and KEY_MA_BIT : jp nz,displaymap
ld a,(KEY_MQ_BYTE) : and KEY_MQ_BIT : jp nz,displaymap
ld a,(KEY_ESC_BYTE) : and KEY_ESC_BIT : jp nz,reboot
ld a,(KEY_R_BYTE) : and KEY_R_BIT : jp nz,make_rollback

;********* reset du moteur pour les GFX *************
ld a,(KEY_W_BYTE) : and KEY_W_BIT : jp z,.skipwidth
ld hl,348-134 ; full width
ld (writer.dynamicwidth_001+1),hl
ld (writer.dynamicwidth_002+1),hl
ld a,(352-134)/4
ld (razscreen.dynamicwidth_003+1),a
xor a
ld (PlaceHasGFX),a
.skipwidth

.retest_place
assert MAXLINKS<11
ld a,(KEY_1_BYTE) : and KEY_1_BIT : ld a,0 : jp nz,.changeplace: ld a,(KEY_F1_BYTE) : and KEY_F1_BIT : ld a,0 : jp nz,.changeplace
ld a,(KEY_2_BYTE) : and KEY_2_BIT : ld a,1 : jp nz,.changeplace: ld a,(KEY_F2_BYTE) : and KEY_F2_BIT : ld a,1 : jp nz,.changeplace
IF MAXLINKS>2
ld a,(KEY_3_BYTE) : and KEY_3_BIT : ld a,2 : jp nz,.changeplace: ld a,(KEY_F3_BYTE) : and KEY_F3_BIT : ld a,2 : jp nz,.changeplace
IF MAXLINKS>3
ld a,(KEY_4_BYTE) : and KEY_4_BIT : ld a,3 : jp nz,.changeplace: ld a,(KEY_F4_BYTE) : and KEY_F4_BIT : ld a,3 : jp nz,.changeplace
IF MAXLINKS>4
ld a,(KEY_5_BYTE) : and KEY_5_BIT : ld a,4 : jp nz,.changeplace: ld a,(KEY_F5_BYTE) : and KEY_F5_BIT : ld a,4 : jp nz,.changeplace
IF MAXLINKS>5
ld a,(KEY_6_BYTE) : and KEY_6_BIT : ld a,5 : jp nz,.changeplace: ld a,(KEY_F6_BYTE) : and KEY_F6_BIT : ld a,5 : jp nz,.changeplace
IF MAXLINKS>6
ld a,(KEY_7_BYTE) : and KEY_7_BIT : ld a,6 : jp nz,.changeplace: ld a,(KEY_F7_BYTE) : and KEY_F7_BIT : ld a,6 : jp nz,.changeplace
IF MAXLINKS>7
ld a,(KEY_8_BYTE) : and KEY_8_BIT : ld a,7 : jp nz,.changeplace: ld a,(KEY_F8_BYTE) : and KEY_F8_BIT : ld a,7 : jp nz,.changeplace
IF MAXLINKS>8
ld a,(KEY_9_BYTE) : and KEY_9_BIT : ld a,8 : jp nz,.changeplace: ld a,(KEY_F9_BYTE) : and KEY_F9_BIT : ld a,8 : jp nz,.changeplace
IF MAXLINKS>9
ld a,(KEY_0_BYTE) : and KEY_0_BIT : ld a,9 : jp nz,.changeplace: ld a,(KEY_F0_BYTE) : and KEY_F0_BIT : ld a,9 : jp nz,.changeplace
ENDIF: ENDIF: ENDIF: ENDIF: ENDIF: ENDIF: ENDIF: ENDIF
ret

.waitkey_entry
;
; display unfinished, display a small arrow
;
ld hl,#E7E4-134/4 : ld a,%01000100 : ld (hl),a : inc l : ld (hl),a : inc l : ld (hl),a
ld h,#FF                     : ld (hl),a : dec l : ld (hl),a : dec l : ld (hl),a
ld h,#EF    : ld a,%00110011 : ld (hl),a : inc l : ld (hl),a : inc l : ld (hl),a
ld h,#F7    : ld a,%00100000 : ld (hl),a : dec l : ld (hl),a : dec l : ld (hl),a

.waitkey

call scankeyboard
ld a,(KEY_SPACE_BYTE) : and KEY_SPACE_BIT : jr nz,.waitend
call .test_place
jp .waitkey

.waitend
call scankeyboard
ld a,(KEY_SPACE_BYTE) : and KEY_SPACE_BIT : jr nz,.waitend

pop hl
inc hl
jp writer.init

; HL=char courant
; A=largeur actuelle
.adjust_spaces
push hl
exa
ld e,2 : ld a,(hl) : cp CHAR_BIG_T_CODE : call z,.test_min
ld e,1 : ld a,(hl) : cp CHAR_BIG_V_CODE : call z,.test_min
ld a,(hl) : cp CHAR_BIG_Y_CODE : call z,.test_min ; pas pertinent en français
ld a,(hl) : cp CHAR_BIG_A_CODE : call z,.test_v
exa
pop hl
ret
.test_min
; >=CHAR_A_CODE && <=CHAR_SMALL_MAX_IDX
inc hl : ld a,(hl) : dec hl
cp CHAR_BIG_A_CODE : jr z,.decale ; forcé pour TA et VA
cp CHAR_A_CODE : ret c
cp CHAR_SMALL_MAX_IDX+1 : ret nc
.decale
exa : sub e : exa : ret
.test_v
inc hl : ld a,(hl) : dec hl : cp CHAR_V_CODE : ret nz
exa : dec a : exa : ret


include 'keyboard.asm'

include 'razscreen.asm'

zeplaces
repeat NBPLACES,x
defb {page}place{x} & 0xFF : defw place{x}
rend

rollbackidx defb 0

lastplace defw 0




IF USEMAP
zemap incbin 'cpcmap.zx0'
include 'dzx0_standard.asm'

zx0decrunch zx0_decrunch (void)

;*********************************************************
                      displaymap
;*********************************************************

ld e,22
.hop call .vbl : call .vbl : ld bc,#BC06 : out (c),c : ld b,#BD : out (c),e : dec e : ld a,#FF : cp e : jr nz,.hop

ld hl,zemap
ld de,#C000
call zx0decrunch

ld ix,map_definition ; liste à scanner

.loop
ld bc,(ix+0) : ld a,b : or c : jp z,.maketag ; terminé
bit 3,b : jr nz,.deuxplaces
bit 4,b : jr nz,.troisplaces
.uneplace
ld de,4 : add ix,de
ld hl,map_tag-1
add hl,bc
ld a,(hl)
or a
call z,.clean
jr .maywetag

.deuxplaces
res 3,b
ld de,6 : add ix,de
ld hl,map_tag-1
add hl,bc
ld a,(hl) : or a : jr nz,.deuxok
ld bc,(ix-4)
ld hl,map_tag-1
add hl,bc
ld a,(hl) : or a : call z,.clean
.deuxok
jr .maywetag

.troisplaces
res 4,b
ld de,8 : add ix,de
ld hl,map_tag-1
add hl,bc
ld a,(hl) : or a : jr nz,.troisok
ld bc,(ix-4)
ld hl,map_tag-1
add hl,bc
ld a,(hl) : or a : jr nz,.troisok
ld bc,(ix-6)
ld hl,map_tag-1
add hl,bc
ld a,(hl) : or a : call z,.clean
.troisok

.maywetag
;********************* lieu déjà visité *****************
ld hl,(current_visited) : xor a : sbc hl,bc : jr z,.tagplace
;ld hl,(last_visited) : xor a : sbc hl,bc : jr z,.retagplace
jp .loop

.tagplace
ld (last_visited_struct),ix ; on fait un backup du lieu courant
jp .loop
;.retagplace

;*******************************************************
.clean ; efface la tuile
ld hl,(ix-2) ; destination avec tag décalage
ld e,30
xor a
.razlineg push hl
ld d,8
.innerraz ld (hl),a : inc hl : dec d : jr nz,.innerraz
pop hl
ld bc,#800 : add hl,bc : jr nc,.addgok : ld bc,88-#4000 : add hl,bc : .addgok
dec e : jr nz,.razlineg
ret

.maketag
;*******************************************************
ld hl,(last_visited_struct)
ld a,h : or l : jr z,.waitkey ; no tag yet
dec hl : ld a,(hl) : dec hl
ld l,(hl) : ld h,a ; destination avec tag décalage
ld e,30
.taglineg push hl
ld d,8
.innertag ld a,(hl) : add a : add a : add a : add a : or (hl) : ld (hl),a : inc hl : dec d : jr nz,.innertag
pop hl
ld bc,#800 : add hl,bc : jr nc,.tagaddgok : ld bc,88-#4000 : add hl,bc : .tagaddgok
dec e : jr nz,.taglineg

.waitkey
call .vbl : ld bc,#BC06 : out (c),c : ld bc,#BD00+23 : out (c),c
call scankeyboard
ld a,(KEY_SPACE_BYTE) : and KEY_SPACE_BIT : jr z,.waitkey
jp main_loop

.vbl ld b,#F5 : in a,(c) : rra : jr c,.vbl
.novbl ld b,#F5 : in a,(c) : rra : jr nc,.novbl
ret
;*********************************************************

current_visited defw 0
last_visited_struct defw 0

include 'map_definition.asm'
ELSE
displaymap jp main_loop
ENDIF

align 256
rollback
defs 256

defs 512 ; endurance+chance+habilete+???


include 'huffman_decode.asm'

include 'floppy.asm'
include 'gfxloader.asm'
include 'ficheperso.asm'


distrib2=4 : ad2=#4000
distrib3=5 : ad3=#4000
distrib4=6 : ad4=#4000
distrib5=7 : ad5=#4000

include 'places.asm'

assert buffer>#7FFF

bank 4
save "./dskfiles/lezard.da4",#4000,#4000
save "lezard.da4",#4000,#4000,DSK,"datalight.dsk"
bank 5
save "./dskfiles/lezard.da5",#4000,#4000
save "lezard.da5",#4000,#4000,DSK,"datalight.dsk"
bank 6
save "./dskfiles/lezard.da6",#4000,#4000
save "lezard.da6",#4000,#4000,DSK,"datalight.dsk"
bank 7
save "./dskfiles/lezard.da7",#4000,#4000
save "lezard.da7",#4000,#4000,DSK,"datalight.dsk"

print {hex4}buffer

print 'donnees de gestion = ',dictionnaire-testliste
