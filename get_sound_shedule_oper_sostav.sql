CREATE OR REPLACE FUNCTION get_sound_rejs_sostav(refcursor,idshedule integer,otorder integer,doorder integer)
  RETURNS refcursor AS
$BODY$
BEGIN
open $1 for
 select b.kod_locality as kod,a.id_point
 from av_shedule_sostav a,av_spr_point b
 where a.del=0 and 
       a.id_shedule=idshedule and
       a.point_order>=otorder and
       a.point_order<=doorder and
       b.del=0 and b.id=a.id_point order by a.point_order;            
 RETURN $1;
END;
$BODY$
  LANGUAGE plpgsql;

