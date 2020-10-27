_TEXT SEGMENT

_DllMainCRTStartup PROC 

mov	EAX, 1 
ret

_DllMainCRTStartup ENDP

;AddFilterASM(
;	byte* resultBitmap,		-> RCX
;	byte* originalBitmap,	-> RDX
;	double opacity,			-> XMM2
;	int offset,				-> R9
;	int byteCount,			-> STOS
;	byte red,				-> STOS
;	byte green,				-> STOS
;	byte blue				-> STOS
;	int rowWidth			-> STOS
;	int stride				-> STOS
;)

AddFilterASM proc
	;Zmienne przechowujace parametry filtra i obrazu
	local opacity:QWORD ;intensywnoœæ
	local byteOffset:DWORD ;offset od poczatku tablicy
	local byteCount:DWORD ;liczba bajtow do przetworzenia
	local bgrComponent[3]:BYTE ;tablica przechowujaca wartosci skladowe filtra (w kolejnosci: niebieski, zielony, czerwony)
	local rowWidth:DWORD ;dlugosc jednego wiersza tablicy bajtow w bajtach z pominieciem stride
	local overflow:DWORD ;nadmiar bajtow w kazdej linii bitmapy, liczony jako roznica miedzy stride a rowWidth

	mov byteOffset, R9D ;zapisanie offsetu z rejestru R9 w zmiennej
	
	mov EAX, DWORD PTR [RBP+48] ;pobranie liczby bajtow do przetworzenia ze stosu i zapisanie w EAX
	mov byteCount, EAX ;przechowanie zawartosci EAX w zmiennej

	mov R11B, BYTE PTR [RBP+56] ;czerwona
	mov BYTE PTR bgrComponent[2], R11B

	mov R11B, BYTE PTR [RBP+64] ;zielona
	mov BYTE PTR bgrComponent[1], R11B

	mov R11B, BYTE PTR [RBP+72] ;niebieska
	mov BYTE PTR bgrComponent[0], R11B 

	mov EAX, DWORD PTR [RBP + 80] ;pobranie szerokosci obrazu w pikselach ze stosu i zapisanie w EAX
	mov rowWidth, EAX

AddFilterASM endp

_TEXT ENDS

END