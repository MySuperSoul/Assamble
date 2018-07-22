;
;本次作业实现一个16进制的查看器，PgDn显示下一页，PgUp显示上一页
;Home显示第一页，End显示最后一页
;
.386
data segment use16
	message1 db 'Please input filename:',0Ah, 0Dh, '$' ;提示输入文件名
	message2 db 'Cannot open file', 0Ah, 0Dh, '$' ;提示输入的文件名有误
	buffer db 100, ? ;设置读入文件名的大小，并记录读入的大小
	filename db 100 dup(0) ;源文件名
	buf db 256 dup(0) ;保存每页需要输出的信息
	handle dw 0
	key dw 0
	bytes_in_buf dw 0
	file_size dd 0 ;文件的总长度
	offset_my dd 0 ;偏移量
	n dd 0

	;子程序中的变量使用
	rows dw 0
	bytes_on_row dw 0
	ASCII db '0123456789ABCDEF' ;换码需要用到的参数
	s db '00000000:            |           |           |                             '
	pattern db '00000000:            |           |           |                             '
data ends

stack1 segment stack use16
	dw 128 dup(?)
stack1 ends ;堆栈段定义

code segment use16
assume cs:code, ds:data, ss:stack1
main:
	mov ax, data
	mov ds, ax
	mov dx, offset message1
	mov ah, 09h
	int 21h ;当前输出提示输入文件名的信息

	mov ah, 0Ah
	mov dx, offset buffer
	int 21h ;得到用户输入

	xor cx, cx
	mov cl, buffer[1] ;实际输入的字符数
	mov si, cx
	mov bx, offset filename
	mov byte ptr [bx + si], 0 ;将回车符置0

	mov ah, 3Dh
	mov al, 0
	mov dx, offset filename
	int 21h ;打开文件，返回句柄
    mov handle, ax ;保存下源文件的句柄

    jc exit_0 ;如果失败，跳转
    jmp next_0 ;成功继续
exit_0:
	mov dx, offset message2
	mov ah, 09h
	int 21h ;输出有错的信息

	mov ah, 0
	int 16h
	
	mov ah, 4Ch
	mov al, 0
	int 21h ;退出当前程序 

next_0:
	mov ah, 42h
	mov al, 2
	mov bx, handle
	mov cx, 0
	mov dx, 0
	int 21h
	mov word ptr file_size[2], dx
    mov word ptr file_size[0], ax ;移动文件指针，dx：ax合一起构成文件的大小

Loop_key: ;循环从键盘读入
	mov eax, dword ptr file_size
	mov ebx, dword ptr offset_my
	sub eax, ebx
	mov dword ptr n, eax ;将计算结果放到n里面去

	cmp eax, 256
	jae set_buf_256
	mov word ptr bytes_in_buf, ax ;否则将n装到字节数里面去
	jmp move ;跳转到移动文件指针的位置去

set_buf_256:
	mov word ptr bytes_in_buf, 256 ;设置为大小256
move:
	xor ax, ax ;先清空ax里面的东西
	mov ah, 42h
	mov al, 0
	mov bx, handle
	mov cx, word ptr offset_my[2]
	mov dx, word ptr offset_my[0]
	int 21h ;移动文件指针

	mov ah, 3Fh
    mov bx, handle
    mov cx, bytes_in_buf
    mov dx, data
    mov ds, dx
    mov dx, offset buf
    int 21h ;读取文件中的字节数到buf当中

    ;通过堆栈进行参数传递
    call far ptr show_this_page ;调用显示当前页的函数

    mov ah, 0
    int 16h ;键盘的输入

    mov word ptr key, ax ;将输入的按键存到key值里面去

    cmp key, 011Bh
    jz  Done ;如果是ESC键，退出关闭文件结束程序

    cmp key, 4900h ;处理的是page_up情况
    jnz page_down ;如果不相等，跳转到下一页进行判断
    mov ax, word ptr offset_my
    sub ax, 256
    mov word ptr offset_my, ax

    cmp ax, 0
    jge Loop_key
    mov word ptr offset_my, 0
    jmp Loop_key ;判断完之后，进入下一次循环读入

page_down: ;处理的是下一页的情况
	cmp key, 5100h
	jnz Home
	xor eax, eax
	mov eax, dword ptr offset_my
	add eax, 256
	mov ebx, dword ptr file_size
	cmp eax, ebx ;offset_my + 256 < file_size
	jae Loop_key
	mov dword ptr offset_my, eax
	jmp Loop_key

Home: ;处理的是按下了home键
	cmp key, 4700h
	jnz End_key ;否则进到end键判断里面去
	mov dword ptr offset_my, 0
	jmp Loop_key

End_key:
	cmp key, 4F00h
	jnz Loop_key
	mov eax, dword ptr file_size
	and eax, 0FFFFFF00h
	mov dword ptr offset_my, eax ;计算offset
	mov eax, dword ptr file_size
	mov ebx, dword ptr offset_my ;用来进行相对应的比较

	cmp eax, ebx
	jne Loop_key
	sub eax, 256
	mov dword ptr offset_my, eax ;如果不相等的话，offset - 256
	jmp Loop_key

Done: ;完成所有操作，按下esc键响应
	mov ah, 3Eh
	mov bx, handle
	int 21h ;关闭文件

	mov ah, 4Ch
	mov al, 0
	int 21h ;退出当前程序
code ends

; 这个代码段主要是实现一些函数，通过堆栈传递参数
code1 segment use16
assume cs: code1

; 清屏的函数
clear_this_page proc far
	push eax
	push ebx
	push ecx
	push edx
	push di
	push es    ;保护我们所要用到的寄存器

	mov ax, 0B800h
	mov es, ax ;显存地址
	xor ah, ah
	mov al, 3
	int 10h  ;调用清屏函数

	pop es
	pop di
	pop edx
	pop ecx
	pop ebx
	pop eax ;将寄存器的值进行还原
	retf
clear_this_page endp ;结束当前的子程序

show_this_page proc far
	push bp
	mov bp, sp ;使用bp进行访问堆栈段的数据
	push eax
	push ebx
	push ecx
	push edx
	push di   ;保护当前的现场

	call clear_this_page ;先进行清屏操作
	mov ax, word ptr bytes_in_buf ;得到当前页字节数到bx寄存器里面
	add ax, 15 ;寄存器值加15,放在dx:ax里面
	xor dx, dx ;寄存器清0，方便进行除法
	mov bx, 16
	div bx  ;当前的行数保存在ax寄存器里面,即ax = rows
	xor ah, ah ;清除余数的影响
	mov word ptr rows, ax ;放到rows变量里面去

	mov cx, 0; cx来当做i使用
show_row: ;循环的步骤在这里实现
	mov ax, word ptr rows ;从rows里面再读出来，并自减1
	sub ax, 1
	cmp cx, ax ;比较
	jne move_row_16
	mov ax, cx ;将i放在al里面
	mov dl, 16
	mul dl ; i*16放在ax里面
	mov dx, word ptr bytes_in_buf
	sub dx, ax ;得到的结果放在dx里面
	mov word ptr bytes_on_row, dx ;送到变量bytes_on_row里
	jmp processon
move_row_16:
	mov word ptr bytes_on_row, 16

;调用show_this_row函数了
processon:
	push cx ;将参数i压入堆栈
	xor eax, eax
	mov al, 16
	mul cl ; i * 16 保存在ax里面
	mov ebx, dword ptr offset_my ;offset装到ebx里面
	add ebx, eax ;offset + i * 16
	push ebx ;第二个参数压入堆栈里面
	lea bx, buf ;buf数组的偏移地址加载进bx里面
	add bx, ax ;ax这个时候是没有改变的
	push bx ;传入第三个参数
	push word ptr bytes_on_row ;传入第四个参数
	call far ptr show_this_row ;调用对应的子函数
	pop bx
	pop bx
	pop ebx
	pop cx ;全部弹出来

	inc cx ;cx加1
	cmp cx, word ptr rows
	jb show_row ;循环rows次

	pop di
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop bp  ;还原当前的现场
	retf ;将参数全部释放掉
show_this_page endp

show_this_row proc far
	push bp
	mov bp, sp ;通过bp访问堆栈段数据
	push eax
	push ebx
	push ecx
	push edx
	push si
	push di   ;保护当前的现场

	
	mov si, 0
	mov di, 0
	mov cx, 75
strcpy:
	lea bx, pattern
	mov al, byte ptr [bx + si]
	lea bx, s
	mov byte ptr [bx + di], al
	inc si
	inc di
	loop strcpy
	
	mov eax, dword ptr [bp + 10]
	push eax
	call far ptr long2hex ;转32位偏移地址
	pop eax ;取出堆栈

	mov cx, 0
Loop_char: ;循环打印16进制
	mov bx, word ptr [bp + 8] ;得到段地址
	mov di, cx ;再偏移
	xor ax, ax ;先清零
	mov al, byte ptr [bx + di]
	push ax ;注意的是只有低位是有效的
	mov al, 3
	mul cl ;结果在ax里面
	lea bx, s
	add ax, bx
	add ax, 10 ;得到s里面的位置
	push ax
	call far ptr char2hex
	pop ax
	pop ax  ;参数还原

	inc cx
	cmp cx, word ptr [bp + 6]
	jb Loop_char ; 循环

	mov cx, 0
Loop_load:
	mov di, cx
	mov bx, word ptr [bp + 8] ;buf偏移地址
	mov al, byte ptr [bx + di] ;buf[i]
	lea bx, s
	add di, 59 ;di = i + 59
	mov byte ptr [bx + di], al

	inc cx
	cmp cx, word ptr [bp + 6]
	jb Loop_load

	mov ax, 0B800h
	mov es, ax ;显存的段地址
	xor di, di ;清0，准备输出
	mov cx, word ptr [bp + 14] ;获取当前的行号
	mov al, 160
	mul cl ;结果在ax里面
	mov di, ax ;对应到当前应该输出的位置了

	mov cx, 0
	lea bx, s
output:
	mov si, cx
	xor ax, ax
	mov al, byte ptr [bx + si] ;s[i]装到al里面
	cmp cx, 59
	jnb set_vp
	cmp al, '|'
	jne set_vp
	mov ah, 0Fh
	jmp show_now
set_vp:
	mov ah, 07h
show_now: ;显存中进行输出
	mov word ptr es:[di], ax ;显存输出
	add di, 2 ;di偏移加2
	inc cx
	cmp cx, 75
	jb output

	pop di
	pop si
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop bp  ;还原当前的现场
	retf
show_this_row endp

char2hex proc far
	push bp
	mov bp, sp ;通过bp访问堆栈段数据
	push eax
	push ebx
	push ecx
	push edx
	push si
	push di   ;保护当前的现场

	mov bx, word ptr [bp + 6] ;得到当前的地址
	xor di, di
	mov ax, word ptr [bp + 8] ;得到char xx
	mov cl, 4
	mov di, ax
	shr di, cl
	and di, 000Fh
	mov cl, byte ptr ASCII[di] ;高四位
	mov byte ptr [bx], cl ;放到s[0]

	and ax, 000Fh ;得到低4位
	mov di, ax
	mov cl, byte ptr ASCII[di]
	mov di, 1
	mov byte ptr [bx + di], cl ;放到s[1]

	pop di
	pop si
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop bp  ;还原当前的现场
retf
char2hex endp

long2hex proc far
	push bp
	mov bp, sp ;通过bp访问堆栈段数据
	push eax
	push ebx
	push ecx
	push edx
	push si
	push di   ;保护当前的现场

	mov edx, dword ptr [bp + 6] ;得到offset
	mov cx, 0
Trans:
	rol edx, 8 ;循环左移8位
	mov ebx, edx
	and ebx, 000000FFh
	push bx ;将第一个参数压入堆栈
	lea bx, s
	mov ax, 2
	mul cl ;得到i * 2
	add bx, ax ;得到需要传入的地址
	push bx ;第二个参数入堆栈
	call char2hex
	pop bx
	pop bx ;参数取出来

	inc cx
	cmp cx, 4
	jb Trans

	pop di
	pop si
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop bp  ;还原当前的现场
retf
long2hex endp
code1 ends

end main ;主程序结束