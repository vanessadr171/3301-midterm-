1. Answers:

Reset and Interrupt Vectors:
The reset vector is at 0x0000 and the interrupt vector is at 0x0008 because these are the addresses used by the PIC18 for reset and interrupts. The `PSECT` and `ORG` commands place them at those addresses without needing linker options.
RETFIE 1:
`retfie 1` returns from the interrupt and restores the saved WREG, STATUS, and BSR values. INT0IF is cleared before returning so the same interrupt does not immediately happen again.
Clearing INT0IF:
INT0IF is cleared before enabling the interrupt so an old interrupt flag does not immediately trigger the ISR. My code uses `bcf INTCON,1,a` before enabling INT0IE and GIE.
RAM Test Patterns:
I used `0x55` and `0xAA` because they alternate between 0s and 1s. Using both patterns helps catch faults that might not be detected by only one pattern.
FSR0 and POSTINC0:
FSR0 starts at `0x100` and `POSTINC0` writes to the current address and then increases FSR0. The test stops when `FSR0H` reaches `0x02`, which means it has finished the `0x100–0x1FF` range.
ANSEL Registers:
The ANSEL registers need banked addressing because they are outside the access-bank SFR range. My code uses `banksel` and `BANKMASK`, such as `clrf BANKMASK(ANSELA),b`, instead of using `,a`.
LED Sweep Counter:
I used a separate `led_pass` counter because the provided delay routine uses `del_a` and `del_b`. If I used those variables for the sweep counter, the delay routine would overwrite the counter and the sweep could loop incorrectly.
Interrupt Delay:
The ISR needs its own delay variables because the interrupt can happen while the main program is using `delay_100ms`. Using the same delay variables would overwrite the main program's counters and affect its timing.

2. AI Usage Acknowledgment:

AI tools were used as a supplemental resource for understanding the assignment, debugging assembly code, and checking syntax and logic. I reviewed and tested the code before submitting it.

3. Status:

M1, M3, and M4 worked during testing. M2 was not fully working because the interrupt did not produce the expected RD7 blinking and heartbeat behavior, and I was not able to fully correct it before submission.
