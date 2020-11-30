using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.ActionFilters;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Models;
using Martex.DMS.BLL.Model;

namespace Martex.DMS.Areas.Claims.Controllers
{
    public partial class ClaimController
    {
        [ReferenceDataFilter(StaticData.PODetailsUOM, false)]
        [ReferenceDataFilter(StaticData.PODetailsProduct, false)]
        [ReferenceDataFilter(StaticData.ETA)]
        [ReferenceDataFilter(StaticData.ContactMethod)]
        [ReferenceDataFilter(StaticData.VendorInvoiceStatus)]
        public ActionResult _Claims_PO(int? suffixClaimID, string purchaseOrderNumber)
        {

            VendorInvoiceInfoCommonModel invoiceDetails = new VendorInvoiceInfoCommonModel();
            if (suffixClaimID > 0 || !string.IsNullOrEmpty(purchaseOrderNumber))
            {
                ViewData["claimID"] = suffixClaimID;
                invoiceDetails = facade.GetVendorInvoiceDetails(suffixClaimID.GetValueOrDefault(), purchaseOrderNumber);
            }
            return View(invoiceDetails);
        }

    }
}
