using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    public class ClientRepDetailsModel
    {
        public ClientRep ClientRep { get; set; }
        public List<Client> ClientsList { get; set; }
    }
}
