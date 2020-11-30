using System;
using System.IO;
using SQLite;
using System.Collections.Generic;
using SQLite.Net;
using Xamarin.Forms;
using System.Linq;

namespace ODISMember.Data
{
    public class DBRepository
    {
        static object locker = new object(); // class level private field
        private static SQLiteConnection _connection = null;
        public DBRepository(SQLiteConnection connection = null) {
            if (connection == null)
            {
                _connection = DependencyService.Get<ISQLite>().GetConnection();
            }
            else {
                _connection = connection;
            }
        }

        public int CreateTable<T>()
        {
            try
            {

                int result = _connection.CreateTable<T>();

                return result;

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        public int GetTableInformation(string tableName)
        {
            lock (locker)
            {

                int result = _connection.GetTableInfo(tableName).Count();

                return result;
            }
        }
        public int InsertRecord(object obj)
        {
            lock (locker)
            {

                int result = _connection.Insert(obj);

                return result;
            }

        }
        public int InsertAllRecords<T>(List<T> listObj)
        {
            lock (locker)
            {

                int result = _connection.InsertAll(listObj);

                return result;
            }

        }
        public int DropTable<T>()
        {
            lock (locker)
            {
                int result = _connection.DropTable<T>();

                return result;
            }
        }
        public List<T> GetAllRecords<T>(string whereQuery = null, string customQuery = null) where T : class
        {
            lock (locker)
            {
                List<T> list = new List<T>();
                string sql = "SELECT * FROM " + typeof(T).Name;
                System.Diagnostics.Debug.WriteLine(sql);
                if (!string.IsNullOrEmpty(customQuery))
                {
                    sql = customQuery;
                }
                if (!string.IsNullOrEmpty(whereQuery))
                {
                    sql = sql + " " + whereQuery;
                }

                list = _connection.Query<T>(sql);

                return list;
            }
        }
        public T GetById<T>(int id) where T : class
        {
            lock (locker)
            {
                try
                {

                    var item = _connection.Get<T>(id);

                    return item;

                }
                catch (Exception ex)
                {
                    throw ex;
                }
            }
        }
        public int UpdateRecord(object obj)
        {
            lock (locker)
            {

                int result = _connection.Update(obj);

                return result;
            }

        }
        public int UpdateAllRecord<T>(List<T> listObj)
        {
            lock (locker)
            {

                int result = _connection.UpdateAll(listObj);

                return result;
            }
        }

        public int DeleteRecord<T>(int id) where T : class
        {
            lock (locker)
            {

                var item = _connection.Get<T>(id);
                int result = _connection.Delete(item);

                return result;
            }

        }
        public int DeleteSpecificRecord(object item)
        {
            lock (locker)
            {

                //var item = _connection.Get<T>(id);
                int result = _connection.Delete(item);

                return result;
            }

        }
        public int DeleteAllRecords<T>()
        {
            lock (locker)
            {

                int result = _connection.DeleteAll<T>();

                return result;
            }
        }
    }
}

