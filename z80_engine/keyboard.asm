
scankeyboard

ld bc,#F40E ; PPI register 14
out (c),c
  ld bc,#F6C0 ; we want to select a register
  out (c),c
  out (c),0   ; validation
  ld bc,#F792 ; PPI configuration input A, output C
  out (c),c
  dec b : ld c,b
ld de,#40F4 ; keyboard line 0 / e=#F4 read port

ld hl,keyboardmap
ld xl,9
.loop ld b,c : out (c),d : ld b,e : in a,(c) : cpl : ld (hl),a : inc hl : inc d : dec xl : jr nz,.loop
;
  ld bc,#F782 ; PPI output A, output C
  out (c),c
  dec b
  out (c),0
ret

keyboardmap defs 9

KEY_F0_BYTE equ keyboardmap+1 : KEY_F0_BIT equ 128
KEY_F1_BYTE equ keyboardmap+1 : KEY_F1_BIT equ 32
KEY_F2_BYTE equ keyboardmap+1 : KEY_F2_BIT equ 64
KEY_F3_BYTE equ keyboardmap+0 : KEY_F3_BIT equ 32
KEY_F4_BYTE equ keyboardmap+2 : KEY_F4_BIT equ 16
KEY_F5_BYTE equ keyboardmap+1 : KEY_F5_BIT equ 16
KEY_F6_BYTE equ keyboardmap+0 : KEY_F6_BIT equ 16
KEY_F7_BYTE equ keyboardmap+1 : KEY_F7_BIT equ 4
KEY_F8_BYTE equ keyboardmap+1 : KEY_F8_BIT equ 8
KEY_F9_BYTE equ keyboardmap+0 : KEY_F9_BIT equ 8
KEY_MA_BYTE equ keyboardmap+3 : KEY_MA_BIT equ 32
KEY_P_BYTE  equ keyboardmap+3 : KEY_P_BIT  equ 8
KEY_MQ_BYTE equ keyboardmap+4 : KEY_MQ_BIT equ 64 ; tocheck

KEY_0_BYTE equ 4+keyboardmap+0 : KEY_0_BIT equ 1
KEY_9_BYTE equ 4+keyboardmap+0 : KEY_9_BIT equ 2
KEY_8_BYTE equ 4+keyboardmap+1 : KEY_8_BIT equ 1
KEY_7_BYTE equ 4+keyboardmap+1 : KEY_7_BIT equ 2
KEY_J_BYTE equ 4+keyboardmap+1 : KEY_J_BIT equ 32
KEY_6_BYTE equ 4+keyboardmap+2 : KEY_6_BIT equ 1
KEY_5_BYTE equ 4+keyboardmap+2 : KEY_5_BIT equ 2
KEY_R_BYTE equ 4+keyboardmap+2 : KEY_R_BIT equ 4
KEY_T_BYTE equ 4+keyboardmap+2 : KEY_T_BIT equ 8
KEY_V_BYTE equ 4+keyboardmap+2 : KEY_V_BIT equ 128
KEY_B_BYTE equ 4+keyboardmap+2 : KEY_B_BIT equ 64
KEY_F_BYTE equ 4+keyboardmap+2 : KEY_F_BIT equ 32
KEY_4_BYTE equ 4+keyboardmap+3 : KEY_4_BIT equ 1
KEY_3_BYTE equ 4+keyboardmap+3 : KEY_3_BIT equ 2
KEY_D_BYTE equ 4+keyboardmap+3 : KEY_D_BIT equ 32
KEY_C_BYTE equ 4+keyboardmap+3 : KEY_C_BIT equ 64
KEY_1_BYTE equ 4+keyboardmap+4 : KEY_1_BIT equ 1
KEY_2_BYTE equ 4+keyboardmap+4 : KEY_2_BIT equ 2
KEY_A_BYTE equ 4+keyboardmap+4 : KEY_A_BIT equ 8
KEY_ESC_BYTE equ 4+keyboardmap+4 : KEY_ESC_BIT equ 4
KEY_W_BYTE equ 4+keyboardmap+4 : KEY_W_BIT equ 128
KEY_SPACE_BYTE equ 4+keyboardmap+1 : KEY_SPACE_BIT equ 128

