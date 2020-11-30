using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class PhoneRepository
    {
        /// <summary>
        /// Saves the specified phone detail
        /// </summary>
        /// <param name="phone">The phone.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="delete">if set to <c>true</c> [delete].</param>
        /// <exception cref="DMSException">Invalid entity name  + entityName</exception>
        public void Save(PhoneEntity phone, string entityName, bool delete = false)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entity name " + entityName);
                }
                phone.EntityID = entity.ID;
                PhoneEntity existingDetails = dbContext.PhoneEntities.Where(u => u.ID == phone.ID).FirstOrDefault();
                if (existingDetails == null)
                {
                    phone.ModifyDate = null;
                    phone.ModifyBy = null;
                    dbContext.PhoneEntities.Add(phone);
                }
                else
                {
                    if (!delete)
                    {
                        existingDetails.PhoneNumber = phone.PhoneNumber;
                        existingDetails.PhoneTypeID = phone.PhoneTypeID;

                        existingDetails.ModifyDate = phone.ModifyDate;
                        existingDetails.ModifyBy = phone.ModifyBy;
                        dbContext.Entry(existingDetails).State = EntityState.Modified;
                    }
                    else
                    {
                        dbContext.Entry(existingDetails).State = EntityState.Deleted;
                    }

                }

                dbContext.SaveChanges();
            }
        }
        /// <summary>
        /// Saves the specified phone.
        /// </summary>
        /// <param name="phone">The phone.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="type">The type.</param>
        /// <param name="recordID">The record ID.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="DMSException">Invalid entity name  + entityName</exception>
        public void Save(PhoneEntity phone, string entityName, string type, int recordID, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entity name " + entityName);
                }

                var types = dbContext.PhoneTypes.Where(x => x.Name == type).FirstOrDefault();
                if (types == null)
                {
                    throw new DMSException("Invalid Phome Type name " + type);
                }

                phone.EntityID = (entity != null) ? entity.ID : 5;
                phone.PhoneTypeID = (types != null) ? types.ID : 1;
                phone.RecordID = recordID;
                //PhoneEntity existingDetails = dbContext.PhoneEntities.Where(u => u.ID == phone.ID).FirstOrDefault();
                PhoneEntity existingDetails = dbContext.PhoneEntities.Where(u => (u.RecordID == recordID) & (u.EntityID == phone.EntityID) & (u.PhoneTypeID == phone.PhoneTypeID)).FirstOrDefault();
                if (existingDetails == null)
                {
                    phone.CreateBy = userName;
                    phone.CreateDate = DateTime.Now;
                    phone.ModifyDate = null;
                    phone.ModifyBy = null;
                    dbContext.PhoneEntities.Add(phone);
                }
                else
                {
                    existingDetails.PhoneNumber = phone.PhoneNumber;
                    existingDetails.ModifyDate = DateTime.Now;
                    existingDetails.ModifyBy = userName;
                    dbContext.Entry(existingDetails).State = EntityState.Modified;

                }

                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the phone details for a particular entity instance.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        public List<PhoneEntity> GetPhoneDetails(int recordID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.PhoneEntities.Where(x => x.RecordID == recordID).Include(x => x.PhoneType).ToList<PhoneEntity>();
                return result;
            }

        }

        /// <summary>
        /// Gets the specified record unique identifier.
        /// </summary>
        /// <param name="recordID">The record unique identifier.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Invalid entity name  + entityName</exception>
        public List<PhoneEntity> Get(int recordID, string entityName)
        {
            List<PhoneEntity> result = null;

            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entity name " + entityName);
                }

                result = dbContext.PhoneEntities.Include("PhoneType").Where(u => u.RecordID == recordID && u.EntityID == entity.ID).ToList<PhoneEntity>();
            }
            return result;
        }

        /// <summary>
        /// Gets the specified record ID.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="type">The type.</param>
        /// <returns></returns>
        public PhoneEntity Get(int recordID, string entityName, string type)
        {
            PhoneEntity model = null;

            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entity name " + entityName);
                }

                var types = dbContext.PhoneTypes.Where(x => x.Name == type).FirstOrDefault();
                if (types == null)
                {
                    throw new DMSException("Invalid Phome Type name " + type);
                }

                model = dbContext.PhoneEntities.Include("PhoneType").Where(u => u.RecordID == recordID && u.PhoneTypeID == types.ID && u.EntityID == entity.ID).FirstOrDefault();
            }
            return model;
        }
        /// <summary>
        /// Gets the name of the phone type by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public PhoneType GetPhoneTypeByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.PhoneTypes.Where(x => x.Name == name).FirstOrDefault();
                return result;
            }
        }


        /// <summary>
        /// Gets the generic phone number.
        /// </summary>
        /// <param name="recordId">The record id.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        public List<PhoneEntityExtended> GetGenericPhoneNumber(int recordId, string entityName, string[] excludedItems = null)
        {
            List<PhoneEntityExtended> result = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                result = (from phone in dbContext.PhoneEntities
                          join phoneType in dbContext.PhoneTypes on phone.PhoneTypeID equals phoneType.ID
                          join entity in dbContext.Entities on phone.EntityID equals entity.ID
                          where phone.RecordID == recordId
                          where entity.Name.Equals(entityName)
                          orderby phone.ModifyDate
                          select new PhoneEntityExtended()
                          {
                              PhoneID = phone.ID,
                              EntityID = phone.EntityID,
                              EntityName = entity.Name,
                              RecordID = phone.RecordID,
                              PhoneTypeID = phone.PhoneTypeID,
                              PhoneTypeName = phoneType.Name,
                              PhoneTypeDescription = phoneType.Description,
                              PhoneNumber = phone.PhoneNumber
                          }).ToList();

                if (excludedItems != null && excludedItems.Length > 0)
                {
                    result = (from l in result
                              where !excludedItems.Contains(l.PhoneTypeName)
                              select l).ToList();
                }
            }

            return result;
        }
        /// <summary>
        /// Gets the generic phone number by phone ID.
        /// </summary>
        /// <param name="phoneID">The phone ID.</param>
        /// <returns></returns>
        public PhoneEntityExtended GetGenericPhoneNumberByPhoneID(int phoneID)
        {
            PhoneEntityExtended result = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                result = (from phone in dbContext.PhoneEntities
                          join phoneType in dbContext.PhoneTypes on phone.PhoneTypeID equals phoneType.ID
                          join entity in dbContext.Entities on phone.EntityID equals entity.ID
                          where phone.ID == phoneID
                          select new PhoneEntityExtended()
                          {
                              PhoneID = phone.ID,
                              EntityID = phone.EntityID,
                              EntityName = entity.Name,
                              RecordID = phone.RecordID,
                              PhoneTypeID = phone.PhoneTypeID,
                              PhoneTypeName = phoneType.Name,
                              PhoneTypeDescription = phoneType.Description,
                              PhoneNumber = phone.PhoneNumber
                          }).FirstOrDefault();
            }
            return result;
        }

        /// <summary>
        /// Deletes the specified phone ID.
        /// </summary>
        /// <param name="phoneID">The phone ID.</param>
        public void Delete(int phoneID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                PhoneEntity existingDetails = dbContext.PhoneEntities.Where(u => u.ID == phoneID).FirstOrDefault();
                if (existingDetails == null)
                {
                    throw new DMSException("Unable to retrieve details for the given Phone ID");
                }
                dbContext.Entry(existingDetails).State = EntityState.Deleted;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the phone types.
        /// </summary>
        /// <param name="entityType">Type of the entity.</param>
        /// <returns></returns>
        public List<PhoneType> GetPhoneTypes(string entityType, string[] typesToExclude, string[] typesToMatch, int recordID, int phoneID)
        {
            List<PhoneEntityExtended> list = GetGenericPhoneNumber(recordID, entityType, typesToExclude);
            List<PhoneType> phoneTypes = ReferenceDataRepository.GetPhoneTypes(entityType, typesToExclude);
            PhoneEntityExtended currentModel = GetGenericPhoneNumberByPhoneID(phoneID);
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (list != null && list.Count > 0)
                {
                    foreach (string str in typesToMatch)
                    {
                        var isRecordFound = list.Where(u => u.PhoneTypeName.Equals(str)).FirstOrDefault();
                        if (isRecordFound != null)
                        {
                            PhoneType type = phoneTypes.Where(u => u.Name.Equals(str)).FirstOrDefault();
                            if (type != null)
                            {
                                phoneTypes.Remove(type);
                            }
                        }
                    }
                    if (currentModel != null && typesToMatch.Contains(currentModel.PhoneTypeName))
                    {
                        phoneTypes.Add(new PhoneType()
                        {
                            ID = currentModel.PhoneTypeID.GetValueOrDefault(),
                            Name = currentModel.PhoneTypeName
                        });
                    }

                }
            }
            return phoneTypes;
        }

        //Lakshmi - Hagerty Integration 
        /// <summary>
        /// Gets list of phone info records by membership number.
        /// </summary>
        /// <param name="MembershipNo">The membership number.</param>
        /// <param name="entityName">The entity name.</param>
        /// <param name="parentpgmID">The parent program ID.</param>
        /// <returns></returns>
        public List<PhoneEntity> GetPhoneInfoByMembershipNumber(string MembershipNo, string entityName, int parentpgmID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var phoneInfo = (from pe in dbContext.PhoneEntities
                                 join m in dbContext.Members on pe.RecordID equals m.ID
                                 join p in dbContext.Programs on m.ProgramID equals p.ID
                                 join ms in dbContext.Memberships on m.MembershipID equals ms.ID
                                 join entity in dbContext.Entities on pe.EntityID equals entity.ID
                                 where (entity.Name == entityName) & (p.ParentProgramID == parentpgmID) & (ms.MembershipNumber == MembershipNo)
                                 select pe);

                return phoneInfo.Include(x => x.PhoneType).ToList();

            }
        }

        //Lakshmi - Hagerty Integration 
        /// <summary>
        /// Gets phone type by phone type id.
        /// </summary>
        /// <param name="phonetypeID">The phone type id.</param>
        /// <returns></returns>
        public PhoneType GetPhoneTypeByID(int phonetypeID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.PhoneTypes.Where(x => x.ID == phonetypeID).FirstOrDefault();
                return result;
            }
        }

        public List<PhoneEntity> GetPhonesForEntity(string entityName, int? recordID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PhoneEntities.Include(p=>p.PhoneType).Where(a => a.Entity.Name.Equals(entityName) && a.RecordID == recordID).ToList();
            }
        }
    }
}
