using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.Areas.Application.Models
{
    /// <summary>
    /// ServiceTechModel
    /// </summary>
    public class ServiceTechModel
    {
        public List<Comment> PreviousComments { get; set; }
        public int? CurrentCommentID { get; set; }
        public string CurrentCommentText { get; set; }
        // Diagnostic codes.
        public List<ServiceDiagnosticCodeModel> DiagnosticCodes { get; set; }

        public bool TrackRepairStatus { get; set; }
        public ServiceTech_RepairLocationDetails RepairLocationDetails { get; set; }

         
    }
}