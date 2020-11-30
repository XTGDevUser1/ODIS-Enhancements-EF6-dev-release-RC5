using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using Martex.DMS.BLL.Facade;
using log4net;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;

namespace WindowsCommunicationService
{
    public partial class CommunicationService : ServiceBase
    {
        System.Timers.Timer t_Service = null;
        CommunicationServiceFacade communicationService = null;
        protected static readonly ILog logger = LogManager.GetLogger(typeof(CommunicationService));


        private int timerInterval = 0;
        public CommunicationService()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            if (t_Service == null)
            {
                string timer_interval = AppConfigRepository.GetValue(AppConfigConstants.Event_Notification_Service_Sleep_Interval);
                logger.Info("Communication Service Service Sleep Interval is " + timer_interval);
                int.TryParse(timer_interval, out timerInterval);
                if (timerInterval == 0)
                {
                    timerInterval = 30000;
                }
                t_Service = new System.Timers.Timer();
                t_Service.Interval = timerInterval;

                t_Service.Elapsed += new System.Timers.ElapsedEventHandler(t_Service_Elapsed);

                t_Service.Enabled = true;
            }
            if (communicationService == null)
            {
                communicationService = new CommunicationServiceFacade();
            }

            logger.Info("Communication Service Started.");
            t_Service.Start();
        }

        void t_Service_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            if (!backgroundWorker_Communication.IsBusy)
            {
                backgroundWorker_Communication.RunWorkerAsync();
            }
        }


        protected override void OnStop()
        {
            if (t_Service != null)
            {
                t_Service.Stop();
                backgroundWorker_Communication.CancelAsync();
                logger.Info("Communication Service Stopped.");
            }
        }

        private void backgroundWorker_Communication_DoWork(object sender, DoWorkEventArgs e)
        {

            communicationService.SendNotification();

        }
    }
}
