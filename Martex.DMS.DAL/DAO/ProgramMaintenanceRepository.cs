using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using log4net;
using System.Data.Entity;
using Newtonsoft.Json;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    ///
    /// </summary>
    public class ProgramMaintenanceRepository
    {
        #region Protected Members
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ProgramMaintenanceRepository));

        #endregion
        /// <summary>
        /// Gets the mobile configuration result.
        /// </summary>
        /// <param name="programID">The program ID.</param>
        /// <param name="configurationType">Type of the configuration.</param>
        /// <param name="configurationCategory">The configuration category.</param>
        /// <param name="callbackNumber">The callback number.</param>
        /// <param name="inboundCallID">The inbound call ID.</param>
        /// <returns></returns>
        public List<MobileCallData_Result> GetMobileConfigurationResult(int programID, string configurationType, string configurationCategory, string callbackNumber, int inboundCallID, int? selectedMemberID, int? selectedMembershipID)
        {
            List<MobileCallData_Result> result = null;
            using (DMSEntities entities = new DMSEntities())
            {
                //using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, new TransactionOptions { IsolationLevel = IsolationLevel.Snapshot }))
                using (TransactionScope tran = new TransactionScope())
                {
                    result = entities.GetMobileCallData(programID, configurationType, configurationCategory, callbackNumber, inboundCallID, selectedMemberID, selectedMembershipID).ToList<MobileCallData_Result>();
                    tran.Complete();
                }
            }

            return result;
        }

        public List<Program> GetPrograms(string InboundNum)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                // Get any programs that match
                var matchingPrograms = dbContext.Programs.Where(
                    x => x.PhoneSystemConfigurations.FirstOrDefault() != null &&
                    x.PhoneSystemConfigurations.FirstOrDefault(y => y.InboundNumber == InboundNum) != null);
                
                var programParentIds =
                    matchingPrograms.Where(x => x.ParentProgramID == null)
                        .Select(x => x.ID);

                var matchingParentProgramIds = programParentIds.Union(
                    matchingPrograms.Where(x => x.ParentProgramID != null)
                        .Select(x => x.ParentProgramID.Value));

                var matchingParents =
                    dbContext.Programs.Where(
                        x => matchingParentProgramIds.Contains(x.ID));

                return matchingParents.ToList();
            }
        }
        /// <summary>
        /// Gets all for.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="userID">The user ID.</param>
        /// <returns></returns>
        public List<Programs_List_Results> GetAllFor(Common.PageCriteria pageCriteria, Guid userID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.GetProgramsList(userID, pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection).ToList<Programs_List_Results>();
                return list;
            }
        }
        /// <summary>
        /// Gets the specified program id.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public Program Get(int programId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.Programs.Where(a => a.ID == programId)
                                                .Include(p => p.Client)
                                                .FirstOrDefault();
                return results;
            }
        }

        /// <summary>
        /// Adds the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <exception cref="System.Exception">Program name already exists.</exception>
        public void Add(Program model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingProgram = dbContext.Programs.Where(u => u.Name == model.Name);
                if (existingProgram.Count() > 0) throw new DMSException("Program name already exists.");
                dbContext.Programs.Add(model);
                dbContext.Entry(model).State = EntityState.Added;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <exception cref="System.Exception">Program name already exists.</exception>
        public void Update(Program model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingProgram = dbContext.Programs.Where(u => u.ID != model.ID && u.Name == model.Name);
                if (existingProgram.Count() > 0) throw new Exception("Program name already exists.");
                existingProgram = dbContext.Programs.Where(u => u.ID == model.ID);
                var results = existingProgram.FirstOrDefault();
                if (results != null)
                {
                    results.Code = model.Code;
                    results.Name = model.Name;
                    results.Description = model.Description;
                    results.ClientID = model.ClientID;
                    results.ParentProgramID = model.ParentProgramID;
                    results.CallFee = model.CallFee;
                    results.DispatchFee = model.DispatchFee;
                    results.IsActive = model.IsActive;
                    results.IsGroup = model.IsGroup;
                    results.ModifyBy = model.ModifyBy;
                    results.ModifyDate = model.ModifyDate;
                    dbContext.Entry(results).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Deletes the specified program id.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <exception cref="DMSException">
        /// Unable to retrieve the Program details.
        /// or
        /// Cannot delete Program because it is linked to other records.
        /// </exception>
        public void Delete(int programId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.Programs.Where(a => a.ID == programId).First();
                if (result == null)
                {
                    throw new DMSException("Unable to retrieve the Program details.");
                }
                if (result.DataGroupPrograms.Count() > 0)
                {
                    throw new DMSException("Cannot delete Program because it is linked to other records.");
                }
                dbContext.Entry(result).State = EntityState.Deleted;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the programs for call.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <returns></returns>
        public static List<ProgramsForCall_Result> GetProgramsForCall(Guid userId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramsForCall(userId).ToList<ProgramsForCall_Result>();
            }
        }


        /// <summary>
        /// Gets the program info.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="configurationType">Type of the configuration.</param>
        /// <param name="configurationCategory">The configuration category.</param>
        /// <returns></returns>
        public List<ProgramInformation_Result> GetProgramInfo(int? programId, string configurationType, string configurationCategory)
        {
            logger.InfoFormat("ProgramMaintenanceRepository - GetProgramInfo(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                programId = programId,
                configurationType = configurationType,
                configurationCategory = configurationCategory
            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetProgramConfigurationForProgram(programId, configurationType, configurationCategory).ToList<ProgramInformation_Result>();
                return result;
            }
        }

        /// <summary>
        /// Gets the program services.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="productCategory">The product category.</param>
        /// <returns></returns>
        public List<ProgramServices_Result> GetProgramServices(int? programId, string productCategory)
        {
            logger.InfoFormat("ProgramMaintenanceRepository - GetProgramServices(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                programId = programId,
                productCategory = productCategory
            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetServicesForProgram(programId, productCategory).ToList<ProgramServices_Result>();
                return result;
            }
        }

        /// <summary>
        /// Gets the dynamic fields.
        /// </summary>
        /// <param name="screenName">Name of the screen.</param>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        public List<DynamicFields> GetDynamicFields(string screenName, int programID)
        {
            logger.InfoFormat("ProgramMaintenanceRepository - GetDynamicFields(), Parameters:  {0}", JsonConvert.SerializeObject(new { screenName = screenName, programID = programID }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<ProgramDynamicFields_Result> result = dbContext.GetProgramDynamicFields(programID, screenName).ToList<ProgramDynamicFields_Result>();
                List<DynamicFields> dynamicFields = new List<DynamicFields>();
                if (result != null && result.Count > 0)
                {
                    List<ProgramDynamicFields_Result> textBoxList = result.Where(u => u.ControlType.Equals(DynamicFieldsControlType.Textbox.ToString())).ToList<ProgramDynamicFields_Result>();
                    List<ProgramDynamicFields_Result> dropDownBoxList = result.Where(u => u.ControlType.Equals(DynamicFieldsControlType.Dropdown.ToString())).ToList<ProgramDynamicFields_Result>();
                    List<ProgramDynamicFields_Result> dropDownBoxListDistinct = dropDownBoxList.GroupBy(x => x.Label).Select(grp => grp.First()).ToList<ProgramDynamicFields_Result>();
                    foreach (ProgramDynamicFields_Result varTextBox in textBoxList)
                    {
                        DynamicFieldsDataType fieldDataType = DynamicFieldsDataType.Text;
                        Enum.TryParse(varTextBox.DataType, out fieldDataType);
                        dynamicFields.Add(new DynamicFields()
                        {
                            ProgramDataItemId = varTextBox.ID,
                            ControlType = DynamicFieldsControlType.Textbox,
                            DataType = fieldDataType,
                            DropDownValues = null,
                            FieldSequence = varTextBox.FieldSequence,
                            IsRequired = varTextBox.IsRequired,
                            Label = varTextBox.Label,
                            MaxLength = varTextBox.MaxLength,
                            Name = varTextBox.Name
                        });
                    }
                    foreach (ProgramDynamicFields_Result varDropDown in dropDownBoxListDistinct)
                    {
                        DynamicFields dropDown = new DynamicFields();
                        dropDown.ProgramDataItemId = varDropDown.ID;
                        dropDown.ControlType = DynamicFieldsControlType.Dropdown;
                        dropDown.DataType = varDropDown.Equals(DynamicFieldsDataType.Text) ? DynamicFieldsDataType.Text : DynamicFieldsDataType.Numeric;
                        dropDown.FieldSequence = varDropDown.FieldSequence;
                        dropDown.IsRequired = varDropDown.IsRequired;
                        dropDown.Label = varDropDown.Label;
                        dropDown.Name = varDropDown.Name;
                        dropDown.MaxLength = varDropDown.MaxLength;
                        dropDown.DropDownValues = (from f in dropDownBoxList
                                                   where f.Label.Equals(varDropDown.Label)
                                                   orderby f.ValueSequence
                                                   select new DynamicFieldsControlDropDownValues()
                                                   {
                                                       Name = f.Value,
                                                       Value = f.Value,
                                                   }).ToList<DynamicFieldsControlDropDownValues>();
                        dynamicFields.Add(dropDown);
                    }
                }
                dynamicFields = dynamicFields.OrderBy(u => u.FieldSequence).ToList<DynamicFields>();
                return dynamicFields;
            }
        }

        /// <summary>
        /// Adds the dynamic data value.
        /// </summary>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="relatedRecordId">The related record id.</param>
        /// <param name="programDataItemId">The program data item id.</param>
        /// <param name="val">The val.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="DMSException">Invalid entity name  + entityName</exception>
        public static void AddDynamicDataValue(string entityName, int relatedRecordId, int programDataItemId, string val, string userName)
        {
            //TFS: 665 - Dispatch - Blank value ProgramDataItemValueEntity
            if (!string.IsNullOrEmpty(val))
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    var entityFromDB = dbContext.Entities.Where(e => e.Name == entityName).FirstOrDefault();
                    if (entityFromDB == null)
                    {
                        throw new DMSException("Invalid entity name " + entityName);
                    }
                    ProgramDataItemValueEntity record = new ProgramDataItemValueEntity()
                    {
                        EntityID = entityFromDB.ID,
                        RecordID = relatedRecordId,
                        ProgramDataItemID = programDataItemId,
                        Value = val,
                        CreateBy = userName,
                        CreateDate = DateTime.Now,
                        ModifyBy = null,
                        ModifyDate = null
                    };

                    dbContext.ProgramDataItemValueEntities.Add(record);
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="entityName"></param>
        /// <param name="relatedRecordId"></param>
        /// <param name="programDataItemName"></param>
        /// <returns></returns>
        public static ProgramDataItemValueEntity Get(string entityName, int relatedRecordId, string programDataItemName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ProgramDataItemValueEntities.Where(u => u.Entity.Name.Equals(entityName) && u.RecordID == relatedRecordId && u.ProgramDataItem.Name.Equals(programDataItemName)).FirstOrDefault();
            }
        }

        public List<RoadsideServices_Result> GetRoadsideServices(int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetRoadsideServices(programID).ToList<RoadsideServices_Result>();
            }
        }

        public List<ProgramDispatchNumber_Result> GetProgramDispatchNumbers(int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramDispatchNumber(programID).ToList<ProgramDispatchNumber_Result>();
            }
        }
    }
}
