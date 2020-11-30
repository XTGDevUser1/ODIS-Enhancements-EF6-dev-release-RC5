using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;
using System.Transactions;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.DAL.DMSBaseException;
using log4net;
using System.Collections;
using Newtonsoft.Json;
using Martex.DMS.BLL.DataValidators;


namespace Martex.DMS.BLL.Facade
{
    public class MemberAPIFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(MemberAPIFacade));
        #endregion


        /// <summary>
        /// Searches the member for API.
        /// </summary>
        /// <param name="customerID">The customer identifier.</param>
        /// <param name="customerGroupID">The customer group identifier.</param>
        /// <param name="internalMemberID">The internal member identifier.</param>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public List<APISearchMembershipModel> SearchMemberAPI(string customerID, string customerGroupID, int? internalMemberID, string lastName, string firstName, string VIN, string userName)
        {
            logger.InfoFormat("MemberAPIFacade - SearchMemberAPI(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                customerID = customerID,
                customerGroupID = customerGroupID,
                internalMemberID = internalMemberID,
                userName = userName
            }));
            MemberRepository memberRepository = new MemberRepository();
            List<SearchMembersForAPI_Result> membershipResult = memberRepository.SearchMemberForAPI(customerID, customerGroupID, internalMemberID, lastName, firstName, VIN, userName);
            List<APISearchMembershipModel> result = new List<APISearchMembershipModel>();

            if (membershipResult != null && membershipResult.Count > 0)
            {
                //Get Distinct Memberships
                var distinctMemberships = membershipResult.GroupBy(a => a.MembershipID).Select(a => a.First()).ToList();
                foreach (var membership in distinctMemberships)
                {
                    #region Membership
                    //Add new Membership
                    var newMembership = new APISearchMembershipModel();
                    newMembership.CustomerGroupID = membership.MembershipNumber;
                    newMembership.InternalCustomerGroupID = membership.MembershipID;

                    //Get Members For Membership
                    List<SearchMembersForAPI_Result> membersForMembership = membershipResult.Where(a => a.MembershipID == membership.MembershipID).ToList();
                    var membershipMembers = new List<APISearchMembershipMemberModel>();
                    var membershipVehicles = new List<APISearchMembershipVehicleModel>();
                    //Get Distinct Members for this Membership
                    var distinctMembersForMembership = membersForMembership.GroupBy(a => a.InternalMemberID).Select(a => a.First()).ToList();
                    foreach (var member in distinctMembersForMembership)
                    {
                        #region Member
                        //Add new Member
                        var newMember = new APISearchMembershipMemberModel()
                        {
                            InternalCustomerID = member.InternalMemberID,
                            FirstName = member.FirstName,
                            MiddleName = member.MiddleName,
                            LastName = member.LastName,
                            Suffix = member.Suffix,
                            Prefix = member.Prefix,
                            EffectiveDate = member.EffectiveDate,
                            ExpirationDate = member.ExpirationDate,
                            Program = member.Program,
                            CustomerID = member.MemberNumber
                        };
                        #region Member Vehicles
                        var memberVehicles = new List<APISearchMembershipVehicleModel>();
                        //Get Vehicles Associated for this Member
                        var memberDetails = membershipResult.Where(a => a.InternalMemberID == member.InternalMemberID && a.VehicleMemberID != null).GroupBy(a => a.VehicleMemberID).Select(a => a.First()).ToList();
                        foreach (var memberVehcile in memberDetails)
                        {
                            var newMemberVehcile = new APISearchMembershipVehicleModel()
                            {
                                VIN = memberVehcile.VIN,
                                Year = memberVehcile.Year,
                                Make = memberVehcile.Make,
                                Model = memberVehcile.Model,
                                MakeOther = memberVehcile.MakeOther,
                                ModelOther = memberVehcile.ModelOther,
                                LicenseState = memberVehcile.LicenseState,
                                LicenseNumber = memberVehcile.LicenseNumber,
                                Color = memberVehcile.Color,
                                Length = memberVehcile.Length,
                                Height = memberVehcile.Height,
                                Description = memberVehcile.Description,
                                Chassis = memberVehcile.Chassis,
                                Engine = memberVehcile.Engine,
                                StartMileage = memberVehcile.StartMileage,
                                EndMileage = memberVehcile.EndMileage,
                                WarrantyStartDate = memberVehcile.WarrantyStartDate,
                                WarrantyEndDate = memberVehcile.WarrantyEndDate,
                                WarrantyMileage = memberVehcile.WarrantyMileage,
                                WarrantyPeriod = memberVehcile.WarrantyPeriod,
                                WarrantyPeriodUOM = memberVehcile.WarrantyPeriodUOM,
                                PurchaseDate = memberVehcile.PurchaseDate
                            };

                            memberVehicles.Add(newMemberVehcile);
                        }
                        newMember.MemberVehicles = memberVehicles;
                        membershipMembers.Add(newMember);
                        #endregion
                        #endregion
                    }
                    newMembership.Members = membershipMembers;
                    #region Membership Vehciles
                    //Get Vehicles Associated for this Membership
                    //var vehiclesForMembership = membershipResult.Where(a => a.MembershipID == membership.MembershipID).ToList();
                    //foreach (var membershipVehcile in vehiclesForMembership)
                    //{
                    //    var newMembeshipVehcile = new APISearchMembershipVehicleModel()
                    //    {
                    //        VIN = membershipVehcile.VIN,
                    //        Year = membershipVehcile.Year,
                    //        Make = membershipVehcile.Make,
                    //        Model = membershipVehcile.Model,
                    //        MakeOther = membershipVehcile.MakeOther,
                    //        ModelOther = membershipVehcile.ModelOther,
                    //        LicenseState = membershipVehcile.LicenseState,
                    //        LicenseNumber = membershipVehcile.LicenseNumber,
                    //        Color = membershipVehcile.Color,
                    //        Length = membershipVehcile.Length,
                    //        Height = membershipVehcile.Height,
                    //        Description = membershipVehcile.Description,
                    //        Chassis = membershipVehcile.Chassis,
                    //        Engine = membershipVehcile.Engine,
                    //        StartMileage = membershipVehcile.StartMileage,
                    //        EndMileage = membershipVehcile.EndMileage,
                    //        WarrantyStartDate = membershipVehcile.WarrantyStartDate,
                    //        WarrantyEndDate = membershipVehcile.WarrantyEndDate,
                    //        WarrantyMileage = membershipVehcile.WarrantyMileage,
                    //        WarrantyPeriod = membershipVehcile.WarrantyPeriod,
                    //        WarrantyPeriodUOM = membershipVehcile.WarrantyPeriodUOM,
                    //        PurchaseDate = membershipVehcile.PurchaseDate
                    //    };

                    //    membershipVehicles.Add(newMembeshipVehcile);
                    //}
                    //newMembership.MembershipVehicles = membershipVehicles;
                    #endregion

                    #region Membership Addresses
                    var membershipAddressList = new List<APISearchMembershipAddressModel>();
                    var distinctMembershipAddress = membersForMembership.Where(a => a.AddressID != null).GroupBy(a => a.AddressID).Select(a => a.First()).ToList();
                    foreach (var memberAddress in distinctMembershipAddress)
                    {
                        var newMemberAddress = new APISearchMembershipAddressModel()
                        {
                            ID = memberAddress.AddressID.GetValueOrDefault(),
                            AddressTypeID = memberAddress.AddressTypeID,
                            AddressType = memberAddress.AddressType,
                            EntityID = memberAddress.AddressEntityID,
                            Entity = memberAddress.AddressEntity,
                            Line1 = memberAddress.Line1,
                            Line2 = memberAddress.Line2,
                            Line3 = memberAddress.Line3,
                            CountryID = memberAddress.CountryID,
                            CountryCode = memberAddress.CountryCode,
                            PostalCode = memberAddress.PostalCode,
                            StateProvince = memberAddress.StateProvince,
                            StateProvinceID = memberAddress.StateProvinceID
                        };
                        membershipAddressList.Add(newMemberAddress);
                    }
                    //var addressRepository = new AddressRepository();
                    //var addressList = addressRepository.GetAddresses(membership.MembershipID, EntityNames.MEMBERSHIP);
                    //var membershipAddressList = new List<APISearchMembershipAddressModel>();
                    //foreach (var address in addressList)
                    //{
                    //    membershipAddressList.Add(GetAddressModel(address));
                    //}

                    newMembership.Addresses = membershipAddressList;
                    #endregion

                    #region Membership Phones
                    var membershipPhonesList = new List<APISearchMembershipPhoneModel>();
                    var distinctMembershipPhones = membersForMembership.Where(a => a.PhoneID != null).GroupBy(a => a.PhoneID).Select(a => a.First()).ToList();
                    foreach (var memberPhone in distinctMembershipPhones)
                    {
                        var newMemberPhone = new APISearchMembershipPhoneModel()
                        {
                            ID = memberPhone.PhoneID.GetValueOrDefault(),
                            PhoneTypeID = memberPhone.PhoneTypeID,
                            PhoneType = memberPhone.PhoneType,
                            Entity = memberPhone.PhoneEntity,
                            EntityID = memberPhone.PhoneEntityID.GetValueOrDefault(),
                            IndexPhoneNumber = memberPhone.IndexPhoneNumber,
                            PhoneNumber = memberPhone.PhoneNumber,
                            Sequence = memberPhone.Sequence
                        };
                        membershipPhonesList.Add(newMemberPhone);
                    }
                    //var phoneRepository = new PhoneRepository();
                    //var phonesList = phoneRepository.Get(membership.MembershipID, EntityNames.MEMBERSHIP);                   
                    //foreach (var phone in phonesList)
                    //{
                    //    membershipPhonesList.Add(GetPhoneModel(phone));
                    //}
                    newMembership.Phones = membershipPhonesList;
                    #endregion
                    result.Add(newMembership);
                    #endregion
                }
            }
            logger.InfoFormat("MemberAPIFacade - SearchMemberAPI(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                result = result
            }));
            //throw new Exception("Test Exception");
            return result;
        }

        public APISearchMembershipPhoneModel GetPhoneModel(PhoneEntity phone)
        {
            var phoneDetail = new APISearchMembershipPhoneModel()
            {
                ID = phone.ID,
                EntityID = phone.EntityID,
                PhoneTypeID = phone.PhoneTypeID,
                PhoneNumber = phone.PhoneNumber,
                IndexPhoneNumber = phone.IndexPhoneNumber,
                Sequence = phone.Sequence
            };
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(a => a.ID == phone.EntityID).FirstOrDefault();
                phoneDetail.Entity = entity != null ? entity.Name : string.Empty;
                var phoneType = dbContext.PhoneTypes.Where(a => a.ID == phone.PhoneTypeID).FirstOrDefault();
                phoneDetail.PhoneType = phoneType != null ? phoneType.Name : string.Empty;
            }

            return phoneDetail;
        }

        public APISearchMembershipAddressModel GetAddressModel(AddressEntity address)
        {
            var addressDetail = new APISearchMembershipAddressModel()
            {
                ID = address.ID,
                EntityID = address.EntityID,
                AddressTypeID = address.AddressTypeID,
                Line1 = address.Line1,
                Line2 = address.Line2,
                Line3 = address.Line3,
                City = address.City,
                StateProvince = address.StateProvince,
                PostalCode = address.PostalCode,
                StateProvinceID = address.StateProvinceID,
                CountryID = address.CountryID,
                CountryCode = address.CountryCode

            };
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(a => a.ID == address.EntityID).FirstOrDefault();
                addressDetail.Entity = entity != null ? entity.Name : string.Empty;
                var addressType = dbContext.AddressTypes.Where(a => a.ID == address.AddressTypeID).FirstOrDefault();
                addressDetail.AddressType = addressType != null ? addressType.Name : string.Empty;
            }
            return addressDetail;
        }


        public string ValidateVehicleFields(string VIN, string make, string model, int? year, bool isVehicleRequired, bool isVINRequired)
        {
            var vehicleErrors = string.Empty;
            var sb = new StringBuilder();
            bool isVehicleInfoValid = true;

            if (isVINRequired)
            {
                if (string.IsNullOrEmpty(VIN))
                {
                    isVehicleInfoValid = false;
                    sb.AppendLine("Vehicle VIN is required");
                }
                else
                {
                    if (!ReferenceDataRepository.CheckIsVINValid(VIN))
                    {
                        isVehicleInfoValid = false;
                        sb.AppendLine("Invalid VIN");
                    }
                }
            }
            if (isVehicleRequired)
            {
                if (string.IsNullOrEmpty(VIN) && !(year == null && string.IsNullOrEmpty(make) && string.IsNullOrEmpty(model)))
                {
                    isVehicleInfoValid = false;
                    sb.AppendLine("The Vehicle VIN or Vehicle Year,Vehicle Make,Vehicle Model are required");
                }
            }
            
            // TFS 1412
            /*else
            {
                if (!(string.IsNullOrEmpty(VIN) && year == null && string.IsNullOrEmpty(make) && string.IsNullOrEmpty(model)))
                {
                    if (!string.IsNullOrEmpty(VIN))
                    {
                        if (isVINRequired && !ReferenceDataRepository.CheckIsVINValid(VIN))
                        {
                            isVehicleInfoValid = false;
                            sb.AppendLine("Invalid VIN");
                        }
                    }
                    else
                    {
                        if ((year == null || string.IsNullOrEmpty(make) || string.IsNullOrEmpty(model)))
                        {
                            isVehicleInfoValid = false;
                            sb.AppendLine("Vehicle Year, Make and Model are required");
                        }
                    }
                }
            }*/
            if (!isVehicleInfoValid)
            {
                vehicleErrors = sb.ToString();
            }
            return vehicleErrors;
        }
    }
}
