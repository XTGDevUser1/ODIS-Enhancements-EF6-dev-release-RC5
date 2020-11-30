using System;
using System.IO;
using Xamarin.Forms;
using ODISMember.Data;
using ODISMember.Droid;

[assembly: Dependency(typeof(SQLite_Android))]
namespace ODISMember.Droid
{
	public class SQLite_Android: ISQLite
	{
		#region ISQLite implementation

		public SQLite.Net.SQLiteConnection GetConnection ()
		{
			var fileName = "CastON.db3";
			var documentsPath = Environment.GetFolderPath (Environment.SpecialFolder.Personal);
			var path = Path.Combine (documentsPath, fileName);

			var platform = new SQLite.Net.Platform.XamarinAndroid.SQLitePlatformAndroid ();
			var connection = new SQLite.Net.SQLiteConnection (platform, path);

			var cmd = connection.CreateCommand ("PRAGMA journal_mode");
			string str = cmd.ExecuteScalar<string> ();

			if (!str.Equals ("wal", StringComparison.CurrentCultureIgnoreCase)) {
				var cmdJournalMode = connection.CreateCommand("PRAGMA journal_mode = WAL");
				string str3  = cmdJournalMode.ExecuteScalar<string> ();

			}
			return connection;
		}

		#endregion

		public SQLite_Android ()
		{
		}
	}
}

