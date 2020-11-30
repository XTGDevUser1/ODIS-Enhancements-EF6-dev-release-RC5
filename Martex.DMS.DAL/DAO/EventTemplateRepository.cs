using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using System.Data.Entity;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class EventTemplateRepository
    {
        /// <summary>
        /// Gets the template by id.
        /// </summary>
        /// <param name="templateId">The template id.</param>
        /// <returns></returns>
        public EventTemplate GetTemplateById(int? templateId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                EventTemplate template = dbContext.EventTemplates.Where(x => x.ID == templateId)
                    .Include(x => x.Template)
                    .Include(x => x.Event)
                    .FirstOrDefault();
                return template;
            }
        }
    }
}
