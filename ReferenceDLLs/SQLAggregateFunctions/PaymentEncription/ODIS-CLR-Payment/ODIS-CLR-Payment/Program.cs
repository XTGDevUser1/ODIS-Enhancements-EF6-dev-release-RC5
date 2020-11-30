using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Linq;
using System.Text;

namespace ODIS_CLR_Payment
{
    public class Program
    {
        public static void Main(string[] args)
        {
            SqlString valueToBeEncrypted = "4715625817520150";
            string encryptedValue = EncryptString.Encrypt(valueToBeEncrypted);
            Console.WriteLine("Value to Be Encrypted : {0} , Value after Encryption : {1}", valueToBeEncrypted, encryptedValue);
            Console.ReadLine();
        }
    }
}
