.model small
.stack 256h
.data
    ; field db 4000 dup(0)
.code

drawField proc 
jmp @startDrawField

@printFrame:
    mov ax, 0FF20h ; 20 space 10 color
    jmp @print

@startDrawField: 
    ;init data segments
    mov ax, 0b800h ;vdieo ram
    mov es, ax ; es -> 0b800h
    mov di, 0   ;es[di]
    
    mov cx, 25  ;rows
    @row:
        mov bx, 32 ;columns
        @col:
            ;bottom frame
            cmp cx, 1
            je @printFrame

            ;top frame
            cmp cx, 25
            je @printFrame

            ;left frame
            cmp bx, 32
            je @printFrame

            ;right frame
            cmp bx, 1
            je @printFrame
        
            mov ax, 1020h ; 20 space 10 color
            @print:
                stosw ; ax -> es[di]
        
            dec bx
            jnz @col


        mov ax, 0020h ; 20 space 10 color
        mov bx, 48
        @empty:
            stosw ; ax -> es[di]
            dec bx
            jnz @empty

    loop @row
    
ret
drawField endp

exit proc
    mov ah, 4ch
    int 21h
    ret
exit endp

main: 
    mov ax, @data
    mov ds, ax

    call drawField
    call exit
end main