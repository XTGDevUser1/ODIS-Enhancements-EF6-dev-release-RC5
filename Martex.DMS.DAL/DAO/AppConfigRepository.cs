using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class AppConfigRepository
    {

        /// <summary>
        /// Gets the App config value for a given key. Returns null if the key is not available.
        /// </summary>
        /// <param name="key">The key.</param>
        /// <returns>Value if one is found for the given key, null otherwise.</returns>
        public static string GetValue(string key)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var appConfigValue = dbContext.ApplicationConfigurations.Where(x => x.Name == key).FirstOrDefault();
                if (appConfigValue != null)
                {
                    return appConfigValue.Value;
                }
            }
            return null;

        }

        public static string GetValue(string key,string type)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {                
                var appConfigValue = dbContext.ApplicationConfigurations.Where(x => x.Name == key && x.ApplicationConfigurationType.Name.Equals(type)).FirstOrDefault();
                if (appConfigValue != null)
                {
                    return appConfigValue.Value;
                }
                else
                {
                    throw new DMSException(string.Format("Unable to find the configuration for {0}", type));
                } 
            }
       
        }

        /// <summary>
        /// Gets the application configuration.
        /// </summary>
        /// <param name="type">The type.</param>
        /// <param name="category">The category.</param>
        /// <returns></returns>
        public ApplicationConfiguration GetApplicationConfiguration(string type, string category)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.ApplicationConfigurations.Where(u => u.ApplicationConfigurationCategory.Name.Equals(category))
                                                         .Where(t => t.ApplicationConfigurationType.Name.Equals(type))
                                                         .FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the application configuration list.
        /// </summary>
        /// <param name="type">The type.</param>
        /// <param name="category">The category.</param>
        /// <returns></returns>
        public List<ApplicationConfiguration> GetApplicationConfigurationList(string type, string category)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.ApplicationConfigurations.Where(u => u.ApplicationConfigurationCategory.Name.Equals(category))
                                                         .Where(t => t.ApplicationConfigurationType.Name.Equals(type)).ToList();
                                                         
            }
        }
    }
}
