using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;       //Lakshmi - Queue Color

namespace Martex.DMS.DAL
{
    public partial class Queue_Result
    {
        public string FormattedElapsedTime
        {
            get
            {
                if (this.Submitted == null)
                {
                    return string.Empty;
                }
                
                //int totalMinutes = int.Parse(this.Elapsed) / 60;
                //int totalSeconds = int.Parse(this.Elapsed) % 60;
               // int totalHours = totalMinutes / 60;
              //  totalMinutes = totalMinutes % 60;

                //return string.Format("{0:d2}:{1:d2}:{2:d2}", totalHours, totalMinutes, totalSeconds);
                return string.Format("{0:d2}", Elapsed);
            }
        }

        //Lakshmi - Queue Color
        public string StatusColor
        {
            get
            {
                string color = string.Empty;

                switch (this.Status)
                {
                    case "Entry":
                    case "Entry^":
                        
                        return GetQueueStatusColor(this.Status,this.ScheduledOriginal, this.StatusDateModified);

                    case "Submitted":
                    case "Submitted^":

                        return GetQueueStatusColor(this.Status, this.ScheduledOriginal, this.StatusDateModified);

                    case "Dispatched":
                    case "Dispatched^":

                        return GetQueueStatusColor(this.Status, this.ScheduledOriginal, this.StatusDateModified);

                    default:
                        return color;
                }


            }
        }

        //Lakshmi - Queue Color
        public static List<QueueStatu> QueueStatusList
        {
            get
            {
                return (Martex.DMS.DAL.DAO.QueueRepository.QueueStatusList == null) ? Martex.DMS.DAL.DAO.QueueRepository.GetQueueStatusList() : Martex.DMS.DAL.DAO.QueueRepository.QueueStatusList;
                
            }
        }

        //Lakshmi - Queue Color
        private string GetQueueStatusColor(string statusName,DateTime? scheduledDate,DateTime? statusModifiedDate)
        {
            string color = string.Empty;
            Martex.DMS.DAL.DAO.QueueRepository queueRep = new DAO.QueueRepository();

            try
            {
                if (!string.IsNullOrEmpty(this.NextAction))
                {
                    color = queueRep.GetQueueStatusColor(statusName, this.NextAction);
                    if (!string.IsNullOrEmpty(color))
                    {
                        return color;
                    }

                }

                if (scheduledDate!=null)    
                {
                    if (((scheduledDate.Value == DateTime.Now) | (scheduledDate.Value <= DateTime.Now)) & (DateTime.Now.Subtract(scheduledDate.Value).TotalMinutes) >= 0)
                    {
                        List<QueueStatu> filterStatus = QueueStatusList.Where(x =>
                                           ((x.SRStatusName.Trim().ToUpper() == this.Status.Trim().ToUpper()) | (x.SRStatusName + "^".Trim().ToUpper() == this.Status.Trim().ToUpper())) &
                                                       (x.IsActive.Value) & (x.Action != null) & (x.Action == "Scheduled") &
                                                    ((DateTime.Now.Subtract(scheduledDate.Value)).TotalMinutes) >= x.Minutes).OrderByDescending(x => x.Minutes).ToList();

                        color = (filterStatus.Count > 0) ? filterStatus.FirstOrDefault().Color : string.Empty;

                    }

                }
                else if (statusModifiedDate!=null)
                {
                    if (DateTime.Now.Subtract(statusModifiedDate.Value).TotalMinutes > 0)
                    {
                        List<QueueStatu> filterStatus = QueueStatusList.Where(x =>
                                       ((x.SRStatusName.Trim().ToUpper() == this.Status.Trim().ToUpper()) | (x.SRStatusName + "^".Trim().ToUpper() == this.Status.Trim().ToUpper())) &
                                       x.Action == null &
                                       x.IsActive.Value & (DateTime.Now.Subtract(statusModifiedDate.Value)).TotalMinutes >= x.Minutes).OrderByDescending(x => x.Minutes).ToList();

                        color = (filterStatus.Count > 0) ? filterStatus.FirstOrDefault().Color : string.Empty;

                    }

                }
                return color;
            }
            catch
            {
                
            }
            return color;
        }

        //TFS : 386
        public string ScheduledColumnBackGroundColor
        {
            get
            {
                if (this.ScheduledOriginal.HasValue)
                {
                    if (this.ScheduledOriginal.GetValueOrDefault() <= DateTime.Now)
                    {
                        return "#F2DEDE";
                    }
                }
                return string.Empty;
            }
        }
        
    }
}
