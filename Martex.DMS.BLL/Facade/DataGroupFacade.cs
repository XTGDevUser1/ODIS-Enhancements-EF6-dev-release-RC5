using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using log4net;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class DataGroupFacade
    {
        #region Protected Methods
        
        /// <summary>
        /// The data group repository
        /// </summary>
        DataGroupRepository repository = new DataGroupRepository();

        #endregion

        #region Public Methods

        /// <summary>
        /// Lists the specified user id.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<DataGroupList> List(Guid userId, PageCriteria pc)
        {
            return repository.Search(userId, pc);
        }

        /// <summary>
        /// Gets the specified data group id.
        /// </summary>
        /// <param name="dataGroupId">The data group id.</param>
        /// <returns></returns>
        public DataGroup Get(string dataGroupId)
        {
            if (!string.IsNullOrEmpty(dataGroupId))
            {
                return repository.Get(int.Parse(dataGroupId));
            }
            return null;
        }

        /// <summary>
        /// Adds the specified data group.
        /// </summary>
        /// <param name="dataGroup">The data group.</param>
        /// <param name="dataGroupProgramList">The data group program list.</param>
        /// <param name="userName">Name of the user.</param>
        public void Add(DataGroup dataGroup, int[] dataGroupProgramList, string userName)
        {
            foreach (int dataGroupProgramId in dataGroupProgramList)
            {
                dataGroup.DataGroupPrograms.Add(new DataGroupProgram() { ProgramID = dataGroupProgramId });
            }
            dataGroup.CreateDate = DateTime.Now;
            dataGroup.ModifyDate = DateTime.Now;
            dataGroup.CreateBy = userName;
            dataGroup.ModifyBy = userName;

            repository.Add(dataGroup);
        }

        /// <summary>
        /// Updates the specified data group.
        /// </summary>
        /// <param name="dataGroup">The data group.</param>
        /// <param name="dataGroupProgramList">The data group program list.</param>
        /// <param name="userName">Name of the user.</param>
        public void Update(DataGroup dataGroup, int[] dataGroupProgramList, string userName)
        {
            dataGroup.ModifyDate = DateTime.Now;
            dataGroup.ModifyBy = userName;
            repository.Update(dataGroup, dataGroupProgramList);
        }

        /// <summary>
        /// Deletes the specified data group id.
        /// </summary>
        /// <param name="dataGroupId">The data group id.</param>
        public void Delete(string dataGroupId)
        {
            repository.Delete(int.Parse(dataGroupId));
        }

        #endregion
    }
}
