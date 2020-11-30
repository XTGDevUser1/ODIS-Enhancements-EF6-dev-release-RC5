using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Common;
using log4net;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class ServiceRepository
    {

        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ServiceRepository));
        #endregion

        /// <summary>
        /// Updates the service request.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <param name="programID">The program ID.</param>
        public void UpdateServiceRequest(ServiceRequest request, string userName, int? vehicleTypeID, int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                ServiceRequest existingDetails = dbContext.ServiceRequests.Where(id => id.ID == request.ID).FirstOrDefault();
                if (existingDetails == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve service request details for the service request id : {0}", request.ID));
                }
                //existingDetails.MemberPaymentTypeID = request.MemberPaymentTypeID;

                existingDetails.ProductCategoryID = request.ProductCategoryID;
                existingDetails.IsPossibleTow = request.IsPossibleTow;
                existingDetails.VehicleCategoryID = request.VehicleCategoryID;
                //existingDetails.CoverageLimit = request.CoverageLimit;
                existingDetails.PassengersRidingWithServiceProvider = request.PassengersRidingWithServiceProvider;
                existingDetails.ServiceTabStatus = request.ServiceTabStatus;
                existingDetails.ModifyDate = DateTime.Now;
                existingDetails.ModifyBy = userName;

                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Updates the service eligibility.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="DMSException">Unable to retrieve service request details</exception>
        public void UpdateServiceEligibility(ServiceRequest request, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                ServiceRequest existingDetails = dbContext.ServiceRequests.Where(id => id.ID == request.ID).FirstOrDefault();
                if (existingDetails == null)
                {
                    throw new DMSException("Unable to retrieve service request details");
                }
                if (existingDetails.IsPossibleTow.GetValueOrDefault())
                {
                    existingDetails.IsSecondaryOverallCovered = request.IsSecondaryOverallCovered;
                    existingDetails.IsSecondaryProductCovered = request.IsSecondaryProductCovered;
                    existingDetails.SecondaryCoverageLimit = request.SecondaryCoverageLimit;
                    existingDetails.SecondaryCoverageLimitMileage = request.SecondaryCoverageLimitMileage;
                    existingDetails.SecondaryServiceCoverageDescription = request.SecondaryServiceCoverageDescription;
                    existingDetails.SecondaryServiceEligiblityMessage = request.SecondaryServiceEligiblityMessage;
                    //existingDetails.IsSecondaryOverallCovered = request.IsSecondaryOverallCovered;
                }
                else
                {
                    //existingDetails.IsSecondaryOverallCovered = null;
                    existingDetails.IsSecondaryProductCovered = null;
                    existingDetails.SecondaryCoverageLimit = null;
                    existingDetails.SecondaryCoverageLimitMileage = null;
                    existingDetails.SecondaryServiceCoverageDescription = null;
                    existingDetails.SecondaryServiceEligiblityMessage = null;
                    existingDetails.IsSecondaryOverallCovered = null;
                }


                existingDetails.IsPrimaryOverallCovered = request.IsPrimaryOverallCovered;
                existingDetails.IsPrimaryProductCovered = request.IsPrimaryProductCovered;
                existingDetails.PrimaryCoverageLimit = request.PrimaryCoverageLimit;
                existingDetails.PrimaryCoverageLimitMileage = request.PrimaryCoverageLimitMileage;
                existingDetails.PrimaryServiceCoverageDescription = request.PrimaryServiceCoverageDescription;
                existingDetails.PrimaryServiceEligiblityMessage = request.PrimaryServiceEligiblityMessage;

                existingDetails.IsServiceGuaranteed = request.IsServiceGuaranteed;
                existingDetails.IsReimbursementOnly = request.IsReimbursementOnly;
                existingDetails.IsServiceCoverageBestValue = request.IsServiceCoverageBestValue;
                existingDetails.ProgramServiceEventLimitID = request.ProgramServiceEventLimitID;

                existingDetails.CurrencyTypeID = request.CurrencyTypeID;

                existingDetails.MileageUOM = request.MileageUOM;

                //existingDetails.IsPrimaryOverallCovered = request.IsPrimaryOverallCovered;

                logger.InfoFormat("Updated Service Eligibility fro the SR : {0}, IsPrimaryOverallCovered : {1}, IsSecondaryOverallCovered : {2}", existingDetails.ID, existingDetails.IsPrimaryOverallCovered, existingDetails.IsSecondaryOverallCovered);
                existingDetails.ModifyDate = DateTime.Now;
                existingDetails.ModifyBy = userName;

                dbContext.SaveChanges();
            }
        }



        /// <summary>
        /// Saves the specified service request ID.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="inputXML">The input XML.</param>
        public void Save(int serviceRequestID, string userName, string inputXML, int? vehicleTypeID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.SaveServiceQuestionAnswers(serviceRequestID, inputXML, userName, vehicleTypeID);
            }
        }
        /// <summary>
        /// Gets the product categories for program.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="vehicleCategoryId">The vehicle category id.</param>
        /// <param name="vehicleTypeId">The vehicle type id.</param>
        /// <returns></returns>
        public List<ProductCategoriesForProgram_Result> GetProductCategoriesForProgram(int programId, int? vehicleCategoryId, int? vehicleTypeId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetProductCategoriesForProgram(programId, vehicleTypeId, vehicleCategoryId).ToList<ProductCategoriesForProgram_Result>();
                return result;
            }
        }

        /// <summary>
        /// Gets the questions for program.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="vehicleCategoryId">The vehicle category id.</param>
        /// <param name="vehicleTypeId">The vehicle type id.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<QuestionsForProductCategory_Result> GetQuestionsForProgram(int programId, int? vehicleCategoryId, int? vehicleTypeId, int? serviceRequestID, string sourceSystemName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetQuestionsForProductCategory(programId, vehicleTypeId, vehicleCategoryId, serviceRequestID, sourceSystemName).ToList<QuestionsForProductCategory_Result>();
                return result;
            }
        }

        /// <summary>
        /// Gets the question answer values.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="vehicleCategoryId">The vehicle category id.</param>
        /// <param name="vehicleTypeId">The vehicle type id.</param>
        /// <returns></returns>
        public List<QuestionAnswerValues_Result> GetQuestionAnswerValues(int programId, int? vehicleCategoryId, int? vehicleTypeId, string sourceSystemName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetQuestionAnswerValues(programId, vehicleTypeId, vehicleCategoryId, sourceSystemName).ToList<QuestionAnswerValues_Result>();
                return result;
            }
        }

        /// <summary>
        /// Gets the diagnostic codes.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<ServiceDiagnosticCodeModel> GetDiagnosticCodes(int serviceRequestID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from src in dbContext.ServiceRequestVehicleDiagnosticCodes
                              join vdc in dbContext.VehicleDiagnosticCodes on src.VehicleDiagnosticCodeID equals vdc.ID
                              join vdcat in dbContext.VehicleDiagnosticCategories on vdc.VehicleDiagnosticCategoryID equals vdcat.ID
                              where src.ServiceRequestID == serviceRequestID
                              orderby vdcat.Sequence, vdc.Sequence
                              select new ServiceDiagnosticCodeModel()
                              {
                                  ID = vdc.ID,
                                  CategoryName = vdcat.Name,
                                  IsPrimary = src.IsPrimary ?? false,
                                  Code = (src.VehicleDiagnosticCodeType == "Standard" ? vdc.LegacyCode :
                                            (
                                                (src.VehicleDiagnosticCodeType == "Ford Standard")
                                                ?
                                                vdc.FordStandardCode
                                                :
                                                (
                                                    src.VehicleDiagnosticCodeType == "Ford Warranty"
                                                    ?
                                                    vdc.FordWarrantyCode
                                                    :
                                                    (
                                                        src.VehicleDiagnosticCodeType == "Ford After Warranty"
                                                        ?
                                                        vdc.FordAfterWarrantyCode
                                                        :
                                                        string.Empty
                                                    )

                                                )
                                            )
                                         ),
                                  CodeName = vdc.Name
                              }).ToList<ServiceDiagnosticCodeModel>();

                return result;
            }
        }

        /// <summary>
        /// Gets the diagnostic codes.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <param name="codeType">Type of the code.</param>
        /// <returns></returns>
        public List<DiagnosticCodes_Result> GetDiagnosticCodes(int serviceRequestID, int vehicleTypeID, string codeType)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetDiagnosticCodes(serviceRequestID, vehicleTypeID, codeType);
                return result.ToList<DiagnosticCodes_Result>();
            }
        }

        /// <summary>
        /// Gets the code types.
        /// </summary>
        /// <returns></returns>
        public Dictionary<string, string> GetCodeTypes()
        {
            Dictionary<string, string> list = new Dictionary<string, string>();
            list.Add("Standard", "Standard");
            list.Add("Ford Standard", "Ford Standard");
            list.Add("Ford Warranty", "Ford Warranty");
            list.Add("Ford After Warranty", "Ford After Warranty");
            return list;
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
            using (DMSEntities dbContext = new DMSEntities())
            {

                dbContext.SaveDiagnosticCodes(serviceRequestID, selectedCodes, codeType, primaryCode, createBy);
            }
        }

        /// <summary>
        /// Gets the service request by id.
        /// </summary>
        /// <param name="Id">The id.</param>
        /// <returns></returns>
        public ServiceRequest GetServiceRequestById(int Id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.ServiceRequests.Include("ServiceRequestStatu").Where(sr => sr.ID == Id).FirstOrDefault<ServiceRequest>();

                return result;
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="serviceRequestID"></param>
        /// <returns></returns>
        public ServiceTech_RepairLocationDetails GetServiceTechRepairLocationDetails(int serviceRequestID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetServiceTechRepairLocationDetails(serviceRequestID).FirstOrDefault();
                return result;
            }
        }

        /// <summary>
        /// Gets the service limits.
        /// </summary>
        /// <param name="productCategoryId">The product category id.</param>
        /// <param name="vehicleCategoryId">The vehicle category id.</param>
        /// <returns></returns>
        public List<ServiceLimits_Result> GetServiceLimits(int programId, int vehicleCategoryId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetServiceLimits(programId, vehicleCategoryId).ToList<ServiceLimits_Result>();
                return result;
            }
        }

        /// <summary>
        /// Gets the primary product.
        /// </summary>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <returns></returns>
        public Product GetPrimaryProduct(int serviceRequestId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var product = (from s in dbContext.ServiceRequests
                               join p in dbContext.Products on s.PrimaryProductID equals p.ID
                               where s.ID == serviceRequestId
                               select p).FirstOrDefault();
                return product;
            }
        }

        /// <summary>
        /// Gets the service request history.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <param name="loggeduser">The loggeduser.</param>
        /// <returns></returns>
        public List<ServiceRequestHistoryList_Result> GetServiceRequestHistory(PageCriteria criteria, Guid loggeduser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 120;
                return dbContext.GetServiceRequestHistoryList(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection, loggeduser).ToList();
            }
        }

        /// <summary>
        /// Get Service Request Count
        /// </summary>
        /// <returns></returns>
        public List<DashboardServiceRequestCount_Result> GetDashboradServiceRequestCount()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetDashboardServiceRequestCount().OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the verify program service event limit.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="programID">The program identifier.</param>
        /// <param name="productCategoryID">The product category identifier.</param>
        /// <param name="productID">The product identifier.</param>
        /// <param name="vehicleTypeID">The vehicle type identifier.</param>
        /// <param name="vehicleCategoryID">The vehicle category identifier.</param>
        /// <returns></returns>
        public List<VerifyProgramServiceEventLimit_Result> GetVerifyProgramServiceEventLimit(int? serviceRequestID, int? programID, int? productCategoryID, int? productID, int? vehicleTypeID, int? vehicleCategoryID, int? secondaryCategoryID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVerifyProgramServiceEventLimit(serviceRequestID, programID, productCategoryID, productID, vehicleTypeID, vehicleCategoryID, secondaryCategoryID).ToList<VerifyProgramServiceEventLimit_Result>();
            }
        }

        /// <summary>
        /// Gets the verify service benefit.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="productCategoryID">The product category identifier.</param>
        /// <param name="vehicleCategoryID">The vehicle category identifier.</param>
        /// <param name="vehicleTypeID">The vehicle type identifier.</param>
        /// <param name="secondaryCategoryID">The secondary category identifier.</param>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <returns></returns>
        public List<VerifyProgramServiceBenefit_Result> GetVerifyProgramServiceBenefit(int? programID, int? productCategoryID, int? vehicleCategoryID, int? vehicleTypeID, int? secondaryCategoryID, int? serviceRequestID, int? productID, bool isPrimaryOverride)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVerifyProgramServiceBenefit(programID, productCategoryID, vehicleCategoryID, vehicleTypeID, secondaryCategoryID, serviceRequestID, productID, isPrimaryOverride).ToList<VerifyProgramServiceBenefit_Result>();
            }
        }

        /// <summary>
        /// Determines whether the POs related to the given SR are in given statuses.
        /// </summary>
        /// <param name="serviceRequestID">The service request unique identifier.</param>
        /// <param name="statuses">The statuses.</param>
        /// <returns></returns>
        public bool HasPOsInStatuses(int serviceRequestID, params string[] statuses)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = (from po in dbContext.PurchaseOrders
                            join s in statuses on po.PurchaseOrderStatu.Name equals s
                            where po.ServiceRequestID == serviceRequestID
                            select po).ToList<PurchaseOrder>();

                return list.Count > 0;
            }
        }



        public List<ProgramDataItemAnswers_Result> GetProgramDataItemAnswers(int programID, string screenName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramDataItemAnswersGet(programID, screenName).ToList();
            }
        }

        public List<ProgramDataItemsForProgram_Result> GetProgramDataItemsForProgram(int programID, string screenName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramDataItemsForProgramGet(programID, screenName).ToList();
            }
        }

        /// <summary>
        /// Updates the service request estimate values.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <exception cref="DMSException"></exception>
        public void UpdateServiceRequestEstimateValues(ServiceRequest request, string loggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                ServiceRequest existingDetails = dbContext.ServiceRequests.Where(id => id.ID == request.ID).FirstOrDefault();
                if (existingDetails == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve service request details for the service request id : {0}", request.ID));
                }

                existingDetails.ServiceEstimateDenyReasonID = request.ServiceEstimateDenyReasonID;
                existingDetails.EstimateDeclinedReasonOther = request.EstimateDeclinedReasonOther;
                existingDetails.ServiceEstimate = request.ServiceEstimate;
                existingDetails.EstimatedTimeCost = request.EstimatedTimeCost;
                existingDetails.IsServiceEstimateAccepted = request.IsServiceEstimateAccepted;
                existingDetails.ModifyDate = DateTime.Now;
                existingDetails.ModifyBy = loggedInUserName;

                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the service eligibility messages.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="sourceSystemName">Name of the source system.</param>
        /// <returns></returns>
        public List<ServiceElibilityMessages_Result> GetServiceEligibilityMessages(int programID, string sourceSystemName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetServiceElibilityMessages(programID, sourceSystemName).ToList<ServiceElibilityMessages_Result>();                
            }
        }
    }
}
