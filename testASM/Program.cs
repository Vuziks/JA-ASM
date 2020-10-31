using System;
using System.Diagnostics;
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
            string filename = @"D:\studia\Gildia Magów Ognia\JA\projekt\aei.bmp";
            float filterOpacity = 0.4f;
            byte red = 128, green = 10, blue = 20;
            Bitmap bmp = new Bitmap(filename);
            Bitmap imageIn;
            Bitmap ImageOut;
            imageIn = ConvertTo24bpp(bmp);
            ImageOut = new Bitmap(imageIn.Width, imageIn.Height, PixelFormat.Format24bppRgb);

            int splitCount = 1;
            int threadCount = splitCount;
            int ImageByteCount = imageIn.Height * GetStride(imageIn);
            int bytesToProcess = ImageByteCount / splitCount;
            int remainder = ImageByteCount % splitCount;
            int i = 0;
            bool useASM = true;

            BitmapData bitmapOutData = null, bitmapInData = null;

            bitmapOutData = ImageOut.LockBits(new Rectangle(0, 0,
               imageIn.Width, imageIn.Height),
               ImageLockMode.WriteOnly, PixelFormat.Format24bppRgb);

            bitmapInData = imageIn.LockBits(new Rectangle(0, 0,
            imageIn.Width, imageIn.Height),
            ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);

            byte[] bufferOut = new byte[bitmapOutData.Stride * bitmapOutData.Height];
            byte[] bufferIn = new byte[bitmapInData.Stride * bitmapInData.Height];
            Marshal.Copy(bitmapInData.Scan0, bufferIn, 0, bufferIn.Length);

            Stopwatch watch = new Stopwatch();

            while (i < splitCount)
            {
                watch.Start();

                Thread[] threads = new Thread[threadCount];
                switch (useASM)
                {
                    case false:
                        for (int j = 0; j < threadCount; j++)
                        {
                            int begin = bytesToProcess * i;
                            if (i == splitCount - 1)
                            {
                                bytesToProcess += remainder;
                            }
                            else if (i >= splitCount)
                            {
                                break;
                            }

                            threads[j] = new Thread(() => 
                            CsDll.Filter.AddFilterC(ref bufferOut, bufferIn, filterOpacity, begin, bytesToProcess, red, green, blue, bitmapInData.Width, bitmapInData.Stride));
                            i++;
                        }
                        break;

                    case true:
                        for (int j = 0; j < threadCount; j++)
                        {

                            int begin = bytesToProcess * i;
                            if (i == splitCount - 1)
                            {
                                bytesToProcess += remainder;
                            }
                            else if (i >= splitCount)
                            {
                                break;
                            }
                            unsafe
                            {
                                threads[j] = new Thread(() =>
                                ASM.AddFilterASM((byte*)bitmapOutData.Scan0.ToPointer(), (byte*)bitmapInData.Scan0.ToPointer(), filterOpacity, begin, bytesToProcess, red, green, blue, bitmapInData.Width, bitmapInData.Stride));
                            }
                            i++;
                        }
                        break;
                }

                for (int j = 0; j < threadCount; j++)
                {
                    if (threads[j] == null)
                    {
                        break;
                    }
                    threads[j].Start();
                }

                for (int j = 0; j < threadCount; j++)
                {
                    if (threads[j] == null)
                    {
                        break;
                    }
                    threads[j].Join();
                }
            }
            watch.Stop();
            if(!useASM)
                Marshal.Copy(bufferOut, 0, bitmapOutData.Scan0, bufferOut.Length);

            ImageOut.UnlockBits(bitmapOutData);
            imageIn.UnlockBits(bitmapInData);
            ImageOut.Save("res.bmp");
            GC.Collect();

            Console.WriteLine(watch.ElapsedMilliseconds);


        }
            public static Bitmap ConvertTo24bpp(Image img)
            {
                var bmp = new Bitmap(img.Width, img.Height, PixelFormat.Format24bppRgb);
                using (var gr = Graphics.FromImage(bmp))
                    gr.DrawImage(img, new Rectangle(0, 0, img.Width, img.Height));
                return bmp;
            }
        
        public static int GetStride(Bitmap bmp)
        {
            BitmapData data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
            int stride = data.Stride;
            bmp.UnlockBits(data);
            return stride;
        }
    }
}

class ASM
{
    [DllImport(@"C:\Users\CLEVO\source\repos\JA-ASM\x64\Debug\AsmDll.dll")]
    public static unsafe extern void AddFilterASM(
        byte* resultBitmap,
        byte* originalBitmap,
        float opacity,
        int offset,
        int byteCount,
        byte red, byte green, byte blue,
        int rowWidth,
        int stride);
}



