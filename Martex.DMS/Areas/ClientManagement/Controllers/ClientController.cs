using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Models;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.BLL.Model;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.ClientManagement.Controllers
{
    /// <summary>
    /// Client Controller
    /// </summary>
    public class ClientController : BaseController
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CLIENT_CLIENT)]
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult _ClientDetails(int? clientID)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside _ClientDetails() of ClientsController with the selectedClientId {0}", clientID);
            Client client = null;
            Guid userId = (Guid)System.Web.Security.Membership.FindUsersByName(GetLoggedInUser().UserName)[GetLoggedInUser().UserName].ProviderUserKey;

            logger.InfoFormat("Try to get the Client with selectedClientId {0}", clientID);
            ClientsFacade clientFacade = new ClientsFacade();
            client = clientFacade.Get(clientID.GetValueOrDefault().ToString());
            logger.InfoFormat("Got the Client with ClientId {0}", client.ID);


            ViewData["mode"] = "edit";
            logger.Info("Call the partial view '_ClientDetails' ");
            ClientModel model = SetClientModel(client ?? new Client());
            return PartialView(model);
        }

        [ReferenceDataFilter(StaticData.Country, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.Organizations, false)]
        [ReferenceDataFilter(StaticData.ClientRep, true)]
        [ReferenceDataFilter(StaticData.ClientType, true)]
        public ActionResult _Client_Information(int? clientID)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside _Client_Information() of ClientsController with the selectedClientId {0}", clientID);
            Client client = null;
            Guid userId = (Guid)System.Web.Security.Membership.FindUsersByName(GetLoggedInUser().UserName)[GetLoggedInUser().UserName].ProviderUserKey;

            logger.InfoFormat("Try to get the Client with selectedClientId {0}", clientID);
            ClientsFacade clientFacade = new ClientsFacade();
            client = clientFacade.Get(clientID.GetValueOrDefault().ToString());
            logger.InfoFormat("Got the Client with ClientId {0}", client.ID);

            ViewData["mode"] = "edit";
            logger.Info("Call the partial view '_Client_Information' ");
            ClientModel model = SetClientModel(client ?? new Client());
            return PartialView(model);
        }

        public ActionResult _Client_Avatar(int? entityID, string entity)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside _Client_Avatar() of ClientsController with the {1}Id {0}", entityID, entity);
            ClientsFacade clientFacade = new ClientsFacade();
            logger.InfoFormat("Try to get the Client with {1}Id {0}", entityID, entity);

            logger.Info("Call the partial view '_Client_Avatar' ");
            ImageLoadModel model = new ImageLoadModel()
            {
                entity = entity,
                entityID = entityID
            };
            return PartialView(model);
        }

        public byte[] CropAtRect(ProfileImageModel model)
        {
            try
            {
                //Rectangle r = new Rectangle(model.X1, model.Y1, model.Width, model.Height);
                var ms = new MemoryStream();
                var newfile = Guid.NewGuid();
                model.ProfileImage.InputStream.CopyTo(ms);


                Image nb = Image.FromStream(ms);
                ms.Close();

                var bmpImage = new Bitmap(nb);
                var clonedImage = bmpImage.Clone(new Rectangle(model.X1, model.Y1, model.Width, model.Height), bmpImage.PixelFormat);

                var tmp = new MemoryStream();
                clonedImage.Save(tmp, ImageFormat.Jpeg);
                return tmp.ToArray();

            }
            catch (Exception ex)
            {
                logger.Info(ex.Message, ex);
                throw ex;

            }

        }

        /// <summary>
        /// Removes the client avatar.
        /// </summary>
        /// <param name="clientID">The client identifier.</param>
        /// <returns></returns>
        public ActionResult _RemoveClientAvatar(int clientID)
        {
            var result = new OperationResult();
            logger.InfoFormat("Trying to remove Avatar for the Client {0}", clientID);
            ClientsFacade clientFacade = new ClientsFacade();
            clientFacade.UpdateAvatar(clientID,"Client", null, GetLoggedInUser().UserName);
            logger.Info("Avatar removed successfully");
            result.Data = new { Message = "Avatar removed successfully" };
            return Json(result);
        }

        /// <summary>
        /// Uploads the client avatar.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="clientID">The client identifier.</param>
        /// <returns></returns>
        public ActionResult UploadClientAvatar(ProfileImageModel model, int entityID, string entity)
        {
            var result = new OperationResult();
            if (model != null)
            {
                logger.InfoFormat("Trying to Upload Avatar for the {1} {0}", entityID, entity);
                ClientsFacade clientFacade = new ClientsFacade();
                clientFacade.UpdateAvatar(entityID, entity, "data:image/png;base64," + Convert.ToBase64String(CropAtRect(model)), GetLoggedInUser().UserName);
                logger.Info("Avatar uploaded successfully");
            }
            result.Data = new { Message = "Avatar updated successfully" };
            return Json(result);
        }

        /// <summary>
        /// Saves the client information section.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        public ActionResult SaveClientInformationSection(ClientModel clientModel)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Try to update the Client whose ClientId is {0}, Data = {1}", clientModel.Client.ID, JsonConvert.SerializeObject(clientModel));
            ClientsFacade clientFacade = new ClientsFacade();
            clientFacade.Update(clientModel, clientModel.ClientOrganizationsValues, GetLoggedInUser().UserName);
            logger.InfoFormat("The Client has been updated", clientModel.Client.ID);
            result.Status = OperationStatus.SUCCESS;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult _Client_Documents(int? clientID)
        {
            logger.InfoFormat("Trying to load documents for the  Client ID {0}", clientID);
            ViewData["ClientID"] = clientID.GetValueOrDefault().ToString();
            return PartialView(clientID);
        }
        #region Helper Methods
        /// <summary>
        /// Sets the client model.
        /// </summary>
        /// <param name="client">The client.</param>
        /// <returns></returns>
        private ClientModel SetClientModel(Client client)
        {
            if (client == null)
            {
                return null;
            }
            ClientModel clientModel = new ClientModel();
            clientModel.Client = client;
            clientModel.isActive = client.IsActive ?? false;

            clientModel.LastUpdateInformation = string.Format("{0} {1}", client.ModifyBy, client.ModifyDate);
            if (client.OrganizationClients.Count > 0)
            {
                int[] organizationValues = new int[client.OrganizationClients.Count];
                string[] organizationStringValues = new string[client.OrganizationClients.Count];
                List<OrganizationClient> clientClientList = client.OrganizationClients.ToList();
                for (int i = 0; i < organizationValues.Count(); i++)
                {
                    organizationValues[i] = clientClientList[i].OrganizationID;
                    organizationStringValues[i] = clientClientList[i].OrganizationID.ToString();
                }
                clientModel.ClientOrganizationsValues = organizationValues;
                clientModel.ClientOrganizationsString = organizationStringValues;
            }
            return clientModel;
        }

        #endregion
    }
}
