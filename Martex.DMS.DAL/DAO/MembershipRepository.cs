using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;    // Lakshmi - Hagerty Integration 
using Martex.DMS.DAL.Common;        // Lakshmi - Hagerty Integration 
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;      // Lakshmi - Hagerty Integration 

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class MembershipRepository
    {
        /// <summary>
        /// Saves the specified membership.
        /// </summary>
        /// <param name="membership">The membership.</param>
        /// <returns></returns>
        public int Save(Membership membership)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Memberships.Add(membership);
                dbContext.SaveChanges();
            }
            return membership.ID;
        }

        // Lakshmi - Hagerty Integration 
        /// <summary>
        /// Saves the specified membership.
        /// </summary>
        /// <param name="membership">The membership.</param>
        /// <param name="entityName">The entity name.</param>
        /// <param name="userName">The logged in user name.</param>
        /// <returns></returns>
        public void Save(Membership membership, string entityName, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entity name " + entityName);
                }

                //Membership existingDetails = (from ms in dbContext.Memberships
                //                              join m in dbContext.Members on ms.ID equals m.MembershipID
                //                              where (ms.MembershipNumber == membership.MembershipNumber) && (m.IsPrimary.Value == true)
                //                              select ms).FirstOrDefault();

                Membership existingDetails = dbContext.Memberships.Where(u => u.ID == membership.ID).FirstOrDefault();

                if (existingDetails != null)
                {
                    existingDetails.IsActive = membership.IsActive;
                    existingDetails.ModifyBy = userName;
                    existingDetails.ModifyDate = System.DateTime.Now;
                    dbContext.Entry(existingDetails).State = EntityState.Modified;
                }

                dbContext.SaveChanges();
            }
        }

        // Lakshmi - Hagerty Integration 
        public int? GetSourceSystemID(string sourceName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //KB: A possible null reference error corrected. The query is modified to get an object from DB and access the ID property, if only a record is obtained.
                var sourcesystemID = dbContext.SourceSystems.Where(x => x.Name == sourceName).FirstOrDefault();
                if (sourcesystemID != null)
                    return sourcesystemID.ID;
            }
            return null;
        }

        public Membership Get(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Memberships.Where(a => a.ID == id).FirstOrDefault();
            }
        }



        /// <summary>
        /// Gets the Membership by membership number.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <returns></returns>
        public Membership GetByMembershipNumber(string membershipNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Memberships.Where(a => a.MembershipNumber.ToLower().Equals(membershipNumber.ToLower())).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the by membership number and program identifier.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public Membership GetByMembershipNumberAndProgramID(string membershipNumber, int? programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var member = dbContext.Members.Include(a => a.Membership).Where(a => a.ProgramID == programID && a.Membership.MembershipNumber == membershipNumber).FirstOrDefault();
                Membership membership = null;               
                if (member != null)
                {
                    membership = member.Membership;
                }

                return membership;
            }
        }

        /// <summary>
        /// Updates the membership.
        /// </summary>
        /// <param name="membership">The membership.</param>
        public void UpdateMembership(Membership membership)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Membership existingDetails = dbContext.Memberships.Where(u => u.ID == membership.ID).FirstOrDefault();

                if (existingDetails != null)
                {
                    existingDetails.MembershipNumber = membership.MembershipNumber;
                    existingDetails.Email = membership.Email;
                    existingDetails.ClientMembershipKey = membership.ClientMembershipKey;
                    existingDetails.IsActive = membership.IsActive;
                    existingDetails.ModifyBy = membership.ModifyBy;
                    existingDetails.ModifyDate = DateTime.Now;
                    existingDetails.SourceSystemID = membership.SourceSystemID;
                    dbContext.Entry(existingDetails).State = EntityState.Modified;
                }
                dbContext.SaveChanges();
            }
        }
    }
}
