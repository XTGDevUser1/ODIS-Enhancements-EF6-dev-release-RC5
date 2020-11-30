using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.Areas.VendorManagement.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Model;
using System.Text;
using Martex.DMS.DAL.Entities.TemporaryCC;
using CsvHelper;
using System.IO;
using Martex.DMS.BLL.Model.TempCCPModels;


namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    public partial class VendorTemporaryCCProcessingController : BaseController
    {
        public VendorTemporaryCCProcessingFacade facade = new VendorTemporaryCCProcessingFacade();

        public ActionResult Index()
        {
            TemporaryCCSearchCriteria model = null;
            model = model.GetModelForSearchCriteria();
            return View(model);
        }

        [ReferenceDataFilter(StaticData.ImportCCFileTypes, true)]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.BUTTON_IMPORT_CCFILE)]
        public ActionResult _ImportCCFile()
        {
            ImportCCUplaodModel model = new ImportCCUplaodModel();
            return PartialView(model);
        }

        [HttpPost]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.BUTTON_IMPORT_CCFILE)]
        public ActionResult UplaodCCFile(ImportCCUplaodModel model)
        {
            string fileName = string.Empty;
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            VendorTemporaryCCProcessingFacade facade = new VendorTemporaryCCProcessingFacade();
            try
            {
                if (!string.IsNullOrEmpty(model.FileType) && model.FileType.Equals("Credit Card Issue Transactions"))
                {

                    #region Virtual Plus Data Retrieval
                    fileName = Path.GetFileNameWithoutExtension(model.CCDocument.FileName);
                    var csv = new CsvReader(new StreamReader(model.CCDocument.InputStream));
                    csv.Configuration.RegisterClassMap<VirtualPlusMap>();
                    csv.Configuration.CultureInfo = new System.Globalization.CultureInfo("en-US");
                    csv.Configuration.HasHeaderRecord = true;
                    List<VirtualPlus> records = csv.GetRecords<VirtualPlus>().ToList();
                    // Filter Trailer Records
                    records = records.Where(u => u.CreateDate != DateTime.MinValue).ToList();
                    Guid processGuid = System.Guid.NewGuid();
                    ImportCCFileResult returnResult = facade.ProcessCreditCardIssueTransactions(records, LoggedInUserName, Session.SessionID, processGuid, Request.RawUrl,fileName);
                    string returnString = RenderPartialViewToString("_ImportCCFileResult", returnResult);
                    result.Data = new { Message = returnString };
                    #endregion
                }
                else if (!string.IsNullOrEmpty(model.FileType) && model.FileType.Equals("Credit Card Charge Transactions"))
                {

                    #region Charged Transactions Data Retrieval
                    fileName = Path.GetFileNameWithoutExtension(model.CCDocument.FileName);
                    var csv = new CsvReader(new StreamReader(model.CCDocument.InputStream));
                    csv.Configuration.HasHeaderRecord = true;
                    csv.Configuration.CultureInfo = new System.Globalization.CultureInfo("en-US");
                    csv.Configuration.RegisterClassMap<ChargedTransactionsMap>();
                    csv.Configuration.TrimFields = true;
                    List<ChargedTransactions> records = csv.GetRecords<ChargedTransactions>().ToList();
                    // Filter Trailer Records
                    records = records.Where(u => u.FinTransactionDate != DateTime.MinValue).ToList();
                    Guid processGuid = System.Guid.NewGuid();
                    ImportCCFileResult returnResult = facade.ProcessCreditCardChargedTransactions(records, LoggedInUserName, Session.SessionID, processGuid, Request.RawUrl,fileName);
                    string returnString = RenderPartialViewToString("_ImportCCFileChargedResult", returnResult);
                    result.Data = new { Message = returnString };
                    #endregion
                }
                else
                {
                    result.Status = OperationStatus.ERROR;
                    result.ErrorMessage = "Unable to determine file type";
                }
            }
            catch (FormatException ex)
            {
                logger.Error(ex);
                result.ErrorMessage = ex.Message;
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = "The selected import file does not match the expected file format. Check that the selected File Type matches the content of the file being imported.";
            }
            catch (CsvHelper.CsvHelperException exx)
            {
                logger.Error(exx);
                result.ErrorMessage = exx.Message;
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = "The selected import file does not match the expected file format. Check that the selected File Type matches the content of the file being imported.";
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = "An error had occured while processing your request.";
            }


            return Json(result, "text/plain", JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [ReferenceDataFilter(StaticData.TemprorayCCIDFilterTypes, true)]
        [ReferenceDataFilter(StaticData.PostingBatch, true)]
        [ReferenceDataFilter(StaticData.Clients, true)]
        public ActionResult _SearchCriteria(TemporaryCCSearchCriteria model)
        {
            TemporaryCCSearchCriteria tempModel = model;
            ModelState.Clear();
            if (model.FilterToLoadID.HasValue)
            {
                TemporaryCCSearchCriteria dbModel = tempModel.GetView(model.FilterToLoadID) as TemporaryCCSearchCriteria;
                if (dbModel != null)
                {
                    return PartialView(dbModel);
                }
            }
            return PartialView(tempModel.GetModelForSearchCriteria());
        }

        [HttpPost]
        public ActionResult _SelectedCriteria(TemporaryCCSearchCriteria model)
        {
            return PartialView(model.GetModelForSearchCriteria());
        }

        public ActionResult _GetCCProcessingList([DataSourceRequest] DataSourceRequest request, TemporaryCCSearchCriteria searchCriteria)
        {
            logger.Info("Inside _GetCCProcessingList of VendorTemporaryCCProcessingController. Attempt to get all Vendor Invoices depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ToBePaidDate";
            string sortOrder = "ASC";
            if (request != null && request.Sorts != null && request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = searchCriteria.GetFilterSearchCritera();

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.Count > 0 ? filter.GetXML() : string.Empty
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            List<VendorCCProcessingList_Result> list = new List<VendorCCProcessingList_Result>();
            if (filter.Count > 0)
            {
                list = facade.GetVendorCCProcessingList(pageCriteria);
            }

            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }

        public ActionResult _GetCCProcessingDetailsList([DataSourceRequest] DataSourceRequest request, int? temporaryCCID)
        {
            logger.Info("Inside _GetCCProcessingDetailsList of VendorTemporaryCCProcessingController. Attempt to get Processing Details depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            RegisterUserModel userProfile = GetProfile();
            List<VendorCCProcessingDetailList_Result> list = new List<VendorCCProcessingDetailList_Result>();

            list = facade.GetVendorCCProcessingDetailList(pageCriteria, temporaryCCID);

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.GetValueOrDefault();
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            return Json(result);
        }

        public ActionResult _GetTemporaryCCCardDetails(int? temporaryCCID)
        {
            TemporaryCCCardDetails_Result result = new TemporaryCCCardDetails_Result();
            if (temporaryCCID != null)
            {
                result = facade.GetTemporaryCCCardDetails(temporaryCCID);
            }
            else
            {
                throw new DMSException("ID should not be null to fetch a card details");
            }
            return View(result);
        }

        public ActionResult SaveTemporaryCCDetails(TemporaryCCCardDetails_Result temopraryCCCardDetails)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.Info("Save CC Card Details");
            var currentUser = LoggedInUserName;
            facade.SaveTemporaryCCDetails(temopraryCCCardDetails, currentUser);
            logger.Info("Updated CC Card Details Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
