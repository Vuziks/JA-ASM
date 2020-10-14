namespace DLL_C
{
    public static class Filter
    {
        public static void AddFilterC(ref byte[] resultBitmap, byte[] originalBitmap, double opacity, int offset, int byteCount, byte red, byte green, byte blue, int rowWidth, int stride)
        {
            int color = 0;
            rowWidth *= 3; // d�ugo�� wiersza bitmapy w bajtach

            double intense = 1 - opacity; // intensywno�� sk�adowych obrazu pierwotnego
            byte[] bgrComponent = { blue, green, red }; // tablica sk�adowych BGR filtra
            int overflow = stride - rowWidth; // nadmiar bajt�w na wiersz
            int row = offset / stride; // nr wiersza
            int colorIndex = (offset - row * overflow) % 3; // indeks sk�adowej BGR, od kt�rej zaczynane jest przetwarzanie danej cz�ci obrazu

            for (int currentByte = offset; currentByte < offset + byteCount; currentByte++) // przej�cie po (byteCount) bajtach, pocz�wszy od indeksu nr (offset)
            {
                if (currentByte % stride >= rowWidth)
                {
                    continue; // pomini�cie bajt�w nieprzechowuj�cych warto�ci subpikseli
                }

                color = (int)(originalBitmap[currentByte] * intense + bgrComponent[colorIndex] * opacity); // obliczenie nowej warto�ci subpiksela

                if (color > 255) // przypisanie maksymalnej warto�ci w razie przepe�nienia
                { color = 255; }

                resultBitmap[currentByte] = (byte)color; // wpisanie warto�ci do tablicy wynikowej

                colorIndex++; // inkrementacja indeksu sk�adowych
                if (colorIndex == 3) // colorIndex = colorIndex % 3
                {
                    colorIndex = 0;
                }
            }
        }
    }
}
