CREATE OR REPLACE FUNCTION get_sound_rejs_do5minut(refcursor)
  RETURNS refcursor AS
$BODY$
BEGIN
open $1 for
select a.id_shedule,
       a.t_o as trip_time,
       ((current_time - time without time zone '00:05'  )) as ttt1,
       (current_time) as ttt2,
       (a.t_o::time without time zone) as ttt_0
  from av_trip a
  where a.napr=1 and
        current_time::time >= (a.t_o::time - time without time zone '00:05'  ) and 
        current_time::time<(a.t_o::time-time without time zone '00:02');

RETURN $1;
END;
$BODY$
  LANGUAGE plpgsql;