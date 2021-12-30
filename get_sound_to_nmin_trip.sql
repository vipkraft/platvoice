CREATE OR REPLACE FUNCTION get_sound_to_nmin_trip(refcursor, dater date, iduser integer)
  RETURNS refcursor AS
$BODY$
BEGIN
 --функция возвращает список регулярных и заказных рейсов с выясненным календарным планом, наличием договора и лицензии 
 -- dater - дата когда хотим уехать
 -- iduser - пользователь, выполняющий операцию
open $1 for
SELECT *,
   dog * lic * wihod * active * (Case WHEN (dates+1)>dater THEN 0 ELSE 1 END) * (Case WHEN datepo<(dater+1) THEN 0 ELSE 1 END) as edet,
   (dog * lic) as dog_lic,
   CASE WHEN dog>0 THEN 1 ELSE 0 END dog_flag,
   CASE WHEN lic>0 THEN 1 ELSE 0 END lic_flag,
   CASE WHEN id_kontr>0 THEN 1 ELSE 0 END kontr_flag,
   CASE WHEN id_ats>0 THEN 1 ELSE 0 END ats_flag,
    (select f.kod_locality
            from av_spr_point f
           where f.del=0 and
                 f.id=k.ot_id_point
         ) as ot_id_locality,
        (select g.kod_locality
            from av_spr_point g
           where g.del=0 and
                 g.id=k.do_id_point
         ) as do_id_locality   
 FROM 
 --av_spr_point s1,av_spr_locality s2,
   (
-- Берем рейсы регулярные (av_trip)
select a.id_shedule,a.plat,a.active,a.dateactive,a.dates,a.datepo,a.ot_id_point,a.ot_order,a.ot_name,
  a.do_id_point,a.do_order,a.do_name,a.form,a.t_o,a.t_s,a.t_p,a.zakaz,a.date_tarif,a.id_route,a.napr
        ,COALESCE(z.id_kontr,'0') as id_kontr,
         z.name_kontr as name_kontr,
         COALESCE(z.id_ats,'0') as id_ats,
         z.name_ats as name_ats,
         z.type_ats as type_ats,
         z.all_mest as all_mest,       
         --Определяем наличие договора и лицензии
        (select count(w.*)
        from av_trip_dog_lic w
        where w.id_kontr=z.id_kontr and
              w.type_date=1 and
              (dater>=w.dates and dater<=w.datepo)
        ) dog,
       (select count(e.*)
        from av_trip_dog_lic e
        where e.id_kontr=z.id_kontr and
              e.type_date=2 and
              dater>=e.dates and dater<=e.datepo
        ) lic
       ,COALESCE(z.wihod,'0') wihod              
       
  from av_trip a
  --Определяем признак выхода по календарному плану
  LEFT JOIN (select distinct on (id_shedule) * from
(select b.*,CASE WHEN (SELECT getsezon(b.sezon,a.dateactive,dater))=true THEN 1 ELSE 0 END as wihod from av_trip a,
av_trip_atp_ats b WHERE b.id_shedule=a.id_shedule) c WHERE c.wihod=1) z ON z.id_shedule=a.id_shedule
 --Проверка на запрет пользователю получать результаты функции 
  WHERE iduser not in (select p.id_user from av_shedule_denyuser p where p.del=0 and p.id_shedule=a.id_shedule) 
-- и объединяем со списком заказных рейсов (av_trip_add)
union all            
  select a.id_shedule,a.plat,a.active,a.dateactive,a.dates,a.datepo,a.ot_id_point,a.ot_order,a.ot_name,
  a.do_id_point,a.do_order,a.do_name,a.form,a.t_o,a.t_s,a.t_p,a.zakaz,a.date_tarif,a.id_route,a.napr,
                      0 as id_kontr,
                      '' as name_kontr,
                      0 as id_ats,
                      '' as name_ats,
                      1 as type_ats,
                      0 as all_mest,                      
                      1 as dog,
                      1 as lic,
                      1 as wihod
                from av_trip_add a
                where a.date_trip=dater
               order by t_o

               ) as k; 
         

RETURN $1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION shedule_status(refcursor, date, integer)
  OWNER TO postgres;
