using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Extensions;

namespace Martex.DMS.BLL.Facade
{
    public class ClientRepMaintenanceFacade
    {
        protected static ILog logger = LogManager.GetLogger(typeof(ClientRepMaintenanceFacade));

        ClientRepMaintenanceRepository repository = new ClientRepMaintenanceRepository();

        public List<ClientRepList_Result> ClientRepList(PageCriteria criteria)
        {
            return repository.ClientRepList(criteria);
        }

        public ClientRep Get(int recordID, bool createIfNotExists = false)
        {
            return repository.Get(recordID, createIfNotExists);
        }

        public void SaveClientRepDetails(ClientRep model, string LoggedInUserName, string eventSource, string sessionID)
        {
            var clientRepID = model.ID;
            repository.SaveClientRepDetails(model, LoggedInUserName);

            EventLogRepository eventLogRepository = new EventLogRepository();

            IRepository<Event> eventRepository = new EventRepository();
            var eventName = EventNames.CREATE_CLIENT_REP;
            if (clientRepID > 0)
            {
                eventName = EventNames.UPDATE_CLIENT_REP;
            }
            Event theEvent = eventRepository.Get<string>(eventName);

            if (theEvent == null)
            {
                throw new DMSException("Invalid event name " + eventName);
            }
            Hashtable ht = new Hashtable();
            ht.Add("FirstName", model.FirstName);
            ht.Add("LastName", model.LastName);
            ht.Add("Title", model.Title);
            ht.Add("Email", model.Email);
            ht.Add("PhoneNumber", model.PhoneNumber);
            ht.Add("MobileNumber", model.MobileNumber);

            EventLog eventLog = new EventLog();
            eventLog.Source = eventSource;
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Description = theEvent.Description;
            eventLog.Data = ht.GetMessageData();
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = LoggedInUserName;

            logger.InfoFormat("Trying to log the event {0}", eventName);
            long eventLogId = eventLogRepository.Add(eventLog, model.ID, EntityNames.CLIENT_REP);

        }

        public void DeleteClientRep(int recordID, string LoggedInUserName)
        {
            repository.DeleteClientRep(recordID, LoggedInUserName);
        }
    }
}
