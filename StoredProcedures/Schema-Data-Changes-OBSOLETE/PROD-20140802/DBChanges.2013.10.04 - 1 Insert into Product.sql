if (select @@ServerName) in ('INFHYDCRM4D\SQLR2')
begin

begin tran
--  commit tran
--  rollback tran

	--------------------------------------------------------------------------------------------
	-- ProductCategory
	--------------------------------------------------------------------------------------------

	if (select count(*) from dbo.ProductCategory where Name = 'Billing') = 0
	begin

		insert into dbo.ProductCategory
		values
		('Billing',	-- Name
		 'Billing',
		 999,
		 1)

	end


	select *
	from	ProductCategory


	--------------------------------------------------------------------------------------------
	-- ProductType
	--------------------------------------------------------------------------------------------

	if (select count(*) from dbo.ProductType where Name = 'Billing') = 0
	begin
		insert into dbo.ProductType
		values
		('Billing',	-- Name
		 'Billing', -- Description
		 999,
		 1)
	end

	--------------------------------------------------------------------------------------------
	-- ProductSubType
	--------------------------------------------------------------------------------------------

	declare @ProductTypeID as int

	-- Billing
	if (select count(*) from dbo.ProductSubType where Name = 'Billing') = 0
	begin

		select @ProductTypeID = ID from dbo.ProductType where Name = 'Billing'

		insert into dbo.ProductSubType
		values
		(@ProductTypeID, -- ProductTypeID
		 'Billing',	-- Name
		 'Billing', -- Description
		 999,
		 1)
	end


	--------------------------------------------------------------------------------------------
	-- Product
	--------------------------------------------------------------------------------------------

	   	--declare @ProductTypeID as int
		--select @ProductTypeID = ID from dbo.ProductType where Name = 'Billing'


	declare @ProductSubTypeID as int,
			@ProductCategoryID as int

		select	@ProductSubTypeID = ID,
				@ProductTypeID = ProductTypeID
		from	dbo.ProductSubType
		where	Name = 'Billing'

		select	@ProductCategoryID = ID from dbo.ProductCategory where Name = 'Billing'


	-- Active Members
	if (select count(*) from dbo.Product where Name = 'Active Members') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Active Members',	-- Name
		 'Active Members', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'ACTIVE MBRS', -- AccountingSystemItemCode
		 '4000-310-01'-- GLCode
		 )
	end
	
	-- Active Members at Year End - Month
	if (select count(*) from dbo.Product where Name = 'Active Members at Year End - Month') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Active Members at Year End - Month',	-- Name
		 'Active Members at Year End - Month', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'ACTIVE MBRS-MO', -- AccountingSystemItemCode
		 '4000-310-01'-- GLCode
		 )
	end

	-- Active Members at Year End - Total
	if (select count(*) from dbo.Product where Name = 'Active Members at Year End - Total') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Active Members at Year End - Total',	-- Name
		 'Active Members at Year End - Total', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'ACTIVE MBRS-YR', -- AccountingSystemItemCode
		 '2521-000-00'-- GLCode
		 )
	end
	
	-- New Registrations
	if (select count(*) from dbo.Product where Name = 'New Registrations') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'New Registrations',	-- Name
		 'New Registrations', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'NEW REGS', -- AccountingSystemItemCode
		 '4000-310-02'-- GLCode
		 )
	end
	
	-- Administration Fee
	if (select count(*) from dbo.Product where Name = 'Administration Fee') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Administration Fee',	-- Name
		 'Administration Fee', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'ADMIN FEE', -- AccountingSystemItemCode
		 '4000-310-03'-- GLCode
		 )
	end
	
	-- Claims Processing Fee
	if (select count(*) from dbo.Product where Name = 'Claims Processing Fee') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Claims Processing Fee',	-- Name
		 'Claims Processing Fee', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'CLAIMS FEE', -- AccountingSystemItemCode
		 '4000-310-04'-- GLCode
		 )
	end

	-- Customer Assistance Calls
	if (select count(*) from dbo.Product where Name = 'Customer Assistance Calls') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Customer Assistance Calls',	-- Name
		 'Customer Assistance Calls', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'ASSIST CALL', -- AccountingSystemItemCode
		 '4000-310-05' -- GLCode
		 )
	end

	-- Dispatch Fee
	if (select count(*) from dbo.Product where Name = 'Dispatch Fee') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Dispatch Fee',	-- Name
		 'Dispatch Fee', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'DISPATCH FEE', -- AccountingSystemItemCode
		 '4000-310-06' -- GLCode
		 )
	end

	-- Information Calls
	if (select count(*) from dbo.Product where Name = 'Information Calls') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Information Calls',	-- Name
		 'Information Calls', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'INFO CALLS', -- AccountingSystemItemCode
		 '4000-310-07' -- GLCode
		 )
	end

	--Release Fee
	if (select count(*) from dbo.Product where Name = 'Release Fee') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Release Fee',	-- Name
		 'Release Fee', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'RELEASE FEE', -- AccountingSystemItemCode
		 '4000-310-08'-- GLCode
		 )
	end
	
	--Answered Calls
	if (select count(*) from dbo.Product where Name = 'Answered Calls') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Answered Calls',	-- Name
		 'Answered Calls', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'ANSWERED CALLS', -- AccountingSystemItemCode
		 '4000-310-09' -- GLCode
		 )
	end
	
	-- Call Transfers
	if (select count(*) from dbo.Product where Name = 'Call Transfers') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Call Transfers',	-- Name
		 'Call Transfers', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'CALL TRANSFERS', -- AccountingSystemItemCode
		 '4000-310-10' -- GLCode
		 )
	end

	-- Cash Dispatches
	if (select count(*) from dbo.Product where Name = 'Cash Dispatches') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Cash Dispatches',	-- Name
		 'Cash Dispatches', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'CASH DISPATCH', -- AccountingSystemItemCode
		 '4000-310-11' -- GLCode
		 )
	end

	-- Billable Purchase Orders
	if (select count(*) from dbo.Product where Name = 'Billable Purchase Orders') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Billable Purchase Orders',	-- Name
		 'Billable Purchase Orders', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'BILLABLE PO', -- AccountingSystemItemCode
		 '4300-310-00' -- GLCode
		 )
	end

	-- Internal Customer - Per Member Per Month
	if (select count(*) from dbo.Product where Name = 'Internal Customer - Per Member Per Month') = 0
	begin
		insert into dbo.Product
		(ProductCategoryID,
		 ProductTypeID,
		 ProductSubTypeID,
		 VehicleTypeID,
		 VehicleCategoryID,
		 Name,
		 [Description],
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsShowOnPO,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode)
		values
		(@ProductCategoryID,
		 @ProductTypeID,
		 @ProductSubTypeID,
		 null, -- VehicleTypeID
		 null, -- VehicleCategory
		 'Internal Customer - Per Member Per Month',	-- Name
		 'Internal Customer - Per Member Per Month', -- Description
		 999, -- Sequence
		 1, -- IsActive
		 getdate(), -- CreateDate
		 'BillingSetUp', -- CreatedBy
		 null, -- ModifiedDate
		 null, -- ModifiedBy
		 0,  -- IsShowOnPO
		 'INTERNAL-PMPM', -- AccountingSystemItemCode
		 '4004-000-99' -- GLCode
		 )
	end

	select * from dbo.Product


end


