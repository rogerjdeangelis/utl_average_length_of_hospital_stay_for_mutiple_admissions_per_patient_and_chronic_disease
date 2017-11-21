Average length of hospital stay for mutiple admissions per patient and chronic disease;

Two Solutions

see
https://communities.sas.com/t5/SAS-Procedures/Count-number-of-events-in-longitudinal-data/m-p/414990#M67549


INPUT
=====

Up to 40 obs WORK.HAVE total obs=22    |               RULES FOR EVENT1                      RESULT
                                       |  ==========================================  =============================
 STUDY_ID  EVENT1  EVENT2  VISITDATE   |  EVENT1     VISITDAT                         EVENTNO    STUDY_ID   AVE_DUR
                                       |
   1001       0       1      20820     |     0         20820                             1         1001       20.0
   1001       0       1      20836     |     0         20836                             1         1002       11.0
   1001       1       0      20862     |     1 -+      20862                             1         1003       39.5 *
   1001       1       0      20876     |     1  |      20876
   1001       1       0      20882     |     1  |      20882  20882-20862 = 20 days         * average of two stays
   1001       0       0      20896     |     0 -+      20896
                                       |
   1002       0       0      20820     |     0         20820
   1002       1       0      20838     |     1 -+      20838
   1002       1       0      20849     |     1 -+      20849  20849-20820 = 11 days
   1002       0       1      20857     |     0         20857
   1002       0       1      20869     |     0         20869
   1002       0       1      20882     |     0         20882
                                       |
   1003       1       0      20820     |     1 -+      20820
   1003       1       0      20841     |     1  |      20841
   1003       1       0      20860     |     1 -+      20860 20860-20820  = 40 days
   1003       0       0      20872     |     0         20872
   1003       0       1      20881     |     0         20881
   1003       1       1      20897     |     1 -+      20897
   1003       1       1      20911     |     1  |      20911
   1003       1       0      20918     |     1  |      20918
   1003       1       1      20936     |     1 -+      20936 20936-20897  = 21 days
   1003       0       1      20947     |     0         20947            (39+40)/2 = 39.5

SOLUTION 1
==========

   * proc transpose does not support multiple variables;
   %utl_gather(have,event,stay,study_id visitdate,havskn,valformat=6.);

   proc sort data=havskn out=havsrt;
    by event study_id visitdate;
   run;quit;

   data havdur;
     retain cnt 0 beg .;
     set havsrt;
     by study_id event stay notsorted;
     if first.stay and stay=1 then beg=visitdate;
     if last.stay and stay=1 then do;
          dur=visitdate-beg;
          output;
     end;
   run;quit;

   proc summary data=havdur mean nway;
   class event study_id;
   var dur;
   output out=want(drop=_type_) mean=average_stay;
   run;quit;

SOLUTION 2
==========
   data events;
   set have(rename=event1=event) have(rename=event2=event in=in2);
   eventNo = 1 + in2;
   drop event1 event2;
   run;

   data want;
   tot_dur = 0;
   do until(last.study_id);
       lastVisit = visitDate;
       set events; by eventNo study_id;
       if in then
           if event then
               if lastVisit > 0 then
                   tot_dur = sum(tot_dur, intck("day", lastVisit, visitDate));
               else;
           else in = 0;
       else
           if event then do;
               in = 1;
               count = sum(count, 1);
               end;
       end;
   if count > 0 then ave_dur = tot_dur / count;
   keep eventNo study_id tot_dur count ave_dur;
   run;

OUTPUT
======

 WORK.WANT total obs=6

                                          AVERAGE_
   Obs    EVENT     STUDY_ID    _FREQ_      STAY

    1     EVENT1      1001         1        20.0
    2     EVENT1      1002         1        11.0
    3     EVENT1      1003         2        39.5

    4     EVENT2      1001         1        16.0
    5     EVENT2      1002         1        25.0
    6     EVENT2      1003         2        20.5


