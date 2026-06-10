.section .init
.global main

/* Stack at top of 16 KB BRAM */
lui  sp, %hi(16*1024)
addi sp, sp, %lo(16*1024)

/* Lab08d: 明確 emit 幾個 compressed instructions 來測試 cdec + cross-boundary
   handling。gcc -march=rv32imc 沒主動 emit compressed (firmware 太小)，所以這裡
   手動 force 一些 c.xxx 出現。沒副作用：c.addi x0,0 = c.nop，c.li t0,0 OK。 */
.option push
.option rvc
    c.nop                  /* 0x0001, no side effect */
    c.li   t0, 0           /* compressed li, side effect = t0=0 (caller-saved, OK) */
    c.nop
    c.nop                  /* 4 compressed = 8 bytes，注入 cross-boundary potential */
.option pop

/* Jump to main */
jal  ra, main

/* If main ever returns, halt with ebreak (core trap → LED 4'b1111).
   注意：gcc 在 -march=rv32imc 下會把 ebreak 自動壓成 c.ebreak (16-bit)。我們
   保留 32-bit 形式 + 段尾 .balign 4，確保跟在後面的 mtvec_handler 落在 4-byte
   邊界 (mtvec direct-mode base[1:0]=00 spec 要求)。 */
.option push
.option norvc
    ebreak
.option pop
.balign 4
