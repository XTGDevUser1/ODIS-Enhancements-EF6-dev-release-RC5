using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAO;

namespace Martex.DMS.BLL.Facade
{
    public partial class MemberManagementFacade
    {
        /// <summary>
        /// Gets the member info details.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public MemberInfoDetails GetMemberInfoDetails(int memberID)
        {
            return repository.GetMemberInfoDetails(memberID);
        }

        /// <summary>
        /// Saves the member info details.
        /// </summary>
        /// <param name="model">The model.</param>
        public void SaveMemberInfoDetails(MemberInfoDetails model, string userName)
        {
            EventLoggerFacade eventLogFacade = new EventLoggerFacade();
            if (model.SuffixName.Equals("Select")) { model.SuffixName = null; }
            if (model.PrefixName.Equals("Select")) { model.PrefixName = null; }
            using (TransactionScope transaction = new TransactionScope())
            {
                repository.SaveMemberInfoDetails(model, userName);
                long eventID = eventLogFacade.LogEvent(null, EventNames.UPDATE_MEMBER, "Saving Member Info Details", userName, null);
                eventLogFacade.CreateRelatedLogLinkRecord(eventID, model.MemberID, EntityNames.MEMBER);
                eventLogFacade.CreateRelatedLogLinkRecord(eventID, model.MembershipID, EntityNames.MEMBERSHIP);
                transaction.Complete();
            }
        }

        /// <summary>
        /// Gets the member details by identifier.
        /// </summary>
        /// <param name="memberId">The member identifier.</param>
        /// <returns></returns>
        public MemberApiModel GetMemberDetailsById(int memberId)
        {
            return repository.GetMemberDetailsById(memberId);
        }

        /// <summary>
        /// Saves the member details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public MemberApiModel SaveMemberDetails(MemberApiModel model)
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                var memberExists = false;
                CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
                AddressRepository addressRepository = new AddressRepository();
                VehicleRepository vehicleRepo = new VehicleRepository();
                PhoneRepository phoneRepository = new PhoneRepository();
                SourceSystem webServiceSourceSystem = lookUpRepo.GetSourceSystem(SourceSystemName.WEB_SERVICE);
                if (model.InternalCustomerID != null)
                {
                    var member = repository.GetMemberDetailsById(model.InternalCustomerID.GetValueOrDefault());
                    if (member != null)
                    {
                        memberExists = true;
                    }
                }
                //1. Save/Update Membership
                model = repository.SaveMembershipDetailsFromWebRequest(model);

                //2. Save/Update Member
                model = repository.SaveMemberDetailsFromWebRequest(model);

                Country memberCountry = lookUpRepo.GetCountryByCode(model.CountryCode);

                //3. Save/Update Address
                AddressEntity addressEntity = addressRepository.GetAddressesForEntity(EntityNames.MEMBER, model.InternalCustomerID, AddressTypeNames.HOME);
                if (addressEntity != null)
                {
                    if (!string.IsNullOrEmpty(model.Address1))
                    {
                        addressEntity.Line1 = model.Address1;
                    }
                    if (!string.IsNullOrEmpty(model.Address2))
                    {
                        addressEntity.Line2 = model.Address2;
                    }
                    if (!string.IsNullOrEmpty(model.City))
                    {
                        addressEntity.City = model.City;
                    }
                    if (!string.IsNullOrEmpty(model.PostalCode))
                    {
                        addressEntity.PostalCode = model.PostalCode;
                    }
                    if (!string.IsNullOrEmpty(model.StateProvince))
                    {
                        addressEntity.StateProvince = model.StateProvince;
                        addressEntity.StateProvinceID = lookUpRepo.GetStateProvinceByAbbreviation(model.StateProvince).ID;
                    }
                    if (!string.IsNullOrEmpty(model.CountryCode))
                    {
                        addressEntity.CountryCode = model.CountryCode;
                        addressEntity.CountryID = memberCountry.ID;
                    }
                    else
                    {
                        model.CountryCode = addressEntity.CountryCode;
                    }
                    addressEntity.ModifyDate = DateTime.Now;
                    addressEntity.ModifyBy = model.CurrentUser;
                }
                else
                {
                    if (!string.IsNullOrEmpty(model.Address1) && !string.IsNullOrEmpty(model.City) && !string.IsNullOrEmpty(model.StateProvince) && !string.IsNullOrEmpty(model.CountryCode) && !string.IsNullOrEmpty(model.PostalCode))
                    {
                        addressEntity = new AddressEntity()
                        {
                            RecordID = model.InternalCustomerID,
                            AddressTypeID = lookUpRepo.GetAddressTypeByName(AddressTypeNames.HOME).ID,
                            Line1 = model.Address1,
                            Line2 = model.Address2,
                            City = model.City,
                            PostalCode = model.PostalCode,
                            StateProvince = model.StateProvince,
                            StateProvinceID = string.IsNullOrEmpty(model.StateProvince) ? (int?)null : lookUpRepo.GetStateProvinceByAbbreviation(model.StateProvince).ID,
                            CountryCode = model.CountryCode,
                            CountryID = memberCountry != null ? memberCountry.ID : (int?)null,
                            CreateDate = DateTime.Now,
                            CreateBy = model.CurrentUser
                        };
                    }
                }
                if (addressEntity != null)
                {
                    logger.InfoFormat("Saving Address for member ID {0}", model.InternalCustomerID);
                    addressRepository.Save(addressEntity, EntityNames.MEMBER);
                    model.AddressEntityID = addressEntity.ID;
                }
                if (memberExists)
                {
                    var phonesList = phoneRepository.GetPhonesForEntity(EntityNames.MEMBER, model.InternalCustomerID);
                    if (phonesList != null)
                    {
                        foreach (var phone in phonesList)
                        {
                            if ((phone.PhoneType != null && phone.PhoneType.Name.Equals(model.PhoneType)) ||
                                (model.AltPhoneType != null && model.AltPhoneType.Equals(phone.PhoneType.Name)))
                            {
                                phoneRepository.Delete(phone.ID);
                            }
                        }
                    }
                }
                memberCountry = lookUpRepo.GetCountryByCode(model.PhoneCountryCode);
                if (model.PhoneNumber != null)
                {
                    //4. Save Primary Phone
                    PhoneType primaryPhoneType = lookUpRepo.GetPhoneTypeByName(model.PhoneType);
                    if (primaryPhoneType == null)
                    {
                        primaryPhoneType = lookUpRepo.GetPhoneTypeByName(PhoneTypeNames.Cell);
                    }
                    var phoneTypeID = primaryPhoneType != null ? primaryPhoneType.ID : 1;
                    var formattedPhoneNumber = string.Format("{0} {1}", memberCountry != null? memberCountry.TelephoneCode : string.Empty, model.PhoneNumber);

                    PhoneEntity primaryPhone = new PhoneEntity()
                    {
                        RecordID = model.InternalCustomerID.GetValueOrDefault(),
                        PhoneTypeID = phoneTypeID,
                        PhoneNumber = formattedPhoneNumber,
                        Sequence = 0,
                        CreateDate = DateTime.Now,
                        CreateBy = model.CurrentUser
                    };
                    logger.InfoFormat("Saving Primary Phone for member ID {0}", model.InternalCustomerID);
                    phoneRepository.Save(primaryPhone, EntityNames.MEMBER, false);
                    model.PrimaryPhoneEntityID = primaryPhone.ID;
                }
                //5. Save Alternate Phone
                PhoneEntity alternatePhone = new PhoneEntity();
                if (model.AltPhoneNumber != null)
                {
                    memberCountry = lookUpRepo.GetCountryByCode(model.AltPhoneCountryCode);
                    PhoneType alternatePhoneType = lookUpRepo.GetPhoneTypeByName(model.AltPhoneType);
                    if (alternatePhoneType == null)
                    {
                        alternatePhoneType = lookUpRepo.GetPhoneTypeByName(PhoneTypeNames.Cell);
                    }
                    var altPhoneTypeID = alternatePhoneType.ID;
                    var altPhoneNumber = string.Format("{0} {1}", memberCountry != null ? memberCountry.TelephoneCode : string.Empty, model.AltPhoneNumber);
                    alternatePhone = new PhoneEntity()
                    {
                        RecordID = model.InternalCustomerID.GetValueOrDefault(),
                        PhoneTypeID = altPhoneTypeID,
                        PhoneNumber = altPhoneNumber,
                        Sequence = 0,
                        CreateDate = DateTime.Now,
                        CreateBy = model.CurrentUser
                    };
                    logger.InfoFormat("Saving Alternate Phone Number for member ID {0}", model.InternalCustomerID);
                    phoneRepository.Save(alternatePhone, EntityNames.MEMBER, false);
                    model.AltPhoneEntityID = alternatePhone.ID;
                }

                //6. Save Vehicle Details
                if (!string.IsNullOrEmpty(model.VehicleVIN) || !(string.IsNullOrEmpty(model.VehicleMake) || string.IsNullOrEmpty(model.VehicleModel) || model.VehicleYear == null))
                {
                    /*
                     * If any vehicle information is passed, then validate that either a Valid VIN or Year, Make AND Model is passed.  
                     * Do not accept incomplete vehicle information.  
                     * If VIN is passed, then accept all other fields as is.  
                     * If Valid or any VIN is not passed, then require all 3 Year, Make AND Model if any one of those is passed in.
                     */
                    logger.InfoFormat("Trying to save Vehicle details for member ID {0}", model.InternalCustomerID);
                    vehicleRepo.SaveOrUpdateVehicleTypeDetailsForWebService(model);
                }
                transaction.Complete();
            }
            return model;
        }


    }
}
