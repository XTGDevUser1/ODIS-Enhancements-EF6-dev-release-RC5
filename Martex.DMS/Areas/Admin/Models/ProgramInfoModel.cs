using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL;

namespace Martex.DMS.Areas.Admin.Models
{
    /// <summary>
    /// Model fro the Program Info
    /// </summary>
    public class ProgramInfoModel
    {
        public List<ProgramInformation_Result> ProgramInformation { get; set; }
        public List<ProgramServices_Result> ProgramServices { get; set; }
        public bool IsCoverageInfoVisible { get; set; }
        public List<ProgramServiceEventLimit> ProgramServiceEventLimit { get; set; }
        public List<MemberProductsUsingCategory_Result> MemberProducts { get; set; }
    }
}