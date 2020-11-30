using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
   public class ContactLogActionFacade
   {
       #region Public Methods
       
       /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
       public void Save(ContactLogAction model, string userName)
       {
           ContactLogActionRepository contactLogActionRepository = new ContactLogActionRepository();
           contactLogActionRepository.Save(model, userName);
       }

       #endregion
   }
}
