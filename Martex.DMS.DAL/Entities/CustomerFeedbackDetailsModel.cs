using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.DAL.Entities
{
    public class CustomerFeedbackDetailsModel
    {        
        public int CustomerFeedbackDetailId { get; set; }
        public int CustomerFeedbackId { get; set; }
        public int? CustomerFeedbackTypeId { get; set; }
        public string CustomerFeedbackTypeDescription { get; set; }
        public int? CustomerFeedbackCategoryId { get; set; }
        public string CustomerFeedbackCategoryDescription { get; set; }
        public int? UserId { get; set; }
        public string Name { get; set; }
        public int? CustomerFeedbackSubCategoryId { get; set; }
        public string CustomerFeedbackSubCategoryDescription { get; set; }
        public bool IsInvalid { get; set; }
        public string InvalidReason { get; set; }
        public string ResolutionDescription { get; set; }
        public string LoggedInUserId { get; set; }
    }
}
