using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel.DataAnnotations;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.Entities
{
    public class VendorRatesDetailsModel
    {
        public int? ContractRateScheduleStatusID { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string SignedBy { get; set; }
        public string SignedByTitle { get; set; }
        public DateTime? SignedDate { get; set; }
        public DateTime? ContractStartDate { get; set; }
        public int VendorID { get; set; }
        public int ContractID { get; set; }
        public int ContractRateScheduleID { get; set; }
        public string ContractRateScheduleStatus { get; set; }

        public string ModifiedBy { get; set; }
        public string CreatedBy { get; set; }

        public DateTime? CreatedOn { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }
}

namespace Martex.DMS.DAL
{
    [MetadataType(typeof(VendorServicesAndRates_Result_DataAnnotation))]
    public partial class VendorServicesAndRates_Result
    {
        VendorManagementRepository repository = new VendorManagementRepository();
        public bool IsServiceRateConfigured
        {
            get
            {
                bool isConfigured = true;
                isConfigured = repository.IsProductRateTypeConfigured(this.ProductID.GetValueOrDefault(), RateTypeNames.Service);
                return isConfigured;
            }
        }
        public bool IsServiceFreeMilesConfigured
        {
            get
            {
                bool isConfigured = true;
                isConfigured = repository.IsProductRateTypeConfigured(this.ProductID.GetValueOrDefault(), RateTypeNames.ServiceFree);
                return isConfigured;
            }
        }

        public bool IsBaseRateConfigured
        {
            get
            {
                bool isConfigured = true;
                isConfigured = repository.IsProductRateTypeConfigured(this.ProductID.GetValueOrDefault(), RateTypeNames.Base);
                return isConfigured;
            }
        }


        public bool IsEnrouteRateConfigured
        {
            get
            {
                bool isConfigured = true;
                isConfigured = repository.IsProductRateTypeConfigured(this.ProductID.GetValueOrDefault(), RateTypeNames.Enroute);
                return isConfigured;
            }

        }
        public bool IsEnrouteFreeMilesConfigured
        {
            get
            {
                bool isConfigured = true;
                isConfigured = repository.IsProductRateTypeConfigured(this.ProductID.GetValueOrDefault(), RateTypeNames.EnrouteFree);
                return isConfigured;
            }

        }

        public bool IsHourlyRateConfigured
        {
            get
            {
                bool isConfigured = true;
                isConfigured = repository.IsProductRateTypeConfigured(this.ProductID.GetValueOrDefault(), RateTypeNames.Hourly);
                return isConfigured;
            }

        }

        public bool IsGOARateConfigured
        {
            get
            {
                bool isConfigured = true;
                isConfigured = repository.IsProductRateTypeConfigured(this.ProductID.GetValueOrDefault(), RateTypeNames.GoneOnArrival);
                return isConfigured;
            }

        }
    }


    public class VendorServicesAndRates_Result_DataAnnotation
    {
        [Required(ErrorMessage = "Product is required,")]
        public int? ProductID { get; set; }

    }
}
