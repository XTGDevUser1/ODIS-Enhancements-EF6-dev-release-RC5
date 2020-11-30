using SQLite.Net.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities
{
    public class SettingsTable
    {
        [PrimaryKey, AutoIncrement]
        public int Id { get; set; }
        public string MemberNumber { get; set; }
        public bool IsLocationAllowed { get; set; }
        public bool IsNotificationEnabled { get; set; }
        public bool IsLoggingEnabled { get; set; }
        public bool IsCameraPermissionAsked { get; set; }
        public bool IsLocationPermissionAsked { get; set; }
        public bool IsGalleryPermissionAsked { get; set; }
        public bool IsWalkthroughShown { get; set; }

    }
}
