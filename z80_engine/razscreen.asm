razscreen
jp .next
.next
xor a
ld (.refx),a

ld b,88+23

BLOCKMAX=(352-134)/4

.reloop
push bc
ld a,(.refx)
ld (.curx),a
ld b,23
ld hl,#C000 : ld e,a : ld d,l : add hl,de
halt
.loopy
push bc
ld a,(.curx) : .dynamicwidth_003 cp BLOCKMAX : jr nc,.nextblock
ld de,#800 : ld b,8
.raz ld (hl),e : add hl,de : djnz .raz

ld de,-#4000 : add hl,de
.nextblock
ld a,(.curx) : dec a : ld (.curx),a
ld de,87 : add hl,de
.plusbas
pop bc
djnz .loopy

ld hl,.refx : inc (hl)

pop bc
djnz .reloop
ret

.curx defb 0
.refx defb 0

.from_translate
ld hl,.skip
ld (razscreen+1),hl
jr .next

.skip
ld hl,.next
ld (razscreen+1),hl
jr .next

