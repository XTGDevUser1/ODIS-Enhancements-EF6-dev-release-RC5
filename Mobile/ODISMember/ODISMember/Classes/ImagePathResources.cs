using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Classes
{
    public static class ImagePathResources
    {
        public static readonly string LoginBackgroundImage = "launch.png";
        public static readonly string InitializingBackgroundImage = Device.OnPlatform("InitializingBackgroundImage.png", "launch.png", null);
        public static readonly string Logo = "pinnacleLogo.png";
        public static readonly string NoImage = "noImage.png";
        public static readonly string RemoveImage = "error.png";
        public static readonly string AddVehicleActive = "ic_add_a_photo_black_48dp.png";//"pmc_add_vehicle_photo_active_red.png";
        public static readonly string AddProfileActive = "pmc_add_profile_photo_active_red.png";
        public static readonly string AddVehicleGrey = "pmc_add_vehicle_photo_grey.png";
        public static readonly string EssentialRoadsideHeader = "EssentialRoadside_header.png";
        public static readonly string HomeLogoBackground = "GettyImages_525805669.png";
        public static readonly string LogoImage = "pinnacleLogoWhiteBackground.png";//"pinnacleLogo.png";// "pinnacle_logo_transparent_white_bg.png";//"pinnacleLogo.png";
        public static readonly string CardShadowBackground = "Shadow.png";
        //vehicle Icons
        public static readonly string VehicleCar = Device.OnPlatform("auto_list_icon.png", "ic_directions_car_black_48dp.png", null);
        public static readonly string VehicleRv = Device.OnPlatform("rv_list_icon.png", "ic_directions_bus_black_48dp.png",null);
        public static readonly string VehicleMotorCycle = Device.OnPlatform("motorcycle_list_icon.png", "ic_motorcycle_black_48dp.png",null);
        public static readonly string ArrowSymbol = "ic_keyboard_arrow_right_black_48dp.png";

        public static readonly string LogoTransparent = "pinnacleLogoWhiteBackground.png";
        public static readonly string PageBackIcon = "ic_back_black_24dp.png";
		public static readonly string DefaultIcon = "icon.png";

		public static readonly string DrawerMenuIcon ="drawerMenu.png";
        public static readonly string ProfileDeafultImage = "ic_account_circle_white_24dp.png";

        //RoadSide Page
        public static readonly string UserCurrentLocationIcon = "ic_current_location.png";

        //Toolbar icons
        public static readonly string AddIcon = "ic_add_black_24dp.png";
		public static readonly string EditIcon = "ic_edit_black_24dp.png";
		public static readonly string RemoveIcon = "ic_remove_circle_outline_black_24dp.png";
        public static readonly string SendIcon = "ic_send_black_24dp.png";

        public static readonly string Tip = "pmc_tips_grey_active_red";

        public static readonly string CardFront = "cardFrontSample.png";
        public static readonly string CardBack = "cardBackSample.png";

        public static readonly string SaveIcon = "ic_save_black_24dp.png";

        //Vehicle Services
        public static readonly string TowService = "pmc_services_tow_active_red.png";
        public static readonly string TireService = "pmc_services_flat_tire_active_red.png";
        public static readonly string LockoutService = "pmc_services_lockout_active_red.png";
        public static readonly string FluidService = "pmc_services_fuel_active_red.png";
        public static readonly string JumpService = "pmc_services_jumpstart_active_red.png";
        public static readonly string WinchService = "pmc_services_winch_active_red.png";
        
        //Vehicle Services questions
        public static readonly string TowServiceQuestions = "tow.png";
        public static readonly string TireServiceQuestions = "tire.png";
        public static readonly string LockoutServiceQuestions = "lockout.png";
        public static readonly string FluidServiceQuestions = "fluid.png";
        public static readonly string JumpServiceQuestions = "jumpstart.png";
        public static readonly string WinchServiceQuestions = "winch.png";

        public static readonly string TowServiceDisabled = "pmc_services_tow_grey.png";

        #region Left Menu Icons
        public static readonly string AccountIcon = "pmc_account_white.png";
        public static readonly string VehicleIcon = "pmc_sidenav_vehicles";
        public static readonly string HistoryIcon = "pmc_sidenav_history";
        public static readonly string HelpIcon = "pmc_sidenav_help_grey";
        public static readonly string LogoutIcon = "pmc_sidenav_logout";
        public static readonly string ProfileIcon = "pmc_profile_account_white";
        public static readonly string SettingsIcon = "pmc_sidenav_account.png";
        #endregion

        #region Bottom Menu Icons
        public static readonly string HomeBottomIcon = "pmc_bottombar_home_inactive";// Device.OnPlatform("ic_home_white_24dp.png", "ic_home_white_24dp.png", "ic_home_white_24dp.png");
        public static readonly string MyCardIcon = "pmc_bottombar_my_card_inactive"; //Device.OnPlatform("ic_access_time_white_24dp.png", "ic_access_time_white_24dp.png", "ic_access_time_white_24dp.png");
        public static readonly string GetHelpIcon = "pmc_bottombar_get_help_inactive";//Device.OnPlatform("ic_add_location_white_24dp.png", "ic_add_location_white_24dp.png", "ic_add_location_white_24dp.png");
        public static readonly string BenefitBottomIcon = "pmc_bottombar_benefits_inactive";
        public static readonly string MoreIcon = "pmc_bottombar_more_inactive";
        /*Selected Icons*/
        public static readonly string HomeBottomIconSelected = "pmc_bottombar_home_active_red";
        public static readonly string MyCardIconSelected = "pmc_bottombar_my_card_active_red";
        public static readonly string GetHelpIconSelected = "pmc_bottombar_get_help_active_red";
        public static readonly string BenefitBottomIconSelected = "pmc_bottombar_benefits_active_red";
        public static readonly string MoreIconSelected = "pmc_bottombar_more_active_red";
        public static readonly string CancelIcon = "ic_cancel_black_24dp.png";
        #endregion Bottom Menu Icons

       
        #region Profile Icons
        public static readonly string ProfileMenuDeafultImage = "pmc_add_profile_photo.png";
        #endregion

        //Custom control Date pickers
        public static readonly string DatePickerIcon = "icDatePicker.png";

    }
}
