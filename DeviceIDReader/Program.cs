using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DeviceIDReader
{
    class Program
    {
        /// <summary>
        /// Opens the standard stream in.
        /// </summary>
        /// <returns></returns>
        private static string OpenStandardStreamIn()
        {
            //// We need to read first 4 bytes for length information
            Stream stdin = Console.OpenStandardInput();
            int length = 0;
            byte[] bytes = new byte[4];
            stdin.Read(bytes, 0, 4);
            length = System.BitConverter.ToInt32(bytes, 0);

            string input = "";
            for (int i = 0; i < length; i++)
            {
                input += (char)stdin.ReadByte();
            }

            return input;
        }

        /// <summary>
        /// Opens the standard stream out.
        /// </summary>
        /// <param name="stringData">The string data.</param>
        private static void OpenStandardStreamOut(string stringData)
        {
            //// We need to send the 4 btyes of length information
            string msgdata = "{\"text\":\"" + stringData + "\"}";
            int DataLength = msgdata.Length;
            Stream stdout = Console.OpenStandardOutput();
            stdout.WriteByte((byte)((DataLength >> 0) & 0xFF));
            stdout.WriteByte((byte)((DataLength >> 8) & 0xFF));
            stdout.WriteByte((byte)((DataLength >> 16) & 0xFF));
            stdout.WriteByte((byte)((DataLength >> 24) & 0xFF));
            //Available total length : 4,294,967,295 ( FF FF FF FF )

            Console.Write(msgdata);
        }
        static void Main(string[] args)
        {
            var appSettings = ConfigurationManager.AppSettings;
            var key = Registry.GetValue(appSettings["PATH_TO_REG_KEY"], appSettings["REG_KEY_VALUE"], string.Empty);
            OpenStandardStreamOut(key == null ? string.Empty : key.ToString());
        }
    }
}
