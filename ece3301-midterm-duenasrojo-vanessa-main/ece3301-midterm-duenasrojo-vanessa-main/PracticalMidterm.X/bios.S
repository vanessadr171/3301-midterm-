; =====================================================================
; File:   bios.S
; Author: <your names here>
;
; ECE 3301L Practical Midterm - "Write Your Own BIOS": Reset, Vectors, and POST
; ECE 3301L - Introduction to Microcontrollers Laboratory
;
; Pure-assembly boot firmware for the PIC18F46K22. You are the BIOS
; author: reset vector -> POST -> vector setup -> boot handoff.
;
; Pin Assignments:
;   RD0-RD7 - POST / status LEDs (RD7 doubles as ISR-toggle LED)
;   RA4     - heartbeat / SOS LED
;   RB0     - INT0 external button (active-low, 10k pull-up)
;   RE0     - RAM-test fault jumper (10k pull-up to 3.3V): ground it
;             to force POST failure. Without the pull-up the pin
;             floats and the boot decision is a coin flip.
;
; Build (pic-as driver - this is what CI runs; NO linker options
; are needed: the vector psects are absolute, ORG'd in the source):
;   pic-as -mcpu=18F46K22 -o firmware.hex bios.S
;
; PROVIDED: config bits, delay routines, SOS trap, app_blink.
; YOU WRITE: boot init, RAM test, LED sweep, ISR body, vector setup.
; =====================================================================

#include <xc.inc>

; ---------------- Configuration bits (PROVIDED - do not change) -----
CONFIG FOSC=INTIO67, PLLCFG=OFF, PRICLKEN=ON, FCMEN=OFF, IESO=OFF
CONFIG PWRTEN=ON, BOREN=SBORDIS, BORV=250
CONFIG WDTEN=OFF, WDTPS=32768
CONFIG CCP2MX=PORTC1, PBADEN=OFF, CCP3MX=PORTB5, HFOFST=ON
CONFIG T3CMX=PORTC0, P2BMX=PORTD2, MCLRE=EXTMCLR
CONFIG STVREN=ON, LVP=ON, XINST=OFF
CONFIG CP0=OFF, CP1=OFF, CP2=OFF, CP3=OFF, CPB=OFF, CPD=OFF
CONFIG WRT0=OFF, WRT1=OFF, WRT2=OFF, WRT3=OFF, WRTC=OFF, WRTB=OFF, WRTD=OFF
CONFIG EBTR0=OFF, EBTR1=OFF, EBTR2=OFF, EBTR3=OFF, EBTRB=OFF

; ---------------- BIOS variables (access bank) ----------------
PSECT udata_acs
del_a:      DS 1        ; delay loop counters (used by PROVIDED delays)
del_b:      DS 1
del_c:      DS 1
sos_i:      DS 1        ; SOS pattern index
led_pass:   DS 1	;LED sweep passcounter
int_del_a: DS 1 ;interupt delay counter 
int_del_b: DS 1 ;NESTED DELAY COUNTER
int_toggle_count: DS 1 ;count the 20 led toggles

; =====================================================================
; RESET VECTOR - the very first instruction the CPU executes.
; An ABSOLUTE psect: the ORG below pins it to address 0x0000 in
; the source itself - no linker options, no IDE settings.
; =====================================================================
PSECT resetVec,abs,ovrld,class=CODE,reloc=2
    ORG     0x0000
resetVec:
    goto    boot

; =====================================================================
; HIGH-PRIORITY INTERRUPT VECTOR - absolute psect ORG'd to 0x0008.
; "Installing an interrupt vector" = putting code at this address.
; =====================================================================
PSECT intVec,abs,ovrld,class=CODE,reloc=2
    ORG     0x0008
intVec:
    btfss INTCON,1,a ;skips next instruction if INT0IF is set
    retfie  1
    movlw 20 ;set the number of led toggles to 20
    movwf int_toggle_count,a ;saves the toggle count
int_blink:
    btg LATD,7,a ;toggle LED connected to RD7
    call int_delay ;wait using seperate interruptcounters
    decfsz int_toggle_count,f,a ;decrease toggle count skipo if 0
    bra int_blink ; repeat until all 20 toggles are complete
    bcf INTCON,1,a ;clear INT0IF after the blinking finishes
    retfie 1
int_delay:
    movlw 2 ;set outer delay loop count
    movwf int_del_a,a ;store the outer loop count
int_delay_outer:
    clrf int_del_b,a ;initialize middle loop counter
int_delay_mid:
    clrf WREG,a ;initialize innerloop counter
int_delay_inner:
    decfsz WREG,w,a ;decrease WREG skip if 0
    bra int_delay_inner ;repeat the inner loop
    decfsz int_del_b,f,a ;decrease mid counter
    bra int_delay_mid ;repeat middle loop
    decfsz int_del_a,f,a ;dec outer counter
    bra int_delay_outer ;repeat the outer loop
    return

; =====================================================================
; BOOT
; =====================================================================
PSECT code
boot:
;configrue the internal oscillator for 16MHz                         ; TODO: Clock - the chip wakes up at 1 MHz. Set OSCCON for
movlw 0x72     ;load the oscillator config value onto w              ;       16 MHz HFINTOSC: IRCF=111, SCS=10 (one movlw/movwf pair;
movwf OSCCON,a ;write th evalue to the oscillator control register   ;       work out the byte value from the OSCCON register map).

banksel ANSELA ;selects the bank containing the register    ; TODO: I/O so POST can report:
clrf BANKMASK(ANSELA),b ;clears that register so its pins are configured for digital I/O   ;       - all ANSELx digital (ANSELA/B/D/E = 0)
banksel ANSELB     ;         !! TRAP: the ANSELx registers live at 0xF38-0xF3C, which
clrf BANKMASK(ANSELB),b    ;         is BELOW the access-bank SFR window (0xF60+). Clearing
banksel ANSELD    ;         them with ",a" assembles without warning but silently
clrf BANKMASK(ANSELD),b    ;         writes ordinary RAM - the pins stay analog and analog
banksel ANSELE     ;         pins always READ AS 0. Use banked access instead:
clrf BANKMASK(ANSELE),b    ;             banksel ANSELA
movlb 0 ;restores bank 0 after the banked accesses   ;         inside the access bank - ",a" is fine for those)
    ;             clrf    BANKMASK(ANSELA),b
clrf TRISD,a ;make RD0-7 outputs    ;             ...
clrf LATD,a ; turn all PORTD LEDs off    ;             movlb   0
bcf TRISA,4,a ;make RA4 an output    ;       - PORTD all outputs, LEDs off (TRIS/LAT are at 0xF80+,
bcf LATA,4,a ;start RA4 low    ;       - RA4 output, off
bsf TRISB,0,a ;make RB0 an input    ;       - RB0 input (INT0 button), RE0 input (fault jumper)
bsf TRISE,0,a ;make RE0 an input
; ---------------------------------------------------------------------
; POST STAGE 1 - RAM test.
; Walk 0x55 then 0xAA through GPR bank 1 (0x100-0x1FF) using FSR0.
; If the RE0 jumper reads LOW, simulate a fault -> goto sos_trap.
; ---------------------------------------------------------------------
post_ram:
    btfss PORTE,0,a ;skip next instruction if RE0 is high    ; TODO: if RE0 is low, goto sos_trap (simulated RAM fault)
    goto sos_trap ;if RE0 is low, report simulated RAM failure
    ; TODO: pattern test with W=0x55 then W=0xAA - either inline or
    lfsr 0,0x100 ;load FSR0 with the starting ram address, 0x100   ;       via a subroutine:
ram_check:
    movlw 0x02 ;load 0x02 into w to check the high byte of FSR0
    cpfseq FSR0H,a ;skip the next instruction if FSR0H = 0X02
    bra ram_write ;If FSR0H is not 0x02, branch to write the next byte
    bra ram_verify ;if FSR0H is 0x02, branch to verify the ram contents
ram_write:
    movlw 0x55 ;load the RAM test pattern 0x55 into w    ;         fill:   lfsr 0,0x100; write pattern via POSTINC0 until
    movwf POSTINC0,a ;write 0x55 to the RAM address pointed to by FSRok0, then incremnt FSR0    ;                 FSR0H reaches 0x02
    bra ram_check;         verify: lfsr 0,0x100; cpfseq POSTINC0 against the
ram_verify:
    lfsr 0,0x100 ;reset FSR0 to the starting RAM address for verification
ram_verify_loop:
    movlw 0x55 ;load the expected RAM test pattern into w
    cpfseq POSTINC0,a ;compare the RAM byte with 0x55 and increment FSR0
    goto sos_trap ;jumps to the sos error handeler if the ram byte does not match
    movlw 0x02 ;load the end of range value into w
    cpfseq FSR0H,a ;skip the next instruction if FSR0H = 0x02
    bra ram_verify_loop ;continues verifying RAM while FSR0H is not 0x02
    bra ram_write_aa
ram_write_aa:
    lfsr 0,0x100 ;reset FSR0 to the starting RAM address for verification
ram_write_aa_loop:
    movlw 0x02 ;load 0x02 onto w to check the end of RAM
    cpfseq FSR0H,a ;skip next instruction if FSR0H = 0X02
    bra ram_write_aa_byte ;write the next ram byte if FSR0H is not 0x02
    bra ram_verify_aa ;verify the 0xAA pattern if FSR0H = 0x02
ram_write_aa_byte:
    movlw 0xAA ;load the test pattern 0xAA into w
    movwf POSTINC0,a ;write 0xAA to RAM and increment FSR0
    bra ram_write_aa_loop ;return to check the next address
ram_verify_aa:
    lfsr 0,0x100 ;reset FSR0 to the starting RAM address for verification
ram_verify_aa_loop:
    movlw 0xAA ;load the test pattern 0xAA into w
    cpfseq POSTINC0,a ;compare RAM with 0xAA, then increment FSR0
    goto sos_trap ;jumps to the sos error handeler if the ram byte does not match
    movlw 0x02 ;load the end of range value into w
    cpfseq FSR0H,a;skip the next instructions if FSR0H=0x02
    bra ram_verify_aa_loop ;continues verifying RAM while FSR0H is not 0x02
    bra     post_leds

; ---------------------------------------------------------------------
; POST STAGE 2 - LED sweep + button sanity check.
; ---------------------------------------------------------------------
post_leds:
    clrf LATD,a ;turn off all LEDs first
    movlw 0x01 ;start with RD0 lit
    movwf LATD,a 
    movlw 0x02 ;we need 2 complete passes
    movwf led_pass,a
led_sweep:
    call delay_100ms ;keeps each LED lit for approx 100ms
    bcf STATUS,0,a ;clear carry before shifting
    rlcf LATD,f,a ; shifts the lit :ED toward the next pin
    btfss STATUS,0,a ;skips next instruction if carry is set
    bra led_sweep ;continues while the LED has not passed RD7
    decfsz led_pass,f,a ;decrease the remaining pass count
    bra led_restart ;if one pass remains restart at RD0
    bra check_rb0 ;when noth passes finish check the button
led_restart:
    movlw 0x01 ;set the LED pattern back to RD0
    movwf LATD,a 
    bra led_sweep ;start the next passok
check_rb0:
    btfss PORTB,0,a ;skip the next instruction if RB0 is high
    goto sos_trap ;if RB0 is low report an error

    
; ---------------------------------------------------------------------
; VECTOR SETUP - make the installed INT0 handler live.
; ---------------------------------------------------------------------
install_vectors:
    bcf INTCON,1,a ;clear the INT0 interupt flag
    bsf INTCON,4,a ;enable the INT0 external interupt
    bcf INTCON2,6,a ;trigger INT0 on a falling edge
    bsf INTCON,7,a ;enable global interupts

; ---------------------------------------------------------------------
; BOOT HANDOFF - the BIOS's last act.
; ---------------------------------------------------------------------
    goto    app_blink

; =====================================================================
; SOS TRAP (PROVIDED) - POST failure. Blinks ...---... forever.
; =====================================================================
sos_trap:
    clrf    LATD,a
sos_loop:
    movlw   3
    movwf   sos_i,a
sos_dots1:
    call    blink_short
    decfsz  sos_i,f,a
    bra     sos_dots1
    movlw   3
    movwf   sos_i,a
sos_dashes:
    call    blink_long
    decfsz  sos_i,f,a
    bra     sos_dashes
    movlw   3
    movwf   sos_i,a
sos_dots2:
    call    blink_short
    decfsz  sos_i,f,a
    bra     sos_dots2
    movlw   20                  ; 2 s dark between SOS letters
    movwf   del_c,a
sos_gap:
    call    delay_100ms
    decfsz  del_c,f,a
    bra     sos_gap
    bra     sos_loop

blink_short:                    ; DOT: quick 50 ms flick, 150 ms off
    bsf     LATA,4,a
    call    delay_50ms
    bcf     LATA,4,a
    call    delay_100ms
    call    delay_50ms
    return

blink_long:                     ; DASH: a full 1 s on, 300 ms off -
    bsf     LATA,4,a            ; deliberately nothing like the 1 Hz
    movlw   10                  ; heartbeat
    movwf   del_c,a
bl_on:
    call    delay_100ms
    decfsz  del_c,f,a
    bra     bl_on
    bcf     LATA,4,a
    call    delay_100ms
    call    delay_100ms
    call    delay_100ms
    return

; =====================================================================
; "USER APPLICATION" (PROVIDED) - what your BIOS boots into.
; =====================================================================
app_blink:
    btg     LATA,4,a
    movlw   5
    movwf   del_c,a
app_wait:
    call    delay_100ms
    decfsz  del_c,f,a
    bra     app_wait
    bra     app_blink

; =====================================================================
; Delays (PROVIDED) - software loops at 16 MHz.
; =====================================================================
delay_100ms:
    movlw   2
    movwf   del_a,a
d100_outer:
    clrf    del_b,a
d100_mid:
    clrf    WREG,a
d100_inner:
    decfsz  WREG,w,a
    bra     d100_inner
    decfsz  del_b,f,a
    bra     d100_mid
    decfsz  del_a,f,a
    bra     d100_outer
    return

delay_50ms:
    movlw   1
    movwf   del_a,a
    bra     d100_outer

    END
