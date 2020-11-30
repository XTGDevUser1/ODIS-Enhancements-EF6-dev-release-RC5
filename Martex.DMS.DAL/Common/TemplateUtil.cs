using Commons.Collections;
using NVelocity;
using NVelocity.App;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.DAL.Common
{
    public static class TemplateUtil
    {
        /// <summary>
        /// Processes the template.
        /// </summary>
        /// <param name="templateString">The template string.</param>
        /// <param name="tagValues">The tag values.</param>
        /// <returns></returns>
        public static string ProcessTemplate(string templateString, Hashtable tagValues)
        {
            if (string.IsNullOrWhiteSpace(templateString))
            {
                return templateString;
            }
            //TFS: 966: Adding a space at the end to avoid issues with Nvelocity that errors out when 
            templateString = templateString + " ";
            //Initialize Velocity
            ExtendedProperties p = new ExtendedProperties();

            VelocityEngine v = new VelocityEngine();
            v.Init(p);

            VelocityContext context = new VelocityContext(tagValues);
            StringWriter writer = new StringWriter();
            v.Evaluate(context, writer, string.Empty, templateString);
            return writer.ToString();
        }
    }
}
