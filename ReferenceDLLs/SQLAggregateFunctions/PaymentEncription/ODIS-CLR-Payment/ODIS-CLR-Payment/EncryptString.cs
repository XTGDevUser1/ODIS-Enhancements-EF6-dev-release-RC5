using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Linq;
using System.Text;
using Microsoft.SqlServer.Server;

namespace ODIS_CLR_Payment
{
    public static class CustomExtensions
    {
        /// <summary>
        /// Blanks if null.
        /// </summary>
        /// <param name="s">The s.</param>
        /// <returns></returns>
        public static string BlankIfNull(this SqlString s)
        {
            if (s.IsNull)
            {
                return string.Empty;
            }
            return (string)s;
        }
    }

    public class EncryptString
    {
        [Microsoft.SqlServer.Server.SqlFunction(DataAccess = DataAccessKind.Read)]
        public static string Encrypt(SqlString valueToBeEncoded)
        {
            return EncryptMethod(valueToBeEncoded.BlankIfNull());
        }

        public static string EncryptMethod(string valueToBeEncoded)
        {
            string returnValue = string.Empty;
            returnValue = AES.Encrypt(valueToBeEncoded);
            return returnValue;
        }

    }
}
