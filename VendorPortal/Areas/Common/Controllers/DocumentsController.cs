using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAO;
using VendorPortal.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Kendo.Mvc.UI;
using Martex.DMS.BLL.Model;
using Martex.DMS.Models;
using System.Web.Script.Serialization;
using System;
using System.IO;
using VendorPortal.Controllers;
using VendorPortal.ActionFilters;
using VendorPortal.Models;

namespace VendorPortal.Areas.Common.Controllers
{
    public class DocumentsController : BaseController
    {

        public ActionResult _SelectDocuments([DataSourceRequest] DataSourceRequest request, string recordId, string documentCategory, string entityName)
        {

            var facade = new DocumentFacade();
            List<DocumentsList_Result> documents = null;
            PageCriteria pageCriteria = null;

            var totalRows = 0;
            var sortColumn = "Name";
            var sortOrder = "ASC";
            if (request != null && request.Sorts != null && request.Sorts.Count > 0)
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
            if (entityName == EntityNames.VENDOR)
            {
                documents = facade.GetDocumentsList(pageCriteria, int.Parse(recordId), entityName, "VendorPortal");
            }
            else
            {
                documents = facade.GetDocumentsList(pageCriteria, int.Parse(recordId), entityName);
            }

            if (documents.Count > 0)
            {
                var rows = documents[0].TotalRows;
                if (rows != null) totalRows = rows.Value;
            }
            return Json(new DataSourceResult() { Data = documents, Total = totalRows }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [NoCache]
        public ActionResult AddDocument(int? recordId, string entityName, string documentCategory, string sourceSystem)
        {
            ViewData[StaticData.DocumentCategories.ToString()] = ReferenceDataRepository.GetDocumentCategories(true).ToSelectListItem<DocumentCategory>(x => x.ID.ToString(), y => y.Name, true); ;
            var model = new DocumentModel();
            model.EntityName = entityName;
            if (recordId != null) model.RecordId = recordId.Value;
            model.SourceSystem = sourceSystem;
            return PartialView("_Document", model);
        }

        [HttpPost]
        [AllowAnonymous]
        public ActionResult Save(DocumentModel model)
        {
            var facade = new DocumentFacade();
            var document = new Document();
            document.CreateDate = DateTime.Now;
            document.CreateBy = LoggedInUserName;
            document.Comment = model.Comment;
            document.DocumentCategoryID = int.Parse(model.DocumentCategoryId);
            document.Name = System.IO.Path.GetFileName(model.FileDocument.FileName);

            document.RecordID = model.RecordId;
            var b = new BinaryReader(model.FileDocument.InputStream);
            byte[] binData = b.ReadBytes(model.FileDocument.ContentLength);
            document.DocumentFile = binData;
            if (model.SourceSystem == SourceSystemName.VENDOR_PORTAL)
            {
                document.IsShownOnVendorPortal = true;
            }
            facade.AddDocument(document, model.EntityName, Request.RawUrl, LoggedInUserName, Session.SessionID, model.RecordId);


            var result = new OperationResult() { Status = OperationStatus.SUCCESS };
            return Json(result, "text/plain", JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult Get(int? documentID, string documentName, bool isContentFromFile, int? recordId)
        {
            byte[] fileContent = null;
            string fileName;
            if (!isContentFromFile)
            {
                var facade = new DocumentFacade();
                var document = facade.GetById(documentID.GetValueOrDefault());
                fileContent = document.DocumentFile;
                fileName = document.Name;
            }
            else
            {
                var facade = new DocumentFacade();
                fileContent = facade.GetFileFromNetwork(documentName);
                fileName = Path.GetFileName(documentName);
            }
            return File(fileContent, "application/octet-stream", fileName);
        }

        [HttpPost]
        public ActionResult Delete(int? documentID, string entityName, int recordID)
        {
            var result = new OperationResult();

            var facade = new DocumentFacade();
            facade.DeleteDocument(documentID.GetValueOrDefault(), entityName, Request.RawUrl, LoggedInUserName, Session.SessionID, recordID);

            return Json(result, JsonRequestBehavior.AllowGet);

        }
    }
}
