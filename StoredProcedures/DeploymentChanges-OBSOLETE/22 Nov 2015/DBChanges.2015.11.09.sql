--Billing Invoice 
               --BillingDefinitionInvoiceID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoice' AND name = 'IDX_BillingDefinitionInvoice')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_BillingDefinitionInvoice] ON [dbo].[BillingInvoice] 
                                (              
                                                [BillingDefinitionInvoiceID] ASC
                                )
                            END
                --BillingScheduleID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoice' AND name = 'IDX_BillingSchedule')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_BillingSchedule] ON [dbo].[BillingInvoice] 
                                (
                                                [BillingScheduleID] ASC
                                )
                            END
                --InvoiceStatusID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoice' AND name = 'IDX_BillingInvoiceStatus')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_BillingInvoiceStatus] ON [dbo].[BillingInvoice] 
                                (
                                                [InvoiceStatusID] ASC
                                )
                            END
                --ClientID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoice' AND name = 'IDX_Client')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_Client] ON [dbo].[BillingInvoice] 
                                (
                                                [ClientID] ASC
                                )
                            END
--Billing Schedule
                --ScheduleStatusID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingSchedule' AND name = 'IDX_ScheduleStatus')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_ScheduleStatus] ON [dbo].[BillingSchedule] 
                                (
                                                [ScheduleStatusID] ASC
                                )
                            END
--Product
                --ProductCategoryID
								IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'Product' AND name = 'IDX_ProductCategoryID')
								BEGIN
									CREATE NONCLUSTERED INDEX [IDX_ProductCategoryID] ON [dbo].[Product] 
									(
                                        [ProductCategoryID] ASC
									)
                                END
                --ProductTypeID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'Product' AND name = 'IDX_ProductTypeID')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_ProductTypeID] ON [dbo].[Product] 
                                (
                                                [ProductTypeID] ASC
                                )
                            END
--Billing Invoice Line
                --InvoiceLineStatusID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoiceLine' AND name = 'IDX_InvoiceLineStatusID')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_InvoiceLineStatusID] ON [dbo].[BillingInvoiceLine] 
                                (
                                                [InvoiceLineStatusID] ASC
                                )
                            END
                --ProductID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoiceLine' AND name = 'IDX_ProductID')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_ProductID] ON [dbo].[BillingInvoiceLine] 
                                (
                                                [ProductID] ASC
                                )
                            END
                --RateTypeID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoiceLine' AND name = 'IDX_RateTypeID')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_RateTypeID] ON [dbo].[BillingInvoiceLine] 
                                (
                                                [RateTypeID] ASC
                                )
                            END
                --BillingInvoiceID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoiceLine' AND name = 'IDX_BillingInvoice')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_BillingInvoice] ON [dbo].[BillingInvoiceLine] 
                                (
                                                [BillingInvoiceID] ASC
                                )
                            END
--Billing Invoice Detail
                --InvoiceDetailStatusID
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoiceDetail' AND name = 'IDX_InvoiceDetailStatusID')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_InvoiceDetailStatusID] ON [dbo].[BillingInvoiceDetail] 
                                (
                                                [InvoiceDetailStatusID] ASC
                                )
                            END
                --IsAdjusted
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoiceDetail' AND name = 'IDX_IsAdjusted')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_IsAdjusted] ON [dbo].[BillingInvoiceDetail] 
                                (
                                                [IsAdjusted] ASC
                                )
                            END
                --EventAmount
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoiceDetail' AND name = 'IDX_EventAmount')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_EventAmount] ON [dbo].[BillingInvoiceDetail] 
                                (
                                                [EventAmount] ASC
                                )
                            END
                --AdjustmentAmount
							IF NOT EXISTS(select * from sys.indexes where object_name(object_id) = 'BillingInvoiceDetail' AND name = 'IDX_AdjustmentAmount')
							BEGIN
                                CREATE NONCLUSTERED INDEX [IDX_AdjustmentAmount] ON [dbo].[BillingInvoiceDetail] 
                                (
                                                [AdjustmentAmount] ASC
                                )
                            END
