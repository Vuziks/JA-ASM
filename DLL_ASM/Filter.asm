_TEXT SEGMENT

_DllMainCRTStartup PROC 

mov	EAX, 1 
ret

_DllMainCRTStartup ENDP

AddFilterASM proc
	;Zmienne przechowujace parametry filtra i obrazu
	local byteOffset:DWORD ;offset od poczatku tablicy
	local byteCount:DWORD ;liczba bajtow do przetworzenia
	local bgrComponent[3]:BYTE ;tablica przechowujaca wartosci skladowe filtra (w kolejnosci: niebieski, zielony, czerwony)
	local rowWidth:DWORD ;dlugosc jednego wiersza tablicy bajtow w bajtach z pominieciem stride
	local overflow:DWORD ;nadmiar bajtow w kazdej linii bitmapy, liczony jako roznica miedzy stride a rowWidth

 ;odlozenie zawartosci rejestrow nieulotnych (nonvolatile) na stos
	push R12
	push R13
	push R14
	push R15
	push RBX
	push RDI
	push RSI
	push RBP

	mov byteOffset, R9D ;zapisanie offsetu z rejestru R9 w zmiennej
	
	mov EAX, DWORD PTR [RBP+48] ;pobranie liczby bajtow do przetworzenia ze stosu i zapisanie w EAX
	mov byteCount, EAX ;przechowanie zawartosci EAX w zmiennej

	xor R11, R11 ;wyzerowanie rejestru R11
	xorps XMM0, XMM0 ;wyzerowanie rejestru 128-bitowego XMM0
	mov R11B, BYTE PTR [RBP+56] ;pobranie wartosci skladowej czerwonej filtra ze stosu i zapisanie w R11B
	cvtsi2sd XMM0, R11 ;konwersja wartosci subpiksela na typ zmiennoprzecinkowy i przechowanie w rejestrze XMM0
	mulsd XMM0, XMM2 ;pomnozenie wartosci subpiksela przez wartosc krycia i zapisanie w XMM0 (red * opacity)
	cvtsd2si R11, XMM0 ;ponowna konwersja wyliczonej wartosci na typ calkowity i zapisanie w R11
	mov BYTE PTR bgrComponent[2], R11B ;przepisanie czerwonej skladowej filtra z rejestru R11 do tablicy skladowych

AddFilterASM endp

_TEXT ENDS

END