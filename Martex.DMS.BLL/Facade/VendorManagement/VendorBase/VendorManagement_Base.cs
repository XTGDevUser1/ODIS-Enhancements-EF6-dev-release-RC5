using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade.VendorManagement.VendorBase
{
    public class VendorManagement_Base
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VendorManagement_Base));
        #endregion

        #region Private Members
        /// <summary>
        /// The Vendor Management Repository
        /// </summary>
        protected VendorManagementRepository repository = new VendorManagementRepository();
        protected VendorInvoiceRepository viRepository = new VendorInvoiceRepository();
        protected AddressRepository addressRepository = new AddressRepository();
        protected VendorManagementRepository vendorManagement_Repository = new VendorManagementRepository();

        #endregion
    }
}
