using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;


namespace Martex.DMS.DAL.Entities
{
    [Serializable]
    public class CheckBoxLookUp
    {
        public int ID { get; set; }
        public string Name { get; set; }
        public bool Selected { get; set; }
    }

    [Serializable]
    public class HistorySearchCriteria
    {
        public int? IDSectionType { get; set; }
        public string IDSectionTypeValue { get; set; }

        public string IDSectionID { get; set; }

        public int? NameSectionType { get; set; }
        public string NameSectionTypeValue { get; set; }

        public string NameSectionTypeISP { get; set; }
        public string NameSectionTypeUser { get; set; }

        public string NameSectionTypeMemberFirstName { get; set; }
        public string NameSectionTypeMemberLastName { get; set; }

        public int? NameSectionFilter { get; set; }
        public string NameSectionFilterValue { get; set; }


        public DateTime? DateSectionFromDate { get; set; }
        public DateTime? DateSectionToDate { get; set; }
        public int? DateSectionPreset { get; set; }
        public string DateSectionPresetValue { get; set; }


        public List<CheckBoxLookUp> ServiceRequestStatus { get; set; }
        public List<CheckBoxLookUp> ServiceType { get; set; }
        public List<CheckBoxLookUp> SpecialList { get; set; }
        public List<CheckBoxLookUp> PurchaseOrderStatus { get; set; }
        public List<CheckBoxLookUp> PaymentType { get; set; }


        public int? VehicleType { get; set; }
        public string VehicleTypeValue { get; set; }

        public string VehicleYear { get; set; }

        public string VehicleMake { get; set; }

        public string VehicleModel { get; set; }

        public string VehicleMakeOther { get; set; }
        public string VehicleModelOther { get; set; }

        public int?[] ClientID { get; set; }

        public string[] ClientIDValuesForCombo
        {
            get;
            set;
        }

        public string[] ClientIDValues
        {
            get
            {
                ClientRepository repository = new ClientRepository();
                
                int clientIDCount = ClientID == null ? 0 : ClientID.Count();
                var returnList = new string[clientIDCount];
                var returnListID = new string[clientIDCount];
                if (clientIDCount > 0)
                {
                    for (int i = 0; i < clientIDCount; i++)
                    {
                        Client model = repository.Get(ClientID[i].GetValueOrDefault());
                        
                        if (model != null)
                        {
                            returnList[i] = model.Name;
                            returnListID[i] = model.ID.ToString();
                        }
                    }
                    ClientIDValuesForCombo = returnListID; 
                }
                return returnList;
            }
        }

        public int?[] ProgramID { get; set; }

        public string[] ProgramIDValuesForCombo
        {
            get;
            set;
        }

        public string[] ProgramIDValues
        {
            get
            {
                ProgramMaintenanceRepository facade = new ProgramMaintenanceRepository();
                int programIDCount = ProgramID == null ? 0 : ProgramID.Count();
                var returnList = new string[programIDCount];
                var returnListID = new string[programIDCount];
                if (programIDCount > 0)
                {
                    for (int i = 0; i < programIDCount; i++)
                    {
                        Program model = facade.Get(ProgramID[i].GetValueOrDefault());
                        if (model != null)
                        {
                            returnList[i] = model.Name;
                            returnListID[i] = model.ID.ToString();
                        }
                    }
                    ProgramIDValuesForCombo = returnListID; 
                }
                return returnList;
            }

        }


        public bool GroupedPanelID { get; set; }
        public bool GroupedPanelName { get; set; }
        public bool GroupedPanelDateRange  { get; set; }
        public bool GroupedPanelClient { get; set; }
        public bool GroupedPanelServiceRequestStatus { get; set; }
        public bool GroupedPanelServiceType { get; set; }
        public bool GroupedPanelSpecial { get; set; }
        public bool GroupedPanelVehicle { get; set; }
        public bool GroupedPanelPaymentType { get; set; }
        public bool GroupedPanelPurchaseOrderStatus { get; set; }
    }
}
