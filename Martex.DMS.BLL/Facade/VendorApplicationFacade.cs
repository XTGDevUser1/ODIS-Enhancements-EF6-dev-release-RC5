using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using VendorPortal.BLL.Models;
using log4net;
using System.Transactions;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using System.Web.Hosting;
using System.IO;
using System.Web;

namespace Martex.DMS.BLL.Facade
{
    public class VendorApplicationFacade
    {
        protected static ILog logger = LogManager.GetLogger(typeof(VendorApplicationFacade));

        /// <summary>
        /// Saves the specified application.
        /// </summary>
        /// <param name="application">The application.</param>
        public VendorApplication Save(VendorApplicationModel application, string eventSource, string session)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                #region 1. VendorApplication
                //1. VendorApplication
                VendorApplication va = GetVendorApplicationFromRequest(application);
                VendorApplicationRepository vaRepository = new VendorApplicationRepository();
                logger.Info("Adding Vendor Application");
                vaRepository.Add(va);
                logger.Info("Added Vendor Application Successfully");
                #endregion
               
                #region 2. Address
                //2. Addresses                
                FillAddressEntity(application.PhysicalAddress, "Business");
                if (!application.IsBillingAddressDifferent)
                {
                    CopyBusinessToBilling(application.PhysicalAddress, application.BillingAddress);
                }
                FillAddressEntity(application.BillingAddress, "Billing");

                if (!application.IsW9DifferentThanBilling)
                {
                    CopyBusinessToBilling(application.BillingAddress, application.W9Address);
                }
                FillAddressEntity(application.W9Address, "Tax");

                List<AddressEntity> vaAddresses = new List<AddressEntity>();

                vaAddresses.Add(application.PhysicalAddress);
                vaAddresses.Add(application.BillingAddress);
                vaAddresses.Add(application.W9Address);

                logger.Info("Adding 3 (Business, Billing and Tax) Address Entities for Vendor Application");
                var addressFacade = new AddressFacade();
                addressFacade.SaveAddresses(va.ID, EntityNames.VENDOR_APPLICATION, application.DBA, vaAddresses, AddressFacade.ADD);
                #endregion

                #region 3. Phone
                //3. Phone
                var phoneFacade = new PhoneFacade();
                var phoneEntities = new List<PhoneEntity>();

                var officePhone = GetPhoneEntity(application.OfficePhone.PhoneNumber, "Office");
                phoneEntities.Add(officePhone);

                var dispatchPhone = GetPhoneEntity(application.DispatchPhone.PhoneNumber, "Dispatch");
                phoneEntities.Add(dispatchPhone);


                PhoneEntity faxPhone = null;
                if (application.FaxPhone != null && !string.IsNullOrWhiteSpace(application.FaxPhone.PhoneNumber))
                {
                    faxPhone = GetPhoneEntity(application.FaxPhone.PhoneNumber, "Fax");
                    phoneEntities.Add(faxPhone);
                }
                PhoneEntity cellPhone = null;
                if (!string.IsNullOrEmpty(application.BusinessCellPhone.PhoneNumber))
                {
                    cellPhone = GetPhoneEntity(application.BusinessCellPhone.PhoneNumber, "Cell");
                    phoneEntities.Add(cellPhone);
                }

                PhoneEntity insurancePhone = GetPhoneEntity(application.InsurancePhoneNumber.PhoneNumber, "Insurance");
                phoneEntities.Add(insurancePhone);

                logger.InfoFormat("Adding {0} [ Office, Dispatch, Fax, Cell* and Insurance ] Phone records for Vendor Application", phoneEntities.Count);

                phoneFacade.SavePhoneDetails(va.ID, EntityNames.VENDOR_APPLICATION, application.DBA, phoneEntities, PhoneFacade.ADD);
                #endregion

                #region 4. Payment Types
                //4. Payment types

                AddPaymentType(application, va.ID);
                #endregion

                #region 5. Products / Services
                //5. Products / Services
                var services = new List<string>();
                if (application.Services != null)
                {
                    services = application.Services.Where(x => !x.Equals("false")).ToList<string>();
                    logger.InfoFormat("Adding {0} products for Vendor Application {1}", services.Count, va.ID);
                    vaRepository.AddProducts(va.ID, services);
                }
                #endregion

                #region 6. Postal Codes
                //6. Postal Codes
                List<string> postalCodes = new List<string>();
                if (!string.IsNullOrEmpty(application.PrimaryZipCodesAsCSV))
                {
                    postalCodes = application.PrimaryZipCodesAsCSV.Split(',',' ','\r','\n').ToList<string>();

                    logger.InfoFormat("Saving Primary Postal codes {0}", application.PrimaryZipCodesAsCSV);
                    vaRepository.AddPostalCodes(va.ID, postalCodes);
                }

                if (!string.IsNullOrEmpty(application.SecondaryZipCodesAsCSV))
                {
                    postalCodes = application.SecondaryZipCodesAsCSV.Split(',', ' ', '\r', '\n').ToList<string>();
                    logger.InfoFormat("Saving Secondary Postal codes {0}", application.SecondaryZipCodesAsCSV);
                    vaRepository.AddPostalCodes(va.ID, postalCodes, true);
                }
                #endregion

                #region 7. EventLog and links
                //7. EventLog and links

                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                logger.Info("Event logs for Vendor Application");
                eventLogFacade.LogEvent(eventSource, EventNames.ADD_VENDOR_APPLICATION, (string)null, application.DBA, va.ID, EntityNames.VENDOR_APPLICATION, null);
                #endregion

                #region 8. Vendor
                //8. Vendor
                Vendor v = GetVendorFromRequest(application);
                if (application.CertificateOfInsurance != null)
                {
                    v.IsInsuranceCertificateOnFile = true;
                }
                VendorManagementRepository vendorRepo = new VendorManagementRepository();
                //TODO: SourceMethod to be set to web.
                v.VendorNumber = application.PhysicalAddress.StateProvinceID.ToString();

                var ss = vendorRepo.GetSourceSystem("VendorPortal");
                if (ss == null)
                {
                    throw new DMSException("Source system - VendorPortal is not set up in the system");
                }
                v.SourceSystemID = ss.ID;

                vendorRepo.AddVendor(v, "VendorPortal");

                // Set vendorID on VendorApplication.
                logger.Info("Set the vendorID on VendorApplicationID");
                vaRepository.SetVendorID(va.ID, v.ID);
                va.VendorID = v.ID;
                #endregion

                #region 9. Vendor Address
                //9. Vendor Address
                var vBusinessAddress = application.PhysicalAddress.Clone();
                var vBillingAddress = application.BillingAddress.Clone();

                //Reuse an existing list.
                vaAddresses.Clear();

                vaAddresses.Add(vBusinessAddress);
                vaAddresses.Add(vBillingAddress);

                logger.Info("Adding 2 [ Business and Billing ] Address Entities for Vendor");
                addressFacade.SaveAddresses(v.ID, EntityNames.VENDOR, application.DBA, vaAddresses, AddressFacade.ADD);
                #endregion

                #region 10. Vendor Phone
                //10. Vendor Phone
                //Reuse existing list
                phoneEntities.Clear();

                officePhone = officePhone.Clone();
                phoneEntities.Add(officePhone);

                if (faxPhone != null)
                {
                    faxPhone = faxPhone.Clone();
                    phoneEntities.Add(faxPhone);
                }

                insurancePhone = insurancePhone.Clone();
                phoneEntities.Add(insurancePhone);

                logger.Info("Adding 3 [ Office, Fax and Insurance ] Phone records for Vendor");
                phoneFacade.SavePhoneDetails(v.ID, EntityNames.VENDOR, application.DBA, phoneEntities, PhoneFacade.ADD);
                #endregion

                #region 11. Vendor Product

                //11. Vendor Product
                logger.InfoFormat("Adding {0} products for Vendor {1}", services.Count, v.ID);
                vendorRepo.SaveVendorServices(v.ID, services, va.CreateDate, va.CreateBy);

                #endregion

                #region 12. Contract
                //12. Contract

                Contract c = new Contract();
                c.VendorApplicationID = va.ID;
                c.VendorID = v.ID;

                c.SourceSystemID = ss.ID;

                var cs = vendorRepo.GetContractStatus("Pending");
                if (cs == null)
                {
                    throw new DMSException("Contract Status - Pending is not set up in the system");
                }
                c.ContractStatusID = cs.ID;

                c.VendorTermsAgreementID = vendorRepo.GetVendorTermsAgreementID();

                c.SignedBy = application.WitnessName;
                c.SignedDate = va.ApplicationSignedDate;
                c.SignedByTitle = application.WitnessTitle;
                c.IsActive = true;
                c.CreateBy = "system";
                c.CreateDate = DateTime.Now;

                logger.Info("Saving Contract");
                vendorRepo.SaveContract(c);
                #endregion

                #region 13. Vendor Location
                //13. Vendor Location
                VendorLocation vl = GetVendorLocation(application);
                vl.VendorID = v.ID;

                VendorManagementRepository vmRepository = new VendorManagementRepository();
                logger.Info("Added Vendor location");
                vmRepository.AddVendorLocation(vl);

                var addressRepo = new AddressRepository();
                addressRepo.UpdateGeographyType(vl.ID, EntityNames.VENDOR_LOCATION);
                #endregion

                #region 14. Vendor Location Address (Business)
                //14. Vendor Location Address (Business)

                vBusinessAddress = application.PhysicalAddress.Clone();

                //Reuse an existing list.
                vaAddresses.Clear();

                vaAddresses.Add(vBusinessAddress);

                logger.Info("Adding 1 Address Entity for Vendor Location");
                addressFacade.SaveAddresses(vl.ID, EntityNames.VENDOR_LOCATION, application.DBA, vaAddresses, AddressFacade.ADD);
                #endregion

                #region 15.Vendor Location Phone (Office)
                //15. Vendor Location Phone (Office)

                //Reuse existing list
                phoneEntities.Clear();

                if (faxPhone != null)
                {
                    faxPhone = faxPhone.Clone();
                    phoneEntities.Add(faxPhone);
                }

                dispatchPhone = dispatchPhone.Clone();
                phoneEntities.Add(dispatchPhone);

                if (cellPhone != null)
                {
                    cellPhone = cellPhone.Clone();
                    phoneEntities.Add(cellPhone);
                }

                logger.InfoFormat("Adding {0} [ Fax, Dispatch and Cell* ] Phone records for Vendor Location", phoneEntities.Count);
                phoneFacade.SavePhoneDetails(vl.ID, EntityNames.VENDOR_LOCATION, application.DBA, phoneEntities, PhoneFacade.ADD);
                #endregion

                #region 16. Business Hours
                //16. Vendor location Business hours.
                logger.Info("Processing business hours");
                vmRepository.SaveBusinessHours(vl.ID, application.BusinessHours, application.DBA);

                // Vendor Application Business hours.
                logger.Info("Processing Vendor Application business hours");
                vaRepository.SaveBusinessHours(va.ID, application.BusinessHours, application.DBA);
                #endregion

                #region 17. Postal Codes
                //17. Postal Codes
                logger.Info("Processing zip codes for VendorLocation");
                vmRepository.SaveZipCodes(vl.ID, application.PrimaryZipCodesAsCSV, application.DBA);
                vmRepository.SaveZipCodes(vl.ID, application.SecondaryZipCodesAsCSV, application.DBA, true);

                logger.Info("Processing Vendor Location payment types");
                AddPaymentTypeForVendorLocation(application, vl.ID);
                #endregion

                #region 18. Event Log and links
                //18. Event Log and links
                logger.Info("Event logs for Vendor");
                eventLogFacade.LogEvent(eventSource, EventNames.ADD_VENDOR, (string)null, application.DBA, v.ID, EntityNames.VENDOR, null);
                #endregion

                #region 19.Save the uploaded file.
                //19. Save the uploaded file.
                var targetFolder = AppConfigRepository.GetValue(AppConfigConstants.INSURANCE_CERTIFICATE_PATH);
                if (targetFolder == null)
                {
                    throw new DMSException(string.Format("App config item {0} not configured in the system", AppConfigConstants.INSURANCE_CERTIFICATE_PATH));
                }
                var targetPath = HostingEnvironment.MapPath("~/" + targetFolder);
                DirectoryInfo di = new DirectoryInfo(targetPath);
                if (!di.Exists)
                {
                    di.Create();
                }
                if (application.CertificateOfInsurance != null)
                {
                    var identifier = Guid.NewGuid();
                    HttpPostedFileBase fileBase = application.CertificateOfInsurance;
                    FileInfo fi = new FileInfo(fileBase.FileName);
                    string fileNameFromRequest = fi.Name;
                    string targetFileName = Path.Combine(targetPath, identifier.ToString()) + "_" + fileNameFromRequest;
                    logger.InfoFormat("Saving file to {0}", targetFileName);
                    fileBase.SaveAs(targetFileName);
                    vaRepository.UpdateInsuranceFileName(va.ID, targetFileName);

                    logger.InfoFormat("Saving document {0} against Vendor ID {1}", fileNameFromRequest, v.ID);
                    // Save the document to the Documents table.
                    DocumentFacade docFacade = new DocumentFacade();
                    Document document = new Document();
                    document.CreateDate = DateTime.Now;
                    document.CreateBy = application.DBA;

                    var docCategory = ReferenceDataRepository.GetDocumentCategoryByName("Application");
                    if (docCategory == null)
                    {
                        throw new DMSException("Document Category : Application is not set up in the system");
                    }
                    document.DocumentCategoryID = docCategory.ID;
                    document.Name = fileNameFromRequest;

                    document.RecordID = v.ID;
                    BinaryReader b = new BinaryReader(fileBase.InputStream);
                    byte[] binData = b.ReadBytes(fileBase.ContentLength);
                    document.DocumentFile = binData;
                    document.IsShownOnVendorPortal = true;
                    docFacade.AddDocument(document, EntityNames.VENDOR, eventSource, application.DBA, session, v.ID);

                    logger.InfoFormat("Document saved successfully against Vendor ID {0}", v.ID);
                }
                #endregion

                tran.Complete();

                return va;
            }

        }

        /// <summary>
        /// Gets the vendor location.
        /// </summary>
        /// <param name="application">The application.</param>
        /// <returns></returns>
        private VendorLocation GetVendorLocation(VendorApplicationModel application)
        {
            VendorLocation vl = new VendorLocation();
            VendorManagementRepository vmRepo = new VendorManagementRepository();

            vl.Email = application.Email;
            var vls = vmRepo.GetVendorLocationStatusByName("Pending");
            if (vls == null)
            {
                throw new DMSException("Vendor Location Status - Pending - is not set up in the system");
            }
            vl.VendorLocationStatusID = vls.ID;
            //TODO: Fix VendorLocationType
            var physicalAddress = application.PhysicalAddress;
            LatitudeLongitude latLong = AddressFacade.GetLatLong(string.Join(",", physicalAddress.Line1, physicalAddress.Line2, physicalAddress.Line3), physicalAddress.City, physicalAddress.StateProvince, physicalAddress.PostalCode, physicalAddress.CountryCode);

            vl.Latitude = latLong.Latitude;
            vl.Longitude = latLong.Longitude;
            vl.IsKeyDropAvailable = application.IsKeyDropAvailable;
            vl.IsOvernightStayAllowed = application.IsOvernightStayAllowed;

            vl.IsElectronicDispatchAvailable = application.SupportForElectronicDispatch;
            vl.IsUsingZipCodes = (!string.IsNullOrEmpty(application.PrimaryZipCodesAsCSV) || !string.IsNullOrEmpty(application.SecondaryZipCodesAsCSV));
            vl.IsOpen24Hours = application.Open24X7;
            vl.IsAbleToCrossNationalBorders = application.IsAbleToCrossNationalBorders;
            vl.IsAbleToCrossStateLines = application.IsAbleToCrossStateLines;

            vl.IsActive = true;
            vl.CreateDate = DateTime.Now;
            vl.CreateBy = application.DBA;

            return vl;
        }



        /// <summary>
        /// Gets the vendor from request.
        /// </summary>
        /// <param name="application">The application.</param>
        /// <returns></returns>
        private Vendor GetVendorFromRequest(VendorApplicationModel application)
        {
            Vendor v = new Vendor();

            v.Name = application.DBA;
            v.CorporationName = application.CorporateName;

            v.Website = application.Website;
            v.Email = application.Email;

            v.ContactFirstName = application.ContactFirstName;
            v.ContactLastName = application.ContactLastName;


            v.DepartmentOfTransportationNumber = application.DotNumber;
            v.MotorCarrierNumber = application.MotorCarrierNumber;
            v.IsEmployeeBackgroundChecked = application.PreEmploymentBackgroundCheck;
            v.IsEmployeeDrugTested = application.RandomDrugTesting;
            v.IsDriverUniformed = application.HasUniformedDrivers;
            v.IsEachServiceTruckMarked = application.VehiclesDisplayCompanyName;


            v.TaxEIN = application.EmployerIdentificationNumber;
            v.TaxSSN = application.SSN;

            // TFS: 1498
            v.IsW9OnFile = !string.IsNullOrEmpty(application.ElectronicSignature);

            v.InsuranceCarrierName = application.InsuranceCarrierName;
            int adminRating = 0;
            int.TryParse(AppConfigRepository.GetValue(AppConfigConstants.VENDOR_ADMIN_RATING_DEFAULT), out adminRating);
            v.AdministrativeRating = adminRating;

            v.AdministrativeRatingModifyDate = DateTime.Now;

            v.IsActive = true;

            v.CreateBy = application.DBA;
            v.CreateDate = DateTime.Now;

            v.W9SignedBy = application.ElectronicSignature;
            v.TaxClassification = application.TaxClassification;
            if ("other".Equals(application.TaxClassification, StringComparison.InvariantCultureIgnoreCase))
            {
                v.TaxClassificationOther = application.OtherTaxPayerDescription;
            }

            CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();

            #region 0. Get the Vendor Region Associated with this Address
            VendorRegion vendorRegion = null;
            if (application.PhysicalAddress.StateProvinceID.HasValue)
            {
                vendorRegion = lookUpRepo.GetVendorRegionByStateID(application.PhysicalAddress.StateProvinceID.Value);
            }
            else
            {
                throw new DMSException(string.Format("State selection is required"));
            }

            v.VendorRegionID = vendorRegion.ID;

            #endregion

            /*Software fields*/
            v.DispatchGPSNetworkID = application.DispatchGPSNetworkID;
            v.DispatchGPSNetworkOther = application.DispatchGPSNetworkOther;
            v.DispatchSoftwareProductID = application.DispatchSoftwareProductID;
            v.DispatchSoftwareProductOther = application.DispatchSoftwareProductOther;
            v.DriverSoftwareProductID = application.DriverSoftwareProductID;
            v.DriverSoftwareProductOther = application.DriverSoftwareProductOther;

            v.IsVirtualLocationEnabled = false;

            return v;

        }



        /// <summary>
        /// Adds the type of the payment.
        /// </summary>
        /// <param name="va">The va.</param>
        /// <param name="applicationID">The application ID.</param>
        private void AddPaymentType(VendorApplicationModel va, int recordID)
        {
            VendorApplicationPaymentTypeRepository vaptRepository = new VendorApplicationPaymentTypeRepository();
            VendorApplicationPaymentType vaPaymentType = null;
            //TODO: Take the values as CSV.
            if (va.Cash)
            {
                vaPaymentType = new VendorApplicationPaymentType();
                vaPaymentType.VendorApplicationID = recordID;
                logger.Info("Adding Cash");
                vaptRepository.Add(vaPaymentType, "Cash");
            }

            if (va.PersonalCheck)
            {
                vaPaymentType = new VendorApplicationPaymentType();
                vaPaymentType.VendorApplicationID = recordID;
                logger.Info("Adding check");
                vaptRepository.Add(vaPaymentType, "Check");
            }

            if (va.Visa)
            {
                vaPaymentType = new VendorApplicationPaymentType();
                vaPaymentType.VendorApplicationID = recordID;
                logger.Info("Adding VISA");
                vaptRepository.Add(vaPaymentType, "Visa");
            }

            if (va.MasterCard)
            {
                vaPaymentType = new VendorApplicationPaymentType();
                vaPaymentType.VendorApplicationID = recordID;
                logger.Info("Adding MasterCard");
                vaptRepository.Add(vaPaymentType, "MasterCard");
            }


            if (va.AmericanExpress)
            {
                vaPaymentType = new VendorApplicationPaymentType();
                vaPaymentType.VendorApplicationID = recordID;
                logger.Info("Adding Amex");
                vaptRepository.Add(vaPaymentType, "AmericanExpress");
            }

            if (va.Discover)
            {
                vaPaymentType = new VendorApplicationPaymentType();
                vaPaymentType.VendorApplicationID = recordID;
                logger.Info("Adding Discover");
                vaptRepository.Add(vaPaymentType, "Discover");
            }

        }


        /// <summary>
        /// Adds the type of the payment.
        /// </summary>
        /// <param name="va">The va.</param>
        /// <param name="applicationID">The application ID.</param>
        private void AddPaymentTypeForVendorLocation(VendorApplicationModel va, int recordID)
        {
            VendorManagementRepository vlptRepository = new VendorManagementRepository();

            //TODO: Take the values as CSV.
            if (va.Cash)
            {

                logger.Info("Adding Cash");
                vlptRepository.AddVendorLocationPaymentType(new VendorLocationPaymentType()
                {
                    VendorLocationID = recordID,
                    IsActive = true,
                    CreateDate = DateTime.Now,
                    CreateBy = va.DBA
                }, "Cash");
            }

            if (va.PersonalCheck)
            {

                logger.Info("Adding check");
                vlptRepository.AddVendorLocationPaymentType(new VendorLocationPaymentType()
                {
                    VendorLocationID = recordID,
                    IsActive = true,
                    CreateDate = DateTime.Now,
                    CreateBy = va.DBA
                }, "Check");
            }

            if (va.Visa)
            {

                logger.Info("Adding VISA");
                vlptRepository.AddVendorLocationPaymentType(new VendorLocationPaymentType()
                {
                    VendorLocationID = recordID,
                    IsActive = true,
                    CreateDate = DateTime.Now,
                    CreateBy = va.DBA
                }, "Visa");
            }

            if (va.MasterCard)
            {

                logger.Info("Adding MasterCard");
                vlptRepository.AddVendorLocationPaymentType(new VendorLocationPaymentType()
                {
                    VendorLocationID = recordID,
                    IsActive = true,
                    CreateDate = DateTime.Now,
                    CreateBy = va.DBA
                }, "MasterCard");

            }


            if (va.AmericanExpress)
            {
                logger.Info("Adding Amex");
                vlptRepository.AddVendorLocationPaymentType(new VendorLocationPaymentType()
                {
                    VendorLocationID = recordID,
                    IsActive = true,
                    CreateDate = DateTime.Now,
                    CreateBy = va.DBA
                }, "AmericanExpress");

            }

            if (va.Discover)
            {
                logger.Info("Adding Discover");
                vlptRepository.AddVendorLocationPaymentType(new VendorLocationPaymentType()
                {
                    VendorLocationID = recordID,
                    IsActive = true,
                    CreateDate = DateTime.Now,
                    CreateBy = va.DBA
                }, "Discover");
            }

        }
        /// <summary>
        /// Copies the business to billing.
        /// </summary>
        /// <param name="business">The business.</param>
        /// <param name="billing">The billing.</param>
        private void CopyBusinessToBilling(AddressEntity business, AddressEntity billing)
        {
            billing.Line1 = business.Line1;
            billing.Line2 = business.Line2;
            billing.Line3 = business.Line3;

            billing.City = business.City;
            billing.CountryID = business.CountryID;
            billing.StateProvinceID = business.StateProvinceID;
            billing.PostalCode = business.PostalCode;
        }

        /// <summary>
        /// Gets the vendor application from request.
        /// </summary>
        /// <param name="application">The application.</param>
        /// <returns></returns>
        private VendorApplication GetVendorApplicationFromRequest(VendorApplicationModel application)
        {
            VendorApplication va = new VendorApplication();

            va.Name = application.DBA;
            va.CorporationName = application.CorporateName;

            va.VendorApplicationReferralSourceID = application.HeardFrom;

            va.Website = application.Website;
            va.Email = application.Email;

            va.ContactFirstName = application.ContactFirstName;
            va.ContactLastName = application.ContactLastName;
            va.IsOpen24Hours = application.Open24X7;

            va.IsKeyDropAvailable = application.IsKeyDropAvailable;
            va.IsOvernightStayAllowed = application.IsOvernightStayAllowed;

            va.DepartmentOfTransportationNumber = application.DotNumber;
            va.MotorCarrierNumber = application.MotorCarrierNumber;
            va.IsEmployeeBackgroundChecked = application.PreEmploymentBackgroundCheck;
            va.IsEmployeeDrugTested = application.RandomDrugTesting;
            va.IsDriverUniformed = application.HasUniformedDrivers;
            va.IsEachServiceTruckMarked = application.VehiclesDisplayCompanyName;

            va.IsElectronicDispatch = application.SupportForElectronicDispatch;
            va.IsFaxDispatch = application.SupportForFax;
            va.IsEmailDispatch = application.SupportForEmail;
            va.IsTextDispatch = application.SupportForText;

            va.MaxTowingGVWR = application.MaxGVW;
            va.TotalServiceVehicleCount = application.TotalNumberOfVehicles;


            va.TaxEIN = application.EmployerIdentificationNumber;
            va.TaxSSN = application.SSN;

            va.TaxClassification = application.TaxClassification;
            if ("other".Equals(application.TaxClassification, StringComparison.InvariantCultureIgnoreCase))
            {
                va.TaxClassificationOther = application.OtherTaxPayerDescription;
            }

            va.W9SignedBy = application.ElectronicSignature;

            va.InsuranceCarrierName = application.InsuranceCarrierName;

            va.ApplicationSignedByName = application.WitnessName;
            va.ApplicationSignedByTitle = application.WitnessTitle;

            va.CreateBy = application.DBA;
            va.CreateDate = DateTime.Now;

            va.ApplicationComments = application.ApplicationComments;
            /*Software fields*/
            va.DispatchGPSNetworkID = application.DispatchGPSNetworkID;
            va.DispatchGPSNetworkOther = application.DispatchGPSNetworkOther;
            va.DispatchSoftwareProductID = application.DispatchSoftwareProductID;
            va.DispatchSoftwareProductOther = application.DispatchSoftwareProductOther;
            va.DriverSoftwareProductID = application.DriverSoftwareProductID;
            va.DriverSoftwareProductOther = application.DriverSoftwareProductOther;


            va.ApplicationSignedDate = application.SignedDate;
            return va;

        }

        /// <summary>
        /// Fills the address entity with Country code, state province abbreviation and address type
        /// </summary>
        /// <param name="address">The address.</param>
        /// <param name="addressType">Type of the address.</param>
        private static void FillAddressEntity(AddressEntity address, string addressType)
        {
            CommonLookUpRepository lookupRepo = new CommonLookUpRepository();
            if (address.CountryID != null)
            {
                Country country = lookupRepo.GetCountry(address.CountryID.Value);
                address.CountryCode = country.ISOCode;
            }
            if (address.StateProvinceID != null)
            {
                StateProvince s = lookupRepo.GetStateProvince(address.StateProvinceID.Value);
                address.StateProvince = s.Abbreviation;
            }
            AddressRepository addressRepo = new AddressRepository();
            var addressTypeFromDB = addressRepo.GetAddressTypeByName(addressType);
            if (addressTypeFromDB == null)
            {
                throw new DMSException(string.Format("Address type - {0} is not set up in the system", addressType));
            }
            address.AddressTypeID = addressTypeFromDB.ID;

        }


        /// <summary>
        /// Gets the phone entity.
        /// </summary>
        /// <param name="phoneNumber">The phone number.</param>
        /// <param name="phoneType">Type of the phone.</param>
        /// <returns></returns>
        private static PhoneEntity GetPhoneEntity(string phoneNumber, string phoneType)
        {
            PhoneRepository phoneRepository = new PhoneRepository();

            var phoneTypeFromDB = phoneRepository.GetPhoneTypeByName(phoneType);

            if (phoneTypeFromDB == null)
            {
                throw new DMSException(string.Format("Phone Type - {0} is not set up in the system", phoneType));
            }

            PhoneEntity phone = null;
            //CR: 1130 - Do not create phone records when the phone number is empty
            if (!string.IsNullOrEmpty(phoneNumber))
            {
                phone = new PhoneEntity() { PhoneNumber = phoneNumber, PhoneTypeID = phoneTypeFromDB.ID };
            }
            return phone;
        }

        /// <summary>
        /// Gets the services.
        /// </summary>
        /// <returns></returns>
        public List<ServicesForVendorPortal_Result> GetServices()
        {
            VendorApplicationRepository repository = new VendorApplicationRepository();
            return repository.GetServices();
        }

        /// <summary>
        /// Gets the vendor details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorApplicationModel GetVendorDetails(int vendorID)
        {
            VendorApplicationModel vendorDetails = new VendorApplicationModel();
            AddressRepository addressRepo = new AddressRepository();
            PhoneRepository phoneRepo = new PhoneRepository();

            List<AddressEntity> addressList = addressRepo.GetAddresses(vendorID, EntityNames.VENDOR);
            vendorDetails.BillingAddress = addressList.Where(a => a.AddressType.Name == AddressTypeNames.BILLING).FirstOrDefault();
            vendorDetails.BusinessAddress = addressList.Where(a => a.AddressType.Name == AddressTypeNames.Business).FirstOrDefault();

            List<PhoneEntity> phoneList = phoneRepo.Get(vendorID, EntityNames.VENDOR);
            vendorDetails.DispatchPhone = phoneList.Where(a => a.PhoneType.Name == PhoneTypeNames.Dispatch).FirstOrDefault();
            vendorDetails.FaxPhone = phoneList.Where(a => a.PhoneType.Name == PhoneTypeNames.Fax).FirstOrDefault();
            vendorDetails.OfficePhone = phoneList.Where(a => a.PhoneType.Name == PhoneTypeNames.Office).FirstOrDefault();

            //vendorDetails.DispatchPhone = phoneRepo.Get(vendorID, EntityNames.VENDOR, PhoneTypeNames.Dispatch);
            //vendorDetails.FaxPhone = phoneRepo.Get(vendorID, EntityNames.VENDOR, PhoneTypeNames.Fax);
            //vendorDetails.OfficePhone = phoneRepo.Get(vendorID, EntityNames.VENDOR, PhoneTypeNames.Office);

            return vendorDetails;
        }


        /// <summary>
        /// Saves the post login values.
        /// </summary>
        /// <param name="application">The application.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <param name="vendorUserID">The vendor user ID.</param>
        /// <param name="userID">The user ID.</param>
        public void SavePostLoginValues(VendorApplicationModel application, int vendorID, string currentUser, string eventSource, string sessionID, int? vendorUserID, Guid userID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                VendorApplicationRepository repository = new VendorApplicationRepository();

                #region 1. Updating Vendor Details
                VendorUser vendorUser = new VendorUser();
                vendorUser.ID = vendorUserID.GetValueOrDefault();
                vendorUser.FirstName = application.ContactFirstName;
                vendorUser.LastName = application.ContactLastName;
                repository.UpdateVendorUser(vendorID, currentUser, vendorUser);

                Vendor vendor = new Vendor();
                vendor.ID = vendorID;
                vendor.ContactFirstName = application.ContactFirstName;
                vendor.ContactLastName = application.ContactLastName;
                vendor.Email = application.Email;
                repository.UpdateVendorDetails(currentUser, vendor);

                repository.UpdateMembershipEmail(userID, application.Email);
                #endregion

                #region 2. Saving Addresses
                var addressFacade = new AddressFacade();
                List<AddressEntity> vaAddresses = new List<AddressEntity>();
                #region 1. Saving/Updating Billing Address
                FillAddressEntity(application.BillingAddress, AddressTypeNames.BILLING);
                vaAddresses.Add(application.BillingAddress);
                logger.InfoFormat("Updating Billing Address Entity for Vendor {0}", vendorID);

                if (application.BillingAddress.ID > 0)
                {
                    addressFacade.SaveAddresses(vendorID, EntityNames.VENDOR, currentUser, vaAddresses, AddressFacade.EDIT);
                }
                else
                {
                    addressFacade.SaveAddresses(vendorID, EntityNames.VENDOR, currentUser, vaAddresses, AddressFacade.ADD);
                }
                #endregion

                #region 2. Saving/Updating Business Address
                vaAddresses.Clear();
                FillAddressEntity(application.BusinessAddress, AddressTypeNames.Business);
                vaAddresses.Add(application.BusinessAddress);
                logger.InfoFormat("Updating Business Address Entity for Vendor {0}", vendorID);
                if (application.BusinessAddress.ID > 0)
                {
                    addressFacade.SaveAddresses(vendorID, EntityNames.VENDOR, currentUser, vaAddresses, AddressFacade.EDIT);
                }
                else
                {
                    addressFacade.SaveAddresses(vendorID, EntityNames.VENDOR, currentUser, vaAddresses, AddressFacade.ADD);
                }
                #endregion
                #endregion

                #region 3. Saving Phones
                var phoneFacade = new PhoneFacade();
                var phoneDispatchEntities = new List<PhoneEntity>();
                var phoneFaxEntities = new List<PhoneEntity>();
                var phoneOfficeEntities = new List<PhoneEntity>();

                #region 1. Saving/Updating Dispatch Phone
                var dispatchPhone = GetPhoneEntity(application.DispatchPhone.PhoneNumber, PhoneTypeNames.Dispatch);
                dispatchPhone.ID = application.DispatchPhone.ID;
                phoneDispatchEntities.Add(dispatchPhone);
                if (application.DispatchPhone.ID > 0)
                {
                    phoneFacade.SavePhoneDetails(vendorID, EntityNames.VENDOR, currentUser, phoneDispatchEntities, PhoneFacade.EDIT);
                }
                else
                {
                    phoneFacade.SavePhoneDetails(vendorID, EntityNames.VENDOR, currentUser, phoneDispatchEntities, PhoneFacade.ADD);
                }
                #endregion

                #region 2. Saving/Updating Fax Phone
                var faxPhone = GetPhoneEntity(application.FaxPhone.PhoneNumber, PhoneTypeNames.Fax);
                faxPhone.ID = application.FaxPhone.ID;
                phoneFaxEntities.Add(faxPhone);

                if (application.FaxPhone.ID > 0)
                {
                    phoneFacade.SavePhoneDetails(vendorID, EntityNames.VENDOR, currentUser, phoneFaxEntities, PhoneFacade.EDIT);
                }
                else
                {
                    phoneFacade.SavePhoneDetails(vendorID, EntityNames.VENDOR, currentUser, phoneFaxEntities, PhoneFacade.ADD);
                }
                #endregion

                #region 3. Saving/Updating Office Phone
                var officePhone = GetPhoneEntity(application.OfficePhone.PhoneNumber, PhoneTypeNames.Office);
                officePhone.ID = application.OfficePhone.ID;
                phoneOfficeEntities.Add(officePhone);
                if (application.OfficePhone.ID > 0)
                {
                    phoneFacade.SavePhoneDetails(vendorID, EntityNames.VENDOR, currentUser, phoneOfficeEntities, PhoneFacade.EDIT);
                }
                else
                {
                    phoneFacade.SavePhoneDetails(vendorID, EntityNames.VENDOR, currentUser, phoneOfficeEntities, PhoneFacade.ADD);
                }
                #endregion

                #endregion

                #region 4. Logging Event
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                long eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.INITIAL_LOGIN_VERIFY_DATA, "Initial Login Verify Data", currentUser, vendorID, EntityNames.VENDOR, sessionID);
                #endregion

                tran.Complete();
            }
        }

        public string GetVendorUserName(string vendorNumber)
        {
            VendorApplicationRepository repository = new VendorApplicationRepository();
            return repository.GetVendorUserName(vendorNumber);
        }
    }
}
