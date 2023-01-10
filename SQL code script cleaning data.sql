-- CLEANING DATA from housing_data--

/* STANDARDIZING DATE FORMAT */

-- Adding new column--
ALTER TABLE housing_data 
ADD SaleDateConverted Date;

-- Inserting converted dates into column--
UPDATE housing_data
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%M %d,%Y');



/* POPULLATING PROPERY ADDRESS WHERE THERE ARE NONE */

-- Using Inner Join where ParcelID matches--

UPDATE housing_data AS a
JOIN housing_data AS b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.propertyaddress,b.propertyaddress)
WHERE a.PropertyAddress IS NULL;



/* BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (Street, City, State) */

-- Using SUBSTRING() & LOCATE()
-- Street --

ALTER TABLE housing_data
Add PropertySplitStreet varchar(255);
UPDATE housing_data
SET PropertySplitStreet = substring(Propertyaddress, 1, locate(',', PropertyAddress) - 1);

-- City --

ALTER TABLE housing_data
Add PropertySplitCity varchar(255);
UPDATE housing_data
SET PropertySplitCity = substring(propertyaddress, locate(',', PropertyAddress) + 1);

-- PropertyAddress contains no state--

-- Using SUBSTRING_INDEX() & LTRIM() for OwnerAddress
-- Street--
ALTER TABLE housing_data
ADD OwnerSplitStreet varchar(255);
UPDATE housing_data
SET OwnerSplitStreet = substring_index(owneraddress, ',', 1);

 -- City --
ALTER TABLE housing_data
ADD OwnerSplitCity varchar(255);
UPDATE housing_data
SET OwnerSplitCity = LTRIM(SUBSTRING_INDEX(substring_index(owneraddress, ',', 2), ',', -1));

 -- State --
ALTER TABLE housing_data
ADD OwnerSplitState varchar(255);
UPDATE housing_data
SET OwnerSplitState = LTRIM(substring_index(owneraddress, ',', -1));


/* CHANGING Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD */

UPDATE housing_data
SET SoldAsVacant = 
	CASE
		WHEN SoldAsVacant = 'Yes' THEN 'Y'
        WHEN SoldAsVacant = 'No' THEN 'N'
        Else SoldAsVacant
	END;
        
        
        
		/* REMOVE DUPLICATES */
-- Using ROW_NUMBER() to delete data --

DELETE FROM housing_data
WHERE UniqueID in (
	SELECT UniqueID
	FROM (
		SELECT UniqueID,
			ROW_NUMBER() OVER (
				PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
				ORDER BY UniqueID
				) AS row_num
		FROM housing_data
		) AS r
	WHERE row_num > 1
);



  /* DELETING UNUSED COLUMNS */

-- Dropping not needed columns --

ALTER TABLE housing_data
	DROP OwnerAddress,
    DROP TaxDistrict,
    DROP PropertyAddress,
    DROP SaleDate;



/* END */