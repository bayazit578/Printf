segment         .text

%define         BUF_LEN 128
%define         STACK_STEP 8
%define         REG_BITS 64
%define         QUADRO_BYTES 8

%macro          display_str 0

                mov     rax, 1
                mov     rdi, 0 
                mov     rdx, 1 
                syscall
%endmacro

%macro          mDISPLAY_BUF 1

                mov     rsi, buf 
                mov     rax, 1 
                mov     rdi, 0 
                mov     rdx, %1
                syscall
%endmacro

global print_f

; global _start
;
; _start:         lea     rdi, test_str
;                 mov     rsi, 0b00001101
;                 mov     rdx, 'c'
;                 mov     rcx, 0x148
;                 mov     r8, 0x8
;                 call    print_f
;
;                 mov     rax, 0x3c
;                 xor     rdi, rdi
;                 syscall
            
;-----------------------------------------------------------
; Descr: print_f display text according to a format string
;
; Entry: RDI - pointer to format string (null-terminated)
;        RSI - number of arguments (unused)
;
; Assum: Arguments are passed on stack after return address
;        Format string contains %b specifier for binary output
;
; Exit:  None (output to stdout)
;
; Destr: RAX, RBX, RCX, RSI, RDI, RDX
;-----------------------------------------------------------

print_f:        pop     rax
                push    r9 
                push    r8 
                push    rcx 
                push    rdx 
                push    rsi 
                push    rdi 
                push    rax

                push    rbp
                mov     rbp, rsp

                mov     r8, STACK_STEP*2                   ; r8 - offset of arg in stack
                mov     rsi, [rbp + r8]
                add     r8, STACK_STEP

                mov     r9, buf                   ; r9 - buf to display text

            .read_loop:
                cmp     byte [rsi], '%'
                je      .display_spec
                cmp     byte [rsi], 0
                je      .display_n_exit

                mov     al, [rsi]
                mov     [r9], al
                inc     rsi
                inc     r9

                cmp     r9, buf_end
                jne     .read_loop

                mov     rbx, rsi
                mDISPLAY_BUF BUF_LEN
                mov     rsi, rbx
                
                mov     r9, buf

                jmp     .read_loop

            .display_spec:
                inc     rsi
                xor     rax, rax
                mov     al, [rsi]
                sub     al, 'b'
                mov     rbx, [rbp + r8]
                call    [jmp_table + rax*8]
                add     r8, STACK_STEP
                cmp     byte [rsi], 0
                jne     .read_loop

            .display_n_exit:
                cmp     r9, buf
                je      .terminate 
                sub     r9, buf
                mDISPLAY_BUF r9

            .terminate:
                pop     rbp
                pop     rax
                add     rsp, STACK_STEP*6
                push    rax
                ret

.to_bin:        lzcnt   rcx, rbx
                sub     rcx, REG_BITS
                neg     rcx
                dec     cl
                ror     rbx, cl
                inc     cl

            .bin_loop:
                mov     rax, rbx
                and     rax, 1
                add     rax, '0'
                rol     rbx, 1

                mov     [r9], rax 
                inc     r9

                cmp     r9, buf_end
                jne     .end_loop1

                mov     r10, rsi 
                mDISPLAY_BUF BUF_LEN
                mov     rsi, r10
                mov     r9, buf
            .end_loop1:
                loop    .bin_loop

                inc     rsi
                ret

.to_char:       mov     rbx, [rbp + r8]
                mov     [r9], rbx
                inc     r9
                inc     rsi
                ret

.to_dec:        lzcnt   rcx, rbx
                sub     rcx, REG_BITS
                neg     rcx
                shl     rcx, 2
                ret

.to_float:

.to_oct:        mov     cl, 3
                mov     rdi, inter_buf
                xor     r12, r12
               
            .inter_loop:
                mov     rax, rbx
                and     rax, 0x7
                add     rax, '0'
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

                cmp     r9, buf_end
                jne     .end_loop2
                
                mov     r10, rsi 
                mDISPLAY_BUF BUF_LEN
                mov     rsi, r10
                mov     r9, buf
            .end_loop2:
                loop    .final_loop
                
                inc     rsi
                ret

.to_hex:        lzcnt   rcx, rbx
                sub     rcx, REG_BITS
                neg     rcx
                dec     cl
                ror     rbx, cl
                inc     cl
                shr     rcx, 2
                inc     rcx

            .hex_loop:
                mov     rax, rbx
                and     rax, 0xf
                mov     al, [hex_table + rax]
                rol     rbx, 4

                mov     [r9], rax 
                inc     r9

                cmp     r9, buf_end
                jne     .end_loop3
                
                mov     r10, rsi 
                mDISPLAY_BUF BUF_LEN
                mov     rsi, r10
                mov     r9, buf

            .end_loop3:                
                loop    .hex_loop       
                
                inc     rsi
                ret

.to_str:

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

hex_table       db  "0123456789abcdf"

test_str        db  "gay %b%c %x %o", 0
