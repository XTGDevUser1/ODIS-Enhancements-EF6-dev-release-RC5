--------------------------------------------------------------------------------------------
-- RateType
--------------------------------------------------------------------------------------------
if (select @@ServerName) in ('INFHYDCRM4D\SQLR2')
begin

begin tran
--  commit tran
--  rollback tran

	-- AmountEach
	if (select count(*) from dbo.RateType where Name = 'AmountEach') = 0
	begin
		insert into dbo.RateType
		values
		('AmountEach',	-- Name
		 'Billing Amount Each', -- Description
		 'Each', -- UnitOfMeasure
		 'Amount', -- UnitOfMeasureSource
		 999, -- Sequence
		 1 -- IsActive
		 )
	end

	-- PercentageEach
	if (select count(*) from dbo.RateType where Name = 'PercentageEach') = 0
	begin
		insert into dbo.RateType
		values
		('PercentageEach',	-- Name
		 'Billing Percentage Each', -- Description
		 'Each', -- UnitOfMeasure
		 'Percentage', -- UnitOfMeasureSource
		 999, -- Sequence
		 1 -- IsActive
		 )
	end

	-- AmountPassThru
	if (select count(*) from dbo.RateType where Name = 'AmountPassThru') = 0
	begin
		insert into dbo.RateType
		values
		('AmountPassThru',	-- Name
		 'Billing Amount PassThru', -- Description
		 'PassThru', -- UnitOfMeasure
		 null, -- UnitOfMeasureSource
		 999, -- Sequence
		 1 -- IsActive
		 )
	end


	-- AmountFixed
	if (select count(*) from dbo.RateType where Name = 'AmountFlat') = 0
	begin
		insert into dbo.RateType
		values
		('AmountFixed',	-- Name
		 'Billing Amount Fixed', -- Description
		 'Fixed', -- UnitOfMeasure
		 null, -- UnitOfMeasureSource
		 999, -- Sequence
		 1 -- IsActive
		 )
	end
	

	-- Manual
	if (select count(*) from dbo.RateType where Name = 'Manual') = 0
	begin
		insert into dbo.RateType
		values
		('Manual',	-- Name
		 'Billing Manual', -- Description
		 'Manual', -- UnitOfMeasure
		 null, -- UnitOfMeasureSource
		 999, -- Sequence
		 1 -- IsActive
		 )
	end

end


select *
from	RateType
where	Sequence = 999

