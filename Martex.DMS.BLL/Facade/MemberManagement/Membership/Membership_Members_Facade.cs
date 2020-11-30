using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.BLL.Facade
{
    public partial class MemberManagementFacade
    {
        /// <summary>
        /// Gets the membership members list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="memberShipID">The member ship ID.</param>
        /// <returns></returns>
        public List<MembershipMembersList_Result> GetMembershipMembersList(PageCriteria pc, int memberShipID)
        {
            return repository.GetMembershipMembersList(pc, memberShipID);
        }

        /// <summary>
        /// Saves the membership member.
        /// </summary>
        /// <param name="Member">The member.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="DMSException">Error while creating Member record !</exception>
        public int SaveMembershipMember(MemberModel Member, string userName, string Source)
        {
            CommonLookUpRepository commonLookupRepo = new CommonLookUpRepository();
            MemberRepository memberRepository = new MemberRepository();
            int memberID = repository.SaveMembershipMember(Member, userName);
            if (memberID <= 0)
            {
                throw new DMSException("Error while creating Member record !");
            }
            logger.InfoFormat("Added Member record @ ID : {0}", memberID);
            Member.MemberID = memberID;


            logger.Info("Attempting to save addresses against member");
            var addressFacade = new AddressFacade();
            List<AddressEntity> addressList = GetAddressEntities(Member, userName, commonLookupRepo);
            addressFacade.SaveAddresses(memberID, EntityNames.MEMBER, userName, addressList, AddressFacade.ADD);

            // For Phone Number
            logger.Info("Attempting to save phone details against member");
            PhoneFacade phoneFacade = new PhoneFacade();
            List<PhoneEntity> phoneList = GetPhoneEntities(Member);
            phoneFacade.SavePhoneDetails(memberID, EntityNames.MEMBER, userName, phoneList, PhoneFacade.ADD);

            EventLoggerFacade eventLogFacde = new EventLoggerFacade();
            long EventLogID = eventLogFacde.LogEvent(Source, EventNames.ADD_MEMBER, "Add Member", userName, null);
            eventLogFacde.CreateRelatedLogLinkRecord(EventLogID, memberID, EntityNames.MEMBER);
            eventLogFacde.CreateRelatedLogLinkRecord(EventLogID, Member.MembershipID, EntityNames.MEMBERSHIP);

            logger.Info("Saved Successfully");

            return memberID;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="memberID"></param>
        public void DeleteMembershipMember(int memberID)
        {
            repository.DeleteMembershipMember(memberID);
        }
        /// <summary>
        /// Delete Member and Membership
        /// </summary>
        /// <param name="memberID"></param>
        /// <param name="membershipID"></param>
        public void DeleteMemberAndMemberShip(int memberID, int membershipID)
        {
            repository.DeleteMemberAndMemberShip(memberID, membershipID);
        }



        /// <summary>
        /// For Last Member
        /// </summary>
        /// <param name="membershipID"></param>
        /// <returns></returns>
        public bool IsLastMember(int membershipID)
        {
            int membersCount = repository.MemberCount(membershipID);
            return membersCount == 1 ? true : false;
        }
        /// <summary>
        /// Gets the address entities.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="repository">The repository.</param>
        /// <returns></returns>
        private static List<AddressEntity> GetAddressEntities(MemberModel model, string userName, CommonLookUpRepository repository)
        {
            List<AddressEntity> addressList = new List<AddressEntity>();
            AddressEntity addressEntity = new AddressEntity();
            addressEntity.AddressTypeID = 1; // Default to Home
            addressEntity.Line1 = model.AddressLine1;
            addressEntity.Line2 = model.AddressLine2;
            addressEntity.Line3 = model.AddressLine3;
            addressEntity.City = model.City;
            addressEntity.StateProvinceID = model.State;
            addressEntity.PostalCode = model.PostalCode;
            addressEntity.CountryID = model.Country;
            addressEntity.CreateDate = addressEntity.ModifyDate = DateTime.Now;
            addressEntity.CreateBy = addressEntity.ModifyBy = userName;
            if (model.State.HasValue)
            {
                addressEntity.StateProvince = repository.GetStateProvince(model.State.Value).Abbreviation;
            }

            if (model.Country.HasValue)
            {
                addressEntity.CountryCode = repository.GetCountry(model.Country.Value).ISOCode;
            }
            addressList.Add(addressEntity);
            return addressList;
        }

        /// <summary>
        /// Gets the phone entities.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        private static List<PhoneEntity> GetPhoneEntities(MemberModel model)
        {
            PhoneEntity phoneEntity = new PhoneEntity();
            phoneEntity.PhoneNumber = model.PhoneNumber;
            phoneEntity.PhoneTypeID = model.PhoneType;
            List<PhoneEntity> phoneList = new List<PhoneEntity>();
            phoneList.Add(phoneEntity);
            return phoneList;
        }
    }
}
