-- define study area as all watershed groups with salmon/steelhead and railways
-- create a temp table holding the definition, with optimized geometry (subdivided)

create schema if not exists temp;
drop table if exists temp.rail_studyarea;

create table temp.rail_studyarea (id serial primary key,
watershed_group_code text ,
geom geometry(polygon, 3005));


with studyarea as (
  select distinct
    w.watershed_group_code,
    w.geom
  from bcfishpass.wsg_species_presence s
  inner join whse_basemapping.fwa_watershed_groups_poly w
  on s.watershed_group_code = w.watershed_group_code
  inner join whse_basemapping.gba_railway_tracks_sp r
  on st_intersects(w.geom, r.geom)
  where 
    s.ch is not null or
    s.cm is not null or
    s.co is not null or
    s.pk is not null or
    s.sk is not null or 
    s.st is not null
)

insert into temp.rail_studyarea (watershed_group_code, geom)
select
  watershed_group_code,
  st_subdivide(geom) as geom
from studyarea;

create index on temp.rail_studyarea using gist (geom);