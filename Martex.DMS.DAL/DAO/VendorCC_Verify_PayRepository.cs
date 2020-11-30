using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using System.Data.Entity.Core.Objects;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorTemporaryCCProcessingRepository
    {
        public VendorCCStatusSummary VerifyVendorTempCC(List<int> vendortempccList, string currentUser)
        {
            VendorCCStatusSummary summary = new VendorCCStatusSummary();
            summary.vendorccPosted = new List<int>();
            

            StringBuilder invoicesXML = new StringBuilder("<Tempcc>");
            vendortempccList.ForEach(i =>
            {
                invoicesXML.AppendFormat("<ID>{0}</ID>", i);
            });
            invoicesXML.Append("</Tempcc>");

            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                List<VendorTempCCMatchUpdate_Result> list = dbContext.VendorTempCCMatchUpdate(invoicesXML.ToString(), currentUser).ToList<VendorTempCCMatchUpdate_Result>();
                if (list.Count() > 0)
                {
                    VendorTempCCMatchUpdate_Result result = list[0];
                    summary.Matched = result.MatchedCount ?? 0;
                    summary.MatchedAmount = result.MatchedAmount ?? 0;
                    summary.Cancelled = result.CancelledCount ?? 0;
                    summary.CancelledAmount = result.CancelledAmount ?? 0;
                    summary.Exception = result.ExceptionCount ?? 0;
                    summary.ExceptionAmount = result.ExceptionAmount ?? 0;
                    summary.Posted = result.PostedCount ?? 0;
                    summary.PostedAmount = result.PostedAmount ?? 0;

                    if (!string.IsNullOrEmpty(result.MatchedIds))
                    {
                        string[] matchedList = result.MatchedIds.Split(',');
                        foreach (string id in matchedList)
                        {
                            summary.vendorccPosted.Add(int.Parse(id));
                        }
                    }
                }
            }
            return summary;
        }

        public decimal UpdateBatchStatistics(long batchID, string batchStatus, List<int> tempcclist, string currentUser, string sessionId,string eventsource)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                decimal? totalAmount = 0;
                dbContext.Database.CommandTimeout = 600;
                StringBuilder invoicesXML = new StringBuilder("<Tempcc>");
                tempcclist.ForEach(i =>
                {
                    invoicesXML.AppendFormat("<ID>{0}</ID>", i);
                });
                invoicesXML.Append("</Tempcc>");
                totalAmount = dbContext.UpdateTempCCBatchDetails(invoicesXML.ToString(), batchID, currentUser, eventsource, "PostTempCC", "Post Temporary Credit Card Records", "VendorInvoice", sessionId).SingleOrDefault<decimal?>();
                return totalAmount.GetValueOrDefault();
            }
            
        }

        public void UpdateGLAccountForInvoices(long batchID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                dbContext.TempCC_VendorInvoice_update(Convert.ToInt32(batchID));
            }
        }

        public void CreateStagingDataForPost(int tempccId, long batchID, DateTime? batchTimeStamp,string currentuser)
        {
            VendorInvoice vi = new VendorInvoice();
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 600;
                TemporaryCreditCard card = (from cardobj in dbContext.TemporaryCreditCards
                                            where cardobj.ID == tempccId
                                            select cardobj).FirstOrDefault();

                PurchaseOrder po = (from poobj in dbContext.PurchaseOrders
                                    where poobj.PurchaseOrderNumber == card.ReferencePurchaseOrderNumber
                                    select poobj).FirstOrDefault();

                if (po.VendorLocationID.HasValue)
                {
                    VendorLocation vendorLocation = (from vendorLocationobj in dbContext.VendorLocations
                                                     where vendorLocationobj.ID == po.VendorLocationID
                                                     select vendorLocationobj).FirstOrDefault();
                    Vendor vendor = (from vendorobj in dbContext.Vendors
                                    where vendorobj.ID == vendorLocation.VendorID
                                    select vendorobj).FirstOrDefault();

                    int vendorEntityId = ReferenceDataRepository.GetEntityByName("Vendor").ID;
                    int billingAddressTypeId = ReferenceDataRepository.GetAddressTypeByName("Billing").ID;
                    AddressEntity billingaddress = (from billingaddressobj in dbContext.AddressEntities
                                                    where billingaddressobj.EntityID == vendorEntityId && billingaddressobj.AddressTypeID == billingAddressTypeId && billingaddressobj.RecordID == vendor.ID
                                                    select billingaddressobj).FirstOrDefault();
                    vi.PurchaseOrderID = po.ID;
                    vi.VendorID = vendor.ID;
                    if (billingaddress != null)
                    {
                        vi.BillingAddressLine1 = billingaddress.Line1;
                        vi.BillingAddressLine2 = billingaddress.Line2;
                        vi.BillingAddressLine3 = billingaddress.Line3;
                        vi.BillingAddressCity = billingaddress.City;
                        vi.BillingAddressStateProvince = billingaddress.StateProvince;
                        vi.BillingAddressPostalCode = billingaddress.PostalCode;
                        vi.BillingAddressCountryCode = billingaddress.CountryCode;
                        vi.BillingBusinessName = vendor.Name;
                        string billingContactName = (vendor.ContactFirstName + vendor.ContactLastName);
                        vi.BillingContactName = billingContactName.Length > 50 ? billingContactName.Substring(0, 50) : billingContactName;
                    }

                   
                }

                DateTime? receivedDate = (from receiveddatemin in dbContext.TemporaryCreditCardDetails
                                          where receiveddatemin.TemporaryCreditCardID == tempccId && receiveddatemin.TransactionType == "Charge"
                                          select receiveddatemin.TransactionDate).Min();
                
                vi.VendorInvoiceStatusID = ReferenceDataRepository.GetVendorInvoiceStatus().Where(x => x.Name == "Paid").FirstOrDefault().ID;
                vi.SourceSystemID = ReferenceDataRepository.GetSourceSystemByName("BackOffice").ID;
                int categoryId = (from category in dbContext.PaymentCategories
                                  where category.Name == "CreditCard"
                                  select category.ID).FirstOrDefault();
                vi.PaymentTypeID = (from paymentType in dbContext.PaymentTypes
                                    where paymentType.Name == "TemporaryCC" && paymentType.PaymentCategoryID == categoryId
                                    select paymentType.ID).FirstOrDefault();
                vi.AccountingInvoiceBatchID = null;
                vi.InvoiceNumber = null;
                vi.ReceivedDate = receivedDate;
                vi.ReceiveContactMethodID = null;
                vi.InvoiceDate = receivedDate;
                vi.InvoiceAmount = card.TotalChargedAmount;
                vi.ToBePaidDate = receivedDate;
                vi.ExportDate = batchTimeStamp;
                vi.ExportBatchID = Convert.ToInt32(batchID);
                vi.PaymentDate = receivedDate;
                vi.PaymentAmount = card.TotalChargedAmount;
                vi.PaymentNumber = card.CreditCardNumber;
                vi.CheckClearedDate = receivedDate;
                vi.ActualETAMinutes = null;
                vi.Last8OfVIN = null;
                vi.VehicleMileage = null;
                vi.IsActive = true;
                vi.CreateDate = DateTime.Now;
                vi.CreateBy = currentuser;
                vi.ModifyDate = null;
                vi.ModifyBy = null;

                //Add vendor invoice
                dbContext.VendorInvoices.Add(vi);
                dbContext.SaveChanges();

                //Update po
                po.PayStatusCodeID = (from paystatus in dbContext.PurchaseOrderPayStatusCodes
                                      where paystatus.Name == "PaidByCC"
                                      select paystatus.ID).FirstOrDefault();
                if (string.IsNullOrEmpty(po.CompanyCreditCardNumber))
                {
                    po.CompanyCreditCardNumber = card.CreditCardNumber;
                }
                po.ModifyDate = DateTime.Now;
                po.ModifyBy = currentuser;

                //Update tempcard
                card.PurchaseOrderID = po.ID;
                card.VendorInvoiceID = vi.ID;
                card.PostingBatchID = Convert.ToInt32(batchID);
                card.TemporaryCreditCardStatusID = (from cardstatus in dbContext.TemporaryCreditCardStatus
                                                    where cardstatus.Name == "Posted"
                                                    select cardstatus.ID).FirstOrDefault();
                card.ModifyDate = DateTime.Now;
                card.ModifyBy = currentuser;

                dbContext.SaveChanges();
                
            }

        }
    }
}
