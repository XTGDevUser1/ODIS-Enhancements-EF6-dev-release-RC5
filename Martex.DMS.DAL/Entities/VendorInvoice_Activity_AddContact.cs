using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using System.Web;
using System.Web.Mvc;

namespace Martex.DMS.DAL.Entities
{
    public class Activity_AddContact
    {
        public bool IsInbound { get; set; }

        public int?[] ContactReasonID { get; set; }

        public string[] ContactReasonIDValuesForCombo
        {
            get;
            set;
        }

        public string[] ContactReasonIDValues
        {
            get
            {
                ContactReasonRepository repository = new ContactReasonRepository();

                int clientIDCount = ContactReasonID == null ? 0 : ContactReasonID.Count();
                var returnList = new string[clientIDCount];
                var returnListID = new string[clientIDCount];
                if (clientIDCount > 0)
                {
                    for (int i = 0; i < clientIDCount; i++)
                    {
                        ContactReason model = repository.Get(ContactReasonID[i].GetValueOrDefault());

                        if (model != null)
                        {
                            returnList[i] = model.Name;
                            returnListID[i] = model.ID.ToString();
                        }
                    }
                    ContactReasonIDValuesForCombo = returnListID;
                }
                return returnList;
            }
        }

        public int?[] ContactActionID { get; set; }

        public string[] ContactActionIDValuesForCombo
        {
            get;
            set;
        }

        public string[] ContactActionIDValues
        {
            get
            {
                ContactActionRepository repository = new ContactActionRepository();

                int clientIDCount = ContactActionID == null ? 0 : ContactActionID.Count();
                var returnList = new string[clientIDCount];
                var returnListID = new string[clientIDCount];
                if (clientIDCount > 0)
                {
                    for (int i = 0; i < clientIDCount; i++)
                    {
                        ContactAction model = repository.Get(ContactActionID[i].GetValueOrDefault());

                        if (model != null)
                        {
                            returnList[i] = model.Name;
                            returnListID[i] = model.ID.ToString();
                        }
                    }
                    ContactActionIDValuesForCombo = returnListID;
                }
                return returnList;
            }
        }

        public int? ContactMethod { get; set; }
        public string ContactMethodValue { get; set; }

        public string TalkedTo { get; set; }
        public string PhoneNumber { get; set; }
        public int PhoneNumberType { get; set; }
        public string Email { get; set; }

        public string Notes { get; set; }

        public int VendorInvoiceID { get; set; }
        public int VendorID { get; set; }
        public int VendorLocationID { get; set; }

        public int MembershipID { get; set; }
        public int MemberID { get; set; }

        public int ClaimID { get; set; }
        public int CustomerFeedbackID { get; set; }

        public int? ContactCategory { get; set; }
        public string ContactCategoryValue { get; set; }

        public int POID { get; set; }
        public int ServiceRequestID { get; set; }
    }

    public class Activity_AddContact_ActionsAndReasons
    {
        public IEnumerable<SelectListItem> contactAction { get; set; }
        public IEnumerable<SelectListItem> contactReason { get; set; }
    }
}
