using ODISMember.Entities.Model;
using System;
using System.Collections.Generic;

namespace ODISMember.Common
{
    public static class ConstantData
    {
        public static Dictionary<int, string> MemberPlans = new Dictionary<int, string>() {
            {0, "Light Duty Roadside Basic - Individual"},
            {1, "Light Duty - Roadside Basic - Family"},
            {2, "Light Duty - Roadside Plus - Individual"},
            {3, "Light Duty - Roadside Plus - Family"},
            {4, "Light Duty - Roadside Premier - Individual"},
            {5, "Light Duty - Roadside Premier - Family"},
            {6, "Medium Duty - Roadside Basic - Individual"},
            {7, "Medium Duty - Roadside Basic - Family"},
            {8, "Medium Duty - Roadside Plus - Individual"},
            {9, "Medium Duty - Roadside Plus - Family"}
        };
        public static Dictionary<int, string> Suffix = new Dictionary<int, string>() {
            {0, "Mr."},
            {1, "Miss."},
            {2, "Mrs."}
        };
        public static Dictionary<int, string> StateProvince = new Dictionary<int, string>() {
            {0, "AP"},
            {1, "TS"},
            {2, "TX"}
        };
        public static Dictionary<int, string> CountryProvince = new Dictionary<int, string>() {
            {0, "IN - India"}
        };
        public static Dictionary<int, string> CreditCardType = new Dictionary<int, string>() {
            {0, "Amex"},
            {1, "Visa"},
            {2, "MC"},
            {3, "Discover"}
        };
        public static Dictionary<int, string> ContactMethod = new Dictionary<int, string>() {
            {0, "Email"},
            {1, "Text"}
        };
        public static List<AccountMenu> GetProfileMenu()
        {
            List<AccountMenu> AccountMenuData = new List<AccountMenu>();
            AccountMenuData.Add(new AccountMenu()
            {
                Id = ODISMember.Entities.Constants.accountProfileMenu.Membership,
                MenuTitle = "Membership",
                isOn = false
            });
            AccountMenuData.Add(new AccountMenu()
            {
                Id = ODISMember.Entities.Constants.accountProfileMenu.Members,
                MenuTitle = "Members",
                isOn = false
            });
            AccountMenuData.Add(new AccountMenu()
            {
                Id = ODISMember.Entities.Constants.accountProfileMenu.ChangePassword,
                MenuTitle = "Change Password",
                isOn = false
            });
            return AccountMenuData;

        }
        public static List<AccountMenu> GetSettingsMenu()
        {
            List<AccountMenu> AccountMenuData = new List<AccountMenu>();
            AccountMenuData.Add(new AccountMenu()
            {
                Id = ODISMember.Entities.Constants.accountProfileMenu.Other,
                MenuTitle = "Notifications",
                isOn = false
            });
            AccountMenuData.Add(new AccountMenu()
            {
                Id = ODISMember.Entities.Constants.accountProfileMenu.Other,
                MenuTitle = "Location Service",
                isOn = false
            });
            return AccountMenuData;

        }
    }
}

