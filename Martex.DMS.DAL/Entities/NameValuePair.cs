using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
     /// <summary>
    /// NameValuePair
    /// </summary>
    public class NameValuePair
    {
        public string Name { get; set; }
        public string Value { get; set; }

        /// <summary>
        /// Gets the XML node.
        /// </summary>
        /// <param name="node">The node.</param>
        /// <returns></returns>
        public static string GetXmlNode(NameValuePair node)
        {
            string returnValue = string.Empty;
            if (!string.IsNullOrEmpty(node.Name) && !(string.IsNullOrEmpty(node.Value)))
            {
                node.Value = node.Value.Replace("\"", "^");
                return string.Format("<Data ProductCategoryQuestionID= \"{0}\"  Answer=\"{1}\" ></Data>", node.Name, node.Value);

            }

            return returnValue;
        }
    }
}
