namespace WinDispatchProcessingService
{
    partial class DispatchProcessingService
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.backgroundWorker_DispatchProcessing = new System.ComponentModel.BackgroundWorker();
            this.backgroundWorker_CloseLoopStatusServiceArrived = new System.ComponentModel.BackgroundWorker();
            this.backgroundWorker_ServiceRequestStatus_Complete = new System.ComponentModel.BackgroundWorker();
            this.backgroundWorker_ReadyForExport = new System.ComponentModel.BackgroundWorker();
            // 
            // backgroundWorker_DispatchProcessing
            // 
            this.backgroundWorker_DispatchProcessing.WorkerSupportsCancellation = true;
            this.backgroundWorker_DispatchProcessing.DoWork += new System.ComponentModel.DoWorkEventHandler(this.backgroundWorker_DispatchProcessing_DoWork);
            // 
            // backgroundWorker_CloseLoopStatusServiceArrived
            // 
            this.backgroundWorker_CloseLoopStatusServiceArrived.WorkerSupportsCancellation = true;
            this.backgroundWorker_CloseLoopStatusServiceArrived.DoWork += new System.ComponentModel.DoWorkEventHandler(this.backgroundWorker_CloseLoopStatusServiceArrived_DoWork);
            // 
            // backgroundWorker_ServiceRequestStatus_Complete
            // 
            this.backgroundWorker_ServiceRequestStatus_Complete.WorkerSupportsCancellation = true;
            this.backgroundWorker_ServiceRequestStatus_Complete.DoWork += new System.ComponentModel.DoWorkEventHandler(this.backgroundWorker_ServiceRequestStatus_Complete_DoWork);
            // 
            // backgroundWorker_ReadyForExport
            // 
            this.backgroundWorker_ReadyForExport.WorkerSupportsCancellation = true;
            this.backgroundWorker_ReadyForExport.DoWork += new System.ComponentModel.DoWorkEventHandler(this.backgroundWorker_ReadyForExport_DoWork);
            // 
            // DispatchProcessingService
            // 
            this.ServiceName = "Service1";

        }

        #endregion

        private System.ComponentModel.BackgroundWorker backgroundWorker_DispatchProcessing;
        private System.ComponentModel.BackgroundWorker backgroundWorker_CloseLoopStatusServiceArrived;
        private System.ComponentModel.BackgroundWorker backgroundWorker_ServiceRequestStatus_Complete;
        private System.ComponentModel.BackgroundWorker backgroundWorker_ReadyForExport;
    }
}
