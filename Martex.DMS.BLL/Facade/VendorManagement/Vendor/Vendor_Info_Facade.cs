using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using System.Transactions;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorManagementFacade
    {
        /// <summary>
        /// Gets the specified vendor ID.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>

        public Vendor Get(int vendorID)
        {
            return vendorManagement_Repository.Get(vendorID);
        }

        /// <summary>
        /// Updates the vendor web account.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <param name="model">The model.</param>
        public void UpdateVendorWebAccount(string userName,VendorWebAccountInfoModel model)
        {
            vendorManagement_Repository.UpdateVendorWebAccount(userName,model);
        }

        /// <summary>
        /// Gets the vendor web account information.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorWebAccountInfoModel GetVendorWebAccountInformation(int vendorID)
        {
            return vendorManagement_Repository.GetVendorWebAccountInformation(vendorID);
        }



        /// <summary>
        /// Updates the vendor information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void UpdateVendorInformation(Vendor model, string userName, int? oldVendorStatusID, int? ChangeResonID, string ChangeReasonComments, string ChangedReasonOther, int vendorLocationID, bool? OldIsLevyActive, string source = "/VendorManagement/VendorHome/")
        {
            if (vendorLocationID == 0)
            {
                logger.InfoFormat("Trying to Update Vendor Information Details");
                EventLogRepository eventLogRepo = new EventLogRepository();
               
                #region Change Status Track
                bool isVendorStatusChanged = false;
                if (oldVendorStatusID.HasValue && oldVendorStatusID.Value != model.VendorStatusID)
                {
                    isVendorStatusChanged = true;
                }
                logger.InfoFormat("Vendor Status is changed for the vendor ID {0}", model.ID);

                bool IsLevyChanged = false;
                if (model.IsLevyActive.GetValueOrDefault() != OldIsLevyActive.GetValueOrDefault())
                {
                  IsLevyChanged = true;
                }
                logger.InfoFormat("Vendor Levy is changed for the vendor ID {0}", model.ID);
                #endregion

                using (TransactionScope transaction = new TransactionScope())
                {
                    #region When Vendor Status Changed
                    if (isVendorStatusChanged)
                    {
                        logger.InfoFormat("Trying to Create Vendor Status Log for the given Vendor ID {0} in Transaction", model.ID);
                        VendorStatusLog vendorStatusLog = new VendorStatusLog()
                        {
                            VendorID = model.ID,
                            VendorStatusIDBefore = oldVendorStatusID,
                            VendorStatusIDAfter = model.VendorStatusID,
                            VendorStatusReasonID = ChangeResonID,
                            VendorStatusReasonOther = ChangedReasonOther,
                            Comment = ChangeReasonComments,
                            CreateBy = userName,
                            CreateDate = DateTime.Now
                        };
                        vendorManagement_Repository.CreateVendorStatusLog(vendorStatusLog);
                    }
                    #endregion

                    #region When Levy Changed
                    if (IsLevyChanged)
                    {
                        CommonLookUpRepository lookUpRepository = new CommonLookUpRepository();
                        Event levyStart = lookUpRepository.GetEvent(EventNames.START_LEVY);
                        Event levyEnd= lookUpRepository.GetEvent(EventNames.END_LEVY);
                       
                        StringBuilder eventDescription = new StringBuilder();
                        eventDescription.Append("<MessageData><IsLevyActiveOld>");
                        eventDescription.Append(OldIsLevyActive.GetValueOrDefault());
                        eventDescription.Append("</IsLevyActiveOld>");
                        eventDescription.Append("<IsLevyActiveNew>");
                        eventDescription.Append(model.IsLevyActive.GetValueOrDefault());
                        eventDescription.Append("</IsLevyActiveNew></MessageData>");
                     
                        EventLog eventLog = new EventLog()
                        {
                            EventID = model.IsLevyActive.GetValueOrDefault() ? levyStart.ID : levyEnd.ID,
                            Source = source,
                            NotificationQueueDate = null,
                            CreateBy = userName,
                            CreateDate = DateTime.Now,
                            Description = eventDescription.ToString()
                        };
                        eventLogRepo.Add(eventLog, model.ID,EntityNames.VENDOR);
                    }
                    #endregion

                    #region Update Vendor Information
                    logger.InfoFormat("Trying to Update Vendor Information for the given ID {0} in Transaction", model.ID);
                    vendorManagement_Repository.UpdateVendorInformation(model, userName);
                    transaction.Complete();
                    logger.Info("Transaction Completed. Records Updated");
                    #endregion
                }
            }
        }
    }
}
