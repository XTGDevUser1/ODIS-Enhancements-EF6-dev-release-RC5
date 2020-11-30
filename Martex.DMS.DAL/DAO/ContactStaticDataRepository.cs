using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class ContactStaticDataRepository
    {

        /// <summary>
        /// Gets the method by ID.
        /// </summary>
        /// <param name="contactMethodID">The contact method ID.</param>
        /// <returns></returns>
        public ContactMethod GetMethodByID(int contactMethodID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var method = dbContext.ContactMethods.Where(x => x.ID == contactMethodID).FirstOrDefault();
                return method;
            }
        }

        /// <summary>
        /// Gets the name of the method by.
        /// </summary>
        /// <param name="contactMethodName">Name of the contact method.</param>
        /// <returns></returns>
        public ContactMethod GetMethodByName(string contactMethodName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var method = dbContext.ContactMethods.Where(x => x.Name == contactMethodName).FirstOrDefault();
                return method;
            }
        }

        /// <summary>
        /// Gets all contact methods.
        /// </summary>
        /// <returns></returns>
        public List<ContactMethod> GetAllContactMethods()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var methods = dbContext.ContactMethods.ToList<ContactMethod>();
                return methods;
            }
        }

        /// <summary>
        /// Gets the name of the type by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public ContactType GetTypeByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var type = dbContext.ContactTypes.Where(x => x.Name == name).FirstOrDefault();
                return type;
            }
        }

        /// <summary>
        /// Gets the contact reason.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <param name="categoryName">Name of the category.</param>
        /// <returns></returns>
        public ContactReason GetContactReason(string name, string categoryName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var reason = dbContext.ContactReasons.Where(x => x.Name == name && x.ContactCategory.Name == categoryName).FirstOrDefault();
                return reason;
            }
        }

        /// <summary>
        /// Gets the name of the contact category by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public ContactCategory GetContactCategoryByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var reason = dbContext.ContactCategories.Where(x => x.Name == name).FirstOrDefault();
                return reason;
            }
        }

        /// <summary>
        /// Gets the name of the contact source by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <param name="category">The category.</param>
        /// <returns></returns>
        public ContactSource GetContactSourceByName(string name, string category)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var source = dbContext.ContactSources.Where(x => x.Name == name && x.ContactCategory.Name == category).FirstOrDefault();
                return source;
            }
        }

        /// <summary>
        /// Gets the name of the contact action by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public ContactAction GetContactActionByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var source = dbContext.ContactActions .Where(x => x.Name == name).FirstOrDefault();
                return source;
            }
        }

        /// <summary>
        /// Gets the name of the contact action by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <param name="category">The category.</param>
        /// <returns></returns>
        public ContactAction GetContactActionByName(string name, string category)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var source = dbContext.ContactActions.Where(x => x.Name == name && x.ContactCategory.Name == category).FirstOrDefault();
                return source;
            }
        }

        
    }
}
