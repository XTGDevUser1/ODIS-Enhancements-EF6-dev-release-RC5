using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;
using System.Data.Entity;
using log4net;
using Newtonsoft.Json;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// Address Repository
    /// </summary>
    public class AddressRepository
    {
        #region Protected Members
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(AddressRepository));

        #endregion

        /// <summary>
        /// Deletes the specified address ID.
        /// </summary>
        /// <param name="addressID">The address ID.</param>
        /// <exception cref="DMSException">Unable to retrieve address record</exception>
        public void Delete(int addressID)
        {
            logger.InfoFormat("AddressRepository - Delete(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                AddressID = addressID
            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                AddressEntity existingDetails = dbContext.AddressEntities.Where(u => u.ID == addressID).FirstOrDefault();

                if (existingDetails == null)
                {
                    throw new DMSException("Unable to retrieve address record");
                }
                dbContext.Entry(existingDetails).State = EntityState.Deleted;
                dbContext.SaveChanges();

            }
        }

        /// <summary>
        /// Saves the specified address.
        /// </summary>
        /// <param name="address">The address.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="delete">if set to <c>true</c> [delete].</param>
        /// <exception cref="DMSException">Invalid entity name  + entityName</exception>
        public void Save(AddressEntity address, string entityName, bool delete = false)
        {
            logger.InfoFormat("AddressRepository - Save(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                AddressTypeID = address.AddressTypeID,
                Line1 = address.Line1,
                Line2 = address.Line2,
                Line3 = address.Line3,
                City = address.City,
                StateProvinceID = address.StateProvinceID,
                StateProvince = address.StateProvince,
                PostalCode = address.PostalCode,
                CountryID = address.CountryID,
                CountryCode = address.CountryCode,
                ModifyDate = address.ModifyDate,
                ModifyBy = address.ModifyBy,
                CreateDate = address.CreateDate,
                CreateBy = address.CreateBy,
                entityName = entityName,
                delete = delete
            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entity name " + entityName);
                }

                // Fill the Lookup Details here
                if (address.StateProvinceID.HasValue)
                {
                    address.StateProvince = dbContext.StateProvinces.Where(u => u.ID == address.StateProvinceID).FirstOrDefault().Abbreviation;
                }
                if (address.CountryID.HasValue)
                {
                    address.CountryCode = dbContext.Countries.Where(u => u.ID == address.CountryID).FirstOrDefault().ISOCode;
                }

                AddressEntity existingDetails = dbContext.AddressEntities.Where(u => u.ID == address.ID).FirstOrDefault();

                if (existingDetails == null)
                {
                    address.EntityID = entity.ID;
                    address.ModifyBy = null;
                    address.ModifyDate = null;
                    dbContext.AddressEntities.Add(address);
                }
                else
                {
                    if (!delete)
                    {
                        existingDetails.AddressTypeID = address.AddressTypeID;
                        existingDetails.Line1 = address.Line1;
                        existingDetails.Line2 = address.Line2;
                        existingDetails.Line3 = address.Line3;
                        existingDetails.City = address.City;
                        existingDetails.StateProvinceID = address.StateProvinceID;
                        existingDetails.StateProvince = address.StateProvince;
                        existingDetails.PostalCode = address.PostalCode;
                        existingDetails.CountryID = address.CountryID;
                        existingDetails.CountryCode = address.CountryCode;
                        existingDetails.EntityID = entity.ID;
                        existingDetails.ModifyDate = address.ModifyDate;
                        existingDetails.ModifyBy = address.ModifyBy;
                        dbContext.Entry(existingDetails).State = EntityState.Modified;
                    }
                    else
                    {
                        logger.InfoFormat("AddressRepository - Save(), Deleting Address :  {0}", JsonConvert.SerializeObject(new
                        {
                            AddressID = existingDetails.ID
                        }));
                        dbContext.Entry(existingDetails).State = EntityState.Deleted;
                    }


                }

                dbContext.SaveChanges();

                if (existingDetails == null)
                {
                    logger.InfoFormat("AddressRepository - Save(), Address Added :  {0}", JsonConvert.SerializeObject(new
                    {
                        Address = address.ID
                    }));
                }
                else
                {
                    if (!delete)
                    {
                        logger.InfoFormat("AddressRepository - Save(), Address Updated :  {0}", JsonConvert.SerializeObject(new
                        {
                            Address = existingDetails.ID
                        }));
                    }
                }
            }

        }
        /// <summary>
        /// Saves the specified address.
        /// </summary>
        /// <param name="address">The address.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="addressType">Type of the address.</param>
        /// <param name="recordID">The record ID.</param>
        /// <exception cref="DMSException">Invalid entity name  + entityName</exception>
        public void Save(AddressEntity address, string entityName, string type, int recordID, string userName)
        {
            logger.InfoFormat("AddressRepository - Save(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                AddressEntity = address,
                entityName = entityName,
                type = type,
                recordID = recordID,
                userName = userName
            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entity name " + entityName);
                }

                var addressType = dbContext.AddressTypes.Where(x => x.Name == type).FirstOrDefault();
                if (addressType == null)
                {
                    throw new DMSException("Invalid Address Type " + type);
                }

                // Fill the Lookup Details here
                if (address.StateProvinceID.HasValue)
                {
                    address.StateProvince = dbContext.StateProvinces.Where(u => u.ID == address.StateProvinceID).FirstOrDefault().Abbreviation;
                }
                if (address.CountryID.HasValue)
                {
                    address.CountryCode = dbContext.Countries.Where(u => u.ID == address.CountryID).FirstOrDefault().ISOCode;
                }

                AddressEntity existingDetails = dbContext.AddressEntities.Where(u => u.ID == address.ID).FirstOrDefault();
                if (existingDetails == null)
                {
                    address.RecordID = recordID;
                    address.AddressTypeID = addressType.ID;
                    address.EntityID = entity.ID;
                    address.ModifyBy = null;
                    address.ModifyDate = null;
                    address.CreateDate = DateTime.Now;
                    address.CreateBy = userName;
                    dbContext.AddressEntities.Add(address);

                }
                else
                {
                    existingDetails.RecordID = recordID;
                    existingDetails.EntityID = entity.ID;
                    existingDetails.AddressTypeID = addressType.ID;

                    existingDetails.Line1 = address.Line1;
                    existingDetails.Line2 = address.Line2;
                    existingDetails.Line3 = address.Line3;
                    existingDetails.City = address.City;
                    existingDetails.StateProvinceID = address.StateProvinceID;
                    existingDetails.StateProvince = address.StateProvince;
                    existingDetails.PostalCode = address.PostalCode;
                    existingDetails.CountryID = address.CountryID;
                    existingDetails.CountryCode = address.CountryCode;
                    existingDetails.ModifyDate = DateTime.Now;
                    existingDetails.ModifyBy = userName;
                    dbContext.Entry(existingDetails).State = EntityState.Modified;
                }

                dbContext.SaveChanges();
                if (existingDetails == null)
                {
                    logger.InfoFormat("AddressRepository - Save(), Address Added :  {0}", JsonConvert.SerializeObject(new
                    {
                        AddressID = address.ID
                    }));
                }
                else
                {
                    logger.InfoFormat("AddressRepository - Save(), Address Updated :  {0}", JsonConvert.SerializeObject(new
                    {
                        AddressID = existingDetails.ID
                    }));
                }
            }

        }

        /// <summary>
        /// Gets the addresses for a particular entity instance.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        public List<AddressEntity> GetAddresses(int recordID, string entityName, string type = null)
        {
            logger.InfoFormat("AddressRepository - GetAddresses(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                recordID = recordID,
                entityName = entityName,
                type = type

            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entity name " + entityName);
                }

                // Modified for getting  type of address
                // Jeevan
                // Date : 07-Nov-2012
                if (!string.IsNullOrEmpty(type))
                {
                    var addresstype = dbContext.AddressTypes.Where(x => x.Name == type).FirstOrDefault();
                    if (addresstype == null)
                    {
                        throw new DMSException("Invalid Address type " + addresstype);

                    }

                    var result = dbContext.AddressEntities.Include("AddressType").Include("StateProvince1").Where(x => x.RecordID == recordID && x.EntityID == entity.ID && x.AddressTypeID == addresstype.ID).ToList<AddressEntity>();
                    return result;
                }
                else
                {
                    var result = dbContext.AddressEntities.Include("AddressType").Include("StateProvince1").Where(x => x.RecordID == recordID && x.EntityID == entity.ID).ToList<AddressEntity>();
                    return result;
                }
            }
        }
        /// <summary>
        /// Gets the name of the address type by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public AddressType GetAddressTypeByName(string name)
        {
            logger.InfoFormat("AddressRepository - GetAddressTypeByName(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                name = name

            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.AddressTypes.Where(x => x.Name == name).FirstOrDefault();
                return result;
            }
        }


        /// <summary>
        /// Gets the generic address by.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="ExcludedTypes">The excluded types.</param>
        /// <returns></returns>
        public List<AddressExtendedEntity> GetGenericAddressBy(int? recordID, string entityName, string[] ExcludedTypes)
        {
            logger.InfoFormat("AddressRepository - GetGenericAddressBy(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                recordID = recordID,
                entityName = entityName,
                ExcludedTypes = ExcludedTypes

            }));
            List<AddressExtendedEntity> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = (from address in dbContext.AddressEntities
                        join addressType in dbContext.AddressTypes on address.AddressTypeID equals addressType.ID
                        join entity in dbContext.Entities on address.EntityID equals entity.ID
                        where entity.Name.Equals(entityName)
                        where address.RecordID == recordID
                        orderby addressType.Sequence
                        select new AddressExtendedEntity()
                        {
                            AddressID = address.ID,
                            EntityID = entity.ID,
                            EntityName = entity.Name,
                            RecordID = address.RecordID,
                            AddressTypeID = addressType.ID,
                            AddressTypeName = addressType.Name,
                            AddressLine1 = address.Line1,
                            AddressLine2 = address.Line2,
                            AddressLine3 = address.Line3,
                            City = address.City,
                            StateProvince = address.StateProvince,
                            StateProvinceID = address.StateProvinceID,
                            CountryID = address.CountryID,
                            CountryCode = address.CountryCode,
                            ZipCode = address.PostalCode

                        }).ToList();
                if (ExcludedTypes != null && ExcludedTypes.Length > 0)
                {
                    list = (from l in list
                            where !ExcludedTypes.Contains(l.AddressTypeName)
                            select l).ToList();
                }

            }
            return list;
        }

        /// <summary>
        /// Gets the address types.
        /// </summary>
        /// <param name="typesToMatch">The types to match.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="recordID">The record identifier.</param>
        /// <param name="currentRecord">The current record.</param>
        /// <param name="ExcludedTypes">The excluded types.</param>
        /// <returns></returns>
        public List<AddressType> GetAddressTypes(string[] typesToMatch, string entityName, int recordID, int currentRecord, string[] ExcludedTypes)
        {
            logger.InfoFormat("AddressRepository - GetAddressTypes(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                typesToMatch = typesToMatch,
                recordID = recordID,
                entityName = entityName,
                currentRecord = currentRecord,
                ExcludedTypes = ExcludedTypes

            }));
            List<AddressExtendedEntity> list = GetGenericAddressBy(recordID, entityName, ExcludedTypes);
            List<AddressType> addressTypes = ReferenceDataRepository.GetAddressTypes(entityName, ExcludedTypes);
            AddressExtendedEntity currentModel = GetGenericAddressBy(currentRecord);
            if (list != null)
            {
                if (typesToMatch != null && typesToMatch.Length > 0)
                {
                    foreach (string str in typesToMatch)
                    {
                        var isRecordFound = list.Where(u => u.AddressTypeName.Equals(str)).FirstOrDefault();
                        if (isRecordFound != null)
                        {
                            AddressType type = addressTypes.Where(u => u.Description.Equals(str)).FirstOrDefault();
                            if (type != null)
                            {
                                addressTypes.Remove(type);
                            }
                        }
                    }
                    if (currentModel != null && typesToMatch.Contains(currentModel.AddressTypeName))
                    {
                        addressTypes.Add(new AddressType()
                        {
                            ID = currentModel.AddressTypeID.GetValueOrDefault(),
                            Description = currentModel.AddressTypeName
                        });
                    }
                }
            }
            return addressTypes;
        }

        /// <summary>
        /// Gets the generic address by.
        /// </summary>
        /// <param name="addressID">The address ID.</param>
        /// <returns></returns>
        public AddressExtendedEntity GetGenericAddressBy(int addressID)
        {
            logger.InfoFormat("AddressRepository - GetGenericAddressBy(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                addressID = addressID

            }));
            AddressExtendedEntity model = new AddressExtendedEntity();
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = (from address in dbContext.AddressEntities
                         join addressType in dbContext.AddressTypes on address.AddressTypeID equals addressType.ID
                         join entity in dbContext.Entities on address.EntityID equals entity.ID
                         where address.ID == addressID
                         select new AddressExtendedEntity()
                         {
                             AddressID = address.ID,
                             EntityID = entity.ID,
                             EntityName = entity.Name,
                             RecordID = address.RecordID,
                             AddressTypeID = addressType.ID,
                             AddressTypeName = addressType.Name,
                             AddressLine1 = address.Line1,
                             AddressLine2 = address.Line2,
                             AddressLine3 = address.Line3,
                             City = address.City,
                             StateProvince = address.StateProvince,
                             StateProvinceID = address.StateProvinceID,
                             CountryID = address.CountryID,
                             CountryCode = address.CountryCode,
                             ZipCode = address.PostalCode

                         }).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Updates the type of the geography.
        /// </summary>
        /// <param name="entityID">The entity unique identifier.</param>
        /// <param name="entityName">Name of the entity.</param>
        public void UpdateGeographyType(int entityID, string entityName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.UpdateGeographyTypes(entityID, entityName);
            }
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Get Member AddressInfo by Membership Number.
        /// </summary>
        /// <param name="membershipNo">Membership Number</param>
        /// <param name="parentpgmID">The parent program identifier.</param>
        /// <returns></returns>
        public List<AddressEntity> GetMemberAddressInfoByMembershipNumber(string membershipNo, int parentpgmID)
        {
            List<AddressEntity> membersAddress = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<AddressEntity> addressList1 = (from ae in dbContext.AddressEntities.Include(a => a.AddressType)
                                                    join m in dbContext.Members on ae.RecordID equals m.ID
                                                    join p in dbContext.Programs on m.ProgramID equals p.ID
                                                    join ms in dbContext.Memberships on m.MembershipID equals ms.ID
                                                    join entity in dbContext.Entities on ae.EntityID equals entity.ID
                                                    where (entity.Name.Trim().ToUpper() == "MEMBER") & (p.ParentProgramID == parentpgmID) & (ms.MembershipNumber == membershipNo)

                                                    select ae).ToList();



                List<AddressEntity> addressList2 = (from ae in dbContext.AddressEntities.Include(a => a.AddressType)
                                                    join ms in dbContext.Memberships on ae.RecordID equals ms.ID
                                                    join m in dbContext.Members on ms.ID equals m.MembershipID
                                                    join p in dbContext.Programs on m.ProgramID equals p.ID
                                                    join entity in dbContext.Entities on ae.EntityID equals entity.ID
                                                    where (entity.Name.Trim().ToUpper() == "MEMBERSHIP") & (p.ParentProgramID == parentpgmID) & (ms.MembershipNumber == membershipNo)
                                                    select ae).ToList();


                membersAddress = addressList1.Union(addressList2).ToList();
                return membersAddress;

            }

        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Get Membership AddressInfo by Membership Number.
        /// </summary>
        /// <param name="membershipNo">Membership Number</param>
        /// <param name="entityName">Entity Name</param>
        /// <returns></returns>
        public List<AddressEntity> GetMembershipAddressInfoByMembershipNumber(string membershipNo, string entityName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var address = (from ae in dbContext.AddressEntities.Include(a => a.AddressType)
                               join ms in dbContext.Memberships on ae.RecordID equals ms.ID
                               join m in dbContext.Members on ms.ID equals m.MembershipID
                               join entity in dbContext.Entities on ae.EntityID equals entity.ID
                               where entity.Name.Equals(entityName)
                               where ms.MembershipNumber.Equals(membershipNo)
                               select ae);

                return address.ToList();

            }
        }

        // Lakshmi - Hagerty Integration
        /// <summary>
        /// Gets the state abbreviation.
        /// </summary>
        /// <param name="stateId">The state identifier.</param>
        /// <returns></returns>
        public string GetStateAbbreviation(int? stateId)
        {
            logger.InfoFormat("AddressRepository - GetStateAbbreviation(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                stateId = stateId

            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                string abbreviation = (dbContext.StateProvinces.Where(x => x.ID == stateId).Select(x => x.Abbreviation).FirstOrDefault());
                if (!string.IsNullOrEmpty(abbreviation))
                {
                    logger.InfoFormat("AddressRepository - GetStateAbbreviation(), Returns:  {0}", JsonConvert.SerializeObject(new
                    {
                        abbreviation = abbreviation

                    }));
                    return abbreviation;
                }
            }
            return null;
        }

        // Lakshmi - Hagerty Integration
        /// <summary>
        /// Saves the hagerty member address.
        /// </summary>
        /// <param name="address">The address.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="type">The type.</param>
        /// <param name="recordID">The record identifier.</param>
        /// <param name="userName">Name of the user.</param>
        public void SaveHagertyMemberAddress(AddressEntity address, string entityName, string type, int recordID, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var entity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();

                var addressType = dbContext.AddressTypes.Where(x => x.Name == type).FirstOrDefault();

                // Fill the Lookup Details here
                if (address.StateProvinceID.HasValue)
                {
                    address.StateProvince = dbContext.StateProvinces.Where(u => u.ID == address.StateProvinceID).FirstOrDefault().Abbreviation;
                }
                if (address.CountryID.HasValue)
                {
                    address.CountryCode = dbContext.Countries.Where(u => u.ID == address.CountryID).FirstOrDefault().ISOCode;
                }
                AddressEntity existingDetails = dbContext.AddressEntities.Where(u => (u.RecordID == address.RecordID) & (u.EntityID == address.EntityID)).FirstOrDefault();

                if (existingDetails == null)
                {
                    address.RecordID = recordID;
                    address.AddressTypeID = (addressType != null) ? addressType.ID : 1;
                    address.EntityID = (entity != null) ? entity.ID : 5;
                    address.ModifyBy = null;
                    address.ModifyDate = null;
                    address.CreateDate = DateTime.Now;
                    address.CreateBy = userName;
                    dbContext.AddressEntities.Add(address);
                }
                else
                {
                    existingDetails.RecordID = recordID;
                    existingDetails.EntityID = entity.ID;
                    existingDetails.AddressTypeID = addressType.ID;

                    existingDetails.Line1 = address.Line1;
                    existingDetails.Line2 = address.Line2;
                    existingDetails.Line3 = address.Line3;
                    existingDetails.City = address.City;
                    //Lakshmi -Added this condition for project 13713 - State& Zip will be updated only when Address object have value.
                    if ((address.StateProvinceID.HasValue) & (!string.IsNullOrEmpty(address.StateProvince)) & (!string.IsNullOrEmpty(address.PostalCode)))
                    {
                        existingDetails.StateProvinceID = address.StateProvinceID;
                        existingDetails.StateProvince = address.StateProvince;
                        existingDetails.PostalCode = address.PostalCode;
                    }
                    //end

                    existingDetails.CountryID = address.CountryID;
                    existingDetails.CountryCode = address.CountryCode;
                    existingDetails.ModifyDate = DateTime.Now;
                    existingDetails.ModifyBy = userName;
                    dbContext.Entry(existingDetails).State = EntityState.Modified;
                }

                dbContext.SaveChanges();
            }

        }

        public AddressEntity GetAddressesForEntity(string entityName, int? memberID, string addressTypeName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.AddressEntities.Where(a => a.AddressType.Name.Equals(addressTypeName) && a.Entity.Name.Equals(entityName) && a.RecordID == memberID).FirstOrDefault();
            }
        }
    }
}
