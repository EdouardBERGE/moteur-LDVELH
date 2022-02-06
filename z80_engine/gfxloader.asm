
include 'dzx0_standard.asm'

;*********************************************************
                      PlaceHasGFX
;*********************************************************
nop
push hl
ex hl,de
ld ix,gfxplace
ld b,0
.reloop
inc b
ld hl,(ix+0) : inc ix : inc ix : ld a,h : or l : jr z,.deadgfx
sbc hl,de
jr nz,.reloop : jr .found

.deadgfx
ld hl,(ix+0) : inc ix : inc ix : ld a,h : or l : jr z,.byebye
sbc hl,de
jr nz,.deadgfx

.found
; found
ld a,b : push af
call MotorON
ld hl,#B000-1024 ;
pop af ; track
di
call read_sector
ei
call MotorOFF
call razscreen
ld bc,#BC06 : out (c),c : ld bc,#BD00    : out (c),c
ld bc,#BC01 : out (c),c : ld bc,#BD01    : out (c),c
ld hl,#B000-1024
ld de,#C000
call zx0decrunch
ld bc,#BC06 : out (c),c : ld bc,#BD00+23 : out (c),c : xor a : ld b,6
.enlarge halt : djnz .enlarge : inc a : ld bc,#BC01 : out (c),c : inc b : out (c),a : ld b,6 : cp 44 : jr nz,.enlarge

.byebye
pop hl
ret

zx0decrunch zx0_decrunch (void)

;*********************************************************
                           GURU
;*********************************************************
ei : pop hl ; read_sector
call MotorOFF
pop hl ; place
ld a,#C9
ld (PlaceHasGFX),a ; premier couac avec les IO on désactive les chargements
;
ld hl,348 ; full width
ld (writer.dynamicwidth_001+1),hl
ld (writer.dynamicwidth_002+1),hl
ld a,88
ld (razscreen.dynamicwidth_003+1),a
ret

gfxplace defw 1,14,30,39,59,71,82,101,116,128,139,149,158,168,195,211,235,249,254,268,279,291,305,317,325,337,350,360,379,390,0
deadplace defw 132,157,188,234,260,307,313,331,346,357,0

