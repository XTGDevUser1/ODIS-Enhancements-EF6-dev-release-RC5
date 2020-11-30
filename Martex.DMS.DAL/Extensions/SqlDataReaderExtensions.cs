using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data.SqlClient;

namespace Martex.DMS.DAL.Extensions
{
    public static class SqlDataReaderExtensions
    {
        #region Sql Data Reader Extension members

        /// <summary>
        /// Gets the string with DB null validation.
        /// </summary>
        /// <param name="value">The value.</param>
        /// <param name="index">The index.</param>
        /// <returns></returns>
        public static string GetStringWithDBNullValidation(this SqlDataReader value, int index)
        {
            string returnValue = string.Empty;
            if (!value.IsDBNull(index))
            {
                returnValue = value.GetString(index);
            }
            return returnValue;
        }

        /// <summary>
        /// Gets the int32 with DB null validation.
        /// </summary>
        /// <param name="value">The value.</param>
        /// <param name="index">The index.</param>
        /// <returns></returns>
        public static int GetInt32WithDBNullValidation(this SqlDataReader value, int index)
        {
            int returnValue = 0;
            if (!value.IsDBNull(index))
            {
                returnValue = value.GetInt32(index);
            }
            return returnValue;
        }
        #endregion
    }
}
