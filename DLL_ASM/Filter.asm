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
.data
Mask1 Byte 0,15,15,15,1,15,15,15,2,15,15,15,15,15,15,15
multipleValue Byte 0,0,0,15,15,15,15,15,15,15,15,15,15,15,15,15  ;maski sluzace do przesuwania skladowych w rejestrach XMM
moveMask Byte 15,15,15,2,3,4,5,6,7,8,9,10,11,12,13,14
.code

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

	mov R11B, BYTE PTR [RBP+56] ;pobranie wartosci skladowej czerwonej filtra ze stosu i zapisanie w R11B
	movd XMM6, R11 ;przeniesienie skladowej do rejestru xmm
	mulss xmm6, xmm2 ;opacity * skladowa -> xmm
	mov BYTE PTR bgrComponent[2], R11B ;przepisanie czerwonej skladowej filtra z rejestru R11 do tablicy skladowych

	mov R11B, BYTE PTR [RBP+64] ;pobranie wartosci skladowej zielonej filtra ze stosu i zapisanie w R11B
	movd XMM7, R11 ;przeniesienie skladowej do rejestru xmm
	mulss xmm7, xmm2 ;opacity * skladowa -> xmm
	mov BYTE PTR bgrComponent[1], R11B ;przepisanie zielonej skladowej filtra z rejestru R11 do tablicy skladowych
	
	mov R11B, BYTE PTR [RBP+72] ;pobranie wartosci skladowej niebieskiej filtra ze stosu i zapisanie w R11B
	movd XMM8, R11 ;przeniesienie skladowej do rejestru xmm
	mulss xmm8, xmm2 ;opacity * skladowa -> xmm
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
	cvtsi2ss XMM1, R11 ;konwersja jedynki na typ zmiennoprzecinkowy i przechowanie w rejestrze XMM1
	subss XMM1, XMM2 ;odjecie krycia od 1 (XMM1 = [XMM1] - [XMM2]) => obliczenie intensywnosci skladowych obrazu pierwotnego
	pshufd xmm1, xmm1, 00000000b ;powtorzenie intensywnosci x4

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

	movdqu xmm0, xmmword PTR [RDX + R10] ;wypelnienie rejestru xmm0 kolejnymi skladowymi obrazu
	movdqu xmm10, xmm0 ;przeniesienie skladowych do xmm10
	psrldq xmm10, 1
	pshufb xmm10, xmmword PTR [moveMask] ;operacje pozwalajace na "wyzerowanie" trzech ostatnich skladowych w rejestrze
	pslldq	xmm0, 8
	psrldq xmm0, 8
	pshufb xmm0, xmmword ptr[Mask1] ;operacje ustawiajace trzy skladowe do przetworzenia co 32-bity w rejetrze xmm0
	;sk³adowe np. 00000000000000AA-000000BB000000CC
	mulps xmm0,xmm1 ; pomnozenie trzech skladowych razy (1-opacity)

	movdqu xmm13, xmm0 ; -> pierwsza sk³adowa
	paddb xmm13,xmm6;dodanie policzonego BGR
	psrldq xmm0, 4
	pslldq xmm13, 15
	psrldq xmm13, 15; ustawienie skladowej na odpowiedniej pozycji

	movdqu xmm14, xmm0; ->  druga sk³adowa
	paddb xmm14,xmm7;dodanie policzonego BGR
	psrldq xmm0, 4
	pslldq xmm14, 15
	psrldq xmm14, 14; ustawienie skladowej na odpowiedniej pozycji

	movdqu xmm15, xmm0; ->  trzecia sk³adowa
	paddb xmm15,xmm8;dodanie policzonego BGR
	pslldq xmm15, 15
	psrldq xmm15, 13; ustawienie skladowej na odpowiedniej pozycji

	;dodawanie sk³adowych przesuniêtych do ci¹gu wynikowego
	paddb xmm10,xmm15
	paddb xmm10,xmm14
	paddb xmm10,xmm13
	
	movdqu xmmword ptr [RCX + R10], xmm10; zapis piksela do obrazu wynikowego
SkipByte: ;etykieta, do ktorej jest wykonywany skok w przypadku wykrycia bajtu nieprzechowujacego subpiksela
	add R10, 3 ;inkrementacja indeksu tablicy R10
	sub byteCount, 3 ;dekrementacja liczby bajtow do przetworzenie
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