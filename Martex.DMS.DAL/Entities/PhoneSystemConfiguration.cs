using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;


namespace Martex.DMS.DAL
{
    [MetadataType(typeof(PhoneSystemConfigurationMetaData))]
    public partial class PhoneSystemConfiguration
    {
    }

    public class PhoneSystemConfigurationMetaData
    {
        [Required(ErrorMessage = "Program Id is required.")]
        public int ProgramID
        {
            get;
            set;
        }

        [Required(ErrorMessage = "IVR Script is required.")]
        public int IVRScriptID
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Skillset is required.")]
        public int SkillsetID
        {
            get;
            set;
        }
      
        [Required(ErrorMessage = "Inbound phone compnay is required.")]
        public int InboundPhoneCompanyID
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Inbound number is required.")]
        [StringLength(50)]
        public string InboundNumber
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Pilot number is required.")]
        [StringLength(50)]
        public string PilotNumber
        {
            get;
            set;
        }
    }
}