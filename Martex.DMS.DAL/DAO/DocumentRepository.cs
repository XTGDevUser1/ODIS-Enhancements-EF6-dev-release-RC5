using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAO;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public class DocumentRepository
    {
        /// <summary>
        /// Gets the documents list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="recordId">The record identifier.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="sourceSystemName">Name of the source system.</param>
        /// <returns></returns>
        public List<DocumentsList_Result> GetDocumentsList(PageCriteria pc, int recordId, string entityName, string sourceSystemName)
        {
            using (var dbContext = new DMSEntities())
            {
                if (!string.IsNullOrEmpty(sourceSystemName))
                {
                    return dbContext.GetDocumentsList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, entityName, recordId, sourceSystemName).ToList();
                }
                else
                {
                    return dbContext.GetDocumentsList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, entityName, recordId, null).ToList();
                }
            }
        }


        /// <summary>
        /// Gets the specified identifier.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <returns></returns>
        public Document Get(int id)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.Documents.FirstOrDefault(x => x.ID == id);
            }
        }
        /// <summary>
        /// Adds the specified document.
        /// </summary>
        /// <param name="document">The document.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public int Add(Document document, string entityName)
        {
            using (var dbContext = new DMSEntities())
            {
                var entityFromDb = dbContext.Entities.FirstOrDefault(x => x.Name == entityName);
                if (entityFromDb == null)
                {
                    throw new DMSException(string.Format("Entity - {0} is not set up in the system", entityName));
                }
                document.EntityID = entityFromDb.ID;
                document.IsActive = true;
                dbContext.Documents.Add(document);
                dbContext.Entry(document).State = EntityState.Added;
                dbContext.SaveChanges();
            }
            return document.ID;
        }

        /// <summary>
        /// Deletes the document.
        /// </summary>
        /// <param name="documentId">The document unique identifier.</param>
        public void DeleteDocument(int documentId)
        {
            var dbContext = new DMSEntities();
            var document = dbContext.Documents.FirstOrDefault(a => a.ID == documentId);
            if (document != null)
            {
                document.IsActive = false;
                //dbContext.Entry(document).State = EntityState.Modified;
                //dbContext.Entry(document).State = EntityState.Deleted;
                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Gets the document category.
        /// </summary>
        /// <param name="documentCategoryName">Name of the document category.</param>
        /// <returns></returns>
        public DocumentCategory GetDocumentCategory(string documentCategoryName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.DocumentCategories.Where(a => a.Name == documentCategoryName).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the state of the vendor.
        /// </summary>
        /// <param name="vendorId">The vendor identifier.</param>
        /// <returns></returns>
        public string GetVendorState(int vendorId)
        {
            string vendorState = string.Empty;
            Entity entityVendor = ReferenceDataRepository.GetEntityByName(EntityNames.VENDOR);
            using (var dbContext = new DMSEntities())
            {
                AddressType businessaddress = dbContext.AddressTypes.FirstOrDefault(x => x.Name == AddressTypeNames.Business);
                AddressEntity address = dbContext.AddressEntities.FirstOrDefault(x => x.EntityID == entityVendor.ID && x.AddressTypeID == businessaddress.ID
                                                                                      && x.RecordID == vendorId);
                if (address != null && address.StateProvinceID.HasValue)
                {
                    StateProvince state = dbContext.StateProvinces.FirstOrDefault(x => x.ID == address.StateProvinceID);
                    if (state != null) vendorState = state.Name;
                }
            }
            return vendorState;
        }

        /// <summary>
        /// Gets the documents for entity.
        /// </summary>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="recordID">The record identifier.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public List<Document> GetDocumentsForEntity(string entityName, int recordID)
        {
            Entity entity = ReferenceDataRepository.GetEntityByName(entityName);
            if (entity == null)
            {
                throw new DMSException(string.Format("Entity Name - {0}  has not been set up in system", entityName));
            }
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Documents.Where(a => a.EntityID == entity.ID && a.RecordID == recordID && a.IsActive == true).ToList();
            }
        }
    }
}
