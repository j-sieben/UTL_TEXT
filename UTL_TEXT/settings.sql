-- Skript to adjust UTL_TEXT to your environment

-- Adjust this settings if you want another FLAG_TYPE

-- define FLAG_TYPE="char(1 byte)";
-- define C_TRUE="'Y'";
-- define C_FALSE="'N'";

define FLAG_TYPE="number(1, 0)";
define C_TRUE=1;
define C_FALSE=0;
   
-- Comment the following query out if you want to assign a specific tablespace for new users
col default_tablespace new_val DEFAULT_TABLESPACE format a128
select property_value default_tablespace
  from database_properties 
 where property_name = 'DEFAULT_PERMANENT_TABLESPACE';
 
-- If you don't want the default permanent tablespace to be the tablespace for new users,
-- provide a name for this parameter here:
-- define DEFAULT_TABLESPACE=#TABLESPACE#
