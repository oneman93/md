resulting-project-loading.md
project about new grade codes
See also Banner side updates: banner-fail-grade-loading.md
See also workshop notes: canvas-resulting-workshop.md
See also LT task: lt_push_to_banner_2024-loading.md
See also resulting-all-errors.md
See also unit test results
See also Academic Transcript test AT-test.md
See also oracle setting job scheduler
See also myequals doc
See also release note
See also resulting-project-t3-loading.md
How to COR
My video here: cor-how-to.mp4

The flow

Resources
item	desc
tickets	ML1008-1012, SES-110	
all my tickets	all my tickets	
db-dev	sydawsdev-db02.Blackboard
Blackboard
dbo	
db-prd	sydawsprd-dm02.Blackboard	
local query	C:\Works\SQLQueries\Blackboard SQL\__resultingProjectDB02.sql	
local query2	C:\Works\SQLQueries\Blackboard SQL\___QAFix.sql	
oracle query	1-grade-fail.sql	
excel	resulting-related-tables.xlsx	
MF mapping document	mapping document.xlsx	
Diagram workflow	Canvas-ERD-personal.vsdx	
Timeline	8th august	
Grading scheme url	https://torrens.beta.instructure.com/accounts/1/grading_settings/schemes
Approval Status
HE Result Status V2	
Helen Jones - The latest Grade codes	Helen Jones Codes	
Review scenario (QA team)	here	
Grade codes - Policy doc	pdf file	
Mylearn staging site	https://torrens.beta.instructure.com/courses/14563/gradebook	
staging Barely used	https://torrens-stage.instructure.com/	
** staging Used a lot	https://mylearn-stage.torrens.edu.au/	
** 10 courses to test (Resulting Solution T2 - Test Data)	https://thinkeducation.atlassian.net/wiki/spaces/QA/pages/3010494475/Resulting+Solution+T2+-+Test+Data	
Refresh Timings (MF)	confluence page	
Deploy checklist, rollback plan (MJones)	confluence	
Datetime vs nvarchar columns
See excel above - Datetime columns tab
Resources - Risk Log:

Resources - My tickets
ML-1010 Grade update logic >> done

unit test ml-1010
ML-1011 Approval logic >> done

ML-1012 Banner schedule

discussion meeting required with Ron
Todo research
ML-1074 Grade audit table >> done

ML-1075 Api create

tblUserActionAudit
done
Key places
item	desc
main table	sydaws-DM02.blackboard.dbo.tbl_Student_Final_View
audit table	result.tblStudentFinalViewAudit
system audit table by trigger	dbo.tbl_Student_Final_Viewaudit
main sp	sydaws-DM02.blackboard.dbo.Canvas_Grade_push
banner sp	informatica.sp_student_grade_push
informatica job (prod, current)	Canvas * Exam Portal Data * LT_Push_to_banner_2024
informatica job (prod, new)	Exam portal * m_student_grade_push
Existing db schema - [dbo]
New db schema to add extra tables and procs to upload logic - [result]
Schedule
item	desc
lt1 FETCH	LT_Process_Grades_T3_2022
lt1 schedule	Refresh Notes Column * every 3 hours from 4am
lt2 UPDATE	LT_Canvas_DM02_Sync
lt2 Schedule name	Canvas to DM02 * every 2 hours from 4:20pm
lt3 PUSH	Canvas\Exam Portal Data\LT_Push_to_banner_2024
lt3 schedule	Banner_Grades_Push_Hourly * hourly from 1130am
5 dataset
@isdebug=1 returns 5 dataset
1. tmpResultStatus - records of result status updated
2. tmpApprovalStataus - records of approval status updated
3. tmpFinalGrade (before) - final grade + score (gradecode not updated)
4. tmpFinalGrade (after) - final grade + score (gradecode updated)
5. tbl_student_final_view

Audit table query
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
BAU - VET grades overrides to Fail/HD
chat / reply here

Hi Rose Lennon, I have checked first 2 students and they were pushed as COMPby grading system and didn't get pushed again since 8/9/25. However, I could see what you said (Fail, HD) in banner side. I think some other process is updating this grade. I also see that they are starting updated back to COMP again today, around 10am.
q. Why it didn't create record in audit table?
ans. Audit table record is inserted by dbo.[Canvas_Grade_Push]. If someone manually update final view table and run mapping task manully to push, audit record will not be created.
q. What was the issue?
Some vet records had course type HE
q. Banner shrmrks still has F.
ans. This seems ok with business as long as it shows as VET.
Supplementary
Resources
item	desc
local query	C:\Works\SQLQueries\Blackboard SQL___supplementary.sql	
Smita Vij sample excel file	here	
Deployed columns	tbl_student_final_view.SupplementaryPushDate, StatusID=251	
Deployed sp	result.spUpdateSuplementaryMarkByStudent	
Supplementary meeting KT recording	here	
exec result.spUpdateSuplementaryMarkByStudent 'A00100252','COU304A','253200',50,'SP',1
"Final grade will be given later (Supplementary Pass or Fail) after giving the student 2nd chance"
MF meeting here
COR fire logic
14/8/25
MF requested here

9/9/25

Logic reviewed chat here

ML-952

Meeting minutes with Melissa P melissa-cor-not-firing-09.09.2025_14.00.48_REC

NGP logic
ML-1249

COR logic change
COR cannot be reselected team chat
MF team chat request
ML-1223
ML-1241
Deploy & Rollback plan
Deploy:

todeploy-resulting-project.xlsx
Rollback plan:

Restore Blackboard.dbo.SP_Student_Grade_Push_bak to SP_Student_Grade_Push
Leave all result schema object as they are. Not affected.
Leave oracle job running. Not affected.
MyLearn Schemes
There are 3 pages to check the current schemes:
Account level: 

Course level: 

Each student level: 

/api/saveUserActionAudit
confluence page
For /api/saveUserActionAudit, see mylearn-backend-validate.md

Deployed (torres.dev /api/saveUserActionAudit)
item	desc
api saveUserAction	https://mylearndb-dev.api.torrens.edu.au/backend-validate/api/saveUserActionAudit
x-api-key	0Y9PXGiVwU318ZnFts7an75IDk5u7Y4S4Y163jTh
operation	POST
json body	test.json

[result].[vBannerResponseBackToOracle]
Reduce speed of pull process: LT_Pull_From_Banner_2025 time taken.

Students are receiving FAIL grades when they have passed
Helen Jones wrong alarm about flow

Melissa Pereira reply

This is a case where an LF/approver changed the total directly after the LF/approver approvals were done and  grade pushed into banner. The correct process of going through COR was not followed and total was changed after that approvals so this change will not flow through to final view/banner and hence the discrepancy.
See also Banner GradePush Logic in diagram: Canvas-ERD-personal.vsdx
meeting minutes
10am, 12/9/25, MF, Hemma, MyLearn schema dynamic setup

here