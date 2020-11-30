using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Text;

namespace VendorPortal.Models
{
    public class ContactUsModel
    {
        public string Name { get; set; }
        public string CompanyName { get; set; }
        public string Email { get; set; }
        public string PhoneNumber { get; set; }
        public string Subject { get; set; }
        public string Comments { get; set; }
        public string ClientIP { get; set; }
        public string Browser { get; set; }
    }

    public static class ContactUsModel_Static
    {
        public static string GetEmailBody(this ContactUsModel model)
        {
            StringBuilder sb = new StringBuilder();
            if (model != null)
            {
                sb.Append("<html>");
                sb.Append("<body>");
                sb.Append(string.Format("Name        : {0}", model.Name));
                sb.Append("<br/>");
                sb.Append(string.Format("CompanyName : {0}", model.CompanyName));
                sb.Append("<br/>");
                sb.Append(string.Format("Email       : {0}", model.Email));
                sb.Append("<br/>");
                sb.Append(string.Format("PhoneNumber : {0}", model.PhoneNumber));
                sb.Append("<br/>");
                sb.Append(string.Format("Subject     : {0}", model.Subject));
                sb.Append("<br/>");
                sb.Append(string.Format("Comments    : {0}", model.Comments));
                sb.Append("<br/>");
                sb.Append(string.Format("<small>This request is originated from {0} using {1}</small>", model.ClientIP, model.Browser));
                sb.Append("</body>");
                sb.Append("</html>");
            }
            return sb.ToString();
        }
    }
}