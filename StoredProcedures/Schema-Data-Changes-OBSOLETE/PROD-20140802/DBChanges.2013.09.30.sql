ALTER TABLE ContactAction
ADD VendorServiceRatingAdjustment decimal(5,2) NULL

UPDATE ContactAction 
SET VendorServiceRatingAdjustment = 
CASE 
      WHEN Name = 'No answer'                   THEN -.5
      WHEN Name = 'No truck/driver available'   THEN -.5
      WHEN Name = 'Not in service area'         THEN -.25
      WHEN Name = 'Pricing issues'              THEN -.5
      WHEN Name = 'Accepted '                   THEN .25
      WHEN Name = 'Long ETA'                    THEN -.5
      WHEN Name = 'Refused Dispatch'            THEN -.5
      WHEN Name = 'Will Not Honor Rates'        THEN -1
      WHEN Name = 'Wait for ISP Callback'       THEN -.5
      ELSE NULL
      END
