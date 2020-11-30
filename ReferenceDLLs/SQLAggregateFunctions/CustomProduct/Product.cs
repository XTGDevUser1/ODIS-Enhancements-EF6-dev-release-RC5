using System;
using System.Data;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;

[Serializable]
[SqlUserDefinedAggregate(
    Format.Native, //use clr serialization to serialize the intermediate result   
    IsInvariantToNulls = true, //optimizer property
    IsInvariantToDuplicates = false, //optimizer property
    IsInvariantToOrder = false) //optimizer property
    //MaxByteSize = 8000) //maximum size in bytes of persisted value
]
[StructLayout(LayoutKind.Sequential)]
public class Product //: IBinarySerialize
{
    /// <summary>
    /// The variable that holds the intermediate result of the concatenation
    /// </summary>
    private SqlDouble intermediateResult;

    /// <summary>
    /// Initialize the internal data structures
    /// </summary>
    public void Init()
    {
        //this.intermediateResult = 1;
    }

    /// <summary>
    /// Accumulate the next value, not if the value is null
    /// </summary>
    /// <param name="value"></param>
    public void Accumulate(SqlDecimal value)
    {
        if (value.IsNull)
        {
            //this.intermediateResult = 0;
            return;
        }
        if (this.intermediateResult.IsNull)
        {
            this.intermediateResult = Convert.ToDouble(value.Value);
        }
        else
        {
            this.intermediateResult *= Convert.ToDouble(value.Value);
        }
    }

    /// <summary>
    /// Merge the partially computed aggregate with this aggregate.
    /// </summary>
    /// <param name="other"></param>
    public void Merge(Product other)
    {
        this.intermediateResult *= other.intermediateResult;
    }

    /// <summary>
    /// Called at the end of aggregation, to return the results of the aggregation.
    /// </summary>
    /// <returns></returns>
    public SqlDecimal Terminate()
    {
        return this.intermediateResult.IsNull ? 0 : (new SqlDecimal(this.intermediateResult.Value));
    }

    //public void Read(BinaryReader r)
    //{
    //    decimal.TryParse(r.ReadString(), out intermediateResult);
    //}

    //public void Write(BinaryWriter w)
    //{
    //    w.Write(this.intermediateResult);
    //}
}