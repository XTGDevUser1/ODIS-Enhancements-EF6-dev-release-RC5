using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Martex.DMS.Models
{
    /// <summary>
    /// Generic IEquality Comparer
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public class GenericIEqualityComparer<T> : IEqualityComparer<T>
    {
        Func<T, T, bool> equalCheck;
        Func<T, int> getHashCode;

        /// <summary>
        /// Initializes a new instance of the <see cref="GenericIEqualityComparer{T}"/> class.
        /// </summary>
        /// <param name="equalCheck">The equal check.</param>
        /// <param name="getHashCode">The get hash code.</param>
        public GenericIEqualityComparer(Func<T, T, bool> equalCheck, Func<T, int> getHashCode)
        {
            this.equalCheck = equalCheck;
            this.getHashCode = getHashCode;
        }

        /// <summary>
        /// Determines whether the specified objects are equal.
        /// </summary>
        /// <param name="x">The first object of type <paramref name="T" /> to compare.</param>
        /// <param name="y">The second object of type <paramref name="T" /> to compare.</param>
        /// <returns>
        /// true if the specified objects are equal; otherwise, false.
        /// </returns>
        public bool Equals(T x, T y)
        {
            return this.equalCheck(x, y);
        }

        /// <summary>
        /// Returns a hash code for this instance.
        /// </summary>
        /// <param name="obj">The obj.</param>
        /// <returns>
        /// A hash code for this instance, suitable for use in hashing algorithms and data structures like a hash table. 
        /// </returns>
        public int GetHashCode(T obj)
        {
            return this.getHashCode(obj);
        }
    }
}