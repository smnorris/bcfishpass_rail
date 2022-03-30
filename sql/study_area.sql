-- define study area as all watershed groups in fraser with salmon/steelhead
-- and create a temp table holding the definition, with optimized geometry (subdivided)

create schema if not exists temp;
drop table if exists temp.rail_studyarea;

create table temp.rail_studyarea as
with studyarea as (
  select distinct
    watershed_group_code
  from bcfishpass.streams
  where 
    (wscode_ltree <@ '100'::ltree or watershed_group_code = 'LFRA') and
    (access_model_ch_co_sk is not null or access_model_st is not null)  
  order by watershed_group_code
)
select 
  row_number() over() as id, * 
from (
  select a.watershed_group_code, st_subdivide(a.geom) as geom
  from whse_basemapping.fwa_watershed_groups_poly a
  inner join studyarea b
  on a.watershed_group_code = b.watershed_group_code
) as f;

create index on temp.rail_studyarea using gist (geom);