using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;

namespace testASM
{
    class Program
    {
        static void Main(string[] args)
        {
            Bitmap bmp = new Bitmap(@"D:\studia\Gildia Magów Ognia\JA\projekt\aei.bmp");
            int threadCount = 4;
            int stride = GetStride(bmp);
            byte red = 200, green = 100, blue = 50;
            bool useASM = true;

            byte[] inByte = ImageToByte(bmp);
            byte[] resultByte = ImageToByte(bmp);

            Thread[] threads = new Thread[threadCount];
            switch (useASM)
            {
                case true:
                    for (int i = 0; i < threadCount; i++)
                    {
                        unsafe
                        {
                            //Bitmap ImageOut = new Bitmap(bmp.Width, bmp.Height, PixelFormat.Format24bppRgb);
                            //Bitmap ImageIn = new Bitmap(bmp.Width, bmp.Height, PixelFormat.Format24bppRgb);
                            BitmapData bitmapInData = bmp.LockBits(new Rectangle(0, 0,
                                bmp.Width, bmp.Height),
                                ImageLockMode.WriteOnly, PixelFormat.Format24bppRgb);
                            BitmapData bitmapOutData = new BitmapData();

                            ASM.AddFilterASM((byte*)bitmapOutData.Scan0.ToPointer(),
                            (byte*)bitmapInData.Scan0.ToPointer(),
                            0.5,
                            54,
                            bmp.Width * bmp.Height * 3,
                            red, green, blue,
                            bmp.Width,
                            stride);
                        }
                    }
                    //File.WriteAllBytes("wynik.bmp", resultByte); zapis btimapOutData do pliku
                    break;

                case false:
                    for (int i = 0; i < threadCount; i++)
                    {
                        threads[i] = new Thread(() =>
                        CsDll.Filter.AddFilterCs(
                            ref resultByte,
                            inByte,
                            0.5,
                            54,
                            bmp.Width * bmp.Height * 3,
                            red, green, blue,
                            bmp.Width,
                            stride));
                    }
                    File.WriteAllBytes("wynik.bmp", resultByte);
                    break;
            }
        }

        public static int GetStride(Bitmap bmp)
        {
            BitmapData data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
            int stride = data.Stride;
            bmp.UnlockBits(data);
            return stride;
        }

        public static byte[] ImageToByte(Image img)
        {
            using (var stream = new MemoryStream())
            {
                img.Save(stream, ImageFormat.Bmp);
                return stream.ToArray();
            }
        }
    }

    class ASM
    {
        [DllImport(@"C:\Users\CLEVO\source\repos\JA-ASM\x64\Debug\AsmDll.dll")]
        public static unsafe extern void AddFilterASM(
            byte* resultBitmap,
            byte* originalBitmap,
            double opacity,
            int offset,
            int byteCount,
            byte red, byte green, byte blue,
            int rowWidth,
            int stride);
    }
}


