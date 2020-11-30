using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Collections;

namespace Martex.DMS.DAL.Common
{
    static class EntityRelationship
    {
        static Hashtable relatedEntityConfig = new Hashtable();
        static Hashtable entityMainAttribute = new Hashtable();
        static EntityRelationship()
        {
            relatedEntityConfig.Add("Tasks", "Project");
            entityMainAttribute.Add("Member", "FirstName");
        }

        /// <summary>
        /// Gets the related entity config.
        /// </summary>
        /// <value>
        /// The related entity config.
        /// </value>
        public static Hashtable RelatedEntityConfig
        {
            get { return relatedEntityConfig; }
        }

        /// <summary>
        /// Gets the entity main attribute.
        /// </summary>
        /// <value>
        /// The entity main attribute.
        /// </value>
        public static Hashtable EntityMainAttribute
        {
            get { return entityMainAttribute; }
        }
    }
}
