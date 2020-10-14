//using System.Drawing;
//using System.Drawing.Imaging;
//using System.IO;
//using System.Reflection;
//using System.Runtime.InteropServices;

//namespace testASM
//{
//    class Program
//    {
//        static void Main(string[] args)
//        {
//            Bitmap bmp = new Bitmap("D:\\studia\\Gildia Magów Ognia\\JA\\projekt\\flower.bmp");

//            BitmapData data = bmp.LockBits(new System.Drawing.Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadOnly, System.Drawing.Imaging.PixelFormat.Format24bppRgb);
//            int stride = data.Stride;
//            bmp.UnlockBits(data);

//            int bitsPerPixel = ((int)bmp.PixelFormat & 0xff00) >> 8;
//            int bytesPerPixel = (bitsPerPixel + 7) / 8;
//            var stride2 = 4 * ((bmp.Width * bytesPerPixel + 3) / 4);

//            byte[] resultByte = ImageToByte(bmp);
//            byte[] inByte = ImageToByte(bmp);

//            //bmp.Save("pies.bmp");

//            CsDll.Filter.AddFilterCs(ref resultByte, inByte, 0.4, 0, inByte.Length, 100, 255, 50, bmp.Width, stride);
//            //unsafe
//            //{
//            //    ASM.AddFilterASM(2.0, 3.0);
//            //}
//            File.WriteAllBytes("wynik.bmp", resultByte);
//        }
//        public static byte[] ImageToByte(Image img)
//        {
//            using (var stream = new MemoryStream())
//            {
//                img.Save(stream, ImageFormat.Bmp);
//                return stream.ToArray();
//            }
//        }
//    }
//    class ASM
//    {
//        [DllImport(@"D:\studia\Gildia Magów Ognia\JA\projekt\Projekt-JA\x64\Debug\AsmDll.dll")]
//        public static unsafe extern void AddFilterASM(double a, double b);
//    }
//}
