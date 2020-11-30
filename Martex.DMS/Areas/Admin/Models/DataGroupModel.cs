using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;
using  Martex.DMS.DAL;

namespace Martex.DMS.Models
{
    /// <summary>
    /// Model for the Data Group
    /// </summary>
    public class DataGroupModel
    {
        public DataGroup DataGroup { get; set; }
        public int[] DataGroupProgramValues { get; set; }
        public string LastUpdateInformation { get; set; }
    }
}