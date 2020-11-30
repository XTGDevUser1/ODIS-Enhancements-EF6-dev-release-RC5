using System;
using Xamarin.Forms.Maps;

namespace ODISMember
{
    
    public class AppConstants
	{
        public static class Event
        {
            public static int OPEN_HOME = 1001;
            public static int OPEN_MYCARD = 1002;
            public static int OPEN_GET_HELP = 1003;
            public static int OPEN_BENEFIT = 1004;
            public static int OPEN_MORE = 1005;
            public static int OPEN_LOGOUT = 1006;

            public static int OPEN_ACCOUNT = 1007;
            public static int OPEN_VEHICLES = 1008;
            public static int OPEN_HISTORY = 1009;
            public static int OPEN_HELP = 1010;
            public static int OPEN_SETTINGS = 1011;
            public static int OPEN_REQUEST_SUCCESS = 1012;
            public static int OPEN_STATUS = 1013;
            public static int OPEN_PROFILE = 1014;

            public static int RESET_BOTTOM_MENU = 1100;
            public static int RESET_LEFT_MENU = 1101;
            public static int OPEN_LEFT_MENU = 1102;

            public static int REFRESH_VEHICLES = 2000;
            public static int REFRESH_ACCOUNT = 2001;
            public static int REFRESH_MEMBERS = 2003;
            public static int REFRESH_MEMBERSHIP_DETAILS = 2004;
            public static int REFRESH_MEMBER_DETAILS = 2005;
            public static int REFRESH_ACTIVE_REQUEST = 2006;
            public static int REFRESH_HELP = 2007;
            public static int ADD_SOURCE_MAP = 2008;
            public static int REMOVE_SOURCE_MAP = 2009;
            public static int REFRESH_STATUS = 2010;
            public static int REFRESH_CURRENT_MEMBER_DETAILS = 2011;

            public static int START_REFRESH_MEMBERS_SYNC = 2012;

            public static int MEMBER_DATA_UPDATED_LOCALLY = 2013;
            public static int MEMBERSHIP_DATA_UPDATED_LOCALLY = 2014;
            public static int APPLICATION_SETTINGS_DATA_UPDATED_LOCALLY = 2015;
            public static int REFRESH_CURRENT_VEHICLE = 2016;
            public static int ADD_CURRENT_LOCATION_POINT = 2017;
            public static int CALL_SCREENSHOOT = 2018;
        }


        public static Distance DISTANCE =new Distance(300);
        public static Distance DISTANCE_DEFAULT = Distance.FromMiles(300);
    }
}

