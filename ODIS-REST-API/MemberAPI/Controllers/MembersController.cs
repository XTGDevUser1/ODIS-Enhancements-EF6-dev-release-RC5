using MemberAPI.DAL.CustomEntities;
using MemberAPI.Models;
using MemberAPI.Services;
using MemberAPI.Services.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using MemberAPI.Common;
using System.Web;
using log4net;
using Martex.DMS.BLL.Model.API;

namespace MemberAPI.Controllers
{
    [RoutePrefix("api")]
    public class MembersController : BaseApiController
    {
        protected readonly IMemberService _memberService = new PinnacleMemberService();
        protected readonly IODISAPIService _odisService = new ODISAPIService();
        protected readonly IFeedService _feedService = new WordPressFeedService();

        protected static readonly ILog logger = LogManager.GetLogger(typeof(MembersController));
        /// <summary>
        /// Joins the specified member.
        /// </summary>
        /// <param name="member">The member.</param>
        /// <returns></returns>
        [Route("v1/Members/Join")]
        [HttpPost]
        public OperationResult Join([FromBody]JoinModel member)
        {
            var result = new OperationResult() {};
            return result;
        }

        /// <summary>
        /// Verifies the specified member.
        /// </summary>
        /// <param name="member">The member.</param>
        /// <returns></returns>
        [Route("v1/Members/RegisterVerify")]
        [HttpPost]
        public OperationResult Verify([FromBody]VerifyRegistrationModel member)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(member);
                var verifyResult = _memberService.VerifyRegistration(OrganizationID, member.MemberNumber, member.LastName, member.FirstName);
                result.Data = verifyResult;
                LogAPIEvent(verifyResult);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }
            return result;
        }

        /// <summary>
        /// Registers the specified member.
        /// </summary>
        /// <param name="member">The member.</param>
        /// <returns></returns>
        [Route("v1/Members/Register")]
        [HttpPost]
        public OperationResult Register([FromBody]RegisterMemberModel member)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { MembershipNumber = member.MembershipNumber, UserName = member.ObjWebUser.UserID });
                _memberService.Register(OrganizationID, member.MembershipNumber, member.ObjWebUser);                
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }
            return result;
        }

        /// <summary>
        /// Resets the password.
        /// </summary>
        /// <param name="resetPassword">The reset password.</param>
        /// <returns></returns>
        [Route("v1/Members/ResetPassword")]
        [HttpPost]
        public OperationResult ResetPassword([FromBody]ResetPasswordModel resetPassword)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { Email = resetPassword.Email }); 
                result.Data = _memberService.ResetPassword(OrganizationID, resetPassword.Email);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// Changes the password.
        /// </summary>
        /// <param name="changePassword">The change password Model</param>
        /// <returns>True if sucess else return exception</returns>
        [Route("v1/Members/ChangePassword")]
        [HttpPost]
        [Authorize]
        public OperationResult ChangePassword([FromBody]ChangePasswordModel changePassword)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
               result.Data = _memberService.ChangePassword(OrganizationID, Claim_MemberShipNumber, changePassword.ObjWebUser, changePassword.OldPassword);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// Changes the password with token.
        /// </summary>
        /// <param name="changePassword">The change password.</param>
        /// <returns>success if password change successfuly else Error</returns>
        [Route("v1/Members/ChangePasswordWithToken")]
        [HttpPost]
        public OperationResult ChangePasswordWithToken([FromBody]ChangePasswordTokenModel changePassword)
        {
            var result = new OperationResult();
            try
            {                
                result.Data = _memberService.ChangePasswordWithToken(OrganizationID, changePassword.PasswordResetToken, changePassword.NewPassword);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// Sends the name of the user.
        /// </summary>
        /// <param name="userMemberNumber">The user member number.</param>
        /// <returns></returns>
        [Route("v1/Members/SendUserName")]
        [HttpPost]
        public OperationResult SendUserName([FromBody]UserMemberNumber userMemberNumber)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID });
                _memberService.SendUserName(OrganizationID, userMemberNumber.Email);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// Gets the Members details of the member
        /// </summary>
        /// <param name="memberNumber">The member number.</param>
        /// <returns>Members details</returns>
        [HttpGet]
        [Authorize]
        [Route("v1/Members")]
        public OperationResult Get()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetMember(OrganizationID, Claim_MemberShipNumber);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// Deletes the member.
        /// </summary>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        [HttpDelete]
        [Authorize]
        [Route("v1/Members")]
        public OperationResult DeleteMember([FromUri]string memberNumber)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.DeleteMember(OrganizationID, memberNumber);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// get the membership details
        /// </summary>
        /// <returns>Membership details</returns>
        [HttpGet]
        [Authorize]
        [Route("v1/Members/Membership")]
        public OperationResult GetMembership()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetMembership(OrganizationID, Claim_MemberShipNumber);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [HttpPut]
        [Authorize]
        [Route("v1/Members/Membership")]
        public OperationResult UpdateMembership(MemberAPI.Services.MembershipService.Membership membership)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, membership = membership });
                result.Data = _memberService.UpdateMembership(OrganizationID, membership);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// Gets the vehicles.
        /// </summary>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        [Route("v1/Members/Vehicles")]
        [HttpGet]
        [Authorize]
        public OperationResult GetVehicles(bool isVehiclePhotoRequired = true)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                var vehicles = _memberService.GetVehicle(OrganizationID, Claim_MemberShipNumber);
                if (!isVehiclePhotoRequired && vehicles != null)
                {
                    vehicles.ForEach(vehicle => {
                        vehicle.Photo = null;
                    });
                }
                result.Data = vehicles;
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();

                //checking for returned exception of type Member Info exception to change the status of response
                MemberInfoException mex = ex as MemberInfoException;
                if (mex != null)
                {
                    result.Status = OperationStatus.INFO;
                }
            }

            return result;
        }
        
        /// <summary>
        /// Adds the edit vehicle.
        /// </summary>
        /// <param name="vehicleInformation">The vehicle information.</param>
        /// <returns></returns>
        [Route("v1/Members/Vehicles")]
        [HttpPost]
        [HttpPut]
        [Authorize]
        public OperationResult AddEditVehicle([FromBody] List<MemberAPI.Services.MembershipService.VehicleInformation> vehicleInformation)
        {   
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, Vehiles = vehicleInformation });
                //MemberAPI.DAL.CNETService.VehicleInformation cnetVehicleInformation = vehicleInformation.Cast<MemberAPI.DAL.CNETService.VehicleInformation>();
                result.Data = _memberService.AddEditMemberVehicle(OrganizationID, Claim_MemberShipNumber, vehicleInformation);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// Deletes the vehicle.
        /// </summary>
        /// <param name="vehicleId">The vehicle identifier.</param>
        /// <returns></returns>
        [Route("v1/Members/Vehicle")]        
        [HttpDelete]
        [Authorize]
        public OperationResult DeleteVehicle([FromUri] long vehicleId)
        {
            var result = new OperationResult();
            try
            {
                result.Data = _memberService.DeleteVehicle(OrganizationID, vehicleId);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }
        
        /// <summary>
        /// Gets the dependents.
        /// </summary>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        [Route("v1/Members/Dependents")]
        [HttpGet]
        [Authorize]
        public OperationResult GetDependents([FromUri]string memberNumber)
        {
            var result = new OperationResult();
            try
            {               
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetDependents(OrganizationID, memberNumber);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }


        /// <summary>
        /// Processes the dependents.
        /// </summary>
        /// <param name="memberDependent">The member dependent.</param>
        /// <returns></returns>
        [Route("v1/Members/Dependents")]
        [HttpPost]
        [HttpPut]
        [Authorize]
        public OperationResult ProcessDependents([FromBody] List<MemberAPI.DAL.CNETService.MemberDependent> memberDependent)
        {
            var result = new OperationResult();
            try
            {  
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.ProcessDependents(OrganizationID, Claim_MemberNumber, memberDependent, HttpContext.Current.Request.HttpMethod == "POST");
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// Updates the member.
        /// </summary>
        /// <param name="cnetMembership">The cnet membership.</param>
        /// <returns></returns>
        //[Route("Members")]
        //[Authorize]
        //[HttpPut]
        //public OperationResult UpdateMember([FromBody] MemberAPI.DAL.CNETService.Membership cnetMembership)
        //{
        //    var result = new OperationResult();
        //    try
        //    {
        //        result.Data = _memberService.UpdateMembership(OrganizationID, Claim_MemberNumber, cnetMembership);
        //    }
        //    catch (Exception ex)
        //    {
        //        result.Status = OperationStatus.ERROR;
        //        result.ErrorMessage = ex.Message;
        //        result.ErrorDetail = ex.ToString();
        //    }

        //    return result;
        //}

        /// <summary>
        /// Adds the edit member.
        /// </summary>
        /// <param name="members">The members.</param>
        /// <returns>Add or Update the member</returns>
        [Route("v1/Members")]
        [Authorize]
        [HttpPost]
        [HttpPut]
        public OperationResult AddEditMember(List<MemberAPI.Services.MembershipService.Member> members)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                bool isSuccessful = _memberService.AddEditMember(OrganizationID, Claim_MemberShipNumber, members);                            
                result.Data = isSuccessful;
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        /// <summary>
        /// Updates the member.
        /// </summary>
        /// <param name="cnetMembership">The cnet membership.</param>
        /// <returns></returns>
        [Route("v1/Members/History")]
        [Authorize]
        [HttpGet]
        public OperationResult GetHistory([FromUri]string sourceSystem = null)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.History(Claim_MemberNumber, Claim_MemberShipNumber, Claim_ProgramID, sourceSystem);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/History/ActiveRequest")]
        [Authorize]
        [HttpGet]
        public OperationResult GetActiveServiceRequest()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetActiveRequest(Claim_MemberNumber, Claim_MemberShipNumber, Claim_ProgramID);
                LogAPIEvent(result);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/History/{id}")]
        [Authorize]
        [HttpGet]
        public OperationResult GetServiceRequest(int id)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetServiceRequest(id);
                LogAPIEvent(result);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/SubmitRequest")]
        [Authorize]
        [HttpPost]
        public OperationResult SubmitRequest(ServiceRequestModel model)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, SR = model });
                result.Data = _odisService.SubmitRequest(model);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/ConfirmEstimate/{id}")]
        [HttpGet]
        public OperationResult ConfirmEstimate(int id)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, ServiceRequestId = id });
                _odisService.ConfirmEstimate(id);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/CancelEstimate/{id}")]
        [HttpGet]
        public OperationResult CancelEstimate(int id)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, ServiceRequestId = id });
                _odisService.CancelEstimate(id);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/ServiceRequest/CloseLoop")]
        [HttpPost]
        public OperationResult UpdateClosedLoopStatus([FromBody]ClosedLoopRequest closedLoopRequest)
        {
            var result = new OperationResult();
            try
            {
                logger.InfoFormat("ClosedLoopRequest is null {0}", closedLoopRequest == null);                
                if(closedLoopRequest != null)
                {
                    logger.InfoFormat("{0}, {1}, {2}", closedLoopRequest.CallStatus, closedLoopRequest.ServiceStatus, closedLoopRequest.ContactLogID);
                }
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, CallStatus = closedLoopRequest.CallStatus, ServiceStatus = closedLoopRequest.ServiceStatus, ContactLogID = closedLoopRequest.ContactLogID });
                _odisService.CloseLoop(closedLoopRequest.CallStatus, closedLoopRequest.ServiceStatus, closedLoopRequest.ContactLogID);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/DMSVehicleChassisList")]        
        [HttpGet]
        public OperationResult GetDMSVehicleChassisList()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetDMSVehicleChassisList();
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/DMSVehicleColorList")]        
        [HttpGet]
        public OperationResult GetDMSVehicleColorList()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetDMSVehicleColorList();
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/DMSVehicleEngineList")]        
        [HttpGet]
        public OperationResult GetDMSVehicleEngineList()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetDMSVehicleEngineList();
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/DMSVehicleMakeList")]        
        [HttpGet]
        public OperationResult GetDMSVehicleMakeList([FromUri]long vehicleTypeID)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, VehicleTypeID = vehicleTypeID });
                result.Data = _memberService.GetDMSVehicleMakeList(vehicleTypeID);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/DMSVehicleModelList")]        
        [HttpGet]
        public OperationResult GetDMSVehicleModelList([FromUri]long vehicleTypeID, [FromUri]string make)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, VehicleTypeID = vehicleTypeID, Make = make });
                result.Data = _memberService.GetDMSVehicleModelList(vehicleTypeID, make);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/StatesForCountry")]        
        [HttpGet]
        public OperationResult GetStatesForCountry([FromUri]long countryID)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, CountryID = countryID });
                result.Data = _memberService.GetStatesForCountry(countryID);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/GetCountryCodes")]        
        [HttpGet]
        public OperationResult GetCountryCodes()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetCountryCodes();
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/DMSVehicleTypeList")]        
        [HttpGet]
        public OperationResult GetDMSVehicleTypeList([FromUri]long programId)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, ProgramId = programId });
                result.Data = _memberService.GetDMSVehicleTypeList(programId);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/DMSVehicleTransmissionList")]        
        [HttpGet]
        public OperationResult GetDMSVehicleTransmissionList()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _memberService.GetDMSVehicleTransmissionList();
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/GetCountries")]        
        [HttpGet]
        public OperationResult GetCountries()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                result.Data = _odisService.GetCountries();
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/DeviceRegister")]
        [Authorize]
        [HttpPost]
        public OperationResult DeviceRegister(DeviceRegisterModel tags)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber });
                _odisService.DeviceRegister(tags);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [Route("v1/Members/GetApplicationSettings")]        
        [HttpGet]
        public OperationResult GetApplicationSettings()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID });
                result.Data = _memberService.GetApplicationSettings(OrganizationID);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }
                
        [HttpGet]
        [Route("v1/Members/MobileStaticDataVersions")]
        public OperationResult GETMobileStaticDataVersions()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID });
                result.Data = _odisService.GETMobileStaticDataVersions();
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [HttpGet]
        [Route("v1/Members/GetDMSMakeModel")]
        public OperationResult GetDMSMakeModel()
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID });
                result.Data = _memberService.GetDMSMakeModel();
                LogAPIEvent(result.Data);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [HttpPost]
        [Route("v1/Members/SendMemberEmail")]
        public OperationResult SendMemberEmail([FromBody] MemberEmailModel memberEmailModel)
        {
            var result = new OperationResult();
            try
            {
                LogAPIEvent(new { OrganizationID = OrganizationID, memberEmailModel = memberEmailModel });
                result.Data = _memberService.SendMemberEmail(OrganizationID, memberEmailModel.ObjWebUser, memberEmailModel.EmailType);
                LogAPIEvent(result.Data);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [HttpGet]
        [Route("v1/Members/GetFeeds")]
        public OperationResult GetFeeds()
        {
            var result = new OperationResult();
            try
            {   
                result.Data = _feedService.GetFeeds();             
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }

        [HttpGet]
        [Route("v1/Members/{id}")]
        public OperationResult GetMemberDetail([FromUri]string id)
        {
            var result = new OperationResult();
            try
            {
                result.Data = _memberService.GetMemberByNumber(OrganizationID,id);
            }
            catch (Exception ex)
            {
                LogAPIEvent(ex, true);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
                result.ErrorDetail = ex.ToString();
            }

            return result;
        }
    }
}
