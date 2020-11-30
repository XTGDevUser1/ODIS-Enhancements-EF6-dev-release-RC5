using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using System.IO;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;

namespace AuditParser
{
    class Program
    {
        static void Main(string[] args)
        {
            string csvPath = @"D:\Projects\MARTEX\DMS\Martex.DMS-MVC4-branch-PostGoLive\test.csv";
            
            DBAuditFacade dbFacade = new DBAuditFacade();
            List<DBAudit> dbAudites = dbFacade.GetDBAudit();
            using (StreamWriter writer = new StreamWriter(csvPath, false))
            {
                writer.Write("ID,Name,EntityName,OperationType,FieldName,OldValue,NewValue");
                writer.Write(writer.NewLine);
                foreach (DBAudit dba in dbAudites)
                {
                    AuditEntity changeSet = XMLSerializationHelper.XmlDeserialize(typeof(AuditEntity), dba.NewData) as AuditEntity;
                    writer.Write(changeSet.Id);
                    writer.Write(",");
                    writer.Write(changeSet.Name);
                    writer.Write(",");
                    writer.Write(changeSet.Type);
                    writer.Write(",");
                    writer.Write(changeSet.OperationType);
                    writer.Write(",");
                    if (changeSet.Changeset != null)
                    {
                        for (int i = 0; i < changeSet.Changeset.Length - 1; i++)
                        {
                            EntityProperty ep = changeSet.Changeset[i];

                            if (ep.OldValue != ep.NewValue)
                            {
                                writer.Write(ep.Name);
                                writer.Write(",");
                                writer.Write(ep.OldValue);
                                writer.Write(",");
                                writer.Write(ep.NewValue);
                                writer.Write(writer.NewLine);
                                if (i != changeSet.Changeset.Length - 2)
                                {
                                    writer.Write(",,,,");
                                }
                            }
                        }
                    }
                    else
                    {
                        writer.Write(",,");
                        writer.Write(writer.NewLine);
                    }
                }
                writer.Flush();
                writer.Close();
            }
        }
    }
}
