using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Facade
{
    public class DeviceFacade
    {
        DeviceRepository repo = new DeviceRepository();

        public void RegisterDevice(List<MobileDeviceRegistration> tags)
        {            
            repo.RegisterDevice(tags);
        }

        public List<MobileDeviceRegistration> GetDevices(List<string> tags)
        {
            return repo.GetDevices(tags);
        }
    }
}
