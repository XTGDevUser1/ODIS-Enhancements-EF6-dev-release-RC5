using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;

[Serializable]
public class CleanupString
{
    [SqlFunction()] 
    public static SqlString RemoveSpecialChars(SqlString inputString,SqlString charset)
    {

        StringBuilder sb = new StringBuilder();
        char[] inputChars = inputString.Value.ToCharArray();

        for (int i = 0, l = inputChars.Length; i < l; i++)
        {
            if (!charset.Value.Contains(inputChars[i]))
            {
                sb.Append(inputChars[i]);
            }
        }

        return new SqlString(sb.ToString());

    }

}

