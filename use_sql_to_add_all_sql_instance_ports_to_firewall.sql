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
