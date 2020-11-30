using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.Data.Entity.Core.Objects;
using System.Runtime.Serialization;
using System.IO;
using System.Collections;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using log4net;
using System.Data.Entity;
using System.Data.Entity.Core.Objects.DataClasses;
using System.Data.Entity.Core.Metadata.Edm;
using System.Data.Entity.Core;

namespace Martex.DMS.DAL
{
    /// <summary>
    /// 
    /// </summary>
    public partial class DMSEntities
    {
        List<DBAudit> auditTrailList = new List<DBAudit>();
        public string UserName { get; set; }
        protected static readonly ILog logger = LogManager.GetLogger(typeof(DMSEntities));

        public enum AuditActions
        {
            I,
            U,
            D
        }

        /// <summary>
        /// Called when [context created].
        /// </summary>
        //partial void OnContextCreated()
        //{
        //    this.SavingChanges += new EventHandler(DMSEntities_SavingChanges);
        //}

        /// <summary>
        /// Handles the SavingChanges event of the DMSEntities control.
        /// </summary>
        /// <param name="sender">The source of the event.</param>
        /// <param name="e">The <see cref="EventArgs"/> instance containing the event data.</param>
        void DMSEntities_SavingChanges(object sender, EventArgs e)
        {
            // Console.WriteLine("Saving Changes..");

            try
            {
                IEnumerable<ObjectStateEntry> changes = this.ObjectStateManager.GetObjectStateEntries(EntityState.Added | EntityState.Deleted | EntityState.Modified);
                foreach (ObjectStateEntry stateEntryEntity in changes)
                {
                    if (!stateEntryEntity.IsRelationship &&
                            stateEntryEntity.Entity != null &&
                                !(stateEntryEntity.Entity is DBAudit) && IsAudited(stateEntryEntity.Entity))
                    {//is a normal entry, not a relationship

                        List<DBAudit> audit = this.AuditTrailFactory(stateEntryEntity, UserName);
                        auditTrailList.AddRange(audit);
                    }
                }

                if (auditTrailList.Count > 0)
                {
                    foreach (var audit in auditTrailList)
                    {//add all audits 
                        this.AddToDBAudits(audit);
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Warn("Error while Auditing", ex);
                
            }
        }
        /// <summary>
        /// Audits the trail factory.
        /// </summary>
        /// <param name="entry">The entry.</param>
        /// <param name="UserName">Name of the user.</param>
        /// <returns></returns>
        private List<DBAudit> AuditTrailFactory(ObjectStateEntry entry, string UserName)
        {
            List<AuditEntity> listOfEntities = GetChanges(entry);
            List<DBAudit> auditList = new List<DBAudit>();
            listOfEntities.ForEach(x =>
            {
                DBAudit audit = new DBAudit();
                audit.AuditId = Guid.NewGuid().ToString();
                audit.RevisionStamp = DateTime.Now;
                audit.TableName = x.Type;
                audit.UserName = UserName;
                audit.NewData = XMLSerializationHelper.XmlSerialize(x);
                audit.Actions = x.OperationType;
                auditList.Add(audit);
            });

            return auditList;
        }

        /// <summary>
        /// Gets the changes.
        /// </summary>
        /// <param name="entry">The entry.</param>
        /// <returns></returns>
        private List<AuditEntity> GetChanges(ObjectStateEntry entry)
        {
            Hashtable ownerEntities = new Hashtable();

            AuditEntity ownerEntity = null;
            IEnumerable<IRelatedEnd> relatedEnd = entry.RelationshipManager.GetAllRelatedEnds();
            AuditEntity currentEntity = new AuditEntity();
            currentEntity.Type = entry.EntitySet.Name;

            // Check if the entity being audited is a root level entity or a related entity.
            string ownerEntityName = null;
            if (EntityRelationship.RelatedEntityConfig.ContainsKey(currentEntity.Type))
            {
                ownerEntityName = (string)EntityRelationship.RelatedEntityConfig[currentEntity.Type];
            }

            if (!string.IsNullOrEmpty(ownerEntityName))
            {
                ownerEntity = new AuditEntity();

                // Traverse through the relationships for ToRole - property Id that leads to the owner entity.
                foreach (var item in relatedEnd)
                {
                    var a = item.RelationshipSet.ElementType as AssociationType;
                    if (a.IsForeignKey)
                    {
                        foreach (var rc in a.ReferentialConstraints)
                        {
                            if (rc.FromRole.Name == ownerEntityName)
                            {
                                string fkPropName = rc.ToProperties[0].Name;
                                object fkPropValue = null;
                                switch (entry.State)
                                {
                                    case EntityState.Added:
                                        fkPropValue = entry.CurrentValues[fkPropName];
                                        break;
                                    default:
                                        fkPropValue = entry.OriginalValues[fkPropName];
                                        break;
                                }

                                Object o = null;
                                this.TryGetObjectByKey(new EntityKey("DMSEntities." + ownerEntityName + "s", "Id", fkPropValue), out o);
                                ownerEntity.Type = ownerEntityName;
                                ownerEntity.OperationType = EntityState.Modified.ToString();
                                ownerEntity.Id = fkPropValue.ToString();
                                ownerEntity.Name = o.GetType().GetProperty("Name").GetValue(o, null).ToString();

                                break;
                            }
                        }
                    }
                }

                // Track the number of owner entities created.
                ownerEntities[ownerEntityName + ownerEntity.Id] = ownerEntity;

            }
            currentEntity.OperationType = entry.State.ToString();
            // ID would be null in the case of add
            if (entry.EntityKey.EntityKeyValues != null && entry.EntityKey.EntityKeyValues.Length > 0)
            {
                currentEntity.Id = entry.EntityKey.EntityKeyValues[0].Value.ToString();
            }

            List<EntityProperty> propChanges = new List<EntityProperty>();

            if (entry.Entity is EntityObject)
            {
                switch (entry.State)
                {
                    case EntityState.Modified:
                        currentEntity.Name = entry.CurrentValues["ID"].ToString();
                        foreach (string propName in entry.GetModifiedProperties())
                        {
                            EntityProperty p = new EntityProperty();
                            p.Name = propName;
                            p.OldValue = entry.OriginalValues[propName].ToString();
                            p.NewValue = entry.CurrentValues[propName].ToString();
                            // Check to see if the propName is a reference to other entities. If yes, then get the name from the reference entity.

                            FillPropertyChanges(entry, ownerEntities, relatedEnd, currentEntity, propName, p);
                            propChanges.Add(p);
                        }

                        break;
                    case EntityState.Added:
                        currentEntity.Name = entry.CurrentValues["ID"].ToString();
                        foreach (var item in entry.CurrentValues.DataRecordInfo.FieldMetadata)
                        {
                            EntityProperty p = new EntityProperty();
                            string propName = item.FieldType.Name;
                            p.Name = propName;
                            p.NewValue = entry.CurrentValues[propName].ToString();
                            // Check to see if the propName is a reference to other entities. If yes, then get the name from the reference entity.

                            #region Commented

                            /*bool stop = false;
                            foreach (var i in relatedEnd)
                            {
                                var a = i.RelationshipSet.ElementType as AssociationType;
                                if (a.IsForeignKey)
                                {
                                    foreach (var rc in a.ReferentialConstraints)
                                    {
                                        if (rc.ToProperties.Contains(propName))
                                        {
                                            string referenceEntity = rc.FromRole.Name;
                                            Object o = null;
                                            //this.TryGetObjectByKey(new EntityKey("POCEntities." + referenceEntity + "s", "Id", entry.OriginalValues[propName]), out o);
                                            //p.OldValue = o.GetType().GetProperty("Name").GetValue(o, null).ToString();

                                            this.TryGetObjectByKey(new EntityKey("POCEntities." + referenceEntity + "s", "Id", entry.CurrentValues[propName]), out o);
                                            p.NewValue = o.GetType().GetProperty("Name").GetValue(o, null).ToString();

                                            Entity tempOldOwnerEntity = null;
                                            if (!ownerEntities.ContainsKey(referenceEntity + entry.CurrentValues[propName]))
                                            {
                                                tempOldOwnerEntity = new Entity();
                                                ownerEntities[referenceEntity + entry.CurrentValues[propName]] = tempOldOwnerEntity;
                                            }
                                            else
                                            {
                                                tempOldOwnerEntity = ownerEntities[referenceEntity + entry.CurrentValues[propName]] as Entity;
                                            }
                                            tempOldOwnerEntity.Id = entry.CurrentValues[propName].ToString();
                                            tempOldOwnerEntity.Name = p.NewValue;
                                            tempOldOwnerEntity.Type = referenceEntity;
                                            tempOldOwnerEntity.OperationType = EntityState.Modified.ToString();

                                            tempOldOwnerEntity.Entity1 = new Entity[] { currentEntity };

                                            stop = true;
                                            break;
                                        }
                                    }
                                }
                                if (stop)
                                {
                                    break;
                                }
                            }
                            */
                            #endregion
                            FillPropertyChanges(entry, ownerEntities, relatedEnd, currentEntity, propName, p);
                            propChanges.Add(p);
                        }
                        break;
                    case EntityState.Deleted:
                        currentEntity.Name = entry.OriginalValues["ID"].ToString();
                        for (int i = 0, l = entry.OriginalValues.FieldCount; i < l; i++)
                        {
                            EntityProperty p = new EntityProperty();
                            string propName = entry.OriginalValues.GetName(i);
                            p.Name = propName;
                            p.OldValue = entry.OriginalValues[i].ToString();

                            // Check to see if the propName is a reference to other entities. If yes, then get the name from the reference entity.

                            #region Commented
                            /*
                            bool stop = false;
                            foreach (var item in relatedEnd)
                            {
                                var a = item.RelationshipSet.ElementType as AssociationType;
                                if (a.IsForeignKey)
                                {
                                    foreach (var rc in a.ReferentialConstraints)
                                    {
                                        if (rc.ToProperties.Contains(propName))
                                        {
                                            string referenceEntity = rc.FromRole.Name;
                                            Object o = null;
                                            this.TryGetObjectByKey(new EntityKey("POCEntities." + referenceEntity + "s", "Id", entry.OriginalValues[propName]), out o);
                                            p.OldValue = o.GetType().GetProperty("Name").GetValue(o, null).ToString();

                                            //this.TryGetObjectByKey(new EntityKey("POCEntities." + referenceEntity + "s", "Id", entry.CurrentValues[propName]), out o);
                                            //p.NewValue = o.GetType().GetProperty("Name").GetValue(o, null).ToString();

                                            Entity tempOldOwnerEntity = null;
                                            if (!ownerEntities.ContainsKey(referenceEntity + entry.OriginalValues[propName]))
                                            {
                                                tempOldOwnerEntity = new Entity();
                                                ownerEntities[referenceEntity + entry.OriginalValues[propName]] = tempOldOwnerEntity;
                                            }
                                            else
                                            {
                                                tempOldOwnerEntity = ownerEntities[referenceEntity + entry.OriginalValues[propName]] as Entity;
                                            }
                                            tempOldOwnerEntity.Id = entry.OriginalValues[propName].ToString();
                                            tempOldOwnerEntity.Name = p.OldValue;
                                            tempOldOwnerEntity.Type = referenceEntity;
                                            tempOldOwnerEntity.OperationType = EntityState.Modified.ToString();

                                            tempOldOwnerEntity.Entity1 = new Entity[] { currentEntity };

                                            stop = true;
                                            break;
                                        }
                                    }
                                }
                                if (stop)
                                {
                                    break;
                                }
                            }
                            */
                            #endregion
                            FillPropertyChanges(entry, ownerEntities, relatedEnd, currentEntity, propName, p);
                            propChanges.Add(p);
                        }
                        break;
                    default:
                        break;
                }


            }
            currentEntity.Changeset = propChanges.ToArray();

            if (ownerEntities.Count > 0)
            {
                List<AuditEntity> ownerEntityList = new List<AuditEntity>();
                ownerEntityList.Add(currentEntity);
                foreach (var item in ownerEntities.Values)
                {
                    ownerEntityList.Add(item as AuditEntity);
                }

                return ownerEntityList;
            }

            return new List<AuditEntity>() { currentEntity };
        }

        /// <summary>
        /// Fills the property changes.
        /// </summary>
        /// <param name="entry">The entry.</param>
        /// <param name="ownerEntities">The owner entities.</param>
        /// <param name="relatedEnd">The related end.</param>
        /// <param name="currentEntity">The current entity.</param>
        /// <param name="propName">Name of the prop.</param>
        /// <param name="p">The p.</param>
        private void FillPropertyChanges(ObjectStateEntry entry, Hashtable ownerEntities, IEnumerable<IRelatedEnd> relatedEnd, AuditEntity currentEntity, string propName, EntityProperty p)
        {
            bool stop = false;
            foreach (var item in relatedEnd)
            {
                var a = item.RelationshipSet.ElementType as AssociationType;
                if (a.IsForeignKey)
                {
                    foreach (var rc in a.ReferentialConstraints)
                    {
                        if (rc.ToProperties.Contains(propName))
                        {
                            string referenceEntity = rc.FromRole.Name;
                            string mainAttribute = "Name";
                            Object o = null;
                            if (entry.State == EntityState.Modified || entry.State == EntityState.Deleted)
                            {
                                if (entry.OriginalValues[propName] != DBNull.Value)
                                {
                                    if (!referenceEntity.EndsWith("y"))
                                    {

                                        this.TryGetObjectByKey(new EntityKey("DMSEntities." + referenceEntity + "s", "ID", entry.OriginalValues[propName]), out o);

                                    }
                                    else
                                    {

                                        this.TryGetObjectByKey(new EntityKey("DMSEntities." + referenceEntity.Replace("y", "ies"), "ID", entry.CurrentValues[propName]), out o);

                                    }
                                    if (EntityRelationship.EntityMainAttribute.Contains(referenceEntity))
                                    {
                                        mainAttribute = (string)EntityRelationship.EntityMainAttribute[referenceEntity];
                                    }
                                    if (o.GetType().GetProperty(mainAttribute) != null)
                                    {
                                        p.OldValue = o.GetType().GetProperty(mainAttribute).GetValue(o, null).ToString();
                                    }
                                  //  p.OldValue = o.GetType().GetProperty("Name").GetValue(o, null).ToString();

                                    // Updated the current entity operation type as Deleted.
                                    AuditEntity tempOldOwnerEntity = null;
                                    if (!ownerEntities.ContainsKey(referenceEntity + entry.OriginalValues[propName]))
                                    {
                                        tempOldOwnerEntity = new AuditEntity();
                                        ownerEntities[referenceEntity + entry.OriginalValues[propName]] = tempOldOwnerEntity;
                                    }
                                    else
                                    {
                                        tempOldOwnerEntity = ownerEntities[referenceEntity + entry.OriginalValues[propName]] as AuditEntity;
                                    }
                                    tempOldOwnerEntity.Id = entry.OriginalValues[propName].ToString();
                                    tempOldOwnerEntity.Name = p.OldValue;
                                    tempOldOwnerEntity.Type = referenceEntity;
                                    tempOldOwnerEntity.OperationType = EntityState.Modified.ToString();

                                    tempOldOwnerEntity.Entity1 = new AuditEntity[] { currentEntity };
                                }

                            }

                            if (entry.State == EntityState.Modified || entry.State == EntityState.Added)
                            {
                                if (entry.CurrentValues[propName] != DBNull.Value)
                                {
                                    if (!referenceEntity.EndsWith("y"))
                                    {
                                        this.TryGetObjectByKey(new EntityKey("DMSEntities." + referenceEntity + "s", "ID", entry.CurrentValues[propName]), out o);
                                    }
                                    else
                                    {
                                        this.TryGetObjectByKey(new EntityKey("DMSEntities." + referenceEntity.Replace("y", "ies"), "ID", entry.CurrentValues[propName]), out o);
                                    }
                                   if (EntityRelationship.EntityMainAttribute.Contains(referenceEntity))
                                   {
                                       mainAttribute = (string)EntityRelationship.EntityMainAttribute[referenceEntity];
                                   }
                                   if (o.GetType().GetProperty(mainAttribute) != null)
                                   {
                                       p.NewValue = o.GetType().GetProperty(mainAttribute).GetValue(o, null).ToString();
                                   }
                                   
                                    AuditEntity tempNewOwnerEntity = null;
                                    if (!ownerEntities.ContainsKey(referenceEntity + entry.CurrentValues[propName]))
                                    {
                                        tempNewOwnerEntity = new AuditEntity();
                                        ownerEntities[referenceEntity + entry.CurrentValues[propName]] = tempNewOwnerEntity;
                                    }
                                    else
                                    {
                                        tempNewOwnerEntity = ownerEntities[referenceEntity + entry.CurrentValues[propName]] as AuditEntity;
                                    }
                                    tempNewOwnerEntity.Id = entry.CurrentValues[propName].ToString();
                                    tempNewOwnerEntity.Name = p.NewValue;
                                    tempNewOwnerEntity.Type = referenceEntity;
                                    tempNewOwnerEntity.OperationType = EntityState.Modified.ToString();


                                    tempNewOwnerEntity.Entity1 = new AuditEntity[] { currentEntity };
                                }
                            }
                            stop = true;
                            break;
                        }
                    }
                }
                if (stop)
                {
                    break;
                }
            }
        }

        /// <summary>
        /// Determines whether the specified entity name is audited.
        /// </summary>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns>
        ///   <c>true</c> if the specified entity name is audited; otherwise, <c>false</c>.
        /// </returns>
        private bool IsAudited(object entityName)
        {
            var db = new DMSEntities();
            string name = entityName.GetType().Name;
            Entity en = db.Entities.Where(e => e.Name == name).FirstOrDefault();

            if (en == null)
            {
                return false;
            }
            return en.IsAudited.GetValueOrDefault();
        }

        /// <summary>
        /// Clones the entity.
        /// </summary>
        /// <param name="obj">The obj.</param>
        /// <returns></returns>
        public EntityObject CloneEntity(EntityObject obj)
        {
            DataContractSerializer dcSer = new DataContractSerializer(obj.GetType());
            MemoryStream memoryStream = new MemoryStream();

            dcSer.WriteObject(memoryStream, obj);
            memoryStream.Position = 0;

            EntityObject newObject = (EntityObject)dcSer.ReadObject(memoryStream);
            return newObject;
        }
    }
}
