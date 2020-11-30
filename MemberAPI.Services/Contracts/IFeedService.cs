using MemberAPI.Services.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services
{
    public interface IFeedService
    {
        List<FeedResult> GetFeeds();
    }
}
