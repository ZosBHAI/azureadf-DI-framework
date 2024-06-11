SELECT *
  FROM [controlTable].[TestMetadataControlTable]
  where  sourceName = 'source1';


delete from  [controlTable].[TestMetadataControlTable]
where sourceName = 'source1' and TableName = 'not_project_table';

select * from dbo.project_table_incr;



delete from  dbo.project_table_incr
where concat(Project,'|',CreationTime) IN (
select concat(Project,'|',CreationTime)  from(
Select Project,CreationTime,
ROW_NUMBER() Over (PARTITION By Project
ORDER By CreationTime desc ) as rk 
from dbo.project_table_incr ) a 
where rk >1
);
select * from [controlTable].[TestPipelineRun];
delete from [controlTable].[TestPipelineRun];
select FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')

insert into dbo.project_table_incr(Project,Creationtime)
values ('project300',FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss'))
update dbo.project_table_incr
set Creationtime = FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')
where Project = 'project90';

drop table dest_dbo.dbo_project_table;
drop table dest_dbo.dbo_project_table_incr;

select * from dest_dbo.dbo_project_table_incr;