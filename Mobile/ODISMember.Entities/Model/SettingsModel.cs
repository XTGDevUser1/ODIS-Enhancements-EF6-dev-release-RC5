using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public enum SettingsEnum
    {
        Location = 1,
        Notification = 2,
        Logs = 3
    }
    public class SettingsModel
    {
        public SettingsEnum SettingType { get; set; }
        public string Text { get; set; }
    }
}
