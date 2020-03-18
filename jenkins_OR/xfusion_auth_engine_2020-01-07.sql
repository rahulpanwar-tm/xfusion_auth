	-- --------------------------------------------------------
-- Host:                         192.168.1.122
-- Server version:               10.1.12-MariaDB - MariaDB Server
-- Server OS:                    Linux
-- HeidiSQL Version:             10.1.0.5464
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Dumping structure for procedure xfusion_development_auth_engine.xfusion_application_create
DROP PROCEDURE IF EXISTS `xfusion_application_create`;
DELIMITER //
CREATE  PROCEDURE `xfusion_application_create`(
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
                           SET temp_role_id = (SELECT DISTINCT id FROM roles WHERE access_key=temp_access_key);
                           
                           -- Mapping User with the New Role
                             INSERT INTO user_roles(user_id,role_id)
                                 VALUES(temp_user_id,temp_role_id);
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












END//
DELIMITER ;

-- Dumping structure for procedure xfusion_development_auth_engine.xfusion_application_get_all
DROP PROCEDURE IF EXISTS `xfusion_application_get_all`;
DELIMITER //
CREATE  PROCEDURE `xfusion_application_get_all`(
	IN `in_user_key` VARCHAR(255),
	IN `in_user_id` VARCHAR(255)





)
    COMMENT 'This Procedure returns all the application of the user'
BEGIN


/*
	---------------------------------------------------------------------------------------------------------------------------------------
	Description	: 	This Procedure returns all the application of the user
	Created On	:	July 20,2016
	Created By	:	Shantanu Bansal
	Modified By : Sarang Sapre
    Modified On : 26 Sept 2018
    Modification : Applied Localization
	---------------------------------------------------------------------------------------------------------------------------------------
	Inputs	:   in_user_key 			------------	(User's Key)								------------------------ VARCHAR (255),
				in_user_id  			------------	(User's ID)									------------------------ VARCHAR (255),
	Output	:	Returns all the application of the user
	---------------------------------------------------------------------------------------------------------------------------------------
*/
	-- Variables
 DECLARE ttpl_application_name VARCHAR(255);
 DECLARE ttpl_admin_role VARCHAR(255);
    -- Default TTPL CONFIG
    SET ttpl_admin_role = 'TTPL_ADMIN';
	SET ttpl_application_name='AUTH_ENGINE';
  
    IF(SELECT count(*) FROM vw_users_roles_applications WHERE users_user_key=in_user_key AND roles_name=ttpl_admin_role AND applications_name=ttpl_application_name)THEN
   
  	SELECT
				DISTINCT 	applications_id,
							applications_name,
							applications_alias,
							application_key,
							applications_url,
							applications_description,
							applications_service_url,
							applications_view_url,
							applications_api_url,
                            applications_file_path,
                            applications_logo_file_path,
                            applications_is_admin_app
				FROM 		vw_users_roles_applications 
				WHERE 		users_user_key=in_user_key
				--		AND applications_is_admin_app!=1
						AND applications_id IS NOT null 
						ORDER BY applications_name ASC;
            
    ElSE 
		        SELECT DISTINCT applications_id,
							              applications_name,
                            applications_alias,
                            application_key,
                            applications_url,
                            applications_description,
                            applications_service_url,
                            applications_view_url,
                            applications_api_url,
                            applications_file_path,
                            applications_logo_file_path,
                            applications_is_admin_app
				FROM 		vw_users_roles_applications 
				WHERE 		users_user_key=in_user_key
				 AND applications_name !=ttpl_application_name 
			--	 AND applications_is_admin_app!=1
                        AND applications_id IS NOT null
								ORDER BY applications_name ASC; 
    
                        

	END IF;

END//
DELIMITER ;

-- Dumping structure for procedure xfusion_development_auth_engine.xfusion_application_update
DROP PROCEDURE IF EXISTS `xfusion_application_update`;
DELIMITER //
CREATE  PROCEDURE `xfusion_application_update`(
	IN `in_user_key` VARCHAR(255),
	IN `in_user_id` VARCHAR(255),
	IN `in_application_id` INT,
	IN `in_application_alias` VARCHAR(255),
	IN `in_url` VARCHAR(255),
	IN `in_description` VARCHAR(255),
	IN `in_service_url` VARCHAR(255),
	IN `in_api_url` VARCHAR(255),
	IN `in_view_url` VARCHAR(255),
	IN `in_file_path` VARCHAR(2056),
	IN `in_logo_file_path` VARCHAR(2056),
	IN `in_admin_app` TINYINT

)
    COMMENT 'This Procedure helps to update a application.'
BEGIN
/*
	--------------------------------------------------------------------------------------------------------------------------------------
	Description	:  This Procedure helps to update a application.
	Created On	:	
	Created By	:	Shantanu Bansal
	--------------------------------------------------------------------------------------------------------------------------------------
	Inputs	:   in_user_key 		  	  ------------	(User's Key)							  	------------------------ VARCHAR (255),
				      in_user_id  			    ------------	(User's ID)								  	------------------------ VARCHAR (255),
				      in_application_id	    ------------	(ID Application )							------------------------ INT,
				      in_application_alias	------------	(Alias of Application Name)		------------------------ VARCHAR (255),
				      in_url  				      ------------	(URL of Application)					------------------------ VARCHAR (255),
              in_description	  		------------	(Decription about Application)------------------------ VARCHAR (255)
				      in_view_url  			    ------------	(URL of Application)					------------------------ VARCHAR (255),
				      in_api_url  		    	------------	(URL of Application)					------------------------ VARCHAR (255),
              in_service_url		  	------------	(URL of Application)					------------------------ VARCHAR (255),
              in_logo_file_path     ------------  (Application Icon)            ------------------------ VARCHAR (2056)

	Output	:	Updates and Sends a message with a code
	---------------------------------------------------------------------------------------------------------------------------------------
*/

	-- Variables
	DECLARE catchArbitrary BOOLEAN;
  DECLARE in_lang_code INT ;
  DECLARE temp_default_lang_code INT;
  DECLARE temp_lang_code INT ;
  
  SET in_lang_code=null;
  SET temp_default_lang_code=(SELECT code FROM language WHERE is_default=1);
  SET temp_lang_code=(SELECT COALESCE(in_lang_code , temp_default_lang_code));


	IF(in_application_alias='') THEN
			SET catchArbitrary=(SELECT xfusion_message_getsingle("isApplicationAliasEmpty",TRUE,temp_lang_code)); 			-- Get Message From messages table
			SELECT @code as code,@msg as msg;


	ELSE
	      IF (SELECT count(*) FROM applications WHERE alias=in_application_alias OR view_url=in_view_url OR api_url = in_api_url) THEN
         SET catchArbitrary=(SELECT xfusion_message_getsingle("isApplicationCreated",FALSE,temp_lang_code));         -- Get Message From messages table
         SELECT @code as code,@msg as msg;
         
         ELSE
         
			IF(SELECT COUNT(*) FROM vw_users_roles_applications WHERE users_user_key=in_user_key and applications_id=in_application_id) THEN
					-- Update Command
					UPDATE applications
							SET alias= in_application_alias,
								url=in_url,
								description=in_description,
								service_url= in_service_url,
								view_url= in_view_url,
								api_url=in_api_url,
                file_path=in_file_path,
                logo_file_path=in_logo_file_path,
                is_admin_app = in_admin_app
							Where id=in_application_id;			
							SET catchArbitrary=(SELECT xfusion_message_getsingle("isApplicationUpdated",TRUE,temp_lang_code)); 			-- Get Message From messages table
							SELECT @code as code,@msg as msg;
			ELSE
							SET catchArbitrary=(SELECT xfusion_message_getsingle("isApplicationExists",FALSE,temp_lang_code)); 			-- Get Message From messages table
							SELECT @code as code,@msg as msg;

			END IF;
	END IF;
	END IF;
END//
DELIMITER ;

-- Dumping structure for procedure xfusion_development_auth_engine.xfusion_roles_get_all_by_user_application
DROP PROCEDURE IF EXISTS `xfusion_roles_get_all_by_user_application`;
DELIMITER //
CREATE  PROCEDURE `xfusion_roles_get_all_by_user_application`(
	IN `in_user_key` VARCHAR(255),
	IN `in_user_id` VARCHAR(255),
	IN `in_application_id` INT








)
    COMMENT 'This procedure is for getting roles on the basis of application id if user exists in the application.'
BEGIN
/*
   ----------------------------------------------------------------------------------------------------------------
   Description :  This procedure is for getting roles on the basis of application id if user exists in the application
   Created On  :  June 13,2016
   Created By  :  Shantanu Bansal
   ----------------------------------------------------------------------------------------------------------------
   Inputs   :   in_user_key               ------------------------------ User's Key
                in_user_id                ------------------------------ User's ID
                in_application_id         ------------------------------ Application's ID
   Output   :  Roles And Their Details
   -----------------------------------------------------------------------------------------------------------------
*/
DECLARE temp_user_id INT;
DECLARE temp_user_role_id INT;
DECLARE temp_TTPL_role VARCHAR(255);
DECLARE isTtplUser BOOLEAN;
DECLARE temp_role_path VARCHAR(255);
   
   
   

SET temp_user_id = (SELECT id FROM users WHERE user_key=in_user_key);
SET temp_user_role_id=(SELECT id FROM roles WHERE application_id=in_application_id and id in(SELECT role_id FROM user_roles WHERE user_id=temp_user_id) LIMIT 1);
SET temp_role_path=(SELECT path FROM roles WHERE id=temp_user_role_id);
 
SET temp_TTPL_role = 'TTPL_ADMIN';
SET isTtplUser = 
            (
               IF (
                  (
                        temp_user_id in (SELECT users_id FROM vw_users_roles_applications WHERE roles_name=temp_TTPL_role)
                        )
                        ,TRUE,FALSE
               )
                );
                

IF(isTtplUser) THEN

      SELECT DISTINCT roles.id as roles_id,
roles.alias as roles_name,
roles.access_key as roles_access_key,
roles.application_id as applications_id

,
                group_concat(coalesce(`attributes`.`id` ,'')
            separator '#x#f#') AS `attributes_ids`,
        group_concat(coalesce(`attributes`.`name`,'')
            separator '#x#f#') AS `attributes_names`,
        group_concat(coalesce(`attributes`.`alias`,'')
            separator '#x#f#') AS `attributes_alias`,
        group_concat(coalesce(`attributes`.`data_type`,'')
            separator '#x#f#') AS `attributes_data_types`,
        group_concat(coalesce(`attributes`.`reg_ex`,'')
            separator '#x#f#') AS `attributes_reg_ex`,
        group_concat(coalesce(`datatypes`.`name`,'')
            separator '#x#f#') AS `datatypes_names`,
        group_concat(coalesce(`datatypes`.`is_regex`,'')
            separator '#x#f#') AS `datatypes_is_regex`,
      group_concat(coalesce(`role_attribute`.`is_required`,'')
            separator '#x#f#') AS `role_attribute_is_required` 

 FROM roles

        left join `role_attribute` ON `role_attribute`.`role_id` = `roles`.`id`
        left join `attributes` ON `role_attribute`.`attribute_id` = `attributes`.`id`
        left join `datatypes` ON `datatypes`.`id` = `attributes`.`data_type`        

WHERE  roles.application_id=in_application_id  
GROUP BY roles.id
ORDER BY roles.alias ASC                     -- AND id!=temp_user_role_id
;
ELSE 
         SELECT DISTINCT roles.id as roles_id,
roles.alias as roles_name,
roles.access_key as roles_access_key,
roles.application_id as applications_id 
,
                       group_concat(coalesce(`attributes`.`id` ,'')
            separator '#x#f#') AS `attributes_ids`,
        group_concat(coalesce(`attributes`.`name`,'')
            separator '#x#f#') AS `attributes_names`,
        group_concat(coalesce(`attributes`.`alias`,'')
            separator '#x#f#') AS `attributes_alias`,
        group_concat(coalesce(`attributes`.`data_type`,'')
            separator '#x#f#') AS `attributes_data_types`,
        group_concat(coalesce(`attributes`.`reg_ex`,'')
            separator '#x#f#') AS `attributes_reg_ex`,
        group_concat(coalesce(`datatypes`.`name`,'')
            separator '#x#f#') AS `datatypes_names`,
        group_concat(coalesce(`datatypes`.`is_regex`,'')
            separator '#x#f#') AS `datatypes_is_regex`,
      group_concat(coalesce(`role_attribute`.`is_required`,'')
            separator '#x#f#') AS `role_attribute_is_required` 
FROM roles  
left join `user_roles` ON `user_roles`.`role_id`=`roles`.`id`   
left join `role_attribute` ON `role_attribute`.`role_id` = `roles`.`id`
left join `attributes` ON `role_attribute`.`attribute_id` = `attributes`.`id`
left join `datatypes` ON `datatypes`.`id` = `attributes`.`data_type`
WHERE  roles.application_id=in_application_id AND roles.name!=temp_TTPL_role 
AND (roles.path like temp_role_path OR roles.path like concat(temp_role_path,'/','%'))
 AND roles.id!=temp_user_role_id
GROUP BY roles.id
ORDER BY roles.alias ASC

;

END IF;                 
END//
DELIMITER ;



ALTER TABLE `attributes`
CHANGE COLUMN `reg_ex` `reg_ex` VARCHAR(256) NULL DEFAULT NULL COMMENT 'Reg_ex formula of the data type' AFTER `data_type`;



ALTER TABLE `attributes`
	ADD UNIQUE INDEX `name_alias_data_type` (`name`, `alias`, `data_type`);





/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
