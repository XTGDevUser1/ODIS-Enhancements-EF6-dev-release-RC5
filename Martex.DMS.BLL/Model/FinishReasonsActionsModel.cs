using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// FinishReasonsActionsModel
    /// </summary>
    public class FinishReasonsActionsModel
    {
        public List<ContactReason> ContactReasons
        {
            get;
            set;
        }

        public List<ContactAction> ContactActions
        {
            set;
            get;
        }
    }
}