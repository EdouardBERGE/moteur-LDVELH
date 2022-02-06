
FastTrack
ld a,#03 : call sendFDCcommand ; commande de réglage du lecteur
ld a,#C1 : call sendFDCparam   ; step rate à 4ms au lieu de 6ms de l'AMSDOS / head unload à 16ms
ld a,#03 : call sendFDCparam   ; head load time 6ms
ret

sendFDCcommand
push hl,bc,af
ld bc,#FB7E   ; statut port
ld hl,0       ; init timeout counter
.waitready
inc hl
ld a,h : or l : call z,unblockFDC     ; au bout d'une seconde on débloque
in a,(c) : jp p,.waitready            ; tant que bit 7 nul, on attend
bit 6,a : call nz,unblockFDC          ; si bit 6 alors le FDC veut renvoyer quelque chose
inc c                                 ; sinon tout est ok pour envoyer au FDC
pop af
out (c),a
pop bc,hl
ret

sendFDCparam
push bc
ld bc,#FB7E   ; statut port
.waitready in 0,(c) : jp p,.waitready ; tant que le FDC est occupé, on attend
inc c         ; I/O port
out (c),a
pop bc
ret

UnblockFDC
in a,(c)
call p,.forceIO ; tant qu'il n'a vraiment rien à nous dire, on tape dans le port I/O
.ready
inc hl
ld a,h : or l : jr z,UnblockFDC
in a,(c) : jp p,.ready
bit 6,a     ; 0:FDC prêt à recevoir 1:FDC prêt à envoyer
ret z       ; FDC dispo à écouter et en attente, on s'en va
inc c
in a,(c)    ; dépiler une donnée du port I/O
dec c
jr .ready

.forceIO inc c : out (c),0 : dec c : ret ; demande de version de la puce

GetResult
push de,hl
ld d,7       ; max de résultats à récupérer
ld hl,result ; tableau des résultats
.wait_ready in a,(c) : jp p,.wait_ready
and 64 : jr z,.GetDone      ; est-ce un résultat?
inc c : ini : inc b : dec c ; oui, on le stocke
dec d
jr nz,.wait_ready
.GetDone
ld a,7          ; nombre de résultats récupérés
sub d           ; est égal à 7 moins restant à faire
ld (nbresult),a ; on enregistre ce nombre
pop hl,de
ret

nbresult    defb 0
result      defs 7
track       defb 0
motor_state defb 0
maxretry    defb 5

; A=lecteur a calibrer
CalibrateDrive
push de
ld d,a ; sauvegarde du lecteur dans D
caliretry
ld a,7:call sendFDCcommand ; calibration
ld a,d:call sendFDCparam   ; lecteur
calires
ld a,8:call sendFDCcommand ; sense int state, pas d'autre paramètre!
call GetResult
ld a,(nbresult) : cp 2 : jr nz,calires ; 2 résultats ou rien
ld a,(result) : and #F8                ; on garde uniquement les bits d'état de ET0
                                       ; sinon ça ne fonctionnera 
cp 32 : jr nz,caliretry                ; si problème on recommence
pop de
ret

; D=lecteur
; E=piste
SeekTrack
ld a,15:call sendFDCcommand ; déplacement piste
ld a,d :call sendFDCparam   ; lecteur
ld a,e :call sendFDCparam   ; piste
WaitSeek
ld a,8 :call sendFDCcommand
call GetResult
ld a,(nbresult) : cp 2 : jr nz,WaitSeek ; 2 résultats ou rien, comme la calibration
ld a,(result) : and #F8                 ; on ne conserve que les bits d'état de ET0
cp 32 : jr nz,WaitSeek                  ; est-ce que l'instruction est terminée?
ld a,(result+1) : cp e : ret z          ; on est sur la piste on s'en va
ld a,d : call CalibrateDrive            ; sinon on recalibre
ld a,(maxretry) : dec a : ld (maxretry),a
jr nz,SeekTrack                         ; et on recommence
jp GURU

MotorON
push bc
ld bc,#FA7E : ld a,1 : out (c),a   ; on démarre
ld (motor_state),a
ld bc,0                            ; on attend environ 1s
.wait push bc : pop bc : djnz .wait : dec c : jr nz,.wait
pop bc
ret

MotorOFF
push bc
ld bc,#FA7E : xor a : out (c),a
ld (motor_state),a
pop bc
ret


ld a,4:call sendFDCcommand ; récupération d'ET3
ld a,d:call sendFDCparam   ; lecteur
call GetResult
ret

; HL=buffer dest
;---------------
; HL=byte next after buffer
; A=track
read_sector
ld bc,#FB7E
ld (track),a : ld d,0 : ld e,a : call seektrack
ld a,#46     : call sendFDCcommand ; command
xor a        : call sendFDCparam ; drive
ld a,(track) : call sendFDCparam ; track
xor a        : call sendFDCparam ; head
ld a,#4D     : call sendFDCparam ; start sector
ld a,3       : call sendFDCparam ; sector size
ld a,#51     : call sendFDCparam ; end sector
ld a,#4F     : call sendFDCparam ; GAP
ld a,5       : call sendFDCparam ; sector size again...
jr read_data.waitready

read_data
.store
inc c : ini : inc b : dec c
.waitready in a,(c) : jp p,.Waitready
and 32 : jr nz,.store

call GetResult

; check des erreurs
ld a,(nbresult) : cp 7 : jp nz,GURU
ld a,(result+0) ; ET0
and 128+64+16+8 ; => ERROR
cp #40
jp nz,GURU
ld a,(result+1) ; ET1
and 32+16+4+1 ; => ERROR
jp nz,GURU
ld a,(result+2) ; ET2
and 32+16 ; => ERROR
jp nz,GURU

ret


