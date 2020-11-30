using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DAO.VendorPortal;
using Martex.DMS.BLL.Model.VendorPortal;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using log4net;

namespace Martex.DMS.BLL.Facade.VendorPortal
{
    public class MessageFacade
    {
        MessageRepository repository = new MessageRepository();
        protected static ILog logger = LogManager.GetLogger(typeof(MessageFacade));

        public List<Message> GetMessages(string scope)
        {
            return repository.GetMessages(scope);
        }
    }
}
