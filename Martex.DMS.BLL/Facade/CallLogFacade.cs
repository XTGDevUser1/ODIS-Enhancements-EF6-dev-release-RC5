using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class CallLogFacade
    {
        /// <summary>
        /// Logs the call.
        /// </summary>
        /// <param name="log">The log.</param>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <param name="currentUser">The current user.</param>
        /// <exception cref="DMSException">
        /// Contact Type - Vendor is not set up in the system
        /// or
        /// Contact Method - Phone is not set up in the system
        /// or
        /// Contact Category - VendorSelection is not set up in the system
        /// or
        /// </exception>
        public static void LogCall(CallLog log, int? serviceRequestId, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                #region 1. Create contactLog record

                var contactLogRepository = new ContactLogRepository();
                ContactLog contactLog = new ContactLog()
                {
                    ContactSourceID = null,
                    TalkedTo = log.CallLogTalkedTo,
                    Company = log.Company,
                    PhoneTypeID = null,
                    PhoneNumber = log.PhoneNumberCalled,
                    Direction = "Outbound",
                    Comments = log.CallLogComments,
                    Description = "Service location selection",
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now
                };

                // Get the phone Type ID
                PhoneRepository phoneRepository = new PhoneRepository();
                //TODO: Remove hardcoding for phonetype.
                PhoneType phoneType = phoneRepository.GetPhoneTypeByName(log.PhoneType);
                if (phoneType == null)
                {
                    throw new DMSException(string.Format("Phone type - {0} is not set up in the system", log.PhoneType));
                }

                contactLog.PhoneTypeID = phoneType.ID;
                // Get Contactcategory, method, type and Source

                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactType vendorType = staticDataRepo.GetTypeByName("Vendor");
                if (vendorType == null)
                {
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }

                contactLog.ContactTypeID = vendorType.ID;
                ContactMethod contactMethod = staticDataRepo.GetMethodByName("Phone");
                if (contactMethod == null)
                {
                    throw new DMSException("Contact Method - Phone is not set up in the system");
                }
                contactLog.ContactMethodID = contactMethod.ID;

                ContactCategory contactCategory = staticDataRepo.GetContactCategoryByName("ServiceLocationSelection");
                if (contactCategory == null)
                {
                    throw new DMSException("Contact Category - VendorSelection is not set up in the system");
                }

                contactLog.ContactCategoryID = contactCategory.ID;
                string source = "Internet";
                if (log.VendorID != null)
                {
                    source = "VendorData";
                }
                ContactSource contactSource = staticDataRepo.GetContactSourceByName(source, "ServiceLocationSelection");
                if (contactSource == null)
                {
                    throw new DMSException(string.Format("Contact Source - {0} for category : ServiceLocationSelection is not set up in the system", source));
                }
                contactLog.ContactSourceID = contactSource.ID;


                contactLogRepository.Save(contactLog, currentUser, serviceRequestId, EntityNames.SERVICE_REQUEST);

                #endregion

                #region 2. Create ContactLoglink records for servicerequest and vendor (if vendorlocation is found).

                if (log.VendorLocationID != null)
                {
                    contactLogRepository.CreateLinkRecord(contactLog.ID, EntityNames.VENDOR_LOCATION, log.VendorLocationID);
                }

                #endregion

                #region 3. Create ContactLogReason

                if (log.ContactReasonID != null)
                {
                    ContactLogReasonRepository contactLogReasonRepo = new ContactLogReasonRepository();
                    ContactLogReason reason = new ContactLogReason()
                    {
                        ContactLogID = contactLog.ID,
                        ContactReasonID = log.ContactReasonID.Value
                    };
                    contactLogReasonRepo.Save(reason, currentUser);
                }

                #endregion

                #region 4. Create ContactLogAction

                if (log.ContactActionID != null)
                {
                    ContactLogActionRepository logActionRepo = new ContactLogActionRepository();
                    ContactLogAction logAction = new ContactLogAction()
                    {
                        ContactLogID = contactLog.ID,
                        ContactActionID = log.ContactActionID
                    };

                    logActionRepo.Save(logAction, currentUser);
                }

                if (log.DynamicDataElements != null)
                {
                    int programDataItemId = 0;
                    foreach (var item in log.DynamicDataElements)
                    {
                        programDataItemId = 0;
                        int.TryParse(item.Key.Split('$')[1], out programDataItemId);
                        if (programDataItemId != 0)
                        {
                            ProgramMaintenanceRepository.AddDynamicDataValue(EntityNames.CONTACT_LOG, contactLog.ID, programDataItemId, item.Value, currentUser);
                        }
                    }
                }

                #endregion

                tran.Complete();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="log"></param>
        /// <param name="serviceRequestId"></param>
        /// <param name="currentUser"></param>
        public static void LogServiceTechCall(CallLog log, int? serviceRequestId, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                #region 1. Create contactLog record

                var contactLogRepository = new ContactLogRepository();
                ContactLog contactLog = new ContactLog()
                {
                    ContactSourceID = null,
                    TalkedTo = log.CallLogTalkedTo,
                    Company = log.Company,
                    PhoneTypeID = null,
                    PhoneNumber = log.PhoneNumberCalled,
                    Direction = "Outbound",
                    Comments = log.CallLogComments,
                    Description = "Contact Service Location",
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now,
                    IsPossibleCallback = false
                };

                // Get the phone Type ID
                PhoneRepository phoneRepository = new PhoneRepository();
                //TODO: Remove hardcoding for phonetype.
                PhoneType phoneType = phoneRepository.GetPhoneTypeByName(log.PhoneType);
                if (phoneType == null)
                {
                    throw new DMSException(string.Format("Phone type - {0} is not set up in the system", log.PhoneType));
                }

                contactLog.PhoneTypeID = phoneType.ID;

                ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
                ContactType vendorType = staticDataRepo.GetTypeByName("Vendor");
                if (vendorType == null)
                {
                    throw new DMSException("Contact Type - Vendor is not set up in the system");
                }

                contactLog.ContactTypeID = vendorType.ID;
                ContactMethod contactMethod = staticDataRepo.GetMethodByName("Phone");
                if (contactMethod == null)
                {
                    throw new DMSException("Contact Method - Phone is not set up in the system");
                }
                contactLog.ContactMethodID = contactMethod.ID;

                ContactCategory contactCategory = staticDataRepo.GetContactCategoryByName("ContactServiceLocation");
                if (contactCategory == null)
                {
                    throw new DMSException("Contact Category - VendorSelection is not set up in the system");
                }

                contactLog.ContactCategoryID = contactCategory.ID;
                ContactSource contactSource = staticDataRepo.GetContactSourceByName("VendorData", "ContactServiceLocation");
                if (contactSource == null)
                {
                    throw new DMSException(string.Format("Contact Source - {0} for category : ContactServiceLocation is not set up in the system", "VendorData"));
                }
                contactLog.ContactSourceID = contactSource.ID;
                contactLogRepository.Save(contactLog, currentUser, serviceRequestId, EntityNames.SERVICE_REQUEST);

                #endregion

                #region 2. Create ContactLoglink records for servicerequest and vendor (if vendorlocation is found).

                if (log.VendorLocationID != null)
                {
                    contactLogRepository.CreateLinkRecord(contactLog.ID, EntityNames.VENDOR_LOCATION, log.VendorLocationID);
                }

                #endregion

                #region 3. Create ContactLogReason

                if (log.ContactReasonID != null)
                {
                    ContactLogReasonRepository contactLogReasonRepo = new ContactLogReasonRepository();
                    ContactLogReason reason = new ContactLogReason()
                    {
                        ContactLogID = contactLog.ID,
                        ContactReasonID = log.ContactReasonID.Value
                    };
                    contactLogReasonRepo.Save(reason, currentUser);
                }

                #endregion

                #region 4. Create ContactLogAction

                if (log.ContactActionID != null)
                {
                    ContactLogActionRepository logActionRepo = new ContactLogActionRepository();
                    ContactLogAction logAction = new ContactLogAction()
                    {
                        ContactLogID = contactLog.ID,
                        ContactActionID = log.ContactActionID
                    };

                    logActionRepo.Save(logAction, currentUser);
                }

                if (log.DynamicDataElements != null)
                {
                    int programDataItemId = 0;
                    foreach (var item in log.DynamicDataElements)
                    {
                        programDataItemId = 0;
                        int.TryParse(item.Key, out programDataItemId);
                        if (programDataItemId != 0)
                        {
                            ProgramMaintenanceRepository.AddDynamicDataValue(EntityNames.CONTACT_LOG, contactLog.ID, programDataItemId, item.Value, currentUser);
                        }
                    }
                }

                #endregion

                tran.Complete();
            }
        }


        public static List<Question> GetProgramDataItems(int programID, string screenName)
        {
            var listOfQuestions = new List<Question>();
            // Now for all those active tabs, load the questions and answers too.
            ServiceRepository repository = new ServiceRepository();
            var questions = repository.GetProgramDataItemsForProgram(programID, screenName);
            var answers = repository.GetProgramDataItemAnswers(programID, screenName);


            questions.ForEach(q =>
            {
                // Build the question
                Question question = new Question()
                {
                    ProductCategoryQuestionId = q.QuestionID.GetValueOrDefault(),
                    ControlType = (DynamicFieldsControlType)Enum.Parse(typeof(DynamicFieldsControlType), q.ControlType),
                    DataType = (DynamicFieldsDataType)Enum.Parse(typeof(DynamicFieldsDataType), q.DataType),
                    AnswerToTriggerRelatedQuestion = q.RelatedAnswer,
                    RelatedQuestionId = q.SubQuestionID,
                    Text = q.QuestionText,
                    IsRequired = q.IsRequired ?? false,
                    Sequence = q.Sequence
                };

                // Fill answers if the control type is a dropdown or a combobox.
                if (question.ControlType == DynamicFieldsControlType.Combobox || question.ControlType == DynamicFieldsControlType.Dropdown)
                {
                    var answersForQuestion = answers.Where(a => a.ProgramDataItemID == question.ProductCategoryQuestionId).OrderBy(a => a.Sequence).ToList<ProgramDataItemAnswers_Result>();
                    List<Answer> dropdownValues = new List<Answer>();
                    answersForQuestion.ForEach(a =>
                    {
                        Answer val = new Answer();
                        val.QuestionID = question.ProductCategoryQuestionId;
                        val.Name = a.Value;
                        val.Value = a.Value;

                        dropdownValues.Add(val);
                    });
                    question.DropDownValues = dropdownValues;
                }
                // Add the question to the list of questions under the service tab.
                listOfQuestions.Add(question);

            });

            return listOfQuestions;
        }
    }
}
