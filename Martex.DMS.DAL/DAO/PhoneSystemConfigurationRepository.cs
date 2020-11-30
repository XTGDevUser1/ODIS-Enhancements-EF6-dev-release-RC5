using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;


namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class PhoneSystemConfigurationRepository 
    {
        /// <summary>
        /// Gets all for.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="userId">The user id.</param>
        /// <returns></returns>
        public List<PhoneSystemConfigurationList> GetAllFor(Common.PageCriteria pageCriteria,Guid? userId)
        {
            DMSEntities dbContext = new DMSEntities();
            var list = dbContext.GetPhoneSystemConfigurationList(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection,userId).ToList<PhoneSystemConfigurationList>();
            return list;
        }
        /// <summary>
        /// Gets the specified phone system configuration id.
        /// </summary>
        /// <param name="phoneSystemConfigurationId">The phone system configuration id.</param>
        /// <returns></returns>
        public PhoneSystemConfiguration Get(int phoneSystemConfigurationId)
        {
            DMSEntities dbContext = new DMSEntities();
            var results = dbContext.PhoneSystemConfigurations.Where(a => a.ID == phoneSystemConfigurationId).First();
            return results;
        }
        /// <summary>
        /// Deletes the specified phone system configuration id.
        /// </summary>
        /// <param name="phoneSystemConfigurationId">The phone system configuration id.</param>
        /// <exception cref="DMSException">Unable to retrieve the Phone System Configuration details.</exception>
        public void Delete(int phoneSystemConfigurationId)
        {
            DMSEntities dbContext = new DMSEntities();
            var phoneSystemConfiguration = dbContext.PhoneSystemConfigurations.Where(a => a.ID == phoneSystemConfigurationId).First();
           
            if (phoneSystemConfiguration == null)
            {
                throw new DMSException("Unable to retrieve the Phone System Configuration details.");
            }

            dbContext.Entry(phoneSystemConfiguration).State = EntityState.Deleted;
            dbContext.SaveChanges();
        }
        /// <summary>
        /// Gets the name of the program.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Program does not exist</exception>
        public string GetProgramName(int programId)
        {
            DMSEntities dbContext = new DMSEntities();
            
            var results = dbContext.Programs.Where(id=>id.ID == programId).FirstOrDefault();
            if (results != null)
            {
                return results.Name;
            }
            throw new DMSException("Program does not exist");
        }

        /// <summary>
        /// Gets the name of the parent program.
        /// </summary>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Program does not exist</exception>
        public string GetParentProgramName(int programId)
        {
            DMSEntities dbContext = new DMSEntities();

            var results = dbContext.Programs.Where(id => id.ID == programId).FirstOrDefault();
            if (results != null)
            {
                var parentProgram = dbContext.Programs.Where(a => a.ID == results.ParentProgramID).FirstOrDefault();
                if (parentProgram != null)
                {
                    return parentProgram.Name;
                }
                else
                {
                    return "No Parent Program";
                }
            }
            throw new DMSException("Program does not exist");
        }
        /// <summary>
        /// Updates the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <exception cref="System.Exception">Phone system configuration already exists for this program.</exception>
        public void Update(PhoneSystemConfiguration model)
        {
            DMSEntities dbContext = new DMSEntities();

            var existingProgram = dbContext.PhoneSystemConfigurations.Where(u => u.ProgramID == model.ProgramID && u.ID != model.ID);
            if (existingProgram.Count() > 0) throw new DMSException("Phone system configuration already exists for this program.");

            var results = dbContext.PhoneSystemConfigurations.Where(p => p.ID == model.ID).FirstOrDefault();
           
            if (results != null)
            {
                results.ProgramID = model.ProgramID;
                results.InboundNumber = model.InboundNumber;
                results.IVRScriptID = model.IVRScriptID;
                results.InboundPhoneCompanyID = model.InboundPhoneCompanyID;
                results.PilotNumber = model.PilotNumber;
                results.SkillsetID = model.SkillsetID;
                results.ModifyBy = model.ModifyBy;
                results.ModifyDate = model.ModifyDate;
                results.IsActive = model.IsActive;
                results.IsShownOnScreen = model.IsShownOnScreen;
                dbContext.Entry(results).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }
        /// <summary>
        /// Adds the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <exception cref="DMSException">Phone system configuration already exists for this program.</exception>
        public void Add(PhoneSystemConfiguration model)
        {
            DMSEntities dbContext = new DMSEntities();

            var existingProgram = dbContext.PhoneSystemConfigurations.Where(u => u.ProgramID == model.ProgramID);
            if (existingProgram.Count() > 0) throw new DMSException("Phone system configuration already exists for this program.");
            dbContext.PhoneSystemConfigurations.Add(model);
            dbContext.Entry(model).State = EntityState.Added;
            dbContext.SaveChanges();
        }

    }
}
