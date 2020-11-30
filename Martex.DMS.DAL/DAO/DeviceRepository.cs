using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.DAL.DAO
{
    public class DeviceRepository
    {

        public List<MobileDeviceRegistration> GetDevices(List<string> tags)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var allDeviceOS = dbContext.MobileDeviceRegistrations.Where(r => tags.Contains(r.Tag)).ToList();
                var distinctDeviceOS = allDeviceOS.GroupBy(x => x.DeviceOS).Select(grp => grp.FirstOrDefault()).ToList();
                return distinctDeviceOS;
            }
        }

        public void RegisterDevice(List<MobileDeviceRegistration> tags)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                for (int i = 0, iCount = tags.Count; i < iCount; i++)
                {
                    var tag = tags[i];

                    List<MobileDeviceRegistration> registeredDevices = dbContext.MobileDeviceRegistrations.Where(a => a.Tag.Equals(tag.Tag, StringComparison.InvariantCultureIgnoreCase) && a.DeviceOS.Equals(tag.DeviceOS, StringComparison.InvariantCultureIgnoreCase)).ToList();

                    if ((registeredDevices == null) || (registeredDevices.Count() == 0))
                    {
                        MobileDeviceRegistration newMobileRegister = new MobileDeviceRegistration()
                        {
                            Tag = tag.Tag,
                            DeviceOS = tag.DeviceOS,
                            CreateBy = tag.CreateBy,
                            CreateDate = DateTime.Now
                        };
                        dbContext.MobileDeviceRegistrations.Add(newMobileRegister);
                    }
                }

                dbContext.SaveChanges();
            }
        }
    }
}
