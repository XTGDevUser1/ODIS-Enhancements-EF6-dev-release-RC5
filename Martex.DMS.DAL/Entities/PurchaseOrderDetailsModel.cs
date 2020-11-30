using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL;
using System.ComponentModel.DataAnnotations;

namespace Martex.DMS.DAL.Entities
{
    [Serializable]
    public class PurchaseOrderDetailsModel
    {
        public PurchaseOrderDetailsModel(PODetailItemByPOId_Result poDetails, string mode = "Database")
        {
            this.ID = poDetails.ID;
            this.PurchaseOrderID = poDetails.PurchaseOrderID;
            this.Sequence = poDetails.Sequence;
            this.Product = new Product() { ID = poDetails.ProductID.GetValueOrDefault(), Name = poDetails.ProductName };
                //poDetails.Product ?? new Product();
            this.ProductID = poDetails.ProductID;
            this.ProductRateID = poDetails.ProductRateID;
            this.RateType = new RateType() { ID = poDetails.ProductRateID.GetValueOrDefault(), Description = poDetails.RateTypeDescription };
            this.Quantity = poDetails.Quantity;
            this.UnitOfMeasure = poDetails.UnitOfMeasure;
            this.Rate = poDetails.Rate;
            this.IsMemberPay = poDetails.IsMemberPay.HasValue ? poDetails.IsMemberPay.Value : false;
            this.ExtendedAmount = poDetails.ExtendedAmount;
            this.Mode = mode;
            
        }

        public PurchaseOrderDetailsModel()
        {
 
        }

        public PurchaseOrderDetail GetPurchaseOrderDetail()
        {
            PurchaseOrderDetail poitem = new PurchaseOrderDetail();
            poitem.ID = this.ID;
            poitem.Sequence = this.Sequence;
            poitem.PurchaseOrderID = this.PurchaseOrderID;
            poitem.ProductID = this.ProductID;
            poitem.ProductRateID = this.ProductRateID;
            poitem.Quantity = this.Quantity;
            poitem.UnitOfMeasure = this.UnitOfMeasure;
            poitem.Rate = this.Rate;
            poitem.IsMemberPay = this.IsMemberPay;
            poitem.CreateBy = this.UserName;
            poitem.CreateDate = DateTime.Now;
            poitem.ModifyBy = this.UserName;
            poitem.ModifyDate = DateTime.Now;
            //poitem.ExtendedAmount = this.ExtendedAmount;
            poitem.ExtendedAmount = (this.Quantity.GetValueOrDefault() * this.Rate.GetValueOrDefault());
            return poitem;
        }

        public int ID
        {
            get;
            set;
        }

        public int PurchaseOrderID
        {
            get;
            set;
        }

        public int? Sequence
        {
            get;
            set;
        }
        
        [Required(ErrorMessage="Required")]
        public Product Product
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Required")]
        public int? ProductID
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Required")]
        public int? ProductRateID
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Required")]
        public RateType RateType
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Required")]
        public decimal? Quantity
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Required")]
        public string UnitOfMeasure
        {
            get;
            set;
        }

        [Required(ErrorMessage = "Required")]
        public decimal? Rate
        {
            get;
            set;
        }

        public bool IsMemberPay
        {
            get;
            set;
        }

        public string Mode
        {
            get;
            set;
        }

        public decimal? ExtendedAmount
        {
            get;
            set;
        }

        public string UserName
        {
            get;
            set;
        }
    }
}