using System;
using ODISMember.Entities;
using ODISMember.Entities.Table;
using System.Collections.Generic;
using System.Linq;
namespace ODISMember.Data
{
	public class DBInitialize
	{
        DBRepository connection;
        public DBInitialize() {
            connection = new DBRepository();
        }
		public void CreateTables ()
		{
			connection.CreateTable<Member> ();
            connection.CreateTable<SettingsTable>();
            connection.CreateTable <LoggerTable>();
            connection.CreateTable<ApplicationSettingsTable>();
            connection.CreateTable<MemberAssociate>();
            connection.CreateTable<ODISMember.Entities.Table.Membership>();
            connection.CreateTable<MobileStaticDataVersion>();
            connection.CreateTable<Countries>();
            connection.CreateTable<VehicleChassis>();
            connection.CreateTable<VehicleColor>();
            connection.CreateTable<VehicleEngine>();
            connection.CreateTable<VehicleTransmission>();
            connection.CreateTable<MakeModel>();
            connection.CreateTable < Notification>();

            DeleteOldLogs();
        }
        public void DeleteOldLogs() {
            List<LoggerTable> loggerTableList = new List<LoggerTable>();
            loggerTableList = connection.GetAllRecords<LoggerTable>();
            if (loggerTableList.Count > 0)
            {
                loggerTableList = loggerTableList.Where(a => a.CreatedDate < DateTime.Now.AddDays(-10)).ToList();
                foreach (LoggerTable log in loggerTableList)
                {
                    connection.DeleteSpecificRecord(log);
                }
            }
        }
	}
}

