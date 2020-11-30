using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;
using log4net;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade;
using System.Web.Security;

namespace ClientPortalService
{

    public class ClientPortalMemberService : IClientPortalMemberService
    {
        protected static ILog logger = LogManager.GetLogger(typeof(ClientPortalMemberService));

        public string AddMember(MemberModel memberInformation,string userName,string password)
        {
            string memberID = string.Empty;
            int? memberIDNew = null;
            IsUserAuthenticated(userName, password);
            logger.Info("Trying to validate Model While Add Member");
            ValidateInputs(memberInformation);
            logger.Info("Model Validate successfully");
            try
            {
                logger.Info("Trying to Create a new Record for Member");
                MemberFacade facade = new MemberFacade();

                memberIDNew = facade.ClientPortalRegisterMember(memberInformation, userName);
                if (memberIDNew.HasValue)
                {
                    memberID = memberIDNew.Value.ToString();
                }
                logger.InfoFormat("Member Created Successfully {0}", memberID);
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                if (ex.InnerException != null)
                {
                    ex = ex.InnerException;
                }
                throw new FaultException(new FaultReason(ex.Message), new FaultCode("UnKnown"));
            }
            return memberID;
        }

        public void UpdateMember(MemberModel memberInformation, string userName, string password)
        {
            IsUserAuthenticated(userName, password);
            logger.Info("Trying to validate Model While Add Member");
            ValidateInputs(memberInformation,true);
            logger.Info("Model Validate successfully");

            try
            {
                logger.InfoFormat("Trying to Update member details for given ID {0}", memberInformation.MemberID);
                MemberFacade facade = new MemberFacade();
                facade.ClientPortalRegisterMember(memberInformation, "Web Service");
                logger.Info("Member Updated Successfully");
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                if (ex.InnerException != null)
                {
                    ex = ex.InnerException;
                }
                throw new FaultException(new FaultReason(ex.Message), new FaultCode("UnKnown"));
            }

        }

        #region Helper Method

        private void ValidateInputs(MemberModel memberInformation, bool isUpdate = false)
        {
            if (memberInformation == null)
            {
                logger.InfoFormat("Invalid Model Error Code {0}", "CPM001");
                throw new FaultException(new FaultReason("Model cannot be null"), new FaultCode("CPM001"));
            }
            if (!memberInformation.IsValid(isUpdate))
            {
                logger.InfoFormat("Validation Error {0}", "CPM002");
                var fex = new FaultException<ValidationFault>(new ValidationFault()
                {
                    ValidationErros = memberInformation.ModelErrors()

                }, new FaultReason("Validation Error"), new FaultCode("CPM002"));
                throw fex;
            }
        }

        private void IsUserAuthenticated(string userName,string password)
        {
            if (string.IsNullOrEmpty(userName) || string.IsNullOrEmpty(password))
            {
                logger.InfoFormat("User Name and Password is required Error Code {0}", "CPM000");
                throw new FaultException(new FaultReason("Credentials required"), new FaultCode("CPM000"));
            }
            if (Membership.ValidateUser(userName, password))
            {
                // Valid user do  not do any thing.
            }
            else
            {
                logger.InfoFormat("User Name and Password is Invalid Error Code {0}", "CPM000");
                throw new FaultException(new FaultReason("Invalid Credentials"), new FaultCode("CPM000"));
            }

        }
        #endregion

    }
}
