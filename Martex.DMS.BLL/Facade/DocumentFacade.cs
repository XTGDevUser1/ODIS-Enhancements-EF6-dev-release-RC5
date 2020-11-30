using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using System.Transactions;
using log4net;
using System.Configuration;
using Martex.DMS.BLL.Common;
using System.IO;
using System.Security.Principal;
using System.Runtime.InteropServices;
using Martex.DMS.DAO;
using System.Collections;

namespace Martex.DMS.BLL.Facade
{
    public class DocumentFacade
    {
        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

        DocumentRepository repository = new DocumentRepository();

        protected static readonly ILog logger = LogManager.GetLogger(typeof(DocumentFacade));

        /// <summary>
        /// Gets the documents list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="recordId">The record unique identifier.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        public List<DocumentsList_Result> GetDocumentsList(PageCriteria pc, int recordId, string entityName, string sourceSystem = AppConfigConstants.DOCUMENT_BACK_OFFICE)
        {
            List<DocumentsList_Result> documentList = new List<DocumentsList_Result>();
            sourceSystem = (sourceSystem == AppConfigConstants.DOCUMENT_BACK_OFFICE) ? string.Empty : sourceSystem;
            documentList = repository.GetDocumentsList(pc, recordId, entityName, sourceSystem);
            if (documentList.Count() > 0)
            {
                documentList.ForEach(x =>
                {
                    x.ContentFromFileSystem = false;
                    x.DocumentType = Path.GetExtension(x.DocumentName).Replace(".", "");
                });
            }
            if (entityName == EntityNames.VENDOR)
            {
                string vendorRegion = string.Empty;
                string vendorNumber = string.Empty;
                string basePath = ConfigurationManager.AppSettings[AppConfigConstants.DOCUMENT_NETWORK_BASE_PATH];//@"\\infhydcrm4d\ODIS_Exports\Regional ISP Docs\";
                string path = string.Empty;

                VendorRepository vendorRepository = new VendorRepository();
                Vendor vendor = vendorRepository.GetByID(recordId);
                string vendorState = repository.GetVendorState(recordId);
                if (vendor != null && vendor.VendorRegionID.HasValue && !string.IsNullOrEmpty(vendorState))
                {
                    vendorNumber = vendor.VendorNumber;
                    vendorRegion = vendor.VendorRegion.Name;
                    path = basePath + vendorRegion + "\\" + vendorState + "\\" + vendorNumber;

                    string documentCategory = string.Empty;
                    if (documentList.Count() > 0)
                    {
                        documentCategory = documentList[0].Category;
                    }
                    else
                    {
                        documentCategory = AppConfigConstants.DOCUMENT_CATEGORY_VENDOR;
                    }
                    //TODO: Use Impersonation.


                    string userNameForDocuments = AppConfigRepository.GetValue(AppConfigConstants.VENDOR_DOCUMENTS_USERNAME);
                    string passwordForDocuments = AppConfigRepository.GetValue(AppConfigConstants.VENDOR_DOCUMENTS_PASSWORD);
                    logger.InfoFormat("Retrieved UserName - {0}, and Password for Documents", userNameForDocuments);

                    string userName = string.Empty;
                    string domain = string.Empty;
                    string[] strTokens = userNameForDocuments.Split('\\');
                    if (strTokens.Length > 1)
                    {
                        domain = strTokens[0];
                        userName = strTokens[1];
                    }
                    else
                    {
                        userName = strTokens[0];
                    }

                    IntPtr token = IntPtr.Zero;
                    LogonUser(userName,
                                domain,
                                passwordForDocuments,
                                9,
                                0,
                                ref token);
                    using (WindowsImpersonationContext context = WindowsIdentity.Impersonate(token))
                    {
                        logger.InfoFormat("Attempting to list {0}", path);
                        if (Directory.Exists(@path))
                        {
                            DirectoryInfo di = new DirectoryInfo(@path);
                            var query = (from p in di.GetFiles()
                                         where !p.Attributes.HasFlag(FileAttributes.System) && !p.Attributes.HasFlag(FileAttributes.Hidden)
                                         select p);
                            foreach (var file in query)
                            {
                                DocumentsList_Result result = new DocumentsList_Result();
                                result.DocumentName = file.Name;
                                result.ContentFromFileSystem = true;
                                result.DateAdded = file.CreationTime;
                                result.DocumentType = Path.GetExtension(file.FullName).Replace(".", "");
                                result.Category = documentCategory;
                                result.ContentPath = file.FullName;
                                documentList.Add(result);
                            }
                        }
                    }
                }
            }

            if (documentList.Count() > 0)
            {
                documentList[0].TotalRows = documentList.Count();
            }
            return documentList;
        }


        public Document GetById(int documentID)
        {
            return repository.Get(documentID);
        }
        /// <summary>
        /// Adds the document.
        /// </summary>
        /// <param name="document">The document.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session unique identifier.</param>
        /// <param name="recordId">The record unique identifier.</param>
        public void AddDocument(Document document, string entityName, string eventSource, string currentUser, string sessionID, int recordId)
        {
            using (var tran = new TransactionScope())
            {
                logger.InfoFormat("Adding document for entity {0} and recordID {1}", entityName, recordId);
                int id = repository.Add(document, entityName);

                var eventLoggerFacade = new EventLoggerFacade();

                #region TFS #522
                //This Condition is Specific to Vendor Portal Document
                //We need to create additional event logs
                if (entityName.Equals(EntityNames.VENDOR) && document.IsShownOnVendorPortal.GetValueOrDefault())
                {
                    //Step 1: Create Event Log and Links
                    Dictionary<string, string> eventDetails = new Dictionary<string, string>();
                    VendorRepository vendorRepo = new VendorRepository();
                    Vendor vendorDetails = vendorRepo.GetByID(document.RecordID.GetValueOrDefault());
                    eventDetails.Add("VendorNumber", vendorDetails == null ? string.Empty : vendorDetails.VendorNumber);
                    long eventLogID = eventLoggerFacade.LogEvent(eventSource, EventNames.EVENT_ADD_DOCUMENT, EventCategories.VENDOR_PORTAL, eventDetails, currentUser, sessionID);
                    eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, recordId, entityName);
                    eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, id, EntityNames.DOCUMENT);

                    //Step 2 : Create Contact Log Record
                    ContactLogRepository contactLogRepository = new ContactLogRepository();
                    ContactLog contactLog = new ContactLog();
                    contactLogRepository.Create(contactLog, currentUser, ContactCategoryNames.VENDOR_PORTAL,
                                                                         ContactTypeNames.SYSTEM,
                                                                         ContactMethodNames.DESKTOP_NOTIFICATION,
                                                                         ContactSourceNames.VENDOR_DATA,
                                                                         ContactReasonName.UPLOAD_DOCUMENT,
                                                                         ContactActionName.NOTIFY_VENDOR_REP_FOR_UPLOAD_DOCUMENT);

                    //Step 2 : Create Communication Queue Record
                    string recipientName = string.Empty;
                    if (vendorDetails != null && vendorDetails.VendorRegionID.HasValue)
                    {
                        recipientName = vendorRepo.VendorRepoUserName(vendorDetails.VendorRegionID.GetValueOrDefault());
                    }
                    if (!string.IsNullOrEmpty(recipientName))
                    {
                        CommunicationQueueRepository commQueueRepository = new CommunicationQueueRepository();
                        Hashtable param = new Hashtable();
                        param.Add("VendorNumber", vendorDetails == null ? string.Empty : vendorDetails.VendorNumber);
                        commQueueRepository.Save(contactLog.ID, ContactMethodNames.DESKTOP_NOTIFICATION, TemplateNames.VENDOR_PORTAL_UPLOAD_DOCUMENT, recipientName, param, currentUser);
                    }
                    else
                    {
                        logger.WarnFormat("Communication Queue Record is not created. Unable to retrieve User Name for Vendor Rep for Vendor ID {0}", vendorDetails == null ? string.Empty : vendorDetails.ID.ToString());
                    }
                    #region TFS : 600 - Add logic to send Larry a notification when a Vendor uploads an insurance document
                    var docCategory = ReferenceDataRepository.GetDocumentCategoryByName("Insurance");
                    if (docCategory != null && document.DocumentCategoryID == docCategory.ID)
                    {
                        AppConfigRepository appConfigRepository = new AppConfigRepository();
                        string recipientInsurancer = string.Empty;
                        //TFS : 600
                        //recipientInsurancer = vendorRepo.GetUser("Larry", "Turner", "NMC");

                        recipientInsurancer = AppConfigRepository.GetValue(AppConfigConstants.INSURANCE_ADMIN_USER);

                        if (!string.IsNullOrEmpty(recipientInsurancer))
                        {
                            CommunicationQueueRepository commQueueRepository = new CommunicationQueueRepository();
                            Hashtable hashTable = new Hashtable();
                            hashTable.Add("VendorNumber", vendorDetails == null ? string.Empty : vendorDetails.VendorNumber);
                            commQueueRepository.Save(contactLog.ID, ContactMethodNames.DESKTOP_NOTIFICATION, TemplateNames.VENDOR_PORTAL_UPLOAD_DOCUMENT, recipientInsurancer, hashTable, currentUser);
                        }
                        else
                        {
                            logger.Warn("Communication Queue Record is not created. Unable to retrieve User Name for Larry Turner");
                        }
                    }
                    #endregion
                }
                else
                {
                    long eventLogId = eventLoggerFacade.LogEvent(eventSource, EventNames.EVENT_ADD_DOCUMENT, string.Empty, currentUser, sessionID);
                    eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogId, recordId, entityName);
                }
                #endregion

                logger.Info("Event logs and links created successfully");

                tran.Complete();

            }
        }

        /// <summary>
        /// Deletes the document.
        /// </summary>
        /// <param name="documentId">The document unique identifier.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session unique identifier.</param>
        /// <param name="recordId">The record unique identifier.</param>
        public void DeleteDocument(int documentId, string entityName, string eventSource, string currentUser, string sessionID, int recordId)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                logger.InfoFormat("Deleting document for entity {0} and recordID {1}", entityName, recordId);
                repository.DeleteDocument(documentId);

                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                long eventLogID = eventLoggerFacade.LogEvent(eventSource, EventNames.EVENT_DELETE_DOCUMENT, string.Empty, currentUser, sessionID);

                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, recordId, entityName);

                logger.Info("Event logs and links created successfully");

                tran.Complete();

            }
        }

        public byte[] GetFileFromNetwork(string documentPath)
        {
            byte[] fileContent = null;
            string userNameForDocuments = AppConfigRepository.GetValue(AppConfigConstants.VENDOR_DOCUMENTS_USERNAME);
            string passwordForDocuments = AppConfigRepository.GetValue(AppConfigConstants.VENDOR_DOCUMENTS_PASSWORD);
            logger.InfoFormat("Retireved UserName - {0}, and Password for Documents", userNameForDocuments);

            string userName = string.Empty;
            string domain = string.Empty;
            string[] strTokens = userNameForDocuments.Split('\\');
            if (strTokens.Length > 1)
            {
                domain = strTokens[0];
                userName = strTokens[1];
            }
            else
            {
                userName = strTokens[0];
            }

            IntPtr token = IntPtr.Zero;
            LogonUser(userName,
                        domain,
                        passwordForDocuments,
                        9,
                        0,
                        ref token);
            using (WindowsImpersonationContext context = WindowsIdentity.Impersonate(token))
            {
                logger.InfoFormat("Attempting to get file from path given - {0} using netowrk creds", documentPath);
                using (FileStream fsSource = new FileStream(@documentPath, FileMode.Open, FileAccess.Read))
                {
                    BinaryReader b = new BinaryReader(fsSource);
                    fileContent = b.ReadBytes(Convert.ToInt32(fsSource.Length));
                }
            }
            return fileContent;
        }

        public DocumentCategory GetDocumentCategory(string documentCategoryName)
        {
            return repository.GetDocumentCategory(documentCategoryName);
        }
    }
}
