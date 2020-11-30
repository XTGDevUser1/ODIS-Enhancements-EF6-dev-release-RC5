using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Kendo.Mvc.UI;
using Martex.DMS.BLL.Model;
using Martex.DMS.Models;
using System.Web.Script.Serialization;
using System;
using System.IO;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.Areas.Common.Controllers
{
    public class DocumentsController : BaseController
    {

        public ActionResult _SelectDocuments([DataSourceRequest] DataSourceRequest request, string recordId, string documentCategory, string entityName, string sourceSystem = SourceSystemName.BACK_OFFICE)
        {

            DocumentFacade facade = new DocumentFacade();
            List<DocumentsList_Result> documents = null;
            PageCriteria pageCriteria = null;

            int totalRows = 0;
            string sortColumn = "Name";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            if (entityName == EntityNames.VENDOR)
            {
                pageCriteria = new PageCriteria()
                {
                    StartInd = 1,
                    EndInd = 500,
                    PageSize = 500,
                    SortColumn = string.Empty,
                    SortDirection = string.Empty,
                    WhereClause = null
                };
            }
            else
            {
                pageCriteria = new PageCriteria()
                {
                    StartInd = request.PageSize * (request.Page - 1) + 1,
                    EndInd = request.PageSize * request.Page,
                    PageSize = request.PageSize,
                    SortDirection = sortOrder,
                    SortColumn = sortColumn,
                    WhereClause = null
                };
            }
            documents = facade.GetDocumentsList(pageCriteria, int.Parse(recordId), entityName);
            if (documents.Count > 0)
            {
                totalRows = documents[0].TotalRows.Value;
            }
            ViewData["sourceSystem"] = sourceSystem;
            return Json(new DataSourceResult() { Data = documents, Total = totalRows });
        }

        [HttpPost]
        [NoCache]
        public ActionResult AddDocument(int? recordId, string entityName, string documentCategory, string sourceSystem)
        {
            var documentCategoryList = ReferenceDataRepository.GetDocumentCategories();
            if (sourceSystem == SourceSystemName.CLIENT_PORTAL)
            {
                documentCategoryList = documentCategoryList.Where(a => a.IsShownOnClientPortal == true).ToList();
            }
            ViewData[StaticData.DocumentCategories.ToString()] = documentCategoryList.ToSelectListItem<DocumentCategory>(x => x.ID.ToString(), y => y.Name, true);
            DocumentModel model = new DocumentModel();
            model.EntityName = entityName;
            model.RecordId = recordId.Value;
            model.SourceSystem = sourceSystem;
            return PartialView("_Document", model);
        }

        [HttpPost]
        [AllowAnonymous]
        public ActionResult Save(DocumentModel model)
        {
            DocumentFacade facade = new DocumentFacade();
            Document document = new Document();
            document.CreateDate = DateTime.Now;
            document.CreateBy = LoggedInUserName;
            document.Comment = model.Comment;
            document.DocumentCategoryID = int.Parse(model.DocumentCategoryId);
            document.Name = System.IO.Path.GetFileName(model.FileDocument.FileName);

            document.RecordID = model.RecordId;
            BinaryReader b = new BinaryReader(model.FileDocument.InputStream);
            byte[] binData = b.ReadBytes(model.FileDocument.ContentLength);
            document.DocumentFile = binData;
            if (model.SourceSystem == SourceSystemName.VENDOR_PORTAL)
            {
                document.IsShownOnVendorPortal = true;
            }
            if (model.SourceSystem == SourceSystemName.CLIENT_PORTAL)
            {
                document.IsShownOnClientPortal = model.IsShownOnClientPortal;
            }
            else if (model.SourceSystem == SourceSystemName.BACK_OFFICE)
            {
                document.IsShownOnVendorPortal = model.IsShownOnVendorPortal;
            }
            facade.AddDocument(document, model.EntityName, Request.RawUrl, LoggedInUserName, Session.SessionID, model.RecordId);

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            return Json(result, "text/plain", JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult Get(int? documentID, string documentName, bool isContentFromFile, int? recordId)
        {
            byte[] fileContent = null;
            string fileName = string.Empty;
            if (!isContentFromFile)
            {
                var facade = new DocumentFacade();
                var document = facade.GetById(documentID.GetValueOrDefault());
                fileContent = document.DocumentFile;
                fileName = document.Name;
            }
            else
            {
                DocumentFacade facade = new DocumentFacade();
                fileContent = facade.GetFileFromNetwork(documentName);
                fileName = Path.GetFileName(documentName);
            }
            return File(fileContent, "application/octet-stream", fileName);
        }

        [HttpPost]
        public ActionResult Delete(int? documentID, string entityName, int recordID)
        {
            OperationResult result = new OperationResult();

            var facade = new DocumentFacade();
            facade.DeleteDocument(documentID.GetValueOrDefault(), entityName, Request.RawUrl, LoggedInUserName, Session.SessionID, recordID);

            return Json(result, JsonRequestBehavior.AllowGet);

        }
    }
}
