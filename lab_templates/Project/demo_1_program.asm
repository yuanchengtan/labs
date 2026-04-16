.section 
.text
.globl _start
.globl main

# Demo 1: interactive MMIO demo for the teaching RISC-V CPU in this repo.
#
# Peripherals:
#   0x2400 -> LED output
#   0x2404 -> switch input
#   0x2408 -> button input [4]=C [3]=U [2]=L [1]=R [0]=D
#   0x2418 -> seven-segment packed hex output
#
# Seven-segment format: 0xMMBBLLLL
#   MM = current mode
#   BB = raw button bits
#   LLLL = LED word currently being driven
#
# Modes:
#   00 : no button, LEDs mirror switches
#   01 : D button, chaser only
#   02 : R button, switches OR chaser
#   03 : L button, switches XOR chaser
#   04 : U button, inverted switches
#   05 : C button, switches with a moving hole
#
# Priority when multiple buttons are pressed:
#   C > U > L > R > D

_start:
main:
    auipc x1, 20
    lui   x1, 0x2          # x1 = 0x00002000
    addi  x1, x1, 0x400    # x1 = LED_ADDRESS 0x2400
    addi  x2, x1, 0x004    # x2 = SW_ADDRESS  0x2404
    addi  x3, x1, 0x008    # x3 = BTN_ADDRESS 0x2408
    addi  x4, x1, 0x018    # x4 = SS_ADDRESS  0x2418

    addi  x5, x0, 1        # x5 = chaser bit
    lui   x6, 0x10         # x6 = 0x00010000 wrap threshold
    lui   x16, 0x10
    addi  x16, x16, -1     # x16 = 0x0000ffff LED mask

demo_loop:
    lw    x7, 0(x2)        # x7 = switches
    lw    x8, 0(x3)        # x8 = buttons

    addi  x10, x7, 0       # default LED word = switches
    addi  x11, x0, 0       # default mode = 0

    andi  x12, x8, 16      # center button
    bne   x12, x0, mode_center

    andi  x12, x8, 8       # up button
    bne   x12, x0, mode_up

    andi  x12, x8, 4       # left button
    bne   x12, x0, mode_left

    andi  x12, x8, 2       # right button
    bne   x12, x0, mode_right

    andi  x12, x8, 1       # down button
    bne   x12, x0, mode_down

after_mode_select:
    and   x10, x10, x16    # keep LED result in the low 16 bits
    sw    x10, 0(x1)
    slli  x13, x11, 24     # mode byte
    slli  x14, x8, 16      # button byte
    add   x15, x13, x14
    add   x15, x15, x10
    sw    x15, 0(x4)

    lui   x12, 0x20        # visible delay between updates

delay_loop:
    addi  x12, x12, -1
    bne   x12, x0, delay_loop
    slli  x5, x5, 1
    bne   x5, x6, keep_chaser
    addi  x5, x0, 1

keep_chaser:
    jal   x0, demo_loop

mode_down:
    addi  x10, x5, 0       # chaser only
    addi  x11, x0, 1
    jal   x0, after_mode_select

mode_right:
    or    x10, x7, x5      # switches OR chaser
    addi  x11, x0, 2
    jal   x0, after_mode_select

mode_left:
    xor   x10, x7, x5      # switches XOR chaser
    addi  x11, x0, 3
    jal   x0, after_mode_select

mode_up:
    xori  x10, x7, -1      # inverted switches
    addi  x11, x0, 4
    jal   x0, after_mode_select

mode_center:
    xori  x13, x5, -1      # invert the chaser bit to create a moving hole
    and   x10, x7, x13
    addi  x11, x0, 5
    jal   x0, after_mode_select

