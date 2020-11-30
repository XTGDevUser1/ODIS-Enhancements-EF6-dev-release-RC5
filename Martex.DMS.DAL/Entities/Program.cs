using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel.DataAnnotations;

namespace Martex.DMS.DAL
{
    [MetadataType(typeof(ProgramMetaData))]
    public partial class Program
    {
    }

    public class ProgramMetaData
    {
        [Required(ErrorMessage = "Program code is required.")]
        public string Code
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Program Name is required.")]
        public string Name
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Client is required.")]
        public string ClientID
        {
            get;
            set;
        }

        public double CallFee
        {
            get;
            set;
        }

        public double DispatchFee
        {
            get;
            set;
        }
    }
}
