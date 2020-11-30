using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO.ListViewFilters;

namespace Martex.DMS.DAL.Entities
{
    public class FilterViewEntity
    {
        public string PageName
        {
            get
            {
                return this._PageName;
            }
        }

        public string LoggedInUser
        {
            get
            {
                return this._LoggedInUserID;
            }
        }

        public string EventHandlerCallBack
        {
            get
            {
                return this._EventHandlerCallBack;
            }
        }

        public string UniqueID
        {
            get
            {
                return this._UniqueID;
            }
        }
        public string SaveMethodName
        {
            get
            {
                return this._SaveMethodName;
            }
        }

        public string JSCollectDataHandler
        {
            get
            {
                return this._DataJSCallBackFuntionName;
            }
        }

       

        public List<ListViewFilter> Views
        {
            get
            {
                List<ListViewFilter> list = null;
                var repository = new ListViewFilterRepository();
                if (!string.IsNullOrEmpty(this.PageName) && !string.IsNullOrEmpty(this.LoggedInUser))
                {
                    list = repository.Get(Guid.Parse(this.LoggedInUser), this.PageName);
                }
                return list;
            }
        }

        public FilterViewEntity(string pageName, string loggedInUserID, string eventHandlerCallBackForApply, string uniqueID, string targetSaveMethodName,string eventHandlerToCollectData)
        {
            this._PageName = pageName;
            this._LoggedInUserID = loggedInUserID;
            this._EventHandlerCallBack = eventHandlerCallBackForApply;
            this._UniqueID = uniqueID;
            this._DataJSCallBackFuntionName = eventHandlerToCollectData;
            this._SaveMethodName = targetSaveMethodName;
        }

        private string _PageName { get; set; }
        private string _LoggedInUserID { get; set; }
        private string _EventHandlerCallBack { get; set; }
        private string _UniqueID { get; set; }
        private string _SaveMethodName { get; set; }
        private string _DataJSCallBackFuntionName { get; set; }

        public ListViewFilter NewRecord { get; set; }
    }
}
