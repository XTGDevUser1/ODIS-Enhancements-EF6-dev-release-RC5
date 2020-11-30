using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Controllers;
using VendorPortal.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using VendorPortal.ActionFilters;
using Martex.DMS.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.DAL.Common;
using VendorPortal.Common;
using Martex.DMS.DAL.Entities;
using log4net;
using System.Web.Security;
using System.Data.Entity.Core.Objects.DataClasses;

namespace VendorPortal.Areas.Users.Controllers
{
    public class HomeController : BaseController
    {
        #region Private Members
        protected VendorUserFacade vendorUserFacade = new VendorUserFacade();
        #endregion

        #region Public Methods
        /// <summary>
        /// Get the user id based on the selection from telerik grid.
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        [Authorize, ValidateInput(false)]
        public ActionResult GetUserId(string userId)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside GetUserId() of UserController. Call by the grid with the userId {0}, try to returns the Jeson object", userId);
            return Json(new { userIdValue = userId }, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// Get the List of users.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ISP_USERMAINTENANCE)]
        [NoCache]
        public ActionResult Index([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside Index() of UserController. Attempt to call the view");

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                SortColumn = "UserName",
                SortDirection = "ASC",
                PageSize = 10
            };
            List<UsersForVendorPortal_Result> list = vendorUserFacade.GetUsersForVendorPortal((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);
            return View(list);
        }

        /// <summary>
        /// Search Method for User Grid
        /// </summary>
        /// <param name="command"></param>
        /// <returns></returns>
        /// 
        [NoCache]
        [Authorize]
        public ActionResult List([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside List() of UsersController. Attempt to get all Users depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "UserName";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }

            List<UsersForVendorPortal_Result> list = vendorUserFacade.GetUsersForVendorPortal((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows;
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            return Json(result, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Get the particular user details based on the id.
        /// </summary>
        /// <param name="selectedUserId"></param>
        /// <param name="mode"></param>
        /// <returns></returns>
        [Authorize]
        [HttpPost]
        [NoCache]
        [ReferenceDataFilter(StaticData.UserRoles, false)]
        public ActionResult Get(string selectedUserId, string mode)
        {

            OperationResult result = new OperationResult();

            RegisterUserModel registerUserModel = null;
            var loggedInUserId = (Guid)GetLoggedInUser().ProviderUserKey;

            if (!string.IsNullOrEmpty(selectedUserId))
            {
                if (IsSuperVendor(Guid.Parse(selectedUserId)))
                {
                    if (!IsSuperVendor(GetLoggedInUserId()))
                    {
                        throw new DMSException("Permission Denied");
                    }
                }
            }
            logger.InfoFormat("Inside Get() of UserController with the selectedUserId {0} and mode {1}", selectedUserId, mode);

            var allowedRoles = vendorUserFacade.GetRoles().Where(x => x.LoweredRoleName != "sysadmin").ToList<aspnet_Roles>();

            if (mode != "add")
            {
                Guid selectedUserGuid = Guid.Parse(selectedUserId);
                logger.InfoFormat("Try to get the user with selectedUserId {0}", selectedUserId);
                registerUserModel = From_aspnet_Users(vendorUserFacade.Get(selectedUserGuid));
                if (registerUserModel.SelectedUserRoles.Contains("VendorAdmin"))
                {
                    registerUserModel.IsAdmin = true;
                }

                // ViewData[StaticData.UserRoles.ToString()] = allowedRoles.ToSelectListItem<aspnet_Roles>(x => x.RoleName, y => y.RoleName, false);
                logger.InfoFormat("Got the user with userId {0}", registerUserModel.ID);
            }
            else
            {
                //ViewData[StaticData.UserRoles.ToString()] = allowedRoles.ToSelectListItem<aspnet_Roles>(x => x.RoleName, y => y.RoleName, false); 
                registerUserModel = new RegisterUserModel();
                // Fill the Vendor details.
                VendorManagementFacade facade = new VendorManagementFacade();
                VendorUser vendorUser = facade.GetVendorUser(GetLoggedInUserId());
                if (vendorUser != null)
                {
                    registerUserModel.VendorID = vendorUser.VendorID;
                    registerUserModel.VendorName = vendorUser.Vendor.Name;
                    registerUserModel.VendorNumber = vendorUser.Vendor.VendorNumber;
                }
            }

            ViewData["mode"] = mode;
            logger.Info("Call the partial view '_UserDetail' ");
            return PartialView("_UserRegistration", registerUserModel);

        }
        /// <summary>
        /// Method used to save the user details.
        /// </summary>
        /// <param name="registerUserModel"></param>
        /// <param name="hdnfldMode"></param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        [NoCache]
        [Authorize]
        public ActionResult Save(RegisterUserModel registerUserModel, string hdnfldMode)
        {
            OperationResult result = new OperationResult();

            try
            {
                if (ModelState.IsValid)
                {
                    if (registerUserModel.UserName.Contains(" "))
                    {
                        throw new DMSException("User Name cannot contain spaces.");
                    }

                    logger.InfoFormat("Inside Save() of UserController with mode {0}", hdnfldMode);
                    aspnet_Users aspNetUser = new aspnet_Users();
                    //Membership properties
                    aspNetUser.UserName = registerUserModel.UserName.Trim();
                    aspNetUser.aspnet_Membership = new aspnet_Membership();
                    if (User.IsInRole("sysadmin"))
                    {
                        aspNetUser.aspnet_Membership.IsApproved = registerUserModel.Active;
                    }
                    else
                    {
                        aspNetUser.aspnet_Membership.IsApproved = true;//registerUserModel.Active;
                    }
                    aspNetUser.aspnet_Membership.Email = registerUserModel.Email;
                    aspNetUser.aspnet_Membership.Password = registerUserModel.Password == null ? string.Empty : registerUserModel.Password;

                    VendorUser vendorUser = new VendorUser();
                    vendorUser.ID = registerUserModel.VendorUserID.GetValueOrDefault();
                    vendorUser.FirstName = registerUserModel.FirstName;
                    vendorUser.LastName = registerUserModel.LastName;
                    vendorUser.VendorID = registerUserModel.VendorID;
                    vendorUser.PostLoginPromptID = null;
                    //For Roles
                    aspNetUser.aspnet_Roles = new EntityCollection<aspnet_Roles>();
                    //if (registerUserModel.IsAdmin)
                    //{
                    //    aspNetUser.aspnet_Roles.Add(new aspnet_Roles()
                    //        {
                    //            RoleName = "VendorAdmin"

                    //        });
                    //}
                    //else
                    //{
                    //    aspNetUser.aspnet_Roles.Add(new aspnet_Roles()
                    //    {
                    //        RoleName = "VendorWeb"

                    //    });
                    //}
                    aspNetUser.aspnet_Roles.Add(new aspnet_Roles()
                    {
                        RoleName = registerUserModel.UserRoleName

                    });
                    if (hdnfldMode == "add")
                    {
                        logger.InfoFormat("Try to add a new user with user name {0}", registerUserModel.UserName);

                        vendorUserFacade.AddUser(aspNetUser, vendorUser, LoggedInUserName);
                        logger.Info("A new user has been created");
                    }
                    else
                    {
                        logger.InfoFormat("Try to update the user whose userId is {0}", registerUserModel.ID);

                        if (hdnfldMode == "edit")
                        {
                            vendorUserFacade.UpdateUser(aspNetUser, vendorUser);
                        }
                        logger.Info("The user has been updated");

                    }
                    result.OperationType = "Success";
                    result.Status = OperationStatus.SUCCESS;
                    return Json(result, JsonRequestBehavior.AllowGet);
                }

                var errorList = GetErrorsFromModelStateAsString();
                logger.Error(errorList);
                throw new DMSException(errorList);
            }
            catch (ArgumentException aex)
            {
                string errroMesasage = aex.Message.ToString();
                if (aex.Message == "Non alpha numeric characters in 'newPassword' needs to be greater than or equal to '1'.")
                {
                    errroMesasage = "The Password should contain atleast 1 special character i.e;  !@#$%^&*()";
                }
                throw new DMSException(errroMesasage, aex);
            }


        }
        /// <summary>
        /// Method used to delete the user from database based on the user id
        /// </summary>
        /// <param name="userID"></param>
        /// <returns></returns>
        [Authorize]
        [HttpPost]
        public ActionResult Delete(string userID)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Delete() of UserController with the userId {0}", userID);
            if (ModelState.IsValid)
            {
                Guid userGUID = new Guid(userID);
                if (IsSuperVendor(userGUID))
                {
                    throw new DMSException("This is the main account for the Vendor and cannot be deleted");
                }

                if (userGUID == GetLoggedInUserId())
                {
                    throw new DMSException("Deleting own account is not allowed in the system");
                }
                // delete data                    
                vendorUserFacade.DeleteUser(userGUID);
                logger.InfoFormat("The record with userId {0} has been Deleted", userID);
                result.OperationType = "Success";
                result.Status = "Success";
                return Json(result);
            }
            var errorList = GetErrorsFromModelStateAsString();
            logger.Error(errorList);
            throw new DMSException(errorList);

        }
        #endregion

        #region Helper Methods
        private RegisterUserModel From_aspnet_Users(aspnet_Users user)
        {
            RegisterUserModel userModel = new RegisterUserModel();
            userModel.UserName = user.UserName;
            VendorManagementFacade facade = new VendorManagementFacade();
            VendorUser vendorUser = facade.GetVendorUser(user.UserId);

            if (vendorUser != null)
            {
                userModel.FirstName = vendorUser.FirstName;
                userModel.LastName = vendorUser.LastName;
                userModel.LastUpdated = vendorUser.ModifyDate;
                userModel.ID = vendorUser.ID;
                userModel.ModifiedBy = vendorUser.ModifyBy;
                userModel.VendorName = vendorUser.Vendor.Name;
                userModel.VendorUserID = vendorUser.ID;
                userModel.VendorID = vendorUser.VendorID;
                userModel.VendorNumber = vendorUser.Vendor.VendorNumber;
            }
            userModel.Email = user.aspnet_Membership.Email;

            userModel.UserRoles = user.aspnet_Roles.Select(c => c.RoleName).ToArray();
            userModel.UserRoleName = user.aspnet_Roles.Select(c => c.RoleName).FirstOrDefault();
            userModel.SelectedUserRoles = userModel.UserRoles;

            userModel.Active = user.aspnet_Membership.IsApproved;
            if (user.LastActivityDate != null)
            {
                userModel.LastActivityDate = user.LastActivityDate;
            }

            return userModel;
        }
        #endregion


    }
}
