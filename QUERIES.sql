--1. Student Profiles
SELECT * FROM vw_student_profile;

--2. GPA Calculation
SELECT s.FirstName || ' ' || s.LastName AS StudentName,
       pkg_sms.get_student_gpa(s.StudentID) AS GPA
FROM Student s;


--3. Attendance Summary for a Class
SET SERVEROUTPUT ON;
DECLARE
    v_classid NUMBER;
BEGIN
    SELECT ClassID INTO v_classid FROM Class WHERE ROWNUM = 1;
    proc_attendance_summary(v_classid);
END;
/


--4. Class Strength (Number of Students per Class)
SELECT * FROM vw_class_strength;

--5. Student Enrollment
SELECT s.FirstName || ' ' || s.LastName AS StudentName,
       c.CourseID, cl.ClassID, e.Status
FROM Enrollment e
JOIN Student s ON e.StudentID = s.StudentID
JOIN Class cl ON e.ClassID = cl.ClassID
JOIN Course c ON cl.CourseID = c.CourseID;

--6. Result Sheet with Grades
SELECT s.FirstName || ' ' || s.LastName AS StudentName,
       r.InternalMarks, r.ExternalMarks, r.TotalMarks, r.Grade
FROM Result r
JOIN Enrollment e ON r.EnrollID = e.EnrollID
JOIN Student s ON e.StudentID = s.StudentID;