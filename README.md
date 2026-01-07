![MIKES DATA WORK GIT REPO](https://raw.githubusercontent.com/mikesdatawork/images/master/git_mikes_data_work_banner_01.png "Mikes Data Work")        

# Use SQL To Add All SQL Instance Ports To Firewall
**Post Date: November 4, 2016**   


![Add SQL Firewall Rules]( https://mikesdatawork.files.wordpress.com/2016/11/mikes_data_work_43340454_s.jpg "SQL Fire Wall Rules")     



## Contents    
- [About Process](##About-Process)  
- [SQL Logic](#SQL-Logic)  
- [Author](#Author)  
- [License](#License)       

## About-Process

<p>Here's some SQL logic that extrapolates all instances ports, and creates a nifty netsh command so you can add those ports to the firewall with a display name of "SQL Instance MyInstanceName".</p>      



## SQL-Logic
```SQL
use master;
set nocount on
 
declare @sql_instances      table ([rootkey] varchar(255), [value] varchar(255))
declare @firewall_commands  table ([int] int identity(1,1), [command] varchar(1000))
declare @run_commands       varchar(max) = ''
 
insert into @sql_instances 
exec master.dbo.xp_instance_regenumvalues 
    @rootkey    = N'HKEY_LOCAL_MACHINE'
,   @key        = N'SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names\\SQL';
 
declare db_cursor   cursor for select upper([rootkey]), upper([value]) from @sql_instances
declare @instance_name  varchar(255)
declare @instance_path  varchar(255)
open    db_cursor;
fetch next from db_cursor into @instance_name, @instance_path
    while @@fetch_status = 0  
        begin 
            declare @port   varchar(50)
            declare @key    varchar(255) = 'software\microsoft\microsoft sql server\' + @instance_path + '\mssqlserver\supersocketnetlib\tcp\ipall'
            exec master..xp_regread
            @rootkey        = 'hkey_local_machine'
            ,   @key        = @key
            ,   @value_name = 'tcpdynamicports'
            ,   @value      = @port output
            declare @add_firewall_rule  varchar(255)
            set @add_firewall_rule  = 'exec master..xp_cmdshell ''netsh advfirewall firewall add rule name="SQL Instance ' 
                            + upper(@instance_name) + '" dir=in action=allow protocol=tcp localport=' + isnull(convert(varchar(10), @port), 1433) + ''''
            insert into @firewall_commands
            select  (@add_firewall_rule)
            fetch next from db_cursor into @instance_name, @instance_path
        end;
    close db_cursor
deallocate db_cursor;
select  @run_commands = @run_commands + '' + command + ';' + char(10) from @firewall_commands
exec    (@run_commands)
```

![Firewall Rules For SQL]( https://mikesdatawork.files.wordpress.com/2016/11/image0012.png "SQL Firewall Rules")
 
Your results will look something like this which can be run from the server directly, or concatenated into variable, and run from a Job. As long as the SQL Service accounts have rights within the OS; the ports will be added accordingly. Using the logic above it is packaged into a variable @run_commands which is run on the server, and adds the firewall rules.


![Get Firewall Commands]( https://mikesdatawork.files.wordpress.com/2016/11/image0021.png "Create Firewall Commands")
 




[![WorksEveryTime](https://forthebadge.com/images/badges/60-percent-of-the-time-works-every-time.svg)](https://shitday.de/)

## Author

[![Gist](https://img.shields.io/badge/Gist-MikesDataWork-<COLOR>.svg)](https://gist.github.com/mikesdatawork)
[![Twitter](https://img.shields.io/badge/Twitter-MikesDataWork-<COLOR>.svg)](https://twitter.com/mikesdatawork)
[![Wordpress](https://img.shields.io/badge/Wordpress-MikesDataWork-<COLOR>.svg)](https://mikesdatawork.wordpress.com/)

    
## License
[![LicenseCCSA](https://img.shields.io/badge/License-CreativeCommonsSA-<COLOR>.svg)](https://creativecommons.org/share-your-work/licensing-types-examples/)

![Mikes Data Work](https://raw.githubusercontent.com/mikesdatawork/images/master/git_mikes_data_work_banner_02.png "Mikes Data Work")

