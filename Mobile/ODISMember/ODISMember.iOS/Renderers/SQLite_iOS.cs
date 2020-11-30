using System;
using System.IO;
using SQLite;
using ODISMember.iOS;
using Xamarin.Forms;
using ODISMember.Data;
using SQLite.Net.Interop;

[assembly: Dependency(typeof(SQLite_iOS))]

namespace ODISMember.iOS
{   
	public class SQLite_iOS: ISQLite
	{
		public SQLite_iOS ()
		{

		}

		#region ISQLite implementation

		public SQLite.Net.SQLiteConnection GetConnection ()
		{
			var fileName = "CastON.db3";
			var documentsPath = Environment.GetFolderPath (Environment.SpecialFolder.Personal);
			var libraryPath = Path.Combine (documentsPath, "..", "Library");
			var path = Path.Combine (libraryPath, fileName);

			var platform = new SQLite.Net.Platform.XamarinIOS.SQLitePlatformIOS ();
			var connection = new SQLite.Net.SQLiteConnection (platform, path);            
            var cmd = connection.CreateCommand("PRAGMA journal_mode");
            string str = cmd.ExecuteScalar<string>();

            if (!str.Equals("wal", StringComparison.CurrentCultureIgnoreCase))
            {
                var cmdJournalMode = connection.CreateCommand("PRAGMA journal_mode = WAL");
                string str3 = cmdJournalMode.ExecuteScalar<string>();
            }

            return connection;
		}

		#endregion
	}
}