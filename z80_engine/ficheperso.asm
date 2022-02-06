
debut_fiche=$

; personnage
habilete_depart  defb 12 ; 1D+6  ; hard 7 / medium 9 / easy 12
endurance_depart defb 24 ; 2D+12 ; hard 14 / medium 19 / easy 24
chance_depart    defb 12 ; 1D+6  ; hard 7 / medium 9 / easy 12
chance_minimum   defb 0  ; peut changer au cours de l'aventure
habilete  defb 0
endurance defb 0
chance    defb 0
rations   defb 0 ; 10 repas => sauf combat, un repas rend 4 pts d'endurance (total 40 pts)
potions   defb 0 ; b2:fortune b1:vigueur b0:adresse
habilete_modifier  defb 0
bonus_degats       defb 0

;potion de vigueur => revient au total depart
;potion bonne fortune => total depart + 1
;potion d'adresse => total depart

base10
ld e,CHAR_0_CODE-1
.dizaine
inc e : add -10 : jr c,.dizaine : add 10
exa : ld a,CHAR_0_CODE : cp e : jr nz,.adizaine
ld (hl),CHAR_SPACE_CODE : jr .afterzero
.adizaine ld (hl),e : .afterzero inc hl : exa : add CHAR_0_CODE : ld (hl),a : ret

init_message
ld de,buffer2-1
.copy inc de : .fromconcat ld a,(hl) : inc hl : ld (de),a : or a : jr nz,.copy
ld (concat_message.addr+1),de
ret
concat_message
.addr ld de,#1234
jr init_message.fromconcat

;***********************************************
             fiche_personnage
;***********************************************
; backup places
ld a,(nblink) :ld (.backuplink+1),a : xor a: ld (nblink),a

.reaffiche
ld a,(chance)   : ld hl,chance_dizaine   : call base10
ld a,(habilete) : ld hl,habilete_dizaine : call base10
ld a,(endurance): ld hl,endurance_dizaine: call base10
ld a,(rations)  : ld hl,ration_dizaine   : call base10

ld hl,msg_feuille_perso : call init_message
; potions
ld a,(potions) : bit 1,a : jr z,.skippotionvigueur
ld hl,msg_utiliser_potion_vigueur : call concat_message
.skippotionvigueur
ld a,(potions) : bit 2,a : jr z,.skippotionfortune
ld hl,msg_utiliser_potion_fortune : call concat_message
.skippotionfortune
ld a,(potions) : bit 0,a : jr z,.skippotionadresse
ld hl,msg_utiliser_potion_adresse : call concat_message
.skippotionadresse
; rations
ld a,(rations) : or a : jr z,.skipration
ld hl,msg_utiliser_ration : call concat_message
.skipration

call razscreen
ld hl,buffer2
call writer
.waitkey
call scankeyboard
ld a,(KEY_R_BYTE) : and KEY_R_BIT : jr nz,.ration
ld a,(KEY_V_BYTE) : and KEY_V_BIT : jr nz,.potion_vigueur
ld a,(KEY_B_BYTE) : and KEY_B_BIT : jr nz,.potion_fortune
ld a,(KEY_A_BYTE) : and KEY_A_BIT : jr nz,.potion_adresse
ld a,(KEY_SPACE_BYTE) : and KEY_SPACE_BIT : jr z,.waitkey
.backuplink ld a,#12 : ld (nblink),a : jp main_loop

.ration
ld a,(rations) : or a : jr z,.waitkey : dec a : ld (rations),a : ld a,(endurance_depart) : ld c,a : ld a,(endurance) : add 4 : cp c : jr c,.rationok : ld a,c : .rationok : ld (endurance),a : jp .reaffiche
.potion_vigueur
ld a,(potions) : bit 1,a : jr z,.waitkey : res 1,a : ld (potions),a : ld a,(endurance_depart) : ld (endurance),a : jp .reaffiche
.potion_fortune
ld a,(potions) : bit 2,a : jr z,.waitkey : res 2,a : ld (potions),a : ld a,(chance_depart) : inc a : ld (chance),a : jp .reaffiche
.potion_adresse
ld a,(potions) : bit 0,a : jr z,.waitkey : res 0,a : ld (potions),a : ld a,(habilete_depart) : ld (habilete),a : jp .reaffiche


;***********************************************
                   get_dice
;***********************************************
ld e,#77
.mogue ld hl,7654 : add hl,hl : add hl,de : ld (.mogue+1),hl
.loop dec h : jr nz,.loop
ld a,r
xor e
ld (get_dice+1),a
.reduce cp 5 : jr c,.getval : sub 6 : jr .reduce
.getval inc a
ret

;***********************************************
                init_personnage
;***********************************************
ld bc,#7FC0 : out (c),c ; ceinture!
ld a,10 : ld (rations),a
call razscreen
ld hl,msg_init_caracs
call writer
.waitkey
call scankeyboard
ld a,(KEY_1_BYTE) : and KEY_1_BIT : jr nz,.easy
ld a,(KEY_2_BYTE) : and KEY_2_BIT : jr nz,.medium
ld a,(KEY_3_BYTE) : and KEY_3_BIT : jr nz,.hard
ld a,(KEY_4_BYTE) : and KEY_4_BIT : jr nz,.random
jr .waitkey
ret
.easy   ld a,12 : ld (chance_depart),a : ld (habilete_depart),a : add a : ld (endurance_depart),a : jr .next
.medium ld a,9  : ld (chance_depart),a : ld (habilete_depart),a : add a : ld (endurance_depart),a : jr .next
.hard   ld a,7  : ld (chance_depart),a : ld (habilete_depart),a : add a : ld (endurance_depart),a : jr .next
.random
call get_dice : add 6 : ld (chance_depart),a
call get_dice : add 6 : ld (habilete_depart),a
call get_dice : add 6 : ld b,a : call get_dice : add b : ld (endurance_depart),a
.next
ld a,(chance_depart) : ld (chance),a
ld a,(habilete_depart) : ld (habilete),a
ld a,(endurance_depart) : ld (endurance),a
xor a : ld (chance_minimum),a

call razscreen
ld hl,msg_init_potion
call writer
.waitkey2
call scankeyboard
ld a,(KEY_1_BYTE) : and KEY_1_BIT : jr nz,.vigueur
ld a,(KEY_2_BYTE) : and KEY_2_BIT : jr nz,.fortune
ld a,(KEY_3_BYTE) : and KEY_3_BIT : jr nz,.adresse
jr .waitkey2
.vigueur ld a,2 : jr .termine
.fortune ld a,4 : jr .termine
.adresse ld a,1
.termine ld (potions),a : ret



;***********************************************
                 engine_prep
;***********************************************

;*** tout d'abord on applique les bonus définitifs ***
push hl
ex hl,de
ld ix,bonusliste
.loopbonus
ld a,(ix+1) : or a : jr z,.bonusend : and 15 : ld h,a : ld l,(ix+0) : sbc hl,de : jr z,.bonusfound
ld a,(ix+1) : ld bc,0 : push ix : pop hl : inc hl : inc hl
add a : adc hl,bc : add a : adc hl,bc : add a : adc hl,bc ; skip bonus
push hl : pop ix
jr .loopbonus
.bonusfound
push ix : pop hl : inc hl : inc hl
ld c,(ix+1)
bit 3,c : jr z,.noration    : ld a,(rations)   : add (hl) : inc hl : ld (rations),a  : .noration
bit 4,c : jr z,.chancemini  :                   ld a,(hl) : inc hl : ld (chance_minimum),a  : .chancemini
bit 5,c : jr z,.nohabilete  : ld a,(habilete)  : add (hl) : inc hl : ld (habilete),a  : .nohabilete
bit 6,c : jr z,.noendurance : ld a,(endurance) : add (hl) : inc hl : ld (endurance),a : .noendurance
bit 7,c : jr z,.bonusend    : ld a,(chance)    : add (hl) : ld (chance),a
.bonusend
ld a,(rations) : and 128 : jr z,.rationovf : xor a : ld (rations),a : .rationovf
; jamais plus que le départ
ld a,(rations) : ld c,a : ld a,10 : cp c : jr nc,.ovfrat : ld (rations),a : .ovfrat
ld a,(habilete) : ld c,a : ld a,(habilete_depart) : cp c : jr nc,.ovfhab : ld (habilete),a : .ovfhab
ld a,(endurance) : ld c,a : ld a,(endurance_depart) : cp c : jr nc,.ovfend : ld (endurance),a : .ovfend
ld a,(chance) : ld c,a : ld a,(chance_depart) : cp c : jr nc,.ovfcha : ld (chance),a : .ovfcha
ld a,(chance_minimum) : ld c,a : ld a,(chance) : cp c : jr nc,.ovfchamin : ld a,c : ld (chance),a : .ovfchamin
pop de : push de ; on récupère le lieu
;***************
   combat_prep
;***************
ld ix,combatliste
.loopcombat
ld l,(ix+0) : ld a,(ix+1) : and 15 : ld h,a : or l : jp z,.combatend : sbc hl,de : jr z,.combatfound
ld bc,4
ld a,(ix+1) : add ix,bc : add a : jr nc,.nofuite : inc ix : inc ix : .nofuite
add a : jr nc,.nodegat : inc ix : .nodegat
add a : jr nc,.nohabilete : inc ix : .nohabilete
add a : jr nc,.noblessure : inc ix : inc ix : .noblessure
add a : jr nc,.noassautsminimum : inc ix : .noassautsminimum
ld a,(ix+0) ; nbadversaire+bits
and 7
ld b,a : .rebique inc ix
ld a,(ix+0) : and #F0 : cp #F0 : jr z,.rebique : ld a,(ix+0) : and #F : cp #F : jr z,.rebique
djnz .rebique
inc ix
jr .loopcombat
.combatfound
; dépiler les infos et renseigner le moteur de gestion de combat
;brk
ld hl,(ix+2) : ld (gestion_combat.gagnant+1),hl
ld de,4 : ld a,(ix+1) : add a : jr nc,.pasdefuite : ld hl,(ix+4) : ld (gestion_combat.fuite+1),hl : inc e : inc e : .pasdefuite
add ix,de ; skip place+gagne+fuite

; extended description decoding
ld de,0 ; degat+habilete
ld hl,0 ; gagner avec blessure
ld c,0 ; assauts
add a : jr nc,.extended_degat : ld d,(ix+0) : inc ix ; D=degat
.extended_degat
add a : jr nc,.extended_habilete : ld e,(ix+0) : inc ix ; E=habilete
.extended_habilete
add a : jr nc,.extended_gagne_avec_blessure : ld hl,(ix+0) : inc ix : inc ix
.extended_gagne_avec_blessure
add a : jr nc,.extended_assauts_minimum : ld c,(ix+0) : inc ix
.extended_assauts_minimum

; poke du moteur
ld a,e : ld (habilete_modifier),a
ld a,d : ld (bonus_degats),a
; ld (),hl ; blessure
ld a,c : ; ld (assautsminpuisfin),a

;ld (gestion_combat.habilete_modifier+1),a
;ld (gestion_combat.endurance_modifier+1),a


ld (gestion_combat.addr+2),ix ; nbadv+info
jr .combatexit
.combatend
ld hl,0 : ld (gestion_combat.addr+2),hl ; pas de combat, struct NULL
.combatexit

pop hl
push hl
;********************
      test_prep
;********************
ld ix,testliste
.looptest
ld l,(ix+0) : ld a,(ix+1) : and 15 : ld h,a : ld h,a : or l : jr z,.testend : sbc hl,de : jr z,.testfound
bit 5,(ix+1) ; est-ce que c'est un test de hasard?
jr nz,.skiphasard
ld bc,6 : add ix,bc : jr .looptest
.skiphasard
ld c,(ix+2) : ld b,0 : add ix,bc : add ix,bc : add ix,bc : ld c,2 : add ix,bc : jr .looptest ; nb x 3 + 2
;;;;;;;;;;;;;;;;;;;
.testfound
ld a,(ix+1) : inc ix : inc ix : ld (gestion_test.teststruct+2),ix
add a : jr c,.testchance
add a : jr c,.testhabilete
add a : jr c,.testhasard
.testendurance ld hl,gestion_test.endurance : jr .testenable
.testhabilete  ld hl,gestion_test.habilete  : jr .testenable
.testchance    ld hl,gestion_test.chance    : jr .testenable
.testhasard    ld hl,gestion_test.hasard

.testenable
ld (gestion_test.saut+1),hl
xor a : jr .testexit ; enable test!
.testend
ld a,#C9
.testexit
ld (gestion_test),a ; on doit arriver avec A=#00 en cas de test
pop hl
ret


;***********************************************
                 gestion_test
;***********************************************
ret ; indispensable!
.teststruct ld ix,#1234
.saut jp #1234
; mutualisation pour les tests à deux choix
.endurance ld bc,endurance : jr .maketest
.habilete ld bc,habilete : jr .maketest
.chance ld bc,chance
.maketest call get_dice : ld d,a : call get_dice : add d : ld b,a : ld a,(bc) : cp d : jr nc,.testok
.testko inc ix : inc ix
.testok ld hl,(ix+0) : jp change_place

.hasard ld b,(ix+0) : inc ix : dec b : ld a,r : add a
.testhasard cp (ix+2) : jr nc,.testok : inc ix : inc ix : inc ix : djnz .testhasard : jr .testok


combatzone defs SIZE_COMBAT_ZONE

;***********************************************
                 gestion_combat
; .gagnant+1 => lieu une fois gagné
; .fuite+1   => lieu une fois gagné
;***********************************************
; backup places
;ld a,(nblink) :ld (.backuplink+1),a : xor a: ld (nblink),a

.addr ld ix,#1234
ld iy,combatzone
ld a,(ix+0) ; struct de zone de combat
ld d,a ; bit 6 fuite | bit 5 double combat
inc ix
and 7
ld b,a
ld (iy+0),a : inc iy ; combatzone = nbadv + end + hab + ...
.unpack_adversaires
push bc
ld bc,0
.extended_carac
ld a,(ix+0) : and 15 : add b : ld b,a ; endurance
ld a,(ix+0) : rrca : rrca : rrca : rrca : and 15 : add c : ld c,a ; habilete
inc ix
ld a,(ix-1) : and 15 : cp 15 : jr z,.extended_carac
ld a,(ix-1) : and 240 : cp 240 : jr z,.extended_carac
ld (iy+0),c
ld (iy+1),b
inc iy : inc iy
pop bc
djnz .unpack_adversaires

ld a,d :and 32 : ld (.double_combat+1),a ; bit 5

.reaffiche
ld a,(chance)   : ld hl,chance_dizaine   : call base10
ld a,(habilete) : ld hl,habilete_dizaine : call base10
ld a,(endurance): ld hl,endurance_dizaine: call base10
ld a,(rations)  : ld hl,ration_dizaine   : call base10

ld hl,msg_feuille_perso : call init_message
ld hl,msg_adversaire : call concat_message

ld iy,combatzone
ld b,(iy+0) ; struct de zone de combat
inc iy
.affiche_adversaires
ld a,(iy+0) : ld hl,adversaire_habilete_dizaine : call base10
ld a,(iy+1) : ld hl,adversaire_endurance_dizaine : call base10
inc iy : inc iy
ld hl,msg_adversaire_spec : call concat_message
djnz .affiche_adversaires

ld hl,msg_choix_attaque : call concat_message
ld hl,(.addr+2)
bit 6,(hl)
jr z,.skipfuite
ld hl,msg_choix_fuir : call concat_message
.skipfuite

call razscreen
ld hl,buffer2
call writer
.waitattaque
call scankeyboard
ld a,(KEY_A_BYTE) : and KEY_A_BIT : jr nz,.attaque
ld hl,(.addr+2) : bit 6,(hl) : jp z,.waitattaque ; pas de test de fuite si on ne peut pas fuire
ld a,(KEY_F_BYTE) : and KEY_F_BIT : jp nz,.fuite
jr z,.waitattaque


.attaque
call razscreen
ld iy,combatzone

.double_combat ld a,0 : or a : jr z,.nodoublette
ld a,(iy+0) : and 6 : jr z,.nodoublette
ld a,(habilete) : ld b,a : ld a,(habilete_modifier) : add b : ld b,a : call get_dice : add b : ld b,a : call get_dice : add b : ld b,a
ld a,(iy+3) : ld c,a : call get_dice : add c : ld c,a : call get_dice : add c : ld c,a ; force d'attaque du deuxième attaquant!
ld a,b : cp c : jr nc,.nodoublette
; Le deuxième attaquant arrive à taper
; ajouter la chance? @@TODO
ld a,(endurance) : sub 2 : /* add b (chance modifie les dégats) */ : ld (endurance),a : add a : jp z,.amdead : jp c,.amdead ; negatif ou zéro

.nodoublette
ld a,(iy+0) ; struct de zone de combat
or a
jp z,.gagnant

ld a,(habilete) : ld b,a : ld a,(habilete_modifier) : add b : ld b,a : call get_dice : add b : ld b,a : call get_dice : add b : ld b,a
ld a,(iy+1) : ld c,a : call get_dice : add c : ld c,a : call get_dice : add c : ld c,a
ld a,b : cp c : jr c,.attaque_manquee : jr z,.esquive
; msg_attaque_reussie
.attaque_reussie
ld hl,msg_attaque_reussie
ld bc,#FE01
call .proposer_chance ; retour du modif dans B
ld a,(bonus_degats) : add 2 : ld c,a
ld a,(iy+2) : sub c : add b : ld (iy+2),a : dec a : bit 7,a : jp z,.reaffiche
; mort de l'adversaire
ld c,(iy+0) : dec (iy+0) : jp z,.gagnant
ld hl,combatzone+3
ld de,combatzone+1
ld b,0
ldir
jp .reaffiche

; msg_attaque_esquive
.esquive
ld hl,msg_attaque_esquive
call writer
.waitesquive
call scankeyboard
ld a,(KEY_SPACE_BYTE) : and KEY_SPACE_BIT : jr z,.waitesquive
jp .reaffiche


; msg_attaque_manque
.attaque_manquee
ld hl,msg_attaque_manque
ld bc,#01FF
call .proposer_chance
ld a,(endurance) : sub 2 : add b : ld (endurance),a : add a : jp z,.amdead : jp c,.amdead
jp .reaffiche


;******************************************
.proposer_chance
;******************************************
push bc
call init_message
ld hl,msg_choix_chance : call concat_message
ld hl,buffer2
call writer
.waitchance
call scankeyboard
ld iy,combatzone
ld a,(KEY_C_BYTE) : and KEY_C_BIT : jr nz,.calculer_chance
ld a,(KEY_SPACE_BYTE) : and KEY_SPACE_BIT : jr nz,.sanslachance
jr .waitchance
.sanslachance
pop bc
ld bc,0
ret

.calculer_chance
call get_dice : ld b,a : call get_dice : add b : ld b,a
ld hl,chance : ld a,(hl) : dec (hl) : cp b : jr z,.ouichanceux : jr c,.ouichanceux
pop bc : ld b,c : ret
.ouichanceux pop bc : ret


; fuite => 2 pts d'endurance en moins, sauf exceptions (possibilité de chance)
.fuite
ld hl,#1234 ; lieu de fuite
ld a,(endurance) : sub 2 : ld (endurance),a : add a : jp z,.amdead : jp c,.amdead
jp change_place

.gagnant ld hl,#1234
jp change_place

.amdead
call razscreen
ld hl,msg_dead
call writer
ld a,(endurance_depart) : ld (endurance),a
ld a,(habilete_depart) : ld (habilete),a
ld a,(chance_depart) : ld (chance),a
.waitdead
call scankeyboard
ld a,(KEY_SPACE_BYTE) : and KEY_SPACE_BIT : jr z,.waitdead
jr .gagnant ; on ne perd JAMAIS!!!!

; Chance => 2D
; si inférieur ou égal => chanceux, sinon malchanceux
; toute utilisation de la chance => -1pt de chance!


; moteur de combat
; token de description
; bit 7: mode de combat étendu (bonus, tours spéciaux)
; bit 6: possibilité de fuite
; bit 5:
; bit 4:
; bit 3:
; bit 2: \
; bit 1:  = nombre de combattants
; bit 0: /
;
;
; pour chaque combattant: habilité+endurance packé sur 4 bits HHHHEEEE
; si endurance ou habileté >15 alors on écrit 15 et on ajoute un octet de description pour le combattant
;
; 
; 
;
;
;
;
/*
        printf("msg_test_reussi defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; test réussi\n"); k++;
        printf("msg_test_manque defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; test manqué\n"); k++;
        printf("msg_attaque_reussi  defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; attaque réussie\n"); k++;
        printf("msg_attaque_esquive defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; attaque esquivée\n"); k++;
        printf("msg_attaque_manque  defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; adversaire porte un coup\n"); k++;
        printf("msg_utiliser_potion defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; utiliser potion\n"); k++;
        printf("msg_utiliser_ration defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; utiliser ration\n"); k++;


        printf("msg_choix_attaque   defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; attaquer\n"); k++;
        printf("msg_choix_fuir      defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; fuir\n"); k++;
        printf("msg_choix_chance    defb "); for (i=0;key[k][i];i++) printf("%d,",key[k][i]); printf("0 ; question utiliser la chance\n"); k++;
*/

taille_fiche=$-debut_fiche
print 'gestion du personnage = ',taille_fiche
