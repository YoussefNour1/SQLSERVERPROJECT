/*******************************************************************/
-- Youssef Part
/*
* Instructor can make Exam (For his coLurse only) by selecting number of questions of each type,
the system selects the questions random, or he can select them manually from question pool.
And he must put a degree for each question on the exam, and total degrees must not exceed the
courseMax Degree (One course may has more than one exam).
* For each exam, we should know type (exam or corrective), intake, branch, track, course, start
time, End time, total time and allowance options.
* System should store each exam which defined by year, Course, instructor.
*/
/*******************************************************************/

-- Create Exam table with additional fields
CREATE TABLE Exam (
    Exam_ID INT PRIMARY KEY IDENTITY,
    Exam_Name NVARCHAR(100),
    Course_ID INT,
    Instructor_ID INT,
    Exam_Type NVARCHAR(50) /* Exam, Corrective */,
    Intake INT,
    Branch_ID INT,
    Track_ID INT,
    Start_Time DATETIME,
    End_Time DATETIME,
    Total_Time INT,
    Allowance NVARCHAR(MAX),
    Year INT,
    FOREIGN KEY (Course_ID) REFERENCES Instructors.Course(Crs_ID),
    FOREIGN KEY (Instructor_ID) REFERENCES Instructors.Instructor(Ins_ID),
	FOREIGN KEY (Intake) REFERENCES TrainingManagers.Intake(Intake_id),
	FOREIGN KEY (Branch_ID) REFERENCES TrainingManagers.Branch(Baranch_id),
	FOREIGN KEY (Track_ID) REFERENCES TrainingManagers.Track(Track_id)
);
GO
-- Create Question table with fields for correct answers
CREATE TABLE Question (
    Q_ID INT PRIMARY KEY IDENTITY,
    Q_Text NVARCHAR(MAX),
    Q_Type NVARCHAR(50),
    INS_ID INT,
    Q_Degree INT,
    Correct_Answer NVARCHAR(MAX),
    FOREIGN KEY (INS_ID) REFERENCES Instructors.Instructor(Ins_ID)
);
GO
-- Procedure to insert a new question with correct answer
CREATE PROCEDURE Instructors.InsertQuestionWithAnswer
    @Q_Text NVARCHAR(MAX),
    @Q_Type NVARCHAR(50),
    @INS_ID INT,
    @Q_Degree INT,
    @Correct_Answer NVARCHAR(MAX)
AS
BEGIN
    INSERT INTO Instructors.Question (Q_Text, Q_Type, INS_ID, Q_Degree, Correct_Answer)
    VALUES (@Q_Text, @Q_Type, @INS_ID, @Q_Degree, @Correct_Answer);
END;
GO
----------------------------------------------
--Exam_Question Table
CREATE TABLE Exam_Question (
    Q_ID INT,
    Exam_ID INT,
	Q_Degree int,
    PRIMARY KEY (Q_ID, Exam_ID),
    FOREIGN KEY (Q_ID) REFERENCES Instructors.Question(Q_ID),
	constraint Exam_ID_ques_fk foreign key (Exam_ID)
    references Instructors.Exam(Exam_Id)
);



-- Procedure to create an exam and select questions
CREATE OR ALTER PROCEDURE Instructors.CreateExamWithQuestions
    @Exam_Name NVARCHAR(100),
    @Course_ID INT,
    @Instructor_ID INT,
    @Exam_Type NVARCHAR(50),
    @Intake INT,
    @Branch_ID INT,
    @Track_ID INT,
    @Start_Time DATETIME,
    @End_Time DATETIME,
    @Allowance NVARCHAR(MAX),
    @Year INT,
    @Num_MCQ INT,
    @Num_TrueFalse INT,
    @Num_Essay INT,
    @Manual_Question_IDs NVARCHAR(MAX) = NULL,  -- Comma-separated question IDs if manually selected
    @Degrees NVARCHAR(MAX) = NULL               -- Comma-separated degrees for each question if manually selected
AS
BEGIN
    DECLARE @Exam_ID INT;
    DECLARE @Total_Degrees INT = 0;
    DECLARE @Degree INT;
    DECLARE @ID INT;
    DECLARE @Total_Time INT;
    DECLARE @DegreeList TABLE (Degree INT);

    -- Calculate Total_Time from Start_Time and End_Time
    SET @Total_Time = DATEDIFF(MINUTE, @Start_Time, @End_Time);

    -- Check if the instructor is allowed to create an exam for the specified course
    IF NOT EXISTS (SELECT 1 FROM Instructors.Instructor_Courses WHERE Instructor_ID = @Instructor_ID AND Course_ID = @Course_ID)
    BEGIN
        RAISERROR('The instructor is not allowed to create an exam for this course', 16, 1);
        RETURN;
    END

    -- Insert the exam into the Exam table
    INSERT INTO Instructors.Exam (Exam_Name, Course_ID, Instructor_ID, Exam_Type, Intake, Branch_ID, Track_ID, Start_Time, End_Time, Total_Time, Allowance, Year)
    VALUES (@Exam_Name, @Course_ID, @Instructor_ID, @Exam_Type, @Intake, @Branch_ID, @Track_ID, @Start_Time, @End_Time, @Total_Time, @Allowance, @Year);

    -- Get the newly inserted Exam_ID
    SET @Exam_ID = SCOPE_IDENTITY();

    -- If questions are manually selected
    IF @Manual_Question_IDs IS NOT NULL
    BEGIN
        -- Split the Manual_Question_IDs and Degrees into individual values
        DECLARE @QuestionList TABLE (Q_ID INT, Q_Degree INT);
        DECLARE @Q_IDList NVARCHAR(MAX) = @Manual_Question_IDs;
        DECLARE @Q_DegreeList NVARCHAR(MAX) = @Degrees;
        WHILE CHARINDEX(',', @Q_IDList) > 0
        BEGIN
            SET @ID = CAST(SUBSTRING(@Q_IDList, 1, CHARINDEX(',', @Q_IDList) - 1) AS INT);
            SET @Degree = CAST(SUBSTRING(@Q_DegreeList, 1, CHARINDEX(',', @Q_DegreeList) - 1) AS INT);
            INSERT INTO @QuestionList (Q_ID, Q_Degree) VALUES (@ID, @Degree);
            SET @Q_IDList = SUBSTRING(@Q_IDList, CHARINDEX(',', @Q_IDList) + 1, LEN(@Q_IDList));
            SET @Q_DegreeList = SUBSTRING(@Q_DegreeList, CHARINDEX(',', @Q_DegreeList) + 1, LEN(@Q_DegreeList));
        END

        -- Insert the last pair of ID and Degree
        SET @ID = CAST(@Q_IDList AS INT);
        SET @Degree = CAST(@Q_DegreeList AS INT);
        INSERT INTO @QuestionList (Q_ID, Q_Degree) VALUES (@ID, @Degree);

        -- Insert into Exam_Question and update total degrees
        INSERT INTO Instructors.Exam_Question (Q_ID, Exam_ID, Q_Degree)
        SELECT Q_ID, @Exam_ID, Q_Degree FROM @QuestionList;
        SET @Total_Degrees = (SELECT SUM(Q_Degree) FROM @QuestionList);
    END
    ELSE
    BEGIN
        -- Randomly select questions
        -- Select MCQ questions
        INSERT INTO Instructors.Exam_Question (Q_ID, Exam_ID, Q_Degree)
        SELECT TOP (@Num_MCQ) Q_ID, @Exam_ID, Q_Degree FROM Question WHERE Q_Type = 'MCQ' AND INS_ID = @Instructor_ID ORDER BY NEWID();

        -- Select True/False questions
        INSERT INTO Instructors.Exam_Question (Q_ID, Exam_ID, Q_Degree)
        SELECT TOP (@Num_TrueFalse) Q_ID, @Exam_ID, Q_Degree FROM Question WHERE Q_Type = 'True/False' AND INS_ID = @Instructor_ID ORDER BY NEWID();

        -- Select Essay questions
        INSERT INTO Instructors.Exam_Question (Q_ID, Exam_ID, Q_Degree)
        SELECT TOP (@Num_Essay) Q_ID, @Exam_ID, Q_Degree FROM Question WHERE Q_Type = 'Essay' AND INS_ID = @Instructor_ID ORDER BY NEWID();

        -- Calculate total degrees for randomly selected questions
        SET @Total_Degrees = (SELECT SUM(Q_Degree) FROM Exam_Question WHERE Exam_ID = @Exam_ID);
    END

    -- Check if Total Degrees exceed Course Max Degree
    DECLARE @Max_Degree INT;
    SELECT @Max_Degree = Max_Degree FROM Course WHERE Crs_ID = @Course_ID;

    IF @Total_Degrees > @Max_Degree
    BEGIN
        RAISERROR('Total degrees exceed the course max degree', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO
--------------------------------------------------------------
-- Function to get all exam details 
CREATE FUNCTION Instructors.GetExamDetails(@Exam_ID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        E.Exam_ID,
        E.Exam_Name,
        E.Course_ID,
        C.Crs_name AS Course_Name,
        E.Instructor_ID,
        I.Ins_FName + ' ' + I.Ins_LName AS Instructor_Name,
        E.Exam_Type,
        E.Intake,
        E.Branch_ID,
        E.Track_ID,
        E.Start_Time,
        E.End_Time,
        E.Total_Time,
        E.Allowance,
        E.Year,
        EQ.Q_ID,
        Q.Q_Text,
        Q.Q_Type,
        EQ.Q_Degree,
        Q.Correct_Answer
    FROM
        Exam E
        JOIN Instructors.Course C ON E.Course_ID = C.Crs_ID
        JOIN Instructors.Instructor I ON E.Instructor_ID = I.Ins_ID
        JOIN Instructors.Exam_Question EQ ON E.Exam_ID = EQ.Exam_ID
        JOIN Instructors.Question Q ON EQ.Q_ID = Q.Q_ID
    WHERE
        E.Exam_ID = @Exam_ID
);
GO

-- function to search for a specific keyword in question table 
CREATE FUNCTION Instructors.SearchQuestionsByKeyword(@Keyword NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
(
    SELECT
        Q.Q_ID,
        Q.Q_Text,
        Q.Q_Type,
        Q.INS_ID,
        Q.Q_Degree,
        Q.Correct_Answer
    FROM
        Instructors.Question Q
    WHERE
        Q.Q_Text LIKE '%' + @Keyword + '%'
);
GO

/******************** Indexers *************************/
-- Department indexers 
-- Index on Dept_name for searching by department name
CREATE INDEX IX_Department_Dept_name ON DatabaseAdmin.Department (Dept_name);

-- Index on Dept_location for filtering by department location
CREATE INDEX IX_Department_Dept_location ON DatabaseAdmin.Department (Dept_location);
GO

-- Training_Manager indexers 
-- Index on Email for efficient lookups by email
CREATE INDEX IX_Training_Manager_Email ON TrainingManagers.Training_Manager (Email);
Go
-- Index on Manager_Fname and Manager_Lname for searching by name
CREATE INDEX IX_Training_Manager_Name ON TrainingManagers.Training_Manager (Manager_Fname, Manager_Lname);
GO

-- Branch indexers
-- Index on dept_id for joining with Department table
CREATE INDEX IX_Branch_dept_id ON TrainingManagers.Branch (dept_id);
GO

-- Student Indexers 
-- Index on Email for efficient lookups by email
CREATE INDEX IX_Student_Email ON Students.Student (Email);
-- Index on Dept_ID, Intake_ID, Track_ID, Manager_ID, and Branch_ID for joins and filtering
CREATE INDEX IX_Student_Dept_ID ON Students.Student (Dept_ID);
CREATE INDEX IX_Student_Intake_ID ON Students.Student (Intake_ID);
CREATE INDEX IX_Student_Track_ID ON Students.Student (Track_ID);
CREATE INDEX IX_Student_Manager_ID ON Students.Student (Manager_ID);
CREATE INDEX IX_Student_Branch_ID ON Students.Student (Branch_ID);
GO

-- Instructor Indexers 
-- Index on Email for efficient lookups by email
CREATE INDEX IX_Instructor_Email ON Instructors.Instructor (Email);
-- Index on Dept_ID for joining with Department table
CREATE INDEX IX_Instructor_Dept_ID ON Instructors.Instructor (Dept_ID);
GO

-- Instructor_Courses indexers
-- Composite index on Instructor_ID and Course_ID for efficient lookups and joins
CREATE INDEX IX_Instructor_Courses_Instructor_Course ON Instructors.Instructor_Courses (Instructor_ID, Course_ID);
GO

-- Question indexers 
-- an index on Q_ID column
CREATE INDEX IX_Question_Q_Text ON Instructors.Question ([Q_ID]);
GO

-- an index on INS_ID column for filtering by instructor
CREATE INDEX IX_Question_INS_ID ON Instructors.Question (INS_ID);
GO

-- Exam Indexers 
-- Create an index on Course_ID column for filtering by course
CREATE INDEX IX_Exam_Course_ID ON Instructors.Exam (Course_ID);
GO
-- an index on Instructor_ID column for filtering by instructor
CREATE INDEX IX_Exam_Instructor_ID ON Instructors.Exam (Instructor_ID);
GO
-- an index on Start_Time and End_Time columns for filtering by time range
CREATE INDEX IX_Exam_Start_End_Time ON Instructors.Exam (Start_Time, End_Time);
GO

-- Exam_Question Indexers
-- an index on Exam_ID column for filtering by exam
CREATE INDEX IX_Exam_Question_Exam_ID ON Instructors.Exam_Question (Exam_ID);
GO
-- an index on Q_ID column for filtering by question
CREATE INDEX IX_Exam_Question_Q_ID ON Instructors.Exam_Question (Q_ID);
GO

-- Instructor_Courses Indexers 
-- a composite index on Ins_ID and Crs_ID columns for instructor-course relationships
CREATE INDEX IX_Instructor_Courses_Ins_Crs ON Instructors.Instructor_Courses (Instructor_ID, Course_ID);
GO
