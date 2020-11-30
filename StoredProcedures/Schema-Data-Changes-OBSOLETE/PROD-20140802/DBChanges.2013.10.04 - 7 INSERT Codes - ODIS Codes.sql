if (select @@ServerName) in ('INFHYDCRM4D\SQLR2')
begin


	begin tran
	-- commit tran
	-- rollback tran
	
	-- Entity
	---------------------------------------------
	declare @EntityName as nvarchar(50)

	select @EntityName = 'BillingInvoice'
	if (select isnull(count(*), 0) from Entity where Name = @EntityName) = 0
	begin
		insert into Entity (Name, IsAudited)
		values (@EntityName, 0)
	end

	select @EntityName = 'BillingPhoneSwitchCallDetail'
	if (select isnull(count(*), 0) from Entity where Name = @EntityName) = 0
	begin
		insert into Entity (Name, IsAudited)
		values (@EntityName, 0)
	end

	select @EntityName = 'BillingPhoneCallMetricsIncomingCalls'
	if (select isnull(count(*), 0) from Entity where Name = @EntityName) = 0
	begin
		insert into Entity (Name, IsAudited)
		values (@EntityName, 0)
	end

	select @EntityName = 'BillingProgram'
	if (select isnull(count(*), 0) from Entity where Name = @EntityName) = 0
	begin
		insert into Entity (Name, IsAudited)
		values (@EntityName, 0)
	end

	select @EntityName = 'MemberCounts'
	if (select isnull(count(*), 0) from Entity where Name = @EntityName) = 0
	begin
		insert into Entity (Name, IsAudited)
		values (@EntityName, 0)
	end


	select 'Entity',* from dbo.Entity


	-- Next Number
	---------------------------------------------
	declare @NextNumberName as nvarchar(50),
			@NextNumberValue as int
	
	
	select	@NextNumberName = 'InvoiceNumber',
			@NextNumberValue = 80000
			
	if (select isnull(count(*), 0) from NextNumber where Name = @NextNumberName) = 0
	begin
		insert into NextNumber (Name, Value)
		values (@NextNumberName, @NextNumberValue)
	end

	select 'NextNumber',* from dbo.NextNumber


	print 'Insert into Billing Code Tables Completed'

end
