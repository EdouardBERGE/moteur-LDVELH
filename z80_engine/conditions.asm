



macro CONDITION_SINGLE lieu, destination
	defw {lieu}+32768,{destination}
mend

macro CONDITION_INIT lieu,venu
	defw {lieu},{venu}
mend
macro CONDITION_NEXT lieu,destination
	defw {lieu}+16384,{destination}
mend
macro CONDITION_END lieu
	defw {lieu}
mend

; on a besoin de garder une trace de notre passage!
IF !USEMAP
map_tag defs NBPLACES,0 ; @@AFINIR!!! modifs à faire dans le writer_map
ENDIF


; HL=place
conditions
ld ix,.liste
ex hl,de ; dans DE
push de

;ld hl,de
;ld bc,320
;xor a
;sbc hl,bc : jr nz,.reloop
;brk

.reloop
ld hl,(ix+0) : ld a,h : or l : jp z,.out
bit 7,h : jr z,.init
.single
ld bc,4 : add ix,bc
res 7,h
sbc hl,de : jr nz,.reloop
; match! est-on déjà venu?
ld hl,de : ld bc,map_tag-1 : add hl,bc : ld a,(hl) : or a : jp z,.out ; non!
ld de,(ix-2) ; changer le lieu
jp .out

.init
sbc hl,de : jr nz,.tester_venu
; on vient sur le paragraphe de la clairiere
ld hl,map_tag-1 : add hl,de : ld a,(hl) : or a : jp z,.out ; on est sur le bon paragraphe mais rien à faire
.tester_venu
ld hl,(ix+2) : xor a : sbc hl,de : jr z,.condition_next ; on vient directement sur le paragraphe de déjà venu
.skip4
ld bc,4
add ix,bc ; skip prologue
bit 6,(ix+1) : jr nz,.skip4
inc ix : inc ix
jr .reloop

.condition_next
ld bc,4
add ix,bc ; skip prologue
bit 6,(ix+1) : jr z,.condition_end
ld hl,(ix+0) : res 6,h
ld bc,map_tag-1 : add hl,bc : ld a,(hl) : or a : jr z,.condition_next ; +skip4
inc ix : inc ix
.condition_end
ld de,(ix+0)
jp .out

.liste
;CONDITION_SINGLE 398,239
;CONDITION_INIT    11,210 : CONDITION_NEXT 125,243 : CONDITION_END 143 ; bête immonde
defw 0

.out
; lieu courant dans DE
ld bc,map_tag-1 : pop hl   : ld (current_visited),hl ; on met toujours les lieux de référence pour la map
                             add hl,bc : ld (hl),1 ; make tag for previous HL
                  ld hl,de : add hl,bc : ld (hl),1 ; make tag for current HL
ex hl,de
; lieu courant dans HL

