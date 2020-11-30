--------------------------------------------------------------------------------------------
-- ProductRateType
--------------------------------------------------------------------------------------------

if (select @@ServerName) in ('INFHYDCRM4D\SQLR2')
begin

-- delete ProductRateType where sequence = 999

	declare	@ProductID as int,
			@RateTypeID as int

	-- Active Members : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Active Members'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Active Members at Year End - Month : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Active Members at Year End - Month'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Active Members at Year End - Total : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Active Members at Year End - Total'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end


	-- New Registrations : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'New Registrations'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Administration Fee : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Administration Fee'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Claims Processing Fee : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Claims Processing Fee'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Customer Assistance Calls : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Customer Assistance Calls'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Dispatch Fee : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Dispatch Fee'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Dispatch Fee : PercentageEach 
	select	@ProductID = ID from dbo.Product where Name = 'Dispatch Fee'
	select	@RateTypeID = ID from dbo.RateType where Name = 'PercentageEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Information Calls : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Information Calls'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Release Fee : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Release Fee'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Release Fee : PercentageEach 
	select	@ProductID = ID from dbo.Product where Name = 'Release Fee'
	select	@RateTypeID = ID from dbo.RateType where Name = 'PercentageEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Answered Calls : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Answered Calls'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end


	-- Call Transfers : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Call Transfers'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end


	-- Cash Dispatches : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Cash Dispatches'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

	-- Billable Purchase Orders : AmountEach
	select	@ProductID = ID from dbo.Product where Name = 'Billable Purchase Orders'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountPassThru'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end


	-- Internal Customer - Per Member Per Month : AmountEach 
	select	@ProductID = ID from dbo.Product where Name = 'Internal Customer - Per Member Per Month'
	select	@RateTypeID = ID from dbo.RateType where Name = 'AmountEach'

	if (select count(*) from ProductRateType where ProductID = @ProductID and RateTypeID = @RateTypeID) = 0
	begin

		insert into dbo.ProductRateType
		values
		(@ProductID,	-- ProductID
		 @RateTypeID, -- RateTypeID
		 999, -- Sequence
		 null, -- IsOptional
		 1 -- IsActive
		 )
	end

end

select * from dbo.ProductRateType



