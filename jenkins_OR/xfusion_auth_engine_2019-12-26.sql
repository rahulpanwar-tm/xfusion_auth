--
-- Disable foreign keys
--
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;

--
-- Set default database
--
USE xfusion_development_auth_engine;

--
-- Drop procedure `xfusion_country_get`
--
DROP PROCEDURE xfusion_country_get;

DELIMITER $$

--
-- Create procedure `xfusion_country_get`
--
CREATE PROCEDURE xfusion_country_get()
  COMMENT 'Helps to get country list'
BEGIN
/*
----------------------------------------------------------------------------------------------------
Description:   Helps to get country list
----------------------------------------------------------------------------------------------------


*/
SELECT id,UCASE(name) As name,UCASE(alias) as alias,country_code from country ORDER BY alias ASC;
END
$$





--
-- Drop procedure `xfusion_utility_count_char`
--
DROP PROCEDURE xfusion_utility_count_char;
--
-- Create function `xfusion_utility_count_char`
--
CREATE FUNCTION xfusion_utility_count_char(`in_str` varchar(512), `in_char` varchar(20))
  RETURNS int(11)
BEGIN
	/*
    ----------------------------------------------------------------------------------------------------------------
	Description	:  Returns Count of Occurrence of Character in a String 
	Created On	:  26 Dec 2019	
	Created By	:  Sarang Sapre
	----------------------------------------------------------------------------------------------------------------
	Inputs		:  in_str 	: string
                   in_char  : character to count
    Output		:
    -----------------------------------------------------------------------------------------------------------------
	*/
	
RETURN LENGTH(in_str) - LENGTH(REPLACE(in_str, in_char, ''));
END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_utility_check`
--
DROP PROCEDURE xfusion_utility_check;

DELIMITER $$

--
-- Create procedure `xfusion_utility_check`
--
CREATE PROCEDURE xfusion_utility_check(
	IN `in_user_key` VARCHAR(255),
	IN `in_user_id` VARCHAR(255),
	IN `in_application_id` INT,
	IN `in_role_id` INT







)
  COMMENT 'This utility is to check wheather the application is have some role and users.'
BEGIN
/*
   -----------------------------------------------------------------------------------------------------------------------------------
   Description :  This utility is to check wheather the application is have some role and users.
   Created On  :  Dec 11,2019
   Created By  :  Sarang Sapre
   -----------------------------------------------------------------------------------------------------------------------------------
   Inputs   :   in_user_key         ------------   (User's Key)                        ------------------------ VARCHAR (255),
                in_user_id           ------------   (User's ID)                         ------------------------ VARCHAR (255),
                in_application_id    ------------   (ID of Application )                ------------------------ INT
   Output   :  Returns a Code which tells the status of application Or Role.
   ------------------------------------------------------------------------------------------------------------------------------------
*/
DECLARE temp_role_level INT;
DECLARE temp_user_count INT;

-- condition checking
IF(in_role_id IS NULL)THEN

SET temp_role_level = (SELECT xfusion_utility_count_char(path,'/') from roles WHERE application_id = (in_application_id) AND (`name`!='TTPL_ADMIN' OR `name`!='superadmin') limit 1);

SET @temp_check = (SELECT IF(temp_role_level>=1,1,0));

ELSE

SET temp_user_count = (SELECT COUNT(*) FROM user_roles WHERE role_id IN (SELECT id FROM roles WHERE id = in_role_id AND `name`!='TTPL_ADMIN' ));

SET @temp_check = (SELECT IF(temp_user_count!=0,1,0));

END IF;

-- output
 drop temporary table if exists temp_checks;
 create temporary table temp_checks 
 SELECT @temp_check As is_check;

END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_role_delete`
--
DROP PROCEDURE xfusion_role_delete;

DELIMITER $$

--
-- Create procedure `xfusion_role_delete`
--
CREATE PROCEDURE xfusion_role_delete(
	IN `in_user_key` VARCHAR(255),
	IN `in_user_id` VARCHAR(255),
	IN `in_application_id` INT,
	IN `in_role_id` INT




)
  COMMENT 'This procedure is for deleting a role.'
BEGIN
/*
   ----------------------------------------------------------------------------------------------------------------
   Description :  This procedure is for deleting a role
   Created On  :  July 20,2016
   Created By  :  Shantanu Bansal
   ----------------------------------------------------------------------------------------------------------------
   Inputs   :   in_user_key              ----------------------- User's Key
                in_user_id               ----------------------- User's ID
                in_application_id        ----------------------- Application's ID
                in_role_id               ----------------------- Role Id (to be deleted)
   Output   :  Message and Code
   -----------------------------------------------------------------------------------------------------------------
*/


  DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
  DECLARE catchArbitrary BOOLEAN;


  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
-- Check user exists in given application or not

  -- calling utility to check users and roles on the application
  CALL `xfusion_utility_check`(in_user_key, in_user_id, in_application_id,in_role_id);
  
 IF ((SELECT is_check FROM temp_checks)=0)THEN
  
    IF(SELECT COUNT(*) FROM roles WHERE id=in_role_id and application_id=in_application_id) THEN
      
        -- Delete Everything of role
      DELETE FROM user_roles
         Where role_id =in_role_id;
        DELETE FROM roles
         Where id =in_role_id;
      
            SET catchArbitrary=(SELECT xfusion_message_getsingle("isRoleDeleted",TRUE,temp_lang_code));        -- Get Message From messages table
            SELECT @code as code,@msg as msg;
ELSE

            SET catchArbitrary=(SELECT xfusion_message_getsingle("isRoleExists",FALSE,temp_lang_code));        -- Get Message From messages table
            SELECT @code as code,@msg as msg;


END IF;

ELSE

            SET catchArbitrary=(SELECT xfusion_message_getsingle("isRoleCheck",TRUE,temp_lang_code));        -- Get Message From messages table
            SELECT @code as code,@msg as msg;

  END IF;




END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_role_inherit_permissions`
--
DROP PROCEDURE xfusion_role_inherit_permissions;

DELIMITER $$

--
-- Create procedure `xfusion_role_inherit_permissions`
--
CREATE PROCEDURE xfusion_role_inherit_permissions(
	IN `in_user_key` varchar(56),
	IN `in_userid` varchar(56),
	IN `in_role` varchar(56),
	IN `in_assign_to_role` varchar(56)


)
BEGIN
	DECLARE catchAribitrary BOOLEAN; 
  DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
  DECLARE temp_from_role_id int;
	DECLARE temp_to_role_id int;

	SET in_lang_code=null;
   SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
   SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
	set temp_from_role_id=(select id from roles where access_key=in_role);
	set temp_to_role_id=(select id from roles where access_key=in_assign_to_role);
	
	insert into role_api_access(role_id,api_id)
	select temp_to_role_id,api_id from role_api_access
	where role_id=temp_from_role_id;


	insert into role_view_access(role_id,view_id)
	select temp_to_role_id,view_id from role_view_access
	where role_id=temp_from_role_id;
	
	SET @catchArbitrary=(SELECT xfusion_message_getsingle("PermissionsInheritedSuccessfully",TRUE,temp_lang_code));			-- Get Message From messages table
	SELECT  @msg AS message , @code AS code;
END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_application_create`
--
DROP PROCEDURE xfusion_application_create;

DELIMITER $$

--
-- Create procedure `xfusion_application_create`
--
CREATE PROCEDURE xfusion_application_create(
	IN `in_user_key` VARCHAR(255),
	IN `in_user_id` VARCHAR(255),
	IN `in_applications_name` VARCHAR(64),
	IN `in_alias` VARCHAR(255),
	IN `in_url` VARCHAR(255),
	IN `in_description` VARCHAR(2056),
	IN `in_view_url` varchar(2056),
	IN `in_api_url` varchar(2056),
	IN `in_service_url` varchar(2056),
	IN `in_file_path` VARCHAR(2056),
	IN `in_logo_file_path` VARCHAR(2056),
	IN `in_admin_app` TINYINT





)
  COMMENT 'This Procedure helps to create a new application.'
BEGIN
/*
   -----------------------------------------------------------------------------------------------------------------------------------
   Description :  This Procedure helps to create a new application.
   Created On  :  July 20,2016
   Created By  :  Shantanu Bansal
   -----------------------------------------------------------------------------------------------------------------------------------
   Inputs   :   
                in_user_key          ---------------  (User's Key)                             --------------------------- VARCHAR (255),
                in_user_id           ---------------  (User's ID)                              --------------------------- VARCHAR (255),
                in_applications_name ---------------  (Name of New Application )               --------------------------- VARCHAR (255),
                in_alias             ---------------  (Alias of Application Name)              --------------------------- VARCHAR (255),
                  in_url               ---------------   (URL of Application)                     --------------------------- VARCHAR (255),
                in_description       ---------------  (Decription about Application)           --------------------------- VARCHAR (255),
                in_view_url          ---------------  (URL of Application)                     --------------------------- VARCHAR (255),
                in_api_url           ---------------  (URL of Application)                     --------------------------- VARCHAR (255),
                  in_service_url       ---------------   (URL of Application)                     --------------------------- VARCHAR (255),
                in_logo_file_path    ---------------  (Application Icon)                       --------------------------- VARCHAR (2056)
                in_admin_app         ---------------- (Admin Application)                      --------------------------- TINYINT
   Output   :  Returns a Message and a Code which tells the status of application creation
   ------------------------------------------------------------------------------------------------------------------------------------
*/



   -- Variables
   DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
  
   -- VARCHAR Variables
   DECLARE temp_access_key VARCHAR(255);
   DECLARE temp_application_key VARCHAR(255);
   DECLARE temp_role_name VARCHAR(255);

   -- INT Variables
   DECLARE temp_application_id INT;
   DECLARE temp_role_id INT;
   DECLARE temp_user_id INT;
   DECLARE temp_user_role_id INT;
   
    -- Boolean Variables
   DECLARE catchArbitrary BOOLEAN;



   -- Set the values of different Variables
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
      SET temp_role_name ='superadmin'; -- (SELECT CONCAT(in_applications_name,"_admin"));
      SET temp_application_key = (SELECT uuid() );
      SET temp_access_key = (SELECT uuid() );
      SET temp_user_id = (SELECT id from users where user_key = in_user_key);
      
         -- Check application with same name should not be there 
         -- if its there then show the error
        IF (SELECT count(*) FROM applications WHERE name=in_applications_name OR view_url=in_view_url OR api_url = in_api_url) THEN
         SET catchArbitrary=(SELECT xfusion_message_getsingle("isApplicationCreated",FALSE,temp_lang_code));         -- Get Message From messages table
         SELECT @code as code,@msg as msg;
      ELSE
         -- id user exists
         IF(temp_user_id) THEN 
                     -- Insert into application table
                    INSERT INTO applications
                                    (name,alias,application_key,url,description,service_url,view_url,api_url,file_path,logo_file_path,is_admin_app) 
                              VALUES  
                                    (in_applications_name,in_alias,temp_application_key,in_url,in_description,in_service_url,in_view_url,in_api_url,in_file_path,in_logo_file_path,in_admin_app);
                            -- Getting Application ID of the newly created application
                     SET temp_application_id = (SELECT DISTINCT id from applications where application_key=temp_application_key);
                  -- create predefined roles
                     IF(select count(*) from roles where name=temp_role_name and application_id=temp_application_id) THEN 
                           SET catchArbitrary=(SELECT xfusion_message_getsingle("isRoleExists",TRUE,temp_lang_code));         -- Get Message From messages table
                           SELECT @code as code,@msg as msg;
                     ELSE
                             CALL xfusion_role_create_ttpl_admin(temp_application_id);
                           SET temp_user_role_id=(SELECT id FROM roles WHERE application_id=temp_application_id AND name='TTPL_ADMIN');
                           SET @path = (SELECT path FROM roles WHERE application_id=temp_application_id limit 1) ;      
                                    -- Creating new Admin Roles for the applications
                           INSERT INTO roles
                                       (name,alias,parent_role_id,application_id,access_key) 
                          VALUES
                           (
                            CONCAT(temp_role_name,'_TTPL_ADMIN'),
                            temp_role_name,temp_user_role_id,
                            temp_application_id,temp_access_key
                           );
                           
                           SET @role = (SELECT id FROM roles WHERE application_id=temp_application_id AND alias=temp_role_name);
                           
                           UPDATE roles
                           SET path = concat(@path,'/',@role)
                           WHERE id = @role;
                           -- Get the role Id for the newly created roles
                         --  SET temp_role_id = (SELECT DISTINCT id FROM roles WHERE access_key=temp_access_key);
                           
                           -- Mapping User with the New Role
                           --   INSERT INTO user_roles(user_id,role_id)
                             --    VALUES(temp_user_id,temp_role_id);
                           /* **************************************************************************************** */ 
                                    -- TTPL MAIN ADMIN ASSIGNED TO ROLE
                           /* **************************************************************************************** */ 
                              SET catchArbitrary=(SELECT xfusion_message_getsingle("isApplicationCreated",TRUE,temp_lang_code));          -- Get Message From messages table
                              SELECT @code as code,@msg as msg;
                     END IF;
         ELSE     
                  SET catchArbitrary=(SELECT xfusion_message_getsingle("isUserExist",FALSE,temp_lang_code));         -- Get Message From messages table
                  SELECT @code as code,@msg as msg;
         END IF;
      END IF;












END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_password_reset`
--
DROP PROCEDURE xfusion_password_reset;

DELIMITER $$

--
-- Create procedure `xfusion_password_reset`
--
CREATE PROCEDURE xfusion_password_reset(

IN in_reset_code VARCHAR(255),
IN in_new_password VARCHAR(255)

)
  COMMENT 'This Procedure helps to reset the password.'
BEGIN
/*
    ----------------------------------------------------------------------------------------------------------------
   Description :   This Procedure helps to reset the password.
   Created On  :  July 18,2016
   Created By  :  Shantanu Bansal
   ----------------------------------------------------------------------------------------------------------------
   Inputs      :   in_reset_code----------------------------- Reset Code of the User to Change the Password
               in_new_password--------------------------- New Password of the User
    Output     :  Returns a Msg and a Code
    -----------------------------------------------------------------------------------------------------------------
*/


   -- Variables
  DECLARE catchAribitrary BOOLEAN;
   DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;


   -- BOOLEAN Variables
   DECLARE isPasswordValid BOOLEAN;
    DECLARE isResetCodeValid BOOLEAN;
    DECLARE isPasswordUpdated BOOLEAN;
    DECLARE catchArbitrary BOOLEAN;
    
    -- DATETIME Variables
   DECLARE lastPasswordChangeDate datetime;
    DECLARE lastactivitydate datetime;
    DECLARE lastlogindate datetime;

   -- VARCHAR Variables
    DECLARE getPasswordKey VARCHAR(255);
    DECLARE PasswordKey VARCHAR(255);
    DECLARE getPassword VARCHAR(255);
    DECLARE encoded_password VARCHAR(255);
    DECLARE tmp_password VARCHAR(255);
    DECLARE in_user_id VARCHAR(255);
    DECLARE in_user_key varchar(255);
    DECLARE temp_password Varchar(256);
    DECLARE temp_pass_check_count int ;
    DECLARE temp_TTPL_role VARCHAR(255);
   

  SET temp_TTPL_role='TTPL_ADMIN';
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
  SET in_user_id=(SELECT user_id FROM password_reset where reset_key=in_reset_code and is_active=1);
  SET in_user_key=(SELECT user_key FROM users WHERE name=in_user_id);
  SET temp_password=(SELECT xfusion_password_encode(in_new_password,in_user_key));
  SET temp_pass_check_count=(SELECT password_check_count FROM membership WHERE email=in_user_id);
  SET in_reset_code = (SELECT SUBSTRING_INDEX(in_reset_code, ":",1));
  
        -- getting previous passwords
 DROP TEMPORARY TABLE IF EXISTS temp_users_password;
 CREATE TEMPORARY TABLE temp_users_password As 
 SELECT user_id,passwords 
 FROM user_passwords 
 WHERE user_id=in_user_id 
 ORDER BY id DESC 
 limit temp_pass_check_count;
        
   -- Check if Reset Code is active or not
   IF(SELECT COUNT(*) FROM password_reset where reset_key=in_reset_code and is_active=1) THEN 

         -- Verfying if Passowrd is in Correct format or Not
        SET isPasswordValid =(SELECT xfusion_password_verify(in_new_password));
     IF((SELECT COUNT(*) FROM temp_users_password WHERE passwords = temp_password)!=0)THEN
          SET catchAribitrary=(SELECT xfusion_message_getsingle('isPasswordUsed',False,temp_lang_code));
         SELECT @code as code,@msg as msg;
    ELSE
    
        IF(isPasswordValid=TRUE) THEN
            -- Setting the user activity time 
                SET lastPasswordChangeDate = UTC_TIMESTAMP();
                SET lastactivitydate = UTC_TIMESTAMP();
                SET lastlogindate = UTC_TIMESTAMP();
            -- Getting Password Key
            SET PasswordKey = (SELECT xfusion_password_getPasswordKey());
            -- Encoding The Password
                SET encoded_password = xfusion_password_encode(in_new_password,PasswordKey);
            -- Updating the fields and the password
                UPDATE membership 
               SET 
                  `password`=encoded_password,
                        password_key=PasswordKey,
                        last_password_changed_date = lastPasswordChangeDate,
                        last_activity_date = lastactivitydate,
                        last_login_date = lastlogindate
               WHERE email = in_user_id;
            SET catchArbitrary=(SELECT xfusion_message_getsingle('isPasswordUpdated',TRUE,temp_lang_code));          -- Get Message From messages table
            SELECT @code as code,@msg as msg;
                
  IF(SELECT COUNT(*) FROM vw_users_roles_applications WHERE users_user_key=in_user_key AND roles_name=temp_TTPL_role) THEN 
                UPDATE membership
                SET is_change_password_prompt_enable=1
                WHERE email = in_user_id ;
               
                END IF;
                
                UPDATE password_reset 
               SET is_active=0
                  WHERE reset_key=in_reset_code and is_active=1;
          
        INSERT INTO user_passwords(user_id, user_key, passwords)
       VALUES(in_user_id,in_user_key,temp_password);
        
        ELSE
        
            SET catchArbitrary=(SELECT xfusion_message_getsingle('isPasswordValid',FALSE,temp_lang_code));        -- Get Message From messages table
            SELECT @code as code,@msg as msg;
        
        
        END IF;
        END IF;
        
      
        
   ELSE
         SET catchArbitrary=(SELECT xfusion_message_getsingle('UserCodeMatch',FALSE,temp_lang_code));          -- Get Message From messages table
         SELECT @code as code,@msg as msg;
    END IF;



END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_users_get_by_application_key`
--
DROP PROCEDURE xfusion_users_get_by_application_key;

DELIMITER $$

--
-- Create procedure `xfusion_users_get_by_application_key`
--
CREATE PROCEDURE xfusion_users_get_by_application_key(
	IN `in_user_key` VARCHAR(255),
	IN `in_user_id` VARCHAR(255),
	IN `in_application_key` VARCHAR(255)

)
  COMMENT 'This procedure is for getting all the users from the application'
BEGIN
/*
	----------------------------------------------------------------------------------------------------------------
	Description	:  This procedure is for getting all the users from the application
	Created On	:	June 13,2016
	Created By	:	Shantanu Bansal
	----------------------------------------------------------------------------------------------------------------
	Inputs	:   	in_user_key                                  -------- User's Key
					in_user_id                                   -------- User's ID
					in_applicationid                             -------- Application Id
	Output	:		UserDetails From Specific Kind Of Application	
					membership.email, 
					membership.user_key,
					membership.is_approved,
					membership.last_activity_date,
					membership.last_login_date,
					membership.creation_date,
					membership.is_locked_out,
                    users.application_id,
                    applications.name,
                    user_roles.role_id,
                    roles.name
	-----------------------------------------------------------------------------------------------------------------
*/
	-- variables
    
	DECLARE catchArbitrary BOOLEAN;
	DECLARE temp_TTPL_role VARCHAR(255);
	DECLARE in_applicationid INT;
    DECLARE temp_user_role_name VARCHAR(255);
	DECLARE temp_user_role_id INT;
	DECLARE temp_user_id INT;
   DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
  
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
  
    SET in_applicationid=(SELECT id FROM applications WHERE application_key=in_application_key LIMIT 1);
    SET temp_TTPL_role='TTPL_ADMIN';
	-- SET temp_user_role_name=(SELECT name FROM roles WHERE application_id = in_applicationid LIMIT 1);
   	
    SET temp_user_id = (SELECT DISTINCT id FROM users where user_key=in_user_key);
    SET temp_user_role_id=(SELECT id FROM roles WHERE application_id=in_applicationid and id in(SELECT role_id FROM user_roles WHERE user_id=temp_user_id) LIMIT 1);
    SET temp_user_role_name=(SELECT name FROM roles WHERE id=temp_user_role_id);
   
    -- Prepared Concated User Addresses By Comma Seprated For Each Users.
    DROP TEMPORARY TABLE IF EXISTS temp_users_address;
    CREATE TEMPORARY TABLE temp_users_address
    AS
    SELECT user_id, GROUP_CONCAT(address) AS addresses,
           GROUP_CONCAT(is_permanent_address) AS is_permanent_address 
    FROM xfusion_development_auth_engine.users_address
    GROUP BY user_id;
    
    -- Prepared Concated User Contact Numbers By Comma Seprated For Each Users.
    DROP TEMPORARY TABLE IF EXISTS temp_users_contact_number;
    CREATE TEMPORARY TABLE temp_users_contact_number
    AS
    SELECT user_id, GROUP_CONCAT(contact_number) AS contact_numbers
    FROM xfusion_development_auth_engine.users_contact_number
    GROUP BY user_id;
    
    -- Prepared Concated User Attributes and Values By Comma Seprated For Each Users By Role Wise.
    DROP TEMPORARY TABLE IF EXISTS temp_users_role_attributes;
    CREATE TEMPORARY TABLE temp_users_role_attributes
    AS    
    SELECT user_id,user_key,
       GROUP_CONCAT(attribute_id) AS attribute_id,
       GROUP_CONCAT(attribute_alias) AS attribute_alias,
       GROUP_CONCAT(value) AS attribute_values
       FROM user_attribute WHERE attribute_id IN (
    SELECT attribute_id FROM role_attribute 
    WHERE role_id IN(SELECT id FROM roles 
    WHERE application_id=in_applicationid))
    GROUP BY user_id;
   
    IF(SELECT COUNT(*) FROM vw_users_roles_applications WHERE users_user_key=in_user_key AND roles_name=temp_TTPL_role) THEN 
			
			IF(SELECT COUNT(*) FROM vw_users_roles_applications WHERE users_user_key=in_user_key AND applications_id=in_applicationid) THEN

					SELECT users_id,users_name,users_is_deleted,users_last_activity_date,users_user_key,
							membership_email,membership_is_approved,membership_is_locked_out,membership_last_activity_date,
							membership_last_login_date,membership_last_password_changed_date,membership_creation_date,
							membership_last_locked_out_date,
							roles_id,roles_alias AS roles_name,applications_name,applications_alias,first_name,last_name,
              preferred_contact_number,country_id,country_name,country_alias,country_code,state_id,
              state_name,state_alias,city_id,city_name,city_alias,user_image_path,user_thumbail_image_path,
              addresses,is_permanent_address,contact_numbers,attribute_id,attribute_alias,attribute_values
					FROM vw_users_roles_applications 
          LEFT JOIN temp_users_address ON vw_users_roles_applications.users_id=temp_users_address.user_id
          LEFT JOIN temp_users_contact_number ON vw_users_roles_applications.users_id=temp_users_contact_number.user_id
          LEFT JOIN temp_users_role_attributes ON vw_users_roles_applications.users_id=temp_users_role_attributes.user_id
					WHERE applications_id=in_applicationid 
							AND users_user_key!=in_user_key  AND roles_name LIKE CONCAT('%',temp_user_role_name);
			ELSE
				SET catchArbitrary=(SELECT xfusion_message_getsingle("isUserApplicationValid",FALSE,temp_lang_code));			-- Get Message From messages table
				SELECT @code AS code, @msg AS msg;

			END IF;

	ELSE


			IF(SELECT COUNT(*) FROM vw_users_roles_applications WHERE users_user_key=in_user_key AND applications_id=in_applicationid) THEN

					SELECT users_id,users_name,users_is_deleted,users_last_activity_date,users_user_key,
							membership_email,membership_is_approved,membership_is_locked_out,membership_last_activity_date,
							membership_last_login_date,membership_last_password_changed_date,membership_creation_date,
							membership_last_locked_out_date,
							roles_id,roles_alias AS roles_name,applications_name,applications_alias ,first_name,last_name,
              preferred_contact_number,country_id,country_name,country_alias,country_code,state_id,
              state_name,state_alias,city_id,city_name,city_alias,user_image_path,user_thumbail_image_path,
              addresses,is_permanent_address,contact_numbers,attribute_id,attribute_alias,attribute_values
					FROM vw_users_roles_applications 
          LEFT JOIN temp_users_address ON vw_users_roles_applications.users_id=temp_users_address.user_id
          LEFT JOIN temp_users_contact_number ON vw_users_roles_applications.users_id=temp_users_contact_number.user_id
          LEFT JOIN temp_users_role_attributes ON vw_users_roles_applications.users_id=temp_users_role_attributes.user_id
					WHERE applications_id=in_applicationid 
							AND users_user_key!=in_user_key 
                             AND roles_name LIKE CONCAT('%',temp_user_role_name)
							AND applications_id!=1 
							AND users_id NOT in (SELECT users_id FROM vw_users_roles_applications WHERE roles_name=temp_TTPL_role);
			ELSE
				SET catchArbitrary=(SELECT xfusion_message_getsingle("isUserApplicationValid",FALSE,temp_lang_code));			-- Get Message From messages table
				SELECT @code AS code, @msg AS msg;
										
			END IF;
	END IF;
END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_user_update_by_user_id`
--
DROP PROCEDURE xfusion_user_update_by_user_id;

DELIMITER $$

--
-- Create procedure `xfusion_user_update_by_user_id`
--
CREATE PROCEDURE xfusion_user_update_by_user_id(
IN in_user_key VARCHAR(255),
IN in_user_id VARCHAR(255),
IN in_edit_user_id INT,
IN in_edit_user_key VARCHAR(255),
IN in_application_id VARCHAR(255),
IN in_edit_role_ids VARCHAR(255),
IN in_email VARCHAR(128),
IN in_first_name VARCHAR(255),
IN in_last_name VARCHAR(255),
IN in_country int(4),
IN in_state int(5),
IN in_city int(6),
IN in_preferred_number VARCHAR(12),
IN in_phone_numbers VARCHAR(500),
IN in_address TEXT,
IN in_is_anonymous tinyint(1),
IN in_is_deleted tinyint(1),
IN in_last_activity_date int(11),
IN in_is_permanent_address varchar(30),
IN in_image_path VARCHAR(2056),
IN in_thumbail_image_path VARCHAR(2056),
IN in_csv_attributes_id VARCHAR(2056),
IN in_csv_attributes_alias VARCHAR(2056),
IN in_csv_attributes_value VARCHAR(2056)

)
  COMMENT 'This procedure is for updating user''s details'
BEGIN


/*
	----------------------------------------------------------------------------------------------------------------
	Description	:  This procedure is for updating a user details.
	Created On	:	January 04,2017
	Created By	:	Amit Agarwal
	----------------------------------------------------------------------------------------------------------------
	Inputs	:   in_user_key------------------------------User's Key
			      	in_user_id-------------------------------User's ID
              in_edit_user_id--------------------------User's Id For Which Profile Will Be Update
			      	in_edit_user_key-------------------------User's Key For Which Profile Will Be Update
			        in_email---------------------------------User's Email
              in_first_name----------------------------User's First Name
              in_last_name-----------------------------User's Last Name
              in_country-------------------------------User's Country
              in_state---------------------------------User's State
              in_city----------------------------------User's City
              in_preferred_number----------------------User's Preferred Mobile Number
              in_phone_numbers-------------------------User's Phone Numbers (Comma Seprated)
              in_address-------------------------------User's Addresses (Comma Seprated)
              in_is_anonymous--------------------------Is Anonymous?
              in_is_deleted----------------------------User Is Deleted?
              in_last_activity_date--------------------Last Activity Date Of User.
              in_is_permanent_address------------------Provided Address Is Permanant Or Not
              in_image_path----------------------------User Image Path 
              in_thumbail_image_path-------------------Thumbail Image Path Of A User
              in_csv_attributes_id---------------------Attribute IDs
              in_csv_attributes_alias------------------Attribute Alias
              in_csv_attributes_value------------------Attribute Values
	Output	:	Returns a Message and a Code.
	-----------------------------------------------------------------------------------------------------------------
*/

-- Declared Variables 
  DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
  DECLARE var_user_id INT;
	DECLARE var_ttpl_admin_role INT;
	DECLARE var_ttpl_viewer_role INT;
	DECLARE isEmailVaild BOOLEAN;
	DECLARE catchArbitrary BOOLEAN;
	DECLARE isEmailTaken BOOLEAN;
	DECLARE temp_edit_user_key VARCHAR(255);
	SET var_ttpl_admin_role=1;
	SET	var_ttpl_viewer_role=1;
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
  -- Checking that provided email id is valid or not.
	SET isEmailVaild =(SELECT xfusion_username_verify(in_email));
  

-- optimising query
-- ------------------
SET in_application_id= (SELECT CONCAT('(',REPLACE(in_application_id,',','\'),(\''),')'));
-- --------------------
  -- Checking that user id exist or not.
	SET var_user_id = (SELECT id FROM users where user_key=in_user_key);

	
  -- Created temporary table for role and application details.
  DROP TABLE IF EXISTS temp_application_ids;
  CREATE TEMPORARY TABLE temp_application_ids (role_id INT,application_id INT);
  
  call xfusion_development_auth_engine.`xfusion_string_split`(in_edit_role_ids);
  -- Inserted splitted data into temporary table.
  INSERT INTO temp_application_ids(role_id) (SELECT split_data from temp_convert);
  
  -- Updating temporary table by role wise.
  UPDATE temp_application_ids
  LEFT JOIN roles ON roles.id=temp_application_ids.role_id
  SET temp_application_ids.application_id = roles.application_id
  WHERE roles.id=temp_application_ids.role_id;
  
  -- Checking that Email id is already taken by someone else or not.
  SET isEmailTaken = (SELECT IF((SELECT COUNT(*) FROM users where `name` = in_email AND id!= in_edit_user_id)!=0,TRUE,FALSE));
    

  IF(isEmailVaild) THEN
			
    IF(isEmailTaken) THEN
    -- Getting message from message table on type wise.
	  	SET catchArbitrary=(SELECT xfusion_message_getsingle("isEmailTaken",TRUE,temp_lang_code)); 			-- Get Message From messages table
			SELECT @code as code,@msg as msg;            
    ELSE
		IF(in_edit_user_id) THEN
      -- Deleting user roles on their user ud and role id wise.
				DELETE FROM user_roles 
        WHERE user_id=in_edit_user_id and role_id in 
         (SELECT id FROM roles 
                    WHERE application_id in 
                   (SELECT application_id FROM temp_application_ids));
       	 -- Updating User Profile In Users Table.
        UPDATE users
        SET name=in_email,
           -- is_anonymous=in_is_anonymous,   
          -- is_deleted=in_is_deleted,
            last_activity_date=from_unixtime(in_last_activity_date),
            first_name=in_first_name,
            last_name=in_last_name,
            country=in_country,
            state=in_state,
            city=in_city,
            preferred_contact_number=in_preferred_number,
            image_path=in_image_path,
            thumbail_image_path=in_thumbail_image_path
        WHERE id=in_edit_user_id;
			
  /* =========================================Insertion Of Phone Numbers Of A User Started====================================*/
  -- Splitting Comma Seprated Phone Numbers.
    call xfusion_development_auth_engine.`xfusion_string_split`(in_phone_numbers);
    
    -- Deleting all records from users_phone before updation of numbers.
    DELETE FROM users_contact_number WHERE user_id=in_edit_user_id;
    -- Inserting all the phone numbers of a user into users_phone table.
    INSERT INTO users_contact_number
    (user_id,contact_number,creation_time,last_modified_time)
    SELECT in_edit_user_id,TRIM(split_data),in_last_activity_date,in_last_activity_date FROM temp_convert;
   
  /* ================================================Insertion Of Phone Numbers Of A User Complete==================================*/
  
  /* ================================================Insertion Of Addresses Of A User Started========================================*/
  -- Splitting Comma Seprated Addresses.
  call xfusion_development_auth_engine.`xfusion_string_split`(in_address);  
  -- Deleting all records from users_phone before updation of numbers.
  DELETE FROM users_address WHERE user_id=in_edit_user_id; 
  -- Inserting all the addresses of a user into users_address table.
  INSERT INTO users_address
  (user_id,address,creation_time,last_modified_time,is_permanent_address)
  SELECT in_edit_user_id,TRIM(split_data),in_last_activity_date,in_last_activity_date,in_is_permanent_address FROM temp_convert;
  
  /* ================================================Insertion Of Addresses Of A User Complete=============================================*/
  
  -- Updating email id in membership table for a particular user.
  UPDATE membership SET `email`=in_email WHERE user_id=in_edit_user_id;
  -- Inserting user roles    
    call xfusion_development_auth_engine.`xfusion_string_split`(in_edit_role_ids);
	INSERT into user_roles(user_id,role_id) (SELECT in_edit_user_id,split_data FROM temp_convert);
	-- Getting User Key For which data is going to be update.		
  SET temp_edit_user_key=(SELECT in_edit_user_key);

    -- If Attributes parameters are blank then user attributes won't be insert or update.
      IF(in_csv_attributes_id is not null and in_csv_attributes_id!='' and in_csv_attributes_id!=' ')THEN
    		-- Droping existing temporary tables before creating these temporary tables.
			DROP TABLE IF EXISTS attributes_id;
    		DROP TABLE IF EXISTS attributes_alias;
    		DROP TABLE IF EXISTS attributes_values;
       
        -- Creating and inserting attributes ids in temporary table.
    		CALL xfusion_utility_string_split(in_csv_attributes_id);
    		CREATE TEMPORARY TABLE attributes_id(id INT NOT NULL AUTO_INCREMENT,name VARCHAR(255),PRIMARY KEY(id)  );
    		INSERT INTO attributes_id(name) (SELECT * from temp_convert);
    	
        -- Creating and inserting attributes alias in temporary table.
        CALL xfusion_utility_string_split(in_csv_attributes_alias);
    		CREATE TEMPORARY TABLE attributes_alias(id INT NOT NULL AUTO_INCREMENT,alias VARCHAR(255),PRIMARY KEY(id)  );
    		INSERT INTO attributes_alias(alias) (SELECT * from temp_convert);
    		
        -- Creating and inserting attributes values in temporary table.
        CALL xfusion_utility_string_split(in_csv_attributes_value);
    		CREATE TEMPORARY TABLE attributes_values(id INT NOT NULL AUTO_INCREMENT,_values VARCHAR(255),PRIMARY KEY(id)  );
    		INSERT INTO attributes_values(_values) (SELECT * from temp_convert);
       
        -- Deleting Existing attributes from table before insertion of attributes.
      	DELETE FROM user_attribute 
      				WHERE user_id=in_edit_user_id 
      					and attribute_id in 
      									(SELECT attribute_id 
      											FROM attributes WHERE role_id in
      													(SELECT id FROM roles WHERE application_id in (in_application_id)));
        
        -- Inserting attributes details into table.
        INSERT INTO user_attribute(in_edit_user_id,user_key,attribute_id,attribute_alias,value)
      		SELECT temp_user_id,temp_edit_user_key,name,alias,_values
      				FROM attributes_id 
      				INNER JOIN attributes_alias ON attributes_alias.id=attributes_id.id
      				INNER JOIN attributes_values ON attributes_values.id=attributes_alias.id;
      END IF;


    -- So that user can login in  assigning role in AUTH
    IF(SELECT COUNT(*) FROM roles WHERE id in (SELECT split_data FROM temp_convert) AND (id=var_ttpl_admin_role OR id=var_ttpl_viewer_role)) THEN
  	  -- USer is TTPL ADMIN
      SET catchArbitrary=(SELECT xfusion_message_getsingle("isUserUpdated",TRUE,temp_lang_code)); 			-- Get Message From messages table
  	  SELECT @code as code,@msg as msg;                                       
    ELSE
  		-- 	USER IS AUTH VIEWER
  		INSERT into user_roles(user_id,role_id) VALUES(in_edit_user_id,3);
  		SET catchArbitrary=(SELECT xfusion_message_getsingle("isUserUpdated",TRUE,temp_lang_code)); 			-- Get Message From messages table
  		SELECT @code as code,@msg as msg;
  	END IF;
  ELSE 
  	SET catchArbitrary=(SELECT xfusion_message_getsingle("isUserExist",FALSE,temp_lang_code)); 			-- Get Message From messages table
  	SELECT @code as code,@msg as msg;
  END IF;
END IF;
	  ELSE 
						SET catchArbitrary=(SELECT xfusion_message_getsingle("isEmailValid",FALSE,temp_lang_code)); 			-- Get Message From messages table
						SELECT @code as code,@msg as msg;

	  END IF;

END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_user_profile_update`
--
DROP PROCEDURE xfusion_user_profile_update;

DELIMITER $$

--
-- Create procedure `xfusion_user_profile_update`
--
CREATE PROCEDURE xfusion_user_profile_update(
	IN `in_user_key` VARCHAR(255),
	IN `in_user_id` VARCHAR(255),
	IN `in_email` VARCHAR(128),
	IN `in_first_name` VARCHAR(255),
	IN `in_last_name` VARCHAR(255),
	IN `in_country` int(4),
	IN `in_state` int(5),
	IN `in_city` int(6),
	IN `in_preferred_number` VARCHAR(12),
	IN `in_phone_numbers` VARCHAR(500),
	IN `in_address` TEXT,
	IN `in_is_anonymous` tinyint(1),
	IN `in_is_deleted` tinyint(1),
	IN `in_last_activity_date` int(11),
	IN `in_is_permanent_address` varchar(30),
	IN `in_image_path` VARCHAR(2056),
	IN `in_thumbail_image_path` VARCHAR(2056)




)
  COMMENT 'This procedure is for updating user''s profile details'
BEGIN


/*
	----------------------------------------------------------------------------------------------------------------
	Description	:  This procedure is for updating a user profile.
	Created On	:	September 30,2016
	Created By	:	Amit Agarwal
	----------------------------------------------------------------------------------------------------------------
	Inputs	:   in_user_key------------------------------User's Key
			      	in_user_id-------------------------------User's ID
			        in_email---------------------------------User's Email
              in_first_name----------------------------User's First Name
              in_last_name-----------------------------User's Last Name
              in_country-------------------------------User's Country
              in_state---------------------------------User's State
              in_city----------------------------------User's City
              in_preferred_number----------------------User's Preferred Mobile Number
              in_phone_numbers-------------------------User's Phone Numbers (Comma Seprated)
              in_address-------------------------------User's Addresses (Comma Seprated)
              in_is_anonymous--------------------------Is Anonymous?
              in_is_deleted----------------------------User Is Deleted?
              in_last_activity_date--------------------Last Activity Date Of User.
              in_is_permanent_address------------------Provided Address Is Permanant Or Not
              in_image_path----------------------------User Image Path 
              in_thumbail_image_path-------------------Thumbail Image Path Of A User
	Output	:	Returns a Message and a Code.
	-----------------------------------------------------------------------------------------------------------------
*/
	-- Variables
	DECLARE catchArbitrary BOOLEAN;
  DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
  	DECLARE var_user_id INT;
  	
  	
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));


  SET var_user_id=(SELECT id FROM users where user_key=in_user_key);
  
  -- Updating User Profile In Users Table.
  UPDATE users
  SET name=in_user_id,
     -- is_anonymous=in_is_anonymous,   
     -- is_deleted=in_is_deleted,
      last_activity_date=from_unixtime(in_last_activity_date),
      first_name=in_first_name,
      last_name=in_last_name,
      country=in_country,
      state=in_state,
      city=in_city,
      preferred_contact_number=in_preferred_number,
      image_path=in_image_path,
      thumbail_image_path=in_thumbail_image_path
  WHERE user_key=in_user_key;
  
    /* =========================================Insertion Of Phone Numbers Of A User Started====================================*/
  -- Splitting Comma Seprated Phone Numbers.
    call xfusion_development_auth_engine.`xfusion_string_split`(in_phone_numbers);
    
    -- Deleting all records from users_phone before updation of numbers.
    DELETE FROM users_contact_number WHERE user_id=var_user_id;
    -- Inserting all the phone numbers of a user into users_phone table.
    INSERT INTO users_contact_number
    (user_id,contact_number,creation_time,last_modified_time)
    SELECT var_user_id,TRIM(split_data),in_last_activity_date,in_last_activity_date FROM temp_convert;
   
  /* ================================================Insertion Of Phone Numbers Of A User Complete==================================*/
  
  /* ================================================Insertion Of Addresses Of A User Started========================================*/
  -- Splitting Comma Seprated Addresses.
  call xfusion_development_auth_engine.`xfusion_string_split`(in_address);  
  -- Deleting all records from users_phone before updation of numbers.
  DELETE FROM users_address WHERE user_id=var_user_id; 
  -- Inserting all the addresses of a user into users_address table.
  INSERT INTO users_address
  (user_id,address,creation_time,last_modified_time,is_permanent_address)
  SELECT var_user_id,TRIM(split_data),in_last_activity_date,in_last_activity_date,in_is_permanent_address FROM temp_convert;
  
  /* ================================================Insertion Of Addresses Of A User Complete=============================================*/

SET catchArbitrary=(SELECT xfusion_message_getsingle("isAccountSettingUpdatedSuccessfully",TRUE,temp_lang_code)); 			-- Get Message From messages table
							SELECT @code as code,@msg as msg;

END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_user_profile_create`
--
DROP PROCEDURE xfusion_user_profile_create;

DELIMITER $$

--
-- Create procedure `xfusion_user_profile_create`
--
CREATE PROCEDURE xfusion_user_profile_create(
												IN in_email varchar(255), 
                        IN in_password VARCHAR(56),
										 		IN in_passwordQuestion varchar(255), 
												IN in_passwordAnswer varchar(255),
												IN in_isApproved BOOLEAN ,
												IN in_applicationid VARCHAR(2056),
										 -- IN in_organisationid INT,
                        IN in_roleid VARCHAR(2056),
                     -- IN in_permissionid INT)
                        IN in_first_name VARCHAR(255),
                        IN in_last_name VARCHAR(255),
                        IN in_country int(4),
                        IN in_state int(5),
                        IN in_city int(6),
                        IN in_preferred_number VARCHAR(12),
                        IN in_phone_numbers VARCHAR(500),
                        IN in_address TEXT,
                        IN in_creation_date int(11),
                        IN in_is_permanent_address TINYINT(1),
                        IN in_image_path VARCHAR(2056),
                        IN in_thumbail_image_path VARCHAR(2056),
												IN in_csv_attributes_id VARCHAR(2056),
												IN in_csv_attributes_alias VARCHAR(2056),
												IN in_csv_attributes_value VARCHAR(2056)
                        )
  COMMENT 'This procedure is for creating a new user and assinging the user different roles in different applications. '
BEGIN
/*
	-------------------------------------------------------------------------------------------------------------------------
	Description	      :  This procedure is for creating a new user and assinging the user different roles in different applications. 
	Created On	      :	June 9,2016
  Created By	      :	Shantanu Bansal
  Modification Desc : Added some parameters to insert user details like - First Name,Last Name,
                      Phone Numbers,Country,State,City,Addresses etc.
  Last Modified On  : September 30,2016 
  Last Modified By  : Amit Agarwal
	-------------------------------------------------------------------------------------------------------------------------
	Inputs	:     in_email------------------------------------- Email Id of the new user
				        in_password---------------------------------- Password
                in_passwordQuestion-------------------------- Security Question
                in_passwordAnswer---------------------------- Answer
                in_isApproved-------------------------------- Approval Bit
                in_applicationid----------------------------- Comma Seperated Application Id
                in_roleid------------------------------------ Comma Seperated Role Id 
                in_first_name-------------------------------- First Name Of The User
                in_last_name--------------------------------- Last Name Of The User
                in_country----------------------------------- Country Of The User
                in_state------------------------------------- State Of The User
                in_city-------------------------------------- City Of The User
                in_preferred_number-------------------------- User's preferred Mobile Number
                in_phone_numbers----------------------------- Comma Seprated Phone Numbers
                in_address----------------------------------- Comma Seprated Addresses
                in_creation_date----------------------------- Record Creation Date Time
                in_is_permanent_address---------------------- Boolean Value For Identify that Address is permanant or not
                in_image_path-------------------------------- User Image Path
                in_thumbail_image_path----------------------- Thumbail Image Path Of A User
	Output	:	A meassage and a code
	--------------------------------------------------------------------------------------------------------------------------
*/
	
	/* Variables */
	-- Boolean Variables
   DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
	DECLARE isUserExist BOOLEAN; 
	DECLARE isUsernameValid BOOLEAN;
	DECLARE isPasswordValid BOOLEAN;
	DECLARE isEmailValid BOOLEAN;
	DECLARE isPasswordQuestionValid BOOLEAN;
	DECLARE isPasswordAnswerValid BOOLEAN;
    DECLARE isUserCreated BOOLEAN;
	DECLARE is_valid BOOLEAN; -- Made as It Can be used in future by chance to maintain uniformity
	DECLARE isAnonymous BOOLEAN;
	DECLARE isDeleted BOOLEAN;
    DECLARE catchAribitrary BOOLEAN;
	-- VarChar Variables
	DECLARE comments VARCHAR(255);
	DECLARE passwordKey VARCHAR(255);
	DECLARE passwordFormat VARCHAR(255);
	DECLARE userKey VARCHAR(255);
	DECLARE in_username VARCHAR(255);
    DECLARE encoded_password VARCHAR(255);
    DECLARE temp_TTPL_role VARCHAR(255);
	-- Date Variables
	DECLARE creationDate datetime;
	DECLARE lastActivityDate datetime;
	DECLARE lastloginDate datetime;
	DECLARE lastPasswordChangeDate datetime;
	DECLARE lastLockedOutDate datetime;
	DECLARE failedPasswordAttemptWindowStart datetime;
	DECLARE failedPasswordAnswerAttemptWindowStart datetime;
	-- Integer variables
	-- DECLARE getUserID INT;              // Removed Not Using as Multiple User ID
	DECLARE failedPasswordAttemptCount INT;
	DECLARE failedPasswordAnswerAttemptCount INT;
    DECLARE temp_TTPL_role_id INT;
    DECLARE temp_user_id INT;
    DECLARE var_user_id INT;
    
    
	-- DECLARE exit handler for sqlexception BEGIN ROLLBACK;END;
 
 
 -- for trasaction and roll back in case of failure
 SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
	SET autocommit = 0;
    START TRANSACTION;
   
   -- TTPL role 
	SET temp_TTPL_role='AUTH_VIEWER';
    SET temp_TTPL_role_id= (SELECT id FROM roles WHERE alias=temp_TTPL_role);
	
--   SET in_isApproved=(select IFNULL(in_isApproved,1));
    
    -- Set email as a user name
    SET in_username = in_email;
    -- Checking that username exist or not.
	IF (SELECT COUNT(*) FROM users where users.name =in_username)!=0 THEN 
		-- Set True in declared Variable.
    SET isUserExist = TRUE;
		SET catchAribitrary=(SELECT xfusion_message_getsingle("isUserExist",isUserExist,temp_lang_code)); 											-- Get Message From messages table
		-- Return code and message 
    SELECT @code as code,@msg as msg,isUserExist as isUserExist;
	ELSE 
    -- Get User valid or not.
		SET isUsernameValid = (SELECT xfusion_username_verify(in_username)); 						  -- Make Function
    -- Get Password Valid Or Not.
		SET isPasswordValid = (SELECT xfusion_password_verify(in_password)); 						  -- Make Function
	-- 	SET isEmailValid = (SELECT xfusion_email_validate(in_email));          						  -- As username is email only
		-- Set Email Is Valid by Value TRUE
    SET isEmailValid = TRUE;
    -- Get Password Question is valid or not
    SET isPasswordQuestionValid = (SELECT xfusion_passwordQuestion_verify(ifnull(in_passwordQuestion,'')));  -- Make Function
		-- Get Password Answer is valid or not
    SET isPasswordAnswerValid = (SELECT xfusion_passwordAnswer_verify(ifnull(in_passwordAnswer,'')));        -- Make Function
		SET isAnonymous = FALSE; 														    	 	  -- Default for new User
		SET isDeleted = FALSE; 																   		  -- Default for new User
		-- Checking that UserName,Password,Password Question And Answer was valid or not
		IF (isPasswordValid = TRUE AND isUsernameValid = TRUE AND isPasswordQuestionValid = TRUE AND isPasswordAnswerValid = TRUE) THEN
			-- Get Password Key
			SET passwordKey = (SELECT xfusion_password_getPasswordKey());                              -- Make Function
      -- Get User Key Of Newly Created User.
			SET userKey = (SELECT xfusion_user_getUserKey());                                          -- Make Function
      -- Get Encoded Password Of Newly Created User.
			SET encoded_password = (SELECT xfusion_password_encode(in_password,passwordKey));
            
            
			SET creationDate = (SELECT utc_timestamp());
			SET lastActivityDate = (SELECT utc_timestamp());
			SET lastloginDate = (SELECT utc_timestamp());
			SET lastPasswordChangeDate = (SELECT utc_timestamp());
			SET lastLockedOutDate = (SELECT utc_timestamp());
			SET failedPasswordAttemptWindowStart = (SELECT utc_timestamp());
			SET failedPasswordAnswerAttemptWindowStart = (SELECT utc_timestamp());
			
			SET failedPasswordAttemptCount = 0;														  -- Default Value													
			SET failedPasswordAnswerAttemptCount = 0;												  -- Default Value				
			
      -- Get Splitted value of application ids
      CALL xfusion_string_split(in_applicationid);
			
			-- Add Data to 'users' table
			INSERT INTO users(name,user_key,is_anonymous,is_deleted,last_activity_date,first_name,
      last_name,country,state,city,preferred_contact_number,
      image_path,thumbail_image_path) 
						(SELECT in_username,userKey,isAnonymous,isDeleted,lastActivityDate,in_first_name,in_last_name,in_country,
                        in_state,in_city,in_preferred_number,in_image_path,in_thumbail_image_path);
      

                        
                        
      -- Set user id of a particular user in declared variable
      SET var_user_id=(SELECT id FROM users where user_key=userKey);
      /* =========================================Insertion Of Phone Numbers Of A User Started====================================*/
  -- Splitting Comma Seprated Phone Numbers.
    call xfusion_development_auth_engine.`xfusion_string_split`(in_phone_numbers);
        
    -- Inserting all the phone numbers of a user into users_contact_number table.
    INSERT INTO users_contact_number
    (user_id,contact_number,creation_time,last_modified_time)
    SELECT var_user_id,TRIM(split_data),in_creation_date,in_creation_date FROM temp_convert;
   
  /* ================================================Insertion Of Phone Numbers Of A User Complete==================================*/
  
  /* ================================================Insertion Of Addresses Of A User Started========================================*/
  -- Splitting Comma Seprated Addresses.
  SET @temp_in_address=(SELECT IFNULL(in_address,''));
  call xfusion_development_auth_engine.`xfusion_string_split`(@temp_in_address);
  
  -- Inserting all the addresses of a user into users_address table.
  INSERT INTO users_address
  (user_id,address,creation_time,last_modified_time,is_permanent_address)
  SELECT var_user_id,TRIM(split_data),in_creation_date,in_creation_date,in_is_permanent_address FROM temp_convert;
  
  /* ================================================Insertion Of Addresses Of A User Complete=============================================*/

    
			
			-- Get UserID
			
            
	/*		SET getUserID = ( SELECT id 
									FROM users 
									WHERE 
											name = in_username); */			
			-- Add Data to 'user_organization' table
			
			/*INSERT INTO user_organization(user_id,organization)
			SELECT id,in_organisationid FROM users where name = in_username;
				*/	
		
			-- Add to 'membership' table
					
			INSERT INTO membership (
									user_id,email,`comment`,`password`,
									password_key,password_format,password_question,
									password_answer,is_approved,last_activity_date,
									last_login_date,last_password_changed_date,
									creation_date,last_locked_out_date,
									failed_password_attempt_count,failed_password_attempt_window_start,
									failed_password_answer_attempt_count,failed_password_answer_attempt_window_start,
									is_locked_out 
                                    )
			SELECT id,in_username," " as `comment`, encoded_password,passwordKey,0 as password_format,
				   in_passwordQuestion,in_passwordAnswer,in_isApproved,lastActivityDate,lastloginDate,
				   lastPasswordChangeDate,creationDate,lastLockedOutDate,failedPasswordAttemptCount,
				   failedPasswordAttemptWindowStart,failedPasswordAnswerAttemptCount,
                   failedPasswordAnswerAttemptWindowStart,0 as is_locked_out
			FROM users WHERE name = in_username;
                                      
			-- Break RoleIds
			CALL xfusion_string_split(in_roleid);
			
            set @usr_id=(select id from users where name=in_username);
            SET temp_user_id = (select id from users where name=in_username LIMIT 1);
			-- Add Data into user_roles        
			INSERT into user_roles(user_id,role_id)
			SELECT temp_user_id,split_data FROM temp_convert;
            
            -- ASSIGNING AUTH VIEWER ROLE
            INSERT into user_roles(user_id,role_id) VALUES(temp_user_id,temp_TTPL_role_id);
            -- Add attributes of the user
            
            
			IF(in_csv_attributes_id is not null and in_csv_attributes_id!='' and in_csv_attributes_id!=' ')THEN
			
      
										
							DROP TABLE IF EXISTS attributes_id;
							DROP TABLE IF EXISTS attributes_alias;
							DROP TABLE IF EXISTS attributes_values;


							CALL xfusion_string_split(in_csv_attributes_id);
							CREATE TEMPORARY TABLE attributes_id(id INT NOT NULL AUTO_INCREMENT,name VARCHAR(255),PRIMARY KEY(id)  );
							INSERT INTO attributes_id(name) (SELECT * from temp_convert);
							CALL xfusion_string_split(in_csv_attributes_alias);
							CREATE TEMPORARY TABLE attributes_alias(id INT NOT NULL AUTO_INCREMENT,alias VARCHAR(255),PRIMARY KEY(id)  );
							INSERT INTO attributes_alias(alias) (SELECT * from temp_convert);
							CALL xfusion_string_split(in_csv_attributes_value);
							CREATE TEMPORARY TABLE attributes_values(id INT NOT NULL AUTO_INCREMENT,_values VARCHAR(255),PRIMARY KEY(id)  );
							INSERT INTO attributes_values(_values) (SELECT * from temp_convert);



							INSERT INTO user_attribute(user_id,user_key,attribute_id,attribute_alias,value)
								SELECT temp_user_id,userKey,name,alias,_values
										FROM attributes_id 
										INNER JOIN attributes_alias ON attributes_alias.id=attributes_id.id
										INNER JOIN attributes_values ON attributes_values.id=attributes_alias.id;

	


			END IF;




			SET isUserCreated=TRUE;
			SET catchAribitrary=( SELECT xfusion_message_getsingle("isUserCreated",TRUE,temp_lang_code)); 							-- Get Message From messages table
			SELECT @code as code,@msg as msg,isUserCreated as isUserCreated,isPasswordValid as isPasswordValid,isUsernameValid as isUsernameValid,isEmailValid as isEmailValid,userKey,in_username as user_id;
		ELSE 
    -- Return Message if Username is not valid 
			IF (isUsernameValid = FALSE) THEN
				SET catchAribitrary=(SELECT xfusion_message_getsingle("isUsernameValid",FALSE,temp_lang_code)); 					-- Get Message From messages table
				SELECT @code as code,@msg as msg,isUsernameValid as isUsernameValid;
        
    -- Return Message if Password is not valid 
			ELSEIF (isPasswordValid = FALSE) THEN
				SET catchAribitrary=(SELECT xfusion_message_getsingle("isPasswordValid",FALSE,temp_lang_code));				    -- Get Message From messages table
				SELECT @code as code,@msg as msg,isPasswordValid as isPasswordValid;
        
    -- Return Message if Email is not valid 
			ELSEIF (isEmailValid = FALSE) THEN
				SET catchAribitrary=(SELECT xfusion_message_getsingle("isEmailValid",FALSE,temp_lang_code)); 					-- Get Message From messages table
				SELECT @code as code,@msg as msg,isEmailValid as isEmailValid;
        
    -- Return Message if Password Question is not valid 
			ELSEIF (isPasswordQuestionValid = FALSE) THEN
				SET catchAribitrary=(SELECT xfusion_message_getsingle("isPasswordQuestionValid",FALSE,temp_lang_code)); 			-- Get Message From messages table
				SELECT @code as code,@msg as msg,isPasswordQuestionValid as isPasswordQuestionValid;
        
    -- Return Message if Password Answer is not valid 
			ELSE 
				SET catchAribitrary=(SELECT xfusion_message_getsingle("isPasswordAnswerValid",FALSE,temp_lang_code)); 			-- Get Message From messages table
				SELECT @code as code,@msg as msg,isPasswordAnswerValid as isPasswordAnswerValid;
			END IF;
		END IF;
	END IF;
    COMMIT;
END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_user_create`
--
DROP PROCEDURE xfusion_user_create;

DELIMITER $$

--
-- Create procedure `xfusion_user_create`
--
CREATE PROCEDURE xfusion_user_create(
	IN `in_email` varchar(255),
	IN `in_username` VARCHAR(50),
	IN `in_password` VARCHAR(56),
	IN `in_passwordQuestion` varchar(255),
	IN `in_passwordAnswer` varchar(255),
	IN `in_isApproved` BOOLEAN,
	IN `in_applicationid` VARCHAR(2056),
	IN `in_roleid` VARCHAR(2056),
	IN `in_csv_attributes_id` VARCHAR(2056),
	IN `in_csv_attributes_alias` VARCHAR(2056),
	IN `in_csv_attributes_value` VARCHAR(2056),
	IN `in_password_check_count` INT

)
  COMMENT 'This procedure is for creating a new user and assinging the user different roles in different applications. '
BEGIN
/*
  -------------------------------------------------------------------------------------------------------------------------
  Description :  This procedure is for creating a new user and assinging the user different roles in different applications. 
  Created On  : June 9,2016
  Created By  : Shantanu Bansal
  -------------------------------------------------------------------------------------------------------------------------
  Inputs  :   in_email                     ------------------------------------- Email Id of the new user
              username                     ------------------------------------- user name 
        in_password                  ------------------------------------- Password
                in_passwordQuestion          ------------------------------------- Security Question
                in_passwordAnswer            ------------------------------------- Answer
                in_isApproved                ------------------------------------- Approval Bit
                in_applicationid             ------------------------------------- Comma Seperated Application Id
                in_roleid                    ------------------------------------- Comma Seperated Role Id 
  Output  : A meassage and a code
  --------------------------------------------------------------------------------------------------------------------------
*/
  
  /* Variables */
  -- Boolean Variables
  DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
  DECLARE isUserExist BOOLEAN; 
  DECLARE isUsernameValid BOOLEAN;
  DECLARE isPasswordValid BOOLEAN;
  DECLARE isEmailValid BOOLEAN;
  DECLARE isPasswordQuestionValid BOOLEAN;
  DECLARE isPasswordAnswerValid BOOLEAN;
    DECLARE isUserCreated BOOLEAN;
  DECLARE is_valid BOOLEAN; -- Made as It Can be used in future by chance to maintain uniformity
  DECLARE isAnonymous BOOLEAN;
  DECLARE isDeleted BOOLEAN;
    DECLARE catchAribitrary BOOLEAN;
  -- VarChar Variables
  DECLARE comments VARCHAR(255);
  DECLARE passwordKey VARCHAR(255);
  DECLARE passwordFormat VARCHAR(255);
  DECLARE userKey VARCHAR(255);
--  DECLARE in_username VARCHAR(255);
    DECLARE encoded_password VARCHAR(255);
    DECLARE temp_TTPL_role VARCHAR(255);
  -- Date Variables
  DECLARE creationDate datetime;
  DECLARE lastActivityDate datetime;
  DECLARE lastloginDate datetime;
  DECLARE lastPasswordChangeDate datetime;
  DECLARE lastLockedOutDate datetime;
  DECLARE failedPasswordAttemptWindowStart datetime;
  DECLARE failedPasswordAnswerAttemptWindowStart datetime;
  -- Integer variables
  -- DECLARE getUserID INT;              // Removed Not Using as Multiple User ID
  DECLARE failedPasswordAttemptCount INT;
  DECLARE failedPasswordAnswerAttemptCount INT;
    DECLARE temp_TTPL_role_id INT;
    DECLARE temp_user_id INT;
  DECLARE temp_auth_role_exists BOOLEAN;
  DECLARE temp_app_logo TEXT ;
  DECLARE temp_loading_icon TEXT ;
  DECLARE temp_theme_id int ;
  DECLARE temp_passwords varchar(255);
    
    
  -- DECLARE exit handler for sqlexception BEGIN ROLLBACK;END;
 
 -- for trasaction and roll back in case of failure
  -- SET autocommit = 0;
     -- START TRANSACTION;
   -- TTPL role 
  SET temp_TTPL_role='AUTH_VIEWER';
    SET temp_TTPL_role_id= (SELECT id FROM roles WHERE alias=temp_TTPL_role);
  
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
    
  IF (SELECT COUNT(*) FROM users where users.name =in_username)!=0 THEN 
    SET isUserExist = TRUE; 
    SET catchAribitrary=(SELECT xfusion_message_getsingle("isUserExist",isUserExist,temp_lang_code));                       -- Get Message From messages table
    SELECT @code as code,@msg as msg,isUserExist as isUserExist;
  ELSE                      -- As username is email only
     SET isEmailValid = TRUE;
     SET isPasswordValid = TRUE;
    SET isAnonymous = FALSE;                                      -- Default for new User
    SET isDeleted = FALSE;  
    SET isPasswordQuestionValid=TRUE;
    SET isPasswordAnswerValid = TRUE;
    SET isUsernameValid = TRUE;                                     -- Default for new User
    
    IF (isPasswordValid = TRUE AND isUsernameValid = TRUE AND isPasswordQuestionValid = TRUE AND isPasswordAnswerValid = TRUE) THEN
      
      SET passwordKey = (SELECT xfusion_password_getPasswordKey());                              -- Make Function
      SET userKey = (SELECT xfusion_user_getUserKey());                                          -- Make Function
      SET encoded_password = (SELECT xfusion_password_encode(in_password,passwordKey));
            
            
      SET creationDate = (SELECT utc_timestamp());
      SET lastActivityDate = (SELECT utc_timestamp());
      SET lastloginDate = (SELECT utc_timestamp());
      SET lastPasswordChangeDate = (SELECT utc_timestamp());
      SET lastLockedOutDate = (SELECT utc_timestamp());
      SET failedPasswordAttemptWindowStart = (SELECT utc_timestamp());
      SET failedPasswordAnswerAttemptWindowStart = (SELECT utc_timestamp());
      
      SET failedPasswordAttemptCount = 0;                             -- Default Value                          
      SET failedPasswordAnswerAttemptCount = 0;                         -- Default Value        
      
      SET temp_app_logo = (SELECT value FROM authorization_config WHERE parameter='DEFAULT_APP_LOGO'); -- default app_logo
      SET temp_loading_icon =(SELECT value FROM authorization_config WHERE parameter='DEFAULT_LOADING_ICON'); -- default loading_icon
      SET temp_theme_id =(SELECT id FROM themes WHERE is_default=1);-- default theme id
      
      SET temp_passwords = (SELECT xfusion_password_encode(in_password,userKey));
      
            CALL xfusion_string_split(in_applicationid);
      
      -- Add Data to 'users' table
      INSERT 
            INTO users(`name`,user_key,email_id,is_anonymous,is_deleted,last_activity_date,theme_id,app_logo,loading_icon) 
            (SELECT in_username,userKey,in_email,isAnonymous,isDeleted,lastActivityDate,temp_theme_id,temp_app_logo,temp_loading_icon);
      
      -- Get UserID
      
   
  /*    SET getUserID = ( SELECT id 
                  FROM users 
                  WHERE 
                      name = in_username); */
                    
                    
      
      -- Add Data to 'user_organization' table
      
      /*INSERT INTO user_organization(user_id,organization)
      SELECT id,in_organisationid FROM users where name = in_username;
        */    
    
      -- Add to 'membership' table
          
      INSERT INTO membership (
                  user_id,email,`comment`,`password`,
                  password_key,password_format,password_question,
                  password_answer,is_approved,last_activity_date,
                  last_login_date,last_password_changed_date,
                  creation_date,last_locked_out_date,
                  failed_password_attempt_count,failed_password_attempt_window_start,
                  failed_password_answer_attempt_count,failed_password_answer_attempt_window_start,
                  is_locked_out ,is_change_password_prompt_enable,password_check_count
                                    )
      SELECT id,in_username," " as `comment`, encoded_password,passwordKey,0 as password_format,
           in_passwordQuestion,in_passwordAnswer,in_isApproved,lastActivityDate,lastloginDate,
           lastPasswordChangeDate,creationDate,lastLockedOutDate,failedPasswordAttemptCount,
           failedPasswordAttemptWindowStart,failedPasswordAnswerAttemptCount,
                   failedPasswordAnswerAttemptWindowStart,0 as is_locked_out,1 as is_change_password_prompt_enable,in_password_check_count
      FROM users WHERE name = in_username;
      
      -- Add to 'user_Password' table
      INSERT INTO user_passwords(user_id, user_key, passwords)
      VALUES(in_username,userKey,temp_passwords);
                                      
      -- Break RoleIds
      CALL xfusion_string_split(in_roleid);
      
        set @usr_id=(select id from users where name=in_username);
        SET temp_user_id = (select id from users where name=in_username LIMIT 1);

      IF(SELECT COUNT(*) FROM temp_convert WHERE split_data=1 OR split_data=3)=0 THEN
      
        -- Add Data into user_roles        
        INSERT into user_roles(user_id,role_id)
        SELECT temp_user_id,split_data FROM temp_convert;
            
        -- ASSIGNING AUTH VIEWER ROLE
        INSERT into user_roles(user_id,role_id) VALUES(temp_user_id,temp_TTPL_role_id);
      ELSE

        -- Add Data into user_roles        
        INSERT into user_roles(user_id,role_id)
        SELECT temp_user_id,split_data FROM temp_convert;


      END IF;


-- Add attributes of the user
      IF(in_csv_attributes_id is not null and in_csv_attributes_id!='' and in_csv_attributes_id!=' ')THEN
      
                    
              DROP TABLE IF EXISTS attributes_id;
              DROP TABLE IF EXISTS attributes_alias;
              DROP TABLE IF EXISTS attributes_values;


              CALL xfusion_string_split(in_csv_attributes_id);
              CREATE TEMPORARY TABLE attributes_id(id INT NOT NULL AUTO_INCREMENT,name VARCHAR(255),PRIMARY KEY(id)  );
              INSERT INTO attributes_id(name) (SELECT * from temp_convert);
              CALL xfusion_string_split(in_csv_attributes_alias);
              CREATE TEMPORARY TABLE attributes_alias(id INT NOT NULL AUTO_INCREMENT,alias VARCHAR(255),PRIMARY KEY(id)  );
              INSERT INTO attributes_alias(alias) (SELECT * from temp_convert);
              CALL xfusion_string_split(in_csv_attributes_value);
              CREATE TEMPORARY TABLE attributes_values(id INT NOT NULL AUTO_INCREMENT,_values VARCHAR(255),PRIMARY KEY(id)  );
              INSERT INTO attributes_values(_values) (SELECT * from temp_convert);



              INSERT INTO user_attribute(user_id,user_key,attribute_id,attribute_alias,value)
                SELECT temp_user_id,userKey,name,alias,_values
                    FROM attributes_id 
                    INNER JOIN attributes_alias ON attributes_alias.id=attributes_id.id
                    INNER JOIN attributes_values ON attributes_values.id=attributes_alias.id;

  


      END IF;





      SET isUserCreated=TRUE;
      SET catchAribitrary=( SELECT xfusion_message_getsingle("isUserCreated",TRUE,temp_lang_code));               -- Get Message From messages table
      SELECT @code as code,@msg as msg,isUserCreated as isUserCreated,isPasswordValid as isPasswordValid,isUsernameValid as isUsernameValid,isEmailValid as isEmailValid,userKey,in_email as user_id;
    
  ELSE 
      IF (isUsernameValid = FALSE) THEN
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isUsernameValid",FALSE,temp_lang_code));           -- Get Message From messages table
        SELECT @code as code,@msg as msg,isUsernameValid as isUsernameValid;
      ELSEIF (isPasswordValid = FALSE) THEN
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isPasswordValid",FALSE,temp_lang_code));           -- Get Message From messages table
        SELECT @code as code,@msg as msg,isPasswordValid as isPasswordValid;
      ELSEIF (isEmailValid = FALSE) THEN
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isEmailValid",FALSE,temp_lang_code));          -- Get Message From messages table
        SELECT @code as code,@msg as msg,isEmailValid as isEmailValid;
      ELSEIF (isPasswordQuestionValid = FALSE) THEN
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isPasswordQuestionValid",FALSE,temp_lang_code));       -- Get Message From messages table
        SELECT @code as code,@msg as msg,isPasswordQuestionValid as isPasswordQuestionValid;
      ELSE 
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isPasswordAnswerValid",FALSE,temp_lang_code));       -- Get Message From messages table
        SELECT @code as code,@msg as msg,isPasswordAnswerValid as isPasswordAnswerValid;
      END IF;
    END IF;
  END IF;
 --   COMMIT;
END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_user_validate`
--
DROP PROCEDURE xfusion_user_validate;

DELIMITER $$

--
-- Create procedure `xfusion_user_validate`
--
CREATE PROCEDURE xfusion_user_validate(
  IN `in_user_id` varchar(56),
  IN `in_password` varchar(56),
  IN `in_application_key` varchar(56),
  IN `in_token_type` TINYINT
)
  COMMENT 'Verifies that the specified user name and password exist in the database '
BEGIN
  /*
      ----------------------------------------------------------------------------------------------------------------
      Description   :   Verifies that the specified user name and password exist in the database 
      Created On    :     2016-06-09
      Created By    :     Abhishek Ginani
      modified By   :     Sarang Sapre
      Modified On   :     16/05/2019
      ----------------------------------------------------------------------------------------------------------------
      Inputs        :       in_user_id- Name of the user to validate.
                          in_password- Password for the specified user.
                            in_token_type: 0 - for Web users
                                                1- for mobile users
                            in_application_key : Application ID
                                
      Output        :   Returns true if the specified username and password are valid; otherwise, false.
      -----------------------------------------------------------------------------------------------------------------
  */

             DECLARE in_lang_code INT ;
           DECLARE temp_default_lang_code INT;
          DECLARE temp_lang_code INT ;
           DECLARE is_valid BOOLEAN;
        DECLARE msg_parameter varchar(256);
        DECLARE parameter_value BOOLEAN;
        DECLARE temp_is_deleted BOOLEAN;
            DECLARE temp_user_key varchar(256);
        DECLARE temp_is_locked_out int;
        DECLARE temp_is_approved int;
        DECLARE temp_dbpassword varchar(256);
        DECLARE temp_password_key varchar(256);
        DECLARE temp_password_hash varchar(512);
        DECLARE temp_userid int;
        DECLARE temp_access_key varchar(64);
        DECLARE temp_last_activity_date DATETIME;
        DECLARE temp_password_change_date DATETIME;
        DECLARE temp_last_login_date DATETIME;
        DECLARE temp_application_id int;
        DECLARE temp_role_id INT;
          DECLARE temp_role_name VARCHAR(255);
          declare temp_user_name varchar(150);
          DECLARE temp_is_password_prompt_enable int(11);
          DECLARE temp_theme_id int(11);
          DECLARE temp_loading_icon TEXT;
          DECLARE temp_app_logo TEXT ;
          DECLARE temp_is_expired INT ; 
          DECLARE catchArbitrary BOOLEAN;
       --  DECLARE exit handler for sqlexception BEGIN ROLLBACK;END;
    
        
        -- SET autocommit=0;
        -- START TRANSACTION;
        
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
        

        SET temp_userid=(select id from users where name=in_user_id limit 1 );
        SET temp_is_expired = (select is_expired from membership where user_id = temp_userid limit 1);
        SET temp_is_password_prompt_enable=(SELECT is_change_password_prompt_enable FROM membership WHERE user_id=temp_userid);
        
   IF(temp_is_expired = 1)THEN

                 SET is_valid=FALSE;
                 SET catchArbitrary=(SELECT xfusion_message_getsingle("isExpired",FALSE,temp_lang_code));          -- Get Message From messages table
                 SELECT is_valid as status,@code as code,@msg as message,utc_timestamp() as `utc_time`,xfusion_config_getvalue('IsGrafanaEnabled') as IsGrafanaEnabled;  
  
   ELSE
        SELECT theme_id ,loading_icon ,app_logo
        INTO temp_theme_id,temp_loading_icon,temp_app_logo
        FROM users WHERE name=in_user_id limit 1;
        
        
        SET is_valid=FALSE;
        SELECT password, password_key, is_approved,is_locked_out,user_key,user_id,is_deleted,
          if(CONCAT(first_name,COALESCE(last_name,''))="",user_id,CONCAT(first_name,COALESCE(last_name,'')))
        INTO temp_dbpassword,
             temp_password_key,
             temp_is_approved,
             temp_is_locked_out,
             temp_user_key,
             temp_userid,
            temp_is_deleted,
            temp_user_name
        FROM vw_user_membership  WHERE vw_user_membership.user_id=temp_userid limit 1;
     
           
      SET temp_access_key=(select roles_access_key from vw_users_roles_applications where users_id=temp_userid and application_key=in_application_key limit 1);
        SET temp_application_id=(select id from applications where application_key=in_application_key limit 1);
        -- Case for validating application key     
        IF (select count(*) from vw_users_roles_applications where application_key=in_application_key and users_id=temp_userid)>0 THEN
      
            -- First check user exist in db. if count in "temp_user_info" table is 0 then set is_valid to false.
              IF temp_user_key is not null THEN
                
                -- Check user lock status
                IF temp_is_locked_out<1 THEN                
                    
                    -- Check user approval status
                    IF temp_is_deleted < 1 THEN
                                     
                        -- Get password hash
                        SET temp_password_hash=(select xfusion_password_encode(in_password,temp_password_key));
                        
                        -- Validate password   
                        IF(temp_password_hash!=temp_dbpassword) THEN
                            SET is_valid=FALSE;
                            SET msg_parameter='passwordNotMatched';
                            SET parameter_value=TRUE;
                            
                            -- Update password failure count
                            call xfusion_password_failure_update_count(temp_user_key);
                        ELSE
                            -- Case when password matched
                            SET is_valid=TRUE;
                            SET msg_parameter='passwordNotMatched';
                            SET parameter_value=FALSE;
                            
                           
                            
                            -- Update membership on successfull login
                            
                        
                            SELECT id,
                                  alias 
                            INTO temp_role_id,temp_role_name
                            FROM  roles WHERE access_key=temp_access_key;

                                
                            set @access_token:=NULL;
                            set @access_token=uuid();       
                                
                            -- Insert Token on successfull login
                            insert into auth_token
                            (
                            user_id,
                            application_id,
                            access_key,
                            token,
                            added_on,
                            is_mobile_token,
              token_binary_key
                            )
                            values(
                                temp_userid,temp_application_id,temp_access_key,@access_token,unix_timestamp(),
                                in_token_type,xfusion_utility_ordered_uuid(token)
                            );
                             
                        END IF;
                        
                    ELSE
                        SET is_valid=FALSE;
                        SET msg_parameter='isUserActive';
                        SET parameter_value=False;
                    END IF;
                    
                ELSE
                    
                    SET is_valid=FALSE;
                    SET msg_parameter='isUserLockedOut';
                    SET parameter_value=TRUE;
                    
                END IF;
            ELSE
                SET is_valid=FALSE;
                SET msg_parameter='isUserExist';
                SET parameter_value=False;
            END IF;
    ELSE
                SET is_valid=FALSE;
                SET msg_parameter='isValidApplication';
                SET parameter_value=False;
        END IF;
        -- Get message 
       SET @result= (select xfusion_message_getsingle(msg_parameter, parameter_value,temp_lang_code));
    --  COMMIT;  
    IF is_valid and temp_access_key is not null THEN
        select  temp_role_name as roles_name,temp_role_id as roles_id,is_valid as status,
                    @code as code,@msg as message, temp_user_key as user_key, 
                    temp_access_key as access_key,in_user_id as user_id ,
                    utc_timestamp() as `utc_time`,
                    @access_token as access_token,
                    in_token_type as token_type,
                    temp_user_name as user_name,
                    temp_is_password_prompt_enable as is_change_password_prompt_enable,
                     xfusion_config_getvalue('IsGrafanaEnabled') as IsGrafanaEnabled,
                temp_theme_id As auth_theme_id,
                temp_loading_icon As auth_loading_icon,
                temp_app_logo As auth_app_logo;
                
        -- select is_valid as status,@code as code,@msg as message, temp_user_key as user_key, temp_access_key as access_key,in_user_id as user_id ,utc_timestamp() as `utc_time`,temp_last_activity_date as last_activity_date,temp_password_change_date as last_password_change_date,temp_last_login_date as last_login_date;

    ELSE
        select is_valid as status,@code as code,@msg as message,utc_timestamp() as `utc_time`,xfusion_config_getvalue('IsGrafanaEnabled') as IsGrafanaEnabled;        
    END IF;

    END IF;
END
$$

DELIMITER ;


ALTER TABLE `users`
	ADD COLUMN `email_id` VARCHAR(256) NULL DEFAULT NULL AFTER `user_key`;



--
-- Drop view `vw_users_roles_applications`
--
DROP VIEW vw_users_roles_applications CASCADE;

--
-- Create view `vw_users_roles_applications`
--
CREATE
VIEW vw_users_roles_applications
AS
SELECT
  `users`.`id` AS `users_id`,
  `users`.`name` AS `users_name`,
  `users`.`email_id` AS `users_email`,
  `users`.`user_key` AS `users_user_key`,
  `users`.`is_deleted` AS `users_is_deleted`,
  `users`.`last_activity_date` AS `users_last_activity_date`,
  `users`.`first_name` AS `first_name`,
  `users`.`last_name` AS `last_name`,
  `users`.`preferred_contact_number` AS `preferred_contact_number`,
  `users`.`country` AS `country_id`,
  `country`.`name` AS `country_name`,
  `country`.`alias` AS `country_alias`,
  `country`.`country_code` AS `country_code`,
  `users`.`state` AS `state_id`,
  `state`.`name` AS `state_name`,
  `state`.`alias` AS `state_alias`,
  `users`.`city` AS `city_id`,
  `city`.`name` AS `city_name`,
  `city`.`alias` AS `city_alias`,
  `users`.`image_path` AS `user_image_path`,
  `users`.`thumbail_image_path` AS `user_thumbail_image_path`,
  `membership`.`email` AS `membership_email`,
  `membership`.`is_approved` AS `membership_is_approved`,
  `membership`.`is_locked_out` AS `membership_is_locked_out`,
  `membership`.`last_activity_date` AS `membership_last_activity_date`,
  `membership`.`last_login_date` AS `membership_last_login_date`,
  `membership`.`last_password_changed_date` AS `membership_last_password_changed_date`,
  `membership`.`creation_date` AS `membership_creation_date`,
  `membership`.`last_locked_out_date` AS `membership_last_locked_out_date`,
  `roles`.`id` AS `roles_id`,
  `roles`.`name` AS `roles_name`,
  `roles`.`access_key` AS `roles_access_key`,
  `roles`.`alias` AS `roles_alias`,
  `roles`.`parent_role_id` AS `roles_parent_role_id`,
  `applications`.`id` AS `applications_id`,
  `applications`.`name` AS `applications_name`,
  `applications`.`alias` AS `applications_alias`,
  `applications`.`application_key` AS `application_key`,
  `applications`.`url` AS `applications_url`,
  `applications`.`description` AS `applications_description`,
  `applications`.`service_url` AS `applications_service_url`,
  `applications`.`view_url` AS `applications_view_url`,
  `applications`.`api_url` AS `applications_api_url`,
  `applications`.`file_path` AS `applications_file_path`,
  `applications`.`logo_file_path` AS `applications_logo_file_path`,
  `applications`.`is_admin_app` AS `applications_is_admin_app`
FROM (((((((`users`
  LEFT JOIN `user_roles`
    ON ((`users`.`id` = `user_roles`.`user_id`)))
  LEFT JOIN `roles`
    ON ((`user_roles`.`role_id` = `roles`.`id`)))
  LEFT JOIN `applications`
    ON ((`roles`.`application_id` = `applications`.`id`)))
  LEFT JOIN `membership`
    ON ((`users`.`id` = `membership`.`user_id`)))
  LEFT JOIN `country`
    ON ((`users`.`country` = `country`.`id`)))
  LEFT JOIN `state`
    ON ((`users`.`state` = `state`.`id`)))
  LEFT JOIN `city`
    ON ((`users`.`city` = `city`.`id`)));



--
-- Drop procedure `xfusion_password_forgot_code`
--
DROP PROCEDURE xfusion_password_forgot_code;

DELIMITER $$

--
-- Create procedure `xfusion_password_forgot_code`
--
CREATE PROCEDURE xfusion_password_forgot_code(
	IN `in_user_id` VARCHAR(255)
,
	IN `in_username` VARCHAR(255)

)
  COMMENT 'This Procedure helps to send a reset code so to update a new password in next procedure .'
BEGIN

/*
  --------------------------------------------------------------------------------------------------------------------------------------
  Description :   This Procedure helps to send a reset code so to update a new password in next procedure .
  Created On  : July 18 ,2016
  Created By  : Shantanu Bansal
  --------------------------------------------------------------------------------------------------------------------------------------
  Inputs  :   in_user_id        ------------  (User's ID)                 ------------------------ VARCHAR (255),
  Output  : Returns a Rest Code if user exists else sends a msg about the non-existance of the user.
  ---------------------------------------------------------------------------------------------------------------------------------------
*/


  -- VARIABLES
  
    -- INT Variables
    DECLARE unique_id INT;
    DECLARE temp_PasswordResetCodeTimeOut INT;
    DECLARE in_lang_code INT ;
    DECLARE temp_default_lang_code INT;
    DECLARE temp_lang_code INT ;
  

    -- DATETIME variables
    DECLARE temp_expire_time datetime;
    DECLARE temp_current_time datetime;
    -- BOOLEAN variables
     DECLARE catchArbitrary BOOLEAN;
    -- VARCHAR Variables
  DECLARE reset_code VARCHAR(255);
    
      SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
   -- Setting Values For the Variables
    SET reset_code = (SELECT uuid());
  
    -- Get Variable Value from config
    SET temp_PasswordResetCodeTimeOut =( SELECT value from authorization_config WHERE parameter='PasswordResetCodeTimeOut');
    
    IF(SELECT COUNT(*) FROM users where email_id = in_user_id AND `name`= in_username) THEN 
      SET unique_id = (select id from password_reset where user_id = in_user_id and expire_time>= now() and is_active=1);
      -- IF TOKEN IS NOT EXPIRED AND IS NOT IN USE
            IF (unique_id) THEN
        SET catchArbitrary=(SELECT xfusion_message_getsingle("CodeSent",TRUE,temp_lang_code));      -- Get Message From messages table
        select @code as code,@msg as msg,reset_key as reset_code from password_reset where id=unique_id;
      ELSE
        -- TOKEN EXPIRED CREATE NEW ONE
        SET temp_current_time=now();
        INSERT into password_reset(user_id,reset_key,creation_time,expire_time,is_active)
              VALUES 
              (in_user_id,reset_code,temp_current_time,date_add(temp_current_time,INTERVAL temp_PasswordResetCodeTimeOut minute),1);
        SET catchArbitrary=(SELECT xfusion_message_getsingle("CodeSent",TRUE,temp_lang_code));      -- Get Message From messages table
        select @code as code,@msg as msg,reset_code;     
      END IF;   
    ELSE 
      SET catchArbitrary=(SELECT xfusion_message_getsingle("isUserExist",FALSE,temp_lang_code));      -- Get Message From messages table
      select @code as code,@msg as msg;
        END IF;

END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_user_create`
--
DROP PROCEDURE xfusion_user_create;

DELIMITER $$

--
-- Create procedure `xfusion_user_create`
--
CREATE PROCEDURE xfusion_user_create(
	IN `in_email` varchar(255),
	IN `in_username` VARCHAR(50),
	IN `in_password` VARCHAR(56),
	IN `in_passwordQuestion` varchar(255),
	IN `in_passwordAnswer` varchar(255),
	IN `in_isApproved` BOOLEAN,
	IN `in_applicationid` VARCHAR(2056),
	IN `in_roleid` VARCHAR(2056),
	IN `in_csv_attributes_id` VARCHAR(2056),
	IN `in_csv_attributes_alias` VARCHAR(2056),
	IN `in_csv_attributes_value` VARCHAR(2056),
	IN `in_password_check_count` INT




)
  COMMENT 'This procedure is for creating a new user and assinging the user different roles in different applications. '
BEGIN
/*
  -------------------------------------------------------------------------------------------------------------------------
  Description :  This procedure is for creating a new user and assinging the user different roles in different applications. 
  Created On  : June 9,2016
  Created By  : Shantanu Bansal
  -------------------------------------------------------------------------------------------------------------------------
  Inputs  :   in_email                     ------------------------------------- Email Id of the new user
              username                     ------------------------------------- user name 
        in_password                  ------------------------------------- Password
                in_passwordQuestion          ------------------------------------- Security Question
                in_passwordAnswer            ------------------------------------- Answer
                in_isApproved                ------------------------------------- Approval Bit
                in_applicationid             ------------------------------------- Comma Seperated Application Id
                in_roleid                    ------------------------------------- Comma Seperated Role Id 
  Output  : A meassage and a code
  --------------------------------------------------------------------------------------------------------------------------
*/
  
  /* Variables */
  -- Boolean Variables
  DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
  DECLARE isUserExist BOOLEAN; 
  DECLARE isUsernameValid BOOLEAN;
  DECLARE isPasswordValid BOOLEAN;
  DECLARE isEmailValid BOOLEAN;
  DECLARE isPasswordQuestionValid BOOLEAN;
  DECLARE isPasswordAnswerValid BOOLEAN;
    DECLARE isUserCreated BOOLEAN;
  DECLARE is_valid BOOLEAN; -- Made as It Can be used in future by chance to maintain uniformity
  DECLARE isAnonymous BOOLEAN;
  DECLARE isDeleted BOOLEAN;
    DECLARE catchAribitrary BOOLEAN;
  -- VarChar Variables
  DECLARE comments VARCHAR(255);
  DECLARE passwordKey VARCHAR(255);
  DECLARE passwordFormat VARCHAR(255);
  DECLARE userKey VARCHAR(255);
--  DECLARE in_username VARCHAR(255);
    DECLARE encoded_password VARCHAR(255);
    DECLARE temp_TTPL_role VARCHAR(255);
  -- Date Variables
  DECLARE creationDate datetime;
  DECLARE lastActivityDate datetime;
  DECLARE lastloginDate datetime;
  DECLARE lastPasswordChangeDate datetime;
  DECLARE lastLockedOutDate datetime;
  DECLARE failedPasswordAttemptWindowStart datetime;
  DECLARE failedPasswordAnswerAttemptWindowStart datetime;
  -- Integer variables
  -- DECLARE getUserID INT;              // Removed Not Using as Multiple User ID
  DECLARE failedPasswordAttemptCount INT;
  DECLARE failedPasswordAnswerAttemptCount INT;
    DECLARE temp_TTPL_role_id INT;
    DECLARE temp_user_id INT;
  DECLARE temp_auth_role_exists BOOLEAN;
  DECLARE temp_app_logo TEXT ;
  DECLARE temp_loading_icon TEXT ;
  DECLARE temp_theme_id int ;
  DECLARE temp_passwords varchar(255);
    
    
  -- DECLARE exit handler for sqlexception BEGIN ROLLBACK;END;
 
 -- for trasaction and roll back in case of failure
  -- SET autocommit = 0;
     -- START TRANSACTION;
   -- TTPL role 
 --  SET in_username = in_email;
  SET temp_TTPL_role='AUTH_VIEWER';
    SET temp_TTPL_role_id= (SELECT id FROM roles WHERE alias=temp_TTPL_role);
  
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
    
  IF (SELECT COUNT(*) FROM users where users.name =in_username AND email_id = in_email)!=0 THEN 
    SET isUserExist = TRUE; 
    SET catchAribitrary=(SELECT xfusion_message_getsingle("isUserExist",isUserExist,temp_lang_code));                       -- Get Message From messages table
    SELECT @code as code,@msg as msg,isUserExist as isUserExist;
  ELSE                      -- As username is email only
     SET isEmailValid = TRUE;
     SET isPasswordValid = TRUE;
    SET isAnonymous = FALSE;                                      -- Default for new User
    SET isDeleted = FALSE;  
    SET isPasswordQuestionValid=TRUE;
    SET isPasswordAnswerValid = TRUE;
    SET isUsernameValid = TRUE;                                     -- Default for new User
    
    IF (isPasswordValid = TRUE AND isUsernameValid = TRUE AND isPasswordQuestionValid = TRUE AND isPasswordAnswerValid = TRUE) THEN
      
      SET passwordKey = (SELECT xfusion_password_getPasswordKey());                              -- Make Function
      SET userKey = (SELECT xfusion_user_getUserKey());                                          -- Make Function
      SET encoded_password = (SELECT xfusion_password_encode(in_password,passwordKey));
            
            
      SET creationDate = (SELECT utc_timestamp());
      SET lastActivityDate = (SELECT utc_timestamp());
      SET lastloginDate = (SELECT utc_timestamp());
      SET lastPasswordChangeDate = (SELECT utc_timestamp());
      SET lastLockedOutDate = (SELECT utc_timestamp());
      SET failedPasswordAttemptWindowStart = (SELECT utc_timestamp());
      SET failedPasswordAnswerAttemptWindowStart = (SELECT utc_timestamp());
      
      SET failedPasswordAttemptCount = 0;                             -- Default Value                          
      SET failedPasswordAnswerAttemptCount = 0;                         -- Default Value        
      
      SET temp_app_logo = (SELECT value FROM authorization_config WHERE parameter='DEFAULT_APP_LOGO'); -- default app_logo
      SET temp_loading_icon =(SELECT value FROM authorization_config WHERE parameter='DEFAULT_LOADING_ICON'); -- default loading_icon
      SET temp_theme_id =(SELECT id FROM themes WHERE is_default=1);-- default theme id
      
      SET temp_passwords = (SELECT xfusion_password_encode(in_password,userKey));
      
            CALL xfusion_string_split(in_applicationid);
      
      -- Add Data to 'users' table
      INSERT 
            INTO users(`name`,user_key,email_id,is_anonymous,is_deleted,last_activity_date,theme_id,app_logo,loading_icon) 
            (SELECT in_username,userKey,in_email,isAnonymous,isDeleted,lastActivityDate,temp_theme_id,temp_app_logo,temp_loading_icon);
      
      -- Get UserID
      
   
  /*    SET getUserID = ( SELECT id 
                  FROM users 
                  WHERE 
                      name = in_username); */
                    
                    
      
      -- Add Data to 'user_organization' table
      
      /*INSERT INTO user_organization(user_id,organization)
      SELECT id,in_organisationid FROM users where name = in_username;
        */    
    
      -- Add to 'membership' table
          
      INSERT INTO membership (
                  user_id,email,`comment`,`password`,
                  password_key,password_format,password_question,
                  password_answer,is_approved,last_activity_date,
                  last_login_date,last_password_changed_date,
                  creation_date,last_locked_out_date,
                  failed_password_attempt_count,failed_password_attempt_window_start,
                  failed_password_answer_attempt_count,failed_password_answer_attempt_window_start,
                  is_locked_out ,is_change_password_prompt_enable,password_check_count
                                    )
      SELECT id,in_email," " as `comment`, encoded_password,passwordKey,0 as password_format,
           in_passwordQuestion,in_passwordAnswer,in_isApproved,lastActivityDate,lastloginDate,
           lastPasswordChangeDate,creationDate,lastLockedOutDate,failedPasswordAttemptCount,
           failedPasswordAttemptWindowStart,failedPasswordAnswerAttemptCount,
                   failedPasswordAnswerAttemptWindowStart,0 as is_locked_out,1 as is_change_password_prompt_enable,in_password_check_count
      FROM users WHERE name = in_username;
      
      -- Add to 'user_Password' table
      INSERT INTO user_passwords(user_id, user_key, passwords)
      VALUES(in_username,userKey,temp_passwords);
                                      
      -- Break RoleIds
      CALL xfusion_string_split(in_roleid);
      
        set @usr_id=(select id from users where name=in_username);
        SET temp_user_id = (select id from users where name=in_username LIMIT 1);

      IF(SELECT COUNT(*) FROM temp_convert WHERE split_data=1 OR split_data=3)=0 THEN
      
        -- Add Data into user_roles        
        INSERT into user_roles(user_id,role_id)
        SELECT temp_user_id,split_data FROM temp_convert;
            
        -- ASSIGNING AUTH VIEWER ROLE
        INSERT into user_roles(user_id,role_id) VALUES(temp_user_id,temp_TTPL_role_id);
      ELSE

        -- Add Data into user_roles        
        INSERT into user_roles(user_id,role_id)
        SELECT temp_user_id,split_data FROM temp_convert;


      END IF;


-- Add attributes of the user
      IF(in_csv_attributes_id is not null and in_csv_attributes_id!='' and in_csv_attributes_id!=' ')THEN
      
                    
              DROP TABLE IF EXISTS attributes_id;
              DROP TABLE IF EXISTS attributes_alias;
              DROP TABLE IF EXISTS attributes_values;


              CALL xfusion_string_split(in_csv_attributes_id);
              CREATE TEMPORARY TABLE attributes_id(id INT NOT NULL AUTO_INCREMENT,name VARCHAR(255),PRIMARY KEY(id)  );
              INSERT INTO attributes_id(name) (SELECT * from temp_convert);
              CALL xfusion_string_split(in_csv_attributes_alias);
              CREATE TEMPORARY TABLE attributes_alias(id INT NOT NULL AUTO_INCREMENT,alias VARCHAR(255),PRIMARY KEY(id)  );
              INSERT INTO attributes_alias(alias) (SELECT * from temp_convert);
              CALL xfusion_string_split(in_csv_attributes_value);
              CREATE TEMPORARY TABLE attributes_values(id INT NOT NULL AUTO_INCREMENT,_values VARCHAR(255),PRIMARY KEY(id)  );
              INSERT INTO attributes_values(_values) (SELECT * from temp_convert);



              INSERT INTO user_attribute(user_id,user_key,attribute_id,attribute_alias,value)
                SELECT temp_user_id,userKey,name,alias,_values
                    FROM attributes_id 
                    INNER JOIN attributes_alias ON attributes_alias.id=attributes_id.id
                    INNER JOIN attributes_values ON attributes_values.id=attributes_alias.id;

  


      END IF;





      SET isUserCreated=TRUE;
      SET catchAribitrary=( SELECT xfusion_message_getsingle("isUserCreated",TRUE,temp_lang_code));               -- Get Message From messages table
      SELECT @code as code,@msg as msg,isUserCreated as isUserCreated,isPasswordValid as isPasswordValid,isUsernameValid as isUsernameValid,isEmailValid as isEmailValid,userKey,in_email as user_id;
    
  ELSE 
      IF (isUsernameValid = FALSE) THEN
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isUsernameValid",FALSE,temp_lang_code));           -- Get Message From messages table
        SELECT @code as code,@msg as msg,isUsernameValid as isUsernameValid;
      ELSEIF (isPasswordValid = FALSE) THEN
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isPasswordValid",FALSE,temp_lang_code));           -- Get Message From messages table
        SELECT @code as code,@msg as msg,isPasswordValid as isPasswordValid;
      ELSEIF (isEmailValid = FALSE) THEN
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isEmailValid",FALSE,temp_lang_code));          -- Get Message From messages table
        SELECT @code as code,@msg as msg,isEmailValid as isEmailValid;
      ELSEIF (isPasswordQuestionValid = FALSE) THEN
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isPasswordQuestionValid",FALSE,temp_lang_code));       -- Get Message From messages table
        SELECT @code as code,@msg as msg,isPasswordQuestionValid as isPasswordQuestionValid;
      ELSE 
        SET catchAribitrary=(SELECT xfusion_message_getsingle("isPasswordAnswerValid",FALSE,temp_lang_code));       -- Get Message From messages table
        SELECT @code as code,@msg as msg,isPasswordAnswerValid as isPasswordAnswerValid;
      END IF;
    END IF;
  END IF;
 --   COMMIT;
END
$$

DELIMITER ;

--
-- Drop procedure `xfusion_user_validate`
--
DROP PROCEDURE xfusion_user_validate;

DELIMITER $$

--
-- Create procedure `xfusion_user_validate`
--
CREATE PROCEDURE xfusion_user_validate(
	IN `in_user_id` varchar(56),
	IN `in_password` varchar(56),
	IN `in_application_key` varchar(56),
	IN `in_token_type` TINYINT


)
  COMMENT 'Verifies that the specified user name and password exist in the database '
BEGIN
  /*
      ----------------------------------------------------------------------------------------------------------------
      Description   :   Verifies that the specified user name and password exist in the database 
      Created On    :     2016-06-09
      Created By    :     Abhishek Ginani
      modified By   :     Sarang Sapre
      Modified On   :     16/05/2019
      ----------------------------------------------------------------------------------------------------------------
      Inputs        :       in_user_id- Name of the user to validate.
                          in_password- Password for the specified user.
                            in_token_type: 0 - for Web users
                                                1- for mobile users
                            in_application_key : Application ID
                                
      Output        :   Returns true if the specified username and password are valid; otherwise, false.
      -----------------------------------------------------------------------------------------------------------------
  */

             DECLARE in_lang_code INT ;
           DECLARE temp_default_lang_code INT;
          DECLARE temp_lang_code INT ;
           DECLARE is_valid BOOLEAN;
        DECLARE msg_parameter varchar(256);
        DECLARE parameter_value BOOLEAN;
        DECLARE temp_is_deleted BOOLEAN;
            DECLARE temp_user_key varchar(256);
        DECLARE temp_is_locked_out int;
        DECLARE temp_is_approved int;
        DECLARE temp_dbpassword varchar(256);
        DECLARE temp_password_key varchar(256);
        DECLARE temp_password_hash varchar(512);
        DECLARE temp_userid int;
        DECLARE temp_access_key varchar(64);
        DECLARE temp_last_activity_date DATETIME;
        DECLARE temp_password_change_date DATETIME;
        DECLARE temp_last_login_date DATETIME;
        DECLARE temp_application_id int;
        DECLARE temp_role_id INT;
          DECLARE temp_role_name VARCHAR(255);
          declare temp_user_name varchar(150);
          DECLARE temp_is_password_prompt_enable int(11);
          DECLARE temp_theme_id int(11);
          DECLARE temp_loading_icon TEXT;
          DECLARE temp_app_logo TEXT ;
          DECLARE temp_is_expired INT ; 
          DECLARE catchArbitrary BOOLEAN;
       --  DECLARE exit handler for sqlexception BEGIN ROLLBACK;END;
    
        
        -- SET autocommit=0;
        -- START TRANSACTION;
        
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
        

        SET temp_userid=(select id from users where name=in_user_id OR email_id =in_user_id  limit 1 );
        SET temp_is_expired = (select is_expired from membership where user_id = temp_userid limit 1);
        SET temp_is_password_prompt_enable=(SELECT is_change_password_prompt_enable FROM membership WHERE user_id=temp_userid);
        
   IF(temp_is_expired = 1)THEN

                 SET is_valid=FALSE;
                 SET catchArbitrary=(SELECT xfusion_message_getsingle("isExpired",FALSE,temp_lang_code));          -- Get Message From messages table
                 SELECT is_valid as status,@code as code,@msg as message,utc_timestamp() as `utc_time`,xfusion_config_getvalue('IsGrafanaEnabled') as IsGrafanaEnabled;  
  
   ELSE
        SELECT theme_id ,loading_icon ,app_logo
        INTO temp_theme_id,temp_loading_icon,temp_app_logo
        FROM users WHERE name=in_user_id OR email_id =in_user_id limit 1;
        
        
        SET is_valid=FALSE;
        SELECT password, password_key, is_approved,is_locked_out,user_key,user_id,is_deleted,
          if(CONCAT(first_name,COALESCE(last_name,''))="",user_id,CONCAT(first_name,COALESCE(last_name,'')))
        INTO temp_dbpassword,
             temp_password_key,
             temp_is_approved,
             temp_is_locked_out,
             temp_user_key,
             temp_userid,
            temp_is_deleted,
            temp_user_name
        FROM vw_user_membership  WHERE vw_user_membership.user_id=temp_userid limit 1;
     
           
      SET temp_access_key=(select roles_access_key from vw_users_roles_applications where users_id=temp_userid and application_key=in_application_key limit 1);
        SET temp_application_id=(select id from applications where application_key=in_application_key limit 1);
        -- Case for validating application key     
        IF (select count(*) from vw_users_roles_applications where application_key=in_application_key and users_id=temp_userid)>0 THEN
      
            -- First check user exist in db. if count in "temp_user_info" table is 0 then set is_valid to false.
              IF temp_user_key is not null THEN
                
                -- Check user lock status
                IF temp_is_locked_out<1 THEN                
                    
                    -- Check user approval status
                    IF temp_is_deleted < 1 THEN
                                     
                        -- Get password hash
                        SET temp_password_hash=(select xfusion_password_encode(in_password,temp_password_key));
                        
                        -- Validate password   
                        IF(temp_password_hash!=temp_dbpassword) THEN
                            SET is_valid=FALSE;
                            SET msg_parameter='passwordNotMatched';
                            SET parameter_value=TRUE;
                            
                            -- Update password failure count
                            call xfusion_password_failure_update_count(temp_user_key);
                        ELSE
                            -- Case when password matched
                            SET is_valid=TRUE;
                            SET msg_parameter='passwordNotMatched';
                            SET parameter_value=FALSE;
                            
                           
                            
                            -- Update membership on successfull login
                            
                        
                            SELECT id,
                                  alias 
                            INTO temp_role_id,temp_role_name
                            FROM  roles WHERE access_key=temp_access_key;

                                
                            set @access_token:=NULL;
                            set @access_token=uuid();       
                                
                            -- Insert Token on successfull login
                            insert into auth_token
                            (
                            user_id,
                            application_id,
                            access_key,
                            token,
                            added_on,
                            is_mobile_token,
              token_binary_key
                            )
                            values(
                                temp_userid,temp_application_id,temp_access_key,@access_token,unix_timestamp(),
                                in_token_type,xfusion_utility_ordered_uuid(token)
                            );
                             
                        END IF;
                        
                    ELSE
                        SET is_valid=FALSE;
                        SET msg_parameter='isUserActive';
                        SET parameter_value=False;
                    END IF;
                    
                ELSE
                    
                    SET is_valid=FALSE;
                    SET msg_parameter='isUserLockedOut';
                    SET parameter_value=TRUE;
                    
                END IF;
            ELSE
                SET is_valid=FALSE;
                SET msg_parameter='isUserExist';
                SET parameter_value=False;
            END IF;
    ELSE
                SET is_valid=FALSE;
                SET msg_parameter='isValidApplication';
                SET parameter_value=False;
        END IF;
        -- Get message 
       SET @result= (select xfusion_message_getsingle(msg_parameter, parameter_value,temp_lang_code));
    --  COMMIT;  
    IF is_valid and temp_access_key is not null THEN
        select  temp_role_name as roles_name,temp_role_id as roles_id,is_valid as status,
                    @code as code,@msg as message, temp_user_key as user_key, 
                    temp_access_key as access_key,in_user_id as user_id ,
                    utc_timestamp() as `utc_time`,
                    @access_token as access_token,
                    in_token_type as token_type,
                    temp_user_name as user_name,
                    temp_is_password_prompt_enable as is_change_password_prompt_enable,
                     xfusion_config_getvalue('IsGrafanaEnabled') as IsGrafanaEnabled,
                temp_theme_id As auth_theme_id,
                temp_loading_icon As auth_loading_icon,
                temp_app_logo As auth_app_logo;
                
        -- select is_valid as status,@code as code,@msg as message, temp_user_key as user_key, temp_access_key as access_key,in_user_id as user_id ,utc_timestamp() as `utc_time`,temp_last_activity_date as last_activity_date,temp_password_change_date as last_password_change_date,temp_last_login_date as last_login_date;

    ELSE
        select is_valid as status,@code as code,@msg as message,utc_timestamp() as `utc_time`,xfusion_config_getvalue('IsGrafanaEnabled') as IsGrafanaEnabled;        
    END IF;

    END IF;
END
$$

DELIMITER ;



-- Dumping structure for procedure xfusion_users_get_by_application
DROP PROCEDURE IF EXISTS `xfusion_users_get_by_application`;
DELIMITER //
CREATE PROCEDURE `xfusion_users_get_by_application`(
	IN `in_user_key` VARCHAR(255),
	IN `in_user_id` VARCHAR(255),
	IN `in_applicationid` INT





)
    COMMENT 'This procedure is for getting all the users from the application'
BEGIN
/*
  ----------------------------------------------------------------------------------------------------------------
  Description :  This procedure is for getting all the users from the application
  Created On  : June 13,2016
  Created By  : Shantanu Bansal
  ----------------------------------------------------------------------------------------------------------------
  Inputs  :     in_user_key                                  -------- User's Key
          in_user_id                                   -------- User's ID
          in_applicationid                             -------- Application Id
  Output  :   UserDetails From Specific Kind Of Application 
          membership.email, 
          membership.user_key,
          membership.is_approved,
          membership.last_activity_date,
          membership.last_login_date,
          membership.creation_date,
          membership.is_locked_out,
                    users.application_id,
                    applications.name,
                    user_roles.role_id,
                    roles.name
  -----------------------------------------------------------------------------------------------------------------
*/
  -- variables
    
  DECLARE catchArbitrary BOOLEAN;
  DECLARE temp_TTPL_role VARCHAR(255);
    DECLARE temp_user_role_id INT;
  DECLARE temp_user_role_name VARCHAR(255);
    DECLARE temp_user_id INT;
     DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
 
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));
 
    
    SET temp_TTPL_role='TTPL_ADMIN';
  
  SET temp_user_role_name=(SELECT name FROM roles WHERE application_id = in_applicationid LIMIT 1);
    
    SET temp_user_id = (SELECT DISTINCT id FROM users where user_key=in_user_key);
    SET temp_user_role_id=(SELECT id FROM roles WHERE application_id=in_applicationid and id in(SELECT role_id FROM user_roles WHERE user_id=temp_user_id) LIMIT 1);
    SET temp_user_role_name=(SELECT name FROM roles WHERE id=temp_user_role_id);
    
    -- Prepared Concated User Addresses By Comma Seprated For Each Users.
    DROP TEMPORARY TABLE IF EXISTS temp_users_address;
    CREATE TEMPORARY TABLE temp_users_address
    AS
    SELECT user_id, GROUP_CONCAT(address) AS addresses,
           GROUP_CONCAT(is_permanent_address) AS is_permanent_address 
    FROM xfusion_development_auth_engine.users_address
    GROUP BY user_id;
    
    -- Prepared Concated User Contact Numbers By Comma Seprated For Each Users.
    DROP TEMPORARY TABLE IF EXISTS temp_users_contact_number;
    CREATE TEMPORARY TABLE temp_users_contact_number
    AS
    SELECT user_id, GROUP_CONCAT(contact_number) AS contact_numbers
    FROM xfusion_development_auth_engine.users_contact_number
    GROUP BY user_id;
    
    -- Prepared Concated User Attributes and Values By Comma Seprated For Each Users By Role Wise.
    DROP TEMPORARY TABLE IF EXISTS temp_users_role_attributes;
    CREATE TEMPORARY TABLE temp_users_role_attributes
    AS    
    SELECT user_id,user_key,
       GROUP_CONCAT(attribute_id) AS attribute_id,
       GROUP_CONCAT(attribute_alias) AS attribute_alias,
       GROUP_CONCAT(value) AS attribute_values
       FROM user_attribute WHERE attribute_id IN (
    SELECT attribute_id FROM role_attribute 
    WHERE role_id IN(SELECT id FROM roles 
    WHERE application_id=in_applicationid))
    GROUP BY user_id;

    
    IF(SELECT COUNT(*) FROM vw_users_roles_applications WHERE users_user_key=in_user_key AND roles_name=temp_TTPL_role) THEN 
      
      IF(SELECT COUNT(*) FROM vw_users_roles_applications WHERE users_user_key=in_user_key AND applications_id=in_applicationid) THEN
          
           SELECT users_id,users_name,users_email,users_is_deleted,users_last_activity_date,users_user_key,
              membership_email,membership_is_approved,membership_is_locked_out,membership_last_activity_date,
              membership_last_login_date,membership_last_password_changed_date,membership_creation_date,
              membership_last_locked_out_date,
              roles_id,roles_alias as roles_name,applications_name,applications_alias,first_name,last_name,
              preferred_contact_number,country_id,country_name,country_alias,country_code,state_id,
              state_name,state_alias,city_id,city_name,city_alias,user_image_path,user_thumbail_image_path,
              addresses,is_permanent_address,contact_numbers,attribute_id,attribute_alias,attribute_values
          FROM vw_users_roles_applications 
          LEFT JOIN temp_users_address ON vw_users_roles_applications.users_id=temp_users_address.user_id
          LEFT JOIN temp_users_contact_number ON vw_users_roles_applications.users_id=temp_users_contact_number.user_id
          LEFT JOIN temp_users_role_attributes ON vw_users_roles_applications.users_id=temp_users_role_attributes.user_id
          WHERE applications_id=in_applicationid 
               AND  users_user_key!=in_user_key AND 
      roles_name LIKE CONCAT('%',temp_user_role_name)
		ORDER BY users_id DESC;
      ELSE
        SET catchArbitrary=(SELECT xfusion_message_getsingle("isUserApplicationValid",FALSE,temp_lang_code));     -- Get Message From messages table
        SELECT @code AS code, @msg AS msg;

      END IF;

  ELSE


      IF(SELECT COUNT(*) FROM vw_users_roles_applications WHERE users_user_key=in_user_key AND applications_id=in_applicationid) THEN
          
              SELECT users_id,users_name,users_email,users_is_deleted,users_last_activity_date,users_user_key,
              membership_email,membership_is_approved,membership_is_locked_out,membership_last_activity_date,
              membership_last_login_date,membership_last_password_changed_date,membership_creation_date,
              membership_last_locked_out_date,
              roles_id,roles_alias as roles_name,applications_name,applications_alias,first_name,last_name,
              preferred_contact_number,country_id,country_name,country_alias,country_code,state_id,
              state_name,state_alias,city_id,city_name,city_alias,user_image_path,user_thumbail_image_path,
              addresses,is_permanent_address,contact_numbers,attribute_id,attribute_alias,attribute_values
          FROM vw_users_roles_applications 
          LEFT JOIN temp_users_address ON vw_users_roles_applications.users_id=temp_users_address.user_id
          LEFT JOIN temp_users_contact_number ON vw_users_roles_applications.users_id=temp_users_contact_number.user_id
          LEFT JOIN temp_users_role_attributes ON vw_users_roles_applications.users_id=temp_users_role_attributes.user_id
          WHERE applications_id=in_applicationid 
                AND users_user_key!=in_user_key 
                             AND roles_name LIKE CONCAT('%',temp_user_role_name)
              AND applications_id!=1 
              AND users_id NOT in (SELECT users_id FROM vw_users_roles_applications WHERE roles_name=temp_TTPL_role) ORDER BY users_id DESC;
      ELSE
        SET catchArbitrary=(SELECT xfusion_message_getsingle("isUserApplicationValid",FALSE,temp_lang_code));     -- Get Message From messages table
        SELECT @code AS code, @msg AS msg;
                    
      END IF;
  END IF;
END//
DELIMITER ;




DELETE FROM `messages` WHERE `parameter`='isAccountSettingUpdatedSuccessfully';
DELETE FROM `messages` WHERE `parameter`='isApplicationCheck';
DELETE FROM `messages` WHERE `parameter`='isRoleCheck';


INSERT INTO `messages` (`parameter`, `value`, `code`, `message`, `language_id`) VALUES ('isAccountSettingUpdatedSuccessfully', 1, 180, 'Account setting updated successfully.', 1);
INSERT INTO `messages` (`parameter`, `value`, `code`, `message`, `language_id`) VALUES ('isAccountSettingUpdatedSuccessfully', 1, 180, '帐户设置已成功更新', 2);
INSERT INTO `messages` (`parameter`, `value`, `code`, `message`, `language_id`) VALUES ('isApplicationCheck', 1, 181, 'Application cannot be deleted', 1);
INSERT INTO `messages` (`parameter`, `value`, `code`, `message`, `language_id`) VALUES ('isRoleCheck', 1, 182, 'Role cannot be deleted', 1);


--
-- Enable foreign keys
--

/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;