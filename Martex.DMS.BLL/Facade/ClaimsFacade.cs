using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using log4net;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Facade.Claim;
using System.Xml;
using Martex.DMS.BLL.Model.Claims;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Claims Facade
    /// </summary>
    public partial class ClaimsFacade : Claim_Facade_Base
    {
        /// <summary>
        /// 
        /// </summary>
        VendorInvoiceRepository viRepository = new VendorInvoiceRepository();

        /// <summary>
        /// Gets the claims list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ClaimsList_Result> GetClaimsList(PageCriteria pc)
        {
            return repository.GetClaimsList(pc);
        }

        /// <summary>
        /// Deletes the claim.
        /// </summary>
        /// <param name="claimID">The claim ID.</param>
        public void DeleteClaim(int claimID)
        {
            repository.DeleteClaim(claimID);
        }

        /// <summary>
        /// Looks up purchase order number.
        /// </summary>
        /// <param name="purchaseOrderNumber">The purchase order number.</param>
        /// <returns></returns>
        public ClaimPurchaseOrderNumberLookUPDetails_Result LookUpPurchaseOrderNumber(string purchaseOrderNumber)
        {
            return repository.LookUpPurchaseOrderNumber(purchaseOrderNumber);
        }

        /// <summary>
        /// Looks up member address details.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public ClaimMemberAddressPhoneNumberLookUP_Result LookUpMemberAddressDetails(int memberID)
        {
            return repository.LookUpMemberAddressDetails(memberID);
        }



        /// <summary>
        /// Gets the member name using membership number.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        public Member GetMemberUsingMembershipNumber(string membershipNumber, int? programID)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");

                if (!string.IsNullOrEmpty(membershipNumber))
                {
                    writer.WriteAttributeString("MemberNumberOperator", "2");
                    writer.WriteAttributeString("MemberNumberValue", membershipNumber);
                }
                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 100,
                PageSize = 100,
                SortColumn = "",
                SortDirection = "",
                WhereClause = whereClauseXML.ToString()
            };
            return repository.GetMemberUsingMembershipNumber(membershipNumber, programID, pageCriteria);
        }

        public List<Queue_Result> SearchBySR(string sr, Guid currentUser)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");

                if (!string.IsNullOrEmpty(sr))
                {
                    writer.WriteAttributeString("RequestNumberOperator", "2");
                    writer.WriteAttributeString("RequestNumberValue", sr);
                }
                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 100,
                PageSize = 100,
                SortColumn = "",
                SortDirection = "",
                WhereClause = whereClauseXML.ToString()
            };
            QueueRepository repository = new QueueRepository();
            return repository.Search(currentUser, pageCriteria);
        }
        public List<SearchMembersByVINOrMS_Result> SearchByVINAndProgram(string vin, int? programID)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");

                if (!string.IsNullOrEmpty(vin))
                {
                    writer.WriteAttributeString("VINOperator", "2");
                    writer.WriteAttributeString("VINValue", vin);
                }
                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 100,
                PageSize = 100,
                SortColumn = "",
                SortDirection = "",
                WhereClause = whereClauseXML.ToString()
            };
            MemberRepository memberRepository = new MemberRepository();
            return memberRepository.SearchMemberByVINOrMS(pageCriteria, programID.Value);
        }
        public List<SearchMembersByVINOrMS_Result> SearchByMembershipAndProgram(string membershipNumber, int? programID)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");

                if (!string.IsNullOrEmpty(membershipNumber))
                {
                    writer.WriteAttributeString("MemberNumberOperator", "2");
                    writer.WriteAttributeString("MemberNumberValue", membershipNumber);
                }
                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 100,
                PageSize = 100,
                SortColumn = "",
                SortDirection = "",
                WhereClause = whereClauseXML.ToString()
            };
            MemberRepository memberRepository = new MemberRepository();
            return memberRepository.SearchMemberByVINOrMS(pageCriteria, programID.Value);
        }
        /// <summary>
        /// Gets the vendor by vendor number.
        /// </summary>
        /// <param name="vendorNumber">The vendor number.</param>
        /// <returns></returns>
        public Vendor GetVendorByVendorNumber(string vendorNumber)
        {
            return repository.GetVendorByVendorNumber(vendorNumber);
        }


        public DAL.Claim GetVehicleForVIN(int vehicleID)
        {
            VehicleFacade vehicleFacade = new VehicleFacade();
            Vehicle information = vehicleFacade.GetVehicle(vehicleID);
            Martex.DMS.DAL.Claim model = new Martex.DMS.DAL.Claim();

            if (information != null)
            {
                model.VehicleTypeID = information.VehicleTypeID;
                model.VehicleVIN = information.VIN;
                model.VehicleYear = information.Year;
                model.VehicleMake = information.Make;
                model.VehicleMakeOther = information.MakeOther;
                model.VehicleModel = information.Model;
                model.VehicleModelOther = information.ModelOther;
                model.VehicleCategoryID = information.VehicleCategoryID;
                model.WarrantyStartDate = information.WarrantyStartDate;
                model.VehicleChassis = information.Chassis;
                model.VehicleEngine = information.Engine;
                model.VehicleTransmission = information.Transmission;
                model.CurrentMiles = information.CurrentMileage;
            }

            return model;

        }
        /// <summary>
        /// Gets the vehicle formembership.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <returns></returns>
        public Martex.DMS.DAL.Claim GetVehicleFormembership(string membershipNumber)
        {
            Martex.DMS.DAL.Claim model = new Martex.DMS.DAL.Claim();
            Vehicle information = repository.GetVehicleFormembership(membershipNumber);
            if (information != null)
            {
                model.VehicleTypeID = information.VehicleTypeID;
                model.VehicleVIN = information.VIN;
                model.VehicleYear = information.Year;
                model.VehicleMake = information.Make;
                model.VehicleMakeOther = information.MakeOther;
                model.VehicleModel = information.Model;
                model.VehicleModelOther = information.ModelOther;
                model.VehicleCategoryID = information.VehicleCategoryID;
                model.WarrantyStartDate = information.WarrantyStartDate;
                model.VehicleChassis = information.Chassis;
                model.VehicleEngine = information.Engine;
                model.VehicleTransmission = information.Transmission;
                model.CurrentMiles = information.CurrentMileage;
            }
            return model;
        }



        //public VendorInvoicePODetails_Result GetPODetailsforClaim(int suffixClaimID)
        //{
        //    PurchaseOrder po = repository.GetPOforClaim(suffixClaimID);
        //    VendorInvoicePODetails_Result vendorInvoicePODetails = new VendorInvoicePODetails_Result();
        //    if (po.PurchaseOrderNumber != null)
        //    {
        //        vendorInvoicePODetails = viRepository.GetVendorInvoicePODetails(po.PurchaseOrderNumber);
        //    }
        //    return vendorInvoicePODetails;
        //}

        /// <summary>
        /// Gets the vendor invoice details.
        /// </summary>
        /// <param name="suffixClaimID">The suffix claim ID.</param>
        /// <returns></returns>
        public VendorInvoiceInfoCommonModel GetVendorInvoiceDetails(int suffixClaimID, string purchaseOrderNumber)
        {
            PurchaseOrder po = null;
            if (suffixClaimID > 0)
            {
                po = repository.GetPOforClaim(suffixClaimID);
            }
            if (po != null && !string.IsNullOrEmpty(po.PurchaseOrderNumber))
            {
                purchaseOrderNumber = po.PurchaseOrderNumber;
            }
            VendorInvoiceInfoCommonModel invoiceDetails = new VendorInvoiceInfoCommonModel();

            invoiceDetails.VendorInvoicePODetails = viRepository.GetVendorInvoicePODetails(purchaseOrderNumber);
            if (invoiceDetails.VendorInvoicePODetails != null)
            {
                int vendorLocationID = invoiceDetails.VendorInvoicePODetails.VendorLocationID.GetValueOrDefault();
                int purchaseOrderID = invoiceDetails.VendorInvoicePODetails.ID;
                invoiceDetails.VendorInvoiceVendorLocationDetails = viRepository.GetVendorInvoiceVendorLocationDetails(vendorLocationID);
            }
            return invoiceDetails;
        }

        public int CreateClaim(ClaimInput model, string userName)
        {
            Martex.DMS.DAL.Claim claim = null;
            if (string.IsNullOrEmpty(model.PayeeType))
            {
                model.PayeeType = PayeeTypeName.MEMBER;
            }
            if (model.VehicleID != null)
            {
                logger.InfoFormat("Loading vehicle details for ID {0}", model.VehicleID);
                claim = GetVehicleForVIN(model.VehicleID.Value);
            }
            else
            {
                logger.InfoFormat("Loading vehicles for membership # {0}", model.MembershipNumber);
                claim = GetVehicleFormembership(model.MembershipNumber);
            }
            
            claim.ClaimTypeID = model.ClaimTypeID;
            claim.PayeeType = model.PayeeType;

            // Fill Address Details
            var addressRepository = new AddressRepository();
            var phoneRepository = new PhoneRepository();
            AddressEntity homeAddress = null;
            PhoneEntity homePhone = null;
            if (model.PayeeType.Equals(PayeeTypeName.MEMBER))
            {
                homeAddress = addressRepository.GetAddresses(model.MemberID, EntityNames.MEMBER, AddressTypeNames.HOME).FirstOrDefault();
                homePhone = phoneRepository.Get(model.VendorID.GetValueOrDefault(), EntityNames.VENDOR, PhoneTypeNames.Home);
            }
            else
            {
                homeAddress = addressRepository.GetAddresses(model.VendorID.GetValueOrDefault(), EntityNames.VENDOR, AddressTypeNames.BILLING).FirstOrDefault();
                homePhone = phoneRepository.Get(model.VendorID.GetValueOrDefault(), EntityNames.VENDOR, PhoneTypeNames.Office);
            }
            if (homeAddress != null)
            {
                claim.PaymentAddressLine1 = homeAddress.Line1;
                claim.PaymentAddressLine2 = homeAddress.Line2;
                claim.PaymentAddressLine3 = homeAddress.Line3;

                claim.PaymentAddressPostalCode = homeAddress.PostalCode;
                claim.PaymentAddressStateProvince = homeAddress.StateProvince;
                claim.PaymentAddressStateProvinceID = homeAddress.StateProvinceID;

                claim.PaymentAddressCity = homeAddress.City;
                claim.PaymentAddressCountryCode = homeAddress.CountryCode;
                claim.PaymentAddressCountryID = homeAddress.CountryID;
            }

            if (homePhone != null)
            {
                claim.ContactPhoneNumber = homePhone.PhoneNumber;
            }

            // Set default values.
            CommonLookUpRepository lookUp = new CommonLookUpRepository();
            claim.SourceSystemID = lookUp.GetSourceSystem(SourceSystemName.BACK_OFFICE).ID;
            claim.ProgramID = model.ProgramID;
            claim.MemberID = model.MemberID;   
            if (!string.IsNullOrEmpty(model.PayeeType))
            {
                if (model.PayeeType.Equals(PayeeTypeName.VENDOR))
                {
                    claim.VendorID = model.VendorID;
                }
                else
                {                    
                    claim.PurchaseOrderID = model.PurchaseOrderID;
                }
            }

            var receivedStatus = lookUp.GetClaimStatus("In-Process");
            claim.ClaimStatusID = receivedStatus.ID;
            //claim.ClaimDate = DateTime.Now;

            // If Payeetype = Member, set member details. If Payeetype = Vendor, set Vendor details as payee name.

            MemberRepository memberRepository = new MemberRepository();
            Member member = memberRepository.Get(model.MemberID);

            string memberName = string.Format("{0} {1} {2}", member.FirstName, member.MiddleName, member.LastName);
            if (!string.IsNullOrEmpty(member.Suffix))
            {
                memberName += ", " + member.Suffix;
            }

            memberName = memberName.Trim();

            if (PayeeTypeName.VENDOR.Equals(model.PayeeType, StringComparison.InvariantCultureIgnoreCase))
            {
                logger.InfoFormat("Setting the payee name to Vendor details of vendor ID : {0}", model.VendorID);
                VendorManagementFacade vendorFacade = new VendorManagementFacade();
                if (model.VendorID.HasValue)
                {
                    var vendor = vendorFacade.Get(model.VendorID.Value);
                    claim.PaymentPayeeName = vendor.Name;
                    claim.ContactName = vendor.Name;
                    claim.ContactEmailAddress = vendor.Email;
                }
                else
                {
                    logger.Warn("Vendor ID is missing from Claim Input");
                }

                claim.VehicleOwnerName = memberName;
            }
            else
            {
                logger.InfoFormat("Setting the payee name to Member details of member ID : {0}", model.MemberID);
                
                claim.PaymentPayeeName = memberName;
                claim.ContactName = memberName;
                claim.ContactEmailAddress = member.Email;
                
            }

            if ("Motorhome Reimbursement".Equals(model.ClaimTypeText, StringComparison.InvariantCultureIgnoreCase))
            {
                var acesPendingStatus = lookUp.GetACESClaimStatus("Pending");
                claim.ACESClaimStatusID = acesPendingStatus.ID;
            }
            
            repository.SaveClaimInformation(claim, userName);

            return claim.ID;
        }

    }
}
