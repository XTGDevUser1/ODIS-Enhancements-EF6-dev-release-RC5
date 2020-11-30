using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Model;
using Martex.DMS.Areas.Application.Models;
using System.Transactions;
using Martex.DMS.DAO;
using System.Xml;
using Martex.DMS.DAL.Common;
using log4net;
using Martex.DMS.BLL.DataValidators;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.BLL.Facade
{
    public class ServiceFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ServiceFacade));

        protected List<ServiceElibilityMessages_Result> serviceEligibilityMessages;
        #endregion

        #region Public Methods
        /// <summary>
        /// Updates the service request.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <param name="programID">The program ID.</param>
        /// <param name="isSMSAvailable">if set to <c>true</c> [is SMS available].</param>
        /// <param name="secondaryCategoryID">The secondary category identifier.</param>
        public void UpdateServiceRequest(ServiceRequest model, string userName, int? vehicleTypeID, int programID, bool isSMSAvailable, int? secondaryCategoryID, int? memberID, int? productID, int? caseID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ServiceRepository repository = new ServiceRepository();

                var hasBusinessExceptions = CallFacade.GetAllExceptions(model.ID, RequestArea.SERVICE).Count > 0;
                if (hasBusinessExceptions)
                {
                    logger.InfoFormat("SR {0} already has business errors", model.ID);
                    model.ServiceTabStatus = (int)TabValidationStatus.VISITED_WITH_ERRORS;
                }
                repository.UpdateServiceRequest(model, userName, vehicleTypeID, programID);
                UpdateServiceEligibility(memberID, programID, model.ProductCategoryID, productID, vehicleTypeID, model.VehicleCategoryID, secondaryCategoryID, model.ID, caseID, userName, SourceSystemName.DISPATCH);
                //CaseRepository caseRepository = new CaseRepository();
                //caseRepository.SetSMSAvailable(model.CaseID, isSMSAvailable);

                tran.Complete();
            }
        }

        /// <summary>
        /// Saves the specified list.
        /// </summary>
        /// <param name="list">The list.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        public void Save(List<NameValuePair> list, string userName, int serviceRequestID, int? vehicleTypeID)
        {
            ServiceRepository repository = new ServiceRepository();
            repository.Save(serviceRequestID, userName, GetXmlForNameValuePair(list), vehicleTypeID);
        }

        /// <summary>
        /// Gets the questionnaire.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="vehicleCategoryId">The vehicle category id.</param>
        /// <param name="vehicleTypeId">The vehicle type id.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<ServiceTab> GetQuestionnaire(int programId, int? vehicleCategoryId, int? vehicleTypeId, int? serviceRequestID, string sourceSystemName = SourceSystemName.DISPATCH)
        {
            var progRepository = new ProgramMaintenanceRepository();
            var programConfig = progRepository.GetProgramInfo(programId, "service", "rule");
            var lamborghiniDefaultForTow = programConfig.Where(x => x.Name == "DeafultSpecialTowType").FirstOrDefault();

            ServiceRepository repository = new ServiceRepository();
            var productCategories = repository.GetProductCategoriesForProgram(programId, vehicleCategoryId, vehicleTypeId);
            List<ServiceTab> serviceTabs = new List<ServiceTab>();
            productCategories.ForEach(x =>
                {
                    //KB: Hide Repair and Billing
                    if (!"Repair".Equals(x.Name, StringComparison.InvariantCultureIgnoreCase) && !"Billing".Equals(x.Name, StringComparison.InvariantCultureIgnoreCase))
                    {
                        serviceTabs.Add(new ServiceTab()
                        {
                            ProductCategoryID = x.ID,
                            ProductCategoryName = x.Name,
                            IsEnabled = x.Enabled,
                            Questions = new List<Question>(),
                            IsVehicleRequired = x.IsVehicleRequired
                        });
                    }
                });


            // Now for all those active tabs, load the questions and answers too.
            var questions = repository.GetQuestionsForProgram(programId, vehicleCategoryId, vehicleTypeId, serviceRequestID, sourceSystemName);
            var answers = repository.GetQuestionAnswerValues(programId, vehicleCategoryId, vehicleTypeId, sourceSystemName);

            serviceTabs.ForEach(s =>
                {

                    var questionsForService = questions.Where(q => q.ProductCategoryID == s.ProductCategoryID).OrderBy(o => o.Sequence).ToList<QuestionsForProductCategory_Result>();
                    questionsForService.ForEach(q =>
                        {
                            // Build the question
                            Question question = new Question()
                            {
                                ControlType = (DynamicFieldsControlType)Enum.Parse(typeof(DynamicFieldsControlType), q.ControlType),
                                DataType = (DynamicFieldsDataType)Enum.Parse(typeof(DynamicFieldsDataType), q.DataType),
                                AnswerToTriggerRelatedQuestion = q.RelatedAnswer,
                                RelatedQuestionId = q.SubQuestionID,
                                ProductCategoryQuestionId = q.ProductCategoryQuestionID.Value,
                                Text = q.QuestionText,
                                HelpText = q.HelpText,
                                IsRequired = q.IsRequired ?? false,
                                Sequence = q.Sequence,
                                AnswerValue = q.AnswerValue ?? string.Empty,
                                IsEnabled = q.IsEnabled ?? false,
                                VehicleCategoryId = q.VehicleCategoryID
                            };

                            // Fill answers if the control type is a dropdown or a combobox.
                            if (question.ControlType == DynamicFieldsControlType.Combobox || question.ControlType == DynamicFieldsControlType.Dropdown || question.ControlType == DynamicFieldsControlType.Radio)
                            {
                                var answersForQuestion = answers.Where(a => a.ProductCategoryQuestionID == question.ProductCategoryQuestionId).OrderBy(a => a.Sequence).ToList<QuestionAnswerValues_Result>();
                                List<Answer> dropdownValues = new List<Answer>();
                                answersForQuestion.ForEach(a =>
                                    {
                                        Answer val = new Answer();
                                        val.QuestionID = question.ProductCategoryQuestionId;
                                        val.Name = a.Value;
                                        val.Value = a.Value;
                                        val.IsPossibleTow = a.IsPossibleTow ?? false;

                                        dropdownValues.Add(val);
                                    });
                                question.DropDownValues = dropdownValues;
                            }

                            // TFS 1454 : Service Tab - Tow Tab: default "Special Type of Tow" to "Lamborghini Tow" for certain programs
                            if (question.Text.Equals("Special Type of Tow?", StringComparison.InvariantCultureIgnoreCase))
                            {
                                logger.Info("Processing question - Special Type of Tow ?");
                                if (lamborghiniDefaultForTow != null)
                                {
                                    logger.Info("ProgramConfiguration has an a default answer defined");
                                    if (string.IsNullOrEmpty(question.AnswerValue))
                                    {
                                        logger.InfoFormat("Setting the default answer to {0}", lamborghiniDefaultForTow.Value);
                                        question.AnswerValue = lamborghiniDefaultForTow.Value;
                                    }
                                }
                            }

                            // Add the question to the list of questions under the service tab.
                            s.Questions.Add(question);

                        });
                });

            return serviceTabs;

        }

        /// <summary>
        /// Gets the service tech details.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        public ServiceTechModel GetServiceTechDetails(int recordID, string entityName, int programID)
        {
            CommentRepository commentRepository = new CommentRepository();
            List<Comment> previousComments = commentRepository.Get(recordID, entityName);

            ServiceTechModel model = new ServiceTechModel();
            model.PreviousComments = previousComments;

            ServiceRepository serviceRepository = new ServiceRepository();
            model.DiagnosticCodes = serviceRepository.GetDiagnosticCodes(recordID);

            #region TFS 616
            logger.InfoFormat("Checking Program Configuration for Program ID {0} Name {1}", programID, "TrackRepairStatus");
            ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
            var programConfigurationList = programMaintenanceRepository.GetProgramInfo(programID, "Service", "Rule");

            model.TrackRepairStatus = programConfigurationList.Where(x => (x.Name.Equals("TrackRepairStatus", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault() != null;
            if (model.TrackRepairStatus)
            {
                logger.InfoFormat("TrackRepairStatus is configured for Program ID {0}", programID);
                model.RepairLocationDetails = serviceRepository.GetServiceTechRepairLocationDetails(recordID);
            }
            else
            {
                logger.InfoFormat("TrackRepairStatus is not configured for Program ID {0}", programID);
            }
            #endregion

            return model;
        }

        /// <summary>
        /// Saves the diagnostic codes.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="selectedCodes">The selected codes.</param>
        /// <param name="codeType">Type of the code.</param>
        /// <param name="primaryCode">The primary code.</param>
        /// <param name="createBy">The create by.</param>
        public void SaveDiagnosticCodes(int serviceRequestID, string selectedCodes, string codeType, int? primaryCode, string createBy)
        {
            var serviceRepository = new ServiceRepository();
            serviceRepository.SaveDiagnosticCodes(serviceRequestID, selectedCodes, codeType, primaryCode, createBy);
        }

        /// <summary>
        /// Gets the service request by id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public ServiceRequest GetServiceRequestById(int id)
        {
            return new ServiceRepository().GetServiceRequestById(id);
        }

        /// <summary>
        /// Gets the primary product.
        /// </summary>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <returns></returns>
        public Product GetPrimaryProduct(int serviceRequestId)
        {
            return new ServiceRepository().GetPrimaryProduct(serviceRequestId);
        }

        /// <summary>
        /// Sets the is dispatch threshold reached.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        public void SetIsDispatchThresholdReached(int serviceRequestID)
        {
            ServiceRequestRepository repository = new ServiceRequestRepository();
            repository.SetIsDispatchThresholdReached(serviceRequestID);
        }

        /// <summary>
        /// Gets the service limits.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="vehicleCategoryId">The vehicle category id.</param>
        /// <returns></returns>
        public List<ServiceLimits_Result> GetServiceLimits(int programId, int vehicleCategoryId)
        {
            ServiceRepository repository = new ServiceRepository();
            return repository.GetServiceLimits(programId, vehicleCategoryId);
        }

        /// <summary>
        /// Gets the service request history.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <param name="loggeduser">The loggeduser.</param>
        /// <param name="list">The list.</param>
        /// <returns></returns>
        public List<ServiceRequestHistoryList_Result> GetServiceRequestHistory(PageCriteria criteria, Guid loggeduser, List<NameValuePair> list)
        {
            ServiceRepository repository = new ServiceRepository();
            criteria.WhereClause = BuildHistoryFilter(list);
            return repository.GetServiceRequestHistory(criteria, loggeduser);
        }

        /// <summary>
        /// Gets the dashborad service request count.
        /// </summary>
        /// <returns></returns>
        public List<DashboardServiceRequestCount_Result> GetDashboradServiceRequestCount()
        {
            ServiceRepository repository = new ServiceRepository();
            return repository.GetDashboradServiceRequestCount();
        }

        /// <summary>
        /// Gets the service eligibility model.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="programID">The program identifier.</param>
        /// <param name="productCategoryID">The product category identifier.</param>
        /// <param name="productID">The product identifier.</param>
        /// <param name="vehicleTypeID">The vehicle type identifier.</param>
        /// <param name="vehicleCategoryID">The vehicle category identifier.</param>
        /// <param name="secondaryCategoryID">The secondary category identifier.</param>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <returns></returns>
        public ServiceEligibilityModel GetServiceEligibilityModel(int? programID, int? productCategoryID, int? productID, int? vehicleTypeID, int? vehicleCategoryID, int? secondaryCategoryID, int? serviceRequestID, int? caseID, string sourceSystemName, bool isOverride = false, bool isPrimaryOverride = false)
        {
            logger.InfoFormat("Calling benefit and limit sps with the following parameters : ProgramID - {0}, ProductCategoryID - {1}, ProductID - {2}, VehicleTypeID - {3}, Vehicle CategoryID - {4}, SecondaryCategoryID - {5}, SR ID - {6}, Case ID - {7}, isOverride = {8}", programID, productCategoryID, productID, vehicleTypeID, vehicleCategoryID, secondaryCategoryID, serviceRequestID, caseID, isOverride);
            var programRepository = new ProgramMaintenanceRepository();
            var program = programRepository.Get(programID.GetValueOrDefault());
            ServiceRepository repository = new ServiceRepository();
            CaseRepository caseRepository = new CaseRepository();
            ServiceEligibilityModel model = new ServiceEligibilityModel();
            if (string.IsNullOrWhiteSpace(sourceSystemName))
            {
                sourceSystemName = SourceSystemName.DISPATCH;
            }
            // Cache the DSE Messages
            if (serviceEligibilityMessages == null)
            {
                //TODO: Expect SourceSystem as a parameter.
                serviceEligibilityMessages = repository.GetServiceEligibilityMessages(programID.GetValueOrDefault(), sourceSystemName);
            }

            if (program != null && program.Client != null)
            {
                model.IsFordProgram = "Ford".Equals(program.Client.Name, StringComparison.InvariantCultureIgnoreCase);
            }

            model.HasMemberEligibilityApplies = false;
            ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
            var mResult = programMaintenanceRepository.GetProgramInfo(programID, "Service", "Validation");
            var memberEligibilityApplies = mResult.Where(x => (x.Name.Equals("MemberEligibilityApplies", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (memberEligibilityApplies != null)
            {
                model.HasMemberEligibilityApplies = true;
            }

            if (!isOverride)
            {
                model.ProgramServiceEventLimit = repository.GetVerifyProgramServiceEventLimit(serviceRequestID, programID, productCategoryID, productID, vehicleTypeID, vehicleCategoryID, secondaryCategoryID);
            }
            model.ServiceBenefit = repository.GetVerifyProgramServiceBenefit(programID, productCategoryID, vehicleCategoryID, vehicleTypeID, secondaryCategoryID, serviceRequestID, productID, isPrimaryOverride);

            if (isOverride)
            {
                model.CaseDetailsIsVehicleEligible = true;
                model.HasWarrantyApplies = false;
                model.CaseDetailsMemberStatus = "Active";
            }
            else
            {
                Case caseDetails = caseRepository.GetCaseById(caseID.GetValueOrDefault());

                if (caseDetails != null)
                {
                    model.CaseDetailsIsVehicleEligible = caseDetails.IsVehicleEligible;
                    model.CaseDetailsMemberStatus = caseDetails.MemberStatus;
                }

                //ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
                var result = programMaintenanceRepository.GetProgramInfo(programID, "Vehicle", "Validation");
                bool vehicleWarrantyApplies = false;
                var item = result.Where(x => (x.Name.Equals("WarrantyApplies", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                if (item != null)
                {
                    vehicleWarrantyApplies = true;
                }

                model.HasWarrantyApplies = vehicleWarrantyApplies;
            }

            VerifyProgramServiceBenefit_Result primaryVPB = null;
            VerifyProgramServiceBenefit_Result secondaryVPB = null;
            VerifyProgramServiceEventLimit_Result primaryVPL = null;
            VerifyProgramServiceEventLimit_Result secondaryVPL = null;


            if (model != null)
            {
                if (model.ServiceBenefit.Count > 0)
                {
                    primaryVPB = model.ServiceBenefit.Where(x => x.IsPrimary == 1).FirstOrDefault();
                    secondaryVPB = model.ServiceBenefit.Where(x => x.IsPrimary == 0).FirstOrDefault();
                }

                if (model.ProgramServiceEventLimit != null && model.ProgramServiceEventLimit.Count > 0)
                {
                    primaryVPL = model.ProgramServiceEventLimit.Where(x => x.IsPrimary == 1).FirstOrDefault();
                    secondaryVPL = model.ProgramServiceEventLimit.Where(x => x.IsPrimary == 0).FirstOrDefault();
                }

                // Consider Primary
                ProcessServiceEligibility(model, primaryVPB, primaryVPL, true);

                // Consider Secondary                
                ProcessServiceEligibility(model, secondaryVPB, secondaryVPL, false);

                logger.InfoFormat("Eligibility evaluated to be as : {0}", model.ToString());
            }

            return model;
        }

        /// <summary>
        /// Gets the message.
        /// </summary>
        /// <param name="vpb">The VPB.</param>
        /// <param name="vpl">The VPL.</param>
        /// <returns></returns>
        private string GetMessage(ServiceEligibilityModel model, VerifyProgramServiceBenefit_Result vpb, VerifyProgramServiceEventLimit_Result vpl, bool isPrimary)
        {
            const string SERVICE_COVERAGE_LIMIT = "ServiceCoverageLimit";
            const string CURRENCY = "Currency";
            const string SERVICE_MILEAGE_LIMIT_UOM = "ServiceMileageLimitUOM";
            const string SERVICE_MILEAGE_LIMIT = "ServiceMileageLimit";
            const string MESSAGE = "Message";
            const string LIMIT_DESCRIPTION = "LimitDescription";
            const string EVENT_COUNT = "EventCount";
            bool isBestValue = false;

            Hashtable dseData = new Hashtable();
            dseData.Add(SERVICE_COVERAGE_LIMIT, vpb != null ? vpb.ServiceCoverageLimit.GetValueOrDefault().ToString("N0") : string.Empty);
            dseData.Add(CURRENCY, model.CurrencyTypeName.BlankIfNull());
            dseData.Add(SERVICE_MILEAGE_LIMIT_UOM, vpb != null ? vpb.ServiceMileageLimitUOM : string.Empty);
            dseData.Add(SERVICE_MILEAGE_LIMIT, vpb != null ? vpb.ServiceMileageLimit.GetValueOrDefault().ToString("N0") : string.Empty);
            dseData.Add(MESSAGE, string.Empty);
            dseData.Add(LIMIT_DESCRIPTION, vpl != null ? vpl.Description : string.Empty);
            dseData.Add(EVENT_COUNT, vpl != null ? vpl.EventCount.ToString() : string.Empty);

            string message = string.Empty;
            //NP 8/21: TFS 439: Considering "MemberEligibilityApplies" from ProgramConfiguration for the program.
            if (model.HasMemberEligibilityApplies.GetValueOrDefault() && (!"Active".Equals(model.CaseDetailsMemberStatus, StringComparison.InvariantCultureIgnoreCase)))
            {
                message = PrepareMessage(ServiceEligibilityMessages.MEMBER_INACTIVE, dseData);//"Member Inactive";
                model.IsPrimaryOverallCovered = model.IsSecondaryOverallCovered = false;
            }
            else if (model.HasWarrantyApplies.GetValueOrDefault() && !(model.CaseDetailsIsVehicleEligible.GetValueOrDefault()))
            {
                message = PrepareMessage(ServiceEligibilityMessages.VEHICLE_OUT_OF_WARRANTY, dseData); //"Vehicle Out of Warranty";
                model.IsPrimaryOverallCovered = model.IsSecondaryOverallCovered = false;
            }
            else if (vpb == null)
            {
                message = PrepareMessage(ServiceEligibilityMessages.UNDETERMINED, dseData);  //"Undetermined";
            }
            else
            {

                if (vpb.IsServiceEligible == 1 && (vpl == null || vpl.IsEligible == 1))
                {
                    if (vpb.IsServiceCoverageBestValue.GetValueOrDefault() && vpb.IsReimbursementOnly.GetValueOrDefault())
                    {
                        message = PrepareMessage(ServiceEligibilityMessages.BEST_VALUE_REIMBURSEMENT_ONLY, dseData); // "Reimbursement Only – Best Value";
                    }
                    else if (vpb.IsServiceCoverageBestValue.GetValueOrDefault())
                    {
                        message = PrepareMessage(ServiceEligibilityMessages.BEST_VALUE, dseData); // "Best Value";
                        isBestValue = true;
                    }
                    else if (vpb.ServiceCoverageLimit > 0 && !vpb.IsReimbursementOnly.GetValueOrDefault())
                    {
                        //message = string.Format("${0} {1} Limit", vpb.ServiceCoverageLimit.GetValueOrDefault().ToString("N0"), model.CurrencyTypeName);
                        message = PrepareMessage(ServiceEligibilityMessages.COVERAGE_LIMIT, dseData);
                    }
                    else if (vpb.ServiceCoverageLimit > 0 && vpb.IsReimbursementOnly.GetValueOrDefault())
                    {
                        //message = string.Format("'Reimbursement Only - ${0} {1}  Limit", vpb.ServiceCoverageLimit.GetValueOrDefault().ToString("N0"), model.CurrencyTypeName);
                        message = PrepareMessage(ServiceEligibilityMessages.COVERAGE_LIMIT_REIMBURSEMENT_ONLY, dseData);
                    }
                    else if (vpb.ServiceCoverageLimit == 0 && !vpb.IsReimbursementOnly.GetValueOrDefault() && (vpb.ServiceMileageLimit == null || vpb.ServiceMileageLimit == 0))
                    {
                        message = PrepareMessage(ServiceEligibilityMessages.ASSIST_ONLY, dseData); //"Assist Only";
                    }
                    else if (vpb.ServiceCoverageLimit == 0 && vpb.IsReimbursementOnly.GetValueOrDefault() && (vpb.ServiceMileageLimit == null || vpb.ServiceMileageLimit == 0))
                    {
                        message = PrepareMessage(ServiceEligibilityMessages.ASSIST_REIMBURSEMENT, dseData);  //"'Reimbursement Only - Provide Assistance";
                    }
                    else
                    {
                        message = vpb.ServiceCoverageDescription;
                    }

                    dseData[MESSAGE] = message;

                    if (vpb.ServiceMileageLimit > 0)
                    {
                        if (vpb.IsServiceCoverageBestValue.GetValueOrDefault())
                        {
                            if (vpb.IsReimbursementOnly.GetValueOrDefault())
                            {
                                //message = string.Format("Reimbursement Only – {0} {1} Limit", vpb.ServiceMileageLimit.GetValueOrDefault().ToString("N0"), vpb.ServiceMileageLimitUOM);
                                message = PrepareMessage(ServiceEligibilityMessages.BEST_VALUE_REIMBURSEMENT_ONLY_MILEAGE_LIMIT, dseData);
                            }
                            else
                            {
                                //message = string.Format("{0} {1} Limit", vpb.ServiceMileageLimit.GetValueOrDefault().ToString("N0"), vpb.ServiceMileageLimitUOM);
                                message = PrepareMessage(ServiceEligibilityMessages.BEST_VALUE_MILEAGE_LIMIT, dseData);
                            }
                        }
                        else
                        {
                            if (vpb.IsReimbursementOnly.GetValueOrDefault())
                            {
                                //message = string.Format("Reimbursement Only – {0} {1} Limit", vpb.ServiceMileageLimit.GetValueOrDefault().ToString("N0"), vpb.ServiceMileageLimitUOM);
                                message = PrepareMessage(ServiceEligibilityMessages.COVERAGE_LIMIT_REIMBURSEMENT_ONLY_MILEAGE_LIMIT, dseData);
                            }
                            else
                            {
                                //message = string.Format("{0} {1} Limit", vpb.ServiceMileageLimit.GetValueOrDefault().ToString("N0"), vpb.ServiceMileageLimitUOM);
                                message = PrepareMessage(ServiceEligibilityMessages.COVERAGE_LIMIT_MILEAGE_LIMIT, dseData);
                            }
                        }

                        //TFS: 406
                        if (model.IsFordProgram)
                        {
                            message = string.Format("{0} or NQR", message);
                        }
                    }

                }
                else if (vpb.IsServiceEligible == 1 && (vpl != null && vpl.IsEligible == 0))
                {
                    //message = string.Format("{0} No coverage - Over Service Count Limit; {1}{2} Current Service Count = {3}", message, vpl.Description, (!string.IsNullOrEmpty(vpl.Description) ? ";" : string.Empty), vpl.EventCount);
                    message = PrepareMessage(ServiceEligibilityMessages.COVERAGE_LIMIT_EXCEEDED, dseData);
                }
                else if (vpb.IsServiceEligible == 0) //TFS: 902
                {
                    //message = "No coverage - Member pays full amount plus applicable dispatch service fee";   
                    message = PrepareMessage(ServiceEligibilityMessages.MEMBER_PAY, dseData);
                }
                else
                {
                    //message = "Undetermined";
                    message = PrepareMessage(ServiceEligibilityMessages.UNDETERMINED, dseData);
                }

            }

            if ((string.IsNullOrEmpty(message) && !isBestValue) || "Undetermined".Equals(message, StringComparison.InvariantCultureIgnoreCase))
            {
                //message = "Undetermined";
                message = PrepareMessage(ServiceEligibilityMessages.UNDETERMINED, dseData);
                if (isPrimary)
                {
                    model.IsPrimaryOverallCovered = null;
                }
                else
                {
                    model.IsSecondaryOverallCovered = null;
                }
            }

            return message;
        }

        /// <summary>
        /// Prepares the message.
        /// </summary>
        /// <param name="messageKey">The message key.</param>
        /// <param name="dseData">The dse data.</param>
        /// <returns></returns>
        private string PrepareMessage(string messageKey, Hashtable dseData)
        {
            string message;
            var template = serviceEligibilityMessages.Where(x => x.Name == messageKey).FirstOrDefault();
            message = TemplateUtil.ProcessTemplate(template.Message, dseData);
            return message;
        }

        /// <summary>
        /// Processes the service eligibility.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="vpb">The VPB.</param>
        /// <param name="vpl">The VPL.</param>
        /// <param name="isPrimary">if set to <c>true</c> [is primary].</param>
        private void ProcessServiceEligibility(ServiceEligibilityModel model, VerifyProgramServiceBenefit_Result vpb, VerifyProgramServiceEventLimit_Result vpl, bool isPrimary)
        {
            var vehicleWarrantyApplies = model.HasWarrantyApplies.GetValueOrDefault();
            var memberEligibilityApplies = model.HasMemberEligibilityApplies.GetValueOrDefault();

            logger.InfoFormat(" Processing {0} VPB and VPL details", isPrimary ? "Primary" : "Secondary");
            logger.InfoFormat("VPB is not null - {0}, VPL is not null - {1}", (vpb != null), (vpl != null));

            if (vpb != null)
            {
                if (isPrimary)
                {
                    // Benefit is available and there is no limit or limit is acceptable.
                    if (vpb.IsServiceEligible == 1 && (vpl == null || vpl.IsEligible == 1))
                    {
                        model.IsPrimaryProductCovered = true;
                    }
                    else
                    {
                        model.IsPrimaryProductCovered = false;
                    }
                    model.PrimaryCoverageLimit = vpb.ServiceCoverageLimit;
                    model.PrimaryCoverageLimitMileage = vpb.ServiceMileageLimit;
                    string descriptionlimiter = "";
                    string vplDescription = string.Empty;
                    if (vpb.ServiceCoverageDescription != null && vpl != null && vpl.Description != null)
                    {
                        descriptionlimiter = "|";
                        vplDescription = vpl.Description;
                    }
                    model.PrimaryServiceCoverageDescription = vpb.ServiceCoverageDescription + descriptionlimiter + vplDescription;


                    model.CurrencyTypeID = vpb.CurrencyTypeID;

                    // Get the currencytype name as well.
                    var currencyTypes = ReferenceDataRepository.GetCurrencyTypes();
                    var currencyType = currencyTypes.Where(x => x.ID == model.CurrencyTypeID).FirstOrDefault();
                    if (currencyType != null)
                    {
                        model.CurrencyTypeName = currencyType.Abbreviation;
                    }
                    model.MileageUOM = vpb.ServiceMileageLimitUOM;
                    model.IsServiceGuaranteed = vpb.IsServiceGuaranteed;
                    model.IsReimbursementOnly = vpb.IsReimbursementOnly;
                    model.IsServiceCoverageBestValue = vpb.IsServiceCoverageBestValue;

                    if (vpl != null)
                    {
                        model.ProgramServiceEventLimitID = vpl.ID;
                    }
                    //NP 8/21: TFS 439: Considering "MemberEligibilityApplies" from ProgramConfiguration for the program.
                    if ((!memberEligibilityApplies || (memberEligibilityApplies && "Active".Equals(model.CaseDetailsMemberStatus, StringComparison.InvariantCultureIgnoreCase))) &&
                            (!vehicleWarrantyApplies || (vehicleWarrantyApplies && model.CaseDetailsIsVehicleEligible.GetValueOrDefault())) &&
                            (vpb.IsPrimary == 1 && vpb.IsServiceEligible == 1) &&
                             (vpl == null || (vpl.IsPrimary == 1 && vpl.IsEligible == 1)))
                    {
                        model.IsPrimaryOverallCovered = true;
                    }
                    else
                    {
                        model.IsPrimaryOverallCovered = false;
                    }
                }
                else
                {
                    // Benefit is available and there is no limit or limit is acceptable.
                    if (vpb.IsServiceEligible == 1 && (vpl == null || vpl.IsEligible == 1))
                    {
                        model.IsSecondaryProductCovered = true;
                    }
                    else
                    {
                        model.IsSecondaryProductCovered = false;
                    }
                    model.SecondaryCoverageLimit = vpb.ServiceCoverageLimit;
                    model.SecondaryCoverageLimitMileage = vpb.ServiceMileageLimit;
                    string descriptionlimiter = "";
                    string vplDescription = string.Empty;
                    if (vpb.ServiceCoverageDescription != null && vpl != null && vpl.Description != null)
                    {
                        descriptionlimiter = "|";
                        vplDescription = vpl.Description;
                    }
                    model.SecondaryServiceCoverageDescription = vpb.ServiceCoverageDescription + descriptionlimiter + vplDescription;
                    //NP 8/21: TFS 439: Considering "MemberEligibilityApplies" from ProgramConfiguration for the program.
                    if ((!memberEligibilityApplies || (memberEligibilityApplies && "Active".Equals(model.CaseDetailsMemberStatus, StringComparison.InvariantCultureIgnoreCase))) &&
                            (!vehicleWarrantyApplies || (vehicleWarrantyApplies && model.CaseDetailsIsVehicleEligible.GetValueOrDefault())) &&
                            (vpb.IsPrimary == 0 && vpb.IsServiceEligible == 1) &&
                             (vpl == null || (vpl.IsPrimary == 0 && vpl.IsEligible == 1)))
                    {
                        model.IsSecondaryOverallCovered = true;
                    }
                    else
                    {
                        model.IsSecondaryOverallCovered = false;
                    }

                }// Is Primary
            } // VPB null check

            if (isPrimary)
            {
                model.PrimaryServiceEligiblityMessage = GetMessage(model, vpb, vpl, isPrimary);
            }
            else
            {
                model.SecondaryServiceEligiblityMessage = GetMessage(model, vpb, vpl, isPrimary);
            }
        }

        /// <summary>
        /// Updates the service eligibility.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="programID">The program identifier.</param>
        /// <param name="productCategoryID">The product category identifier.</param>
        /// <param name="productID">The product identifier.</param>
        /// <param name="vehicleTypeID">The vehicle type identifier.</param>
        /// <param name="vehicleCategoryID">The vehicle category identifier.</param>
        /// <param name="secondaryCategoryID">The secondary category identifier.</param>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="caseID">The case identifier.</param>
        /// <param name="userName">Name of the user.</param>
        public void UpdateServiceEligibility(int? memberID, int? programID, int? productCategoryID, int? productID, int? vehicleTypeID, int? vehicleCategoryID, int? secondaryCategoryID, int? serviceRequestID, int? caseID, string userName, string sourceSystemName)
        {
            logger.Info("Determine service eligibility");
            if (productCategoryID == null)
            {
                return;

            }
            else
            {
                ProductCategory pc = ReferenceDataRepository.GetProductCategoryById(productCategoryID.GetValueOrDefault());
                if (!"Home Locksmith".Equals(pc.Name, StringComparison.InvariantCultureIgnoreCase))
                {
                    if (vehicleTypeID == null)
                    {
                        return;
                    }
                }
            }

            var existingSR = GetServiceRequestById(serviceRequestID.GetValueOrDefault());
            if (existingSR != null && ("Complete".Equals(existingSR.ServiceRequestStatu.Name, StringComparison.InvariantCultureIgnoreCase) ||
                                        "Cancelled".Equals(existingSR.ServiceRequestStatu.Name, StringComparison.InvariantCultureIgnoreCase)
                                        ))
            {
                logger.InfoFormat("Not executing DSE as the status of the SR {0} is {1}", serviceRequestID, existingSR.ServiceRequestStatu.Name);
                return;
            }

            ServiceRepository repository = new ServiceRepository();
            ServiceRequest model = new ServiceRequest();
            model.ID = serviceRequestID.GetValueOrDefault();

            ServiceEligibilityModel serviceModel = GetServiceEligibilityModel(programID, productCategoryID, productID, vehicleTypeID, vehicleCategoryID, secondaryCategoryID, serviceRequestID, caseID, sourceSystemName);

            model.IsSecondaryOverallCovered = serviceModel.IsSecondaryOverallCovered;
            model.IsSecondaryProductCovered = serviceModel.IsSecondaryProductCovered;
            model.SecondaryCoverageLimit = serviceModel.SecondaryCoverageLimit;
            model.SecondaryCoverageLimitMileage = serviceModel.SecondaryCoverageLimitMileage;
            model.SecondaryServiceCoverageDescription = serviceModel.SecondaryServiceCoverageDescription;
            model.SecondaryServiceEligiblityMessage = serviceModel.SecondaryServiceEligiblityMessage;

            model.IsPrimaryOverallCovered = serviceModel.IsPrimaryOverallCovered;
            model.IsPrimaryProductCovered = serviceModel.IsPrimaryProductCovered;
            model.PrimaryCoverageLimit = serviceModel.PrimaryCoverageLimit;
            model.PrimaryCoverageLimitMileage = serviceModel.PrimaryCoverageLimitMileage;
            model.PrimaryServiceCoverageDescription = serviceModel.PrimaryServiceCoverageDescription;
            model.PrimaryServiceEligiblityMessage = serviceModel.PrimaryServiceEligiblityMessage;

            model.IsServiceGuaranteed = serviceModel.IsServiceGuaranteed;
            model.IsReimbursementOnly = serviceModel.IsReimbursementOnly;
            model.IsServiceCoverageBestValue = serviceModel.IsServiceCoverageBestValue;
            model.ProgramServiceEventLimitID = serviceModel.ProgramServiceEventLimitID;

            model.CurrencyTypeID = serviceModel.CurrencyTypeID;

            model.MileageUOM = serviceModel.MileageUOM;

            model.IsPrimaryOverallCovered = serviceModel.IsPrimaryOverallCovered;
            model.IsSecondaryOverallCovered = serviceModel.IsSecondaryOverallCovered;

            repository.UpdateServiceEligibility(model, userName);

        }


        /// <summary>
        /// Services the tech call history.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <returns></returns>
        public List<ServiceTechCallHistory_Result> ServiceTechCallHistory(int serviceRequestID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetServiceTechCallHistory(serviceRequestID).ToList<ServiceTechCallHistory_Result>();
            }
        }

        public void UpdateNextActionAndAssignedTo(int serviceRequestID, string nextAction, string nextActionAssignedTo, DateTime? nextActionScheduledDate, string eventSource, string sessionID, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                var serviceRequestRepository = new ServiceRequestRepository();
                serviceRequestRepository.UpdateNextActionDetails(serviceRequestID, nextAction, nextActionScheduledDate, nextActionAssignedTo, eventSource, sessionID, currentUser);
                tran.Complete();
            }
        }
        #endregion

        #region Private Methods
        /// <summary>
        /// Gets the XML for name value pair.
        /// </summary>
        /// <param name="list">The list.</param>
        /// <returns></returns>
        private string GetXmlForNameValuePair(List<NameValuePair> list)
        {
            StringBuilder sbParams = new StringBuilder();

            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(sbParams, settings))
            {
                writer.WriteStartElement("ROW");
                if (list != null)
                {
                    foreach (NameValuePair item in list)
                    {
                        writer.WriteStartElement("Data");
                        writer.WriteAttributeString("ProductCategoryQuestionID", item.Name);
                        writer.WriteAttributeString("Answer", item.Value);
                        writer.WriteEndElement();
                    }
                }
                writer.WriteEndElement();
                writer.Close();
            }
            return sbParams.ToString();
        }

        /// <summary>
        /// Builds the history filter.
        /// </summary>
        /// <param name="list">The list.</param>
        /// <returns></returns>
        private string BuildHistoryFilter(List<NameValuePair> list)
        {
            string returnValue = string.Empty;
            if (list.Count > 0)
            {
                StringBuilder sbParams = new StringBuilder();

                XmlWriterSettings settings = new XmlWriterSettings();
                settings.Indent = true;
                settings.OmitXmlDeclaration = true;
                using (XmlWriter writer = XmlWriter.Create(sbParams, settings))
                {
                    writer.WriteStartElement("ROW");
                    writer.WriteStartElement("Filter");
                    foreach (NameValuePair item in list)
                    {
                        writer.WriteAttributeString(item.Name, item.Value);
                    }
                    writer.WriteEndElement();
                    writer.WriteEndElement();
                    writer.Close();
                }
                returnValue = sbParams.ToString();
            }
            return returnValue;
        }
        #endregion

    }
}
