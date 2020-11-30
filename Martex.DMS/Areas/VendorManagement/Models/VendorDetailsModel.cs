using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.Areas.VendorManagement.Models
{
    public class VendorDetailsModel
    {
        VendorManagementFacade facade = new VendorManagementFacade();

        public Vendor BasicInformation { get; set; }
        public string ContractStatus { get; set; }

        /// <summary>
        /// Gets the vendor contract status ID.
        /// </summary>
        /// <value>
        /// The vendor contract status ID.
        /// </value>
        public int? VendorContractStatusID
        {
            get
            {
                if (this.BasicInformation != null)
                {
                    return facade.GetVendorContractStatus(this.BasicInformation.ID);
                }
                else
                {
                    return null;
                }
            }
        }

        /// <summary>
        /// Gets the name of the source system.
        /// </summary>
        /// <value>
        /// The name of the source system.
        /// </value>
        public string SourceSystemName
        {
            get
            {
                if (this.BasicInformation != null)
                {
                    SourceSystem model = ReferenceDataRepository.GetSourceSystemByID(this.BasicInformation.SourceSystemID.GetValueOrDefault());
                    if (model == null)
                    {
                        return string.Empty;
                    }
                    else
                    {
                        return model.Description;
                    }
                }
                else
                {
                    return string.Empty;
                }
            }
        }

        public int VendorLocationID { get; set; }

        // Change Reason Properties
        public int? ChangeResonID { get; set; }
        public string ChangeReasonComments { get; set; }
        public string ChangedReasonOther { get; set; }

        //To Hold the State of Previous Values
        public int? OldVendorStatusID { get; set; }

        // To Hold the State of Previous Values for Levy
        public bool? OldIsLevyActive { get; set; }

        /// <summary>
        /// Gets or sets the vendor region.
        /// </summary>
        /// <value>
        /// The vendor region.
        /// </value>
        public VendorRegion VendorRegion { get; set; }

        public VendorWebAccountInfoModel WebAccountInfo { get; set; }

        public bool IsCoachNetDealerPartner { get; set; }

        public string Indicators { get; set; }

    }
}