using System.Collections.Generic;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;


namespace Martex.DMS.BLL.Communication
{
    /// <summary>
    /// NotifierFactory
    /// </summary>
    public class NotifierFactory
    {
        /// <summary>
        /// Gets the notifiers.
        /// </summary>
        /// <param name="communicationQueue">The communication queue.</param>
        /// <returns></returns>
        public static INotifier GetNotifiers(CommunicationQueue communicationQueue)
        {
            INotifier iNotifier = null;
            ContactStaticDataRepository repository = new ContactStaticDataRepository();
            ContactMethod contactMethod = repository.GetMethodByID(communicationQueue.ContactMethodID.Value);
            // Get ContactMethod object by ID and use the name in the switch case statement.
            switch (contactMethod.Name)
            {
                case ContactMethodNames.PHONE:
                    {
                        break;
                    }
                case ContactMethodNames.TEXT:
                    {
                        iNotifier = new SMSNotifier();
                        break;
                    }
                case ContactMethodNames.EMAIL:
                    {
                        iNotifier = new EmailNotifier();
                        break;
                    }
                case ContactMethodNames.FAX:
                    {
                        iNotifier = new TwilioFaxNotifier();
                        break;
                    }
                case ContactMethodNames.IVR:
                    {
                        iNotifier = new AmazonConnectNotifier();
                        break;
                    }
                case ContactMethodNames.DESKTOP_NOTIFICATION:
                    {
                        iNotifier = new DesktopNotifier();
                        break;
                    }
                case ContactMethodNames.MOBILE_NOTIFICATION:
                    {
                        iNotifier = new MobileNotifier();
                        break;
                    }
                default:
                    break;
            }
            return iNotifier;
        }
    }
}
