%let date=APRIL,2020;
%put &date;
/*%put is used to display the value in log wd*/
Title "xyz &date vvv";
proc print data=sashelp.class (obs=4);
run;

%let c=&sysdate;
%put &c;
Title "xyz &c vvv";
proc print data=sashelp.class (obs=4);
run;

proc import file="C:\Users\Nikita\Downloads\Demographic Data.xlsx"
out=Danalysis dbms=xlsx 
replace;
getnames=yes;
run;

data Danalysis;
set Danalysis;
output;
Treatment="Total";
output;
run;
ods trace on;
proc freq data=Danalysis;
table Gender*Treatment / norow nopercent;
ods output  CrossTabFreqs=ainput;
/*(keep=Gender Treatment Frequency ColPercent);*/
run;
ods trace off;
data G_total(keep=Gender Treatment   count_p);
length Gender Treatment count_p $30.;
set ainput;
where (Gender= "Male" or Gender="Female") and (Treatment="Group 1" or Treatment="Group 2" or Treatment="Total" );
count_p=cats(Frequency,"(",ColPercent,")");
run;
proc transpose data=G_total out=G_total1(drop=_NAME_);
by Gender;
var count_p;
id Treatment;run;

data Gender(drop=Gender);
length  Parameter  Statistics $30.;
set G_total1;
if (Gender="Female" or Gender="Male") then Statistics="n(%)";
if Gender="Female" then Parameter="^{style^{NBSPACE 5}}Female";
else Parameter="*{style*{NBSPACE 5}}Male";
run;

data Gender1;
infile cards missover;
input Parameter $30. Statistics $30. Group_1 $30. Group_2 $30. Total $30.  ;
cards;
Gender
;run;
data G_col;
set Gender1
 Gender;run;
data dummy;
length bl $30.;
bl='';run;


data input (rename= (Age1 = Age Weight1 = Weight  Height1 = Height));
set Danalysis;
length Height1 8.  Weight1 8. ;
Age1=input(Age ,2.);
Weight1=input(Weight , 3.);
Height1=input(Height,3.);
drop Age Weight Height;
run;
ods trace on;
option symbolgen;
%macro xyz (var,out1,out2,out3,out4,out5,out6);

proc means data=input  N mean  stdDev Q1 median Q3 min max  maxdec=1;
var  &var ;
class Treatment ;
output out=&out1 N=_n mean=_mean stdDev=_std Q1=_q1 median=_q2 
       Q3=_q3 min=_min max=_max ;
run; 
data &out2 (Keep=Treatment n mean_sd q1q2q3 minmax  );
length Treatment n mean_sd q1q2q3 minmax $30. ;
set &out1; 
mean_sd=strip(put(_Mean,4.2)) ||" ("||put(_std,4.2)||")" ; 
Q1Q2Q3=strip(put(_q1,3.1))||"," || put(_q2,3.1)||","||put(_q3,3.1);
n=strip(put(_n,3.));
Minmax=cats(put(_Min,3.1),",",put(_Max,3.1));
run;
data &out3;
set &out2;
if Treatment="" then Treatment="Total";
run;
proc sort data=&out3 out=&out4;
by treatment;run;

proc transpose data=&out4 out=&out5;
id Treatment;
var n mean_sd q1q2q3 minmax;
run;
data &out6;
length Para  Parameter  Statistics $30.;
set &out5;
if _NAME_="n" then Para="&var";
if Para="Age" then Parameter="Age (Yrs)";
else if Para="Height" then Parameter="Height (cm)";
else if Para="weight" then Parameter="Weight (Kg)";
else if Para="BMI" then Parameter="BMI";
else Parameter="";
if _NAME_="mean_sd" then Statistics="Mean(SD)";
else if _NAME_="q1q2q3" then Statistics="Q1,Q2,Q3";
else if _NAME_="minmax" then Statistics="Min,Max";
else Statistics="n";
run;
%mend xyz;
%xyz(Age,Age2,age3,age4,a5,a6,a7);
%xyz(Height,h2,h3,h4,h5,h6,h7);
%xyz(weight,w2,w3,w4,w5,w6,w7);
%xyz(BMI,b2,b3,b4,b5,b6,b7);
data xyz(drop=_NAME_ Para bl);
set  G_col dummy a7  dummy h7 dummy w7 dummy b7;
run;
options nodate nonumber papersize=(15 15) orientation=landscape;
ods pdf file="C:\Users\Nikita\Desktop\Pharma_stats\sas_demo_mock2.pdf"
style=sasweb;
proc report data=xyz split="*";
define Group_1/"Group 1 * N=20";
define Group_2/"Grou p 2 * N=20";
define Total/"Total * N=40";
compute after _page_/style=[just=left font_weight=MEDIUM] ;
line 'n :No. of nonmissing Observations';
line 'SD : Standard Devation';
line 'Q1,Q2,Q3 : 1st Quartile, Median, 3rd Quartile';
line 'Min,Max : Minimum,Maximum';
endcomp;
run;
proc print data=xyz noobs;
title4 'Table 1.1 : Demographic Table';
run;
ods pdf close;


