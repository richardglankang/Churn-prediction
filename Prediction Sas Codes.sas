libname churn "C:\Users\ys314\Desktop\Churn";

/************************* Exploratory analysis *******************************/
proc import out=churn.customer_churn
datafile="C:\Users\ys314\Desktop\Churn\WA_Fn-UseC_-Telco-Customer-Churn.csv"
dbms=csv replace;
run;


ods rtf file="C:\Users\ys314\Desktop\Churn" style =analysis;

proc sgplot data=churn.customer_churn pctlevel=group;
vbar churn / stat=percent missing datalabel;
label Embarked = "Overall Churn Rate";
title "Churn Percent";
run;


PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR gender/ group = churn stat=percent missing ;
 TITLE 'Churn vs Gender';
RUN; 

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR SeniorCitizen/ group = churn stat=percent missing ;
 TITLE 'Churn vs SeniorCitizen';
RUN; 

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR Partner/ group = churn stat=percent missing ;
 TITLE 'Churn vs Partner';
RUN; 

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR Dependents/ group = churn stat=percent missing ;
 TITLE 'Churn vs Dependents';
RUN; 

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR PhoneService/ group = churn stat=percent missing ;
 TITLE 'Churn vs Multiplelines';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR MultipleLines/ group = churn stat=percent missing ;
 TITLE 'Churn vs Multiplelines';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR InternetService/ group = churn stat=percent missing ;
 TITLE 'Churn vs InternetService';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR OnlineSecurity/ group = churn stat=percent missing ;
 TITLE 'Churn vs OnlineSecurity';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR OnlineBackup/ group = churn stat=percent missing ;
 TITLE 'Churn vs OnlineBackup';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR DeviceProtection/ group = churn stat=percent missing ;
 TITLE 'Churn vs DeviceProtection';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR TechSupport/ group = churn stat=percent missing ;
 TITLE 'Churn vs TechSupport';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR StreamingTV/ group = churn stat=percent missing ;
 TITLE 'Churn vs StreamingTV';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR Contract/ group = churn stat=percent missing ;
 TITLE 'Churn vs Contract';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR PaperlessBilling/ group = churn stat=percent missing ;
 TITLE 'Churn vs PaperlessBilling';
RUN;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR PaymentMethod/ group = churn stat=percent missing ;
 TITLE 'Churn vs PaymentMethod';
RUN;


proc sgplot data= churn.customer_churn;
vbox tenure/ category=churn group=churn attrid=myid;
title 'Churn vs Tenure';
run;
 
proc sgplot data= churn.customer_churn;
vbox MonthlyCharges/ category=churn group=churn attrid=myid;
title 'Churn vs MonthlyCharges';
run;

proc sgplot data= churn.customer_churn;
vbox TotalCharges/ category=churn group=churn attrid=myid;
title 'Churn vs TotalCharges';
run;

PROC SGPLOT DATA = churn.customer_churn pctlevel = group;
 VBAR SeniorCitizen/ group = Partner stat=percent missing ;
 TITLE 'SeniorCitizen vs Partner';
RUN; 
ods rtf close;


/************************* Cusomer Segmentation with k-means clustering *************************/
/*import data */
proc import datafile= "C:\Users\ys314\Desktop\Churn\train3.csv"
out = churn.train
dbms = csv 
replace;
run;

proc import datafile= "C:\Users\ys314\Desktop\Churn\test3.csv"
out = churn.test
dbms = csv 
replace;
run;

/* combining training and test set*/
proc sql;
	create table churn.master as select * from churn.train union all select * 
		from churn.test;
quit;

/*scaling */
proc stdize data=churn.master out=churn.for_cluster method=RANGE;
   var MonthlyCharges TotalCharges tenure;
run;

/* try k = 2 to 6 */
%macro doFASTCLUS;
	%do k=2 %to 6;

		proc fastclus data=churn.for_cluster radius=0 replace=full maxclusters=&k
			out=churn.new_cluster&k;
			var MonthlyCharges TotalCharges tenure SeniorCitizen partner dependents;
		run;

		proc means data=churn.new_cluster&k;
			Class cluster;
			var churn MonthlyCharges TotalCharges tenure SeniorCitizen partner dependents;
			output out=churn.testtemp MEAN=m;
		run;

	%end;
%mend;

%doFASTCLUS;

/************************* Logistic Regression for Churn Prediction  *************************/
/****** log transformation& create new variables******/
data x1;
set churn.train;
ln_tenure = log(tenure);
ln_tot_charge = log(totalcharges);
ln_mon_charge = log(monthlycharges);
totalcharge_tenure = totalcharges*tenure;
fiber_tenure = InternetService_Fiber_optic*tenure;
tv_tenure = StreamingTV_Yes*tenure;
paperless_tenure = paperlessbilling*tenure;
extra_service_count = StreamingTV_Yes + StreamingMovies_Yes + onlinesecurity_yes + onlinebackup_yes + deviceprotection_yes ;
run;

data x2;
set churn.test;
ln_tenure = log(tenure);
ln_tot_charge = log(totalcharges);
ln_mon_charge = log(monthlycharges);
totalcharge_tenure = totalcharges*tenure;
fiber_tenure = InternetService_Fiber_optic*tenure;
tv_tenure = StreamingTV_Yes*tenure;
paperless_tenure = paperlessbilling*tenure;
extra_service_count = StreamingTV_Yes + StreamingMovies_Yes + onlinesecurity_yes + onlinebackup_yes + deviceprotection_yes ;
run;

ods rtf file="C:C:\Users\ys314\Desktop\churn_models.rtf"
style =analysis;
/* model one - demographic data only */
proc logistic data=x1 descending plots(only)=roc;
model Churn = seniorcitizen partner dependents;
run;
/* model two - demographic data  + account info */
proc logistic data=x1 descending plots(only)=roc;
model Churn = seniorcitizen paperlessbilling InternetService_Fiber_optic InternetService_No TechSupport_Yes StreamingTV_Yes StreamingMovies_Yes PaymentMethod_electronic_check;
run;
/* model two - demographic data  + account info + subscription info */
proc logistic data=x1 descending plots(only)=roc;
model Churn = seniorcitizen tenure paperlessbilling totalcharges InternetService_Fiber_optic InternetService_No TechSupport_Yes StreamingTV_Yes StreamingMovies_Yes Contract_One_year Contract_Two_year PaymentMethod_electronic_check;
run;
ods pdf close;

/* out of sample evaluation - scoring & confustion matrix*/
proc logistic data=x1 descending plots(only)=roc;
model Churn = seniorcitizen partner dependents;
score data=x2 out=pred_1;
run;
data pred_1; set pred_1;
if P_1 le 0.5 then churn_predict=0; else churn_predict=1;
run;
proc freq data=pred_1;
tables churn*churn_predict;
run;

proc logistic data=x1 descending plots(only)=roc;
model Churn = seniorcitizen tenure paperlessbilling totalcharges InternetService_Fiber_optic InternetService_No TechSupport_Yes StreamingTV_Yes StreamingMovies_Yes Contract_One_year Contract_Two_year PaymentMethod_electronic_check; 
score data=x2 out=pred_2;
run;
data pred_2; set pred_2;
if P_1 le 0.5 then churn_predict=0; else churn_predict=1;
run;
proc freq data=pred_2;
tables churn*churn_predict;
run;


