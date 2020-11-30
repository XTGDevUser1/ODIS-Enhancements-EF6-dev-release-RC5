using Martex.DMS.DAL;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Linq.Expressions;
using System.Text;
using System.Threading.Tasks;

namespace ExportClaimDocuments
{
    class Program
    {
        static void Main(string[] args)
        {
            var listOfDocuments = new List<Document>();

            int fordClientID = 0;
            int.TryParse(ConfigurationManager.AppSettings["FordClientID"], out fordClientID);

            using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["ApplicationServices"].ConnectionString))
            {
                var query = "SELECT D.* FROM Claim C JOIN Program P ON C.ProgramID = P.ID JOIN Document D ON D.EntityID = (SELECT ID FROM Entity WHERE Name = 'Claim') AND D.RecordID = C.ID WHERE P.ClientID = " + fordClientID;
                var sqlCommand = new SqlCommand(query, connection);

                connection.Open();

                var reader = sqlCommand.ExecuteReader();
                while(reader.Read())
                {
                    try
                    {
                        var exportFileName = string.Format("{0}-{1}-{2}", reader["RecordID"], reader["ID"], reader["Name"]);
                        var fileContent = (byte[])reader["DocumentFile"];
                        var targetPath = Path.Combine(ConfigurationManager.AppSettings["TargetFolder"], exportFileName);

                        File.WriteAllBytes(targetPath, fileContent);
                        Console.WriteLine("Exported for Claim {0} to {1}", reader["RecordID"], targetPath);
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine("Error while exporting the document for Claim {0}", reader["RecordID"]);
                        Console.WriteLine("Error Detail : {0}", ex.ToString());
                    }
                }
            }

            Console.WriteLine("Done! Press any key to continue");
            Console.ReadKey();
            
        }
    }
}
