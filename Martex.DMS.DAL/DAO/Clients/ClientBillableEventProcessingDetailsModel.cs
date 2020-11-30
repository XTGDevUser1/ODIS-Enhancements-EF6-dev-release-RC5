using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO.Clients
{
    public class ClientBillableEventProcessingDetailsModel
    {
        public int BillingInvoiceDetailID { get; set; }
        public int? BillingDispositionStatusID { get; set; }

        public int? InvoiceDetailStatusID { get; set; }

        public int? AdjustmentReasonID { get; set; }
        public string AdjustmentReasonOther { get; set; }
        public string AdjustmentComment { get; set; }
        public decimal AdjustmentAmount { get; set; }

        public decimal? EventAmount { get; set; }
        public int? Quantity { get; set; }

        public int? ExcludeReasonID { get; set; }
        public string ExcludeReasonOther { get; set; }
        public string ExcludeComment { get; set; }

        public bool IsAdjusted { get; set; }
        public bool IsExcluded { get; set; }

        public string InternalComment { get; set; }
        public string ClientNote { get; set; }

    }

    public static class ClientBillableEventProcessingDetailsModel_Extended
    {
        public static void Validate(this ClientBillableEventProcessingDetailsModel model)
        {
            ClientRepository repository = new ClientRepository();
            CommonLookUpRepository lookUP = new CommonLookUpRepository();
            ClientBillableEventProcessingDetails_Result dbResult = repository.GetBillingInvoiceDetail(model.BillingInvoiceDetailID);
            if (model.InvoiceDetailStatusID.GetValueOrDefault() != dbResult.DetailsStatusID.GetValueOrDefault())
            {
                if (model.InvoiceDetailStatusID.HasValue)
                {
                    BillingInvoiceDetailStatu status = lookUP.GetBillingInvoiceDetailStatus(model.InvoiceDetailStatusID.GetValueOrDefault());
                    if (status.Name.Equals("DELETED", StringComparison.OrdinalIgnoreCase))
                    {
                        throw new DMSException("Users cannot change status to Deleted");
                    }
                    else if (status.Name.Equals("POSTED", StringComparison.OrdinalIgnoreCase))
                    {
                        throw new DMSException("Users cannot change status to Posted");
                    }
                    else if (status.Name.Equals("EXCEPTION", StringComparison.OrdinalIgnoreCase))
                    {
                        throw new DMSException("Users cannot change status to Exception");
                    }
                    else if (status.Name.Equals("EXCLUDED", StringComparison.OrdinalIgnoreCase))
                    {
                        if (!model.IsExcluded)
                        {
                            throw new DMSException("Users cannot change status to Excluded, you must fill in the Exclude tab information to exclude this event");
                        }
                    }
                }

            }

            if (model.IsAdjusted)
            {
                if (model.AdjustmentAmount == 0)
                {
                    throw new DMSException("Adjustment Amount is required");
                }
                if (!model.AdjustmentReasonID.HasValue)
                {
                    throw new DMSException("Adjustment Reason is required");
                }
                BillingAdjustmentReason reason = lookUP.GetBillingAdjustmentReason(model.AdjustmentReasonID.Value);
                if (reason.Name.Equals("OTHER", StringComparison.OrdinalIgnoreCase))
                {
                    if (string.IsNullOrEmpty(model.AdjustmentReasonOther))
                    {
                        throw new DMSException("Adjustment Reason Other is required");
                    }
                }

            }

            if (model.IsExcluded)
            {
                if (!model.ExcludeReasonID.HasValue)
                {
                    throw new DMSException("Exclude Reason is required");
                }
                BillingExcludeReason excludeReason = lookUP.GetBillingExcludeReason(model.ExcludeReasonID.Value);
                if (excludeReason.Name.Equals("OTHER", StringComparison.OrdinalIgnoreCase))
                {
                    if (string.IsNullOrEmpty(model.ExcludeReasonOther))
                    {
                        throw new DMSException("Exclude Reason Other is required");
                    }
                }
            }

        }
    }
}
