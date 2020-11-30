using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Controllers;
using VendorPortal.ActionFilters;
using Martex.DMS.BLL.Facade.VendorPortal;
using Martex.DMS.BLL.Facade;
using Martex.DMS.BLL.Model.VendorPortal;
using Martex.DMS.DAO;
using VendorPortal.Common;
using Martex.DMS.DAL;
using VendorPortal.Models;
using Martex.DMS.DAL.Common;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.DAO;

namespace VendorPortal.Areas.ISP.Controllers
{
    public class VendorInfoController : BaseController
    {
        /// <summary>
        /// _s the vendor_ information.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.VendorInfoTaxClassification, true)]
        public ActionResult _Vendor_Information(int? vendorID)
        {
            logger.InfoFormat("Executing Vendor Information for Vendor ID {0}", vendorID);
            VendorPortalAccountFacade facade = new VendorPortalAccountFacade();
            VendorAccountModel model = new VendorAccountModel();
            if (vendorID != null)
            {
                 model = facade.GetVendorAccountDetails(vendorID.GetValueOrDefault());
            }
            else
            {
                logger.Warn("Executing _Vendor_Information in VendorInfoController, vendorID is null");
            }
            model.VendorLocationID = 0;
            logger.InfoFormat("Executing Finished for Vendor ID {0}", vendorID);
            return PartialView(model);
        }

        /// <summary>
        /// _s the vendor_ location_ info.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Location_Info(int vendorID, int vendorLocationID)
        {
            VendorPortalAccountFacade facade = new VendorPortalAccountFacade();
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            logger.InfoFormat("Trying to load Vendor Location Details for Vendor Location ID {0}", vendorLocationID);
            VendorLocationAccountModel model = null;
            model = facade.GetVendorLocationAccountDetails(vendorID, vendorLocationID);
            if (model.AddressInformation != null && model.AddressInformation.CountryID.HasValue)
            {
                ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(model.AddressInformation.CountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            }
            logger.InfoFormat("Execution Finished for the Vendor information Details with Vendor Location ID {0}", vendorLocationID);
            return PartialView(model);
        }

        /// <summary>
        /// Saves the vendor information section.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [HttpPost, ValidateInput(false)]
        public ActionResult SaveVendorInformationSection(VendorAccountModel model)
        {
            OperationResult result = new OperationResult();

            #region Verify Levy Address In Case Levy is Selected

            if (model.VendorDetails.IsLevyActive.GetValueOrDefault() == true)
            {
                logger.InfoFormat("Trying to check Levy Address exis or not for Vendor ID {0}", model.VendorDetails.ID);
                AddressRepository repository = new AddressRepository();
                List<AddressEntity> addressList = repository.GetAddresses(model.VendorDetails.ID, EntityNames.VENDOR, AddressTypeNames.LEVY);
                if (addressList == null || addressList.Count == 0)
                {
                    result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                    return Json(result);
                }
            }
            #endregion

            #region Save Method
            logger.Info("Executing Save Vendor Information Section");
            var facade = new VendorPortalAccountFacade();
            facade.UpdateVendorInformation(model, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Finished Save Vendor Information Section");
            #endregion

            return Json(result, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Validates the input for vendor location.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <exception cref="DMSException"></exception>
        private void ValidateInputForVendorLocation(VendorLocationAccountModel model)
        {
            CommonLookUpRepository lookUp =  new CommonLookUpRepository();
            VendorLocationStatu status = lookUp.GetVendorLocationStatus(model.BasicInformation.VendorLocationStatusID.GetValueOrDefault());
             StringBuilder sbErros = new StringBuilder();
             bool hasError = false;
             if (status.Name.Equals("Active", StringComparison.OrdinalIgnoreCase))
             {

                 sbErros.Append("In order to make location status Active the following fields are required:");

                 if (string.IsNullOrEmpty(model.AddressInformation.Line1))
                 {
                     sbErros.Append(string.Format("<br/>Address 1"));
                     hasError = true;
                 }
                 if (string.IsNullOrEmpty(model.AddressInformation.City))
                 {
                     sbErros.Append(string.Format("<br/>City"));
                     hasError = true;
                 }
                 if (!model.AddressInformation.CountryID.HasValue)
                 {
                     sbErros.Append(string.Format("<br/>Country"));
                     hasError = true;
                 }
                 if (!model.AddressInformation.StateProvinceID.HasValue)
                 {
                     sbErros.Append(string.Format("<br/>State"));
                     hasError = true;
                 }
                 if (string.IsNullOrEmpty(model.AddressInformation.PostalCode))
                 {
                     sbErros.Append(string.Format("<br/>Postal Code"));
                     hasError = true;
                 }

                 //validation for Phone Types as it's a Control tht's why we need to validate by hitting DB
                 var phoneFacade = new PhoneFacade();
                 PhoneEntity entity = phoneFacade.Get(model.BasicInformation.ID, EntityNames.VENDOR_LOCATION, PhoneTypeNames.Dispatch);
                 if (entity == null)
                 {
                     sbErros.Append(string.Format("<br/> Dispatch phone number"));
                     hasError = true;
                 }

                 if (model.PaymentTypes == null || model.PaymentTypes.Where(u => u.Selected == true).Count() <= 0)
                 {
                     sbErros.Append(string.Format("<br/>At least 1 payment type"));
                     hasError = true;
                 }
             }
            if (hasError)
            {
                throw new DMSException(sbErros.ToString());
            }
        }


        [DMSAuthorize]
        [NoCache]
        [HttpPost, ValidateInput(false)]
        public ActionResult _Vendor_Location_Info_Save(VendorLocationAccountModel model)
        {
            if (model.BasicInformation.VendorLocationStatusID.HasValue)
            {
                ValidateInputForVendorLocation(model);
            }
            OperationResult result = new OperationResult();
            #region Save Method
            logger.Info("Executing Save Vendor Location Information Section");
            var facade = new VendorPortalAccountFacade();
            facade.SaveVendorLocationInfoDetails(model, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Finished Save Vendor Location Information Section");
            #endregion
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
