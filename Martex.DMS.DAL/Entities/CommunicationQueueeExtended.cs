using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel.DataAnnotations;
using System.Collections;
using System.Xml;
using System.IO;

namespace Martex.DMS.DAL
{
    
    public partial class CommunicationQueue
    {
        public int CommunicationLogID { get; set; }
        /// <summary>
        /// Extract Node name and values as key value pairs.
        /// </summary>
        /// <param name="xml">The XML.</param>
        /// <returns>Hashtable with key value pairs</returns>
        public Hashtable XMLToKeyValuePairs(string xml)
        {
            Hashtable ht = new Hashtable();

            XmlDocument doc = new XmlDocument();
            doc.Load(new StringReader(xml));

            XmlNodeList nodes = doc.DocumentElement.ChildNodes;

            foreach (XmlNode node in nodes)
            {
                ht.Add(node.Name, node.InnerText ?? string.Empty);
            }

            return ht;
        }
    }
}
