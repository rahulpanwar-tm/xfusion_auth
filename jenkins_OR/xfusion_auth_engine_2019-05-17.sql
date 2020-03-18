USE `xfusion_auth_engine`;


DROP FUNCTION IF EXISTS `xfusion_utility_ordered_uuid`;
DELIMITER //
CREATE  FUNCTION `xfusion_utility_ordered_uuid`(`uuid` BINARY(36)) RETURNS binary(16)
    DETERMINISTIC
    COMMENT 'Converts uuid into binary format'
RETURN UNHEX(CONCAT(SUBSTR(uuid, 15, 4),SUBSTR(uuid, 10, 4),SUBSTR(uuid, 1, 8),SUBSTR(uuid, 20, 4),SUBSTR(uuid, 25)))//
DELIMITER ;

-- Data exporting was unselected.
-- Dumping structure for procedure xfusion_auth_engine.xfusion_user_validate
DROP PROCEDURE IF EXISTS `xfusion_user_validate`;
DELIMITER //
CREATE  PROCEDURE `xfusion_user_validate`(
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
END//
DELIMITER ;


ALTER TABLE membership
ADD is_expired TINYINT;


ALTER TABLE auth_token
ADD token_binary_key BINARY(50);

INSERT INTO messages( parameter, value, code, message, language_id) VALUES
( 'isExpired', 0, 142, 'Your 14 Days Trail Session is Expired.  Please Contact us via email info@globetouch.com', 1), 
( 'isExpired', 0, 143, ' 您的14天试用期已过期请通过电子邮件info@globetouch.com与我们联系', 2);


DROP EVENT IF EXISTS `event_expire_signup_users`;
DELIMITER //
CREATE  EVENT `event_expire_signup_users` ON SCHEDULE EVERY 1 DAY STARTS '2019-05-17 00:00:00' ON COMPLETION PRESERVE ENABLE COMMENT 'used to expire signup users who' DO BEGIN

  
  DROP TEMPORARY TABLE IF EXISTS temp_user_list;
  CREATE TEMPORARY TABLE temp_user_list
  SELECT users_id 
  FROM vw_users_roles_applications 
  WHERE roles_alias LIKE CONCAT('%','signup','%')  AND roles_parent_role_id = 313
   AND application_key = '9a959887-5946-11e6-9bb0-fe984cc15272'
   AND membership_creation_date > '2019-05-16 00:00:00'
  AND DATEDIFF(now() ,membership_creation_date) >14 ; 
  
  
  UPDATE membership
  SET is_expired = 1
  WHERE user_id in (SELECT users_id FROM temp_user_list);
  

END//
DELIMITER ;


UPDATE auth_token
SET token_binary_key = xfusion_utility_ordered_uuid(token);


