using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;
using log4net;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;
using System.Data.SqlClient;
using Newtonsoft.Json;
using System.Web.Security;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class ReferenceDataRepository
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ReferenceDataRepository));
        /// <summary>
        /// Gets all feedback types.
        /// </summary>
        /// <returns>
        /// List of Feedback type records
        /// </returns>
        public static List<FeedbackType> GetFeedbackTypes()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.FeedbackTypes.OrderBy(x => x.Sequence).ToList<FeedbackType>();
                return list;
            }
        }

        /// <summary>
        /// Gets the program by ID.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public static Program GetProgramByID(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.Programs.Where(x => x.ID == id)
                    .Include(x => x.Client)
                    .FirstOrDefault();
                return list;
            }
        }

        public static Program GetProgramByIDAndClientID(int id, int clientID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.Programs.Where(x => x.ID == id && x.ClientID == clientID)
                    .Include(x => x.Client)
                    .FirstOrDefault();
                return list;
            }
        }

        /// <summary>
        /// Gets all StateProvinces.
        /// </summary>
        /// <param name="countryId">The country id.</param>
        /// <returns>
        /// List of Feedback type records
        /// </returns>
        public static List<StateProvince> GetStateProvinces(int countryId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.StateProvinces.Where(x => x.CountryID == countryId).OrderBy(x => x.Sequence).ToList<StateProvince>();
                return list;
            }
        }

        // NP 01/11: Getting the state provinces for the states US and CA
        public static List<StateProvince> GetAllStateProvinces()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = (from sp in dbContext.StateProvinces
                            join c in dbContext.Countries on sp.CountryID equals c.ID
                            where (c.ISOCode == "US" || c.ISOCode == "CA")
                            orderby sp.CountryID, sp.Sequence
                            //orderby sp.Sequence
                            select sp).ToList<StateProvince>();
                //dbContext.StateProvinces.Where(s=>s.CountryID ==()).OrderBy(x => x.CountryID).ToList<StateProvince>();
                return list;
            }
        }

        /// <summary>
        /// Gets all StateProvinces.
        /// </summary>
        /// <param name="countryName">Name of the country.</param>
        /// <returns>
        /// List of Feedback type records
        /// </returns>
        public static List<StateProvince> GetStateProvinces(string countryName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.StateProvinces.Where(x => x.Country.Name == countryName).OrderBy(x => x.Sequence).ToList<StateProvince>();
                return list;
            }
        }

        /// <summary>
        /// Gets the feedbacktype record for the given Id
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns>
        /// An instance of Feedback type
        /// </returns>
        public static FeedbackType GetFeedbackType(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var feedbackType = dbContext.FeedbackTypes.Where(a => a.ID == id).FirstOrDefault();
                return feedbackType;
            }
        }

        /// <summary>
        /// Gets all the priorities.
        /// </summary>
        /// <returns>
        /// List of Priorities
        /// </returns>
        public static List<ServiceRequestPriority> GetPriorities()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.ServiceRequestPriorities.Where(x => x.IsActive == true).OrderBy(a => a.Sequence).ToList<ServiceRequestPriority>();
                return list;
            }
        }
        /// <summary>
        /// Gets the queue filter items.
        /// </summary>
        /// <returns></returns>
        public static Dictionary<string, string> GetQueueFilterItems()
        {
            var list = new Dictionary<string, string>();

            list.Add("AssignedTo", "Assigned To");
            list.Add("Client", "Client");
            list.Add("ClosedLoop", "Closed Loop Status");
            list.Add("ISPName", "ISP Name");
            list.Add("MemberNumber", "Member #");
            list.Add("Member", "Member Last Name");
            list.Add("NextAction", "Next Action");
            list.Add("PONumber", "PO #");
            list.Add("Priority", "Priority");
            list.Add("RequestNumber", "Request #");
            list.Add("ServiceType", "Service Type");
            list.Add("CreateBy", "User Name");

            return list;
        }

        /// <summary>
        /// Gets the suffix.
        /// </summary>
        /// <returns></returns>
        public static List<Suffix> GetSuffix()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Suffixes.OrderBy(s => s.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the prefix.
        /// </summary>
        /// <returns></returns>
        public static List<Prefix> GetPrefix()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Prefixes.OrderBy(s => s.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the emergency assistance reason.
        /// </summary>
        /// <returns></returns>
        public static List<EmergencyAssistanceReason> GetEmergencyAssistanceReason()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.EmergencyAssistanceReasons.Where(s => s.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the organizations.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <returns></returns>
        public static List<dms_users_organizations_List> GetOrganizations(Guid userId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var organizations = dbContext.GetUserOrganizations(userId); ;
                return organizations.OrderBy(a => a.Name).ToList<dms_users_organizations_List>();
            }
        }

        /// <summary>
        /// Gets the roles.
        /// </summary>
        /// <param name="applicationID">The application ID.</param>
        /// <returns></returns>
        public static List<aspnet_Roles> GetRoles(string applicationName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var roles = (from r in dbContext.aspnet_Roles
                             join a in dbContext.aspnet_Applications on r.ApplicationId equals a.ApplicationId
                             where a.ApplicationName == applicationName
                             select r).ToList<aspnet_Roles>();
                return roles;
            }
        }
        /// <summary>
        /// Gets the user roles.
        /// </summary>
        /// <param name="organizationID">The organization ID.</param>
        /// <returns></returns>
        public static List<DropDownRoles> GetUserRoles(int? organizationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (organizationID != null)
                {
                    var userRoles = (from aspRoles in dbContext.aspnet_Roles
                                     join roleID in dbContext.OrganizationRoles
                                     on aspRoles.RoleId equals roleID.RoleID
                                     where roleID.OrganizationID == organizationID
                                     select new DropDownRoles() { RoleID = aspRoles.RoleId, RoleName = aspRoles.RoleName });
                    return userRoles.ToList<DropDownRoles>();
                }
                else
                {
                    var userRoles = (from aspRoles in dbContext.aspnet_Roles
                                     select new DropDownRoles() { RoleID = aspRoles.RoleId, RoleName = aspRoles.RoleName });
                    return userRoles.ToList<DropDownRoles>();
                }
            }
        }

        /// <summary>
        /// Gets the data groups.
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <returns></returns>
        public static List<DropDownDataGroup> GetDataGroups(int? organizationId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                var resultTest = (from users in dbContext.Users
                                  join oc in dbContext.OrganizationClients
                                      on users.OrganizationID equals oc.OrganizationID
                                  join datagroup in dbContext.DataGroups
                                  on oc.OrganizationID equals datagroup.OrganizationID
                                  join dataGroupPrograms in dbContext.DataGroupPrograms
                                  on datagroup.ID equals dataGroupPrograms.DataGroupID
                                  join programs in dbContext.Programs
                                  on dataGroupPrograms.ProgramID equals programs.ID
                                  where users.OrganizationID == organizationId
                                  where programs.IsActive == true
                                  select new DropDownDataGroup() { ID = datagroup.ID, Name = datagroup.Name }).Distinct();
                return resultTest.ToList<DropDownDataGroup>();
            }

        }

        /// <summary>
        /// Gets the clients.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <returns></returns>
        public static List<Clients_Result> GetClients(Guid userID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.GetClients(userID).OrderBy(u => u.ClientName);
                return results.ToList<Clients_Result>();
            }
        }

        public static Client GetClientForUser(string userName)
        {
            Client client = null;
            using (DMSEntities dbContext = new DMSEntities())
            {

                User user = dbContext.Users.Where(a => a.aspnet_Users.LoweredUserName.Equals(userName.ToLower())).FirstOrDefault();
                if (user != null)
                {
                    client = GetOrganizationClients(user.OrganizationID.GetValueOrDefault()).FirstOrDefault();
                }

            }
            return client;
        }

        /// <summary>
        /// Gets all clients.
        /// </summary>
        /// <returns></returns>
        public static List<Client> GetAllClients()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Clients.Where(u => u.IsActive == true).OrderBy(u => u.Name).ToList();
            }
        }

        /// <summary>
        /// Gets the organization clients.
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <returns></returns>
        public static List<Client> GetOrganizationClients(int organizationId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                var result = (from c in dbContext.Clients.Include(c => c.OrganizationClients)
                              join oc in dbContext.OrganizationClients on c.ID equals oc.ClientID
                              where oc.OrganizationID == organizationId
                              select c);
                return result.ToList<Client>();
            }
        }


        /// <summary>
        /// Gets the data group programs.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="organizationId">The organization id.</param>
        /// <returns></returns>
        public static List<ProgramsList> GetDataGroupPrograms(Guid userId, string organizationId)
        {
            int? orgID = null;
            if (!string.IsNullOrEmpty(organizationId)) { int.Parse(organizationId); }
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetPrograms(userId, orgID).ToList();  // Temp code, need to change
                return result.ToList<ProgramsList>();
            }
        }

        /// <summary>
        /// Gets the ivr scripts.
        /// </summary>
        /// <returns></returns>
        public static List<IVRScript> GetIvrScripts()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.IVRScripts;
                return results.ToList<IVRScript>();
            }
        }

        /// <summary>
        /// Gets the skill sets.
        /// </summary>
        /// <returns></returns>
        public static List<Skillset> GetSkillSets()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.Skillsets;
                return results.ToList<Skillset>();
            }
        }

        /// <summary>
        /// Gets the in bound phone company.
        /// </summary>
        /// <returns></returns>
        public static List<PhoneCompany> GetInBoundPhoneCompany()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.PhoneCompanies;
                return results.ToList<PhoneCompany>();
            }
        }

        /// <summary>
        /// Gets the program.
        /// </summary>
        /// <returns></returns>
        public static List<Program> GetProgram()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.Programs.Where(u => u.IsActive == true).Include(p => p.Client);
                return results.ToList<Program>();
            }
        }
        public static List<Program> GetProgramByClient(int clientID, bool considerWithGroup = false)
        {
            List<Program> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (considerWithGroup)
                {
                    list = dbContext.Programs.Where(u => u.IsActive == true && u.ClientID == clientID && u.IsGroup == false).OrderBy(u => u.Name).Include(p => p.Client).ToList();
                }
                else
                {
                    list = dbContext.Programs.Where(u => u.IsActive == true && u.ClientID == clientID).OrderBy(u => u.Name).Include(p => p.Client).ToList();
                }
            }
            return list;
        }

        public static List<Program> GetProgramByClient(int clientID)
        {
            List<Program> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.Programs.Where(u => u.IsActive == true && u.ClientID == clientID).Include(p => p.Client).OrderBy(u => u.Name).ToList();
                return list;
            }
        }

        public static List<Program> GetProgramByClientOrderByID(int clientID)
        {
            List<Program> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.Programs.Where(u => u.IsActive == true && u.ClientID == clientID).Include(p => p.Client).OrderBy(u => u.ID).ToList();
                return list;
            }
        }
        /// <summary>
        /// Gets the program for member.
        /// </summary>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        public static List<ChildrenPrograms_Result> GetProgramForMember(int programID)
        {
            logger.InfoFormat("ReferenceDataRepository - GetProgramForMember(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                programID = programID
            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.GetChildrenPrograms(programID).ToList<ChildrenPrograms_Result>();
                logger.InfoFormat("ReferenceDataRepository - GetProgramForMember(), Returns:  {0}", JsonConvert.SerializeObject(new
                {
                    results = results
                }));
                return results;
            }
        }

        /// <summary>
        /// Gets the transition program for member.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public static List<ChildrenPrograms_Result> GetTransitionProgramForMember(int programID)
        {
            logger.InfoFormat("ReferenceDataRepository - GetTransitionProgramForMember(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                programID = programID
            }));
            var list = new List<ChildrenPrograms_Result>();

            using (DMSEntities dbContext = new DMSEntities())
            {
                var listMemberProgramChange = dbContext.MemberProgramChangeMappings.Where(a => a.FromProgramID == programID).ToList();

                foreach (var itemMemberProgramChange in listMemberProgramChange)
                {
                    var program = dbContext.Programs.Where(a => a.ID == itemMemberProgramChange.ToProgramID).FirstOrDefault();
                    if (program != null)
                    {
                        list.Add(new ChildrenPrograms_Result()
                        {
                            ProgramID = program.ID,
                            ProgramName = program.Name,
                            ClientID = program.ClientID
                        });
                    }
                }
            }
            logger.InfoFormat("ReferenceDataRepository - GetProgramForMember(), Returns:  {0}", JsonConvert.SerializeObject(new
            {
                list = list
            }));
            return list;
        }

        /// <summary>
        /// Gets the child programs.
        /// </summary>
        /// <param name="programName">Name of the program.</param>
        /// <returns></returns>
        public static List<ChildrenPrograms_Result> GetChildPrograms(string programName)
        {
            logger.InfoFormat("ReferenceDataRepository - GetChildPrograms(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                programName = programName
            }));
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.GetChildrenProgramsByName(programName).ToList<ChildrenPrograms_Result>();
                logger.InfoFormat("ReferenceDataRepository - GetChildPrograms(), Returns:  {0}", JsonConvert.SerializeObject(new
                {
                    results = results
                }));
                return results;
            }
        }

        /// <summary>
        /// Gets the country.
        /// </summary>
        /// <returns></returns>
        public static List<Country> GetCountry()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.Countries.Where(x => x.IsActive == true);
                return results.OrderBy(a => a.Sequence).ToList<Country>();
            }
        }

        public static List<Country> GetCountryTelephoneCode(bool addPR = true)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.Countries;
                var countriesFromDB = results.OrderBy(a => a.TelephoneCode).ToList<Country>();
                if (addPR)
                {
                    countriesFromDB.Add(new Country() { ISOCode = "PR", TelephoneCode = "1", Name = "Puerto Rico" });
                }
                return countriesFromDB;
            }
        }

        /// <summary>
        /// Gets the parent programs for program.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        public static List<ProgramsList> GetParentProgramsForProgram(Guid userId, string programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetPrograms(userId, null).ToList();

                if (!string.IsNullOrEmpty(programID) && !(programID.Contains("null")))
                {
                    int pID = int.Parse(programID);
                    result = result.Where(u => u.ID != pID).ToList();
                }
                return result.ToList<ProgramsList>();
            }
        }

        /// <summary>
        /// Gets the type of the vehicle.
        /// </summary>
        /// <param name="orderbyName">if set to <c>true</c> [orderby name].</param>
        /// <returns></returns>
        public static List<VehicleType> GetVehicleType(bool orderbyName = false)
        {
            List<VehicleType> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (orderbyName)
                {
                    list = dbContext.VehicleTypes.Where(u => u.IsActive == true).OrderBy(u => u.Name).ToList();
                }
                else
                {
                    list = dbContext.VehicleTypes.ToList();
                }
            }
            return list;
        }
        /// <summary>
        /// Gets the vehicle categories.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <returns></returns>
        public static List<VehicleCategory> GetVehicleCategories(string vehicleType)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from vtvc in dbContext.VehicleTypeVehicleCategories
                              join vt in dbContext.VehicleTypes on vtvc.VehicleTypeID equals vt.ID
                              join vc in dbContext.VehicleCategories on vtvc.VehicleCategoryID equals vc.ID
                              where vt.Name == vehicleType && vt.IsActive == true && vc.IsActive == true && vtvc.IsActive == true
                              select vc
                              );
                return result.ToList<VehicleCategory>();
            }
        }

        public static VehicleCategory GetVehicleCategoryByName(string vehicleCategoryName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.VehicleCategories.Where(x => x.Name == vehicleCategoryName).FirstOrDefault();
                return result;
            }
        }

        public static VehicleType GetVehicleTypeByName(string vehicleTypeName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.VehicleTypes.Where(x => x.Name == vehicleTypeName).FirstOrDefault();
                return result;
            }
        }
        /// <summary>
        /// Gets the vehicle categories.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <returns></returns>
        public static List<VehicleCategory> GetVehicleCategories(int vehicleType)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from vtvc in dbContext.VehicleTypeVehicleCategories
                              join vt in dbContext.VehicleTypes on vtvc.VehicleTypeID equals vt.ID
                              join vc in dbContext.VehicleCategories on vtvc.VehicleCategoryID equals vc.ID
                              where vt.ID == vehicleType && vt.IsActive == true && vc.IsActive == true && vtvc.IsActive == true
                              select vc
                              );
                return result.ToList<VehicleCategory>();
            }
        }

        /// <summary>
        /// Gets the vehicle categories.
        /// </summary>
        /// <returns></returns>
        public static List<VehicleCategory> GetVehicleCategories()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.VehicleCategories.Where(vc => vc.IsActive == true).OrderBy(vc => vc.Sequence);
                return result.ToList<VehicleCategory>();
            }
        }

        /// <summary>
        /// Gets the contact method.
        /// </summary>
        /// <returns></returns>
        public static List<ContactMethod> GetContactMethod()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.ContactMethods.Where(cm => cm.IsShownOnPO == true && cm.IsActive == true).OrderBy(cm => cm.Sequence);
                return result.ToList<ContactMethod>();
            }
        }
        /// <summary>
        /// Gets the contact method for send reciept.
        /// </summary>
        /// <returns></returns>
        public static List<ContactMethod> GetContactMethodForSendReciept()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.ContactMethods.Where(cm => cm.IsShownOnPayment == true && cm.IsActive == true).OrderBy(cm => cm.Sequence);
                return result.ToList<ContactMethod>();
            }
        }

        /// <summary>
        /// Gets the vehicle years.
        /// </summary>
        /// <returns></returns>
        public static List<VehicleYears_Result> GetVehicleYears()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetDistinctVehicleYears();
                return result.ToList<VehicleYears_Result>();
            }
        }


        /// <summary>
        /// Gets the vehicle make.
        /// </summary>
        /// <param name="year">The year.</param>
        /// <param name="addOther">if set to <c>true</c> [add other].</param>
        /// <returns></returns>
        public static List<MakeModel> GetVehicleMake(int vehicleTypeID, bool addOther = true)
        {
            //Other added due to business Logic.
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<MakeModel> result = (from n in dbContext.MakeModels.Where(v => v.VehicleTypeID == vehicleTypeID && v.IsActive == true).OrderBy(o => o.Make)
                                          select n).ToList<MakeModel>();
                if (addOther)
                {
                    result.Add(new MakeModel { Make = "Other" });
                }

                return result;
            }
        }

        ///// <summary>
        ///// Gets the RV make.
        ///// </summary>
        ///// <param name="addOther">if set to <c>true</c> [add other].</param>
        ///// <returns></returns>
        //public static List<RVMakeModel> GetRVMake(bool addOther = true)
        //{
        //    //Other added due to business Logic.
        //    using (DMSEntities dbContext = new DMSEntities())
        //    {
        //        List<RVMakeModel> result = dbContext.RVMakeModels.Where(r => r.IsActive == true).OrderBy(o => o.Make).ToList<RVMakeModel>();
        //        if (addOther)
        //        {
        //            result.Add(new RVMakeModel { Make = "Other" });
        //        }

        //        return result;
        //    }
        //}

        ///// <summary>
        ///// Gets the motor cycle make.
        ///// </summary>
        ///// <param name="addOther">if set to <c>true</c> [add other].</param>
        ///// <returns></returns>
        //public static List<MotorcycleMakeModel> GetMotorCycleMake(bool addOther = true)
        //{
        //    //Other added due to business Logic.
        //    using (DMSEntities dbContext = new DMSEntities())
        //    {
        //        List<MotorcycleMakeModel> result = dbContext.MotorcycleMakeModels.OrderBy(o => o.Make).ToList<MotorcycleMakeModel>();
        //        if (addOther)
        //        {
        //            result.Add(new MotorcycleMakeModel { Make = "Other" });
        //        }

        //        return result;
        //    }
        //}
        ///// <summary>
        ///// Gets the trailer make.
        ///// </summary>
        ///// <param name="addOther">if set to <c>true</c> [add other].</param>
        ///// <returns></returns>
        //public static List<TrailerMakeModel> GetTrailerMake(bool addOther = true)
        //{
        //    //Other added due to business Logic.
        //    using (DMSEntities dbContext = new DMSEntities())
        //    {
        //        List<TrailerMakeModel> result = dbContext.TrailerMakeModels.Where(t => t.IsActive == true).OrderBy(o => o.Make).ToList<TrailerMakeModel>();

        //        if (addOther)
        //        {
        //            result.Add(new TrailerMakeModel { Make = "Other" });
        //        }

        //        return result;
        //    }
        //}

        /// <summary>
        /// Gets the vehicle model.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="year">The year.</param>
        /// <param name="otherRequired">if set to <c>true</c> [other required].</param>
        /// <returns></returns>
        public static List<MakeModel> GetVehicleModel(int vehicleTypeID, string make, bool otherRequired = false)
        {
            List<MakeModel> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = (from n in dbContext.MakeModels.Where(y => y.VehicleTypeID == vehicleTypeID && y.Make == make && y.IsActive == true).OrderBy(o => o.Model)
                        select n).ToList<MakeModel>();

            }
            if (otherRequired)
            {
                if (list == null)
                {
                    list = new List<MakeModel>();
                }
                list.Add(new MakeModel() { Model = "Other" });
            }
            return list;
        }
        /// <summary>
        /// Gets the vehicle model for trailer.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="year">The year.</param>
        /// <param name="otherRequired">if set to <c>true</c> [other required].</param>
        /// <returns></returns>
        //public static List<TrailerMakeModel> GetVehicleModelForTrailer(string make, double year, bool otherRequired = false)
        //{
        //    List<TrailerMakeModel> list = null;
        //    using (DMSEntities dbContext = new DMSEntities())
        //    {
        //        list = (from n in dbContext.TrailerMakeModels.Where(y => y.Make == make && y.IsActive == true).OrderBy(o => o.Model)
        //                select n).ToList<TrailerMakeModel>();

        //    }
        //    if (otherRequired)
        //    {
        //        if (list == null)
        //        {
        //            list = new List<TrailerMakeModel>();
        //        }
        //    }
        //    list.Add(new TrailerMakeModel() { Model = "Other" });
        //    return list;
        //}

        ///// <summary>
        ///// Gets the motorcycle make.
        ///// </summary>
        ///// <param name="addOther">if set to <c>true</c> [add other].</param>
        ///// <returns></returns>
        //public static List<MotorcycleMakeModel> GetMotorcycleMake(bool addOther = true)
        //{
        //    using (DMSEntities dbContext = new DMSEntities())
        //    {
        //        var result = dbContext.MotorcycleMakeModels.Where(x => x.IsActive == true).ToList<MotorcycleMakeModel>();
        //        if (addOther)
        //        {
        //            result.Add(new MotorcycleMakeModel { Make = "Other" });
        //        }

        //        return result;
        //    }
        //}

        ///// <summary>
        ///// Gets the motorcycle model.
        ///// </summary>
        ///// <param name="Make">The make.</param>
        ///// <param name="addOther">if set to <c>true</c> [add other].</param>
        ///// <returns></returns>
        //public static List<MotorcycleMakeModel> GetMotorcycleModel(string Make, bool addOther = true)
        //{
        //    using (DMSEntities dbContext = new DMSEntities())
        //    {
        //        List<MotorcycleMakeModel> result = dbContext.MotorcycleMakeModels.Where(m => m.Make == Make && m.IsActive == true).ToList<MotorcycleMakeModel>();
        //        if (addOther)
        //        {
        //            result.Add(new MotorcycleMakeModel { Model = "Other" });
        //        }
        //        return result;
        //    }
        //}
        ///// <summary>
        ///// Gets the RV model.
        ///// </summary>
        ///// <param name="make">The make.</param>
        ///// <param name="isOtherRequired">if set to <c>true</c> [is other required].</param>
        ///// <returns></returns>
        //public static List<RVMakeModel> GetRVModel(string make, bool isOtherRequired = false)
        //{
        //    List<RVMakeModel> list = null;
        //    using (DMSEntities dbContext = new DMSEntities())
        //    {
        //        list = (from n in dbContext.RVMakeModels.Where(y => y.Make == make && y.IsActive == true).OrderBy(o => o.Model)
        //                select n).ToList<RVMakeModel>();

        //    }
        //    if (isOtherRequired)
        //    {
        //        if (list == null)
        //        {
        //            list = new List<RVMakeModel>();
        //        }
        //        list.Add(new RVMakeModel() { Model = "Other" });
        //    }
        //    return list;
        //}

        /// <summary>
        /// Gets the type of the RV.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public static List<RVType> GetRVType(string make, string model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from n in dbContext.MakeModels.Where(y => y.VehicleTypeID == 2 && y.Make == make && y.Model == model && y.IsActive == true && y.RVTypeID != null)
                              select n.RVType);
                var list = result.ToList<RVType>();
                if (list.Count > 0)
                {
                    return list;
                }
                else
                {
                    return dbContext.RVTypes.Where(r => r.IsActive == true).ToList();
                }
            }
        }

        /// <summary>
        /// Gets the type of the RV.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public static RVType GetRVType(string rvTypeName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.RVTypes.Where(y => y.Name == rvTypeName && y.IsActive == true).FirstOrDefault();
                return result;
            }
        }
        /// <summary>
        /// Gets the contact action.
        /// </summary>
        /// <param name="category">The category.</param>
        /// <returns></returns>
        public static List<ContactAction> GetContactAction(string category)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from n in dbContext.ContactActions.Where(y => y.ContactCategory.Name == category && y.IsActive == true && y.IsShownOnScreen == true).OrderBy(o => o.Sequence)
                              select n);

                return result.ToList<ContactAction>();
            }
        }
        /// <summary>
        /// Gets the contact reasons.
        /// </summary>
        /// <param name="category">The category.</param>
        /// <returns></returns>
        public static List<ContactReason> GetContactReasons(string category)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from n in dbContext.ContactReasons.Where(y => y.ContactCategory.Name == category && y.IsActive == true && y.IsShownOnScreen == true).OrderBy(o => o.Sequence)
                              select n);

                return result.ToList<ContactReason>();
            }
        }
        /// <summary>
        /// Gets the contact source.
        /// </summary>
        /// <param name="category">The category.</param>
        /// <returns></returns>
        public static List<ContactSource> GetContactSource(string category)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from n in dbContext.ContactSources.Where(y => y.ContactCategory.Name == category && y.IsActive == true).OrderBy(o => o.Sequence)

                              select n
                              );

                return result.ToList<ContactSource>();
            }
        }

        /// <summary>
        /// Gets the contact category.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public static ContactCategory GetContactCategory(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContactCategories.Where(x => x.Name == name).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the contact method.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public static ContactMethod GetContactMethod(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContactMethods.Where(x => x.Name == name).FirstOrDefault();
            }
        }
        /// <summary>
        /// Get Call Types
        /// </summary>
        /// <returns></returns>
        public static List<CallType> GetCallTypes()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.CallTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList<CallType>();
            }
        }
        /// <summary>
        /// Return List of Language
        /// </summary>
        /// <returns></returns>
        public static List<Language> GetLanguage()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Languages.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList<Language>();
            }
        }

        /// <summary>
        /// Gets the users.
        /// </summary>
        /// <returns></returns>
        public static List<aspnet_Users> GetUsers(string applicationName = "")
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (string.IsNullOrEmpty(applicationName))
                {
                    return dbContext.aspnet_Users.Where(u => u.aspnet_Membership.IsApproved == true).OrderBy(u => u.UserName).ToList<aspnet_Users>();
                }
                else
                {
                    return dbContext.aspnet_Users.Where(u => u.aspnet_Membership.IsApproved == true && u.aspnet_Applications.ApplicationName.Equals(applicationName)).OrderBy(u => u.UserName).ToList<aspnet_Users>();
                }
            }
        }

        /// <summary>
        /// Gets the history search criteria name section users.
        /// </summary>
        /// <returns></returns>
        public static List<aspnet_Users> GetHistorySearchCriteriaNameSectionUsers()
        {
            List<aspnet_Users> users = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                users = (from f in dbContext.aspnet_Users
                         join u in dbContext.Users on f.UserId equals u.aspnet_UserID
                         join m in dbContext.aspnet_Membership on f.UserId equals m.UserId
                         where m.IsApproved == true
                         orderby f.UserName
                         select f).ToList();
            }

            return users;
        }
        /// <summary>
        /// Get Custom Colors
        /// </summary>
        /// <returns></returns>
        public static List<VehicleColor> GetColors()
        {
            List<VehicleColor> list = new List<VehicleColor>();
            list.Add(new VehicleColor() { Name = "Beige", Value = "Beige" });
            list.Add(new VehicleColor() { Name = "Black", Value = "Black" });
            list.Add(new VehicleColor() { Name = "Blue", Value = "Blue" });
            list.Add(new VehicleColor() { Name = "Brown", Value = "Brown" });
            list.Add(new VehicleColor() { Name = "Burgundy", Value = "Burgundy" });
            list.Add(new VehicleColor() { Name = "Charcoal", Value = "Charcoal" });
            list.Add(new VehicleColor() { Name = "Gold", Value = "Gold" });
            list.Add(new VehicleColor() { Name = "Gray", Value = "Gray" });
            list.Add(new VehicleColor() { Name = "Green", Value = "Green" });
            list.Add(new VehicleColor() { Name = "Off White", Value = "Off White" });
            list.Add(new VehicleColor() { Name = "Orange", Value = "Orange" });
            list.Add(new VehicleColor() { Name = "Pink", Value = "Pink" });
            list.Add(new VehicleColor() { Name = "Purple", Value = "Purple" });
            list.Add(new VehicleColor() { Name = "Red", Value = "Red" });
            list.Add(new VehicleColor() { Name = "Silver", Value = "Silver" });
            list.Add(new VehicleColor() { Name = "Tan", Value = "Tan" });
            list.Add(new VehicleColor() { Name = "Turquoise", Value = "Turquoise" });
            list.Add(new VehicleColor() { Name = "White", Value = "White" });
            // CR: 1071 : Added yellow to the list
            list.Add(new VehicleColor() { Name = "Yellow", Value = "Yellow" });
            return list;

        }


        /// <summary>
        /// Gets the PO time filter values.
        /// </summary>
        /// <returns></returns>
        public static Dictionary<string, string> GetPOTimeFilterValues()
        {
            Dictionary<string, string> list = new Dictionary<string, string>();
            list.Add("1w", "1 week");
            list.Add("1m", "1 month");
            list.Add("3m", "3 months");
            list.Add("3m+", "Over 3 months");

            return list;
        }

        /// <summary>
        /// Gets the mileage UOM.
        /// </summary>
        /// <returns></returns>
        public static Dictionary<string, string> GetMileageUOM()
        {
            Dictionary<string, string> list = new Dictionary<string, string>();
            list.Add("Miles", "Miles");
            list.Add("Kilometers", "Kilometers");

            return list;
        }

        public static Dictionary<string, string> GetWarrantyPeriodUOM()
        {
            Dictionary<string, string> list = new Dictionary<string, string>();
            list.Add("Months", "Months");
            list.Add("Years", "Years");

            return list;
        }

        /// <summary>
        /// Gets the address types.
        /// </summary>
        /// <param name="entityType">Type of the entity.</param>
        /// <returns></returns>
        public static List<AddressType> GetAddressTypes(string entityType, string[] typesToExclude = null)
        {
            List<AddressType> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = (from at in dbContext.AddressTypes
                        join ate in dbContext.AddressTypeEntities on at.ID equals ate.AddressTypeID
                        where (ate.Entity.Name == entityType &&
                                ate.IsShownOnScreen == true && at.IsActive == true)
                        orderby ate.Sequence
                        select at).ToList<AddressType>();

                if (typesToExclude != null && typesToExclude.Length > 0)
                {
                    list = (from l in list
                            where !typesToExclude.Contains(l.Name)
                            select l).ToList();
                }

            }
            return list;
        }


        /// <summary>
        /// Gets the PO details products.
        /// </summary>
        /// <returns></returns>
        public static List<Product> GetPODetailsProducts()
        {
            //orderby p.ProductCategoryID, p.Name
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = (from p in dbContext.Products
                            join pt in dbContext.ProductTypes on p.ProductTypeID equals pt.ID
                            where (pt.Name == "Service" && p.IsActive == true && pt.IsActive == true && p.IsShowOnPO == true)
                            orderby p.Name
                            select p).ToList<Product>();
                return list;
            }
        }

        /// <summary>
        /// Gets the prodct rate.
        /// </summary>
        /// <param name="productID">The product ID.</param>
        /// <returns></returns>
        public static List<RateType> GetProdctRate(int? productID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = (from rt in dbContext.RateTypes
                            join prt in dbContext.ProductRateTypes on rt.ID equals prt.RateTypeID
                            where (prt.ProductID == productID)
                            select rt).ToList<RateType>();
                return list;

            }
        }

        /// <summary>
        /// Gets the product by id.
        /// </summary>
        /// <param name="productID">The product ID.</param>
        /// <returns></returns>
        public static Product GetProductById(int? productID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var p = dbContext.Products.Where(x => x.ID == productID).FirstOrDefault();
                return p;

            }
        }

        /// <summary>
        /// Gets the PO cancel reason.
        /// </summary>
        /// <returns></returns>
        public static List<PurchaseOrderCancellationReason> GetPOCancelReason()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                List<PurchaseOrderCancellationReason> listValues = entities.PurchaseOrderCancellationReasons.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList<PurchaseOrderCancellationReason>();
                return listValues;
            }
        }

        /// <summary>
        /// Gets the phone types.
        /// </summary>
        /// <param name="entityType">Type of the entity.</param>
        /// <returns></returns>
        public static List<PhoneType> GetPhoneTypes(string entityType, string[] typesToExclude = null)
        {
            List<PhoneType> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {

                list = (from pt in dbContext.PhoneTypes
                        join pte in dbContext.PhoneTypeEntities on pt.ID equals pte.PhoneTypeID
                        where (pte.Entity.Name == entityType &&
                                pte.IsShownOnScreen == true && pt.IsActive == true)
                        orderby pte.Sequence
                        select pt).ToList<PhoneType>();

                if (typesToExclude != null && typesToExclude.Length > 0)
                {

                    list = (from l in list
                            where !typesToExclude.Contains(l.Name)
                            select l).ToList();
                }

            }
            return list;
        }

        /// <summary>
        /// Gets the type of the trailer.
        /// </summary>
        /// <returns></returns>
        public static List<TrailerType> GetTrailerType()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                List<TrailerType> listValues = entities.TrailerTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList<TrailerType>();
                return listValues;
            }
        }
        /// <summary>
        /// Gets the type of the hitch.
        /// </summary>
        /// <returns></returns>
        public static List<HitchType> GetHitchType()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                List<HitchType> listValues = entities.HitchTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList<HitchType>();
                return listValues;
            }
        }
        /// <summary>
        /// Gets the size of the ball.
        /// </summary>
        /// <returns></returns>
        public static List<BallSize> GetBallSize()
        {
            List<BallSize> ballSize = new List<BallSize>();
            ballSize.Add(new BallSize() { ID = "1 7/8", Name = "1 7/8" });
            ballSize.Add(new BallSize() { ID = "2", Name = "2" });
            ballSize.Add(new BallSize() { ID = "2 5/16", Name = "2 5/16" });
            ballSize.Add(new BallSize() { ID = "Other", Name = "Other" });
            return ballSize;
        }

        /// <summary>
        /// Gets the contact category.
        /// </summary>
        /// <returns></returns>
        public static List<ContactCategory> GetContactCategory()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                List<ContactCategory> listValues = entities.ContactCategories.Where(c => c.IsActive == true && (c.IsShownOnFinish != false || c.IsShownOnFinish == null)).OrderBy(c => c.Sequence).ToList<ContactCategory>();
                return listValues;
            }
        }

        public static List<ContactCategory> GetContactCategoryForAddContact()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                List<ContactCategory> listValues = entities.ContactCategories.Where(c => c.IsActive == true && c.IsShownOnActivity == true).OrderBy(c => c.Sequence).ToList<ContactCategory>();
                return listValues;
            }
        }
        /// <summary>
        /// Services the request status.
        /// </summary>
        /// <returns></returns>
        public static List<ServiceRequestStatu> ServiceRequestStatus()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                List<ServiceRequestStatu> listValues = entities.ServiceRequestStatus.Where(c => c.IsActive == true).OrderBy(c => c.Sequence).ToList<ServiceRequestStatu>();
                return listValues;
            }
        }

        /// <summary>
        /// Nexts the actions.
        /// </summary>
        /// <returns></returns>
        public static List<NextAction> NextActions()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                List<NextAction> listValues = entities.NextActions.Where(c => c.IsActive == true).OrderBy(c => c.Name).ToList<NextAction>();
                return listValues;
            }
        }

        /// <summary>
        /// Nexts the actions.
        /// </summary>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public static List<NextAction> NextActions(string entityName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Entity theEntity = dbContext.Entities.Where(u => u.Name.Equals(entityName)).FirstOrDefault();
                if (theEntity == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Entity Name {0}", entityName));
                }
                List<NextAction> listValues = (from nextAction in dbContext.NextActions
                                               join nextActionEntity in dbContext.NextActionEntities
                                               on nextAction.ID equals nextActionEntity.NextActionID
                                               where nextActionEntity.EntityID == theEntity.ID &&
                                               nextActionEntity.IsShownOnScreen == true &&
                                               nextAction.IsActive == true
                                               select nextAction).OrderBy(u => u.Name).ToList();

                return listValues;
            }
        }

        /// <summary>
        /// Gets the axles.
        /// </summary>
        /// <returns></returns>
        public static List<AxlesEntity> GetAxles()
        {
            List<AxlesEntity> axlesList = new List<AxlesEntity>();
            axlesList.Add(new AxlesEntity() { ID = 1, Name = "1" });
            axlesList.Add(new AxlesEntity() { ID = 2, Name = "2" });
            axlesList.Add(new AxlesEntity() { ID = 3, Name = "3" });
            axlesList.Add(new AxlesEntity() { ID = 4, Name = "4" });
            return axlesList;
        }


        /// <summary>
        /// Gets the assigned to.
        /// </summary>
        /// <returns></returns>
        public static List<User> GetAssignedTo()
        {
            List<User> assignedTo = new List<User>();
            using (DMSEntities db = new DMSEntities())
            {
                assignedTo = db.GetAssignedTo().ToList<User>();
                return assignedTo;
            }
        }

        public static List<UsersListForRole_Result> GetUsersListForRole(Guid roleID)
        {
            List<UsersListForRole_Result> assignedTo = new List<UsersListForRole_Result>();
            using (DMSEntities db = new DMSEntities())
            {
                assignedTo = db.GetUsersListForRole(roleID).ToList<UsersListForRole_Result>();
                return assignedTo;
            }
        }


        /// <summary>
        /// Gets the closed loop stuses.
        /// </summary>
        /// <returns></returns>
        public static List<ClosedLoopStatu> GetClosedLoopStuses()
        {
            using (DMSEntities db = new DMSEntities())
            {
                List<ClosedLoopStatu> closedLoopSatus = db.ClosedLoopStatus.Where(c => c.IsActive == true).OrderBy(c => c.Sequence).ToList<ClosedLoopStatu>();
                return closedLoopSatus;
            }
        }
        /// <summary>
        /// Gets the payment types.
        /// </summary>
        /// <returns></returns>
        public static List<PaymentType> GetPaymentTypes()
        {
            using (DMSEntities db = new DMSEntities())
            {
                logger.Info("Loading payment types");
                var paymentTypes = (from pt in db.PaymentTypes
                                    join pc in db.PaymentCategories on pt.PaymentCategoryID equals pc.ID
                                    where (pt.IsActive == true && pc.Name == "CreditCard")
                                    orderby pt.Sequence
                                    select pt).ToList<PaymentType>();
                return paymentTypes;
            }
        }

        /// <summary>
        /// Gets the currency types.
        /// </summary>
        /// <returns></returns>
        public static List<CurrencyType> GetCurrencyTypes()
        {
            using (DMSEntities db = new DMSEntities())
            {
                logger.Info("Loading currency types");
                List<CurrencyType> currencyType = db.CurrencyTypes.Where(c => c.IsActive == true).OrderBy(c => c.Sequence).ToList<CurrencyType>();
                return currencyType;
            }
        }
        /// <summary>
        /// Gets the payment reasons.
        /// </summary>
        /// <param name="transactionTypeID">The transaction type ID.</param>
        /// <returns></returns>
        public static List<PaymentReason> GetPaymentReasons(int transactionTypeID)
        {
            using (DMSEntities db = new DMSEntities())
            {
                logger.Info("Loading payment reasons");
                var paymentReason = (from pr in db.PaymentReasons
                                     where pr.IsActive == true && pr.PaymentTransactionTypeID == transactionTypeID
                                     select pr).OrderBy(p => p.Sequence).ToList<PaymentReason>();

                return paymentReason;
            }
        }

        /// <summary>
        /// Gets the service member pay mode.
        /// </summary>
        /// <returns></returns>
        public static List<PaymentType> GetServiceMemberPayMode()
        {
            using (DMSEntities db = new DMSEntities())
            {
                BillTo billto = db.BillToes.Where(p => p.Name.Equals("Member")).FirstOrDefault();
                List<PaymentType> paymentType = (from fbtpt in db.BillToPaymentTypes
                                                 join pt in db.PaymentTypes on fbtpt.PaymentTypeID equals pt.ID
                                                 where fbtpt.BillToID.Value == billto.ID
                                                 where pt.IsActive == true && fbtpt.IsActive == true
                                                 select pt
                                                 ).OrderBy(p => p.Sequence).ToList<PaymentType>();
                return paymentType;
            }
        }




        /// <summary>
        /// Gets the ETA.
        /// </summary>
        /// <returns></returns>
        public static Dictionary<string, string> GetETA()
        {
            Dictionary<string, string> list = new Dictionary<string, string>();
            list.Add("15", "15 mins");
            list.Add("30", "30 mins");
            list.Add("45", "45 mins");
            list.Add("60", "60 mins");
            list.Add("75", "75 mins");
            list.Add("90", "90 mins");
            list.Add("120", "120 mins");

            return list;
        }

        /// <summary>
        /// Gets the member pay types.
        /// </summary>
        /// <returns></returns>
        public static List<PaymentType> GetMemberPayTypes()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from btpt in dbContext.BillToPaymentTypes
                              join pt in dbContext.PaymentTypes on btpt.PaymentTypeID equals pt.ID
                              where pt.IsActive == true
                              && btpt.BillTo.Name == "Member"
                              && btpt.IsActive == true
                              orderby btpt.Sequence
                              select pt).ToList<PaymentType>();
                return result;

            }
        }

        /// <summary>
        /// Gets the bill to.
        /// </summary>
        /// <param name="billToName">Name of the bill to.</param>
        /// <returns></returns>
        public static int? GetBillTo(string billToName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.BillToes.Where(bt => bt.Name == billToName).FirstOrDefault<BillTo>();
                if (result != null)
                {
                    return result.ID;
                }
            }
            return null;

        }

        /// <summary>
        /// Gets the product category by id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public static ProductCategory GetProductCategoryById(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.ProductCategories.Where(x => x.ID == id).FirstOrDefault();
                return result;
            }
        }

        /// <summary>
        /// Gets the name of the product category by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public static ProductCategory GetProductCategoryByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.ProductCategories.Where(x => x.Name == name).FirstOrDefault<ProductCategory>();
                return result;
            }
        }


        /// <summary>
        /// Gets the product categories.
        /// </summary>
        /// <param name="orderbyName">if set to <c>true</c> [orderby name].</param>
        /// <returns></returns>
        public static List<ProductCategory> GetProductCategories(bool orderbyName = true)
        {
            List<ProductCategory> listValues = null;
            using (DMSEntities entities = new DMSEntities())
            {
                if (orderbyName)
                {
                    listValues = entities.ProductCategories.Where(x => x.IsActive == true).OrderBy(a => a.Name).ToList<ProductCategory>();

                }
                else
                {
                    listValues = entities.ProductCategories.Where(x => x.IsActive == true).OrderBy(a => a.Sequence).ToList<ProductCategory>();
                }
                return listValues;
            }
        }

        /// <summary>
        /// Gets the unit of measure.
        /// </summary>
        /// <returns></returns>
        public static List<GetUnitOfMeasures_Result> GetUnitOfMeasure()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                List<GetUnitOfMeasures_Result> listValues = entities.GetUnitOfMeasures().ToList<GetUnitOfMeasures_Result>();
                return listValues;
            }
        }

        /// <summary>
        /// Gets the PO copy product.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <param name="vehicleCatagory">The vehicle catagory.</param>
        /// <returns></returns>
        public static List<Product> GetPOCopyProduct(int? vehicleType, int? vehicleCatagory, int? programID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                List<Product> listValues = entities.GetPOCopyProducts(vehicleType, vehicleCatagory, programID).ToList<Product>();
                return listValues;
            }
        }

        /// <summary>
        /// RVs the type default weight.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <param name="rvtypeId">The rvtype id.</param>
        /// <returns></returns>
        public static int? RVTypeDefaultWeight(int vehicleTypeId, string make, string model, int rvtypeId)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                MakeModel rvMM = entities.MakeModels.Where(rv => rv.VehicleTypeID == vehicleTypeId && rv.Make == make && rv.Model == model && (rvtypeId == 0 || rv.RVTypeID == rvtypeId)).FirstOrDefault<MakeModel>();
                if (rvMM != null)
                {
                    return rvMM.VehicleCategoryID;
                }
            }
            return null;
        }

        /// <summary>
        /// Motorcycles the default weight.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        //public static int? MotorcycleDefaultWeight(string make, string model)
        //{
        //    using (DMSEntities entities = new DMSEntities())
        //    {
        //        MotorcycleMakeModel motorcycleMM = entities.MotorcycleMakeModels.Where(m => m.Make == make && m.Model == model).FirstOrDefault<MotorcycleMakeModel>();
        //        if (motorcycleMM != null)
        //        {
        //            return motorcycleMM.VehicleCategoryID;
        //        }
        //    }
        //    return null;
        //}

        /// <summary>
        /// Trailers the default weight.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        //public static int? TrailerDefaultWeight(string make, string model)
        //{
        //    using (DMSEntities entities = new DMSEntities())
        //    {
        //        TrailerMakeModel trailerMM = entities.TrailerMakeModels.Where(m => m.Make == make && m.Model == model).FirstOrDefault<TrailerMakeModel>();
        //        if (trailerMM != null)
        //        {
        //            return trailerMM.VehicleCategoryID;
        //        }
        //    }
        //    return null;
        //}

        /// <summary>
        /// Autoes the default weight.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public static int GetVehicleTypeDefaultWeight(int vehicleTypeId, string make, string model)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                MakeModel autoMM = entities.MakeModels.Where(m => m.VehicleTypeID == vehicleTypeId && m.Make == make && m.Model == model).FirstOrDefault<MakeModel>();
                if (autoMM != null)
                {
                    return autoMM.VehicleCategoryID ?? 1;
                }
            }
            return 1; // LightDuty
        }

        /// <summary>
        /// Gets the vehicle validation rule.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public static List<ProgramInformation_Result> GetVehicleValidationRule(int programId)
        {
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var result = repository.GetProgramInfo(programId, "Vehicle", "Validation");

            return result.Where(x => x.Value.Equals("Yes", StringComparison.InvariantCultureIgnoreCase)).ToList<ProgramInformation_Result>();
        }
        /// <summary>
        /// Gets the DB audit.
        /// </summary>
        /// <returns></returns>
        public static List<DBAudit> GetDBAudit()
        {
            List<DBAudit> returnValue = new List<DBAudit>();
            using (DMSEntities entities = new DMSEntities())
            {
                returnValue = entities.DBAudits.ToList<DBAudit>();
            }
            return returnValue;
        }

        /// <summary>
        /// Gets the GOA reason.
        /// </summary>
        /// <returns></returns>
        public static List<PurchaseOrderGOAReason> GetGOAReason()
        {
            List<PurchaseOrderGOAReason> returnValue = new List<PurchaseOrderGOAReason>();
            using (DMSEntities entities = new DMSEntities())
            {
                returnValue = entities.PurchaseOrderGOAReasons.Where(r => r.IsActive == true).OrderBy(r => r.Sequence).ToList<PurchaseOrderGOAReason>();
            }
            return returnValue;
        }

        /// <summary>
        /// Gets the roles that can change dollar limit.
        /// </summary>
        /// <returns></returns>
        public static string GetRolesThatCanChangeDollarLimit()
        {
            string returnValue = string.Empty;
            using (DMSEntities entities = new DMSEntities())
            {
                ApplicationConfiguration appConfig = entities.ApplicationConfigurations.Where(app => app.ApplicationConfigurationTypeID == 1 && app.Name == "RolesThatCanChangeDollarLimit").FirstOrDefault<ApplicationConfiguration>();
                if (appConfig != null)
                {
                    returnValue = appConfig.Value;
                }
            }
            return returnValue;
        }

        /// <summary>
        /// Gets the type of the history search criteria ID section.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntity> GetHistorySearchCriteriaIDSectionType()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            list.Add(new DropDownEntity() { ID = 1, Name = "Service Request" });
            list.Add(new DropDownEntity() { ID = 2, Name = "Purchase Order" });
            list.Add(new DropDownEntity() { ID = 3, Name = "ISP" });
            list.Add(new DropDownEntity() { ID = 4, Name = "Member" });
            list.Add(new DropDownEntity() { ID = 5, Name = "VIN" });
            list.Add(new DropDownEntity() { ID = 6, Name = "Contact Phone Number" });
            return list;
        }
        /// <summary>
        /// Gets the type of the history search criteria name section.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntity> GetHistorySearchCriteriaNameSectionType()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            list.Add(new DropDownEntity() { ID = 1, Name = "ISP" });
            list.Add(new DropDownEntity() { ID = 2, Name = "Member" });
            list.Add(new DropDownEntity() { ID = 3, Name = "User" });
            return list;
        }
        /// <summary>
        /// Gets the type of the history search criteria name filter.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntity> GetHistorySearchCriteriaNameFilterType()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            list.Add(new DropDownEntity() { ID = 1, Name = "Is equal to" });
            list.Add(new DropDownEntity() { ID = 2, Name = "Starts with" });
            list.Add(new DropDownEntity() { ID = 3, Name = "Contains" });
            list.Add(new DropDownEntity() { ID = 3, Name = "Ends with" });
            return list;
        }

        /// <summary>
        /// Gets the type of the vendor search criteria name filter.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntity> GetVendorSearchCriteriaNameFilterType()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            list.Add(new DropDownEntity() { ID = 2, Name = "Is equal to" });
            list.Add(new DropDownEntity() { ID = 4, Name = "Begins with" });
            list.Add(new DropDownEntity() { ID = 6, Name = "Contains" });
            list.Add(new DropDownEntity() { ID = 5, Name = "Ends with" });
            return list;
        }

        public static List<DropDownEntityForString> GetCustomerFeedbackSearchCriteriaNameFilterType()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Is equal to", Value = "Is equal to" });
            list.Add(new DropDownEntityForString() { Text = "Begins with", Value = "Begins With" });
            list.Add(new DropDownEntityForString() { Text = "Contains", Value = "Contains" });
            list.Add(new DropDownEntityForString() { Text = "Ends with", Value = "Ends With" });
            return list;
        }

        public static List<DropDownEntityForString> GetSearchFilterType()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Is equal to", Value = "eq" });
            list.Add(new DropDownEntityForString() { Text = "Begins with", Value = "begins" });
            list.Add(new DropDownEntityForString() { Text = "Contains", Value = "contains" });
            list.Add(new DropDownEntityForString() { Text = "Ends with", Value = "endwith" });
            return list;
        }

        public static List<DropDownEntityForString> GetCustomerFeedbackSearchCriteriaValueMemberType()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Member First Name", Value = "Member First Name" });
            list.Add(new DropDownEntityForString() { Text = "Member Last Name", Value = "Member Last Name" });
            return list;
        }

        public static List<DropDownEntityForString> GetCustomerFeedbackSearchCriteriaNamesurveyFilterType()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Is equal to", Value = "Is equal to" });
            list.Add(new DropDownEntityForString() { Text = "Begins with", Value = "Begins with" });
            list.Add(new DropDownEntityForString() { Text = "Contains", Value = "Contains" });
            list.Add(new DropDownEntityForString() { Text = "Ends with", Value = "Ends With" });
            return list;
        }


        /// <summary>
        /// Gets the history search criteria date preset.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntity> GetHistorySearchCriteriaDatePreset()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            list.Add(new DropDownEntity() { ID = 1, Name = "Last 7 days" });
            list.Add(new DropDownEntity() { ID = 2, Name = "Last 30 days" });
            list.Add(new DropDownEntity() { ID = 3, Name = "Last 90 days" });
            return list;
        }

        public static List<DropDownEntity> GetTemporaryCCSearchCriteriaDatePreset()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            list.Add(new DropDownEntity() { ID = 1, Name = "Last 60 days" });
            list.Add(new DropDownEntity() { ID = 2, Name = "Last 120 days" });
            list.Add(new DropDownEntity() { ID = 3, Name = "Last 180 days" });
            return list;
        }

        public static List<DropDownEntity> GetVendorInvoiceSearchCriteriaDatePreset()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            list.Add(new DropDownEntity() { ID = 0, Name = "All" });
            list.Add(new DropDownEntity() { ID = 1, Name = "Last 7 days" });
            list.Add(new DropDownEntity() { ID = 2, Name = "Last 30 days" });
            list.Add(new DropDownEntity() { ID = 3, Name = "Last 90 days" });
            return list;
        }
        /// <summary>
        /// Gets the history search criteria special.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntity> GetHistorySearchCriteriaSpecial()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            list.Add(new DropDownEntity() { ID = 1, Name = "GOA" });
            list.Add(new DropDownEntity() { ID = 2, Name = "Re-Dispatch" });
            list.Add(new DropDownEntity() { ID = 3, Name = "Possible Tow" });
            list.Add(new DropDownEntity() { ID = 4, Name = "Member CC Payment" });
            return list;
        }

        /// <summary>
        /// Gets the purchase order status.
        /// </summary>
        /// <returns></returns>
        public static List<PurchaseOrderStatu> GetPurchaseOrderStatus()
        {
            using (DMSEntities dbConext = new DMSEntities())
            {
                return dbConext.PurchaseOrderStatus.Where(i => i.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }
        /// <summary>
        /// Gets the type of the history search criteria payment.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntity> GetHistorySearchCriteriaPaymentType()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            list.Add(new DropDownEntity() { ID = 1, Name = "Company Check/DirectDeposit" });
            list.Add(new DropDownEntity() { ID = 2, Name = "Company Credit Card" });
            list.Add(new DropDownEntity() { ID = 3, Name = "Member Paid" });
            return list;
        }

        /// <summary>
        /// Gets the history search criteria vehicle make model year.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForYears> GetHistorySearchCriteriaVehicleMakeModelYear()
        {
            using (DMSEntities dbConext = new DMSEntities())
            {
                List<DropDownEntityForYears> result = dbConext.VehicleMakeModels.Select(m => new DropDownEntityForYears
                {
                    Value = m.Year,
                    Text = m.Year
                }
                                                    )
                                                    .Distinct()
                                                    .Where(u => u.Text.HasValue)
                                                    .OrderByDescending(u => u.Value)
                                                    .ToList();

                return result;
            }
        }

        /// <summary>
        /// Gets the history search criteria make.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <param name="year">The year.</param>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetHistorySearchCriteriaMake(int vehicleTypeId)
        {
            List<DropDownEntityForString> list = null;
            using (DMSEntities dbConext = new DMSEntities())
            {
                list = dbConext.MakeModels.Where(u => u.VehicleTypeID == vehicleTypeId)
                                                         .Select(m => new DropDownEntityForString
                                                         {
                                                             Text = m.Make,
                                                             Value = m.Make
                                                         })
                        .Distinct()
                        .OrderBy(u => u.Text)
                        .ToList();
            }
            if (list != null)
            {
                list.Add(new DropDownEntityForString { Text = "Other", Value = "Other" });
            }
            return list;
        }
        /// <summary>
        /// Gets the history search criteria programs.
        /// </summary>
        /// <param name="clientID">The client ID.</param>
        /// <returns></returns>
        public static List<Program> GetHistorySearchCriteriaPrograms(int[] clientID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = (from p in dbContext.Programs
                               where clientID.Contains(p.ClientID.HasValue ? p.ClientID.Value : -1)
                               select p).Where(p => p.IsActive == true && p.IsGroup == false).OrderBy(u => u.Name);
                return results.ToList<Program>();
            }
        }
        /// <summary>
        /// Gets the history search criteria model.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <param name="make">The make.</param>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetHistorySearchCriteriaModel(int vehicleTypeId, string make)
        {
            List<DropDownEntityForString> list = null;
            using (DMSEntities dbConext = new DMSEntities())
            {
                list = dbConext.MakeModels.Where(u => u.VehicleTypeID == vehicleTypeId && u.Make.Equals(make, StringComparison.InvariantCultureIgnoreCase))
                                                         .Select(m => new DropDownEntityForString
                                                         {
                                                             Text = m.Model,
                                                             Value = m.Model
                                                         })
                        .Distinct()
                        .OrderBy(u => u.Text)
                        .ToList();
            }
            if (list != null)
            {
                list.Add(new DropDownEntityForString { Text = "Other", Value = "Other" });
            }
            return list;
        }

        /// <summary>
        /// Gets the vendor source types.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntity> GetVendorSourceTypes()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<DropDownEntity> list = null;
                list = (from cs in dbContext.ContactMethods
                        where cs.IsShownOnVendor == true
                        select new DropDownEntity
                        {
                            ID = cs.ID,
                            Name = cs.Name
                        }).ToList<DropDownEntity>();
                return list;
            }
        }

        /// <summary>
        /// Gets the vendor status.
        /// </summary>
        /// <returns></returns>
        public static List<VendorStatu> GetVendorStatus()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorStatus.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the vendor region.
        /// </summary>
        /// <returns></returns>
        public static List<VendorRegion> GetVendorRegion()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorRegions.OrderBy(u => u.Name).ToList();
            }
        }

        /// <summary>
        /// Gets the vendor status.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public static VendorStatu GetVendorStatus(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorStatus.Where(u => u.IsActive == true && u.Name == name).OrderBy(u => u.Sequence).FirstOrDefault();
            }
        }
        /// <summary>
        /// Gets the member management status.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetMemberManagementStatus()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Active", Value = "Active" });
            list.Add(new DropDownEntityForString() { Text = "Inactive", Value = "Inactive" });
            return list;
        }
        /// <summary>
        /// Gets the vendor location status.
        /// </summary>
        /// <returns></returns>
        public static List<VendorLocationStatu> GetVendorLocationStatus()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorLocationStatus.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the source system by ID.
        /// </summary>
        /// <param name="sourceSystemID">The source system ID.</param>
        /// <returns></returns>
        public static SourceSystem GetSourceSystemByID(int sourceSystemID)
        {
            SourceSystem model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.SourceSystems.Where(u => u.ID == sourceSystemID).FirstOrDefault();
            }
            return model;
        }


        /// <summary>
        /// Gets source system by name.
        /// </summary>
        /// <param name="sourceSystem">The source system.</param>
        /// <returns></returns>
        public static SourceSystem GetSourceSystemByName(string sourceSystem)
        {
            SourceSystem model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.SourceSystems.Where(u => u.Name == sourceSystem).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the vendor status change reason.
        /// </summary>
        /// <returns></returns>
        public static List<VendorStatusReason> GetVendorStatusChangeReason()
        {
            using (DMSEntities dboContext = new DMSEntities())
            {
                return dboContext.VendorStatusReasons.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }
        /// <summary>
        /// Gets the ACH account types.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetACHAccountTypes()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Checking", Value = "Checking" });
            list.Add(new DropDownEntityForString() { Text = "Saving", Value = "Saving" });
            return list;
        }

        /// <summary>
        /// Gets the ACH status.
        /// </summary>
        /// <returns></returns>
        public static List<ACHStatu> GetACHStatus()
        {
            using (DMSEntities dboContext = new DMSEntities())
            {
                return dboContext.ACHStatus.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }
        /// <summary>
        /// Gets the ACH reciept method.
        /// </summary>
        /// <returns></returns>
        public static List<ContactMethod> GetACHRecieptMethod()
        {
            using (DMSEntities dboContext = new DMSEntities())
            {
                return dboContext.ContactMethods.Where(u => u.IsActive == true && u.IsShownOnVendor == true && u.Name.Contains("Mail")).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the comments types.
        /// </summary>
        /// <returns></returns>
        public static List<CommentType> GetCommentsTypes()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.CommentTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the referral sources.
        /// </summary>
        /// <returns></returns>
        public static List<VendorApplicationReferralSource> GetReferralSources()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorApplicationReferralSources.Where(v => v.IsActive == true).OrderBy(v => v.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the vendor contract status.
        /// </summary>
        /// <returns></returns>
        public static List<ContractStatu> GetVendorContractStatus()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContractStatus.Where(v => v.IsActive == true).OrderBy(v => v.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the vendor contract rate schedule status.
        /// </summary>
        /// <returns></returns>
        public static List<ContractRateScheduleStatu> GetVendorContractRateScheduleStatus()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContractRateScheduleStatus.Where(v => v.IsActive == true).OrderBy(v => v.Sequence).ToList();
            }
        }


        /// <summary>
        /// Gets the vendor term agreements.
        /// </summary>
        /// <returns></returns>
        public static List<VendorTermsAgreement> GetVendorTermAgreements()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorTermsAgreements.Where(v => v.IsActive == true).OrderBy(v => v.EffectiveDate).ToList();
            }
        }
        /// <summary>
        /// Gets the vendor info tax classifications.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetVendorInfoTaxClassifications()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Individual / Sole Proprietor", Value = "Individual / Sole Proprietor" });
            list.Add(new DropDownEntityForString() { Text = "Corporation", Value = "Corporation" });
            list.Add(new DropDownEntityForString() { Text = "Partnership", Value = "Partnership" });
            list.Add(new DropDownEntityForString() { Text = "Other", Value = "Other" });
            return list;
        }

        /// <summary>
        /// Vendors the portal contact us subject.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> VendorPortalContactUsSubject()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Comment", Value = "Comment" });
            list.Add(new DropDownEntityForString() { Text = "Question", Value = "Question" });
            list.Add(new DropDownEntityForString() { Text = "Other", Value = "Other" });
            return list;
        }


        /// <summary>
        /// Gets the rate schedules related to contract.
        /// </summary>
        /// <param name="iContractID">The i contract ID.</param>
        /// <returns></returns>
        public List<ContractRateSchedule> GetRateSchedulesRelatedToContract(int iContractID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContractRateSchedules.OrderBy(a => a.StartDate).Where(a => a.ContractID == iContractID && a.IsActive == true).ToList<ContractRateSchedule>();
            }
        }

        /// <summary>
        /// Gets the addressfor entity.
        /// </summary>
        /// <param name="EntityName">Name of the entity.</param>
        /// <returns></returns>
        public static List<AddressType> GetAddressforEntity(string EntityName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = (from at in dbContext.AddressTypes
                               join ae in dbContext.AddressEntities on at.ID equals ae.AddressTypeID
                               join e in dbContext.Entities on ae.EntityID equals e.ID
                               where e.Name == EntityName
                               orderby at.Name
                               select at
                               ).Distinct();
                return results.ToList<AddressType>();
            }
        }


        /// <summary>
        /// Gets the ACH account types.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetVendorInvoiceTypes()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Vendor", Value = "Vendor" });
            list.Add(new DropDownEntityForString() { Text = "PO", Value = "PO" });
            list.Add(new DropDownEntityForString() { Text = "Invoice", Value = "Invoice" });
            return list;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetTemporaryCCIDFilterTypes()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "CC Ref PO#", Value = "CCMatchPO" });
            list.Add(new DropDownEntityForString() { Text = "Last 5 of CC#", Value = "Last5ofTempCC" });
            return list;
        }

        /// <summary>
        /// Gets the claim name filter types.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetClaimNameFilterTypes()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Member", Value = "Member" });
            list.Add(new DropDownEntityForString() { Text = "Vendor", Value = "Vendor" });
            return list;
        }

        /// <summary>
        /// Gets the contact methods.
        /// </summary>
        /// <returns></returns>
        public static List<ContactMethod> GetContactMethods()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContactMethods.OrderBy(a => a.Sequence).ToList<ContactMethod>();
            }
        }
        /// <summary>
        /// Gets the contact methods for vendor.
        /// </summary>
        /// <returns></returns>
        public static List<ContactMethod> GetContactMethodsForVendor()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContactMethods.Where(u => u.IsActive == true && u.IsShownOnVendor == true).OrderBy(a => a.Sequence).ToList<ContactMethod>();
            }
        }

        /// <summary>
        /// Gets the contact methods for claim.
        /// </summary>
        /// <returns></returns>
        public static List<ContactMethod> GetContactMethodsForClaim()
        {
            List<ContactMethod> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.ContactMethods.Where(u => u.IsActive == true).OrderBy(a => a.Sequence).ToList<ContactMethod>();
            }
            list = list.Where(u => u.Name.Contains("Phone") || u.Name.Contains("Email") || u.Name.Contains("Fax") || u.Name.Contains("Web") || u.Name.Contains("Mail")).ToList();
            return list;
        }

        /// <summary>
        /// Gets the claim reject reason.
        /// </summary>
        /// <returns></returns>
        public static List<ClaimRejectReason> GetClaimRejectReason()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ClaimRejectReasons.Where(u => u.IsActive == true).OrderBy(a => a.Sequence).ToList<ClaimRejectReason>();
            }
        }

        /// <summary>
        /// Gets the members by membership number.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <returns></returns>
        public static List<DropDownEntity> GetMembersByMembershipNumber(string membershipNumber)
        {
            List<DropDownEntity> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (string.IsNullOrEmpty(membershipNumber))
                {
                    membershipNumber = null;
                }
                List<MemberName_Result> memberNameList = dbContext.GetMemberNameUsingMembershipNumber(membershipNumber).ToList();
                if (memberNameList.Count > 0)
                {
                    list = memberNameList.Select(u => new DropDownEntity() { ID = u.MemberID, Name = u.Member }).ToList();
                }
            }
            if (list == null)
            {
                list = new List<DropDownEntity>();
            }

            return list;
        }

        /// <summary>
        /// Gets the PO status list.
        /// </summary>
        /// <returns></returns>
        public static List<PurchaseOrderStatu> GetPOStatusList()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PurchaseOrderStatus.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the vendor invoice status.
        /// </summary>
        /// <returns></returns>
        public static List<VendorInvoiceStatu> GetVendorInvoiceStatus()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorInvoiceStatus.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the vendor invoice status by identifier.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <returns></returns>
        public static VendorInvoiceStatu GetVendorInvoiceStatusById(int id)
        {
            VendorInvoiceStatu statu = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                statu = dbContext.VendorInvoiceStatus.Where(u => u.ID == id).FirstOrDefault<VendorInvoiceStatu>();
            }
            return statu;
        }

        /// <summary>
        /// Gets the invoice statuses.
        /// </summary>
        /// <returns></returns>
        public static List<VendorInvoiceStatu> GetInvoiceStatuses()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorInvoiceStatus.Where(v => v.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the vendor locations.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorLocationTransactionList_Result> GetVendorLocationTransactionList(PageCriteria pc, int vendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorLocationTransactionList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, vendorLocationID).ToList<VendorLocationTransactionList_Result>();
            }
        }

        /// <summary>
        /// Gets the batch statuses.
        /// </summary>
        /// <returns></returns>
        public static List<BatchStatu> GetBatchStatuses()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.BatchStatus.Where(a => a.IsActive == true).OrderBy(a => a.Name).ToList<BatchStatu>();
            }
        }

        /// <summary>
        /// Gets the post login URL.
        /// </summary>
        /// <param name="postLoginPromptId">The post login prompt id.</param>
        /// <returns></returns>
        public PostLoginPrompt GetPostLoginUrl(int postLoginPromptId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PostLoginPrompts.Where(a => a.ID == postLoginPromptId).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the name of the post login prompt by.
        /// </summary>
        /// <param name="postLoginPromptName">Name of the post login prompt.</param>
        /// <returns></returns>
        public PostLoginPrompt GetPostLoginPromptByName(string postLoginPromptName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PostLoginPrompts.Where(a => a.Name == postLoginPromptName).FirstOrDefault();
            }
        }

        #region Claim Related Methods
        /// <summary>
        /// Gets the claim types.
        /// </summary>
        /// <returns></returns>
        public static List<ClaimType> GetClaimTypes()
        {
            List<ClaimType> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.ClaimTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();

            }
            return list;
        }
        /// <summary>
        /// Gets the claim categories.
        /// </summary>
        /// <returns></returns>
        public static List<ClaimCategory> GetClaimCategories()
        {
            List<ClaimCategory> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.ClaimCategories.Where(u => u.IsActive == true).OrderBy(u => u.Name).ToList();

            }
            return list;
        }

        /// <summary>
        /// Gets the claim status.
        /// </summary>
        /// <returns></returns>
        public static List<ClaimStatu> GetClaimStatus()
        {
            List<ClaimStatu> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.ClaimStatus.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();

            }
            return list;
        }

        /// <summary>
        /// Gets the billing invoice detail disposition.
        /// </summary>
        /// <returns></returns>
        public static List<BillingInvoiceDetailDisposition> GetBillingInvoiceDetailDisposition()
        {
            List<BillingInvoiceDetailDisposition> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.BillingInvoiceDetailDispositions.Where(u => u.IsActive == true).OrderBy(u => u.Name).ToList();

            }
            return list;
        }


        /// <summary>
        /// Gets the billing invoice detail status.
        /// </summary>
        /// <returns></returns>
        public static List<BillingInvoiceDetailStatu> GetBillingInvoiceDetailStatus()
        {
            List<BillingInvoiceDetailStatu> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.BillingInvoiceDetailStatus.Where(u => u.IsActive == true).OrderBy(u => u.Name).ToList();

            }
            return list;
        }
        public static List<BillingInvoiceDetailStatu> GetBillingInvoiceDetailStatusPendingReady()
        {
            List<BillingInvoiceDetailStatu> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.BillingInvoiceDetailStatus.Where(u => u.IsActive == true && (u.Name == "PENDING" || u.Name == "READY")).OrderBy(u => u.Name).ToList();

            }
            return list;
        }

        /// <summary>
        /// Gets the billing adjustment reason.
        /// </summary>
        /// <returns></returns>
        public static List<BillingAdjustmentReason> GetBillingAdjustmentReason()
        {
            List<BillingAdjustmentReason> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.BillingAdjustmentReasons.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();

            }
            return list;
        }

        /// <summary>
        /// Gets the billing exclude reason.
        /// </summary>
        /// <returns></returns>
        public static List<BillingExcludeReason> GetBillingExcludeReason()
        {
            List<BillingExcludeReason> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.BillingExcludeReasons.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();

            }
            return list;
        }

        /// <summary>
        /// Gets the billing definition invoice line.
        /// </summary>
        /// <returns></returns>
        public static List<BillingDefinitionInvoiceLine> GetBillingDefinitionInvoiceLine(int billingDefinitionInvoiceID)
        {
            List<BillingDefinitionInvoiceLine> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.BillingDefinitionInvoiceLines.Where(u => u.IsActive == true && u.BillingDefinitionInvoiceID == billingDefinitionInvoiceID).OrderBy(u => u.Name).ToList();

            }
            return list;
        }

        /// <summary>
        /// Gets the claim status.
        /// </summary>
        /// <param name="roleId">The role id.</param>
        /// <returns></returns>
        public static List<ClaimStatu> GetClaimStatus(Guid userId)
        {
            List<ClaimStatu> list = null;
            Securable securable = null;
            bool IsAccessibleForReadyForPayment = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                #region Verify Securable
                securable = dbContext.Securables.Where(u => u.FriendlyName.Equals("CLAIMS_STAUTS_READYFORPAYMENT")).FirstOrDefault();
                if (securable == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Securable {0}", "CLAIMS_STAUTS_READYFORPAYMENT"));
                }
                #endregion

                #region Get Claims
                list = dbContext.ClaimStatus.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
                #endregion

                List<Securable_IsAccessible_Result> result = dbContext.GetSecurableIsAccessible(userId, "CLAIMS_STAUTS_READYFORPAYMENT").ToList();
                if (result != null && result.Count > 0)
                {
                    IsAccessibleForReadyForPayment = true;
                }
            }
            //Securables
            if (!IsAccessibleForReadyForPayment)
            {
                list = list.Where(u => !u.Name.Equals("ReadyForPayment")).ToList();
            }

            return list.OrderBy(u => u.Name).ToList();
        }

        /// <summary>
        /// Gets the claim types except.
        /// </summary>
        /// <param name="Name">The name.</param>
        /// <returns></returns>
        public static List<ClaimType> GetClaimTypesExcept(string Name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ClaimTypes.Where(u => u.IsActive == true && u.Name != Name).OrderBy(u => u.Sequence).ToList();

            }
        }

        /// <summary>
        /// Gets the claim category base on claim.
        /// </summary>
        /// <param name="claimTypeID">The claim type identifier.</param>
        /// <returns></returns>
        public static List<ClaimCategory> GetClaimCategoryBaseOnClaim(int claimTypeID)
        {
            List<ClaimCategory> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = (from categories in dbContext.ClaimCategories
                        join claimType in dbContext.ClaimTypeCategories on categories.ID equals claimType.ClaimCategoryID
                        where claimType.ClaimTypeID == claimTypeID
                        orderby categories.Name
                        select categories).ToList();

            }

            return list;
        }

        #endregion

        /// <summary>
        /// Gets the payee types.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetPayeeTypes()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Member", Value = "Member" });
            list.Add(new DropDownEntityForString() { Text = "Vendor", Value = "Vendor" });
            return list;
        }

        /// <summary>
        /// Gets the export batches for invoice.
        /// </summary>
        /// <returns></returns>
        public static List<Batch> GetExportBatchesForInvoice()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.Batches.Where(x => x.BatchType.Name == "VendorInvoiceExport").ToList();
                return list;
            }
        }

        /// <summary>
        /// Gets the vendor invoice exceptions.
        /// </summary>
        /// <returns></returns>
        public static List<string> GetVendorInvoiceExceptions()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorInvoiceExceptions.Select(u => u.Description).Distinct().ToList();
            }
        }

        /// <summary>
        /// Gets the client payment created by.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetClientPaymentCreatedBy()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.ClientPayments.Select(u => new DropDownEntityForString()
                {
                    Text = u.CreateBy,
                    Value = u.CreateBy
                }).Distinct().ToList();
            }

            return list;
        }

        /// <summary>
        /// Gets the logged in user phone.
        /// </summary>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="PhoneType">Type of the phone.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public static string GetLoggedInUserPhone(string entityName, string PhoneType, int? vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var phone = dbContext.GetPhoneNumber(vendorID, entityName, PhoneType).FirstOrDefault();
                if (phone != null)
                {
                    return phone.PhoneNumber;
                }
                return string.Empty;
            }
        }

        /// <summary>
        /// Gets the payment types for ACES.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetPaymentTypesForACES()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Check", Value = "Check" });
            return list;
        }

        /// <summary>
        /// Gets the document categories.
        /// </summary>
        /// <returns></returns>
        public static List<DocumentCategory> GetDocumentCategories(bool isVendorPortal = false)
        {
            List<DocumentCategory> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (isVendorPortal)
                {
                    list = dbContext.DocumentCategories.Where(a => a.IsActive == true && a.IsShownOnVendorPortal == true).OrderBy(a => a.Sequence).ToList<DocumentCategory>();
                }
                else
                {
                    list = dbContext.DocumentCategories.Where(a => a.IsActive == true).OrderBy(a => a.Sequence).ToList<DocumentCategory>();
                }
            }
            return list;
        }





        /// <summary>
        /// Gets the name of the document category by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public static DocumentCategory GetDocumentCategoryByName(string name)
        {
            DocumentCategory category = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                category = dbContext.DocumentCategories.Where(a => a.Name == name).SingleOrDefault<DocumentCategory>();

            }
            return category;
        }

        /// <summary>
        /// Gets the vendor region.
        /// </summary>
        /// <param name="vendorRegionID">The vendor region ID.</param>
        /// <returns></returns>
        public VendorRegion GetVendorRegion(int vendorRegionID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorRegions.Where(a => a.ID == vendorRegionID).FirstOrDefault();
            }
            throw new NotImplementedException();
        }

        /// <summary>
        /// Gets the contact category.
        /// </summary>
        /// <param name="contactCategoryID">The contact category ID.</param>
        /// <returns></returns>
        public ContactCategory GetContactCategory(int contactCategoryID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContactCategories.Where(a => a.ID == contactCategoryID).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the name of the entity by.
        /// </summary>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        public static Entity GetEntityByName(string entityName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Entities.Where(a => a.Name == entityName).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the owner programs for claim.
        /// </summary>
        /// <returns></returns>
        public static List<Program> GetOwnerProgramsForClaim()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = (from p in dbContext.Programs
                            join c in dbContext.Clients on p.ClientID equals c.ID
                            where c.Name == "Ford" && p.IsGroup == false && !(
                            p.Name == "Ford QFC" || p.Name == "Ford Direct Tow" || p.Name == "Ford Transport"
                            ) && p.IsActive == true
                            orderby p.Name
                            select p).ToList<Program>();

                return list;
            }
        }

        /// <summary>
        /// Gets the type of the programs for search by claim.
        /// </summary>
        /// <param name="claimType">Type of the claim.</param>
        /// <returns></returns>
        public static List<Program> GetProgramsForSearchByClaimType(string claimType)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = (from pc in dbContext.ProgramConfigurations
                            join p in dbContext.Programs on pc.ProgramID equals p.ID
                            where pc.Name == claimType && pc.Value == "Yes"
                            select p).ToList<Program>();
                return list;
            }
        }

        /// <summary>
        /// Gets the export batches for claim.
        /// </summary>
        /// <returns></returns>
        public static List<Batch> GetExportBatchesForClaim()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.Batches.Where(x => x.BatchType.Name == "ClaimExport").ToList();
                return list;
            }
        }

        /// <summary>
        /// Gets the vendor invoice payment difference reason codes.
        /// </summary>
        /// <returns></returns>
        public static List<VendorInvoicePaymentDifferenceReasonCode> GetVendorInvoicePaymentDifferenceReasonCodes()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.VendorInvoicePaymentDifferenceReasonCodes.Where(v => v.IsActive == true).OrderBy(a => a.Sequence).ToList<VendorInvoicePaymentDifferenceReasonCode>();
                return list;
            }
        }

        /// <summary>
        /// Gets the billing events.
        /// </summary>
        /// <returns></returns>
        public static List<ClientBillableEventProcessingCascadeBillingEvent_Result> GetBillingEvents(string lineID)
        {
            List<ClientBillableEventProcessingCascadeBillingEvent_Result> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.GetClientBillableEventProcessingCascadeBillingEvent(lineID).ToList();
            }
            return list;
        }

        /// <summary>
        /// Gets the type of the billing schedule.
        /// </summary>
        /// <returns></returns>
        public static List<BillingScheduleType> GetBillingScheduleType()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.BillingScheduleTypes.Where(v => v.IsActive == true).OrderBy(a => a.Sequence).ToList<BillingScheduleType>();
                return list;
            }
        }

        /// <summary>
        /// Gets the regenerate billing events clients.
        /// </summary>
        /// <returns></returns>
        public static List<Client> GetRegenerateBillingEventsClients()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<Client> list = (from client in dbContext.Clients
                                     join billingDefinitionInvoice in dbContext.BillingDefinitionInvoices
                                     on client.ID equals billingDefinitionInvoice.ClientID
                                     where client.IsActive == true
                                     orderby client.Name
                                     select client
                                     ).ToList();

                return list;
            }
        }

        /// <summary>
        /// Gets the billing definition invoice.
        /// </summary>
        /// <returns></returns>
        public static List<BillingDefinitionInvoice> GetBillingDefinitionInvoice(int? clientID = null)
        {
            List<BillingDefinitionInvoice> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (clientID.HasValue)
                {
                    list = dbContext.BillingDefinitionInvoices.Where(v => v.IsActive == true && v.ClientID == clientID.Value).OrderBy(a => a.Sequence).ToList<BillingDefinitionInvoice>();
                }
                else
                {
                    list = dbContext.BillingDefinitionInvoices.Where(v => v.IsActive == true).OrderBy(a => a.Sequence).ToList<BillingDefinitionInvoice>();
                }

            }
            return list;
        }

        /// <summary>
        /// Gets the purchase order pay status codes.
        /// </summary>
        /// <returns></returns>
        public static List<PurchaseOrderPayStatusCode> GetPurchaseOrderPayStatusCodes()
        {
            List<PurchaseOrderPayStatusCode> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.PurchaseOrderPayStatusCodes.Where(a => a.IsActive == true).OrderBy(a => a.Sequence).ToList<PurchaseOrderPayStatusCode>();
            }
            return list;
        }

        /// <summary>
        /// Gets the temporary credit card exceptions.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetTemporaryCreditCardExceptions()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            List<string> exceptionList;
            using (DMSEntities dbContext = new DMSEntities())
            {
                exceptionList = dbContext.TemporaryCreditCards.Where(x => x.ExceptionMessage != null && x.ExceptionMessage != "").Select(x => x.ExceptionMessage).Distinct().ToList();
            }
            if (exceptionList != null && exceptionList.Count > 0)
            {
                for (int i = 0; i < exceptionList.Count; i++)
                {
                    list.Add(new DropDownEntityForString() { Text = exceptionList[i].ToString(), Value = exceptionList[i].ToString() });
                }
            }
            return list;
        }

        /// <summary>
        /// Gets the name of the purchase order pay status code by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public static PurchaseOrderPayStatusCode GetPurchaseOrderPayStatusCodeByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PurchaseOrderPayStatusCodes.Where(a => a.Name == name).FirstOrDefault();
            }
        }

        public static PurchaseOrderPayStatusCode GetPurchaseOrderPayStatusCodeByID(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PurchaseOrderPayStatusCodes.Where(a => a.ID == id).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the po products for client invoice.
        /// </summary>
        /// <returns></returns>
        public static List<Product> GetPOProductsForClientInvoice()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                var list = (from p in dbContext.Products
                            join pc in dbContext.ProductCategories on p.ProductCategoryID equals pc.ID
                            //where (pt.Name == "Billing" && p.IsActive == true && pt.IsActive == true && p.IsShowOnPO == true)
                            orderby p.Name
                            select p).ToList<Product>();
                return list;
            }
        }

        public static List<Product> GetPOProductsList()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                var list = (from p in dbContext.Products
                            orderby p.Name
                            select p).ToList<Product>();
                return list;
            }
        }

        /// <summary>
        /// Gets the billing invoice line status.
        /// </summary>
        /// <returns></returns>
        public static List<BillingInvoiceLineStatu> GetBillingInvoiceLineStatus()
        {
            List<BillingInvoiceLineStatu> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.BillingInvoiceLineStatus.Where(u => u.IsActive == true).OrderBy(u => u.Name).ToList();

            }
            return list;
        }

        /// <summary>
        /// Gets the aces claim status.
        /// </summary>
        /// <returns></returns>
        public static List<ACESClaimStatu> GetAcesClaimStatus()
        {
            List<ACESClaimStatu> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.ACESClaimStatus.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();

            }
            return list;
        }

        /// <summary>
        /// Gets the posting batch.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntity> GetPostingBatch()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            List<Batch> batchList = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                batchList = (from batch in dbContext.Batches
                             join batchType in dbContext.BatchTypes on
                             batch.BatchTypeID equals batchType.ID
                             where batchType.Name.Equals("TemporaryCCPost")
                             orderby batch.CreateDate
                             select batch).ToList();

            }
            if (batchList != null)
            {
                foreach (Batch b in batchList)
                {
                    list.Add(new DropDownEntity() { ID = b.ID, Name = b.CreateDate.GetValueOrDefault().ToShortDateString() });
                }
            }
            return list;
        }

        /// <summary>
        /// Gets the temporary credit card status.
        /// </summary>
        /// <returns></returns>
        public static List<TemporaryCreditCardStatu> GetTemporaryCreditCardStatus()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.TemporaryCreditCardStatus.Where(u => u.IsActive == true).OrderBy(a => a.Sequence).ToList<TemporaryCreditCardStatu>();
            }
        }

        /// <summary>
        /// Gets the import cc file types.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetImportCCFileTypes()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Credit Card Issue Transactions", Value = "Credit Card Issue Transactions" });
            list.Add(new DropDownEntityForString() { Text = "Credit Card Charge Transactions", Value = "Credit Card Charge Transactions" });
            return list;
        }


        /// <summary>
        /// Gets the billing invoice status.
        /// </summary>
        /// <returns></returns>
        public static List<BillingInvoiceStatu> GetBillingInvoiceStatus()
        {
            List<BillingInvoiceStatu> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.BillingInvoiceStatus.Where(u => u.IsActive == true).OrderBy(u => u.Name).ToList();

            }
            return list;
        }

        //Lakshmi- Hagerty Integration
        /// <summary>
        /// Gets the name of the program by PGM.
        /// </summary>
        /// <param name="pgmName">Name of the PGM.</param>
        /// <returns></returns>
        public static Program GetProgramByPgmName(string pgmName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Program result = dbContext.Programs.Where(u => u.Name == pgmName & u.ParentProgramID == null)
                    .Include(p => p.Client)
                    .FirstOrDefault();
                return result;
            }
        }

        /// <summary>
        /// Gets the cc match status.
        /// </summary>
        /// <returns></returns>
        public static List<TemporaryCreditCardStatu> GetCCMatchStatus()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.TemporaryCreditCardStatus.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the name of the address type by.
        /// </summary>
        /// <param name="addressTypeName">Name of the address type.</param>
        /// <returns></returns>
        public static AddressType GetAddressTypeByName(string addressTypeName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.AddressTypes.Where(a => a.Name == addressTypeName).FirstOrDefault();
            }
        }

        //Lakshmi- Email on Map Tab
        /// <summary>
        /// Gets the decline reasons.
        /// </summary>
        /// <returns></returns>
        public static List<ContactEmailDeclineReason> GetDeclineReasons()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContactEmailDeclineReasons.ToList<ContactEmailDeclineReason>();
            }
        }

        /// <summary>
        /// Gets the configuration types.
        /// </summary>
        /// <returns></returns>
        public static List<ConfigurationType> GetConfigurationTypes()
        {
            List<ConfigurationType> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.ConfigurationTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
            return list;
        }

        /// <summary>
        /// Gets the control types.
        /// </summary>
        /// <returns></returns>
        public static List<ControlType> GetControlTypes()
        {
            List<ControlType> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.ControlTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
            return list;
        }

        /// <summary>
        /// Gets the configuration categories.
        /// </summary>
        /// <returns></returns>
        public static List<ConfigurationCategory> GetConfigurationCategories()
        {
            List<ConfigurationCategory> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.ConfigurationCategories.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
            return list;
        }

        /// <summary>
        /// Gets the data types.
        /// </summary>
        /// <returns></returns>
        public static List<DataType> GetDataTypes()
        {
            List<DataType> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.DataTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
            return list;
        }

        /// <summary>
        /// Gets the product categories.
        /// </summary>
        /// <returns></returns>
        public static List<ProductCategory> GetProductCategories()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.ProductCategories.Where(vc => vc.IsActive == true).OrderBy(vc => vc.Sequence);
                return result.ToList<ProductCategory>();
            }
        }

        public static List<ProductCategory> GetProductCategoriesForRules()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.ProductCategories.Where(vc => vc.IsActive == true && vc.Name != "Billing" && vc.Name != "Repair").OrderBy(vc => vc.Sequence);
                return result.ToList<ProductCategory>();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public static List<NotificationRecipientType> GetNotificationRecipientType()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.NotificationRecipientTypes.Where(u => u.IsActive == true && u.IsShownOnManualNotification == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the vehicle make model.
        /// </summary>
        /// <param name="year">The year.</param>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public static List<MakeModel> GetMakeModel(int vehicleTypeId, string make, string model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.MakeModels.Where(vmm => vmm.VehicleTypeID == vehicleTypeId &&
                                                                    vmm.Make == make &&
                                                                    vmm.Model == model).ToList<MakeModel>();
                return list;
            }
        }

        /// <summary>
        /// Gets the rv make model.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        //public static List<RVMakeModel> GetRVMakeModel(string make, string model)
        //{
        //    using (DMSEntities dbContext = new DMSEntities())
        //    {
        //        var list = dbContext.RVMakeModels.Where(vmm => vmm.Make == make &&
        //                                                            vmm.Model == model).ToList<RVMakeModel>();
        //        return list;
        //    }
        //}


        /// <summary>
        /// Gets the products related to product category.
        /// </summary>
        /// <param name="productCategoryId">The product category identifier.</param>
        /// <returns></returns>
        public List<ProductForProductCategory_Result> GetProductsRelatedToProductCategory(int? productCategoryId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<ProductForProductCategory_Result> list = dbContext.GetProductForProductCategory(productCategoryId).ToList<ProductForProductCategory_Result>();
                return list;
            }
        }

        /// <summary>
        /// Gets the rate type by identifier.
        /// </summary>
        /// <param name="rateTypeID">The rate type identifier.</param>
        /// <returns></returns>
        public static RateType GetRateTypeByID(int rateTypeID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var rateType = dbContext.RateTypes.Where(x => x.ID == rateTypeID).FirstOrDefault();
                return rateType;
            }
        }
        /// <summary>
        /// Gets the message scope.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetMessageScope()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Dispatch", Value = "Dispatch" });
            list.Add(new DropDownEntityForString() { Text = "Vendor Portal", Value = "VendorPortal" });
            return list;
        }
        /// <summary>
        /// Gets the type of the message.
        /// </summary>
        /// <returns></returns>
        public static List<MessageType> GetMessageType()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.MessageTypes.Where(u => u.IsActive == 1).OrderBy(u => u.Sequence).ToList();
            }
        }
        /// <summary>
        /// Gets the event categories.
        /// </summary>
        /// <returns></returns>
        public static List<EventCategory> GetEventCategories()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.EventCategories.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the client reps.
        /// </summary>
        /// <returns></returns>
        public static List<ClientRep> GetClientReps()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ClientReps.Where(a => a.IsActive == true).OrderBy(a => a.FirstName).ToList();
            }
        }

        /// <summary>
        /// Gets the client types.
        /// </summary>
        /// <returns></returns>
        public static List<ClientType> GetClientTypes()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ClientTypes.Where(a => a.IsActive == true).OrderBy(a => a.Sequence).ToList();
            }
        }
        /// <summary>
        /// Gets the event types.
        /// </summary>
        /// <returns></returns>
        public static List<EventType> GetEventTypes()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.EventTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }
        /// <summary>
        /// Gets the events.
        /// </summary>
        /// <returns></returns>
        public static List<Event> GetEvents()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Events.Where(u => u.IsActive == true).OrderBy(u => u.Name).ToList();
            }
        }

        /// <summary>
        /// Gets the application names.
        /// </summary>
        /// <returns></returns>
        public static List<aspnet_Applications> GetApplicationNames()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.aspnet_Applications.ToList();
            }
        }

        /// <summary>
        /// Gets the concern types.
        /// </summary>
        /// <returns></returns>
        public static List<ConcernType> GetConcernTypes()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ConcernTypes.Where(a => a.IsActive == true).OrderBy(a => a.Sequence).ToList();
            }
        }
        /// <summary>
        /// Gets the type of the concern.
        /// </summary>
        /// <returns></returns>
        public static List<ConcernType> GetConcernType()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ConcernTypes.Where(u => u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }
        /// <summary>
        /// Gets the concern.
        /// </summary>
        /// <param name="concernTypeID">The concern type identifier.</param>
        /// <returns></returns>
        public static List<Concern> GetConcern(int concernTypeID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Concerns.Where(u => u.IsActive == true && u.ConcernTypeID == concernTypeID).OrderBy(u => u.Sequence).ToList();
            }
        }


        /// <summary>
        /// Gets the client name for program.
        /// </summary>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        public static string GetClientNameForProgram(int programId)
        {
            string clientName = string.Empty;
            using (DMSEntities dbContext = new DMSEntities())
            {
                Program program = dbContext.Programs.Where(a => a.ID == programId).FirstOrDefault();
                if (program != null)
                {
                    Client client = dbContext.Clients.Where(a => a.ID == program.ClientID).FirstOrDefault();
                    if (client != null)
                    {
                        clientName = client.Name;
                    }
                }
            }
            return clientName;
        }

        /// <summary>
        /// Gets the capture claim number details for sr.
        /// </summary>
        /// <param name="srId">The sr identifier.</param>
        /// <returns></returns>
        public static CaptureClaimNumberDetailsForSR_Result GetCaptureClaimNumberDetailsForSR(int srId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetCaptureClaimNumberDetailsForSR(srId).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the event names.
        /// </summary>
        /// <param name="tabId">The event identifier.</param>
        /// <param name="isEnter">if set to <c>true</c> [is enter].</param>
        /// <returns></returns>
        public static string GetEventName(int tabId, bool isEnter)
        {
            string eventName = string.Empty;
            if (isEnter)
            {
                switch (tabId)
                {
                    case 0:
                        eventName = EventNames.ENTER_START_TAB;
                        break;
                    case 1:
                        eventName = EventNames.ENTER_EMERGENCY_TAB;
                        break;
                    case 2:
                        eventName = EventNames.ENTER_MEMBER_TAB;
                        break;
                    case 3:
                        eventName = EventNames.ENTER_VEHICLE_TAB;
                        break;
                    case 4:
                        eventName = EventNames.ENTER_SERVICE_TAB;
                        break;
                    case 5:
                        eventName = EventNames.ENTER_MAP_TAB;
                        break;
                    case 6:
                        eventName = EventNames.ENTER_ESTIMATE_TAB;
                        break;
                    case 7:
                        eventName = EventNames.ENTER_DISPATCH_TAB;
                        break;
                    case 8:
                        eventName = EventNames.ENTER_PO_TAB;
                        break;
                    case 9:
                        eventName = EventNames.ENTER_PAYMENT_TAB;
                        break;
                    case 10:
                        eventName = EventNames.ENTER_ACTIVITY_TAB;
                        break;
                    case 11:
                        eventName = EventNames.ENTER_FINISH_TAB;
                        break;
                }
            }
            else
            {
                switch (tabId)
                {
                    case 0:
                        eventName = EventNames.LEAVE_START_TAB;
                        break;
                    case 1:
                        eventName = EventNames.LEAVE_EMERGENCY_TAB;
                        break;
                    case 2:
                        eventName = EventNames.LEAVE_MEMBER_TAB;
                        break;
                    case 3:
                        eventName = EventNames.LEAVE_VEHICLE_TAB;
                        break;
                    case 4:
                        eventName = EventNames.LEAVE_SERVICE_TAB;
                        break;
                    case 5:
                        eventName = EventNames.LEAVE_MAP_TAB;
                        break;
                    case 6:
                        eventName = EventNames.LEAVE_ESTIMATE_TAB;
                        break;
                    case 7:
                        eventName = EventNames.LEAVE_DISPATCH_TAB;
                        break;
                    case 8:
                        eventName = EventNames.LEAVE_PO_TAB;
                        break;
                    case 9:
                        eventName = EventNames.LEAVE_PAYMENT_TAB;
                        break;
                    case 10:
                        eventName = EventNames.LEAVE_ACTIVITY_TAB;
                        break;
                    case 11:
                        eventName = EventNames.LEAVE_FINISH_TAB;
                        break;
                }
            }
            return eventName;
        }


        public static PO_MemberPayDispatchFee_Result CalculateMemberPayDispatchFee(int poId, decimal? poAmount, string spName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Database.SqlQuery<PO_MemberPayDispatchFee_Result>(
                    spName + " @poId, @purchaseOrderAmount",
                    new SqlParameter("poId", poId),
                    new SqlParameter("purchaseOrderAmount", poAmount.GetValueOrDefault())).FirstOrDefault();

            }
        }

        /// <summary>
        /// Checks the is vin valid.
        /// </summary>
        /// <param name="vin">The vin.</param>
        /// <returns></returns>
        public static bool CheckIsVINValid(string vin)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var sql = @"SELECT dbo.fnc_IsValidVINCheckDigit({0}) ";
                return dbContext.Database.SqlQuery<bool>(sql, vin).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the name of the language by.
        /// </summary>
        /// <param name="languageName">Name of the language.</param>
        /// <returns></returns>
        public static Language GetLanguageByName(string languageName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Languages.Where(u => u.Name == languageName).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the name of the call type by.
        /// </summary>
        /// <param name="callTypeName">Name of the call type.</param>
        /// <returns></returns>
        public static CallType GetCallTypeByName(string callTypeName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.CallTypes.Where(u => u.Name == callTypeName).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the dispatch software product.
        /// </summary>
        /// <param name="includeInactive">if set to <c>true</c> [include inactive].</param>
        /// <returns></returns>
        public static List<DispatchSoftwareProduct> GetDispatchSoftwareProduct(bool includeInactive = false)
        {
            var list = new List<DispatchSoftwareProduct>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (includeInactive)
                {
                    list = dbContext.DispatchSoftwareProducts.OrderBy(a => a.Sequence).ToList();
                }
                else
                {
                    list = dbContext.DispatchSoftwareProducts.Where(a => a.IsActive == true).OrderBy(a => a.Sequence).ToList();
                }
            }
            return list;
        }

        /// <summary>
        /// Gets the dispatch GPS network.
        /// </summary>
        /// <returns></returns>
        public static List<DispatchGPSNetwork> GetDispatchGPSNetwork()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.DispatchGPSNetworks.Where(a => a.IsActive == true).OrderBy(a => a.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the service request decline reason.
        /// </summary>
        /// <returns></returns>
        public static List<ServiceRequestDeclineReason> GetServiceRequestDeclineReason()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ServiceRequestDeclineReasons.OrderBy(a => a.Sequence).ToList();
            }
        }

        /// <summary>
        /// Gets the name of the vendor term agreement by.
        /// </summary>
        /// <param name="agreementName">Name of the agreement.</param>
        /// <returns></returns>
        public static VendorTermsAgreement GetVendorTermAgreementByName(string agreementName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorTermsAgreements.Where(v => v.FileName == agreementName).FirstOrDefault();
            }
        }

        public static TimeType GetTimeTypeByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.TimeTypes.Where(v => v.Name == name).FirstOrDefault();
            }
        }

        public static List<CustomerFeedbackStatu> GetCustomerFeedbackStatus()
        {
            List<CustomerFeedbackStatu> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.CustomerFeedbackStatus.Where(u => u.IsActive == 1).OrderBy(u => u.Sequence).ToList();

            }
            return list;
        }

        public static List<CustomerFeedbackSource> GetCustomerFeedbackSources()
        {
            List<CustomerFeedbackSource> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.CustomerFeedbackSources.Where(u => u.IsActive == 1).OrderBy(u => u.Sequence).ToList();

            }
            return list;
        }

        public static CustomerFeedbackSource GetCustomerFeedbackSourceByName(string sourceName)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.CustomerFeedbackSources.Where(a => a.Name == sourceName).FirstOrDefault();
            }
        }

        public static List<CustomerFeedbackType> GetCustomerFeedbackTypes()
        {
            List<CustomerFeedbackType> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.CustomerFeedbackTypes.Where(u => u.IsActive == 1).OrderBy(u => u.Sequence).ToList();

            }
            return list;
        }


        public static CustomerFeedbackType GetCustomerFeedbackTypeByName(string customerFeedbackType)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.CustomerFeedbackTypes.Where(a => a.Name == customerFeedbackType).FirstOrDefault();
            }
        }


        public static List<CustomerFeedbackPriority> GetCustomerFeedbackPrioritys()
        {
            List<CustomerFeedbackPriority> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.CustomerFeedbackPriorities.Where(u => u.IsActive == 1).OrderBy(u => u.Sequence).ToList();

            }
            return list;
        }
        /// <summary>
        /// Gets the claim ID filter types.
        /// </summary>
        /// <returns></returns>
        public static List<DropDownEntityForString> GetClaimIDFilterTypes()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Claim", Value = "Claim" });
            list.Add(new DropDownEntityForString() { Text = "Member", Value = "Member" });
            list.Add(new DropDownEntityForString() { Text = "Vendor", Value = "Vendor" });
            return list;
        }


        public static List<DropDownEntityForString> GetCustomerFeedbackIDFilterTypes(string callFrom)
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();

            list.Add(new DropDownEntityForString() { Text = "Purchase Order", Value = "PurchaseOrder" });
            list.Add(new DropDownEntityForString() { Text = "Service Request", Value = "ServiceRequest" });
            if (callFrom == CallFrom.FEEDBACK)
            {
                list.Add(new DropDownEntityForString() { Text = "Feedback", Value = "Feedback" });
                list.Add(new DropDownEntityForString() { Text = "Member #", Value = "Member" });
            }
            else
            {
                list.Add(new DropDownEntityForString() { Text = "Member #", Value = "Member" });
            }           
            
            return list;
        }


        public static List<CheckBoxLookUp> GetCustomerSurveyFeedbackStatus()
        {
            List<CheckBoxLookUp> list = new List<CheckBoxLookUp>();
            list.Add(new CheckBoxLookUp() { ID = 1, Name = "Open" });
            list.Add(new CheckBoxLookUp() { ID = 2, Name = "Closed" });
            return list;
        }
        public static List<DropDownEntity> GetCustomerFeedbackClients()
        {
            List<DropDownEntity> list = null;
            using (DMSEntities dbConext = new DMSEntities())
            {
                list = dbConext.Clients.Select(m => new DropDownEntity
                {
                    Name = m.Name,
                    ID = m.ID
                })
                        .Distinct()
                        .OrderBy(u => u.Name)
                        .ToList();
            }
            if (list != null)
            {
                list.Add(new DropDownEntity { Name = "Other", ID = 0 });
            }
            return list;
        }
        public static List<DropDownEntity> GetCustomerFeedbackProgram(int Clientid)
        {
            List<DropDownEntity> list = null;
            using (DMSEntities dbConext = new DMSEntities())
            {
                list = dbConext.Programs.Select(m => new DropDownEntity
                {
                    Name = m.Name,
                    ID = m.ID
                }).Where(x => x.ID == Clientid)
                        .Distinct()
                        .OrderBy(u => u.Name)
                        .ToList();
            }
            if (list != null)
            {
                list.Add(new DropDownEntity { Name = "Other", ID = 0 });
            }
            return list;
        }
        public static List<DropDownEntity> GetCustomerFeedbackNextactions()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            using (DMSEntities dbConext = new DMSEntities())
            {
                list = dbConext.NextActions.Select(m => new DropDownEntity
                {
                    ID = m.ID,
                    Name = m.Description
                })
                        .Distinct()
                        .OrderBy(u => u.Name)
                        .ToList();
            }
            //if (list != null)
            //{
            //    list.Add(new DropDownEntityForString { Text = "Other", Value = "Other" });
            //}

            return list;
        }


        public static List<DropDownEntityForString> GetCustomerFeedbackFilterValueTypes()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            list.Add(new DropDownEntityForString() { Text = "Created By", Value = "Created By" });
            list.Add(new DropDownEntityForString() { Text = "Member", Value = "Member" });
            list.Add(new DropDownEntityForString() { Text = "Assigned To", Value = "Assigned To" });
            return list;
        }




        public static List<Program> GetProgram(int Client)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.Programs.Where(x => x.ClientID == Client).OrderBy(x => x.ClientID).ToList<Program>();
                return list;
            }
        }




        public static List<DropDownEntity> GetCustomerFeedbackStatus_List()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            using (DMSEntities dbConext = new DMSEntities())
            {
                list = dbConext.CustomerFeedbackStatus.Select(m => new DropDownEntity
                {
                    ID = m.ID,
                    Name = m.Description
                })
                        .Distinct()
                        .OrderBy(u => u.Name)
                        .ToList();
            }
            //if (list != null)
            //{
            //    list.Add(new DropDownEntityForString { Text = "Other", Value = "Other" });
            //}

            return list;
        }

        public static List<DropDownEntity> GetCustomerFeedbackSource_List()
        {
            List<DropDownEntity> list = new List<DropDownEntity>();
            using (DMSEntities dbConext = new DMSEntities())
            {
                list = dbConext.CustomerFeedbackSources.Select(m => new DropDownEntity
                {
                    ID = m.ID,
                    Name = m.Description
                })
                        .Distinct()
                        .OrderBy(u => u.Name)
                        .ToList();
            }
            //if (list != null)
            //{
            //    list.Add(new DropDownEntityForString { Text = "Other", Value = "Other" });
            //}

            return list;
        }
        public static List<CustomerFeedbackPriority> GetCustomerFeedbackPriority_List()
        {
            List<CustomerFeedbackPriority> list = new List<CustomerFeedbackPriority>();
            using (DMSEntities dbConext = new DMSEntities())
            {
                list = dbConext.CustomerFeedbackPriorities.Where(u => u.IsActive == 1).OrderBy(u => u.Sequence).ToList();
            }
            //if (list != null)
            //{
            //    list.Add(new DropDownEntityForString { Text = "Other", Value = "Other" });
            //}

            return list;
        }        
        public static List<DropDownEntityForString> GetFeedbackRequestBy_List()
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            using (DMSEntities dbConext = new DMSEntities())
            {
                list = dbConext.aspnet_Users.Select(m => new DropDownEntityForString
                {
                    Value = m.UserName,
                    Text = m.UserName
                })
                        .Distinct()
                        .OrderBy(u => u.Text)
                        .ToList();
            }

            return list;
        }

        public static CustomerFeedbackStatu GetCustomerFeedbackStatusById(int StatusId)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.CustomerFeedbackStatus.Where(x => x.ID == StatusId).FirstOrDefault();
            }
        }

        public static CustomerFeedbackStatu GetCustomerFeedbackStatusByName(string name)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.CustomerFeedbackStatus.Where(x => x.Name == name).FirstOrDefault();
            }
        }

        public static List<User> GetUsersList()
        {   
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Users.OrderBy(u => u.ID).OrderBy(x=>x.FirstName).ToList<User>();
            }
            
        }

        public static List<CustomerFeedbackCategory> GetCustomerFeedbackCategoryByTypeId(int? customerFeedbackTypeId)
        {
            using (var dbContext = new DMSEntities())
            {
                var results = (from fc in dbContext.CustomerFeedbackCategories
                               join tc in dbContext.CustomerFeedbackTypeCategories on fc.ID equals tc.CustomerFeedbackCategoryID
                               join ft in dbContext.CustomerFeedbackTypes on tc.CustomerFeedbackTypeID equals ft.ID
                               where ft.ID == customerFeedbackTypeId
                               orderby fc.Name
                               select fc
                               ).Distinct();
                return results.ToList<CustomerFeedbackCategory>();
            }
        }

        public static List<CustomerFeedbackSubCategory> GetCustomerFeedbackSubCategoryByCategoryId(int? customerFeedbackCategoryId)
        {
            using (var dbContext = new DMSEntities())
            {
                var results = (from fsc in dbContext.CustomerFeedbackSubCategories
                               join csc in dbContext.CustomerFeedbackCategorySubCategories on fsc.ID equals csc.CustomerFeedbackSubCategoryID
                               join fc in dbContext.CustomerFeedbackCategories on csc.CustomerFeedbackCategoryID equals fc.ID
                               where fc.ID == customerFeedbackCategoryId
                               orderby fsc.Name
                               select fsc
                               ).Distinct();
                return results.ToList<CustomerFeedbackSubCategory>();
            }
        }  

        public static List<CustomerFeedbackInvalidReason> GetCustomerFeedbackInvalidReasons()
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.CustomerFeedbackInvalidReasons.ToList<CustomerFeedbackInvalidReason>();
            }
        }

        /// <summary>
        /// Gets the users for next action -> Role
        /// </summary>
        /// <param name="nextActionID">The next action identifier.</param>
        /// <returns></returns>
        public List<GetUsersByNextActionRoles_Result> GetUsersForNextAction(int? nextActionID)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.GetUsersByNextActionRoles(nextActionID).ToList<GetUsersByNextActionRoles_Result>();
            }
        }
        
    }
}
