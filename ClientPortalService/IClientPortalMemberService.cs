using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;
using Martex.DMS.DAL.Entities;

namespace ClientPortalService
{
    [ServiceContract]
    public interface IClientPortalMemberService
    {
        [OperationContract]
        [FaultContract(typeof(ValidationFault))]
        string AddMember(MemberModel memberInformation, string userName, string password);

        [OperationContract]
        [FaultContract(typeof(ValidationFault))]
        void UpdateMember(MemberModel memberInformation, string userName, string password);
   
    }
}
