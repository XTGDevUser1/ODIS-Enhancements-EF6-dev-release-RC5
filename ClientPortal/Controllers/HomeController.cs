using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using Kendo.Mvc.UI;
using ClientPortal.Models;
using ClientPortal.ActionFilters;
using ClientPortal.Common;
using ClientPortal.Areas.Common.Controllers;

namespace ClientPortal.Controllers
{
    public class HomeController : BaseController
    {
        #region Private Members
        UsersFacade usersFacade;
        #endregion

        #region Public Methods
        /// <summary>
        /// Get the user id based on the selection from telerik grid.
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        [Authorize]
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
        [Authorize]
        [NoCache]
        public ActionResult Index([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside Index() of UserController. Attempt to call the view");
            UsersFacade userFacade = new UsersFacade();
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                SortColumn = "UserName",
                SortDirection = "ASC",
                PageSize = 10
            };
            List<SearchUsersListClientPortal_Result> list = userFacade.ListClientPortal((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);
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
            UsersFacade userFacade = new UsersFacade();
            List<SearchUsersListClientPortal_Result> list = userFacade.ListClientPortal((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);

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
            return Json(result);
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
        public ActionResult Get(string selectedUserId, string mode)
        {
            OperationResult result = new OperationResult();

            RegisterUserModel registerUserModel = null;
            var loggedInUserId = (Guid)GetLoggedInUser().ProviderUserKey;
            logger.InfoFormat("Inside Get() of UserController with the selectedUserId {0} and mode {1}", selectedUserId, mode);


            if (mode != "add")
            {
                logger.InfoFormat("Try to get the user with selectedUserId {0}", selectedUserId);
                registerUserModel = From_aspnet_Users(new UsersFacade().Get(Guid.Parse(selectedUserId)));

                ViewData[StaticData.DataGroups.ToString()] = ReferenceDataRepository.GetDataGroups(registerUserModel.OrganizationID).ToSelectListItem<DropDownDataGroup>(x => x.ID.ToString(), y => y.Name, false);

                ViewData[StaticData.UserRoles.ToString()] = ReferenceDataRepository.GetUserRoles(registerUserModel.OrganizationID).ToSelectListItem<DropDownRoles>(x => x.RoleName, y => y.RoleName, false);
                logger.InfoFormat("Got the user with userId {0}", registerUserModel.ID);
            }
            else
            {
                registerUserModel = From_aspnet_Users(new UsersFacade().Get(loggedInUserId));

                ViewData[StaticData.UserRoles.ToString()] = ReferenceDataRepository.GetUserRoles(registerUserModel.OrganizationID).ToSelectListItem<DropDownRoles>(x => x.RoleName, y => y.RoleName, false);

                ViewData[StaticData.DataGroups.ToString()] = ReferenceDataRepository.GetDataGroups(registerUserModel.OrganizationID).ToSelectListItem<DropDownDataGroup>(x => x.ID.ToString(), y => y.Name, false);
                registerUserModel = null;
            }

            ViewData[StaticData.Organizations.ToString()] = ReferenceDataRepository.GetOrganizations(loggedInUserId).ToSelectListItem<dms_users_organizations_List>(x => x.ID.ToString(), y => y.Name, true);


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
        [HttpPost]
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
                    usersFacade = new UsersFacade();
                    logger.InfoFormat("Inside Save() of UserController with mode {0}", hdnfldMode);
                    aspnet_Users aspNetUser = new aspnet_Users();
                    //Membership properties
                    aspNetUser.UserName = registerUserModel.UserName.Trim();
                    aspNetUser.aspnet_Membership = new aspnet_Membership();
                    aspNetUser.aspnet_Membership.IsApproved = registerUserModel.Active;
                    aspNetUser.aspnet_Membership.Email = registerUserModel.Email;
                    aspNetUser.aspnet_Membership.Password = registerUserModel.Password == null ? string.Empty : registerUserModel.Password;

                    //For User Table
                    aspNetUser.Users = new System.Data.Objects.DataClasses.EntityCollection<Martex.DMS.DAL.User>();

                    if (hdnfldMode == "add")
                    {
                        logger.InfoFormat("Try to add a new user with user name {0}", registerUserModel.UserName);
                        //For User Table
                        aspNetUser.Users.Add(new Martex.DMS.DAL.User()
                        {
                            FirstName = registerUserModel.FirstName,
                            LastName = registerUserModel.LastName,
                            CreateBy = GetLoggedInUser().UserName,
                            CreateDate = DateTime.Now,
                            OrganizationID = registerUserModel.OrganizationID,
                            ModifyBy = GetLoggedInUser().UserName,
                            ModifyDate = DateTime.Now,
                            AgentNumber = registerUserModel.AgentNumber,
                            PhoneUserID = registerUserModel.PhoneUserId,
                            PhonePassword = registerUserModel.PhonePassword
                        });

                        //For Roles
                        aspNetUser.aspnet_Roles = new System.Data.Objects.DataClasses.EntityCollection<aspnet_Roles>();
                        foreach (string role in registerUserModel.SelectedUserRoles)
                        {
                            aspNetUser.aspnet_Roles.Add(new aspnet_Roles()
                            {
                                RoleName = role
                            });
                        }
                        if (registerUserModel.SelectedDataGroupsID != null)
                        {
                            //For Data Groups
                            aspNetUser.Users.FirstOrDefault().UserDataGroups = new System.Data.Objects.DataClasses.EntityCollection<UserDataGroup>();
                            foreach (int dataGroupID in registerUserModel.SelectedDataGroupsID)
                            {
                                aspNetUser.Users.FirstOrDefault().UserDataGroups.Add(new UserDataGroup() { DataGroupID = dataGroupID });
                            }
                        }
                        usersFacade.Add(aspNetUser);
                        logger.Info("A new user has been created");
                    }
                    else
                    {
                        logger.InfoFormat("Try to update the user whose userId is {0}", registerUserModel.ID);
                        //For User Table
                        aspNetUser.Users.Add(new Martex.DMS.DAL.User()
                        {
                            OrganizationID = registerUserModel.OrganizationID,
                            FirstName = registerUserModel.FirstName,
                            LastName = registerUserModel.LastName,
                            ModifyBy = GetLoggedInUser().UserName,
                            ModifyDate = DateTime.Now,
                            ID = registerUserModel.ID.Value,
                            AgentNumber = registerUserModel.AgentNumber,
                            PhoneUserID = registerUserModel.PhoneUserId,
                            PhonePassword = registerUserModel.PhonePassword
                        });

                        //For Roles
                        aspNetUser.aspnet_Roles = new System.Data.Objects.DataClasses.EntityCollection<aspnet_Roles>();
                        foreach (string role in registerUserModel.SelectedUserRoles)
                        {
                            aspNetUser.aspnet_Roles.Add(new aspnet_Roles()
                            {
                                RoleName = role
                            });
                        }

                        //For Data Groups
                        if (registerUserModel.SelectedDataGroupsID != null)
                        {
                            aspNetUser.Users.FirstOrDefault().UserDataGroups = new System.Data.Objects.DataClasses.EntityCollection<UserDataGroup>();
                            foreach (int dataGroupID in registerUserModel.SelectedDataGroupsID)
                            {
                                aspNetUser.Users.FirstOrDefault().UserDataGroups.Add(new UserDataGroup() { DataGroupID = dataGroupID });
                            }
                        }
                        if (hdnfldMode == "edit")
                        {
                            usersFacade.Update(aspNetUser);
                        }
                        logger.Info("The user has been updated");

                    }
                    result.OperationType = "Success";
                    result.Status = OperationStatus.SUCCESS;
                    return Json(result);
                }

                var errorList = GetErrorsFromModelStateAsString();
                logger.Error(errorList);
                throw new DMSException(errorList);
            }
            catch (ArgumentException aex)
            {
                throw new DMSException(aex.Message, aex);
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
                // delete data                    
                new UsersFacade().Delete(new Guid(userID));
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
            var userProfile = user.Users.FirstOrDefault();
            if (userProfile != null)
            {
                userModel.FirstName = userProfile.FirstName;
                userModel.LastName = userProfile.LastName;
                userModel.OrganizationID = userProfile.OrganizationID;
                userModel.LastUpdated = userProfile.ModifyDate;
                userModel.ID = userProfile.ID;
                userModel.AgentNumber = userProfile.AgentNumber;
                userModel.ModifiedBy = userProfile.ModifyBy;
                userModel.PhoneUserId = userProfile.PhoneUserID;
                userModel.PhonePassword = userProfile.PhonePassword;
            }
            userModel.Email = user.aspnet_Membership.Email;

            userModel.UserRoles = user.aspnet_Roles.Select(c => c.RoleName).ToArray();
            userModel.SelectedUserRoles = userModel.UserRoles;
            userModel.DataGroupsID = user.Users.FirstOrDefault().UserDataGroups.Select(id => id.DataGroupID).ToArray();
            userModel.SelectedDataGroupsID = userModel.DataGroupsID;
            userModel.Active = user.aspnet_Membership.IsApproved;
            if (user.LastActivityDate != null)
            {
                userModel.LastActivityDate = user.LastActivityDate.ToLocalTime();
            }

            return userModel;
        }
        #endregion

    }
}
