-- CHANGE DATE FORMAT 
ALTER TABLE NashvilleHousingComp
ADD COLUMN sale_date_new DATE;

UPDATE NashvilleHousingComp
SET sale_date_new = substr(SaleDate, -4) || '-' || 
             CASE substr(SaleDate, 1, 3)
                 when 'Jan' then '01'
                 when 'Feb' then '02'
                 when 'Mar' then '03'
                 when 'Apr' then '04'
                 when 'May' then '05'
                 when 'Jun' then '06'
                 when 'Jul' then '07'
                 when 'Aug' then '08'
                 when 'Sep' then '09'
                 when 'Oct' then '10'
                 when 'Nov' then '11'
                 when 'Dec' then '12'
             END || '-' ||
             CASE when substr(SaleDate, -8, 1) = ' ' then '0' || substr(SaleDate, -7, 1)
                 else substr(SaleDate, -8, 2) 
             END;     

select SaleDate, sale_date_new
from NashvilleHousingComp;

------------------------------------------------------------------------------------------------------------------------------------------------------
-- POPULATE PROPERTY ADDRESS DATA
-- check if there are empty values
select *
from NashvilleHousingComp
where PropertyAddress = '';

-- replace empty values with null
update NashvilleHousingComp
set PropertyAddress = nullif(PropertyAddress, '');

-- check if nulls replaced empty values
select *
from NashvilleHousingComp
where PropertyAddress is null;

-- populate null values with the address from the same parcel id but different unique ids (should be 29)
-- because there are instances of parcel ids showing up twice so we want to copy 
-- that address into the same parcel id that doesn't have an address
-- this is like a self join 
UPDATE NashvilleHousingComp
   SET PropertyAddress = (select b.PropertyAddress
                           from NashvilleHousingComp b
                           where NashvilleHousingComp.ParcelID = b.ParcelID)
where EXISTS (select b.PropertyAddress
                           from NashvilleHousingComp b
                           where NashvilleHousingComp.ParcelID = b.ParcelID
                           and NashvilleHousingComp."unique_id " <> b."unique_id "
                           and NashvilleHousingComp.PropertyAddress is null);

------------------------------------------------------------------------------------------
--SEPERATE ADDRESS INTO ADDRESS, CITY, AND STATE
select *
from NashvilleHousingComp;

--substr(string, start, length of string)
-- at position 1 is the firt character of the string.
--instr searches for a substring in a string and returns an integer indicating the position
-- -1 to remove the comma

select
substr(PropertyAddress, 1, instr(PropertyAddress, ',') -1) as address,
substr(PropertyAddress, instr(PropertyAddress, ',') +1, length(PropertyAddress)) as city
FROM NashvilleHousingComp;

-- since above query works, add address and city columns:
ALTER TABLE NashvilleHousingComp
ADD COLUMN property_split_address Nvarchar(255);

UPDATE NashvilleHousingComp
SET property_split_address = substr(PropertyAddress, 1, instr(PropertyAddress, ',') -1);


ALTER TABLE NashvilleHousingComp
ADD COLUMN property_split_city Nvarchar(255);

UPDATE NashvilleHousingComp
SET property_split_city = substr(PropertyAddress, instr(PropertyAddress, ',') +1, length(PropertyAddress));

-- to get the state, lets use different method: parsename
select substr(OwnerAddress, -2, 2)
FROM NashvilleHousingComp;
-- this works so add state column:

ALTER TABLE NashvilleHousingComp
ADD COLUMN property_split_state Nvarchar(255);

UPDATE NashvilleHousingComp
SET property_split_state = substr(OwnerAddress, -2, 2);


------------------------------------------------------------------------------------------
-- change Y and N to Yes and No in 'sold as vacant' column

select distinct(SoldAsVacant), count(SoldAsVacant) 
from NashvilleHousingComp
group by SoldAsVacant;
-- there are 4 values: No, N, Yes, Y


select SoldAsVacant,
    case when SoldAsVacant = 'Y' THEN 'Yes'
        when SoldAsVacant = 'N' THEN 'No'
        else SoldAsVacant
        end
  from NashvilleHousingComp;
  
-- the above query works, so update table
update NashvilleHousingComp
set SoldAsVacant = 
    case when SoldAsVacant = 'Y' THEN 'Yes'
        when SoldAsVacant = 'N' THEN 'No'
        else SoldAsVacant
        end;
        
-- check: 
select distinct(SoldAsVacant), count(SoldAsVacant) 
from NashvilleHousingComp
group by SoldAsVacant;

------------------------------------------------------------------------------------------
-- remove duplicates 

-- partition it on values that should be unique: parcel id, property address, sale price, sale date, legal reference
-- create a cte (temp table) so that i can filter out row_num
with row_num_cte as (
select *,
    row_number() over (
    partition by ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
                    order by unique_id) row_num
  from NashvilleHousingComp
 -- order by ParcelID;
)

select *
  from row_num_cte
  where row_num > 1;
-- gives us 104 duplicate rows

-- delete:
delete from NashvilleHousingComp
where rowid not in (
    select min(rowid) from NashvilleHousingComp 
    group by ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
    );


------------------------------------------------------------------------------------------
-- remove unused columns: ownwer address and property address, tax district
ALTER TABLE NashvilleHousingComp
DROP COLUMN PropertyAddress;

ALTER TABLE NashvilleHousingComp
DROP COLUMN OwnerAddress;

ALTER TABLE NashvilleHousingComp
DROP COLUMN TaxDistrict;

ALTER TABLE NashvilleHousingComp
DROP COLUMN SaleDate;












