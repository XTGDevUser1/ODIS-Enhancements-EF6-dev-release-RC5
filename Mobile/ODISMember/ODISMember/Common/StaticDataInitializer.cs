using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Reflection;
using ODISMember.Entities.Table;
using Newtonsoft.Json;
using ODISMember.Entities;
using ODISMember.Data;
using System.Diagnostics;

namespace ODISMember.Common
{
    public class StaticDataInitializer
    {

        /// <summary>
        /// Assembly of the current class
        /// </summary>
        Assembly assembly = typeof(StaticDataInitializer).GetTypeInfo().Assembly;

        /// <summary>
        /// The database repository
        /// </summary>
        DBRepository dbRepository = new DBRepository();

        MemberHelper memberHelper = new MemberHelper();
        /// <summary>
        /// Inserts the vehicle colors into local database
        /// </summary>
        private void InsertVehicleColors()
        {
            List<VehicleColor> vehicleColorItems;
            vehicleColorItems = dbRepository.GetAllRecords<VehicleColor>();
            if (vehicleColorItems.Count == 0)
            {
                Stream streamVehicleColor = assembly.GetManifestResourceStream(Constants.JSON_VEHICLE_COLOR_LIST);
                using (var reader = new System.IO.StreamReader(streamVehicleColor))
                {
                    string json = reader.ReadToEnd();
                    vehicleColorItems = JsonConvert.DeserializeObject<List<VehicleColor>>(json);
                    dbRepository.InsertAllRecords<VehicleColor>(vehicleColorItems);
                }
            }
        }

        /// <summary>
        /// Inserts the vehicle chassis static data into local database
        /// </summary>
        private void InsertVehicleChassis()
        {
            List<VehicleChassis> vehicleChassisItems;
            vehicleChassisItems = dbRepository.GetAllRecords<VehicleChassis>();
            if (vehicleChassisItems.Count == 0)
            {
                Stream streamVehicleColor = assembly.GetManifestResourceStream(Constants.JSON_VEHICLE_CHASSIS_LIST);
                using (var reader = new System.IO.StreamReader(streamVehicleColor))
                {
                    string json = reader.ReadToEnd();
                    vehicleChassisItems = JsonConvert.DeserializeObject<List<VehicleChassis>>(json);
                    dbRepository.InsertAllRecords<VehicleChassis>(vehicleChassisItems);
                }
            }
        }

        /// <summary>
        /// Inserts the vehicle engine static data into local database
        /// </summary>
        private void InsertVehicleEngine()
        {
            List<VehicleEngine> items;
            items = dbRepository.GetAllRecords<VehicleEngine>();
            if (items.Count == 0)
            {
                Stream stream = assembly.GetManifestResourceStream(Constants.JSON_VEHICLE_ENGINE_LIST);
                using (var reader = new System.IO.StreamReader(stream))
                {
                    string json = reader.ReadToEnd();
                    items = JsonConvert.DeserializeObject<List<VehicleEngine>>(json);
                    dbRepository.InsertAllRecords<VehicleEngine>(items);
                }
            }
        }

        /// <summary>
        /// Inserts the vehicle transmission data into local database
        /// </summary>
        private void InsertVehicleTransmission()
        {
            List<VehicleTransmission> items;
            items = dbRepository.GetAllRecords<VehicleTransmission>();
            if (items.Count == 0)
            {
                Stream stream = assembly.GetManifestResourceStream(Constants.JSON_VEHICLE_TRANSMISSION_LIST);
                using (var reader = new System.IO.StreamReader(stream))
                {
                    string json = reader.ReadToEnd();
                    items = JsonConvert.DeserializeObject<List<VehicleTransmission>>(json);
                    dbRepository.InsertAllRecords<VehicleTransmission>(items);
                }
            }
        }

        /// <summary>
        /// Inserts the countries data into local database
        /// </summary>
        private void InsertCountries()
        {
            List<Countries> items;
            items = dbRepository.GetAllRecords<Countries>();
            if (items.Count == 0)
            {
                Stream stream = assembly.GetManifestResourceStream(Constants.JSON_VEHICLE_COUNTRIES_LIST);
                using (var reader = new System.IO.StreamReader(stream))
                {
                    string json = reader.ReadToEnd();
                    items = JsonConvert.DeserializeObject<List<Countries>>(json);
                    dbRepository.InsertAllRecords<Countries>(items);
                }
            }
        }
        /// <summary>
        /// Inserts the static data versions.
        /// </summary>
        private void InsertStaticDataVersions()
        {
            List<MobileStaticDataVersion> items;
            items = dbRepository.GetAllRecords<MobileStaticDataVersion>();
            if (items.Count == 0)
            {
                Stream stream = assembly.GetManifestResourceStream(Constants.JSON_MOBILE_STATIC_DATA_VERSION_LIST);
                using (var reader = new System.IO.StreamReader(stream))
                {
                    string json = reader.ReadToEnd();
                    items = JsonConvert.DeserializeObject<List<MobileStaticDataVersion>>(json);
                    dbRepository.InsertAllRecords<MobileStaticDataVersion>(items);
                }
            }
        }
        /// <summary>
        /// Inserts the application settings.
        /// </summary>
        private void InsertApplicationSettings()
        {
            List<ApplicationSettingsTable> items;
            items = dbRepository.GetAllRecords<ApplicationSettingsTable>();
            if (items.Count == 0)
            {
                Stream stream = assembly.GetManifestResourceStream(Constants.JSON_APPLICATION_SETTINGS_LIST);
                using (var reader = new System.IO.StreamReader(stream))
                {
                    string json = reader.ReadToEnd();
                    items = JsonConvert.DeserializeObject<List<ApplicationSettingsTable>>(json);
                    dbRepository.InsertAllRecords<ApplicationSettingsTable>(items);
                }
            }
        }

        /// <summary>
        /// Inserts the make model values data into local database
        /// </summary>
        private void InsertMakeModel()
        {
            List<MakeModel> items;
            items = dbRepository.GetAllRecords<MakeModel>();
            if (items.Count == 0)
            {
                Stream stream = assembly.GetManifestResourceStream(Constants.JSON_MAKE_MODEL_LIST);
                using (var reader = new System.IO.StreamReader(stream))
                {
                    string json = reader.ReadToEnd();
                    items = JsonConvert.DeserializeObject<List<MakeModel>>(json);
                    dbRepository.InsertAllRecords<MakeModel>(items);
                }
            }
        }

        public void InitializeStaticData()
        {
            InsertStaticDataVersions();
            InsertApplicationSettings();
            InsertCountries();
            InsertVehicleChassis();
            InsertVehicleColors();
            InsertVehicleEngine();
            InsertVehicleTransmission();
            InsertMakeModel();           
            CompareSaticDataVersion();
        }
        public void CompareSaticDataVersion()
        {
            var task = memberHelper.GetStaticDataVersions();
            task.ContinueWith(x =>
            {
                if (x.IsCompleted)
                {
                    OperationResult operationResult = x.Result;
                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
                    {
                        List<MobileStaticDataVersion> saticDataVersions = dbRepository.GetAllRecords<MobileStaticDataVersion>();

                        List<MobileStaticDataVersion> serverSaticDataVersions = new List<MobileStaticDataVersion>();
                        serverSaticDataVersions = JsonConvert.DeserializeObject<List<MobileStaticDataVersion>>(operationResult.Data.ToString());

                        foreach (MobileStaticDataVersion serverVersion in serverSaticDataVersions)
                        {
                            MobileStaticDataVersion localVersion = saticDataVersions.Where(a => a.Name == serverVersion.Name).FirstOrDefault();

                            //Local version not matching with server version
                            if (localVersion!=null && serverVersion!=null && localVersion.Version != serverVersion.Version)
                            {
                                localVersion.Version = serverVersion.Version;
                                UpdateLocalData(localVersion,false);
                            }

                            //server have a new item to insert
                            if (localVersion == null && serverVersion != null) {
                                UpdateLocalData(serverVersion, true);
                            }
                        }
                    }
                }

            });
        }

        public void UpdateLocalData(MobileStaticDataVersion version, bool isNewInsert = false)
        {
            switch (version.Name)
            {
                case "ApplicationSettings":
                    UpdateApplicationSettings(version, isNewInsert);
                    break;
                case "Countries":
                    UpdateCountries(version, isNewInsert);
                    break;
                case "VehicleChassis":
                    UpdateVehicleChassis(version, isNewInsert);
                    break;
                case "VehicleColor":
                    UpdateVehicleColor(version, isNewInsert);
                    break;
                case "VehicleEngine":
                    UpdateVehicleEngine(version, isNewInsert);
                    break;
                case "VehicleTransmission":
                    UpdateVehicleTransmission(version, isNewInsert);
                    break;
                case "MakeModel":
                    UpdateMakeModel(version, isNewInsert);
                    break;
            }
        }
        private void UpdateMakeModel(MobileStaticDataVersion version, bool isNewInsert = false)
        {
            memberHelper.GetMakeModels().ContinueWith(x =>
            {
                if (x.IsCompleted)
                {
                    OperationResult operationResult = x.Result;
                    UpdateOrInsertVersion(operationResult, version, isNewInsert);
                }
            });
        }
        private void UpdateVehicleTransmission(MobileStaticDataVersion version, bool isNewInsert = false)
        {
            memberHelper.GetVehicleTransmissions().ContinueWith(x =>
            {
                if (x.IsCompleted)
                {
                    OperationResult operationResult = x.Result;
                    UpdateOrInsertVersion(operationResult, version, isNewInsert);
                }
            });
        }

        private void UpdateVehicleEngine(MobileStaticDataVersion version, bool isNewInsert = false)
        {
            memberHelper.GetVehicleEngines().ContinueWith(x =>
            {
                if (x.IsCompleted)
                {
                    OperationResult operationResult = x.Result;
                    UpdateOrInsertVersion(operationResult, version, isNewInsert);
                }
            });
        }

        private void UpdateVehicleColor(MobileStaticDataVersion version, bool isNewInsert = false)
        {
            memberHelper.GetVehicleColors().ContinueWith(x =>
            {
                if (x.IsCompleted)
                {
                    OperationResult operationResult = x.Result;
                    UpdateOrInsertVersion(operationResult, version, isNewInsert);
                }
            });
        }

        private void UpdateVehicleChassis(MobileStaticDataVersion version, bool isNewInsert = false)
        {
            memberHelper.GetVehicleChassis().ContinueWith(x =>
            {
                if (x.IsCompleted)
                {
                    OperationResult operationResult = x.Result;
                    UpdateOrInsertVersion(operationResult, version, isNewInsert);
                }
            });
        }

        private void UpdateCountries(MobileStaticDataVersion version, bool isNewInsert = false)
        {
            memberHelper.GetCountryCodes().ContinueWith(x =>
            {
                if (x.IsCompleted)
                {
                    OperationResult operationResult = x.Result;
                    UpdateOrInsertVersion(operationResult, version, isNewInsert);
                }
            });
        }
        public void UpdateApplicationSettings(MobileStaticDataVersion version, bool isNewInsert = false)
        {
            memberHelper.GetApplicationSettings().ContinueWith(x =>
            {
                if (x.IsCompleted)
                {
                    OperationResult operationResult = x.Result;
                    UpdateOrInsertVersion(operationResult, version, isNewInsert);
                }
            });

        }

        public void UpdateOrInsertVersion(OperationResult operationResult, MobileStaticDataVersion version, bool isNewInsert=false) {
    
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                ODISBackgroundService.GetInstance().Enqueue(() =>
                {
                    if (isNewInsert)
                    {
                        dbRepository.InsertRecord(version);
                    }
                    else
                    {
                        dbRepository.UpdateRecord(version);
                    }
                });
            }
        }

        public void UpdateMembers()
        {
            memberHelper.GetMembers().ContinueWith(x =>
            {
                if (x.IsCompleted)
                {

                }
            });
        }
        public void UpdateMembership()
        {
            memberHelper.GetMembership().ContinueWith(x =>
            {
                if (x.IsCompleted)
                {

                }
            });
        }
    }
}
