using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using log4net;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;

namespace WinDispatchProcessingService
{
    public partial class DispatchProcessingService : ServiceBase
    {
        System.Timers.Timer t_Service = null;
        System.Timers.Timer t_Service_A = null;
        System.Timers.Timer t_Service_B = null;
        System.Timers.Timer t_Service_C = null;
        DispatchProcessingServiceFacade dispatchServiceFacade = null;
        protected static readonly ILog logger = LogManager.GetLogger(typeof(DispatchProcessingService));
        DispatchProcessingServiceRepository dispatchServiceRepository = new DispatchProcessingServiceRepository();
        int timerInterval = 30 * 1000;
        int timerInterval_For_A = 5 * 60 * 1000;
        int timerInterval_For_B = 5 * 60 * 1000;
        int timerInterval_For_C = 5 * 60 * 1000;

        //int timerInterval_For_A = 60 * 60 * 1000;
        //int timerInterval_For_B = 48 * 60 * 60 * 1000;
        //int timerInterval_For_C = 330 * 60 * 1000;

        public DispatchProcessingService()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            if (t_Service == null)
            {
                // Get all the times intervals
                //string timer_intervalString_For_A = AppConfigRepository.GetValue(AppConfigConstants.AGING_CLOSE_LOOP_MINUTES_Service_Sleep_Interval);
                //string timer_intervalString_For_B = AppConfigRepository.GetValue(AppConfigConstants.AGING_SERVICE_REQUEST_HOURS_Service_Sleep_Interval);
                //string timer_intervalString_For_C = AppConfigRepository.GetValue(AppConfigConstants.AGING_READY_FOR_EXPORT_MINUTES_Service_Seleep_Interval);

                //if (!string.IsNullOrEmpty(timer_intervalString_For_A))
                //{
                //    int.TryParse(timer_intervalString_For_A, out timerInterval_For_A);
                //    timerInterval_For_A = timerInterval_For_A * 60 * 1000;
                //}
                //if (!string.IsNullOrEmpty(timer_intervalString_For_B))
                //{
                //    int.TryParse(timer_intervalString_For_B, out timerInterval_For_B);
                //    timerInterval_For_B = timerInterval_For_B * 60 * 60 * 1000;
                //}
                //if (!string.IsNullOrEmpty(timer_intervalString_For_C))
                //{
                //    int.TryParse(timer_intervalString_For_C, out timerInterval_For_C);
                //    timerInterval_For_C = timerInterval_For_C * 60 * 1000;
                //}


                logger.Info("Dispatch Processing Service Time Interval is [MS]" + timerInterval);
                logger.Info("Service Request Closed Loop Status to Service Arrived  Time Interval is [MS]" + timerInterval_For_A);
                logger.Info("Age Service Request Status to Complete Time Interval is [MS]" + timerInterval_For_B);
                logger.Info("Service Request Ready for Export Time Interval is [MS]" + timerInterval_For_C);
                t_Service = new System.Timers.Timer();
                t_Service.Interval = timerInterval;
                t_Service.Elapsed += new System.Timers.ElapsedEventHandler(t_Service_Elapsed);
                t_Service.Enabled = true;

                //FOR Age Service Request Closed Loop Status to Service Arrived
                t_Service_A = new System.Timers.Timer();
                t_Service_A.Interval = timerInterval_For_A;
                t_Service_A.Elapsed += new System.Timers.ElapsedEventHandler(t_Service_A_Elapsed);
                t_Service_A.Enabled = true;

                //FOR Age Service Request Status to Complete
                t_Service_B = new System.Timers.Timer();
                t_Service_B.Interval = timerInterval_For_B;
                t_Service_B.Elapsed += new System.Timers.ElapsedEventHandler(t_Service_B_Elapsed);
                t_Service_B.Enabled = true;

                //FOR Set Service Request Ready for Export
                t_Service_C = new System.Timers.Timer();
                t_Service_C.Interval = timerInterval_For_C;
                t_Service_C.Elapsed += new System.Timers.ElapsedEventHandler(t_Service_C_Elapsed);
                t_Service_C.Enabled = true;

            }
            if (dispatchServiceFacade == null)
            {
                dispatchServiceFacade = new DispatchProcessingServiceFacade();
            }

            logger.Info("Dispatch Processing Service Started.");
            t_Service.Start();
            logger.Info("Age Service Request Closed Loop Status to Service Arrived Started.");
            t_Service_A.Start();
            logger.Info("Age Service Request Status to Complete Started.");
            t_Service_B.Start();
            logger.Info("Set Service Request Ready for Export  Started.");
            t_Service_C.Start();
        }

        void t_Service_C_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            if (!backgroundWorker_ReadyForExport.IsBusy)
            {
                backgroundWorker_ReadyForExport.RunWorkerAsync();
            }
        }

        void t_Service_B_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            if (!backgroundWorker_ServiceRequestStatus_Complete.IsBusy)
            {
                backgroundWorker_ServiceRequestStatus_Complete.RunWorkerAsync();
            }
        }

        void t_Service_A_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            if (!backgroundWorker_CloseLoopStatusServiceArrived.IsBusy)
            {
                backgroundWorker_CloseLoopStatusServiceArrived.RunWorkerAsync();
            }
        }

        void t_Service_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            if (!backgroundWorker_DispatchProcessing.IsBusy)
            {
                backgroundWorker_DispatchProcessing.RunWorkerAsync();
            }
        }

        protected override void OnStop()
        {
            if (t_Service != null)
            {
                t_Service.Stop();
                backgroundWorker_DispatchProcessing.CancelAsync();
                logger.Info("Dispatch Processing Service Stopped.");
            }
            if (t_Service_A != null)
            {
                t_Service_A.Stop();
                backgroundWorker_CloseLoopStatusServiceArrived.CancelAsync();
                logger.Info("Service Request Closed Loop Status to Service Arrived is Stopped.");
            }
            if (t_Service_B != null)
            {
                t_Service_B.Stop();
                backgroundWorker_ServiceRequestStatus_Complete.CancelAsync();
                logger.Info("Age Service Request Status to Complete is Stopped.");
            }
            if (t_Service_C != null)
            {
                t_Service_C.Stop();
                backgroundWorker_ReadyForExport.CancelAsync();
                logger.Info("Service Request Ready for Export is Stopped.");
            }
        }

        private void backgroundWorker_DispatchProcessing_DoWork(object sender, DoWorkEventArgs e)
        {
            // Initate Close Loop
            dispatchServiceFacade.StartProcessing("system");
            
        }

        private void backgroundWorker_CloseLoopStatusServiceArrived_DoWork(object sender, DoWorkEventArgs e)
        {

            // FOR Age Service Request Closed Loop Status to Service Arrived
            dispatchServiceRepository.UpdateServiceRequestClosedLoopStatus();
         
        }

        private void backgroundWorker_ServiceRequestStatus_Complete_DoWork(object sender, DoWorkEventArgs e)
        {
            //FOR Age Service Request Status to Complete
            dispatchServiceRepository.UpdateServiceRequestStatus();
        }

        private void backgroundWorker_ReadyForExport_DoWork(object sender, DoWorkEventArgs e)
        {
            //FOR Set Service Request Ready for Export
            dispatchServiceRepository.PrepareServiceRequestExport();
        }
    }
}
