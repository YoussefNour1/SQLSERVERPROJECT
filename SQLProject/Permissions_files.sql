USE Examination
GO


-- Roles
CREATE ROLE AdminRole;
CREATE ROLE TrainingManagerRole;
CREATE ROLE InstructorRole;
CREATE ROLE StudentRole;

-- SCHEMA
GO
CREATE SCHEMA Instructors;
GO
CREATE SCHEMA Students;
GO
CREATE SCHEMA TrainingManagers;
GO
CREATE SCHEMA DatabaseAdmin;
GO
--Tables That belongs to Admin Schema
ALTER SCHEMA DatabaseAdmin transfer dbo.InsertTraninngManger
ALTER SCHEMA DatabaseAdmin transfer dbo.Department
ALTER SCHEMA DatabaseAdmin transfer dbo.InsertDepartment

--Admins Permissions 
GRANT CONTROL ON SCHEMA::DatabaseAdmin TO AdminRole;
GRANT CONTROL ON SCHEMA::TrainingManagers TO AdminRole;
GRANT CONTROL ON SCHEMA::Instructors TO AdminRole;
GRANT CONTROL ON SCHEMA::Students TO AdminRole;
GRANT EXECUTE ON OBJECT::Instructors.InsertInstructor TO AdminRole;

--Tables That belongs to Training Manager Schema
ALTER SCHEMA TrainingManagers transfer dbo.Training_Manager
ALTER SCHEMA TrainingManagers transfer dbo.Branch
ALTER SCHEMA TrainingManagers transfer dbo.Track
ALTER SCHEMA TrainingManagers transfer dbo.Intake
ALTER SCHEMA TrainingManagers transfer dbo.Update_adds_inbranch
ALTER SCHEMA TrainingManagers transfer dbo.Update_adds_inTrack
ALTER SCHEMA TrainingManagers transfer dbo.Intake_addedby_manager
Alter SCHEMA TrainingManagers transfer dbo.AddNewStudent

-- Training Manager permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::TrainingManagers TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Students.Student TO TrainingManagerRole
GRANT EXECUTE ON OBJECT::Students.AddNewStudent TO TrainingManagerRole


-- Tables That belongs to Instructor
ALTER SCHEMA Instructors TRANSFER dbo.Instructor
ALTER SCHEMA Instructors TRANSFER dbo.Course
ALTER SCHEMA Instructors TRANSFER dbo.Instructor_Courses
ALTER SCHEMA Instructors TRANSFER dbo.Exam
ALTER SCHEMA Instructors TRANSFER dbo.Question
ALTER SCHEMA Instructors TRANSFER dbo.Exam_Question

--Instructor Permissions 
GRANT SELECT,Update ON SCHEMA::Instructors TO InstructorRole
GRANT SELECT ON Students.Student TO InstructorRole
GRANT EXECUTE ON OBJECT::Instructors.AssignInstructorToCourse TO InstructorRole
GRANT EXECUTE ON OBJECT::Instructors.InsertQuestionWithAnswer TO InstructorRole
GRANT SELECT, INSERT, UPDATE, DELETE ON Instructors.Exam TO InstructorRole
GRANT SELECT, INSERT, UPDATE, DELETE ON Instructors.Exam_Question TO InstructorRole
GRANT EXECUTE ON OBJECT::Instructors.CreateExamWithQuestions TO InstructorRole
-- Tables That belongs to Students 
ALTER SCHEMA Students TRANSFER dbo.Student

--Student Permissions
GRANT SELECT ON SCHEMA::Students TO StudentRole;