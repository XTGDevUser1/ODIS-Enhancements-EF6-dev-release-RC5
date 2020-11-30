using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{
    public partial class MemberManagementRepository
    {
        /// <summary>
        /// Gets the member ship info details.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public MemberShipInfoDetails GetMemberShipInfoDetails(int membershipID)
        {
            MemberShipInfoDetails model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = (from membership in dbContext.Memberships
                         join member in dbContext.Members on membership.ID equals member.MembershipID
                         join program in dbContext.Programs on member.ProgramID equals program.ID
                         join client in dbContext.Clients on program.ClientID equals client.ID
                         where membership.ID == membershipID
                         where member.IsPrimary == true
                         select new MemberShipInfoDetails()
                         {
                             ClientID = client.ID,
                             ProgramID = member.ProgramID,
                             ClientReference = membership.ClientReferenceNumber,
                             CreatedBy = membership.CreateBy,
                             ModifiedBy = membership.ModifyBy,
                             ModifiedOn = membership.ModifyDate,
                             CreatedOn = membership.CreateDate,
                             EffectiveDate = member.EffectiveDate,
                             Email = member.Email,
                             ExpirationDate = member.ExpirationDate,
                             FirstName = member.FirstName,
                             LastName = member.LastName,
                             MembershipID = membershipID,
                             MemberShipNumber = membership.MembershipNumber,
                             MemberSince = member.MemberSinceDate,
                             MiddleName = member.MiddleName,
                             PrefixName = member.Prefix,
                             SuffixName = member.Suffix,
                             MasterMemberID = member.ID,
                             SourceID = membership.SourceSystemID,
                             MemberNote = membership.Note,
                             MemberReferenceProgram = member.ReferenceProgram

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
                if (model.ClientID != null)
                {
                    Client client = dbContext.Clients.Where(a => a.ID == model.ClientID).FirstOrDefault();
                    model.ClientName = client.Name;
                }
            }
            return model;
        }

        /// <summary>
        /// Updates the member ship info details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <exception cref="DMSException">
        /// </exception>
        public void UpdateMemberShipInfoDetails(MemberShipInfoDetails model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var membershipDetails = dbContext.Memberships.Where(u => u.ID == model.MembershipID).FirstOrDefault();
                var memberDetails = dbContext.Members.Where(u => u.ID == model.MasterMemberID).FirstOrDefault();

                if (membershipDetails == null) { throw new DMSException(string.Format("Unable to retrieve membership details for the given id {0}", model.MembershipID)); }
                if (memberDetails == null) { throw new DMSException(string.Format("Unable to retrieve member details for the given id {0}", model.MasterMemberID)); }

                #region Master Member Details
                memberDetails.ModifyDate = DateTime.Now;
                memberDetails.ModifyBy = userName;
                //Sanghi : CR 252 DO NOT UPDATE Is Active Field as this field is treated as Deleted Flag for Member
                //memberDetails.IsActive = model.IsMemberExpired;
                memberDetails.ExpirationDate = model.ExpirationDate;
                memberDetails.EffectiveDate = model.EffectiveDate;
                memberDetails.Email = model.Email;
                memberDetails.Suffix = model.SuffixName;
                memberDetails.Prefix = model.PrefixName;
                memberDetails.FirstName = model.FirstName;
                memberDetails.LastName = model.LastName;
                memberDetails.MiddleName = model.MiddleName;
                memberDetails.ProgramID = model.ProgramID;
                #endregion

                #region MembershipDetails
                membershipDetails.ModifyBy = userName;
                membershipDetails.ModifyDate = DateTime.Now;
                membershipDetails.ClientReferenceNumber = model.ClientReference;
                membershipDetails.Email = model.Email;
                membershipDetails.MembershipNumber = model.MemberShipNumber;
                membershipDetails.Note = model.MemberNote;

                #endregion

                dbContext.SaveChanges();
            }
        }
    }
}
