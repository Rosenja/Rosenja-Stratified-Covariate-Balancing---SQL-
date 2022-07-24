/****** Script for SelectTopNRows command from SSMS  ******/

USE HAP823
GO

/*
LOS For Dr.Smith

Visually show that Dr. Smith see a different set of patients than his peer group. 
Show a tree where the nodes are the diagnoses, the consequences are length of stay within the tree branch, and each branch is drawn proportional to the expected length of stay.
Balance the data through stratified covariate balancing. 

Switch the tree structure of peer group (but not the length of stay) with Dr. Smith's tree.
Report the unconfounded impact of Dr. Smith on length of stay using the common odds ratio of having above average length of stay.


Using SQL, group the diagnoses into commonly occurring strata.
Within each strata, calculate the odds of mortality from cancer.
Calculate the common odds ratio across strata.

*/

SELECT CAST(Hypertension as int) as Hypertension
,CAST(Anemia as int) as Anemia 
,CAST(Diabetes as int) as Diabetes 
,CAST(HIV as int) as HIV 
,CAST([Stomach Cancer] as int) as Stomach_Cancer 
,CAST([Lung Cancer] as int) as Lung_Cancer 
,CAST([Myocardial Infarction] as int) as Myocardial_Infarction 
,CAST([Heart Failure] as int) as Heart_Failure 
,CAST([Metastetic Cancer] as int) as Metastetic_Cancer 
,CAST([Cared for by Dr Smith] as int) as Cared_for_by_Dr_Smith
,CAST(LOS as int) as LOS INTO #TeachOne  
FROM [HAP823].[dbo].[dsmith]

select * from #TeachOne
drop table #TeachOne


--Branch 1: HF and Metastatic Cancer LOS
SELECT (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END) as Physician,
SUM(LOS) as HF_MC_LOS
FROM #TeachOne
WHERE Heart_Failure  = 1 AND Metastetic_Cancer = 1
GROUP BY (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END)
ORDER BY (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END)

--DrSmith - 2787
--OtherDoctor - 2499

--Branch 2: HF and no Metastatic Cancer LOS
f
SELECT (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END) as Physician,
SUM(LOS) as HF_NOMC_LOS
FROM #TeachOne
WHERE Heart_Failure  = 1 AND Metastetic_Cancer = 0
GROUP BY (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END)
ORDER BY (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END)

--DrSmith - 2529
--OtherDoctor - 2529

--Branch 3: No HF and Metastatic Cancer LOS

SELECT (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END) as Physician,
SUM(LOS) as HF_NOMC_LOS
FROM #TeachOne
WHERE Heart_Failure  = 0 AND Metastetic_Cancer = 1
GROUP BY (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END)
ORDER BY (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END)

--DrSmith - 2627
--OtherDoctor - 2627

--Branch 3: No HF and No Metastatic Cancer LOS

SELECT (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END) as Physician,
SUM(LOS) as HF_NOMC_LOS
FROM #TeachOne
WHERE Heart_Failure  = 0 AND Metastetic_Cancer = 0
GROUP BY (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END)
ORDER BY (case when Cared_for_by_Dr_Smith =1 then 'DrSmith' Else 'OtherDoctor' END)

--DrSmith - 7622
--OtherDoctor - 2906

--Q1.2 balancing the data
--drop table #cases

select count(los) as nCases
	  ,sum(IFF([LOS] = 3.00, 1.,0.)) AS a
	  ,COUNT(Cased_for_by_Dr_Smith)-SUM(IFF(LOS = 3.99, 1.,0.)) AS b
	  ,Hypertension, Anemia, [Diabetes], [HIV], Stomach_Cancer, Lung_Cancer
	  ,Myocardial_Infarction, Heart_Failure, Metastetic_Cancer
INTO #Cases
FROM #TeachOne
WHERE Cared_for_by_Dr_Smith = 1
GROUP BY Hypertension, Anemia, [Diabetes], [HIV], Stomach_Cancer, Lung_Cancer
	     ,Myocardial_Infarction, Heart_Failure, Metastetic_Cancer

--512 rows


--Controls: patient is cared for by Peers
--drop table #Controls

select count(los) as nCases
	  ,sum(IFF([LOS] = 3.00, 1.,0.)) AS a
	  ,COUNT(Cased_for_by_Dr_Smith)-SUM(IFF(LOS = 3.99, 1.,0.)) AS b
	  ,Hypertension, Anemia, [Diabetes], [HIV], Stomach_Cancer, Lung_Cancer
	  ,Myocardial_Infarction, Heart_Failure, Metastetic_Cancer
INTO #Controls 
FROM #TeachOne
WHERE Cared_for_by_Dr_Smith = 0
GROUP BY Hypertension, Anemia, [Diabetes], [HIV], Stomach_Cancer, Lung_Cancer
	     ,Myocardial_Infarction, Heart_Failure, Metastetic_Cancer

--512 rows


select * from #Cases
select * from #Controls 




-- Match cases with controls and calculate common odds ratio 
SELECT sum(a*d/(a+b+c+d))/sum(b*c/(a+b+c+d)) As [Common Odds]
FROM #Cases inner join #Controls on 
#Cases.[Hypertension] =#Controls.[Hypertension]
and #Cases.[anemia] = #Controls.[Anemia]
and #Cases.[Diabetes]= #Controls.[Diabetes]
and #Cases.[HIV]= #Controls.[HIV]
and #Cases.[Stomach Cancer]= #Controls.[Stomach Cancer]
and #Cases.[Lung Cancer]= #Controls.[Lung Cancer]
and #Cases.[Myocardial Infarction]= #Controls.[Myocardial Infarction]
and #Cases.[Heart Failure]= #Controls.[Heart Failure]
and #Cases.[Metastetic Cancer]= #Controls.[Metastetic Cancer]


/****** Bench-marking Dr. Smith Weighted LOS ******/

USE Benchmarking -- Name of your database is likely to be different
DROP TABLE  #Cases, #Controls -- Drop temporary files if they already exist

-- Cases: patient is cared for by Dr Smith
SELECT SUM([Cared for by Dr Smith]) AS nCases -- # patients seen by Dr. Smith
      , Avg(LOS) AS casesLOS  -- Average LOS for Dr. Smith patients 
      , [Hypertension],[Anemia],[Diabetes], [HIV],[Stomach Cancer],[Lung Cancer],[Myocardial Infarction],[Heart Failure],[Metastetic Cancer]
INTO #Cases  -- Save in temporary file called Cases
FROM [dbo].[Data2$]  -- Name of your table may be different
WHERE [Cared for by Dr Smith] = 1 -- Only patients care for by Dr. Smith
GROUP BY  -- Create strata as combinations of the 10 diseases
      [Hypertension],[Anemia],[Diabetes],[HIV],[Stomach Cancer],[Lung Cancer],[Myocardial Infarction],[Heart Failure],[Metastetic Cancer]
-- (512 row(s) affected)    

   
--Controls: patients seen by peer group
SELECT Sum(1.-[Cared for by Dr Smith]) AS nControls -- Patients seen by peer 
       , Avg([LOS]) AS ControlsLOS  -- Average lengh of stay for peer group
       , [Hypertension],[Anemia],[Diabetes], [HIV],[Stomach Cancer]
	,[Lung Cancer],[Myocardial Infarction],[Heart Failure]
	,[Metastetic Cancer]
INTO #Controls  -- Save in temporary file called Controls
FROM [dbo].[Data2$]  -- Name of your table may be different
WHERE [Cared for by Dr Smith] = 0 -- Patients cared for by peer group
GROUP BY  -- Create strata as combinations of the 10 diseases
      [Hypertension],[Anemia],[Diabetes],[HIV],[Stomach Cancer]
	,[Lung Cancer],[Myocardial Infarction],[Heart Failure]
	,[Metastetic Cancer]
-- (512 row(s) affected)  

-- Match cases with controls and calculate common odds ratio 
DROP TABLE #Match
SELECT CAST(nCases as float)/Cast(nControls as Float) As [Weight]
	, nCases, nControls, casesLOS, controlsLOS,	#Cases.Hypertension, #Cases.Anemia, #Cases.Diabetes
	, #Cases.HIV, #Cases.[Stomach Cancer], #Cases.[Lung Cancer],#Cases.[Myocardial Infarction], #Cases.[Heart Failure], #Cases.[Metastetic Cancer]
INTO #Match
FROM #Cases inner join #Controls on 
	#Cases.[Hypertension] =#Controls.[Hypertension]
	and #Cases.[anemia] = #Controls.[Anemia]
	and #Cases.[Diabetes]= #Controls.[Diabetes]
	and #Cases.[HIV]= #Controls.[HIV]
	and #Cases.[Stomach Cancer]= #Controls.[Stomach Cancer]
	and #Cases.[Lung Cancer]= #Controls.[Lung Cancer]
	and #Cases.[Myocardial Infarction]= #Controls.[Myocardial Infarction]
	and #Cases.[Heart Failure]= #Controls.[Heart Failure]
	and #Cases.[Metastetic Cancer]= #Controls.[Metastetic Cancer]
-- (512 row(s) affected)

-- Average impact of Dr. Smith & peer group after balance
SELECT CASE WHEN [Cared for by Dr Smith]=1 THEN 'Dr Smith' ELSE 'Peer Group' END As [Cared for by]
	, Round(Avg((CASE WHEN [Cared for by Dr Smith]=1 THEN 1. 
			WHEN [Cared for by Dr Smith]=0 THEN [Weight] ELSE Null End)* LOS),2) As [Average LOS]
FROM [dbo].[Data2$] a left join #match b on 
	a.[Hypertension] =b.[Hypertension]
	and a.[anemia] = b.[Anemia]
	and a.[Diabetes]= b.[Diabetes]
	and a.[HIV]= b.[HIV]
	and a.[Stomach Cancer]= b.[Stomach Cancer]
	and a.[Lung Cancer]= b.[Lung Cancer]
	and a.[Myocardial Infarction]= b.[Myocardial Infarction]
	and a.[Heart Failure]= b.[Heart Failure]
	and a.[Metastetic Cancer]= b.[Metastetic Cancer]
GROUP BY [Cared for by Dr Smith]

/*
Cared for by	Average LOS
Peer Group		5.97
Dr Smith		3.88
*/


/*
END Question 1
*/



/*
Question 2
*/


SELECT ([Column 0])as ID
       ,cast([Cancer] as int)as CA
       ,[I305 1]
       ,[I309 81]
	   ,[I311 ]
	   ,[IE849 7]
	   ,[I150 9]
	   ,[I276 1]
	   ,[I276 8]
	   ,[I530 81]
	   ,[I263 9]
	   ,[I276 51]
	   ,[IV15 82]
	   ,[I511 9]
	   ,[I401 9]
	   ,[I787 20]
	   ,[I564 00]
	   ,[I272 4]
	   ,[I280 9]
	   ,[I285 9]
	   ,[I496 ]
	   ,[I458 9]
	   ,[I486 ]
	   ,[IV58 61]
	   ,[I197 7]
	   ,[I578 9]
	   ,[I584 9]
	   ,[IV66 7]
	   ,[I244 9]
	   ,[I414 01]
	   ,[I599 0]
	   ,[I414 00]
	   ,[I585 9]
	   ,[I600 00]
	   ,[I428 0]
	   ,[I427 31]
       ,[I403 90]
	   ,cast([Dead] as int) as Dead
	   into stoamch_cancer1 FROM [Stratified_covariate].[dbo].[StomachCancer]-----(100000 rows affected)

Select ID,CA,[I305 1]+[I309 81]+[I311 ]+[IE849 7]+[I150 9]+[I276 1] +[I276 8] +[I530 81]+[I263 9]
      +[I276 51]+[IV15 82]+[I511 9]+[I401 9]+[I787 20]+[I564 00]+[I272 4]+[I280 9]+[I285 9]
   +[I496 ]+[I458 9]+[I486 ]+[IV58 61]+[I197 7]+[I578 9]+[I584 9]+[IV66 7]+[I414 01]
   +[I599 0] +[I414 00]  +[I585 9]+[I600 00] +[I428 0]+[I403 90] as strata,Dead
Into #temp1
FROM stoamch_cancer1

select * from #temp1

--CASES
---drop table #cases
SELECT COUNT(distinct [ID]) AS nCases -- Number of residents unable to eat
, Sum(IIF([Dead] = 1, 1., 0.)) AS a 
, SUM(IIF([Dead] = 0, 1., 0.)) AS b 
, strata
INTO #Cases -- Save in temporary file called Cases
FROM #temp1  
WHERE [CA] = 1 -- Select only residents who were unable to eat
GROUP BY strata -------(176 rows affected)

--CONTROLS
--drop table #controls
SELECT COUNT(distinct [ID]) AS nControls -- Number of residents unable to eat
, Sum(IIF([Dead] = 1, 1., 0.)) AS c 
, SUM(IIF([Dead] = 0, 1., 0.)) AS d
, strata
INTO #Controls -- Save in temporary file called Cases
FROM #temp1  
WHERE [CA] = 0 -- Select only residents who were unable to eat
GROUP BY strata-------(23823 rows affected)

SELECT #cases.*,ncontrols,c,d 
FROM #Cases inner join #Controls 
ON  #cases.strata=#Controls.strata

-----CALCULATING ODDS RATIO
select sum(a*d/(a+b+c+d))/sum(b*c/(a+b+c+d)) As [Common Odds Ratio]
FROM #Cases inner join #Controls 
ON  #cases.strata=#Controls.strata

select 
(a+1)/(b+1) as Odds, *
 from #Cases

---Calculate the common odds ratio across strata. 
Declare @TotalCases Float
Set @TotalCases = (Select Count ([Dead]) from #temp1 Where [CA] =1)


 SELECT sum(cast((a*d)/(a+b+c+d)as float))/sum(cast((b*c)/(a+b+c+d)as float)) As [Common Odds]
,sum (cast((a+b)/(c+d)as float)) As WeightControl
,sum(Cast(a+b As Float))/ @TotalCases As Overlap

INTO #Match 
FROM #Cases inner join #Controls on
#Cases.strata =#Controls.strata

select * from #Match


Drop table #Cases
SELECT COUNT(distinct ID) AS nCases
, Sum(IIF([Dead] = 1, 1., 0.)) AS a 
, SUM(IIF([Dead] = 0, 1., 0.)) AS b 
,[I305 1], [I309 81]
, [IE849 7], [I150 9], [I530 81], [I263 9]
, [I787 20], [I272 4], [I280 9], [I486 ]
, [I578 9], [I584 9]
, [I585 9], [I427 31], [I403 90]
INTO #Cases
FROM stoamch_cancer1 
WHERE [CA] = 1
GROUP BY  [I305 1], [I309 81]
, [IE849 7], [I150 9], [I530 81], [I263 9]
, [I787 20], [I272 4], [I280 9], [I486 ]
, [I578 9], [I584 9]
, [I585 9], [I427 31], [I403 90]-------(95 rows affected)

--- Grouping Controls that have NO Cancer by the conditions & separating dead to column A & B
Drop table #Controls 
SELECT COUNT(distinct [ID]) AS nControls
, Sum(IIF([Dead] = 1, 1., 0.)) AS c
, SUM(IIF([Dead] = 0, 1., 0.)) AS d
, [I305 1], [I309 81]
, [IE849 7], [I150 9], [I530 81], [I263 9]
, [I787 20], [I272 4], [I280 9], [I486 ]
, [I578 9], [I584 9]
, [I585 9], [I427 31], [I403 90]
INTO #Controls
FROM stoamch_cancer1 
WHERE [CA] = 0
GROUP BY  [I305 1], [I309 81]
, [IE849 7], [I150 9], [I530 81], [I263 9]
, [I787 20], [I272 4], [I280 9], [I486 ]
, [I578 9], [I584 9]
, [I585 9], [I427 31], [I403 90]  --(2493 rows affected)


-- Calculating the Common Odd Ratio 

SELECT sum(a*d/(a+b+c+d))/sum(b*c/(a+b+c+d)) As [Common Odds Ratio]
into #OddsRatio
FROM #Cases inner join #Controls 
ON  #Cases.[I305 1] =#Controls.[I305 1]
and #Cases.[I309 81] = #Controls.[I309 81]
and #Cases.[IE849 7]= #Controls.[IE849 7]
and #Cases.[I150 9]= #Controls.[I150 9]
and #Cases.[I530 81]= #Controls.[I530 81]
and #Cases.[I263 9]= #Controls.[I263 9]
and #Cases.[I787 20]= #Controls.[I787 20] 
and #Cases.[I272 4]= #Controls.[I272 4] 
and #Cases.[I280 9]= #Controls.[I280 9] 
and #Cases.[I486 ]= #Controls.[I486 ] 
and #Cases.[I578 9]= #Controls.[I578 9] 
and #Cases.[I584 9]= #Controls.[I584 9] 
and #Cases.[I585 9]= #Controls.[I585 9] 
and #Cases.[I427 31]= #Controls.[I427 31] 
and #Cases.[I403 90]= #Controls.[I403 90] 

select * from #OddsRatio

-- Matching Cases with controls 
drop table #Match
select  a ,b ,c ,d into #Match
 from #Cases  join #Controls 
ON #Cases.[I305 1] =#Controls.[I305 1]
and #Cases.[I309 81] = #Controls.[I309 81]
and #Cases.[IE849 7]= #Controls.[IE849 7]
and #Cases.[I150 9]= #Controls.[I150 9]
and #Cases.[I530 81]= #Controls.[I530 81]
and #Cases.[I263 9]= #Controls.[I263 9]
and #Cases.[I787 20]= #Controls.[I787 20] 
and #Cases.[I272 4]= #Controls.[I272 4] 
and #Cases.[I280 9]= #Controls.[I280 9] 
and #Cases.[I486 ]= #Controls.[I486 ] 
and #Cases.[I578 9]= #Controls.[I578 9] 
and #Cases.[I584 9]= #Controls.[I584 9] 
and #Cases.[I585 9]= #Controls.[I585 9] 
and #Cases.[I427 31]= #Controls.[I427 31] 
and #Cases.[I403 90]= #Controls.[I403 90] --(88 rows affected)

---Sum of the controls and cases 73804.0  

select * from #Match

--Calculating the overalp 
Declare @TotalCases Float
SET @totalCases = (SELECT Sum(nCases) FROM #Cases)
SELECT ROUND(SUM(a+b)*100/@TotalCases,2) as [Percent Overlap]
FROM #Match

/*
END Question 2
*/

/*
Question 3
*/

DROP TABLE #DATA
SELECT Str([src_subject_id], 7)+Concat_Levels AS ID, [src_subject_id],Concat_Levels
, Max(Bupropion) AS Bupropion 
, Max(CAST([Treatment_plan_equal_3] AS FLOAT)) as Remission
, CASE WHEN Sum([Heart])=0 THEN 0 ELSE 1 END AS [Heart]
, CASE WHEN Sum([Vascular])=0 THEN 0 ELSE 1 END AS [Vascular]
, CASE WHEN Sum([Haematopoietic])=0 THEN 0 ELSE 1 END AS [Haematopoietic]
, CASE WHEN Sum([Eyes_Ears_Nose_Throat_Larynx])=0 THEN 0 ELSE 1 END AS [Eyes_Ears_Nose_Throat_Larynx]
, CASE WHEN Sum([Gastrointestinal])=0 THEN 0 ELSE 1 END AS [Gastrointestinal]
, CASE WHEN Sum([Renal])=0 THEN 0 ELSE 1 END AS [Renal]
, CASE WHEN Sum([Genitourinary])=0 THEN 0 ELSE 1 END AS [Genitourinary]
, CASE WHEN Sum([Musculoskeletal_Integument])=0 THEN 0 ELSE 1 END AS [Musculoskeletal_Integument]
, CASE WHEN Sum([Neurological])=0 THEN 0 ELSE 1 END AS [Neurological]
, CASE WHEN Sum([Psychiatric_Illness])=0 THEN 0 ELSE 1 END AS [Psychiatric_Illness]
, CASE WHEN Sum([Respiratory])=0 THEN 0 ELSE 1 END AS [Respiratory]
, CASE WHEN Sum([Liver])=0 THEN 0 ELSE 1 END AS [Liver]
, CASE WHEN Sum([Endocrine])=0 THEN 0 ELSE 1 END AS [Endocrine]
, CASE WHEN Sum([Alcohol])=0 THEN 0 ELSE 1 END AS [Alcohol]
, CASE 
	WHEN Sum([Amphetamine])>0 THEN 1 
	WHEN Sum([Opioid])>0 THEN 1
	WHEN Sum([Cocaine])>0 THEN 1
		ELSE 0 END AS [AmphetamineOpioidCocaineAddiction]
, CASE WHEN Sum([Panic])=0 THEN 0 ELSE 1 END AS [Panic]
, CASE 
	WHEN Sum([Specific_Phobia])>0 THEN 1 
	WHEN Sum([Social_Phobia])>0 THEN 1
		ELSE 0 END AS [Phobia]
, CASE WHEN Sum([OCD])=0 THEN 0 ELSE 1 END AS [OCD]
, CASE WHEN Sum([PTSD])=0 THEN 0 ELSE 1 END AS [PTSD]
, CASE WHEN Sum([Anxiety])=0 THEN 0 ELSE 1 END AS [Anxiety]
, CASE 
	WHEN Sum([Paranoid_Personality])>0 THEN 1 
	WHEN Sum([Borderline_Personality])>0 THEN 1
	WHEN Sum([Dependent_Personality])>0 THEN 1
	WHEN Sum([Antisocial_Personality])>0 THEN 1 
	WHEN SUM([Personality_Disorder])>0 THEN 1 
		ELSE 0 END AS [Personality]
INTO #Data 
FROM [STARD].[dbo].[Data]
GROUP BY src_subject_id, Concat_Levels
Order by src_subject_id, Concat_Levels desc 
Go
-- 5624 trials of antidepressants
select top 20 * from #data


/****** Analysis of Remissions  ******/
DROP TABLE #DATA
SELECT Str([src_subject_id], 7)+Concat_Levels AS ID, [src_subject_id],Concat_Levels As Trial
, [Concat]
, Max(CAST([Treatment_plan_equal_3] AS FLOAT)) as Remission
, Max(Bupropion) AS Bupropion 
, Max(CIT) AS Citalopram
, MAX(Mirzapine) AS Mirzapine
, MAX(Buspirone) AS Buspirone
, MAX(Lithium) AS Lithium
, MAX(Nortriptyline) AS Nortriptyline
, MAX(Sertraline) AS Sertraline
, MAX(Thyroid) AS Thyroid
, MAX(Tranylclypromine) AS Tranylclypromine
, Max(Venlafaxine) AS Venlafaxine
, CASE WHEN Sum([Neurological])=0 THEN 0 ELSE 1 END AS [Neurological]
, CASE WHEN Sum([PTSD])=0 THEN 0 ELSE 1 END AS [PTSD]
, CASE WHEN Sum([Heart])=0 THEN 0 ELSE 1 END AS [Heart]
, CASE WHEN Sum([Vascular])=0 THEN 0 ELSE 1 END AS [Vascular]
, CASE WHEN Sum([Haematopoietic])=0 THEN 0 ELSE 1 END AS [Haematopoietic]
, CASE WHEN Sum([Eyes_Ears_Nose_Throat_Larynx])=0 THEN 0 ELSE 1 END AS [Eyes_Ears_Nose_Throat_Larynx]
, CASE WHEN Sum([Gastrointestinal])=0 THEN 0 ELSE 1 END AS [Gastrointestinal]
, CASE WHEN Sum([Renal])=0 THEN 0 ELSE 1 END AS [Renal]
, CASE WHEN Sum([Genitourinary])=0 THEN 0 ELSE 1 END AS [Genitourinary]
, CASE WHEN Sum([Musculoskeletal_Integument])=0 THEN 0 ELSE 1 END AS [Musculoskeletal_Integument]
, CASE WHEN Sum([Psychiatric_Illness])=0 THEN 0 ELSE 1 END AS [Psychiatric_Illness]
, CASE WHEN Sum([Respiratory])=0 THEN 0 ELSE 1 END AS [Respiratory]
, CASE WHEN Sum([Liver])=0 THEN 0 ELSE 1 END AS [Liver]
, CASE WHEN Sum([Endocrine])=0 THEN 0 ELSE 1 END AS [Endocrine]
, CASE WHEN Sum([Alcohol])=0 THEN 0 ELSE 1 END AS [Alcohol]
, CASE WHEN Sum([Panic])=0 THEN 0 ELSE 1 END AS [Panic]
, CASE WHEN Sum([OCD])=0 THEN 0 ELSE 1 END AS [OCD]
, CASE WHEN Sum([Anxiety])=0 THEN 0 ELSE 1 END AS [Anxiety]
, CASE 
	WHEN Sum([Amphetamine])>0 THEN 1 
	WHEN Sum([Opioid])>0 THEN 1
	WHEN Sum([Cocaine])>0 THEN 1
		ELSE 0 END AS [AmphetamineOpioidCocaineAddiction]
, CASE 
	WHEN Sum([Specific_Phobia])>0 THEN 1 
	WHEN Sum([Social_Phobia])>0 THEN 1
		ELSE 0 END AS [Phobia]
, CASE 
	WHEN Sum([Paranoid_Personality])>0 THEN 1 
	WHEN Sum([Borderline_Personality])>0 THEN 1
	WHEN Sum([Dependent_Personality])>0 THEN 1
	WHEN Sum([Antisocial_Personality])>0 THEN 1 
	WHEN SUM([Personality_Disorder])>0 THEN 1 
		ELSE 0 END AS [Personality]
INTO #Data 
FROM [STARD].[dbo].[Data]
GROUP BY src_subject_id, Concat_Levels, [Concat]
Order by src_subject_id, Concat_Levels desc 
Go
-- 5624 trials of antidepressants
--(7374 row(s) affected)
--Select distinct [concat] from #data order by [concat] desc

-- Create a table of distinct medications
DROP TABLE #Meds 
SELECT [Concat] AS Medication, ROW_NUMBER() OVER(Order by [Concat] desc) as MedId, COUNT(distinct [src_subject_id]) As nTrials
INTO #Meds FROM #Data
GROUP BY [Concat]
HAVING COUNT(distinct [src_subject_id])>29
-- Select * from #meds
/*
Medication	MedId	nTrials
MED1100000000	1	266
MED1001000000	2	253
MED1000000100	3	33
MED1000000000	4	3670
MED0100000000	5	235
MED0010000001	6	50
MED0010000000	7	102
MED0000010000	8	107
MED0000001000	9	218
MED0000000010	10	42
MED0000000001	11	241
MED0000000000	12	91
*/

DECLARE @Index INT
SET @index = 1  
WHILE (@Index <13)
BEGIN
    DROP TABLE #Cases, #Med
    SELECT Medication INTO #Med FROM #Meds Where MedID=@index
	SELECT CASE 
		WHEN SUM(Remission)=0 THEN 1./(SUM(Remission)+SUM(1-Remission)+1) 
		WHEN SUM(1-Remission) =0 THEN SUM(Remission)+SUM(1-Remission)+1 
		ELSE SUM(Remission)/SUM(1-Remission) END as pCases
	  , SUM(Remission)+SUM(1-Remission) as nCases
	  , STR([Heart],1)+STR([Vascular],1)+STR([Haematopoietic],1)+STR([Eyes_Ears_Nose_Throat_Larynx],1)+STR([Gastrointestinal],1)+STR([Renal],1)
	  +STR([Genitourinary],1)+STR([Musculoskeletal_Integument],1)+STR([Neurological],1)+STR([Psychiatric_Illness],1)+STR([Respiratory],1)+STR([Liver],1)
	  +STR([Endocrine],1)+STR([Alcohol],1)+STR([AmphetamineOpioidCocaineAddiction],1)+STR([Panic],1)+STR([Phobia],1)
	  +STR([OCD],1)+STR([PTSD],1)+STR([Anxiety],1)+STR([Personality],1)AS CaseStrata
	  , [Concat]
	INTO #Cases
	FROM #DATA INNER JOIN #Med On #DATA.[Concat]=#Med.Medication
	WHERE [Neurological]=1 and PTSD=1
	GROUP BY   
		   [Heart],[Vascular],[Haematopoietic],[Eyes_Ears_Nose_Throat_Larynx],[Gastrointestinal],[Renal],[Genitourinary],[Musculoskeletal_Integument]
		  ,[Neurological],[Psychiatric_Illness],[Respiratory],[Liver],[Endocrine],[Alcohol],[AmphetamineOpioidCocaineAddiction],[Panic],[Phobia],[OCD]
		  ,[PTSD],[Anxiety],[Personality],[Concat]
	-- (103 row(s) affected)

	DROP TABLE #Controls
	SELECT CASE 
		WHEN SUM(Remission)=0 THEN 1./(SUM(Remission)+SUM(1-Remission)+1) 
		WHEN SUM(1-Remission) =0 THEN SUM(Remission)+SUM(1-Remission)+1 
		ELSE SUM(Remission)/SUM(1-Remission) END as pControls
	  , SUM(Remission)+SUM(1-Remission) as nCases
	  , STR([Heart],1)+STR([Vascular],1)+STR([Haematopoietic],1)+STR([Eyes_Ears_Nose_Throat_Larynx],1)+STR([Gastrointestinal],1)+STR([Renal],1)
	  +STR([Genitourinary],1)+STR([Musculoskeletal_Integument],1)+STR([Neurological],1)+STR([Psychiatric_Illness],1)+STR([Respiratory],1)+STR([Liver],1)
	  +STR([Endocrine],1)+STR([Alcohol],1)+STR([AmphetamineOpioidCocaineAddiction],1)+STR([Panic],1)+STR([Phobia],1)
	  +STR([OCD],1)+STR([PTSD],1)+STR([Anxiety],1)+STR([Personality],1)AS ControlStrata
	  , [Concat]as Medication
	INTO #Controls
	FROM #DATA INNER JOIN #Med On #DATA.[Concat]!=#Med.Medication
	WHERE [Neurological]=1 and PTSD=1 
	GROUP BY   [Heart],[Vascular],[Haematopoietic],[Eyes_Ears_Nose_Throat_Larynx],[Gastrointestinal],[Renal],[Genitourinary],[Musculoskeletal_Integument]
		  ,[Neurological],[Psychiatric_Illness],[Respiratory],[Liver],[Endocrine],[Alcohol],[AmphetamineOpioidCocaineAddiction],[Panic],[Phobia],[OCD],[PTSD]
		  ,[Anxiety],[Personality], [Concat]
	--(103 row(s) affected)

	Select #Cases.*, #Controls.* 
	FROM #Cases inner join #Controls on #Cases.CaseStrata=#Controls.ControlStrata 
	ORDER BY Medication desc
	
SET @Index = @Index + 1
END
GO
