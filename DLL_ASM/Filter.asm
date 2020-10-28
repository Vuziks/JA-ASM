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

	xor R11, R11 ;wyzerowanie rejestru R11
	xorps XMM0, XMM0 ;wyzerowanie rejestru 128-bitowego XMM0
	mov R11B, BYTE PTR [RBP+64] ;pobranie wartosci skladowej zielonej filtra ze stosu i zapisanie w R11B
	cvtsi2sd XMM0, R11 ;konwersja wartosci subpiksela na typ zmiennoprzecinkowy i przechowanie w rejestrze XMM0
	mulsd XMM0, XMM2 ;pomnozenie wartosci subpiksela przez wartosc krycia i zapisanie w XMM0 (green * opacity)
	cvtsd2si R11, XMM0 ;ponowna konwersja wyliczonej wartosci na typ calkowity i zapisanie w R11
	mov BYTE PTR bgrComponent[1], R11B ;przepisanie zielonej skladowej filtra z rejestru R11 do tablicy skladowych

	xor R11, R11 ;wyzerowanie rejestru R11
	xorps XMM0, XMM0 ;wyzerowanie rejestru 128-bitowego XMM0
	mov R11B, BYTE PTR [RBP+72] ;pobranie wartosci skladowej niebieskiej filtra ze stosu i zapisanie w R11B
	cvtsi2sd XMM0, R11 ;konwersja wartosci subpiksela na typ zmiennoprzecinkowy i przechowanie w rejestrze XMM0
	mulsd XMM0, XMM2 ;pomnozenie wartosci subpiksela przez wartosc krycia i zapisanie w XMM0 (blue * opacity)
	cvtsd2si R11, XMM0 ;ponowna konwersja wyliczonej wartosci na typ calkowity i zapisanie w R11
	mov BYTE PTR bgrComponent[0], R11B ;przepisanie niebieskiej skladowej filtra z rejestru R11 do tablicy skladowych

	mov EAX, DWORD PTR [RBP + 80] ;pobranie szerokosci obrazu w pikselach ze stosu i zapisanie w EAX
	mov RBX, 3 ;zapisanie wartosci 3 (liczby skladowych piksela - 24bpp RGB) do RBX
	push RDX ;odlozenie zawartosci RDX na stos (wskaznika na tablice bajtow obrazu pierwotnego)
	mul RBX ;pomnozenie RAX przez RBX (rowWidth * 3)
	mov rowWidth, EAX ;zapisanie obliczonej wartosci (szerokosci obrazu w bajtach) do zmiennej rowWidth

	mov R8D, DWORD PTR [RBP + 88] ;pobranie wartosci stride ze stosu i zapisanie w rejestrze R8

	xor R10, R10 ;wyzerowanie rejestru R10
	mov R10D, byteOffset ;zapisanie offsetu w rejestrze R10 - bedzie on sluzyl do przemieszczania sie po elementach tablicy bajtow

	mov EAX, R8D ;przepisanie wartosci stride z R8D do EAX
	sub EAX, rowWidth ;obliczanie nadmiaru w kazdej linii bitmapy poprzez odjecie dlugosci wiersza od stride
	mov overflow, EAX ;zapisanie nadmiaru bajtow z rejestru EAX w zmiennej overflow

	mov EAX, byteOffset ;zapisanie offsetu w EAX
	xor RDX, RDX ;wyzerowanie rejestru RDX
	mov EBX, R8D ;przepisanie wartosci stride z R8D do EBX
	div EBX ;podzielenie offsetu przez stride (EAX / EBX) => obliczenie numeru wiersza, w ktorym zaczynane jest przetwarzanie bitmapy
	mov EBX, overflow ;zapisanie nadmiaru bajtow na wiersz w EBX
	mul EBX ;pomnozenie numeru wiersza przez nadmiar => obliczenie liczby bajtow, ktore pominieto (niezawierajacych danych o skladowych BGR)
	neg EAX ;negacja obliczonej wartosci w EAX
	add EAX, byteOffset ;dodanie offsetu do EAX => obliczenie numeru analizowanego bajtu zawierajacego skladowa BGR - pomija puste bajty (EAX = offset - row * overflow)
	mov EBX, 3 ;zapisanie wartosci 3 (liczby skladowych piksela - 24bpp RGB) do RBX
	div EBX ;podzielenie numeru bajtu ze skladowa przez liczbe skladowych jednego piksela
	mov EBX, EDX ;przepisanie reszty z dzielenia z EDX do EBX => wyznaczenie indeksu koloru pierwszego bajtu reprezentujacego subpiksel
	pop RDX ;zdjecie ze stosu wskaznika na tablice bajtow obrazu pierwotnego i zapisanie go w RDX
	
	mov R9, 0 ;zapisanie liczby 0 w R9
	mov R11, 1 ;przechowanie w rejestrze R11 wartosci 1 (do obliczania intensywnosci pierwotnych kolorow)
	cvtsi2sd XMM1, R11 ;konwersja jedynki na typ zmiennoprzecinkowy i przechowanie w rejestrze XMM1
	subsd XMM1, XMM2 ;odjecie krycia od 1 (XMM1 = [XMM1] - [XMM2]) => obliczenie intensywnosci skladowych obrazu pierwotnego

	mov R11W, 0FFFFh ;zapisanie maksymalnej wartosci bajtu w rejestrze R11 (wartosc zajmuje dlugosc slowa, zeby mozna bylo wykonac warunkowe kopiowanie - CMOVcc)

MainLoop: ;glowna petla programu umozliwiajaca przetworzenie wszystkich bajtow z zakresu
	push RDX ;odlozenie zawartosci RDX na stos (wskaznika na tablice bajtow obrazu pierwotnego)
	mov RDX, 0 ;zapisanie wartosci 0 w RDX, ¿eby uniknac wystapienia bledow przy dzieleniu
	mov RAX, R10 ;zapisanie indeksu przetwarzanego bajtu z R10 w RAX
	div R8 ;podzielenie indeksu przez stride
	mov RAX, RDX ;zapisanie reszty z dzielenia w RAX => wyznaczenie offsetu wzgledem poczatku wiersza
	pop RDX ;przywrocenie wskaznika na tablice bajtow obrazu pierwotnego ze stosu do RDX
	sub EAX, rowWidth ;odjecie dlugosci wiersza od indeksu bajtu w wierszu i zapisanie w EAX
	jns SkipByte ;pominiecie dalszego przetwarzania bajtu w razie, gdy indeks bajtu w wierszu wykracza poza dlugosc wiersza z subpikselami (currentByte % stride - rowWidth >=0 ? skok do SkipByte)
	
	xor RAX, RAX ;wyzerowanie rejestru RAX
	xorps XMM0, XMM0 ;wyzerowanie rejestru 128-bitowego XMM0
	;mov	 AL, BYTE PTR [RDX + R10] ;pobranie bajtu z tablicy bajtow obrazu pierwotnego o zadanym indeksie R10 i zapisanie w AL
	pmovzxbq XMM0, WORD PTR [RDX + R10]	
	;cvtsi2sd XMM0, XMM0
	cvtdq2ps XMM0, XMM0
	;cvtsi2sd XMM0, RAX ;konwersja wartosci subpiksela na typ zmiennoprzecinkowy i przechowanie w rejestrze XMM0
	mulsd XMM0, XMM1 ;pomnozenie wartosci z XMM0 przez intensywnosc skladowej i zapisanie w XMM0
	cvtsd2si RAX, XMM0 ;ponowna konwersja wyliczonej wartosci na typ calkowity i zapisanie w RAX
	
	add AL, BYTE PTR bgrComponent[RBX] ;dodanie do bajtu wartosci skladowej filtra z uwzglednieniem krycia i zapisanie w AL
	cmovc AX, R11W ;jesli wystapilo przeniesienie z bitu 7 na 8 (przekroczono maksymalna wartosc dla bajtu), zapisanie 0FFFFh w AX (0FFh w AL)
	mov BYTE PTR [RCX + R10], AL ;zapisanie obliczonej wartosci bajtu do tablicy bajtow obrazu wynikowego pod tym samym indeksem

	inc EBX ;inkrementacja EBX, czyli indeksu koloru z tablicy skladowych BGR
	cmp EBX, 3 ;porownanie wartosci EBX z liczba skladowych piksela (24bpp RGB)
	cmove EBX, R9D ;zeby uniknac wykroczenia poza zakres tablicy, zapisanie 0 w EBX, jesli EBX jest rowne 3
	
SkipByte: ;etykieta, do ktorej jest wykonywany skok w przypadku wykrycia bajtu nieprzechowujacego subpiksela
	inc R10 ;inkrementacja indeksu tablicy R10
	dec byteCount ;dekrementacja liczby bajtow do przetworzenie
	jnz MainLoop ;jesli nie przetworzono wszystkich bajtow (byteCount != 0), skok do glownej petli

	;przywrocenie wartosci rejestrow nieulotnych (nonvolatile)
	pop RBP
	pop RSI
	pop RDI
	pop RBX
	pop R15
	pop R14
	pop R13
	pop R12

	ret ;powrot z procedury

AddFilterASM endp

_TEXT ENDS

END