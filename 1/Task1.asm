code segment
assume cs:code
main:
	mov ax, 0B800h
	mov es, ax		;显存的段地址
	mov ax, 0003h   ;
	int 10h			;清屏
	mov cx, 0		;代表的是当前的ASCII值,同时做为控制信号,输出256个后停止
	
LooPrint:
	mov di, 0		;偏移地址先置0
	mov ax, cx		;将当前的cx值送到ax里面
	mov dl, 19h		;做除数25, 计算行数和列数
	div dl			;al为商-->列, ah为余数-->行
	mov bh, ah      ;用bh来保存行数ah
	mov bl, 14		;列 * 7 * 2 = 14
	mul bl			;得到列的地址偏移量
	add di, ax      ;加到偏移地址di里面去

	mov al, bh      ;行数拿出来给到al里面
	mov bl, 160     ;计算行数的偏移量
	mul bl          ;乘积放到ax里面
	add di, ax      ;现在得到了总的偏移量

	mov ax, cx      ;导入ASCII码值
	mov ah, 0Ch     ;设置背景黑色，前景亮红
	mov word ptr es:[di], ax  ;送到显存里输出

	add di, 2       ;向右输出第一个ASCII码值数字
	mov ax, cx      ;重新导入当前的ASCII码值
	mov dl, 16      ;用来计算两位的16进制数
	div dl          ;al为商:第一位 ah为余数:第二位

	mov bh, ah      ;存下第二位
	and ah, 00h     ;掩掉高位，方便计算
	mov bl, 10      ;和10比较,比10小的转化成整数的ASCII码值,>=10的时候转化成字母的ASCII码值
	cmp al, bl      ;第一位和10进行比较
	jb  pro_number  ;如果比10小，则按照数字ASCII进行输出
	sub al, 10
	add al, 41h		;这两步是转换到大写字母的ASCII码值 
	mov ah, 0Ah	    ;设置为黑色背景，前景亮绿色
	mov word ptr es:[di], ax	;送到显存里输出
	jmp next_number ;跳到下一个数处理

pro_number:
	add al, 30h		;加上'0'的ASCII码值进行转换
	mov ah, 0Ah	;设置为黑色背景，前景亮绿色
	mov word ptr es:[di], ax	;送到显存里输出

next_number:
	add di, 2       ;偏移地址再加2
	mov al, bh      ;取出第二位
	mov bl, 10      ;这里参照上面的就好了
	cmp al, bl      ;第一位和10进行比较
	jb  pro_number1  ;如果比10小，则按照数字ASCII进行输出
	sub al, 10
	add al, 41h		;这两步是转换到大写字母的ASCII码值 
	mov ah, 0Ah	    ;设置为黑色背景，前景亮绿色
	mov word ptr es:[di], ax	;送到显存里输出
	jmp Next 		;跳到下一个处理过程

pro_number1:
	add al, 30h		;加上'0'的ASCII码值进行转换
	mov ah, 0Ah	    ;设置为黑色背景，前景亮绿色
	mov word ptr es:[di], ax	;送到显存里输出

Next:
	inc cx
	cmp cx,256	    ;执行256次
	jne LooPrint

	mov ah, 0
	int 16h		
	mov ah, 4Ch
	int 21h		
code ends
end main

