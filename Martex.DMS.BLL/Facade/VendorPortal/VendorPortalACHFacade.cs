using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO.VendorPortal;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using System.Transactions;
using System.Web;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.IO;
using System.Web.Hosting;
using Martex.DMS.BLL.SMTPSettings;
using System.Web.Mail;
using System.Collections;
using Martex.DMS.DAL.Extensions;

namespace Martex.DMS.BLL.Facade.VendorPortal
{
    public class VendorPortalACHFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VendorPortalACHFacade));
        VendorPortalACHRepository repository = new VendorPortalACHRepository();
        CommonLookUpRepository lookUp = new CommonLookUpRepository();
        #endregion

        #region Public Methods
        /// <summary>
        /// Gets the vendor ACH details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorACH GetVendorACHDetails(int vendorID)
        {
            logger.InfoFormat("Trying to retrieve Vendor ACH Details for the Vendor ID {0}", vendorID);
            VendorACH model = repository.GetVendorACHDetails(vendorID);
            if (model == null)
            {
                logger.InfoFormat("Unable to find ACH Details for the Vendor ID {0}", vendorID);
                model = new VendorACH();
                model.VendorID = vendorID;
            }
            return model;
        }

        /// <summary>
        /// Logs the event for sign up.
        /// </summary>
        /// <param name="sessionID">The session ID.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="userName">Name of the user.</param>
        public void LogEventForSignUp(string sessionID, int vendorID, string userName)
        {
            logger.InfoFormat("Trying to create Event Log When user click the Sign Up from Vendor Portal for Vendor ID {0}", vendorID);
            Event signUpEvent = lookUp.GetEvent(EventNames.ACH_SIGNUP_CLICKED);
            EventLogRepository eventLogRepo = new EventLogRepository();
            EventLog eventLog = new EventLog()
            {
                EventID = signUpEvent.ID,
                Source = "Vendor",
                Description = "Clicked ACH Signup on Vendor Portal",
                NotificationQueueDate = null,
                CreateBy = userName,
                CreateDate = DateTime.Now,
                SessionID = sessionID
            };
            eventLogRepo.Add(eventLog, vendorID, EntityNames.VENDOR);
            logger.Info("Event Log Created successfully");
        }

        /// <summary>
        /// Completes the sign up for vendor ACH.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="sessionID">The session ID.</param>
        public void CompleteSignUpForVendorACH(VendorACH model, string userName, string sessionID, HttpPostedFileBase ACHVoidedCheck)
        {
            #region Set the LookUp Fields for Model
            ACHStatu validStatus = lookUp.GetACHStatus("Valid");
            SourceSystem source = lookUp.GetSourceSystem(SourceSystemName.VENDOR_PORTAL);
            model.ACHStatusID = validStatus.ID;
            model.SourceSystemID = source.ID;

            if (string.IsNullOrEmpty(model.ReceiptEmail))
            {
                // SET Receipt Contact Method ID to Mail
                ContactMethod mail = lookUp.GetContactMethod(ContactMethodNames.MAIL);
                model.ReceiptContactMethodID = mail.ID;
            }
            else
            {
                // SET Receipt Contact Method ID to EMail
                ContactMethod email = lookUp.GetContactMethod(ContactMethodNames.EMAIL);
                model.ReceiptContactMethodID = email.ID;
            }
            #endregion

            #region Fill Country and State
            if (model.BankAddressCountryID.HasValue)
            {
                model.BankAddressCountryCode = lookUp.GetCountry(model.BankAddressCountryID.Value).ISOCode;
            }
            if (model.BankAddressStateProvinceID.HasValue)
            {
                model.BankAddressStateProvince = lookUp.GetStateProvince(model.BankAddressStateProvinceID.Value).Abbreviation;
            }
            #endregion

            #region Set Null Values Explicitly
            model.IsACHSecurityBlock = null;
            model.ACHSecurityBlockNumber = null;
            model.CreateDate = DateTime.Now;
            model.CreateBy = userName;
            model.ModifyBy = null;
            model.ModifyDate = null;
            model.IsActive = true;
            model.ACHSignedByDate = System.DateTime.Now;
            model.IsVoidedCheckOnFile = ACHVoidedCheck == null ? false : true;
            #endregion

            #region DB Insertion
            using (TransactionScope transaction = new TransactionScope())
            {
                logger.InfoFormat("Trying to create Vendor ACH Record for Vendor ID {0}", model.VendorID);
                repository.CreateACHRecord(model);

                logger.InfoFormat("Trying to create Event Log When user Complete the Sign Up from Vendor Portal for Vendor ID {0}", model.VendorID);
                Event insertEvent = lookUp.GetEvent(EventNames.ACH_INSERT_RECORD);
                EventLogRepository eventLogRepo = new EventLogRepository();
                EventLog eventLog = new EventLog()
                {
                    EventID = insertEvent.ID,
                    Source = "Vendor",
                    Description = "Insert ACH from Vendor Portal",
                    NotificationQueueDate = null,
                    CreateBy = userName,
                    CreateDate = DateTime.Now,
                    SessionID = sessionID
                };
                eventLogRepo.Add(eventLog, model.VendorID, EntityNames.VENDOR);

                logger.InfoFormat("ACH Record created successfully for Vendor ID {0}", model.VendorID);
                logger.Info("Event Log Created successfully");
                SaveFileToDisk(ACHVoidedCheck, AppConfigConstants.VENDOR_PORTAL_ACH_VOIDED_CHECK_PATH);
                transaction.Complete();
            }
            #endregion
        }

        private void SaveFileToDisk(HttpPostedFileBase file, string appConfigConstantPath)
        {
            logger.Info("Trying to uplaod the file if use have uplaoded");
            if (file != null)
            {
                var targetFolder = AppConfigRepository.GetValue(appConfigConstantPath);
                if (targetFolder == null)
                {
                    throw new DMSException(string.Format("App config item {0} not configured in the system", appConfigConstantPath));
                }
                var targetPath = HostingEnvironment.MapPath("~/" + targetFolder);
                DirectoryInfo di = new DirectoryInfo(targetPath);
                if (!di.Exists)
                {
                    di.Create();
                }
                var identifier = Guid.NewGuid();
                FileInfo fi = new FileInfo(file.FileName);
                string fileNameFromRequest = fi.Name;
                string targetFileName = Path.Combine(targetPath, identifier.ToString()) + "_" + fileNameFromRequest;
                file.SaveAs(targetFileName);
                logger.Info("File Saved on disk successfully");
            }
            else
            {
                logger.Info("File is not uplaoded by the user");
            }
        }

        /// <summary>
        /// Turns the on or off vendor ACH.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="sessionID">The session ID.</param>
        public void TurnOnOrOffVendorACH(VendorACH model, string userName, string sessionID)
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                #region Event Log
                logger.InfoFormat("Trying to create Event Log When user click Turn off for ACH {0}", model.VendorID);
                Event signUpEvent = lookUp.GetEvent(model.IsActive ? EventNames.ACH_TURN_ON : EventNames.ACH_TURN_OFF);
                EventLogRepository eventLogRepo = new EventLogRepository();
                EventLog eventLog = new EventLog()
                {
                    EventID = signUpEvent.ID,
                    Source = "Vendor",
                    Description = model.IsActive ? "Turned on ACH from Vendor Portal" : "Turned off ACH from Vendor Portal",
                    NotificationQueueDate = null,
                    CreateBy = userName,
                    CreateDate = DateTime.Now,
                    SessionID = sessionID
                };
                eventLogRepo.Add(eventLog, model.VendorID, EntityNames.VENDOR);
                logger.Info("Event Log Created successfully");
                #endregion

                #region Vendor ACH
                logger.InfoFormat("Trying to Update Vendor ACH Information for Vendor ID {0}", model.VendorID);
                repository.UpdateACHInformationFor_ActiveInactive(model, userName);
                logger.InfoFormat("Update success for Vendor ID {0}", model.VendorID);
                #endregion

                transaction.Complete();
            }

            #region Send Email to Vendor Email
            Vendor vendor = repository.GetVendorDetails(model.VendorID.Value);
            if (vendor != null)
            {
                if (!string.IsNullOrEmpty(vendor.Email))
                {
                    EmailService service = new EmailService();
                    bool isSuccess = false;
                    string fromDisplayName = AppConfigConstants.GLOBAL_FROM_DISPLAY_NAME_COACH_VENDOR;
                    string fromAddress = AppConfigRepository.GetValue(AppConfigConstants.NO_REPLY_FROM_EMAIL_ADDRESS);
                    string toDisplayName = vendor.ContactFirstName + " " + vendor.ContactLastName;
                    Hashtable context = new Hashtable();
                    context.Add("Office", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER).GetFormattedPhoneNumber() ?? string.Empty);
                    isSuccess = service.SendEmail(context, vendor.Email, TemplateNames.VENDOR_PORTAL_STOP_ACH, fromAddress, fromDisplayName, toDisplayName);
                    if (isSuccess)
                    {
                        logger.InfoFormat("Email sent Success");
                    }
                    else
                    {
                        logger.InfoFormat("Unable to Send mail check log for failure");
                    }
                }
                else
                {
                    logger.InfoFormat("Unable to Send Stop ACH mail beacuse no email found for Vendor ID {0}", model.VendorID);
                }
            }
            else
            {
                logger.InfoFormat("Unable to retrieve Vendor Details for the Given Vendor ID {0}", model.VendorID);
            }
            #endregion

        }

        public void UpdateACHDetails(VendorACH model, string userName, string sessionID, HttpPostedFileBase ACHVoidedCheck)
        {
            #region Set the LookUp Fields for Model
            ACHStatu validStatus = lookUp.GetACHStatus("Valid");
            model.ACHStatusID = validStatus.ID;
            if (string.IsNullOrEmpty(model.ReceiptEmail))
            {
                // SET Receipt Contact Method ID to Mail
                ContactMethod mail = lookUp.GetContactMethod(ContactMethodNames.MAIL);
                model.ReceiptContactMethodID = mail.ID;
            }
            else
            {
                // SET Receipt Contact Method ID to EMail
                ContactMethod email = lookUp.GetContactMethod(ContactMethodNames.EMAIL);
                model.ReceiptContactMethodID = email.ID;
            }
            #endregion

            #region Fill Country and State
            if (model.BankAddressCountryID.HasValue)
            {
                model.BankAddressCountryCode = lookUp.GetCountry(model.BankAddressCountryID.Value).ISOCode;
            }
            if (model.BankAddressStateProvinceID.HasValue)
            {
                model.BankAddressStateProvince = lookUp.GetStateProvince(model.BankAddressStateProvinceID.Value).Abbreviation;
            }
            #endregion

            #region DB Insertion
            using (TransactionScope transaction = new TransactionScope())
            {
                logger.InfoFormat("Trying to Update Vendor ACH Record for Vendor ID {0}", model.VendorID);
                repository.UpdateACHRecord(model, userName);

                logger.InfoFormat("Trying to create Event Log for Update ACH for Vendor ID {0}", model.VendorID);
                Event insertEvent = lookUp.GetEvent(EventNames.ACH_UPDATE_RECORD);
                EventLogRepository eventLogRepo = new EventLogRepository();
                EventLog eventLog = new EventLog()
                {
                    EventID = insertEvent.ID,
                    Source = "Vendor",
                    Description = "Update ACH from Vendor Portal",
                    NotificationQueueDate = null,
                    CreateBy = userName,
                    CreateDate = DateTime.Now,
                    SessionID = sessionID
                };
                eventLogRepo.Add(eventLog, model.VendorID, EntityNames.VENDOR);

                logger.InfoFormat("ACH Record Updated successfully for Vendor ID {0}", model.VendorID);
                logger.Info("Event Log Created successfully");

                SaveFileToDisk(ACHVoidedCheck, AppConfigConstants.VENDOR_PORTAL_ACH_VOIDED_CHECK_PATH);
                transaction.Complete();
            }
            #endregion
        }
        #endregion
    }
}
