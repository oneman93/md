* resulting-project-loading.md
* project about new grade codes 
* See also Banner side updates: [banner-fail-grade-loading.md](./banner-fail-grade-loading.md)
* See also workshop notes: [canvas-resulting-workshop.md](./canvas-resulting-workshop.md)
* See also LT task: [LT_Push_to_banner_2024-loading.md](./LT_Push_to_banner_2024-loading.md)
* See also [resulting-all-errors.md](resulting-all-errors.md)
* See also [unit test results](result-project-unit-testing.md)
* See also Academic Transcript test [AT-test.md](AT_test.md)
* See also [oracle setting job scheduler](resulting-project-oracle-job-schduler.md)
* See also [myequals doc](resulting-myequals-loading.md)
* See also [release note](resulting-project-release-note.md)
* See also [resulting-project-t3-loading.md](resulting-project-t3-loading.md)

# How to COR

* My video here: [cor-how-to.mp4](https://laureateaus-my.sharepoint.com/:v:/g/personal/matthew_oh_torrens_edu_au/IQDgxFKC1HdmTZNnEpwm7IQsAXgRw5JhJDdkWpoiSFOAezw?email=hjones%40Torrens.edu.au&e=bHr0sF)

![](./Canvas-DLE/imgs/img-resulting-project/0052.png "0052.png")


# The flow
![](./Canvas-DLE/imgs/img-resulting-project/0051.png "0051.png")

# Resources

item | desc
--|--
tickets | [ML1008-1012](https://thinkeducation.atlassian.net/browse/ML-1008), [SES-110](https://thinkeducation.atlassian.net/browse/SES-110)
all my tickets | [all my tickets](https://thinkeducation.atlassian.net/jira/software/projects/ML/issues/ML-1010?jql=project%20%3D%20%22ML%22%20AND%20assignee%20%3D%20currentUser%28%29%20AND%20status%20IN%20%28%22In%20Progress%22%2C%20Stuck%2C%20%22To%20Do%22%2C%20%22On%20Hold%22%29%0AORDER%20BY%20created%20DESC)
db-dev | sydawsdev-db02.Blackboard<br>Blackboard<br>dbo
db-prd | sydawsprd-dm02.Blackboard
local query | `C:\Works\SQLQueries\Blackboard SQL\__resultingProjectDB02.sql`
local query2 | `C:\Works\SQLQueries\Blackboard SQL\___QAFix.sql`
oracle query | `1-grade-fail.sql`
excel | [resulting-related-tables.xlsx](https://laureateaus-my.sharepoint.com/:x:/r/personal/matthew_oh_torrens_edu_au/Documents/WebExcel/resulting-related-tables.xlsx?d=w3ce6c9ff55ac408788866947673a0246&csf=1&web=1&e=X5KeFH)
MF mapping document | [mapping document.xlsx](https://laureateaus-my.sharepoint.com/:x:/g/personal/mfoster_torrens_edu_au/EdlPoRP93j1DpmTXHpVlnccBkZhUsi0lh-79UY_jids7WQ?email=matthew.oh%40torrens.edu.au&wdOrigin=TEAMS-MAGLEV.p2p_ns.rwc&wdExp=TEAMS-TREATMENT&wdhostclicktime=1751943069135&web=1)
Diagram workflow | [Canvas-ERD-personal.vsdx](https://laureateaus-my.sharepoint.com/:u:/r/personal/matthew_oh_torrens_edu_au/Documents/Visio-Onedrive/Canvas-ERD-personal.vsdx?d=w08d9826785894c5492ea1690b54e5afd&csf=1&web=1&e=5L9m9X)
Timeline | 8th august
Grading scheme url | https://torrens.beta.instructure.com/accounts/1/grading_settings/schemes<br>Approval Status<br>HE Result Status V2
Helen Jones - The latest Grade codes | [Helen Jones Codes](https://teams.microsoft.com/l/message/19:8471c419bcc84eab930d6a8502a65a62@thread.tacv2/1753055150667?tenantId=a3e3792c-ef72-4468-b62d-a7b484147698&groupId=081b39ee-bf3f-42b9-b055-36028b16b5a0&parentMessageId=1753055150667&teamName=T%26L%20Product%20Team&channelName=%F0%9F%A7%AC%20%20Resulting%20Solution&createdTime=1753055150667)
Review scenario (QA team) | [here](https://thinkeducation.atlassian.net/wiki/spaces/QA/pages/edit-v2/3002597412)
Grade codes - Policy doc | [pdf file](https://laureateaus.sharepoint.com/sites/MyTorrens/Shared%20Documents/Forms/Policies_Filter.aspx?id=%2Fsites%2FMyTorrens%2FShared%20Documents%2FPolicies%2FPolicies%20%2D%20Summary%20of%20Changes%2F2025%2F20250526%20Comms%20re%20policy%20changes%20effective%202%20June%202025%2Epdf&parent=%2Fsites%2FMyTorrens%2FShared%20Documents%2FPolicies%2FPolicies%20%2D%20Summary%20of%20Changes%2F2025)
Mylearn staging site | https://torrens.beta.instructure.com/courses/14563/gradebook
staging Barely used| https://torrens-stage.instructure.com/ 
** staging Used a lot| https://mylearn-stage.torrens.edu.au/ 
** 10 courses to test (Resulting Solution T2 - Test Data) | https://thinkeducation.atlassian.net/wiki/spaces/QA/pages/3010494475/Resulting+Solution+T2+-+Test+Data
Refresh Timings (MF) | [confluence page](https://thinkeducation.atlassian.net/wiki/spaces/DLE/pages/3018686475/Refresh+Timings)
Deploy checklist, rollback plan (MJones)| [confluence](https://thinkeducation.atlassian.net/wiki/spaces/DLE/pages/3021078529/Deployment+Checklist+Staging+to+Prod)

## Datetime vs nvarchar columns

* See excel above - `Datetime columns` tab
![](./Canvas-DLE/imgs/img-resulting-project/0050.png "50")


## Resources - Risk Log:

![](./Canvas-DLE/imgs/img-resulting-project/0032.png "32")


## Resources - My tickets

* [ML-1010 Grade update logic](https://thinkeducation.atlassian.net/browse/ML-1010) >> done
  * [unit test ml-1010](./result-project-unit-testing.md#ml-1010)

* [ML-1011 Approval logic](https://thinkeducation.atlassian.net/browse/ML-1011) >> done

* [ML-1012 Banner schedule](https://thinkeducation.atlassian.net/browse/ML-1012)
  * discussion meeting required with Ron
  * Todo research

* [ML-1074 Grade audit table](https://thinkeducation.atlassian.net/browse/ML-1074) >> done

* [ML-1075 Api create](https://thinkeducation.atlassian.net/browse/ML-1075)
  * `tblUserActionAudit`
  * done


# Key places

item | desc
--|--
main table | `sydaws-DM02.blackboard.dbo.tbl_Student_Final_View`
audit table | `result.tblStudentFinalViewAudit`
system audit table by trigger| `dbo.tbl_Student_Final_Viewaudit`
main sp | `sydaws-DM02.blackboard.dbo.Canvas_Grade_push`
banner sp | `informatica.sp_student_grade_push`
informatica job (prod, current) | `Canvas * Exam Portal Data * LT_Push_to_banner_2024`
informatica job (prod, new) | `Exam portal * m_student_grade_push`

* Existing db schema - `[dbo]`
* New db schema to add extra tables and procs to upload logic - `[result]`


# Schedule

item | desc
--|--
lt1 `FETCH` | LT_Process_Grades_T3_2022
lt1 schedule | Refresh Notes Column * `every 3 hours from 4am`
lt2 `UPDATE`| LT_Canvas_DM02_Sync
lt2 Schedule name | `Canvas to DM02` * `every 2 hours from 4:20pm`
lt3 `PUSH` | Canvas\Exam Portal Data\LT_Push_to_banner_2024
lt3 schedule | Banner_Grades_Push_Hourly * `hourly from 1130am`



# 5 dataset

* `@isdebug=1` returns 5 dataset

```
1. tmpResultStatus - records of result status updated
2. tmpApprovalStataus - records of approval status updated
3. tmpFinalGrade (before) - final grade + score (gradecode not updated)
4. tmpFinalGrade (after) - final grade + score (gradecode updated)
5. tbl_student_final_view
```

![](./Canvas-DLE/imgs/img-resulting-project/0040.png "40")
![](./Canvas-DLE/imgs/img-resulting-project/0041.png "41")

# Audit table query

```
* ml-1231, 1244
* C:\Works\SQLQueries\Blackboard SQL\___QAFix.sql

select a.*
	, v.Lecturer_Approval, v.Lecturer_Approved_Mark, v.Lecturer_Approved_Grade, v.Lecturer_Approved_Date, v.Lecturer_Additional_Comment
	, v.Academic_Services_Approval, v.Academic_Services_Approved_Mark, v.Academic_Services_Approved_Grade, v.Academic_Services_Approved_Status, v.Academic_Services_Approved_Date
	, stu.short_name as StudentName
	, v.Student_ID
	, v.Term_ID
	, v.Subject
	, v.course_id
	, cast (cast(v.course_id as float) as int) CRN
	, lec.short_name as LecturerOrApproverName
	, case when a.IsApprovalStatusChange=0 then lec.short_name else null end as LecturerName
	, case when a.IsApprovalStatusChange=1 then lec.short_name else null end as ApproverName
from result.tblStudentFinalViewAudit a
inner join tbl_Student_Final_View v on a.StudentKey=v.student_key
inner join Canvas_Users stu on stu.id=a.UserID
left join Canvas_Users lec on lec.id=a.GraderID
```


# BAU - VET grades overrides to Fail/HD

* [chat / reply here](https://teams.microsoft.com/l/message/19:Nj8Y58ngFByb8__1bpCIwZKSLPu8uQ7WcUXd0D35zTo1@thread.tacv2/1758087724285?tenantId=a3e3792c-ef72-4468-b62d-a7b484147698&groupId=081b39ee-bf3f-42b9-b055-36028b16b5a0&parentMessageId=1758082303294&teamName=T%26L%20Product%20Team&channelName=%F0%9F%9B%A0%EF%B8%8F%20Resulting%20Solution%20Hypercare%20(T2%202025)&createdTime=1758087724285&ngc=true&allowXTenantAccess=true)

![](./Canvas-DLE/imgs/img-resulting-project/0044.png "0044.png")
![](./Canvas-DLE/imgs/img-resulting-project/0045.png "0045.png")
![](./Canvas-DLE/imgs/img-resulting-project/0046.png "0046.png")
![](./Canvas-DLE/imgs/img-resulting-project/0047.png "0047.png")
![](./Canvas-DLE/imgs/img-resulting-project/0048.png "0048.png")
![](./Canvas-DLE/imgs/img-resulting-project/0049.png "0049.png")

```
Hi Rose Lennon, I have checked first 2 students and they were pushed as COMPby grading system and didn't get pushed again since 8/9/25. However, I could see what you said (Fail, HD) in banner side. I think some other process is updating this grade. I also see that they are starting updated back to COMP again today, around 10am.
```

* q. Why it didn't create record in audit table?
  * ans. Audit table record is inserted by `dbo.[Canvas_Grade_Push]`. If someone manually update final view table and run mapping task manully to push, audit record will not be created.
* q. What was the issue?
  * Some vet records had course type `HE`
* q. Banner `shrmrks` still has `F`. 
  * ans. This seems ok with business as long as it shows as `VET`.

# Supplementary

## Resources

item | desc
--|--
local query | C:\Works\SQLQueries\Blackboard SQL\___supplementary.sql
Smita Vij sample excel file | [here](https://laureateaus.sharepoint.com/:x:/r/sites/AcademicAdministrationandPartnerships/_layouts/15/Doc.aspx?sourcedoc=%7BF74749E1-9118-456E-AF7B-75CC5026685A%7D&file=(T2%2025)%20All%20faculties%20Supps.xlsx&wdLOR=c4E823C50-F887-4A98-ACC3-F86F3527758F&fromShare=true&action=default&mobileredirect=true)
Deployed columns | tbl_student_final_view.SupplementaryPushDate, StatusID=251
Deployed sp | `result.spUpdateSuplementaryMarkByStudent`
Supplementary meeting KT recording | [here](https://teams.microsoft.com/l/meetingrecap?driveId=b%21RJvUnUPYJE2KreIpEKIt6t2Q4NKYM6JFudHnIX_umzuieAuaqIwrT4W-bXLWQnQj&driveItemId=017GIML6FN7CEIIFR2WJHJOGEPBP3FNJH3&sitePath=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmatthew_oh_torrens_edu_au%2FEa34iIQWOrJOlxiPC_ZWpPsBRgNf38dqKanluozciOOP1A&fileUrl=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmatthew_oh_torrens_edu_au%2FEa34iIQWOrJOlxiPC_ZWpPsBRgNf38dqKanluozciOOP1A&iCalUid=040000008200E00074C5B7101A82E0080000000000C95E6F8028DC0100000000000000001000000075D3783D90314E48B70DCC4B4A3272F8&threadId=19%3Ameeting_NzViOGEyZDAtZTZiNC00ZDNlLTgwMDItNzI4M2E3N2YzYjVk%40thread.v2&organizerId=8f7dc2ab-cd80-4ae7-85a9-da08bb4d92a1&tenantId=a3e3792c-ef72-4468-b62d-a7b484147698&callId=70e5a358-8e6b-41d6-89f0-dc38020dcf36&threadType=Meeting&meetingType=Scheduled&subType=RecapSharingLink_RecapChiclet)

```
exec result.spUpdateSuplementaryMarkByStudent 'A00100252','COU304A','253200',50,'SP',1
```

* "Final grade will be given later (Supplementary Pass or Fail) after giving the student 2nd chance"
* MF meeting [here](https://teams.microsoft.com/l/meetingrecap?driveId=b%211ESYOMZUdU-YddhJR_EcYhmkDq1pPG1Ioc-I5xkvIEZEf8VfWkBPTKn20_70gv3Z&driveItemId=01JG3T3P7ZB3XIKRCW5VBKBBOKVEYRNTI4&sitePath=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmfoster_torrens_edu_au%2FEfkO7oVEVu1CoIXKqTEWzRwBVFzsAec5SN45B-wf55quog&fileUrl=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmfoster_torrens_edu_au%2FEfkO7oVEVu1CoIXKqTEWzRwBVFzsAec5SN45B-wf55quog&iCalUid=040000008200E00074C5B7101A82E008000000000B04F740D022DC010000000000000000100000006793FEEA9AA85343BDB3B06426F87C39&threadId=19%3Ameeting_YTJkMmRlMDItOThkMC00MGI1LWE2YWMtMGZjZjcyYTU2OWJi%40thread.v2&organizerId=149814b7-0c7b-46dd-938e-525eaf949ce7&tenantId=a3e3792c-ef72-4468-b62d-a7b484147698&callId=05bd79e5-198c-4601-9685-f9f5c5ae09c0&threadType=Meeting&meetingType=Scheduled&subType=RecapSharingLink_RecapChiclet)


# COR fire logic


* 14/8/25
* [MF requested here](https://teams.microsoft.com/l/message/19:meeting_ODk5MWFlOTItOGI5ZC00NjUxLTg0MzAtM2U2NTFiZjdkYTgw@thread.v2/1755126149215?context=%7B%22contextType%22%3A%22chat%22%7D)

![](./Canvas-DLE/imgs/img-resulting-project/0042.png "0042.png")
![](./Canvas-DLE/imgs/img-resulting-project/0043.png "0043.png")

* 9/9/25
* Logic reviewed [chat here](https://teams.microsoft.com/l/message/19:meeting_ODk5MWFlOTItOGI5ZC00NjUxLTg0MzAtM2U2NTFiZjdkYTgw@thread.v2/1757393789866?context=%7B%22contextType%22%3A%22chat%22%7D)
* [ML-952](https://thinkeducation.atlassian.net/browse/ML-952)

* Meeting minutes with Melissa P [melissa-cor-not-firing-09.09.2025_14.00.48_REC](https://laureateaus-my.sharepoint.com/:v:/r/personal/matthew_oh_torrens_edu_au/Documents/LocalVideos/melissa-cor-not-firing-09.09.2025_14.00.48_REC.mp4?csf=1&web=1&e=ahFkj2)


# NGP logic

* [ML-1249](https://thinkeducation.atlassian.net/browse/ML-1249)

![](./Canvas-DLE/imgs/img-resulting-project/0037.png "37")
![](./Canvas-DLE/imgs/img-resulting-project/0038.png "38")
![](./Canvas-DLE/imgs/img-resulting-project/0039.png "39")

# COR logic change

* COR cannot be reselected [team chat](https://teams.microsoft.com/l/message/19:meeting_ODk5MWFlOTItOGI5ZC00NjUxLTg0MzAtM2U2NTFiZjdkYTgw@thread.v2/1755129199009?context=%7B%22contextType%22%3A%22chat%22%7D)
* [MF team chat request](https://teams.microsoft.com/l/message/19:meeting_ODk5MWFlOTItOGI5ZC00NjUxLTg0MzAtM2U2NTFiZjdkYTgw@thread.v2/1755126149215?context=%7B%22contextType%22%3A%22chat%22%7D)
* [ML-1223](https://thinkeducation.atlassian.net/browse/ML-1223)
* [ML-1241](https://thinkeducation.atlassian.net/browse/ML-1241)


# Deploy & Rollback plan

* Deploy: 
  * [todeploy-resulting-project.xlsx](https://laureateaus-my.sharepoint.com/:x:/r/personal/matthew_oh_torrens_edu_au/_layouts/15/Doc.aspx?sourcedoc=%7B25DCD987-BB78-418B-93E0-962A8FCC0529%7D&file=___todo-torrens-projects.xlsx&action=default&mobileredirect=true)

* Rollback plan:
  * Restore `Blackboard.dbo.SP_Student_Grade_Push_bak` to `SP_Student_Grade_Push`
  * Leave all `result` schema object as they are. Not affected.
  * Leave oracle job running. Not affected.

# MyLearn Schemes

* There are 3 pages to check the current schemes:
  * Account level:
    ![](./Canvas-DLE/imgs/img-resulting-project/0034.png "34 account")
    
  * Course level:
    ![](./Canvas-DLE/imgs/img-resulting-project/0033.png "33 course")

  * Each student level:
    ![](./Canvas-DLE/imgs/img-resulting-project/0035.png "35 each student")


# /api/saveUserActionAudit

* [confluence page](https://thinkeducation.atlassian.net/wiki/spaces/IW/pages/3005022214/Canvas+Resulting+Project+API)
* For `/api/saveUserActionAudit`, see [mylearn-backend-validate.md](./mylearn-backend-validate.md)

![](./Canvas-DLE/imgs/img-resulting-project/0028.png "28")
![](./Canvas-DLE/imgs/img-resulting-project/0029.png "29")
![](./Canvas-DLE/imgs/img-resulting-project/0030.png "30")
![](./Canvas-DLE/imgs/img-resulting-project/0031.png "31")

## Deployed (torres.dev /api/saveUserActionAudit)
item|desc
--|--
api saveUserAction | https://mylearndb-dev.api.torrens.edu.au/backend-validate/api/saveUserActionAudit
x-api-key | 0Y9PXGiVwU318ZnFts7an75IDk5u7Y4S4Y163jTh
operation | POST
json body | [test.json](./MyLearn/test.json)


![](./MyLearn/img-backend/0035.png "35")
![](./MyLearn/img-backend/0036.png "36")

# [result].[vBannerResponseBackToOracle]

* Reduce speed of pull process: `LT_Pull_From_Banner_2025` time taken. 

![](./MyLearn/img-backend/0040.png "0040.png")


# Students are receiving FAIL grades when they have passed

* [Helen Jones wrong alarm about flow](https://teams.microsoft.com/l/message/19:927d5e53017b4012a9bd811014a497b3@thread.v2/1757056389115?context=%7B%22contextType%22%3A%22chat%22%7D)

* Melissa Pereira reply
```
This is a case where an LF/approver changed the total directly after the LF/approver approvals were done and  grade pushed into banner. The correct process of going through COR was not followed and total was changed after that approvals so this change will not flow through to final view/banner and hence the discrepancy.
```

* See also `Banner GradePush Logic` in diagram: [Canvas-ERD-personal.vsdx](https://laureateaus-my.sharepoint.com/:u:/r/personal/matthew_oh_torrens_edu_au/Documents/Visio-Onedrive/Canvas-ERD-personal.vsdx?d=w08d9826785894c5492ea1690b54e5afd&csf=1&web=1&e=5L9m9X)



# meeting minutes

* 10am, 12/9/25, MF, Hemma, MyLearn schema dynamic setup

* [here](https://teams.microsoft.com/l/meetingrecap?driveId=b%21hpX-nyZ6mkWTrxhD3NcIUscXTfmAaSZLjRZWQ5CcySNMIy7pIgr2Sa3U8fT0Bi0Z&driveItemId=01BM5BEMWUPKLTBLNEPZBJRUXBZFKFXAZY&sitePath=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fhemmachat_paramabuddhi_torrens_edu_au%2FEdR6lzCtpH5CmNLhyVRbgzgBo2WRun_aOBm5bIQcCEibgA&fileUrl=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fhemmachat_paramabuddhi_torrens_edu_au%2FEdR6lzCtpH5CmNLhyVRbgzgBo2WRun_aOBm5bIQcCEibgA&iCalUid=040000008200E00074C5B7101A82E00807E9090CE749D961C9E4DB01000000000000000010000000735F838CF3336C4790ABEA01C68057FE&masterICalUid=040000008200E00074C5B7101A82E00800000000E749D961C9E4DB01000000000000000010000000735F838CF3336C4790ABEA01C68057FE&threadId=19%3Ameeting_Y2YyNDQwZjktMGRlOC00MmNkLWIxZmQtMzFiZGMxZWZlMzk2%40thread.v2&organizerId=e08c6412-0ddb-4137-878d-5a2093d5950d&tenantId=a3e3792c-ef72-4468-b62d-a7b484147698&callId=47a0c0ba-b419-4185-bd46-692ea504ea04&threadType=Meeting&meetingType=Recurring&subType=RecapSharingLink_RecapChiclet)

# DO NOT COPY FROM HERE -------------------------


# My qna
* q. how can i select 1 row only to push?
  * ans. use student_id or student_key
* q. how can i check oracle log?

```
SELECT * from SZTBGRD where sztbgrd_student_id='A00123737';	-- RUN IN BANNER PROTO

SELECT SFRSTCR_GRDE_CODE, sfrstcr.* FROM sfrstcr WHERE sfrstcr_pidm = 143746 order by sfrstcr_activity_date desc;	--run in banner
```


# MF qna 

* q. what is `A0` in beginning? who sets?

A0A00157158
A0A00155728
A0A00163709
A0A00124242
A0A00163368
A0A00139925
A0A00145612
A0A00152800
A0A00164772

* q. Are we copy/duplicate canvas/exam portal?
  * ans. no. the only change is `mt_Student_Grade_push_2`

![](./Canvas-DLE/imgs/img-resulting-project/0027.png "27")

* q. What is inserting rows to `tbl_Student_final_view`?
  * ans. LT_Process_Grades_T3_2022

* q. Approved * COR * same column, different items?
  * ans. yes

* q. where can i start updating proc? dm02 prod/dev?
  * `sydawsdev-db02`

* q. in oracle, why only 2k records in SZTBGRD?
```
select * from SZTBGRD order by sztbgrd_process_date desc; --2155 only?
--08-jul-25: 6 records
select * from SZTBGRD order by sztbgrd_process_date asc;
--17-FEB-25: 143 records
```
  * ans. there is manual delete job
* Q. what is banner grade scale?
  * ans. certain grades only for certain subjects
* q. where does Blackboard.dbo.Term get deleted?
  * ans. `Blackboard\DM02 Faster Refresh\LT_Blackboard_DM02_Data_Refresh\MT_DL_BB_Term_Full`

# Self study

## what is this for?
Canvas\Canvas Data 2\`LT_CanvasDATA2_To_ODS_LOAD or TF_Canvas_Sync_ODS`
* Mt_Populate_canvas_terms 
* M_Populate_canvas_terms 

## Update table

* Canvas\Canvas Data 2\`LT_Canvas_DM02_Sync`
* MT_Canvas_Grades_Push
* `M_Canvas_Grades_Push` 
    * Source: `exec [dbo].[Canvas_Grade_Push];`  (canvas grade/score tables)
    * Target: `tbl_student_final_view` (dm02 final table)
    * dm01.Blackboard.dbo.SP_DummyTarget

## Push from Canvas to Banner

* `LT_Push_to_banner_2024` or Overnight loads
* Canvas\Exam Portal Data\`mt_Student_Grade_push_2`
* Canvas\Exam Portal Data\m_Student_Grade_push
* begin
`INFORMATICA.SP_STUDENT_GRADE_PUSH()\;`
end\;
* oracle, informatica.SP_DUMMYTARGET
* oracle, SZTBGRD

## QNA - self stduy

* q. Who calls `sydaws-DM02.blackboard.dbo.Canvas_Grade_push`?
  * ans. LT_Canvas_DM02_Sync

* q. after `tbl_student_final_view` is updated with final grades/scores, how does it save to Banner?

* q. Why inserting terms?

* q. who populates `[BLACKBOARD].[dbo].canvas_final_scores`?
  * ans. `LT_Canvas_DM02_Sync * MT_Canvas_Final_Grades`
  * `tgecanvas/VIEW/scores * Canvas_Final_Scores` 

# Screenshots - self study2

* How dm02 data is pushed to Banner

![](./Canvas-DLE/imgs/img-resulting-project/0023.png "23")
![](./Canvas-DLE/imgs/img-resulting-project/0017.png "17")
![](./Canvas-DLE/imgs/img-resulting-project/0022.png "22")
![](./Canvas-DLE/imgs/img-resulting-project/0024.png "24")
![](./Canvas-DLE/imgs/img-resulting-project/0025.png "25")
![](./Canvas-DLE/imgs/img-resulting-project/0026.png "26")

![](./Canvas-DLE/imgs/img-resulting-project/0021.png "21 (1/3) get rows to update")
![](./Canvas-DLE/imgs/img-resulting-project/0019.png "19 (2/3) update grade")
![](./Canvas-DLE/imgs/img-resulting-project/0020.png "20 (3/3) update SZTBGRD ignore")


# Screenshots - self study

* How canvas data is saved into `dm-02`

![14](./Canvas-DLE/imgs/img-resulting-project/0014.png "14")
![12](./Canvas-DLE/imgs/img-resulting-project/0012.png "12")
![](./Canvas-DLE/imgs/img-resulting-project/0013.png "13")
![](./Canvas-DLE/imgs/img-resulting-project/0015.png "15")
![](./Canvas-DLE/imgs/img-resulting-project/0016.png "16")


# Screenshots - meeting
![](./Canvas-DLE/imgs/img-resulting-project/0011.png "11")
![](./Canvas-DLE/imgs/img-resulting-project/0001.png "1")
![](./Canvas-DLE/imgs/img-resulting-project/0002.png "2")
![](./Canvas-DLE/imgs/img-resulting-project/0003.png "3")
![](./Canvas-DLE/imgs/img-resulting-project/0004.png "4")
![](./Canvas-DLE/imgs/img-resulting-project/0005.png "5")
![](./Canvas-DLE/imgs/img-resulting-project/0006.png "6")
![](./Canvas-DLE/imgs/img-resulting-project/0007.png "7")
![](./Canvas-DLE/imgs/img-resulting-project/0008.png "8")
![](./Canvas-DLE/imgs/img-resulting-project/0009.png "9")
![](./Canvas-DLE/imgs/img-resulting-project/0010.png "10")

# Meeting videos

## meeting minutes, 8/8/25, 2:30pm, capturing user behaviour of MyLearn + audit table discussion, MF, MP, Van, Trang

[Resulting T2 - Pending Open Questions](https://teams.microsoft.com/l/meetingrecap?driveId=b%21TMk7BG4a5ES6TSPYn6hzRMcXTfmAaSZLjRZWQ5CcySNMIy7pIgr2Sa3U8fT0Bi0Z&driveItemId=01SWHVSAD2YCNFS3Y24RGJMYJZWG2J473X&sitePath=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmelissa_pereira_torrens_edu_au%2FEXrAmllvGuRMlmE5sbSef3cBfJLmoQeVhF6fngtpz7ZzEg&fileUrl=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmelissa_pereira_torrens_edu_au%2FEXrAmllvGuRMlmE5sbSef3cBfJLmoQeVhF6fngtpz7ZzEg&iCalUid=040000008200E00074C5B7101A82E00800000000A02B58749107DC0100000000000000001000000060A91E3E21D0144B836D16A890B841BF&threadId=19%3Ameeting_ODkyZDQ5OGMtYmM5Ni00YzAxLThjM2YtMGZkZDAzNmVmNDAx%40thread.v2&organizerId=3cd6b7f8-af96-4340-9911-709922356e2d&tenantId=a3e3792c-ef72-4468-b62d-a7b484147698&callId=d7ee97a2-da3e-4067-87a0-398fa28d9db3&threadType=Meeting&meetingType=Scheduled&subType=RecapSharingLink_RecapChiclet)

## meeting minutes, Resulting project discussion, MF

* [teams meeting](https://teams.microsoft.com/l/meetingrecap?driveId=b%211ESYOMZUdU-YddhJR_EcYhmkDq1pPG1Ioc-I5xkvIEZEf8VfWkBPTKn20_70gv3Z&driveItemId=01JG3T3PZYFAXZSCQQXFHLCCI3ZAC6RLEZ&sitePath=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmfoster_torrens_edu_au%2FETgoL5kKELlOsQkbyAXorJkBHVQKH07aDt-zP4xFnnAhWw&fileUrl=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmfoster_torrens_edu_au%2FETgoL5kKELlOsQkbyAXorJkBHVQKH07aDt-zP4xFnnAhWw&iCalUid=040000008200E00074C5B7101A82E008000000002525DD1D14EBDB010000000000000000100000000B5C5E05D65DFA408B34A4FB634F6F07&threadId=19%3Ameeting_OTdjNzlhZTItNGYxNi00M2Y3LWFkZTYtOGQwNzRhOWMzOTA4%40thread.v2&organizerId=149814b7-0c7b-46dd-938e-525eaf949ce7&tenantId=a3e3792c-ef72-4468-b62d-a7b484147698&callId=f3141fea-df2c-4630-89ba-a6db7aa91370&threadType=Meeting&meetingType=Scheduled&subType=RecapSharingLink_RecapChiclet)



950 full description will update status
1030 once grading schema is ready, you need to update Supplementary logic here.

***finished sql**

1610 ML-1010
2002 ml-1011 UI front end part
2046 Approval column - only visible to LF
2047 ML-1010
If not approved, just update grade, but not approved status
UI explain
2358
***2521 back to sql**
coalesce
recalculate grade based on score
2705 set score 0 for normal fail
2757 what needs to be populated:
Approved:
Approved mark:
Approved date:
Approved date > Exam Push date

2945 what we are doing is just popluating these table columns from canvas
3017 who's doing front end part?
3100 ml-1011 hacking javascript to show/hide
***3215 back to sql**
3204 important part: 2 phase: (1) update status (2) update approved
3257 stupid question: are we still using exam portal?


q. are we pushing grade without approval?
q. what are we pusing differently wehn approval?
q. what temp table for saving approval?

3429 ml-1012 banner schedule to push. Maybe Ron to schedule this job.
3654, if jacbo does n't update grade, it will have error, FT code doesn't exist.

**3819, banner script SP_STUDENT_GRADE_PUSH**
4349 MEETING FINISH



## Other meetings

* [mf-bulk-tables-grade-02.07.2025_15.57.58_REC.mp4](https://laureateaus-my.sharepoint.com/:v:/r/personal/matthew_oh_torrens_edu_au/Documents/LocalVideos/mf-bulk-tables-grade-02.07.2025_15.57.58_REC.mp4?csf=1&web=1&e=SAaZhh)
* [canvas-mymarks-02.07.2025_14.34.53_REC.mp4, helen jones](https://laureateaus-my.sharepoint.com/:v:/r/personal/matthew_oh_torrens_edu_au/Documents/LocalVideos/canvas-mymarks-02.07.2025_14.34.53_REC.mp4?csf=1&web=1&e=evkh8k)



# QNA meetings with MF, 18/7/25, FRI, MF

[Teams meeting](https://teams.microsoft.com/l/meetingrecap?driveId=b%21RJvUnUPYJE2KreIpEKIt6t2Q4NKYM6JFudHnIX_umzuieAuaqIwrT4W-bXLWQnQj&driveItemId=017GIML6C7QSIP7IHAK5EII57HJFQLI737&sitePath=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmatthew_oh_torrens_edu_au%2FEV-EkP-g4FdIhHfnSWC0f38Bw864ipdUrhORQE4okOdiDw&fileUrl=https%3A%2F%2Flaureateaus-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmatthew_oh_torrens_edu_au%2FEV-EkP-g4FdIhHfnSWC0f38Bw864ipdUrhORQE4okOdiDw&iCalUid=040000008200E00074C5B7101A82E00800000000A0538EC1F5F7DB01000000000000000010000000EBF11B319FA36147A97A58A0587964D2&threadId=19%3Ameeting_MzNjOWUxMDQtNDlmYi00NjMxLWEzYmYtNDM4MzgxMWM5Yzg1%40thread.v2&organizerId=8f7dc2ab-cd80-4ae7-85a9-da08bb4d92a1&tenantId=a3e3792c-ef72-4468-b62d-a7b484147698&callId=d29c6156-efbc-4125-bc30-332efab94a81&threadType=Meeting&meetingType=Scheduled&subType=RecapSharingLink_RecapChiclet)


* q. are we pushing grade(Result Staus) without approval (Approval Staus)?
  * ans. no. banner pushing logic does not change. it only pushed when approved. When `Result Status` changed, the columns below will be populated:

```
-- columns will udpate:
--graded_at, published_score, published_grade,grader_id				>> + user_id, course_id >> tbl_result_status_changes
--graded_at, published_score, published_grade(i=4, c=,grader_id)		>> + user_id, course_id >> tbl_approval_status_changes
```

* q. what are we pusing differently when approval?
  * ans. no change. only pushing to banner when approved.


* q. what temp table for saving approval? are we talking about something like SZTBGRD for approval?
  * ans. Same table, `tbl_student_final_view` 4 columns will be updated



* q. how am i updating in accordance with schema?
  * ans. unmodified grade.



* Q. if we give banner job to schedule updating grade, how can we confirm that banner updated?
  * ans. by SZTBGRD table status


* q. why do we need two audit tables? where are they inserted?
  * ans. one table with extra column `ApprovalStatusChanged`

