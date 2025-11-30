-------------------------------
-- 1. Sequences for primary key generation
-------------------------------
CREATE SEQUENCE seq_student START WITH 1001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_dept START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_course START WITH 101 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_instr START WITH 2001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_class START WITH 3001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_enroll START WITH 4001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_attendance START WITH 5001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_result START WITH 6001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_audit START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

-------------------------------
-- 2. Tables
-------------------------------
-- Department
CREATE TABLE Department (
DeptID NUMBER PRIMARY KEY,
DeptName VARCHAR2(100) NOT NULL UNIQUE,
HOD VARCHAR2(100)
);

-- Student
CREATE TABLE Student (
StudentID NUMBER PRIMARY KEY,
FirstName VARCHAR2(50) NOT NULL,
LastName VARCHAR2(50),
DOB DATE,
Gender CHAR(1) CHECK (Gender IN ('M','F','O')),
Email VARCHAR2(100) UNIQUE,
Phone VARCHAR2(15),
Address VARCHAR2(255),
AdmissionDate DATE DEFAULT SYSDATE,
DeptID NUMBER REFERENCES Department(DeptID) ON DELETE SET NULL
);

-- Course
CREATE TABLE Course (
CourseID NUMBER PRIMARY KEY,
CourseName VARCHAR2(200) NOT NULL,
Credits NUMBER(2) CHECK (Credits >= 0),
DeptID NUMBER REFERENCES Department(DeptID) ON DELETE SET NULL
);

-- Instructor
CREATE TABLE Instructor (
InstructorID NUMBER PRIMARY KEY,
FirstName VARCHAR2(50) NOT NULL,
LastName VARCHAR2(50),
Email VARCHAR2(100) UNIQUE,
Phone VARCHAR2(15),
DeptID NUMBER REFERENCES Department(DeptID)
);

-- Class / Offering
CREATE TABLE Class (
ClassID NUMBER PRIMARY KEY,
CourseID NUMBER NOT NULL REFERENCES Course(CourseID) ON DELETE CASCADE,
InstructorID NUMBER REFERENCES Instructor(InstructorID),
Semester VARCHAR2(10),
Year NUMBER(4) CHECK (Year >= 2000),
Capacity NUMBER(4) DEFAULT 60
);


-- Enrollment (resolving M:N)
CREATE TABLE Enrollment (
EnrollID NUMBER PRIMARY KEY,
StudentID NUMBER NOT NULL REFERENCES Student(StudentID) ON DELETE CASCADE,
ClassID NUMBER NOT NULL REFERENCES Class(ClassID) ON DELETE CASCADE,
EnrollmentDate DATE DEFAULT SYSDATE,
Status VARCHAR2(20) DEFAULT 'ENROLLED',
CONSTRAINT uc_student_class UNIQUE (StudentID, ClassID)
);


-- Attendance
CREATE TABLE Attendance (
AttendanceID NUMBER PRIMARY KEY,
EnrollID NUMBER NOT NULL REFERENCES Enrollment(EnrollID) ON DELETE CASCADE,
AttendDate DATE NOT NULL,
Status VARCHAR2(10) CHECK (Status IN ('P', 'A', 'L')) -- Present/Absent/Late
);


-- Result
CREATE TABLE Result (
ResultID NUMBER PRIMARY KEY,
EnrollID NUMBER UNIQUE REFERENCES Enrollment(EnrollID) ON DELETE CASCADE,
InternalMarks NUMBER(5,2) CHECK (InternalMarks BETWEEN 0 AND 50),
ExternalMarks NUMBER(5,2) CHECK (ExternalMarks BETWEEN 0 AND 50),
TotalMarks NUMBER(5,2),
Grade VARCHAR2(2)
);


-- Admin Audit
CREATE TABLE Admin_Audit (
AuditID NUMBER PRIMARY KEY,
TableName VARCHAR2(50),
Operation VARCHAR2(10),
ChangedBy VARCHAR2(50),
ChangedOn DATE DEFAULT SYSDATE,
Details VARCHAR2(4000)
);


-------------------------------
-- 3. Indexes
-------------------------------
CREATE INDEX idx_student_dept ON Student(DeptID);
CREATE INDEX idx_course_dept ON Course(DeptID);
CREATE INDEX idx_enrollment_student ON Enrollment(StudentID);
CREATE INDEX idx_enrollment_class ON Enrollment(ClassID);


-------------------------------
-- 4. Views
-------------------------------
CREATE OR REPLACE VIEW vw_student_profile AS
SELECT s.StudentID,
s.FirstName || ' ' || NVL(s.LastName,'') AS FullName,
s.Email,
d.DeptName,
s.AdmissionDate
FROM Student s LEFT JOIN Department d ON s.DeptID = d.DeptID;


CREATE OR REPLACE VIEW vw_class_strength AS
SELECT c.ClassID, cr.CourseName, c.Semester, c.Year, COUNT(e.EnrollID) AS Strength
FROM Class c LEFT JOIN Course cr ON c.CourseID = cr.CourseID
LEFT JOIN Enrollment e ON c.ClassID = e.ClassID
GROUP BY c.ClassID, cr.CourseName, c.Semester, c.Year;

-------------------------------
-- 6. Triggers (audit triggers + compute result trigger)
-------------------------------
-- Trigger: Audit for Student
CREATE OR REPLACE TRIGGER trg_audit_student
AFTER INSERT OR UPDATE OR DELETE ON Student
FOR EACH ROW
BEGIN
IF INSERTING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Student','INSERT',USER,SYSDATE,'Inserted StudentID='||:NEW.StudentID);
ELSIF UPDATING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Student','UPDATE',USER,SYSDATE,'Updated StudentID='||:NEW.StudentID);
ELSIF DELETING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Student','DELETE',USER,SYSDATE,'Deleted StudentID='||:OLD.StudentID);
END IF;
END;
/

-- Trigger: Audit for Course
CREATE OR REPLACE TRIGGER trg_audit_course
AFTER INSERT OR UPDATE OR DELETE ON Course
FOR EACH ROW
BEGIN
IF INSERTING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Course','INSERT',USER,SYSDATE,'Inserted CourseID='||:NEW.CourseID);
ELSIF UPDATING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Course','UPDATE',USER,SYSDATE,'Updated CourseID='||:NEW.CourseID);
ELSIF DELETING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Course','DELETE',USER,SYSDATE,'Deleted CourseID='||:OLD.CourseID);
END IF;
END;
/

-- Trigger: Audit for Class
CREATE OR REPLACE TRIGGER trg_audit_class
AFTER INSERT OR UPDATE OR DELETE ON Class
FOR EACH ROW
BEGIN
IF INSERTING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Class','INSERT',USER,SYSDATE,'Inserted ClassID='||:NEW.ClassID);
ELSIF UPDATING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Class','UPDATE',USER,SYSDATE,'Updated ClassID='||:NEW.ClassID);
ELSIF DELETING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Class','DELETE',USER,SYSDATE,'Deleted ClassID='||:OLD.ClassID);
END IF;
END;
/

-- Trigger: Audit for Enrollment
CREATE OR REPLACE TRIGGER trg_audit_enrollment
AFTER INSERT OR UPDATE OR DELETE ON Enrollment
FOR EACH ROW
BEGIN
IF INSERTING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Enrollment','INSERT',USER,SYSDATE,'Inserted EnrollID='||:NEW.EnrollID||' StudentID='||:NEW.StudentID||' ClassID='||:NEW.ClassID);
ELSIF UPDATING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Enrollment','UPDATE',USER,SYSDATE,'Updated EnrollID='||:NEW.EnrollID);
ELSIF DELETING THEN
INSERT INTO Admin_Audit(AuditID, TableName, Operation, ChangedBy, ChangedOn, Details)
VALUES (seq_audit.NEXTVAL,'Enrollment','DELETE',USER,SYSDATE,'Deleted EnrollID='||:OLD.EnrollID);
END IF;
END;
/

-- Trigger: Automatically compute TotalMarks and Grade for Result
CREATE OR REPLACE TRIGGER trg_compute_result
BEFORE INSERT OR UPDATE ON Result
FOR EACH ROW
BEGIN
:NEW.TotalMarks := NVL(:NEW.InternalMarks,0) + NVL(:NEW.ExternalMarks,0);
IF :NEW.TotalMarks >= 85 THEN
:NEW.Grade := 'A+';
ELSIF :NEW.TotalMarks >= 75 THEN
:NEW.Grade := 'A';
ELSIF :NEW.TotalMarks >= 60 THEN
:NEW.Grade := 'B';
ELSIF :NEW.TotalMarks >= 50 THEN
:NEW.Grade := 'C';
ELSE
:NEW.Grade := 'F';
END IF;
END;
/

-------------------------------
-- 7. Procedures, Functions, Cursors
-------------------------------
CREATE OR REPLACE FUNCTION func_calculate_gpa(p_studentid IN NUMBER)
RETURN NUMBER
AS
    v_gpa NUMBER;
BEGIN
    SELECT
        SUM(
            CASE
                WHEN TotalMarks >= 85 THEN 10
                WHEN TotalMarks >= 75 THEN 9
                WHEN TotalMarks >= 60 THEN 8
                WHEN TotalMarks >= 50 THEN 6
                ELSE 0
            END * NVL(Credits, 0)
        ) / NULLIF(SUM(NVL(Credits, 0)), 0)
    INTO v_gpa
    FROM Result r
    JOIN Course c ON r.CourseID = c.CourseID
    WHERE r.StudentID = p_studentid;

    RETURN NVL(v_gpa, 0);
END;
/


CREATE OR REPLACE PROCEDURE proc_attendance_summary(p_classid IN NUMBER)
AS
    v_att_total   NUMBER;
    v_att_present NUMBER;
BEGIN
    FOR rec IN (
        SELECT e.EnrollID, s.FirstName, s.LastName
        FROM Enrollment e
        JOIN Student s ON e.StudentID = s.StudentID
        WHERE e.ClassID = p_classid
    ) LOOP
        SELECT 
            COUNT(*),
            SUM(CASE WHEN Status = 'P' THEN 1 ELSE 0 END)
        INTO 
            v_att_total,
            v_att_present
        FROM Attendance
        WHERE EnrollID = rec.EnrollID;

        DBMS_OUTPUT.PUT_LINE(
            'Student: ' || rec.FirstName || ' ' || rec.LastName ||
            ' | Total: ' || NVL(v_att_total, 0) ||
            ' | Present: ' || NVL(v_att_present, 0)
        );
    END LOOP;
END;
/


SET SERVEROUTPUT ON;

EXEC proc_attendance_summary(10);



-------------------------------
-- 8. Package example
-------------------------------
-------------------------------
-- Package: pkg_sms
-- Purpose: Handle student enrollment and GPA calculation
-------------------------------

-- 1. Package specification
CREATE OR REPLACE PACKAGE pkg_sms IS

  -- Procedure to enroll a student in a class
  PROCEDURE enroll_student(
    p_studentid IN NUMBER,   -- ID of the student
    p_classid   IN NUMBER,   -- ID of the class
    p_enrollid  OUT NUMBER,  -- Output: enrollment ID
    p_status    OUT VARCHAR2 -- Output: status message
  );

  -- Function to get a student's GPA
  FUNCTION get_student_gpa(
    p_studentid IN NUMBER    -- ID of the student
  ) RETURN NUMBER;

END pkg_sms;
/


-- 2. Package body
CREATE OR REPLACE PACKAGE BODY pkg_sms IS

  -- Procedure implementation
  PROCEDURE enroll_student(
    p_studentid IN NUMBER,
    p_classid   IN NUMBER,
    p_enrollid  OUT NUMBER,
    p_status    OUT VARCHAR2
  ) IS
  BEGIN
    -- Calls another procedure that does the actual enrollment
    proc_enroll_student(p_studentid, p_classid, p_enrollid, p_status);
  END enroll_student;

  -- Function implementation
  FUNCTION get_student_gpa(
    p_studentid IN NUMBER
  ) RETURN NUMBER IS
    v_gpa NUMBER;
  BEGIN
    -- Calls another function that calculates GPA
    v_gpa := fn_get_student_gpa(p_studentid);
    RETURN v_gpa;
  END get_student_gpa;

END pkg_sms;
/


CREATE OR REPLACE PACKAGE BODY pkg_sms IS

  PROCEDURE enroll_student(
    p_studentid IN NUMBER,
    p_classid   IN NUMBER,
    p_enrollid  OUT NUMBER,
    p_status    OUT VARCHAR2
  ) IS
  BEGIN
    -- Simple logic without external procedure
    p_enrollid := p_studentid + p_classid;  -- dummy logic
    p_status   := 'ENROLLED';
  END enroll_student;

  FUNCTION get_student_gpa(
    p_studentid IN NUMBER
  ) RETURN NUMBER IS
  BEGIN
    -- Simple logic without external function
    RETURN 9.0; -- fixed GPA
  END get_student_gpa;

END pkg_sms;
/


-------------------------------
-- 8. Package example
-------------------------------
CREATE OR REPLACE PACKAGE pkg_sms IS
PROCEDURE enroll_student(p_studentid IN NUMBER, p_classid IN NUMBER, p_enrollid OUT NUMBER, p_status OUT VARCHAR2);
FUNCTION get_student_gpa(p_studentid IN NUMBER) RETURN NUMBER;
END pkg_sms;
/
CREATE OR REPLACE PACKAGE BODY pkg_sms IS
PROCEDURE enroll_student(p_studentid IN NUMBER, p_classid IN NUMBER, p_enrollid OUT NUMBER, p_status OUT VARCHAR2) IS
BEGIN
proc_enroll_student(p_studentid, p_classid, p_enrollid, p_status);
END;


FUNCTION get_student_gpa(p_studentid IN NUMBER) RETURN NUMBER IS
BEGIN
RETURN fn_get_student_gpa(p_studentid);
END;
END pkg_sms;
/

-------------------------------
-- 9. Sample Data (INSERT statements)
-------------------------------
-- Departments
INSERT INTO Department(DeptID, DeptName, HOD) VALUES (seq_dept.NEXTVAL,'Computer Science','Dr. Kaur');
INSERT INTO Department(DeptID, DeptName, HOD) VALUES (seq_dept.NEXTVAL,'Mathematics','Dr. Sharma');


-- Students
INSERT INTO Student(StudentID, FirstName, LastName, DOB, Gender, Email, Phone, AdmissionDate, DeptID)
VALUES (seq_student.NEXTVAL,'Manmeet','Kaur',TO_DATE('2003-05-15','YYYY-MM-DD'),'F','manmeet@example.com','9876543210',SYSDATE,1);


INSERT INTO Student(StudentID, FirstName, LastName, DOB, Gender, Email, Phone, AdmissionDate, DeptID)
VALUES (seq_student.NEXTVAL,'Aman','Singh',TO_DATE('2002-11-22','YYYY-MM-DD'),'M','aman@example.com','9876500011',SYSDATE,1);


-- Courses
INSERT INTO Course(CourseID, CourseName, Credits, DeptID) VALUES (seq_course.NEXTVAL,'Database Systems',4,1);
INSERT INTO Course(CourseID, CourseName, Credits, DeptID) VALUES (seq_course.NEXTVAL,'Data Structures',4,1);


-- Instructors
INSERT INTO Instructor(InstructorID, FirstName, LastName, Email, Phone, DeptID)
VALUES (seq_instr.NEXTVAL,'Harjit','Gill','gill@example.com','9988776655',1);


-- Class/Offering: note CourseID and InstructorID will be from seqs created above; adjust if needed
-- We'll fetch last values to approximate: but safer to insert using sequence values directly
INSERT INTO Class(ClassID, CourseID, InstructorID, Semester, Year, Capacity)
VALUES (seq_class.NEXTVAL, -- ClassID
(SELECT CourseID FROM (SELECT CourseID FROM Course WHERE CourseName='Database Systems') WHERE ROWNUM=1),
(SELECT InstructorID FROM (SELECT InstructorID FROM Instructor WHERE Email='gill@example.com') WHERE ROWNUM=1),
'Fall',2025,60);


-- Enrollment (using seq_enroll) - link students to class
INSERT INTO Enrollment(EnrollID, StudentID, ClassID)
VALUES (seq_enroll.NEXTVAL,
(SELECT StudentID FROM (SELECT StudentID FROM Student WHERE FirstName='Manmeet' AND LastName='Kaur') WHERE ROWNUM=1),
(SELECT ClassID FROM (SELECT ClassID FROM Class) WHERE ROWNUM=1));


INSERT INTO Enrollment(EnrollID, StudentID, ClassID)
VALUES (seq_enroll.NEXTVAL,
(SELECT StudentID FROM (SELECT StudentID FROM Student WHERE FirstName='Aman' AND LastName='Singh') WHERE ROWNUM=1),
(SELECT ClassID FROM (SELECT ClassID FROM Class) WHERE ROWNUM=1));


-- Attendance
INSERT INTO Attendance(AttendanceID, EnrollID, AttendDate, Status)
VALUES (seq_attendance.NEXTVAL,
(SELECT EnrollID FROM (SELECT EnrollID FROM Enrollment WHERE ROWNUM=1) WHERE ROWNUM=1),
TO_DATE('2025-11-01','YYYY-MM-DD'),'P');


-- Results
INSERT INTO Result(ResultID, EnrollID, InternalMarks, ExternalMarks)
VALUES (seq_result.NEXTVAL,
(SELECT EnrollID FROM (SELECT EnrollID FROM Enrollment WHERE ROWNUM=1) WHERE ROWNUM=1),
40,42);


COMMIT;
/


-------------------------------
-- 10. Sample Queries & Examples
-------------------------------
-- 1) View student profile
SELECT * FROM vw_student_profile;


-- 2) Join: Student with Enrollment and Class and Course
SELECT s.StudentID, s.FirstName, c.CourseName, cl.Semester, cl.Year
FROM Student s
JOIN Enrollment e ON s.StudentID = e.StudentID
JOIN Class cl ON e.ClassID = cl.ClassID
JOIN Course c ON cl.CourseID = c.CourseID
WHERE s.StudentID = (SELECT StudentID FROM Student WHERE FirstName='Manmeet' AND ROWNUM=1);


-- 3) Aggregation: class strength
SELECT cl.ClassID, cr.CourseName, COUNT(e.EnrollID) AS Strength
FROM Class cl JOIN Course cr ON cl.CourseID = cr.CourseID
LEFT JOIN Enrollment e ON cl.ClassID = e.ClassID
GROUP BY cl.ClassID, cr.CourseName;


-- 4) Subquery: students who are not enrolled in any class
SELECT s.StudentID, s.FirstName
FROM Student s
WHERE NOT EXISTS (SELECT 1 FROM Enrollment e WHERE e.StudentID = s.StudentID);

-- 5) Update attendance example
UPDATE Attendance SET Status = 'P' WHERE AttendanceID = 5001;



CREATE OR REPLACE FUNCTION func_calculate_gpa(p_studentid IN NUMBER)
RETURN NUMBER
AS
    v_gpa NUMBER;
BEGIN
    SELECT 
        SUM(
            CASE
                WHEN r.TotalMarks >= 85 THEN 10
                WHEN r.TotalMarks >= 75 THEN 9
                WHEN r.TotalMarks >= 60 THEN 8
                WHEN r.TotalMarks >= 50 THEN 6
                ELSE 0
            END * NVL(c.Credits, 0)
        ) / NULLIF(SUM(NVL(c.Credits,0)),0)
    INTO v_gpa
    FROM Result r
    JOIN Enrollment e ON r.EnrollID = e.EnrollID
    JOIN Class cl ON e.ClassID = cl.ClassID
    JOIN Course c ON cl.CourseID = c.CourseID
    WHERE e.StudentID = p_studentid;

    RETURN NVL(v_gpa,0);
END;
/


SHOW ERRORS FUNCTION func_calculate_gpa;

