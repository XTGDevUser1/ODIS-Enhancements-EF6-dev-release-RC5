using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;

namespace Martex.DMS.DAL.DAO
{
    public partial class MemberManagementRepository
    {

        /// <summary>
        /// Gets the member info details.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public MemberInfoDetails GetMemberInfoDetails(int memberID)
        {
            MemberInfoDetails model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = (from member in dbContext.Members
                         join membership in dbContext.Memberships on member.MembershipID equals membership.ID
                         join program in dbContext.Programs on member.ProgramID equals program.ID
                         join client in dbContext.Clients on program.ClientID equals client.ID
                         where member.ID == memberID
                         select new MemberInfoDetails()
                         {
                             MembershipID = member.MembershipID,
                             MemberID = memberID,
                             ClientID = client.ID,
                             ProgramID = member.ProgramID,
                             MembershipNumber = membership.MembershipNumber,
                             ExpirationDate = member.ExpirationDate,
                             PrefixName = member.Prefix,
                             SuffixName = member.Suffix,
                             FirstName = member.FirstName,
                             MiddleName = member.MiddleName,
                             LastName = member.LastName,
                             Email = member.Email,
                             ClientReference = membership.ClientReferenceNumber,
                             ProgramReference = member.ReferenceProgram,
                             MemberSince = member.MemberSinceDate,
                             EffectiveDate = member.EffectiveDate,
                             CreatedBy = member.CreateBy,
                             ModifiedBy = member.ModifyBy,
                             ModifiedOn = member.ModifyDate,
                             CreatedOn = member.CreateDate,
                             SourceID = member.SourceSystemID
                         }).FirstOrDefault();

                // For Source System
                if (model.SourceID.HasValue)
                {
                    SourceSystem sourceSystem = dbContext.SourceSystems.Where(u => u.ID == model.SourceID.Value).FirstOrDefault();
                    if (sourceSystem != null)
                    {
                        model.SourceSystemName = sourceSystem.Name;
                    }
                }

                // For Suffix and Prefix LookUp
                if (!string.IsNullOrEmpty(model.SuffixName))
                {
                    Suffix suffix = dbContext.Suffixes.Where(u => u.Name.Equals(model.SuffixName)).FirstOrDefault();
                    if (suffix != null)
                    {
                        model.SuffixID = suffix.ID;
                    }
                }
                if (!string.IsNullOrEmpty(model.PrefixName))
                {
                    Prefix prefix = dbContext.Prefixes.Where(u => u.Name.Equals(model.PrefixName)).FirstOrDefault();
                    if (prefix != null)
                    {
                        model.PrefixID = prefix.ID;
                    }

                }
            }

            return model;
        }


        /// <summary>
        /// Saves the member info details.
        /// </summary>
        /// <param name="model">The model.</param>
        public void SaveMemberInfoDetails(MemberInfoDetails model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                var existingMemberRecord = dbContext.Members.Where(u => u.ID == model.MemberID).FirstOrDefault();
                if (existingMemberRecord == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Member Details for the given ID {0}", model.MemberID));
                }
                existingMemberRecord.ProgramID = model.ProgramID;
                existingMemberRecord.Suffix = model.SuffixName;
                existingMemberRecord.Prefix = model.PrefixName;
                existingMemberRecord.FirstName = model.FirstName;
                existingMemberRecord.MiddleName = model.MiddleName;
                existingMemberRecord.LastName = model.LastName;
                existingMemberRecord.Email = model.Email;
                existingMemberRecord.EffectiveDate = model.EffectiveDate;
                existingMemberRecord.ExpirationDate = model.ExpirationDate;
                existingMemberRecord.MemberSinceDate = model.MemberSince;
                existingMemberRecord.ReferenceProgram = model.ProgramReference;
                //Sanghi : CR 252 DO NOT UPDATE Is Active Field as this field is treated as Deleted Flag for Member
                //existingMemberRecord.IsActive = model.IsMemberExpired;
                existingMemberRecord.ModifyBy = userName;
                existingMemberRecord.ModifyDate = DateTime.Now;

                dbContext.SaveChanges();
            }
        }


        public MemberApiModel GetMemberDetailsById(int memberID)
        {

            MemberApiModel model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                Member existingMember = dbContext.Members.Where(a => a.ID == memberID).FirstOrDefault();
                if (existingMember != null)
                {
                    model = (from member in dbContext.Members
                             join membership in dbContext.Memberships on member.MembershipID equals membership.ID
                             join program in dbContext.Programs on member.ProgramID equals program.ID
                             //join client in dbContext.Clients on program.ClientID equals client.ID
                             where member.ID == memberID

                             select new MemberApiModel()
                             {
                                 CustomerGroupID = member.MembershipID.ToString(),
                                 CustomerID = memberID.ToString(),
                                 IsPrimary = memberID == member.MembershipID ? true : false,
                                 ProgramID = program.ID,
                                 FirstName = member.FirstName,
                                 MiddleName = member.MiddleName,
                                 LastName = member.LastName,
                                 Email = member.Email,
                                 ExpirationDate = member.ExpirationDate,
                                 EffectiveDate = member.EffectiveDate,
                                 InternalCustomerGroupID = member.MembershipID,
                                 InternalCustomerID = member.ID
                             }).FirstOrDefault();

                    AddressEntity memberAddress = dbContext.AddressEntities.Where(a => a.AddressType.Name.Equals("Home") && a.Entity.Name.Equals("Member") && a.RecordID == memberID).FirstOrDefault();
                    if (memberAddress != null)
                    {
                        model.Address1 = memberAddress.Line1;
                        model.Address2 = memberAddress.Line2;
                        model.City = memberAddress.City;
                        model.StateProvince = memberAddress.StateProvince != null ? memberAddress.StateProvince.Trim() : null;
                        model.CountryCode = memberAddress.CountryCode;
                    }
                    //TODO: Requires Review
                    /*Vehicle memberVehicle = dbContext.Vehicles.Where(v => v.MemberID == memberID ||
                                                (v.MembershipID == membershipID && v.MemberID == null)
                                               )
                                               &&
                                               v.IsActive == true).FirstOrDefault();
                    if (memberVehicle != null)
                    {
                        model.VehicleVIN = memberVehicle.VIN;
                        model.VehicleType = memberVehicle.VehicleType != null ? memberVehicle.VehicleType.Name : string.Empty;
                        model.VehicleYear = memberVehicle.Year == null ? 0 : int.Parse(memberVehicle.Year);
                        model.VehicleMake = memberVehicle.Make != null ? memberVehicle.Make : memberVehicle.MakeOther;
                        model.VehicleModel = memberVehicle.Model != null ? memberVehicle.Model : memberVehicle.ModelOther;
                    }*/
                }
            }

            return model;
        }
        public Member GetMemberDetailsByMemberID(int memberID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Members.Where(a => a.ID == memberID).FirstOrDefault();
            }
        }


        /// <summary>
        /// Saves the membership details from web request.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public MemberApiModel SaveMembershipDetailsFromWebRequest(MemberApiModel model)
        {
            var membershipExists = false;
            CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
            SourceSystem webServiceSourceSystem = lookUpRepo.GetSourceSystem(SourceSystemName.WEB_SERVICE);
            MembershipRepository membershipRepository = new MembershipRepository();
            Membership membership = null;
            MemberRepository memberRepository = new MemberRepository();
            if (model.InternalCustomerID != null)
            {
                Member member = memberRepository.GetMemberByClientMemberKey(model.CustomerID, model.ClientID.GetValueOrDefault());
                if (member != null)
                {
                    membershipExists = true;
                    membership = member.Membership;
                    model.InternalCustomerGroupID = membership.ID;
                }
            }
            else if (model.InternalCustomerGroupID != null)
            {
                membership = membershipRepository.Get(model.InternalCustomerGroupID.GetValueOrDefault());
                if (membership != null)
                {
                    membershipExists = true;
                    model.InternalCustomerGroupID = membership.ID;
                }
            }
            else if (!string.IsNullOrEmpty(model.CustomerGroupID))
            {
                membership = membershipRepository.GetByMembershipNumberAndProgramID(model.CustomerGroupID, model.ProgramID);
                if (membership != null)
                {
                    membershipExists = true;
                    model.InternalCustomerGroupID = membership.ID;
                }
            }
            if (membershipExists)
            {
                if (!string.IsNullOrEmpty(model.CustomerGroupID))
                {
                    membership.MembershipNumber = !(string.IsNullOrEmpty(model.CustomerGroupID)) ? model.CustomerGroupID : model.CustomerID;
                    membership.ClientMembershipKey = !(string.IsNullOrEmpty(model.CustomerGroupID)) ? model.CustomerGroupID : model.CustomerID;
                }
                if (!string.IsNullOrEmpty(model.Email))
                {
                    membership.Email = model.Email;
                }

                membership.IsActive = true;
                membership.ModifyBy = model.CurrentUser;
                membership.ModifyDate = DateTime.Now;
                membership.SourceSystemID = webServiceSourceSystem.ID;
                membershipRepository.UpdateMembership(membership);
            }
            else
            {
                membership = new Membership();
                membership.MembershipNumber = !(string.IsNullOrEmpty(model.CustomerGroupID)) ? model.CustomerGroupID : model.CustomerID;
                membership.Email = model.Email;
                membership.ClientMembershipKey = !(string.IsNullOrEmpty(model.CustomerGroupID)) ? model.CustomerGroupID : model.CustomerID;
                membership.IsActive = true;
                membership.CreateBy = model.CurrentUser;
                membership.CreateDate = DateTime.Now;
                membership.SourceSystemID = webServiceSourceSystem.ID;

                model.InternalCustomerGroupID = membershipRepository.Save(membership);
            }


            return model;
        }

        /// <summary>
        /// Saves the member details from web request.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public MemberApiModel SaveMemberDetailsFromWebRequest(MemberApiModel model)
        {
            MembershipRepository membershipRepository = new MembershipRepository();
            MemberRepository memberRepo = new MemberRepository();

            var memberExists = false;
            Member member = null;            
            if (model.InternalCustomerID != null)
            {
                member = memberRepo.Get(model.InternalCustomerID.GetValueOrDefault());
                if (member != null)
                {
                    memberExists = true;
                }
            }
            //else 
            //{
            //    member = memberRepo.GetMemberByClientMemberKey(model.CustomerID, model.ClientID.GetValueOrDefault());
            //    if (member != null)
            //    {
            //        memberExists = true;
            //    }
            //}
                        
            var membersForMembership = GetMembersByMembershipID(model.InternalCustomerGroupID.GetValueOrDefault());
            // While adding a member, if there already exists a primary member, set the current member as non-primary.
            // While updating, we can set the current member to be primary / not based on the request.
            var hasPrimaryMember = false;
            foreach (var m in membersForMembership)
            {
                var existingMember = GetMemberDetailsById(m.ID);
                if (existingMember != null && existingMember.IsPrimary == true)
                {
                    hasPrimaryMember = true;
                    break;
                }
            }

            if (hasPrimaryMember && !memberExists)
            {
                model.IsPrimary = false;
            }

            CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
            SourceSystem webServiceSourceSystem = lookUpRepo.GetSourceSystem(SourceSystemName.WEB_SERVICE);
            
            if (memberExists)
            {
                if (model.ProgramID != null)
                {
                    member.ProgramID = model.ProgramID;
                }
                if (!string.IsNullOrEmpty(model.FirstName))
                {
                    member.FirstName = model.FirstName;
                }
                if (!string.IsNullOrEmpty(model.MiddleName))
                {
                    member.MiddleName = model.MiddleName;
                }
                if (!string.IsNullOrEmpty(model.LastName))
                {
                    member.LastName = model.LastName;
                }
                if (!string.IsNullOrEmpty(model.Email))
                {
                    member.Email = model.Email;
                }
                //TFS: 1587
                if (model.EffectiveDate != null)
                {
                    member.EffectiveDate = model.EffectiveDate;
                    //member.MemberSinceDate = model.EffectiveDate;
                }
                if (model.ExpirationDate != null)
                {
                    member.ExpirationDate = model.ExpirationDate;
                }
                
                if (member.EffectiveDate >= member.ExpirationDate)
                {
                    throw new DMSException("EffectiveDate value exceeds ExpirationDate value");
                }
                
                member.IsPrimary = model.IsPrimary ?? false;
                member.IsActive = true;
                member.ModifyDate = DateTime.Now;
                member.ModifyBy = model.CurrentUser;
                memberRepo.Save(member, EntityNames.MEMBER, model.CurrentUser);
            }
            else
            {
                member = new Member()
                {
                    MembershipID = model.InternalCustomerGroupID.GetValueOrDefault(),
                    ProgramID = model.ProgramID,
                    FirstName = model.FirstName,
                    MiddleName = model.MiddleName,
                    LastName = model.LastName,
                    Email = model.Email,
                    EffectiveDate = model.EffectiveDate,
                    ExpirationDate = model.ExpirationDate,
                    MemberSinceDate = model.EffectiveDate,
                    ClientMemberKey = model.CustomerID,
                    IsPrimary = model.IsPrimary,
                    IsActive = true,
                    CreateDate = DateTime.Now,
                    CreateBy = model.CurrentUser,
                    SourceSystemID = webServiceSourceSystem.ID,
                    MemberNumber = model.CustomerID
                };

                model.InternalCustomerID = memberRepo.Save(member);
            }
            return model;
        }

        /// <summary>
        /// Saves the vehicle details from web request.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public MemberApiModel SaveVehicleDetailsFromWebRequest(MemberApiModel model)
        {
            CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
            int? vehicleCategoryID = null,
                   rvTypeID = null,
                   vehicleTypeID = null;
            string vehicleMake = null,
                vehicleMakeOther = null,
                vehicleModel = null,
                vehicleModelOther = null;

            VehicleType vehicleType = lookUpRepo.GetVehicleTypeByName(model.VehicleType);
            if (vehicleType == null)
            {
                vehicleType = lookUpRepo.GetVehicleTypeByName(VehicleTypeNames.AUTO);
            }
            vehicleTypeID = vehicleType != null ? vehicleType.ID : 1;
            var makeModel = ReferenceDataRepository.GetMakeModel(vehicleTypeID.Value, model.VehicleMake, model.VehicleModel).FirstOrDefault();
            if (vehicleType.Name == VehicleTypeNames.RV)
            {                
                if (makeModel != null)
                {
                    vehicleMake = model.VehicleMake;
                    vehicleModel = model.VehicleModel;
                    vehicleCategoryID = makeModel.VehicleCategoryID;
                    rvTypeID = makeModel.RVTypeID;
                }
                else
                {
                    vehicleMake = "Other";
                    vehicleMakeOther = model.VehicleMake;
                    vehicleModel = "Other";
                    vehicleModelOther = model.VehicleModel;
                }
            }
            else
            {   
                var lightDutyVehicleCategory = lookUpRepo.GetVehicleCategoryByName(VehicleCategoryNames.LIGHT_DUTY);
                if (vehicleType.Name == VehicleTypeNames.AUTO)
                {
                    vehicleCategoryID = lightDutyVehicleCategory != null ? lightDutyVehicleCategory.ID : 1;
                }

                if (makeModel != null)
                {
                    vehicleMake = model.VehicleMake;
                    vehicleModel = model.VehicleModel;
                }
                else
                {
                    vehicleMake = "Other";
                    vehicleMakeOther = model.VehicleMake;
                    vehicleModel = "Other";
                    vehicleModelOther = model.VehicleModel;
                }
            }
            Vehicle vehicle = new Vehicle()
            {
                VehicleCategoryID = vehicleCategoryID,
                RVTypeID = rvTypeID,
                VehicleTypeID = vehicleTypeID,
                Make = vehicleMake,
                MakeOther = vehicleMakeOther,
                Model = vehicleModel,
                ModelOther = vehicleModelOther,
                MembershipID = model.InternalCustomerGroupID,
                MemberID = model.InternalCustomerID,
                VIN = model.VehicleVIN,
                Year = model.VehicleYear.GetValueOrDefault().ToString(),
                Color = model.VehicleColor,
                CreateDate = DateTime.Now,
                CreateBy = model.CurrentUser,
                Source = SourceSystemName.WEB_SERVICE,
                IsActive = true
            };

            VehicleRepository vehicleRepository = new VehicleRepository();
            vehicle = vehicleRepository.SaveVehicleDetails(vehicle, model.CurrentUser);
            model.VehicleID = vehicle.ID;
            return model;
        }

    }
}
