using System;
using SQLite.Net;

namespace ODISMember.Data
{
	public interface ISQLite
	{
		SQLiteConnection GetConnection();
	}
}

