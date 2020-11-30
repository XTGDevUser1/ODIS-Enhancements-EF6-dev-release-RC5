using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ClientPortalServiceClient;
using System.ServiceModel;
using ClientPortalServiceClient.ServiceReferenceClient;

namespace ClientPortalServiceClient
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                ClientPortalMemberServiceClient client = new ClientPortalMemberServiceClient();
                MemberModel model = new MemberModel();
                model.MemberID = 1;
                model.PhoneType = 1;
                model.AddressTypeID = 2;
                model.FirstName = "Sanghi Krishna";
                model.LastName = "Kanhiya";
                model.Email = "sanghimz@gmail.com";
                model.EffectiveDate = DateTime.Now.AddDays(1);
                model.ExpirationDate = DateTime.Now.AddDays(4);
                model.AddressLine1 = "Test 222222222222";
                model.PhoneNumber = "2485250690";

                client.AddMember(model,"democlient","deopass@");
            }
            catch (FaultException<ValidationFault> validationException)
            {
                ValidationError[] list = validationException.Detail.ValidationErros;
            }
            catch (FaultException faultException)
            {
                throw faultException; 
            }
            catch (Exception generalException)
            {
                throw generalException;
            }
        }
    }
}
