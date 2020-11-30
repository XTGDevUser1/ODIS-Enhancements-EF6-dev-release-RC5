using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using System.Web.Mvc;

namespace Martex.DMS.Areas.Common.Models
{
    [Serializable]
    public class NotificationModel
    {
        public int? NotificationRecipentType { get; set; }        

        public string[] NotificationUserRoleID { get; set; }

        public int? NotificationSeconds { get; set; }

        public string NotificationMessage { get; set; }

    }
}