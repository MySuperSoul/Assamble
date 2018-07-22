	.386
data4 segment use16
	buffer db 25
		   db ?
		   db 25 dup(?)
	sequence db '************$' ;输出计算式
data4 ends

stack1 segment stack use16      ;堆栈段
	dw 128 dup(0)
stack1 ends

code segment use16
	assume cs:code, ds:data4, ss:stack1
	start: mov ax, data4																																																																       																																
		   mov ds, ax																																													  																									
		   lea di, sequence  ;装入计算式偏移地址
		   call Tr_num		 ;输入的子程序调用	

		   push ax			 ;第一个数放入堆栈保护
		   inc di			 ;跳过中间的一个*
		   mov ah, 2
		   mov dl, 0Dh
		   int 21h
		   mov ah, 2
		   mov dl, 0Ah
		   int 21h			 ;回车换行

		   call Tr_num		 ;进行第二个数的处理
		   push ax			 ;保护第二个数
		   mov ah, 2
		   mov dl, 0Dh
		   int 21h
		   mov ah, 2
		   mov dl, 0Ah
		   int 21h			 ;回车换行

		   mov word ptr [di], '$=' ;结束标志和等于号，注意是小端规则
		   lea dx, sequence
		   mov ah, 09h
		   int 21h 			 ;输出当前的计算式
		   mov ah, 2
		   mov dl, 0Dh
		   int 21h
		   mov ah, 2
		   mov dl, 0Ah
		   int 21h			 ;回车换行

		   xor eax, eax
		   xor ebx, ebx
		   xor ecx, ecx
		   xor edx, edx      ;32位寄存器全部清空

		   pop ax
		   pop bx			 ;第二个数在ax里面，第一个数在bx里面
		   mul ebx					;结果此时存储在eax里面，可以存放的下
		push eax				;此时的计算结果后面可能会有用
		mov cx, 0
next_pos:																																						
		xor edx, edx			;清0，方便做除法
		mov ebx, 10
		div ebx
		cmp eax, 0
		je  Done_10
		add dl, '0'
		push dx
		add cx, 1
		jmp next_pos
Done_10:
		add dl, '0'
		push dx				;最后一位放进表达式即可
		add cx, 1
Out_num:
		pop dx
		mov ah, 2
		int 21h
		loop Out_num				;循环打印出来
		mov ah, 2
		mov dl, 0Dh
		int 21h
		mov ah, 2
		mov dl, 0Ah
		int 21h			 ;回车换行
		pop eax			 ;把eax里数据取回来

		push eax
		mov  cx, 8		 ;由于是输出的八位16进制数，所以cx置8
Nextpos:
		xor edx, edx
		mov ebx, 16
		div ebx
		cmp dl, 10		 ;16进制，所以是除16 
		jb low_case
		sub dl, 10
		add dl, 'A'
		jmp process
low_case:
		add dl, '0'		 ;数字到ASCII转换
process:
		push dx
		loop Nextpos

		mov cx, 8
Out_16:
		pop dx
		mov ah, 2
		int 21h
		loop Out_16		 ;循环将栈中的字符输出
		mov ah, 2
		mov dl, 'h'
		int 21h
		mov ah, 2
		mov dl, 0Dh
		int 21h
		mov ah, 2
		mov dl, 0Ah
		int 21h			 ;回车换行
		pop eax
		call putbinary	 ;转换成2进制的输出
done:
		mov ah, 0
		int 16h
		mov ah, 4Ch
		int 21h			 ;所有完成，程序结束

Tr_num proc near
		mov dx, offset buffer   ;装入buffer的偏移地址
		mov ah, 0Ah        
		int 21h					;输入一个字符串类型，默认是正确的
		xor cx, cx
		xor ax, ax				;同时清0
		mov cl, buffer[1]       ;数字的个数
		mov bx, offset buffer+2 ;已输入字符串的首字母

again:
		xor dh, dh
		mov dl, [bx]			;取出该字符
		mov byte ptr [di], dl   ;放进表达式里面
		push dx                 ;放进堆栈保护
		mov dx, 10
		mul dx
		pop dx					;弹出来
		sub dl, '0'
		add ax, dx

		inc bx					;准备下一个字符
		inc di					;到下一个位置，准备输入
		loop again				;继续该过程，直到全部读完

		ret
Tr_num endp

putbinary proc near
		xor ebx, ebx
		xor edx, edx
		mov ebx, 80000000h		;通过ebx的循环移位实现
		mov cx, 32				;固定输出32位的2进制
OUT_2:
		push eax
		and eax, ebx
		cmp eax, 0				;每位取与，如果结果为0，输出'0'，否则则是'1'
		je OUT_1
		mov dl, '1'
		jmp Process_then
OUT_1:
		mov dl, '0'
Process_then:
		xor eax, eax
		mov ah, 2
		int 21h
		shr ebx, 1				;移位控制
		inc dh
		cmp dh, 4				;控制输出空格的位置
		je OutSpace
Back:
		pop eax
		loop OUT_2

		cmp cx, 0
		je done_now
OutSpace:
		cmp cx, 1
		je  OUTB
		mov dl, ' '
		jmp Final
OUTB:
		mov dl,'B'				;最后一位显示的是'B'表示2进制
Final:
		mov ah, 2
		int 21h
		xor dh, dh
		jmp Back

done_now: ret
putbinary endp

code ends
	end start 