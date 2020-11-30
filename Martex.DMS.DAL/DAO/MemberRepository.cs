using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;
using log4net;
using Newtonsoft.Json;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    ///
    /// </summary>
    public class MemberRepository
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(MemberRepository));

        #endregion

        /// <summary>
        /// Insert a new Record in Member Table.
        /// </summary>
        /// <param name="member"></param>
        /// <returns></returns>
        public int Save(Member member)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Members.Add(member);
                dbContext.SaveChanges();
            }
            return member.ID;
        }
        /// <summary>
        /// Gets the client reference control data.
        /// </summary>
        /// <param name="programID">The program ID.</param>
        /// <param name="screenName">Name of the screen.</param>
        /// <returns></returns>
        public static ProgramDataItemForClientReference_Result GetClientReferenceControlData(int? programID, string screenName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetProgramDataItemForClientReference(programID, screenName);
                return result.FirstOrDefault();
            }
        }
        /// <summary>
        /// Searches the member.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        public List<SearchMember_Result> SearchMember(Common.PageCriteria pageCriteria, int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 180;
                var list = dbContext.SearchMember(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, programID).ToList<SearchMember_Result>();
                return list;
            }
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="programID"></param>
        /// <returns></returns>
        public List<ProgramServiceEventLimit> GetProgramServiceEventLimit(int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ProgramServiceEventLimits.Where(u => u.ProgramID == programID && u.IsActive == true).OrderBy(u => u.Description).ToList();
            }
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="pageCriteria"></param>
        /// <param name="memberIDList"></param>
        /// <param name="membershipIDList"></param>
        /// <returns></returns>
        public List<StartCallMemberSelections_Result> SearchMember(PageCriteria criteria, string memberIDList)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 180;
                var list = dbContext.GetStartCallMemberSelections(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection, memberIDList).ToList<StartCallMemberSelections_Result>();
                return list;
            }
        }


        /// <summary>
        /// Searches the member.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        public List<SearchMember_Result> SearchMemberMerge(Common.PageCriteria pageCriteria, int? programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 180;
                var list = dbContext.SearchMember_Merge(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, programID).ToList<SearchMember_Result>();
                return list;
            }
        }

        public List<SearchMembersByVINOrMS_Result> SearchMemberByVINOrMS(Common.PageCriteria pageCriteria, int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 180;
                var list = dbContext.SearchMembersByVINOrMS(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, programID).ToList<SearchMembersByVINOrMS_Result>();
                return list;
            }
        }
        /// <summary>
        /// Gets the vehicle information.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public List<Vehicle> GetVehicleInformation(int memberID, int membershipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<Vehicle> result = (from v in dbContext.Vehicles
                                        where (v.MemberID == memberID ||
                                                (v.MembershipID == membershipID && v.MemberID == null)
                                               )
                                               &&
                                               v.IsActive == true
                                        select v).ToList<Vehicle>();
                return result;
            }
        }
        /// <summary>
        /// Gets the member information.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public List<Member_Information_Result> GetMemberInformation(int memberID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberInformation(memberID).ToList();
            }
        }
        /// <summary>
        /// Gets the service request history.
        /// </summary>
        /// <param name="memberShipID">The member ship ID.</param>
        /// <returns></returns>
        public List<RecentServiceRequest> GetServiceRequestHistory(int memberShipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                List<RecentServiceRequest> result = (from sr in dbContext.ServiceRequests
                                                     join c in dbContext.Cases on sr.CaseID equals c.ID
                                                     join m in dbContext.Members on c.MemberID equals m.ID
                                                     join ms in dbContext.Memberships on m.MembershipID equals ms.ID
                                                     join srs in dbContext.ServiceRequestStatus on sr.ServiceRequestStatusID equals srs.ID
                                                     join pc in dbContext.ProductCategories on sr.ProductCategoryID equals pc.ID into ProductCategoryDetails
                                                     from pcd in ProductCategoryDetails.DefaultIfEmpty()
                                                     join ss in dbContext.SourceSystems on c.SourceSystemID equals ss.ID into SourceSystems
                                                     from cs in SourceSystems.DefaultIfEmpty()
                                                     where ms.ID == memberShipID
                                                     select new RecentServiceRequest()
                                                     {
                                                         ServiceRequestID = sr.ID,
                                                         Status = srs.Name,
                                                         Date = sr.CreateDate,
                                                         Service = pcd.Name,
                                                         Year = c.VehicleYear,
                                                         Make = c.VehicleMake == "Other" ? c.VehicleMakeOther : c.VehicleMake,
                                                         Model = c.VehicleModel == "Other" ? c.VehicleModelOther : c.VehicleModel,
                                                         MemberName = (m.FirstName ?? string.Empty) + " " +
                                                                        ((m.MiddleName != null && m.MiddleName.Length > 0) ? m.MiddleName.Substring(0, 1) : string.Empty) + " " +
                                                                        (m.LastName ?? string.Empty) + " " +
                                                                        (m.Suffix ?? string.Empty),
                                                         MemberID = c.MemberID,
                                                         SourceSystemName = cs.Name,
                                                         ContactPhoneNumber = c.ContactPhoneNumber,
                                                         ContactFirstName = c.ContactFirstName,
                                                         ContactLastName = c.ContactLastName,
                                                         CreateDate = sr.CreateDate,
                                                         MembershipNumber = ms.MembershipNumber
                                                     }
                                               ).OrderByDescending(u => u.Date).ToList<RecentServiceRequest>();
                return result;
            }
        }
        /// <summary>
        /// Gets the member from case.
        /// </summary>
        /// <param name="callbackNumber">The callback number.</param>
        /// <param name="phoneTypeId">The phone type id.</param>
        /// <returns></returns>
        public Member GetMemberFromCase(string callbackNumber, int phoneTypeId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var member = (from c in dbContext.Cases
                              join m in dbContext.Members
                              on c.MemberID equals m.ID
                              where c.ContactPhoneNumber == callbackNumber /*&& (phoneTypeId == c.ContactPhoneTypeID) - Turned off check against phone type*/
                              select m);
                return member.FirstOrDefault();
            }
        }
        /// <summary>
        /// Gets the specified id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public Member Get(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var member = dbContext.Members.Include("Membership").Include("Program").Where(x => x.ID == id);
                return member.FirstOrDefault();
            }
        }
        /// <summary>
        /// Gets the closed loop.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<CloseLoopSearch_Result> GetClosedLoop(PageCriteria pageCriteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetCloseLoopSearch(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection).ToList<CloseLoopSearch_Result>();
            }
        }
        /// <summary>
        /// Retrieve Associate List for Member Tab
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<MemberAssociateList_Result> GetAssociateListForMember(PageCriteria pageCriteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberAssociateList(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection).ToList<MemberAssociateList_Result>();
            }
        }
        /// <summary>
        /// Gets the membership contact information phone details.
        /// </summary>
        /// <param name="membsershipID">The membsership ID.</param>
        /// <param name="phonetypeID">The phonetype ID.</param>
        /// <returns></returns>
        private PhoneEntity GetMembershipContactInformationPhoneDetails(int membsershipID, int phonetypeID)
        {

            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.PhoneEntities.Where(u => u.PhoneTypeID == phonetypeID)
                                                    .Where(p => p.RecordID == membsershipID)
                                                    .FirstOrDefault();

                if (result == null) { result = new PhoneEntity(); result.PhoneNumber = string.Empty; }
                return result;
            }

        }
        /// <summary>
        /// Retrieve Contact Information for Member Tab
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public MemberContactInformation_Result GetMembershipContactInformation(int memberID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                var result = dbContext.GetMemberContactInformation(memberID).FirstOrDefault();
                return result;
            }
        }
        /// <summary>
        /// Retrieve Service Request History for Member Tab
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<MemberServiceRequestHistory_Result> GetMemberServiceRequestHistory(PageCriteria pageCriteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMemberServiceRequestHistory(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection).ToList<MemberServiceRequestHistory_Result>();
            }
        }
        /// <summary>
        /// Update Email Address if it's changes
        /// </summary>
        /// <param name="firstName">The first name.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="email">The email.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="memberID">The member ID.</param>
        /// <exception cref="DMSException">Unable to retrieve member details while updating email</exception>
        public void UpdatePersonalInfo(string firstName, string lastName, string email, string userName, int memberID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Member member = dbContext.Members.Where(u => u.ID == memberID).FirstOrDefault();
                if (member != null)
                {
                    //throw new DMSException("Unable to retrieve member details while updating email");
                    member.Email = email;
                    member.ModifyBy = userName;
                    member.ModifyDate = System.DateTime.Now;

                    dbContext.SaveChanges();
                }

            }
        }
        /// <summary>
        /// Gets the member detailsby ID.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public Member GetMemberDetailsbyID(int memberID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.Members.Where(u => u.ID == memberID).FirstOrDefault();
            }
        }
        /// <summary>
        /// Gets the membership information.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public MembsershipInformation_Result GetMembershipInformation(int memberID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMembershipInformation(memberID).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the member by number.
        /// </summary>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        public Member GetMemberByNumber(string memberNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var member = (from ms in dbContext.Memberships
                              join m in dbContext.Members on ms.ID equals m.MembershipID
                              where m.IsPrimary == true && ms.MembershipNumber == memberNumber
                              select m).FirstOrDefault();
                return member;
            }
        }
        /// <summary>
        /// Gets the mobile call for service.
        /// </summary>
        /// <param name="phoneNumber">The phone number.</param>
        /// <returns></returns>
        public Mobile_CallForService GetMobileCallForService(string phoneNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetMemberFromMobileCallForService(phoneNumber).ToList<Mobile_CallForService>();
                return result.FirstOrDefault();
            }
        }
        /// <summary>
        /// Clients the portal member registration.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="loggedInUser">The logged in user.</param>
        /// <returns></returns>
        public int? ClientPortalMemberRegistration(MemberModel model, string loggedInUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //TODO : NP 10/28: Commented as it is giving error.
                int? returnValue = null;
                int? recordID = null;
                //dbContext.ClientPortalRegisterMember(model.MemberID,
                //                                 model.ProgramID,
                //                                 model.Prefix,
                //                                 model.FirstName,
                //                                 model.MiddleName,
                //                                 model.LastName,
                //                                 model.Suffix,
                //                                 model.PhoneType,
                //                                 model.PhoneNumber,
                //                                 model.AddressLine1,
                //                                 model.AddressLine2,
                //                                 model.AddressLine3,
                //                                 model.AddressTypeID,
                //                                 model.City,
                //                                 model.State,
                //                                 model.PostalCode,
                //                                 model.Country,
                //                                 model.Email,
                //                                 model.EffectiveDate,
                //                                 model.ExpirationDate,
                //                                 loggedInUser
                //                                 ).FirstOrDefault();
                if (recordID.HasValue)
                {
                    returnValue = recordID.Value;
                }
                return returnValue;

            }
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets the member number.
        /// </summary>
        /// <param name="membershipId">The membership ID.</param>
        /// <returns></returns>
        public string GetMemberNumber(int membershipId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //KB: Changed after member number was dropped during the development of member management module.
                Membership member = dbContext.Memberships.Where(m => m.ID == membershipId).FirstOrDefault<Membership>();
                if (member != null)
                {
                    return member.MembershipNumber;
                }
            }
            return null;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Save member info.
        /// </summary>
        /// <param name="member">The Member object</param>
        /// <param name="entityName">The Entity name</param>
        /// <param name="userName">logged in User name</param>
        /// <returns></returns>
        public void Save(Member member, string entityName, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Member existingDetails = null;
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entity name " + entityName);
                }

                existingDetails = dbContext.Members.Where(u => u.ID == member.ID).FirstOrDefault();

                if (existingDetails == null)
                {
                    member.CreateDate = DateTime.Now;
                    member.CreateBy = userName;
                    dbContext.Members.Add(member);
                    dbContext.SaveChanges();

                }
                else
                {
                    existingDetails.ProgramID = member.ProgramID;
                    existingDetails.Prefix = Left(member.Prefix, 10);
                    existingDetails.FirstName = Left(member.FirstName, 50);
                    existingDetails.MiddleName = Left(member.MiddleName, 50);
                    existingDetails.LastName = Left(member.LastName, 50);
                    existingDetails.Suffix = Left(member.Suffix, 10);
                    existingDetails.Email = Left(member.Email, 255);

                    if (member.EffectiveDate.HasValue) // TFS  : 594
                    {
                        existingDetails.EffectiveDate = member.EffectiveDate;
                    }
                    if (member.ExpirationDate.HasValue) // TFS  : 594
                    {
                        existingDetails.ExpirationDate = member.ExpirationDate;
                    }
                    if (member.MemberSinceDate.HasValue)
                    {
                        existingDetails.MemberSinceDate = member.MemberSinceDate;
                    }
                    existingDetails.IsPrimary = member.IsPrimary;
                    existingDetails.ModifyDate = DateTime.Now;
                    existingDetails.ModifyBy = userName;
                    existingDetails.IsActive = member.IsActive; // TFS  : 594
                    //NP (12/23): Added to update the column ClientMemberType
                    //if (member.ClientMemberType != null)
                    //{
                    existingDetails.ClientMemberType = member.ClientMemberType;
                    //}
                    dbContext.Entry(existingDetails).State = EntityState.Modified;
                    dbContext.SaveChanges();

                }

            }

        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets list of memberships info by membership number.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="parentpgmID">The parent program ID.</param>
        /// <returns></returns>
        public List<Membership> GetMemberShipsByMembershipNo(string membershipNumber, int parentpgmID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<Membership> memberships = (from ms in dbContext.Memberships
                                                join m in dbContext.Members on ms.ID equals m.MembershipID
                                                join p in dbContext.Programs on m.ProgramID equals p.ID
                                                where (ms.MembershipNumber == membershipNumber) & (p.ParentProgramID == parentpgmID) & (m.IsPrimary.Value == true)
                                                select ms).ToList();
                return memberships;
                #region commented
                //List<Membership> memberships = (from ms in dbContext.Memberships
                //              join m in dbContext.Members on ms.ID equals m.MembershipID
                //              where (ms.MembershipNumber == membershipNumber) & (m.IsPrimary.Value == true)
                //              select ms).ToList();
                //if (memberships != null & memberships.Count > 0)
                //{
                //    foreach (Membership membership in memberships)
                //    {
                //        Member member = dbContext.Members.Where(x => x.MembershipID == membership.ID & x.IsPrimary.Value == true).FirstOrDefault();
                //        if (member != null)
                //        {
                //            members.Add(member);
                //        }
                //    }

                //     filteredMemberships = (from ms in memberships
                //                                            join m in members on ms.ID equals m.MembershipID
                //                                            join p in dbContext.Programs on m.ProgramID equals p.ID
                //                                            where (p.ParentProgramID == parentpgmID)
                //                                            select ms).ToList();
                //}
                #endregion
            }

        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets a memberships info by membership number.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="parentpgmID">The parent program ID.</param>
        /// <returns></returns>
        public Membership GetMemberShip(string membershipNumber, int parentpgmID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //KB: Changed after member number was dropped during the development of member management module.
                Membership memberships = (from ms in dbContext.Memberships
                                          join m in dbContext.Members on ms.ID equals m.MembershipID
                                          join p in dbContext.Programs on m.ProgramID equals p.ID
                                          where (ms.MembershipNumber == membershipNumber) & (p.ParentProgramID == parentpgmID) & (m.IsPrimary.Value == true)
                                          select ms).FirstOrDefault();
                if (memberships != null)
                {
                    return memberships;
                }
            }
            return null;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets list of secondary members by membership number.
        /// </summary>
        /// <param name="memberNumber">The membership number.</param>
        /// <returns></returns>
        public List<Member> GetSecondaryMembersByNumber(string memberNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<Member> memberList = (from ms in dbContext.Memberships
                                           join m in dbContext.Members on ms.ID equals m.MembershipID
                                           where m.IsPrimary == false && ms.MembershipNumber == memberNumber
                                           select m).ToList<Member>();
                return memberList;
            }
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Get list of members by membership id.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public List<Member> GetMembersByMembershipID(int membershipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //KB: Changed after member number was dropped during the development of member management module.
                List<Member> member = dbContext.Members.Where(m => m.MembershipID == membershipID).ToList<Member>();
                if (member != null && member.Count > 0)
                {
                    return member;
                }
            }
            return null;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Get list of Primary Member info by MembershipNumber
        /// </summary>
        /// <param name="membershipNo">The membership number.</param>
        /// <param name="parentpgmID">The parent program ID.</param>
        /// <returns></returns>
        public List<Member> GetPrimaryMemberInfoByMembershipNumber(string membershipNo, int parentpgmID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<Member> member = (from m in dbContext.Members
                                       join ms in dbContext.Memberships on m.MembershipID equals ms.ID
                                       join p in dbContext.Programs on m.ProgramID equals p.ID
                                       where (ms.MembershipNumber == membershipNo) & (p.ParentProgramID == parentpgmID) & (m.IsPrimary.Value == true)
                                       select m).ToList();
                if (member != null & member.Count > 0)
                {
                    return member;
                }

            }
            return null;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Get list of secondary member info by membership number.
        /// </summary>
        /// <param name="membershipNo">The membership number.</param>
        /// <returns></returns>
        public List<Member> GetSecondaryMemberInfoByMembershipNumber(string membershipNo, int parentpgmID)
        {

            using (DMSEntities dbContext = new DMSEntities())
            {
                List<Member> member = (from m in dbContext.Members
                                       join ms in dbContext.Memberships on m.MembershipID equals ms.ID
                                       join p in dbContext.Programs on m.ProgramID equals p.ID
                                       where (ms.MembershipNumber == membershipNo) & (p.ParentProgramID == parentpgmID) & (m.IsPrimary.Value == false)
                                       select m).ToList();
                if (member != null & member.Count > 0)
                {
                    return member.ToList();
                }
            }
            return null;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Find if Hagerty service returned any new members.
        /// </summary>
        /// <param name="membershipNo">The membership number.</param>
        /// <param name="memberList">Hagerty service returned secondary member list</param>
        /// <param name="parentpgmID">The parent program ID.</param>
        /// <returns></returns>
        public List<SecondaryMember> MoreNewSecondaryMember(string membershipNo, List<SecondaryMember> memberList, int parentpgmID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var fNames = (from m in dbContext.Members
                              join ms in dbContext.Memberships on m.MembershipID equals ms.ID
                              join p in dbContext.Programs on m.ProgramID equals p.ID
                              where (ms.MembershipNumber == membershipNo) & (p.ParentProgramID == parentpgmID) & (m.IsPrimary.Value == false)
                              select m.FirstName.Trim().ToUpper()).ToList();

                var lNames = (from m in dbContext.Members
                              join ms in dbContext.Memberships on m.MembershipID equals ms.ID
                              join p in dbContext.Programs on m.ProgramID equals p.ID
                              where (ms.MembershipNumber == membershipNo) & (p.ParentProgramID == parentpgmID) & (m.IsPrimary.Value == false)
                              select m.LastName.Trim().ToUpper()).ToList();

                if (fNames.Count > 0 & lNames.Count > 0)
                {
                    var moreNewMembers = (from wsMember in memberList where !(fNames.Contains(wsMember.secFirstName) & lNames.Contains(wsMember.secLastName)) select wsMember);

                    if (moreNewMembers != null)
                    {
                        return moreNewMembers.ToList();
                    }
                }

            }
            return null;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Get list of Hagerty secondary members that are already exist in the data base.
        /// </summary>
        /// <param name="members">Data base retuned secondary member list.</param>
        /// <param name="memberList">Hagerty service returned secondary member list.</param>
        /// <returns></returns>
        public List<Member> ExistingSecondaryMember(List<Member> members, List<SecondaryMember> memberList)
        {

            List<Member> existingMembers = (from M in members
                                            join ML in memberList on M.FirstName.Trim().ToUpper() equals ML.secFirstName
                                            where ((M.FirstName.Trim().ToUpper() + "|" + M.LastName.Trim().ToUpper()).Equals(ML.secFullName))
                                            select M).ToList();
            if (existingMembers != null & existingMembers.Count > 0)
            {
                return existingMembers.ToList();
            }

            return null;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets list of members id by membership number.
        /// </summary>
        /// <param name="membershipNo">The membership number.</param>
        /// <param name="parentpgmID">The parent program ID.</param>
        /// <returns></returns>
        public int[] GetMemberIDList(string membershipNo, int parentpgmID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                int[] memberIds = (from M in dbContext.Members
                                   join MS in dbContext.Memberships on M.MembershipID equals MS.ID
                                   join p in dbContext.Programs on M.ProgramID equals p.ID
                                   where (MS.MembershipNumber == membershipNo) & (p.ParentProgramID == parentpgmID)
                                   select M.ID).ToArray();
                return memberIds;
            }
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets program id by customer program plan.
        /// </summary>
        /// <param name="customerType">The customer type.</param>
        /// <param name="planType">The customer plan Type.</param>
        /// <returns></returns>
        public int? GetHagertyNewProgramID(string customerType, string planType)
        {

            using (DMSEntities dbContext = new DMSEntities())
            {
                try
                {
                    var PgmMapInfo = dbContext.HagertyProgramMaps.Where(p => p.CustomerType.Trim().ToUpper() == customerType.Trim().ToUpper() &
                                                        p.PlanType.Trim().ToUpper() == planType.Trim().ToUpper()).FirstOrDefault();
                    if (PgmMapInfo != null)
                    {
                        return PgmMapInfo.ProgramID;
                    }
                    else
                    {
                        var pgm = dbContext.HagertyProgramMaps.Where(p => p.CustomerType == "Non-Standard").FirstOrDefault();
                        return pgm.ProgramID;

                    }
                }
                catch
                {
                    var pgm = dbContext.HagertyProgramMaps.Where(p => p.CustomerType == "Non-Standard").FirstOrDefault();
                    return pgm.ProgramID;
                }
            }

        }


        /// <summary>
        /// Updates the members expiration date.
        /// </summary>
        /// <param name="expirationDate">The expiration date.</param>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Member Not Found with ID : +memberID
        /// or
        /// No SR found with ID :+serviceRequestID
        /// </exception>
        public DateTime? UpdateMembersExpirationDate(DateTime? expirationDate, int memberID, int serviceRequestID, string currentUser)
        {
            DateTime? membersExpirationDate = null;
            DateTime? membersEffectiveDate = null;
            string isActive = "Inactive";
            bool? isMemberActive = null;
            Member existingMember = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                existingMember = dbContext.Members.Where(a => a.ID == memberID).FirstOrDefault();
                if (existingMember == null)
                {
                    throw new DMSException("Member Not Found with ID : " + memberID);
                }
                membersExpirationDate = existingMember.ExpirationDate;
                membersEffectiveDate = existingMember.EffectiveDate;
                isMemberActive = existingMember.IsActive;
                //TFS : 435
                if (membersEffectiveDate <= DateTime.Now && expirationDate >= DateTime.Now)//&& isMemberActive == true)
                {
                    isActive = "Active";
                    existingMember.IsActive = true;
                }
                else
                {
                    existingMember.IsActive = false;
                }
                existingMember.ExpirationDate = expirationDate;
                existingMember.ModifyBy = currentUser;
                existingMember.ModifyDate = DateTime.Now;
                dbContext.Entry(existingMember).State = EntityState.Modified;
                ServiceRequest existingSR = dbContext.ServiceRequests.Where(a => a.ID == serviceRequestID).FirstOrDefault();
                if (existingSR == null)
                {
                    throw new DMSException("No SR found with ID :" + serviceRequestID);
                }
                Case existingCase = dbContext.Cases.Where(a => a.ID == existingSR.CaseID).FirstOrDefault();
                existingCase.MemberStatus = isActive;
                dbContext.Entry(existingCase).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
            return membersExpirationDate;
        }

        /// <summary>
        /// Saves the members expiration date.
        /// </summary>
        /// <param name="expirationDate">The expiration date.</param>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Member Not Found with ID :  + memberID</exception>
        public DateTime? SaveMembersExpirationDate(DateTime? expirationDate, int memberID, string currentUser)
        {
            DateTime? membersExpirationDate = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                Member existingMember = dbContext.Members.Where(a => a.ID == memberID).FirstOrDefault();
                if (existingMember == null)
                {
                    throw new DMSException("Member Not Found with ID : " + memberID);
                }
                membersExpirationDate = existingMember.ExpirationDate;

                existingMember.ExpirationDate = expirationDate;
                existingMember.ModifyBy = currentUser;
                existingMember.ModifyDate = DateTime.Now;

                dbContext.Entry(existingMember).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
            return membersExpirationDate;
        }

        /// <summary>
        /// Saves the name of the member.
        /// </summary>
        /// <param name="firstName">The first name.</param>
        /// <param name="middleName">Name of the middle.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <exception cref="DMSException">Member Not Found with ID :  + memberID</exception>
        public void SaveMemberName(string firstName, string middleName, string lastName, int memberID, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Member existingMember = dbContext.Members.Where(a => a.ID == memberID).FirstOrDefault();
                if (existingMember == null)
                {
                    throw new DMSException("Member Not Found with ID : " + memberID);
                }
                existingMember.FirstName = firstName;
                existingMember.MiddleName = middleName;
                existingMember.LastName = lastName;

                existingMember.ModifyBy = currentUser;
                existingMember.ModifyDate = DateTime.Now;

                dbContext.Entry(existingMember).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the members program identifier.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <exception cref="DMSException">Member Not Found with ID :  + memberID</exception>
        public void UpdateMembersProgramID(int programID, int memberID, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Member existingMember = dbContext.Members.Where(a => a.ID == memberID).FirstOrDefault();
                if (existingMember == null)
                {
                    throw new DMSException("Member Not Found with ID : " + memberID);
                }
                existingMember.ProgramID = programID;
                existingMember.ModifyBy = currentUser;
                existingMember.ModifyDate = DateTime.Now;

                dbContext.Entry(existingMember).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the program coverage information list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramCoverageInformationList_Result> GetProgramCoverageInformationList(PageCriteria pc, int? programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramCoverageInformationList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, programID).ToList();
            }
        }

        //Lakshmi - Hagerty Production Fix- Truncate string if value is more than defined length.
        /// <summary>
        /// Get the first n characters from the left.
        /// </summary>
        /// <param name="s">The string</param>
        /// <param name="number">The number of characters to be extracted from the start.</param>
        /// <returns></returns>
        public string Left(string s, int number)
        {
            if (!string.IsNullOrEmpty(s) && s.Length > number)
            {
                return s.Substring(0, number);
            }
            else if (!string.IsNullOrEmpty(s) && s.Length <= number)
            {
                return s;
            }

            return s;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets the member parent by program identifier.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <returns></returns>
        public int? GetMemberParentProgrambyID(int memberID)
        {
            int? parentPgmID = null;
            using (DMSEntities entities = new DMSEntities())
            {
                var program = (from p in entities.Programs
                               join m in entities.Members on p.ID equals m.ProgramID
                               where m.ID == memberID
                               select p).FirstOrDefault();
                if (program != null && program.ParentProgramID != null)
                {
                    parentPgmID = program.ParentProgramID.Value;
                }

            }
            return parentPgmID;
        }





        /// <summary>
        /// Gets the member by client member key.
        /// </summary>
        /// <param name="clientMemberKey">The client member key.</param>
        /// <returns></returns>
        public Member GetMemberByClientMemberKey(string clientMemberKey, int clientID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Members.Where(a => (a.ClientMemberKey == clientMemberKey) && a.Program.ClientID == clientID).Include(m=>m.Membership).Include("Program").FirstOrDefault();
            }
        }

        public List<SearchMembersForAPI_Result> SearchMemberForAPI(string customerID, string customerGroupID, int? internalMemberID, string lastName, string firstName, string vehicleVIN, string userName)
        {
            logger.InfoFormat("MemberRepository - SearchMemberForAPI(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                customerID = customerID,
                customerGroupID = customerGroupID,
                internalMemberID = internalMemberID,
                userName = userName
            }));
            List<SearchMembersForAPI_Result> result = new List<SearchMembersForAPI_Result>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Database.CommandTimeout = 180;
                result = dbContext.SearchMembersForAPI(customerID, customerGroupID, internalMemberID, lastName, firstName, vehicleVIN, userName).ToList();
            }
            logger.InfoFormat("MemberRepository - SearchMemberForAPI(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                result = result
            }));
            return result;
        }
    }

    //Lakshmi - Hagerty Integration
    public class SecondaryMember
    {
        public string secFirstName { get; set; }
        public string secLastName { get; set; }
        public string secFullName { get; set; }
    }
}
