segment         .text

global _start

_start:         mov  rdi, test_str
                mov  rsi, 1
                call print_f

                mov  rax, 0x3c
                xor  rdi, rdi
                syscall
            
;-----------------------------------------------------------
; Descr: print_f display text according to a format sting
;
; Entry: 
;
; Assum:
;
; Exit:
;
; Destr:
;-----------------------------------------------------------

print_f:        pop   rax
                push  r9 
                push  r8 
                push  rcx 
                push  rdx 
                push  rsi 
                push  rdi 
                push  rax

                push  rbp
                mov   rbp, rsp

                mov   r8, 16
                mov   rsi, [rbp + r8]
                add   r8, 8

                mov   rax, 1
                mov   rdi, 1
                mov   rdx, 1

            .read_loop:
                cmp   byte [rsi], '%'
                je    .display_spec
                cmp   byte [rsi], 0
                je    .end

                syscall
                inc   rsi
                jmp   .read_loop

            .display_spec:
                inc   rsi
                sub   [rsi], 'b'
                xor   rax, rax
                mov   al, [rsi]
                call  [jmp_table + rax*8]
                cmp   byte [rsi], 0
                jne   .read_loop

            .end:
                pop   rbp
                pop   rax
                add   rsp, 6*8
                push  rax
                ret

.to_binary:     mov   rbx, [rbp + r8]
                lzcnt rcx, rbx
                sub   rcx, 64
                neg   rcx
        
            .binary_loop:
                mov   rax, rbx
                and   rax, 1
                add   rax, '0'
                shr   rbx, 1

                push  rsi
                push  rax
                mov   rax, 1
                mov   rdi, 1
                mov   rsi, rsp
                mov   rdx, 1

                mov   rax, rcx
                syscall
                mov   rcx, rax
                add   rsp, 8
                pop   rsi

                loop  .binary_loop

                add   r8, 8
                inc   rsi
                
                ret
.to_char:
.to_decimal:
.to_float:


section         .data

jmp_table:
            dq print_f.to_binary ;%b
            dq print_f.to_char   ;%c
            dq print_f.to_decimal;%d 
            dq 4 dup(0)
            dq print_f.to_float  ;%f

test_str    db "gay %b", 0
