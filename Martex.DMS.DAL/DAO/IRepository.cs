using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// Repository Interface to Create Dao's for diffrent entities.
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public interface IRepository<T> where T : class
    {
        List<T> GetAll();
        int Add(T entity);
        void Update(T entity);
        void Delete<T1>(T1 id);
        T Get<T1>(T1 id); 
    }
}
