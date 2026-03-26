segment         .text

%define         BUF_LEN 128
%define         STACK_STEP 8
%define         REG_BITS 64
%define         QUADRO_BYTES 8

%macro          mDISPLAY_STR 2
         
                lea     rsi, [%1]
                mov     rax, 1 
                mov     rdi, 0 
                mov     rdx, %2 
                syscall
%endmacro
                

%macro          mDISPLAY_BUF 1

                mDISPLAY_STR buf, %1                
%endmacro


global          print_f
extern          printf
default rel
            
;-----------------------------------------------------------
; Descr: print_f display text according to a format string
;
; Entry: RDI - pointer to format string (null-terminated)
;
; Assum: Format string contains %b specifier for binary 
;        output
;
; Exit:  Output to stdout
;
; Destr: RAX, RBX, RCX, RSI, RDI, RDX
;-----------------------------------------------------------

print_f:        pop     rax
                mov     [saved_regs + saved.rdi], rdi
                mov     [saved_regs + saved.rsi], rsi
                mov     [saved_regs + saved.rdx], rdx
                mov     [saved_regs + saved.rcx], rcx
                mov     [saved_regs + saved.r8], r8
                mov     [saved_regs + saved.r9], r9
                mov     [saved_regs + saved.rax], rax


                call    printf wrt ..plt

                mov     rdi, [saved_regs + saved.rdi]
                mov     rsi, [saved_regs + saved.rsi]
                mov     rdx, [saved_regs + saved.rdx]
                mov     rcx, [saved_regs + saved.rcx]
                mov     r8, [saved_regs + saved.r8]
                mov     r9, [saved_regs + saved.r9]
                mov     rax, [saved_regs + saved.rax]

                push    r9 
                push    r8 
                push    rcx 
                push    rdx 
                push    rsi 
                push    rdi 
                push    rax

                push    rbp
                mov     rbp, rsp

                mov     r8, STACK_STEP*2          ; r8 - offset of arg in stack
                mov     rsi, [rbp + r8]
                add     r8, STACK_STEP

                lea     r9, [buf]                   ; r9 - buf to display text

            .read_loop:
                cmp     byte [rsi], '%'
                je      .display_spec
                cmp     byte [rsi], 0
                je      .display_n_exit

                mov     al, [rsi]
                mov     [r9], al
                inc     rsi
                inc     r9

                lea     r15, [buf_end]
                cmp     r9, r15
                jne     .read_loop

                mov     rbx, rsi
                mDISPLAY_BUF BUF_LEN
                mov     rsi, rbx
                
                lea     r9, [buf]

                jmp     .read_loop

            .display_spec:
                inc     rsi
                xor     rax, rax
                mov     al, [rsi]
                sub     al, 'b'
                mov     rbx, [rbp + r8]
                lea     r15, [jmp_table]
                jmp     [r15 + rax*8]
            .spec_end:
                inc     rsi
                add     r8, STACK_STEP
                cmp     byte [rsi], 0
                jne     .read_loop

            .display_n_exit:
                lea     r15, [buf]
                cmp     r9, r15
                je      .terminate 
                lea     r15, [buf]
                sub     r9, r15
                mDISPLAY_BUF r9

            .terminate:
                pop     rbp
                pop     rax
                add     rsp, STACK_STEP*6
                push    rax
                ret

.to_bin:        mov     rcx, 1
                call    convert_2_pow
                jmp     .spec_end

.to_char:       mov     rbx, [rbp + r8]
                mov     [r9], rbx
                inc     r9
                jmp     .spec_end

.to_dec:        lzcnt   rcx, rbx
                sub     rcx, REG_BITS
                neg     rcx
                shl     rcx, 2
                jmp     .spec_end

.to_float:

.to_oct:        mov     rcx, 3
                call    convert_2_pow
                jmp     .spec_end

.to_hex:        mov     rcx, 4
                call    convert_2_pow
                jmp     .spec_end

.to_str:        lea     r15, [buf]
                sub     r9, r15
                mov     r12, rsi
                mDISPLAY_BUF r9
                lea     r9, [buf]

                mov     rdi, rbx
                xor     al, al
                mov     rcx, -1
                repne   scasb
                not     rcx
                dec     rcx
                mDISPLAY_STR rbx, rcx
                mov     rsi, r12
                jmp     .spec_end

;-----------------------------------------------------------
; Descr: convert_2_pow converts a number to a string in a 
;        given base that is a power of 2
;
; Entry: RBX - number to convert
;        RCX - exponent for base (base = 2^RCX)
;        R9  - pointer to output buffer
;        RSI - pointer to format string (used for buffer flush)
;
; Assum:
;
; Exit:  R9  -> updated position in output buffer
;        Output buffer contains the converted number
;
; Destr: RAX, RCX, RDI, R10, R12, R13
;-----------------------------------------------------------

 convert_2_pow: mov     r13, -1
                shl     r13, cl
                not     r13

                lea     rdi, [inter_buf]
                xor     r12, r12
               
            .inter_loop:
                mov     rax, rbx
                and     rax, r13
                lea     r15, [hex_table]
                mov     al, [r15 + rax]
                shr     rbx, cl

                inc     r12
                mov     byte [rdi], al

                inc     rdi
                cmp     rbx, 0
                jne     .inter_loop
                dec     rdi
                mov     rcx, r12
            .final_loop:
                mov     r12, [rdi]
                mov     [r9], r12
                dec     rdi
                inc     r9

                lea     r15, [buf_end]
                cmp     r9, r15
                jne     .end_loop2

                mov     r10, rsi 
                mDISPLAY_BUF BUF_LEN
                mov     rsi, r10
                lea     r9, [buf]
            .end_loop2:
                loop    .final_loop
                ret

section         .data

jmp_table:      dq  print_f.to_bin    ;%b
                dq  print_f.to_char   ;%c
                dq  print_f.to_dec    ;%d 
                    times 1 dq 0
                dq  print_f.to_float  ;%f
                    times 8 dq 0
                dq  print_f.to_oct    ;%o
                    times 3 dq 0
                dq  print_f.to_str    ;%s
                    times 4 dq 0
                dq  print_f.to_hex    ;%x

inter_buf           times 8 dq 0

buf             db  BUF_LEN dup(0)
buf_end:

saved_regs:     times 7 dq 0

struc           saved

  .rdi:         resq    1 
  .rsi:         resq    1
  .rdx:         resq    1 
  .rcx:         resq    1
  .r8:          resq    1
  .r9:          resq    1
  .rax:         resq    1

endstruc

hex_table       db  "0123456789abcdf"
