ALTER TABLE MemberProduct
ADD CreateDate	DATETIME NULl
GO
ALTER TABLE MemberProduct
ADD CreateBy	NVARCHAR(50) NULL
GO
ALTER TABLE MemberProduct
ADD ModifyDate	DATETIME NULl
GO
ALTER TABLE MemberProduct
ADD ModifyBy	NVARCHAR(50) NULL
GO


ALTER TABLE MemberProductProductCategory
ADD CreateDate	DATETIME NULl
GO
ALTER TABLE MemberProductProductCategory
ADD CreateBy	NVARCHAR(50) NULL
GO
ALTER TABLE MemberProductProductCategory
ADD ModifyDate	DATETIME NULl
GO
ALTER TABLE MemberProductProductCategory
ADD ModifyBy	NVARCHAR(50) NULL
GO


ALTER TABLE ProductProvider
ADD CreateDate	DATETIME NULl
GO
ALTER TABLE ProductProvider
ADD CreateBy	NVARCHAR(50) NULL
GO
ALTER TABLE ProductProvider
ADD ModifyDate	DATETIME NULl
GO
ALTER TABLE ProductProvider
ADD ModifyBy	NVARCHAR(50) NULL
GO
