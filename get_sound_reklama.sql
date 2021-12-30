-- Function: get_sound_rejs(refcursor, timestamp without time zone)

-- DROP FUNCTION get_sound_rejs(refcursor, timestamp without time zone);

CREATE OR REPLACE FUNCTION get_sound_rejs(refcursor, dater timestamp without time zone)
  RETURNS refcursor AS
$BODY$
Declare
  ttt timestamp;
BEGIN
ttt:=dater;
open $1 for
select * from
((select distinct on (a.createdate)
        a.createdate,
        to_char(a.createdate,'dd.mm.yyyy hh24:mi:ss.us') as createdt,
        a.id_shedule,
        a.trip_time,
        b.ot_id_point,
        (select f.kod_locality
           from av_spr_point f
          where f.del=0 and
                f.id=b.ot_id_point
        ) as ot_id_locality,
        b.do_id_point,
       (select g.kod_locality
           from av_spr_point g
          where g.del=0 and
                g.id=b.do_id_point
        ) as do_id_locality,
        case when not((b.plat-a.platform)=0) then a.platform else b.plat end as platforma,
        a.trip_flag,
        b.ot_order,
        b.do_order,
        b.ot_name,
        b.do_name,
        b.napr,
        a.id_oper
from av_disp_oper a,
      (select zz.*,
         case when zz.napr=2 then zz.t_p else zz.t_o end as trip_time
         from av_trip zz
         where zz.active=1
       ) b  
where a.createdate>ttt and
      a.trip_flag>0 and
      a.id_shedule=b.id_shedule and
      TRIM(a.trip_time)=TRIM(b.trip_time) and a.del=0 and a.id_oper IN (VALUES(1),(2),(3),(4),(8),(100)))
union all
       --Рейсы из av_trip_add -- 
select  distinct on (a.createdate)
        a.createdate,
        to_char(a.createdate,'dd.mm.yyyy hh24:mi:ss.us') as createdt,
        a.id_shedule,
        a.trip_time,
        b.ot_id_point,
        (select f.kod_locality
           from av_spr_point f
          where f.del=0 and
                f.id=b.ot_id_point
        ) as ot_id_locality,
        b.do_id_point,
       (select g.kod_locality
           from av_spr_point g
          where g.del=0 and
                g.id=b.do_id_point
        ) as do_id_locality,
        case when not((b.plat-a.platform)=0) then a.platform else b.plat end as platforma,
        a.trip_flag,
        b.ot_order,
        b.do_order,
        b.ot_name,
        b.do_name,
        1 as napr,
        a.id_oper
from av_disp_oper a,
      (select zz.*,
         case when zz.napr=2 then zz.t_p else zz.t_o end as trip_time
         from av_trip_add zz
         where zz.active=1
       ) b  
where a.createdate>ttt and
      a.trip_flag>0 and
      a.id_shedule=b.id_shedule and
      TRIM(a.trip_time)=TRIM(b.trip_time) and a.del=0 and a.id_oper IN (VALUES(1),(2),(3),(4),(8),(100))) k order by k.createdate DESC,K.TRIP_TIME ASC;       
 RETURN $1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION get_sound_rejs(refcursor, timestamp without time zone)
  OWNER TO postgres;
