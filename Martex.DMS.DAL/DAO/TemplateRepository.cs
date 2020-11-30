using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class TemplateRepository
    {
        /// <summary>
        /// Gets the template by ID.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public Template GetTemplateByID(int id)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.Templates.Where(u => u.ID == id).FirstOrDefault();
            }
        }
        /// <summary>
        /// Gets the name of the template by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public Template GetTemplateByName(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.Templates.Where(u => u.Name.Equals(name)).FirstOrDefault();
            }
        }
    }
}
