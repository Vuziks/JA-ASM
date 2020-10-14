namespace DLL_C
{
    public static class Filter
    {
        public static void AddFilterC(ref byte[] resultBitmap, byte[] originalBitmap, double opacity, int offset, int byteCount, byte red, byte green, byte blue, int rowWidth, int stride)
        {
            int color = 0;
            rowWidth *= 3; // d³ugoœæ wiersza bitmapy w bajtach

            double intense = 1 - opacity; // intensywnoœæ sk³adowych obrazu pierwotnego
            byte[] bgrComponent = { blue, green, red }; // tablica sk³adowych BGR filtra
            int overflow = stride - rowWidth; // nadmiar bajtów na wiersz
            int row = offset / stride; // nr wiersza
            int colorIndex = (offset - row * overflow) % 3; // indeks sk³adowej BGR, od której zaczynane jest przetwarzanie danej czêœci obrazu

            for (int currentByte = offset; currentByte < offset + byteCount; currentByte++) // przejœcie po (byteCount) bajtach, pocz¹wszy od indeksu nr (offset)
            {
                if (currentByte % stride >= rowWidth)
                {
                    continue; // pominiêcie bajtów nieprzechowuj¹cych wartoœci subpikseli
                }

                color = (int)(originalBitmap[currentByte] * intense + bgrComponent[colorIndex] * opacity); // obliczenie nowej wartoœci subpiksela

                if (color > 255) // przypisanie maksymalnej wartoœci w razie przepe³nienia
                { color = 255; }

                resultBitmap[currentByte] = (byte)color; // wpisanie wartoœci do tablicy wynikowej

                colorIndex++; // inkrementacja indeksu sk³adowych
                if (colorIndex == 3) // colorIndex = colorIndex % 3
                {
                    colorIndex = 0;
                }
            }
        }
    }
}
