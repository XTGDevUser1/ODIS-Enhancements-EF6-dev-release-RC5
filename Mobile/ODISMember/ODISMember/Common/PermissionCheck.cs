using Plugin.Permissions;
using Plugin.Permissions.Abstractions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Common
{
    public static class PermissionCheck
    {
        public static async Task<PermissionStatus> AskPermission(Permission permission)
        {

            var status = PermissionStatus.Unknown;
            switch (permission)
            {
                case Permission.Calendar:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Calendar);
                    break;
                case Permission.Camera:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Camera);
                    break;
                case Permission.Contacts:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Contacts);
                    break;
                case Permission.Microphone:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Microphone);
                    break;
                case Permission.Phone:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Phone);
                    break;
                case Permission.Photos:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Photos);
                    break;
                case Permission.Reminders:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Reminders);
                    break;
                case Permission.Sensors:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Sensors);
                    break;
                case Permission.Sms:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Sms);
                    break;
                case Permission.Storage:
                    status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Storage);
                    break;
            }
            if (status != PermissionStatus.Granted)
            {
                switch (permission)
                {
                    case Permission.Calendar:
                        status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Calendar))[Permission.Calendar];
                        break;
                    case Permission.Camera:
                      //  var results = await CrossPermissions.Current.RequestPermissionsAsync(new[] { Permission.Camera });
                       // status = results[Permission.Camera];
                         status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Camera))[Permission.Camera];
                        break;
                    case Permission.Contacts:
                        status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Contacts))[Permission.Contacts];
                        break;
                    case Permission.Microphone:
                        status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Microphone))[Permission.Microphone];
                        break;
                    case Permission.Phone:
                        status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Phone))[Permission.Phone];
                        break;
                    case Permission.Photos:
                        status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Photos))[Permission.Photos];
                        break;
                    case Permission.Reminders:
                        status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Reminders))[Permission.Reminders];
                        break;
                    case Permission.Sensors:
                        status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Sensors))[Permission.Sensors];
                        break;
                    case Permission.Sms:
                        status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Sms))[Permission.Sms];
                        break;
                    case Permission.Storage:
                        status = (await CrossPermissions.Current.RequestPermissionsAsync(Permission.Storage))[Permission.Storage];
                        break;
                }

                switch (permission)
                {
                    case Permission.Calendar:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Calendar);
                        break;
                    case Permission.Camera:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Camera);
                        break;
                    case Permission.Contacts:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Contacts);
                        break;
                    case Permission.Microphone:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Microphone);
                        break;
                    case Permission.Phone:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Phone);
                        break;
                    case Permission.Photos:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Photos);
                        break;
                    case Permission.Reminders:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Reminders);
                        break;
                    case Permission.Sensors:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Sensors);
                        break;
                    case Permission.Sms:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Sms);
                        break;
                    case Permission.Storage:
                        status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Storage);
                        break;
                }
            }
            return status;
        }
    }
}
