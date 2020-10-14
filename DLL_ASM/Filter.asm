_TEXT SEGMENT

_DllMainCRTStartup PROC 

mov	EAX, 1 
ret

_DllMainCRTStartup ENDP

AddFilterASM proc x: DWORD, y: DWORD
 xor eax,eax
 mov eax,x
 mov ecx,y
 ror ecx,1
 shld eax,ecx,2
 jnc ET1
 mul y
 ret
ET1: mul x
 neg y
 ret

AddFilterASM endp

_TEXT ENDS

END