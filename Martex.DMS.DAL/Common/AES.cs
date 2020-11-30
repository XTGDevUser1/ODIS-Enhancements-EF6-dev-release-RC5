using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Security.Cryptography;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.DAL.Common
{
    public static class AES
    {      

        /// <summary>
        /// Encrypts the specified plain text.
        /// </summary>
        /// <param name="plainText">The plain text.</param>
        /// <param name="passPhrase">The pass phrase.</param>
        /// <param name="saltValue">The salt value.</param>
        /// <param name="hashAlgorithm">The hash algorithm.</param>
        /// <param name="passwordIterations">The password iterations.</param>
        /// <param name="initVector">The init vector.</param>
        /// <param name="keySize">Size of the key.</param>
        /// <returns></returns>
        public static string Encrypt(string plainText)
        {
            /* Step 1 : Retrieve Configuration Values From Application Configuration */
            List<ApplicationConfiguration> appConfiguration = new AppConfigRepository().GetApplicationConfigurationList("WebService", "CreditCard");
            if (appConfiguration == null)
            {
                throw new DMSException("Unable to retrieve Application Configuration values for credit card processing");
            }
            ApplicationConfiguration passPhraze = appConfiguration.Where(u => u.Name.Equals("AESPassPhrase")).FirstOrDefault();
            ApplicationConfiguration saltValue = appConfiguration.Where(u => u.Name.Equals("AESSaltValue")).FirstOrDefault(); ;
            ApplicationConfiguration hasAlgorithm = appConfiguration.Where(u => u.Name.Equals("AESAlgorithm")).FirstOrDefault(); ;
            ApplicationConfiguration passwordIterations = appConfiguration.Where(u => u.Name.Equals("AESPasswordIterations")).FirstOrDefault(); ;
            ApplicationConfiguration initVector = appConfiguration.Where(u => u.Name.Equals("AESInitVector")).FirstOrDefault(); ;
            ApplicationConfiguration keySize = appConfiguration.Where(u => u.Name.Equals("AESKeySize")).FirstOrDefault(); ;

            if (passPhraze == null || saltValue == null || hasAlgorithm == null || passwordIterations == null || initVector == null || keySize == null)
            {
                throw new DMSException("Unable to retrieve Application Configuration values for encryption");
            }

            int passwordIterationsInt = 0;
            int.TryParse(passwordIterations.Value, out passwordIterationsInt);

            int keySizeInt = 0;
            int.TryParse(keySize.Value, out keySizeInt);
            // Convert strings into byte arrays.
            // Let us assume that strings only contain ASCII codes.
            // If strings include Unicode characters, use Unicode, UTF7, or UTF8 
            // encoding.
            byte[] initVectorBytes = Encoding.ASCII.GetBytes(initVector.Value);
            byte[] saltValueBytes = Encoding.ASCII.GetBytes(saltValue.Value);

            // Convert our plaintext into a byte array.
            // Let us assume that plaintext contains UTF8-encoded characters.
            byte[] plainTextBytes = Encoding.UTF8.GetBytes(plainText);

            // First, we must create a password, from which the key will be derived.
            // This password will be generated from the specified passphrase and 
            // salt value. The password will be created using the specified hash 
            // algorithm. Password creation can be done in several iterations.
            PasswordDeriveBytes password = new PasswordDeriveBytes(
                                                            passPhraze.Value,
                                                            saltValueBytes,
                                                            hasAlgorithm.Value,
                                                            passwordIterationsInt);

            // Use the password to generate pseudo-random bytes for the encryption
            // key. Specify the size of the key in bytes (instead of bits).
            byte[] keyBytes = password.GetBytes(keySizeInt / 8);

            // Create uninitialized Rijndael encryption object.
            RijndaelManaged symmetricKey = new RijndaelManaged();
            //symmetricKey.Padding = PaddingMode.PKCS7;

            // It is reasonable to set encryption mode to Cipher Block Chaining
            // (CBC). Use default options for other symmetric key parameters.
            symmetricKey.Mode = CipherMode.CBC;

            // Generate encryptor from the existing key bytes and initialization 
            // vector. Key size will be defined based on the number of the key 
            // bytes.
            ICryptoTransform encryptor = symmetricKey.CreateEncryptor(
                                                             keyBytes,
                                                             initVectorBytes);

            // Define memory stream which will be used to hold encrypted data.
            MemoryStream memoryStream = new MemoryStream();

            // Define cryptographic stream (always use Write mode for encryption).
            CryptoStream cryptoStream = new CryptoStream(memoryStream,
                                                         encryptor,
                                                         CryptoStreamMode.Write);
            // Start encrypting.
            cryptoStream.Write(plainTextBytes, 0, plainTextBytes.Length);

            // Finish encrypting.
            cryptoStream.FlushFinalBlock();

            // Convert our encrypted data from a memory stream into a byte array.
            byte[] cipherTextBytes = memoryStream.ToArray();

            // Close both streams.
            memoryStream.Close();
            cryptoStream.Close();

            // Convert encrypted data into a base64-encoded string.
            string cipherText = Convert.ToBase64String(cipherTextBytes);

            // Return encrypted string.
            return cipherText;
        }


        /// <summary>
        /// Decrypts the specified cipher text.
        /// </summary>
        /// <param name="cipherText">The cipher text.</param>
        /// <param name="passPhrase">The pass phrase.</param>
        /// <param name="saltValue">The salt value.</param>
        /// <param name="hashAlgorithm">The hash algorithm.</param>
        /// <param name="passwordIterations">The password iterations.</param>
        /// <param name="initVector">The init vector.</param>
        /// <param name="keySize">Size of the key.</param>
        /// <returns></returns>
        public static string Decrypt(string cipherText)
        {
            List<ApplicationConfiguration> appConfiguration = new AppConfigRepository().GetApplicationConfigurationList("WebService", "CreditCard");
            if (appConfiguration == null)
            {
                throw new DMSException("Unable to retrieve Application Configuration values for credit card processing");
            }
            ApplicationConfiguration passPhraze = appConfiguration.Where(u => u.Name.Equals("AESPassPhrase")).FirstOrDefault();
            ApplicationConfiguration saltValue = appConfiguration.Where(u => u.Name.Equals("AESSaltValue")).FirstOrDefault(); ;
            ApplicationConfiguration hasAlgorithm = appConfiguration.Where(u => u.Name.Equals("AESAlgorithm")).FirstOrDefault(); ;
            ApplicationConfiguration passwordIterations = appConfiguration.Where(u => u.Name.Equals("AESPasswordIterations")).FirstOrDefault(); ;
            ApplicationConfiguration initVector = appConfiguration.Where(u => u.Name.Equals("AESInitVector")).FirstOrDefault(); ;
            ApplicationConfiguration keySize = appConfiguration.Where(u => u.Name.Equals("AESKeySize")).FirstOrDefault(); ;

            if (passPhraze == null || saltValue == null || hasAlgorithm == null || passwordIterations == null || initVector == null || keySize == null)
            {
                throw new DMSException("Unable to retrieve Application Configuration values for encryption");
            }

            int passwordIterationsInt = 0;
            int.TryParse(passwordIterations.Value, out passwordIterationsInt);

            int keySizeInt = 0;
            int.TryParse(keySize.Value, out keySizeInt);

            // Convert strings defining encryption key characteristics into byte
            // arrays. Let us assume that strings only contain ASCII codes.
            // If strings include Unicode characters, use Unicode, UTF7, or UTF8
            // encoding.
            byte[] initVectorBytes = Encoding.ASCII.GetBytes(initVector.Value);
            byte[] saltValueBytes = Encoding.ASCII.GetBytes(saltValue.Value);

            // Convert our ciphertext into a byte array.
            byte[] cipherTextBytes = Convert.FromBase64String(cipherText);
            //ASCIIEncoding con = new ASCIIEncoding();
            //byte[] cipherTextBytes = con.GetBytes(cipherText);
            // First, we must create a password, from which the key will be 
            // derived. This password will be generated from the specified 
            // passphrase and salt value. The password will be created using
            // the specified hash algorithm. Password creation can be done in
            // several iterations.
            PasswordDeriveBytes password = new PasswordDeriveBytes(
                                                             passPhraze.Value,
                                                             saltValueBytes,
                                                             hasAlgorithm.Value,
                                                             passwordIterationsInt);

            // Use the password to generate pseudo-random bytes for the encryption
            // key. Specify the size of the key in bytes (instead of bits).
            byte[] keyBytes = password.GetBytes(keySizeInt / 8);

            // Create uninitialized Rijndael encryption object.
            RijndaelManaged symmetricKey = new RijndaelManaged();
            //symmetricKey.Padding = PaddingMode.None;

            // It is reasonable to set encryption mode to Cipher Block Chaining
            // (CBC). Use default options for other symmetric key parameters.
            symmetricKey.Mode = CipherMode.CBC;

            // Generate decryptor from the existing key bytes and initialization 
            // vector. Key size will be defined based on the number of the key 
            // bytes.
            ICryptoTransform decryptor = symmetricKey.CreateDecryptor(
                                                             keyBytes,
                                                             initVectorBytes);

            // Define memory stream which will be used to hold encrypted data.
            MemoryStream memoryStream = new MemoryStream(cipherTextBytes);

            // Define cryptographic stream (always use Read mode for encryption).
            CryptoStream cryptoStream = new CryptoStream(memoryStream,
                                                          decryptor,
                                                          CryptoStreamMode.Read);

            // Since at this point we don't know what the size of decrypted data
            // will be, allocate the buffer long enough to hold ciphertext;
            // plaintext is never longer than ciphertext.
            byte[] plainTextBytes = new byte[cipherTextBytes.Length];

            // Start decrypting.
            int decryptedByteCount = cryptoStream.Read(plainTextBytes,
                                                       0,
                                                       plainTextBytes.Length);

            // Close both streams.
            memoryStream.Close();
            cryptoStream.Close();

            // Convert decrypted data into a string. 
            // Let us assume that the original plaintext string was UTF8-encoded.
            string plainText = Encoding.UTF8.GetString(plainTextBytes,
                                                       0,
                                                       decryptedByteCount);

            // Return decrypted string.   
            return plainText;
        }
    }
}
