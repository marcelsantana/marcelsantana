=====================
APAGAR MUITOS ARQUIVOS NO LINUX
=====================
mkdir empty_dir
rsync -a --delete empty_dir/    logs/
OU
cd logs
perl -e 'for(<*.log>){((stat)[9]<(unlink))}'

=====================
GIT
=====================
git checkout master
git pull origin master
git branch <nome branch>

---------------------
---------------------
excluir um branch remoto
git push origin :nome_do_branch

---------------------
Merge de branches
---------------------
git checkout development
git pull origin development
git branch -r
**** para cada branch que deve ser integrado
git merge --no-ff <nome do branch completo>

---------------------
Merge do development com release e com master
---------------------
git checkout release
git merge --no-ff development

git checkout master
git merge --no-ff release

---------------------
voltar um commit
---------------------
git reset --hard HEAD

---------------------
Clonar repositório com submodulos
---------------------
git clone --recursive git@bitbucket.org:integrador_b2w/integrador_core.git .

---------------------
Verificar quais branches faltam fazer merge
---------------------
git branch --no-merged <branch>

---------------------
Verificar quais merges formam um branch
---------------------
git branch --merged <branch>
---------------------
User config
---------------------
git config --list
git config --global user.name "Marcel Santana"
git config --global user.email "marceltuk@gmail.com"

--------------------------------------------------------------------------------
-- FRM-30085: Unable to adjust form for output. is Solved
--------------------------------------------------------------------------------
select * from dba_objects
where status <> 'VALID'
AND OWNER = 'RMS01';

select 'alter '||do.object_type||' ' || owner || '.'||do.object_name||' compile;'
    from dba_objects do,sys.diana_version$ dv
    where dv.obj#=do.object_id
    and do.timestamp <> to_char(dv.stime,'YYYY-MM-DD:HH24:MI:SS')    
--------------------------------------------------------------------------------------------------------------------------------
--- Recompile objects
--------------------------------------------------------------------------------------------------------------------------------
select 'alter '||decode( object_type , 'PACKAGE BODY' ,'PACKAGE' , OBJECT_TYPE) ||' '||object_name||
   decode( object_type , 'PACKAGE BODY' ,' compile body;' , ' compile;')
from dba_objects
   where object_name like '%FRECLASS%' and owner = user and object_type like '%PACKAGE%'
   order by object_type;
--------------------------------------------------------------------------------------------------------------------------------
--- Last compiled objects
--------------------------------------------------------------------------------------------------------------------------------
select * from
(SELECT * FROM user_objects ORDER BY last_ddl_time DESC)
where rownum <= 10;
--------------------------------------------------------------------------------------------------------------------------------
--- Verify session lost to QUEUE
--------------------------------------------------------------------------------------------------------------------------------
select *  from v$access where object = 'FM_FRECLASS_SQL';
--------------------------------------------------------------------------------------------------------------------------------
--- Verify DB version
--------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM v$version;
--------------------------------------------------------------------------------------------------------------------------------
--- dba registry objetos invalidos no server   -
--------------------------------------------------------------------------------------------------------------------------------
select * from dba_registry;
--------------------------------------------------------------------------------------------------------------------------------
--- Recompile DIANA
--------------------------------------------------------------------------------------------------------------------------------
select 'alter '||do.object_type||' ' || owner || '.'||do.object_name||' compile;'
from dba_objects do,sys.diana_version$ dv
where dv.obj#=do.object_id
and do.timestamp <> to_char(dv.stime,'YYYY-MM-DD:HH24:MI:SS');

--------------------------------------------------------------------------------------------------------------------------------
--- shows current statements for active sessions
--------------------------------------------------------------------------------------------------------------------------------
SELECT
    p.username pu,
    s.username su,
    s.status stat,
    s.sid ssid,
    s.serial# sser,
    substr(p.spid,1,8) spid,
    substr(sa.sql_text,1,2000) txt
FROM
    v$process p,
    v$session s,
    v$sqlarea sa
WHERE
    p.addr = s.paddr
    AND   s.username IS NOT NULL
    AND   s.sql_address = sa.address (+)
    AND   s.sql_hash_value = sa.hash_value (+)
    AND   s.status = 'ACTIVE'
ORDER BY
    1,
    2,
    7;
-------------- KILL SESSION --------------------------------------------------------------------------------------------------
SET FEEDBACK OFF
SET SERVEROUTPUT ON size unlimited 
execute dbms_output.enable(buffer_size => NULL);
SET LINESIZE 140
-- Displays list of sessions initiated by the current database user
EXECUTE kill_session.load_possible_victims;

-- Prompt for Session# to kill
PROMPT ;
ACCEPT kill_id char DEFAULT '0' PROMPT 'Enter the Kill ID of session to kill (-1 for all, 0 to exit): ';
PROMPT ;

-- Processes the value entered by the user
EXECUTE kill_session.kill_selected_victim(&kill_id);

SET FEEDBACK ON
-- end of file
-------------- LOCKED OBJECTS --------------------------------------------------------------------------------------------------
set line 190
col object_name format a20
col object_type format a15
col os_user_name format a20
col oracle_username format a20
set pagesize 50
select substr(o.object_name,1,30) object_name,
       substr(o.object_type,1,12) object_type,
       l.object_id,
       l.session_id sid,
       s.serial#,
       substr(l.oracle_username,1,20) oracle_username,
       l.os_user_name,
       s.logon_time
  from all_objects     o,
       v$locked_object  l,
       v$session        s
 where o.object_id = l.object_id
   and l.session_id = s.sid
 order by 2,1;
/
--------------------------------------------------------------------------------------------------------------------------------
-- Check your consumer group
SELECT se.sid sess_id,
       co.name consumer_group,
       se.state,
       se.consumed_cpu_time cpu_time,
       se.cpu_wait_time,
       se.queued_time
  FROM v$rsrc_session_info se, v$rsrc_consumer_group co
 WHERE se.current_consumer_group_id = co.id
   AND se.sid = sys_context('USERENV', 'SID'); 
--------------------------------------------------------------------------------------------------------------------------------  
--- QUEUE
--------------------------------------------------------------------------------------------------------------------------------
-- https://rgbusvn.us.oracle.com/svn/rgbuprod/rms/branches/se-rms-14_1_x/Cross_Pillar/install_scripts/source/create_async_queue_subscribers_force.sql
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--- DBMANIFEST
--------------------------------------------------------------------------------------------------------------------------------
--- Tables changed after last orpatch
select *
  from dba_objects 
 where object_type = 'TABLE' 
   and owner = 'RMS01'
   --and object_name = 'FM_FISCAL_DOC_DETAIL' 
   and trunc(TO_DATE(last_ddl_time, 'DD-MM-YY')) > trunc(TO_DATE('18-FEB-20', 'DD-MM-YY'));
   
select * from dba_tab_columns where table_name = 'FM_LOG_DETAIL' and owner = 'RMS01' order by column_id; --and column_name = 'REDUCED_ICMS_TAX_INFO';

select * from dbmanifest where file_name like '%Localization%' order by 5 desc;

--------------------------------------------------------------------------------------------------------------------------------
--- LOGGER_LOG
--------------------------------------------------------------------------------------------------------------------------------
begin
  logger.set_level('DEBUG');
end;
/
--------------------------------------------------------------------------------------------------------------------------------
--- DROP ALL SCHEMA OBJECTS 
--------------------------------------------------------------------------------------------------------------------------------
set serveroutput on;
begin
  for x in (select * from user_objects where object_type <> 'SYNONYM') loop
    begin
    if x.object_type = 'TYPE' THEN
       execute immediate 'drop '||x.object_type||' '||x.object_name||' force';
    else
       execute immediate 'drop '||x.object_type||' '||x.object_name;
    end if;
    exception when others then
       dbms_output.put_line('error: '||sqlerrm);
    end;
  end loop;
end;
--------------------------------------------------------------------------------------------------------------------------------
-- ORACLE QUEUE
--------------------------------------------------------------------------------------------------------------------------------
-- listar a tabela relacionada a uma fila
select t.*
  from user_queues q
     , user_queue_tables t
where q.name = upper('nb_nfe_wms_aq')
  and t.queue_table = q.queue_table
--------------------------------------------------------------------------------------------------------------------------------
-- View schemas in database
--------------------------------------------------------------------------------------------------------------------------------
select username as schema_name
from sys.all_users
order by username;
--------------------------------------------------------------------------------------------------------------------------------
--- JSON Generation 
-------------------------------------------------------------------------------------------------------------------------------
/*
https://docs.oracle.com/en/database/oracle/oracle-database/12.2/adjsn/generation.html#GUID-C0F8F837-EE36-4EDD-9261-6E8A9245906C
https://universodosdados.com/2018/12/03/os-super-poderes-das-de-transformacao/
*/
