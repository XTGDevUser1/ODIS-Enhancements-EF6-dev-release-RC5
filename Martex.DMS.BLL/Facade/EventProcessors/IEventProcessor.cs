using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using log4net;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade.EventProcessors
{
    public interface IEventProcessor
    {
        void ProcessEventLog(EventLog eventLog, EventSubscriptionRecipient subscriptionRecipient);
    }
  public class SendSurveyEventProcessor : DefaultEventProcessor
  {
    protected static readonly ILog logger = LogManager.GetLogger(typeof(SendSurveyEventProcessor));
    public override void ProcessEventLog(EventLog eventLog, EventSubscriptionRecipient subscriptionRecipient)
    {
      /*
       * For SendSurvey, we need to collect the following details and send that as EventLog.Data.
       * EventLogID - goes as elogid parameter in the survey link
       * ServiceTeamName
       * ServiceTeamNumber
       * Email (this is already part of the current EventLog.Data
       */
      //var keysFromExistingData = eventLog.Data.XMLToKeyValuePairs();

      //var serviceTeamName = AppConfigRepository.GetValue(AppConfigConstants.SERVICE_TEAM_NAME);
      //var serviceTeamNumber = AppConfigRepository.GetValue(AppConfigConstants.SERVICE_TEAM_NUMBER);
      //var surveyLink = AppConfigRepository.GetValue(AppConfigConstants.SURVEY_LINK);

      //keysFromExistingData.Add("EventLogID", eventLog.ID);
      //keysFromExistingData.Add("ServiceTeamName", serviceTeamName.BlankIfNull());
      //keysFromExistingData.Add("ServiceTeamNumber", serviceTeamNumber.BlankIfNull());

      //surveyLink = TemplateUtil.ProcessTemplate(surveyLink, keysFromExistingData);

      //keysFromExistingData.Add("SurveyLink", surveyLink.BlankIfNull());

      //eventLog.Data = keysFromExistingData.GetEventDetail();

      //base.ProcessEventLog(eventLog, subscriptionRecipient);
    }
  }
}
