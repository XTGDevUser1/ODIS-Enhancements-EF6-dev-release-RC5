using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Controllers;
using VendorPortal.ActionFilters;
using Kendo.Mvc.UI;
using VendorPortal.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Model;
using Microsoft.Reporting.WebForms;
using System.Web.Hosting;

namespace VendorPortal.Areas.ISP.Controllers
{
    public class VendorRatesController : BaseController
    {
        protected VendorManagementFacade vendorFacade = new VendorManagementFacade();
        /// <summary>
        /// _s the vendor_ rates.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Rates(int? vendorID)
        {
            var vendorManagementfacade = new VendorManagementFacade();
            if (vendorID == null)
            {
                logger.Warn("Executing _Vendor_Rates in VendorRatesController, vendorID is null");
            }
            var list =
                vendorManagementfacade.GetVendorLocationsList(vendorID.GetValueOrDefault())
                    .OrderBy(x => x.VendorLocationID)
                    .ToSelectListItem(x => x.VendorLocationID.ToString(), y => y.LocationAddress, false);
            ViewData[StaticData.LocationList.ToString()] = new SelectList(list, "Value", "Text");
            return PartialView(vendorID.GetValueOrDefault());
        }

        /// <summary>
        /// _s the vendor_ location_ rates.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <param name="vendorLocationID">The vendor location identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Location_Rates(int vendorID, int vendorLocationID)
        {
            return PartialView(vendorLocationID);
        }

        /// <summary>
        /// _s the get vendor rates.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _GetVendorRates([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info(
                "Inside _GetVendorRates() of Vendor Rates Controller. Attempt to get Vendor Rates depending upon the GridCommand");
            var gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "ASC";
            if (request != null && request.Sorts != null && request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending)
                    ? "ASC"
                    : "DESC";
            }
            var pageCriteria = new PageCriteria()
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
            var repository = new VendorManagementRepository();
            List<VendorServicesAndRates_Result> ratesList = null;
            ratesList =
                repository.GetVendorServicesAndRates(
                    repository.GetVendorLatestContractRateSchedule(LoggedInUserVendorID).GetValueOrDefault(), null);
            logger.InfoFormat("Call the view by sending {0} number of records", ratesList.Count);
            int totalRows = 0;
            if (ratesList.Count > 0)
            {
                totalRows = ratesList.Count;
            }
            var result = new DataSourceResult()
            {
                Data = ratesList,
                Total = totalRows
            };
            return Json(result, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// _s the get vendor location rates.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorLocationID">The vendor location identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _GetVendorLocationRates([DataSourceRequest] DataSourceRequest request, int vendorLocationID)
        {
            logger.Info(
                "Inside _GetVendorLocationRates() of Vendor Rates Controller. Attempt to get Vendor Rates depending upon the GridCommand");
            var gridUtil = new GridUtil();
            var sortColumn = "";
            var sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending)
                    ? "ASC"
                    : "DESC";
            }
            var pageCriteria = new PageCriteria()
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
            var repository = new VendorManagementRepository();
            var ratesList =
                repository.GetVendorServicesAndRates(
                    repository.GetVendorLatestContractRateSchedule(LoggedInUserVendorID).GetValueOrDefault(),
                    vendorLocationID);
            var result = new DataSourceResult()
            {
                Data = ratesList
            };
            if (ratesList != null)
            {
                logger.InfoFormat("Call the view by sending {0} number of records", ratesList.Count);
                int totalRows = 0;
                if (ratesList.Count > 0)
                {
                    totalRows = ratesList.Count;
                }
                result.Total = totalRows;


            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        [DMSAuthorize]
        public ActionResult GetRatesForPreview()
        {
            logger.InfoFormat("Generating preview");
            var ratesAgreement = new VendorRatesAgreementModel();
            
            var profile = GetProfile();
            var vendorID = profile.VendorID.GetValueOrDefault();
            var vendor = vendorFacade.Get(vendorID);

            if (vendor.VendorApplications != null && vendor.VendorApplications.Count > 0)
            {
                var vendorApplication = vendor.VendorApplications.FirstOrDefault();
                ratesAgreement.ApplicationDate = vendorApplication.CreateDate;
            }

            VendorRatesModel model = vendorFacade.GetVendorRates(vendorID, null);

            ratesAgreement.VendorID = vendorID;
            ratesAgreement.PurposeForPreview = "print";
            ratesAgreement.Source = "rates";
            ratesAgreement.SendEmail = true;
            
            string fileName = "rates".Equals(ratesAgreement.Source, StringComparison.InvariantCultureIgnoreCase) ? "RateSchedule" : "WelcomeLetter";
            fileName = string.Format("{0}_{1}_{2}.pdf", vendor.VendorNumber, fileName, DateTime.Now.ToString("yyyyMMdd_HHmm"));
                        
            if (model.CurrentRateSchedule != null)
            {
                ratesAgreement.RateScheduleID = model.CurrentRateSchedule.ContractRateScheduleID;
            }
            else
            {
                return Content("No Rates Schedule set up for the Vendor");
            }
            
            byte[] bytes = GetRatesAgreementPDF(ratesAgreement);
            return File(bytes, "application/pdf", fileName);
        }

        private byte[] GetRatesAgreementPDF(VendorRatesAgreementModel ratesAgreement)
        {
           
            // Run the report and extract the PDF.
            ReportViewer reportViewer = new ReportViewer();
            var localReport = reportViewer.LocalReport;
            string purposeForPreview = "Print".Equals(ratesAgreement.PurposeForPreview, StringComparison.InvariantCultureIgnoreCase) ? "1" : "0";
            if ("rates".Equals(ratesAgreement.Source, StringComparison.InvariantCultureIgnoreCase))
            {
                localReport.ReportPath = HostingEnvironment.MapPath("~/Reports/RptContractRateSchedule.rdlc");
                var vendorDetails = vendorFacade.GetVendorDetailsForReport(ratesAgreement.VendorID);
                var rates = vendorFacade.GetRateSchedulesForReport(ratesAgreement.RateScheduleID);


                localReport.DataSources.Add(new Microsoft.Reporting.WebForms.ReportDataSource("dsVendor", vendorDetails));
                localReport.DataSources.Add(new Microsoft.Reporting.WebForms.ReportDataSource("dsRateSchedule", rates));

                string includeCover = ratesAgreement.SendEmail ? "0" : "1";



                //Fact: There is no need to pass VendorID and RateScheduleID as the dataasets are provided to the report in the above statements.
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("PageVisibility", includeCover));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmAdditionalText", ratesAgreement.AdditionalText ?? string.Empty));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmToEmailAddress", ratesAgreement.Email));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmPurpose", purposeForPreview));
                string applicationDate = DateTime.Now.ToShortDateString();
                if (ratesAgreement.ApplicationDate != null)
                {
                    applicationDate = ratesAgreement.ApplicationDate.Value.ToShortDateString();
                }
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmApplicationDate", applicationDate));
            }
            else
            {
                localReport.ReportPath = HostingEnvironment.MapPath("~/Reports/RptWelcomeNotice.rdlc");
                var vendorDetails = vendorFacade.GetVendorDetailsForReport(ratesAgreement.VendorID);

                localReport.DataSources.Add(new Microsoft.Reporting.WebForms.ReportDataSource("dsVendor", vendorDetails));

                //Fact: There is no need to pass VendorID and RateScheduleID as the dataasets are provided to the report in the above statements.
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmAdditionalText", ratesAgreement.AdditionalText ?? string.Empty));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmToEmailAddress", ratesAgreement.Email));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmPurpose", purposeForPreview));

            }


            reportViewer.ProcessingMode = ProcessingMode.Local;
            byte[] bytes = reportViewer.LocalReport.Render("PDF");
            return bytes;
        }

    }
}
