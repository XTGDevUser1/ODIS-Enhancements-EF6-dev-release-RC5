using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Communication
{
    
    /// <summary>
    /// Notifier Interface to Create notifications for diffrent services.
    /// </summary>
    public interface INotifier
    {
        void Notify(CommunicationQueue communicationQueue);
    }
}
