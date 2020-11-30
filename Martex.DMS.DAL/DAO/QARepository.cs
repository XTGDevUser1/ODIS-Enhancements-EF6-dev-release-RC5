using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// QARepository
    /// </summary>
    public class QARepository
    {
        /// <summary>
        /// Gets the QA concern type list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<QAConcernTypeList_Result> GetQAConcernTypeList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetQAConcernTypeList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<QAConcernTypeList_Result>();
            }
        }


        /// <summary>
        /// Deletes the type of the concern.
        /// </summary>
        /// <param name="concernTypeId">The concern type identifier.</param>
        public void DeleteConcernType(int concernTypeId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var qAConcernType = dbContext.ConcernTypes.Where(a => a.ID == concernTypeId).FirstOrDefault();
                if (qAConcernType != null)
                {
                    dbContext.Entry(qAConcernType).State = EntityState.Deleted;
                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the type of the concern.
        /// </summary>
        /// <param name="concernTypeId">The concern type identifier.</param>
        /// <returns></returns>
        public ConcernType GetConcernType(int concernTypeId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var concernType = dbContext.ConcernTypes.Where(a => a.ID == concernTypeId).FirstOrDefault();
                if (concernType == null)
                {
                    concernType = new ConcernType();
                }
                return concernType;
            }
        }

        /// <summary>
        /// Saves the type of the concern.
        /// </summary>
        /// <param name="concernType">Type of the concern.</param>
        public void SaveConcernType(ConcernType concernType)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var mode = "add";
                if (concernType != null && concernType.ID > 0)
                {
                    var existingConcernType = dbContext.ConcernTypes.Where(a => a.ID == concernType.ID).FirstOrDefault();
                    if (existingConcernType != null)
                    {
                        mode = "edit";
                        existingConcernType.Name = concernType.Name;
                        existingConcernType.Description = concernType.Description;
                        existingConcernType.IsActive = concernType.IsActive;
                        existingConcernType.Sequence = concernType.Sequence;
                    }
                }
                if (mode == "add")
                {
                    dbContext.ConcernTypes.Add(concernType);
                }
                dbContext.SaveChanges();
            }
        }
        
        /// <summary>
        /// Gets the qa concern type list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="concernTypeID">The concern type identifier.</param>
        /// <returns></returns>
        public List<QAConcernList_Result> GetQAConcernList(PageCriteria pc, int? concernTypeID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetQAConcernList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, concernTypeID).ToList<QAConcernList_Result>();
            }
        }


        /// <summary>
        /// Deletes the concern.
        /// </summary>
        /// <param name="concernId">The concern identifier.</param>
        public void DeleteConcern(int concernId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var qAConcern = dbContext.Concerns.Where(a => a.ID == concernId).FirstOrDefault();
                if (qAConcern != null)
                {
                    dbContext.Concerns.Remove(qAConcern);
                }
                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Gets the concern.
        /// </summary>
        /// <param name="concernId">The concern identifier.</param>
        /// <returns></returns>
        public Concern GetConcern(int concernId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var concern = dbContext.Concerns.Include("ConcernType").Where(a => a.ID == concernId).FirstOrDefault();
                if (concern == null)
                {
                    concern = new Concern();
                }
                return concern;
            }
        }

        /// <summary>
        /// Saves the concern.
        /// </summary>
        /// <param name="concern">The concern.</param>
        public void SaveConcern(Concern concern)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var mode = "add";
                if (concern != null && concern.ID > 0)
                {
                    var existingConcern = dbContext.Concerns.Where(a => a.ID == concern.ID).FirstOrDefault();
                    if (existingConcern != null)
                    {
                        mode = "edit";
                        existingConcern.Name = concern.Name;
                        existingConcern.Description = concern.Description;
                        existingConcern.IsActive = concern.IsActive;
                        existingConcern.Sequence = concern.Sequence;
                        existingConcern.ConcernTypeID = concern.ConcernTypeID;
                    }
                }
                if (mode == "add")
                {
                    dbContext.Concerns.Add(concern);
                }
                dbContext.SaveChanges();
            }
        }
    }
}
