using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{
    public class VendorApplicationPaymentTypeRepository
    {

        /// <summary>
        /// Adds the specified VendorApplicationPaymentType.
        /// </summary>
        /// <param name="vapt">The VendorApplicationPaymentType.</param>
        /// <param name="paymentType">Type of the payment.</param>
        public void Add(VendorApplicationPaymentType vapt, string paymentType)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var paymentTypeFromDB = dbContext.PaymentTypes.Where(p => p.Name == paymentType).FirstOrDefault();
                if (paymentTypeFromDB == null)
                {
                    throw new DMSException(string.Format("Payment type - {0} is not set up in the system",paymentType));
                }
                vapt.PaymentTypeID = paymentTypeFromDB.ID;
                dbContext.VendorApplicationPaymentTypes.Add(vapt);
                dbContext.SaveChanges();
            }
        }
    }
}
