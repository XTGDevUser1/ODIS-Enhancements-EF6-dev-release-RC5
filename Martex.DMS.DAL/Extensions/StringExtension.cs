using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Collections;
using System.Xml;
using System.IO;
using log4net;

namespace Martex.DMS.DAL.Extensions
{
    public static class StringExtension
    {
        static readonly ILog logger = LogManager.GetLogger(typeof(StringExtension));
        /// <summary>
        /// Gets the XML.
        /// </summary>
        /// <param name="eventDetails">The event details.</param>
        /// <returns></returns>
        public static string GetXml(this Dictionary<string, string> eventDetails)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();

            settings.Indent = false;
            settings.NewLineOnAttributes = false;
            settings.OmitXmlDeclaration = true;

            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("EventDetail");
                foreach (var item in eventDetails.Keys)
                {
                    writer.WriteStartElement(item.ToString());
                    if (eventDetails[item] != null)
                    {
                        writer.WriteValue(eventDetails[item].ToString());
                    }
                    writer.WriteEndElement();
                }
                writer.WriteEndElement();

                writer.Close();
            }
            return whereClauseXML.ToString();
        }

        /// <summary>
        /// Gets the message data.
        /// </summary>
        /// <param name="htParams">The ht params.</param>
        /// <returns></returns>
        public static string GetMessageData(this Hashtable htParams, bool skipIndent = false)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            if (skipIndent)
            {
                settings.Indent = false;
                settings.NewLineOnAttributes = false;
            }
            else
            {
                settings.Indent = true;
            }
            settings.OmitXmlDeclaration = true;

            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("MessageData");
                foreach (var item in htParams.Keys)
                {
                    writer.WriteStartElement(item.ToString());
                    if (htParams[item] != null)
                    {
                        writer.WriteValue(htParams[item].ToString());
                    }
                    writer.WriteEndElement();
                }
                writer.WriteEndElement();

                writer.Close();
            }
            return whereClauseXML.ToString();
        }

        public static string GetEventDetail(this Hashtable htParams, bool skipIndent = false)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            if (skipIndent)
            {
                settings.Indent = false;
                settings.NewLineOnAttributes = false;
            }
            else
            {
                settings.Indent = true;
            }
            settings.OmitXmlDeclaration = true;

            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("EventDetail");
                foreach (var item in htParams.Keys)
                {
                    writer.WriteStartElement(item.ToString());
                    if (htParams[item] != null)
                    {
                        writer.WriteValue(htParams[item].ToString());
                    }
                    writer.WriteEndElement();
                }
                writer.WriteEndElement();

                writer.Close();
            }
            return whereClauseXML.ToString();
        }

        public static string GetFormattedPhoneNumber(this string p)
        {
            if (string.IsNullOrEmpty(p))
            {
                return p;
            }
            var tokens = p.Split(' ');
            var phoneNumber = tokens[1];
            //TODO: Let's drop extension for now to support the size of the target column.
            phoneNumber = phoneNumber.Split('x', 'X')[0];

            return string.Format("({0}){1}-{2}", phoneNumber.Substring(0, 3), phoneNumber.Substring(3, 3), phoneNumber.Substring(6));
        }

        /// <summary>
        /// Extract Node name and values as key value pairs.
        /// </summary>
        /// <param name="xml">The XML.</param>
        /// <returns>Hashtable with key value pairs</returns>
        public static Hashtable XMLToKeyValuePairs(this string xml)
        {
            Hashtable ht = new Hashtable();

            try
            {
                if (!string.IsNullOrEmpty(xml))
                {
                    XmlDocument doc = new XmlDocument();
                    doc.Load(new StringReader(xml));

                    XmlNodeList nodes = doc.DocumentElement.ChildNodes;

                    foreach (XmlNode node in nodes)
                    {
                        ht.Add(node.Name, node.InnerText ?? string.Empty);
                    }
                }
            }
            catch (Exception)
            {
                logger.WarnFormat("Input string is not a well-formed XML : {0}", xml);
            }

            return ht;
        }

        /// <summary>
        /// Blanks if null.
        /// </summary>
        /// <param name="str">The string.</param>
        /// <returns></returns>
        public static string BlankIfNull(this string str)
        {
            if (string.IsNullOrWhiteSpace(str))
            {
                return string.Empty;
            }
            return str;
        }

        public static string NullIfBlank(this string str)
        {
            if (string.IsNullOrWhiteSpace(str))
            {
                return null;
            }
            return str;
        }
    }
}
