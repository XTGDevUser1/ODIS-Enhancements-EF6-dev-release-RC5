using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace VendorPortal.Models
{
    public class GenericIEqualityComparer<T> : IEqualityComparer<T>
    {
        Func<T, T, bool> equalCheck;
        Func<T, int> getHashCode;
        public GenericIEqualityComparer(Func<T, T, bool> equalCheck, Func<T, int> getHashCode)
        {
            this.equalCheck = equalCheck;
            this.getHashCode = getHashCode;
        }

        public bool Equals(T x, T y)
        {
            return this.equalCheck(x, y);
        }

        public int GetHashCode(T obj)
        {
            return this.getHashCode(obj);
        }
    }
}