-- get crossings for analysis
CREATE TABLE temp.rail_crossings AS
WITH xings AS
(
SELECT 
  c.aggregated_crossings_id, 
  c.crossing_source, 
  c.crossing_type_code,
  c.barrier_status, 
  c.stream_order,
  c.linear_feature_id,
  c.blue_line_key,
  c.downstream_route_measure,
  c.wscode_ltree, 
  c.localcode_ltree, 
  c.watershed_group_code,
  c.geom
FROM bcfishpass.crossings c
INNER JOIN temp.fraserskeena_salmon_rail sa
ON c.watershed_group_code = sa.watershed_group_code
WHERE c.rail_owner_name IS NOT NULL
),

-- amount of stream upstream
fwa_upstream AS
(
SELECT
  a.aggregated_crossings_id,
  COALESCE(ROUND((SUM(ST_Length(s.geom)::numeric) / 1000), 2), 0) AS total_network_km,
  COALESCE(ROUND(((SUM(ST_Length(s.geom)) FILTER (WHERE wb.waterbody_type = 'R' OR (wb.waterbody_type IS NULL AND s.edge_type IN (1000,1100,2000,2300)))) / 1000)::numeric, 2), 0) AS total_stream_km,
  COALESCE(ROUND(((SUM(ST_Length(s.geom)) FILTER (
    WHERE (s.gradient >= 0 AND s.gradient < .03) AND (wb.waterbody_type != 'R' OR (wb.waterbody_type IS NOT NULL AND s.edge_type NOT IN (1000,1100,2000,2300)))
  )) / 1000)::numeric, 2), 0) AS total_slopeclass03_waterbodies_km,
  COALESCE(ROUND(((SUM(ST_Length(s.geom)) FILTER (
    WHERE (s.gradient >= 0 AND s.gradient < .03) AND (wb.waterbody_type = 'R' OR (wb.waterbody_type IS NULL AND s.edge_type IN (1000,1100,2000,2300)))
  )) / 1000)::numeric, 2), 0) AS total_slopeclass03_km,
  COALESCE(ROUND(((SUM(ST_Length(s.geom)) FILTER (WHERE s.gradient >= .03 AND s.gradient < .05) / 1000))::numeric, 2), 0) as total_slopeclass05_km,
  COALESCE(ROUND(((SUM(ST_Length(s.geom)) FILTER (WHERE s.gradient >= .05 AND s.gradient < .08) / 1000))::numeric, 2), 0) as total_slopeclass08_km,
  COALESCE(ROUND(((SUM(ST_Length(s.geom)) FILTER (WHERE s.gradient >= .08 AND s.gradient < .15) / 1000))::numeric, 2), 0) as total_slopeclass15_km,
  COALESCE(ROUND(((SUM(ST_Length(s.geom)) FILTER (WHERE s.gradient >= .15 AND s.gradient < .22) / 1000))::numeric, 2), 0) as total_slopeclass22_km,
  COALESCE(ROUND(((SUM(ST_Length(s.geom)) FILTER (WHERE s.gradient >= .22 AND s.gradient < .30) / 1000))::numeric, 2), 0) as total_slopeclass30_km
FROM xings a
LEFT OUTER JOIN whse_basemapping.fwa_stream_networks_sp s
ON FWA_Upstream(
    a.blue_line_key,
    a.downstream_route_measure,
    a.wscode_ltree,
    a.localcode_ltree,
    s.blue_line_key,
    s.downstream_route_measure,
    s.wscode_ltree,
    s.localcode_ltree,
    True,
    1
   )
LEFT OUTER JOIN whse_basemapping.fwa_waterbodies wb
ON s.waterbody_key = wb.waterbody_key
GROUP BY a.aggregated_crossings_id
),


-- amount of 'potentially accessible' stream upstream (below natural barriers falls >=5m, 15% gradients etc.)
-- nope, not for tomorrow

-- n salmon observations upstream
upstr_obs AS
(SELECT 
  a.aggregated_crossings_id,
  COALESCE(COUNT(*) FILTER (WHERE o.species_code = 'AO'), 0) as n_ao,
  COALESCE(COUNT(*) FILTER (WHERE o.species_code = 'CH'), 0) as n_ch,
  COALESCE(COUNT(*) FILTER (WHERE o.species_code = 'CM'), 0) as n_cm,
  COALESCE(COUNT(*) FILTER (WHERE o.species_code = 'CO'), 0) as n_co,
  COALESCE(COUNT(*) FILTER (WHERE o.species_code = 'PK'), 0) as n_pk,
  COALESCE(COUNT(*) FILTER (WHERE o.species_code = 'SA'), 0) as n_sa,
  COALESCE(COUNT(*) FILTER (WHERE o.species_code = 'SK'), 0) as n_sk,
  COALESCE(COUNT(*) FILTER (WHERE o.species_code = 'ST'), 0) as n_st
FROM xings a
LEFT OUTER JOIN bcfishobs.fiss_fish_obsrvtn_events_sp o
ON FWA_Upstream(
    a.blue_line_key,
    a.downstream_route_measure,
    a.wscode_ltree,
    a.localcode_ltree,
    o.blue_line_key,
    o.downstream_route_measure,
    o.wscode_ltree,
    o.localcode_ltree,
    True,
    1
   )
WHERE o.species_code IN ('AO','CH','CM','CO','PK','SA','SK','ST')
GROUP BY a.aggregated_crossings_id
),

-- anthropogenic barriers upstream
upstr_barriers AS
(SELECT 
  a.aggregated_crossings_id,
  COALESCE(COUNT(*) FILTER (WHERE b.crossing_source = 'BCDAMS'), 0) as n_dams,
  COALESCE(COUNT(*) FILTER (WHERE b.crossing_source = 'BCDAMS' AND d.hydro_dam_ind = 'Y'), 0) as n_dams_hydro,
  COALESCE(COUNT(*) FILTER (WHERE b.crossing_source = 'PSCIS'), 0) as n_pscis,
  COALESCE(COUNT(*) FILTER (WHERE b.crossing_source = 'MODELLED CROSSINGS'), 0) as n_modelled_cbs
FROM xings a
LEFT OUTER JOIN bcfishpass.crossings b
ON FWA_Upstream(
    a.blue_line_key,
    a.downstream_route_measure,
    a.wscode_ltree,
    a.localcode_ltree,
    b.blue_line_key,
    b.downstream_route_measure,
    b.wscode_ltree,
    b.localcode_ltree,
    False,
    1
   )
LEFT OUTER JOIN bcfishpass.dams d ON b.dam_id = d.dam_id
WHERE b.barrier_status IN ('BARRIER', 'POTENTIAL') OR (b.barrier_status IS NULL and b.pscis_status = 'DESIGN') -- handle null barrier status designs https://github.com/smnorris/bcfishpass/issues/164
GROUP BY a.aggregated_crossings_id
),

dnstr_barriers AS 
(SELECT 
  a.aggregated_crossings_id,
  COALESCE(COUNT(*) FILTER (WHERE b.crossing_source = 'BCDAMS'), 0) as n_dams,
  COALESCE(COUNT(*) FILTER (WHERE b.crossing_source = 'BCDAMS' AND d.hydro_dam_ind = 'Y'), 0) as n_dams_hydro,
  COALESCE(COUNT(*) FILTER (WHERE b.crossing_source = 'PSCIS'), 0) as n_pscis,
  COALESCE(COUNT(*) FILTER (WHERE b.crossing_source = 'MODELLED CROSSINGS'), 0) as n_modelled_cbs
FROM xings a
LEFT OUTER JOIN bcfishpass.crossings b
ON FWA_Downstream(
    a.blue_line_key,
    a.downstream_route_measure,
    a.wscode_ltree,
    a.localcode_ltree,
    b.blue_line_key,
    b.downstream_route_measure,
    b.wscode_ltree,
    b.localcode_ltree,
    False,
    1
   )
LEFT OUTER JOIN bcfishpass.dams d ON b.dam_id = d.dam_id
WHERE b.barrier_status IN ('BARRIER', 'POTENTIAL') OR (b.barrier_status IS NULL and b.pscis_status = 'DESIGN') -- handle null barrier status designs https://github.com/smnorris/bcfishpass/issues/164
GROUP BY a.aggregated_crossings_id
)

SELECT
  a.aggregated_crossings_id, 
  a.crossing_source, 
  a.crossing_type_code,
  a.barrier_status, 
  a.stream_order,
  a.linear_feature_id,
  a.blue_line_key,
  a.downstream_route_measure,
  a.wscode_ltree, 
  a.localcode_ltree, 
  a.watershed_group_code,
  s.total_network_km,
  s.total_stream_km,
  s.total_slopeclass03_waterbodies_km,
  s.total_slopeclass03_km,
  s.total_slopeclass05_km,
  s.total_slopeclass08_km,
  s.total_slopeclass15_km,
  s.total_slopeclass22_km,
  s.total_slopeclass30_km,
  o.n_ao,
  o.n_ch,
  o.n_cm,
  o.n_co,
  o.n_pk,
  o.n_sa,
  o.n_sk,
  o.n_st,
  u.n_dams as n_dams_upstr,
  u.n_dams_hydro as n_dams_hydro_upstr,
  u.n_pscis as n_pscis_upstr,
  u.n_modelled_cbs as n_modelled_cbs_upstr,
  d.n_dams as n_dams_dnstr,
  d.n_dams_hydro as n_dams_hydro_dnstr,
  d.n_pscis as n_pscis_dnstr,
  d.n_modelled_cbs as n_modelled_cbs_dnstr,
  a.geom
FROM xings a
LEFT OUTER JOIN fwa_upstream s
ON a.aggregated_crossings_id = s.aggregated_crossings_id
LEFT OUTER JOIN upstr_obs o
ON a.aggregated_crossings_id = o.aggregated_crossings_id
LEFT OUTER JOIN upstr_barriers u
ON a.aggregated_crossings_id = u.aggregated_crossings_id
LEFT OUTER JOIN dnstr_barriers d
ON a.aggregated_crossings_id = d.aggregated_crossings_id;

-- extract all crossings above/below rail crossings

CREATE INDEX ON temp.rail_crossings (linear_feature_id);
CREATE INDEX ON temp.rail_crossings (blue_line_key);
CREATE INDEX ON temp.rail_crossings (watershed_group_code);
CREATE INDEX ON temp.rail_crossings USING GIST (wscode_ltree);
CREATE INDEX ON temp.rail_crossings USING BTREE (wscode_ltree);
CREATE INDEX ON temp.rail_crossings USING GIST (localcode_ltree);
CREATE INDEX ON temp.rail_crossings USING BTREE (localcode_ltree);
CREATE INDEX ON temp.rail_crossings USING GIST (geom);