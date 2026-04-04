.section .text
.global _start

_start:
    # Stack pointer = top of DSRAM (0x0000_2000 + 8KB = 0x0000_4000)
    li   sp, 0x00004000

    # Write magic value to DSRAM base so we can verify the store worked
    li   t0, 0x00002000
    li   t1, 0xCAFEBABE
    sw   t1, 0(t0)

    # WFI — core asserts core_sleep_o here; testbench polls this to detect completion
loop:
    wfi
    j    loop
