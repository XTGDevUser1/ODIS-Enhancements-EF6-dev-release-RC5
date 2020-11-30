using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;
using System.Text.RegularExpressions;


[Serializable]

public class StringSearch
{
    /// <summary>
    /// Finds the specified input string.
    /// </summary>
    /// <param name="inputString">The input string.</param>
    /// <param name="searchPattern">The search pattern.</param>
    /// <returns></returns>
    [SqlFunction()]
    public static SqlString Find(SqlString inputString, SqlString searchPattern)
    {

        StringBuilder sb = new StringBuilder();

        Match match = Regex.Match(inputString.Value, searchPattern.Value, RegexOptions.Compiled);
        bool matchResult = match.Success;

        do
        {
            if (match.Groups.Count > 0 && match.Groups["grpVar"] != null)
            {
                for (int i = 0, l = match.Groups["grpVar"].Captures.Count; i < l; i++)
                {
                    string trailingDigit = match.Groups["grpVar"].Captures[i].Value;
                    sb.Append(trailingDigit);
                    sb.Append(";");
                }

            }

        } while ((match = match.NextMatch()) != null && match.Success);

        return new SqlString(sb.ToString());

    }

    /// <summary>
    /// Finds the specified input string.
    /// </summary>
    /// <param name="inputString">The input string.</param>
    /// <param name="searchPattern">The search pattern.</param>
    /// <returns></returns>
    [SqlFunction()]
    public static SqlString Replace(SqlString inputString, SqlString searchPattern, SqlString replaceWith)
    {
        Regex regEx = new Regex(searchPattern.Value);
        return new SqlString(regEx.Replace(inputString.Value, replaceWith.Value));

    }
}

