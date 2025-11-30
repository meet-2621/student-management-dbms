# Student Management System (DBMS Project)

## Overview
This project is a **Student Management System** built using **Oracle SQL and PL/SQL**. It is designed to manage academic operations efficiently, including **student enrollment, course and class management, attendance tracking, result calculation, GPA computation, and audit logging**. 

The system demonstrates robust database design, automation with triggers and procedures, and modular programming using packages and functions.

---

## Features
- **Automatic ID generation** using sequences for Students, Courses, Instructors, Classes, Enrollments, Attendance, and Results.
- **Student, Course, Instructor, and Class Management** with relational database integrity.
- **Enrollment Management** with unique student-class combination constraint.
- **Attendance Tracking** (Present, Absent, Late) with daily summaries.
- **Result & Grade Management**:
  - Automatic calculation of Total Marks and Grade via triggers.
- **GPA Calculation**:
  - Weighted GPA based on course credits and marks using a PL/SQL function.
- **Audit Logging**:
  - Tracks all inserts, updates, and deletes in key tables.
- **Views & Reports**:
  - Predefined views for student profiles and class strength.

---

## Technologies Used
- **Oracle SQL**
- **PL/SQL**
- **Sequences, Triggers, Views, Procedures, Functions, Packages**
- **DBMS Concepts:** Primary Keys, Foreign Keys, Unique Constraints, Data Integrity

---

## Database Structure
The system consists of the following tables:
- `Department`
- `Student`
- `Course`
- `Instructor`
- `Class`
- `Enrollment`
- `Attendance`
- `Result`
- `Admin_Audit`

It also includes:
- **Sequences** for automatic ID generation.
- **Triggers** for grade calculation and audit logging.
- **Views** for simplified reporting.
- **Packages** for reusable procedures and functions.

---

## Sample Queries
Some useful queries to test and explore the project:

1. **Student Profiles**
```sql
SELECT * FROM vw_student_profile;
GPA Calculation

SELECT s.FirstName || ' ' || s.LastName AS StudentName,
       pkg_sms.get_student_gpa(s.StudentID) AS GPA
FROM Student s;


Attendance Summary

DECLARE
    v_classid NUMBER;
BEGIN
    SELECT ClassID INTO v_classid FROM Class WHERE ROWNUM = 1;
    proc_attendance_summary(v_classid);
END;
/


Class Strength

SELECT * FROM vw_class_strength;


Student Enrollment

SELECT s.FirstName || ' ' || s.LastName AS StudentName,
       c.CourseID, cl.ClassID, e.Status
FROM Enrollment e
JOIN Student s ON e.StudentID = s.StudentID
JOIN Class cl ON e.ClassID = cl.ClassID
JOIN Course c ON cl.CourseID = c.CourseID;


Result Sheet

SELECT s.FirstName || ' ' || s.LastName AS StudentName,
       r.InternalMarks, r.ExternalMarks, r.TotalMarks, r.Grade
FROM Result r
JOIN Enrollment e ON r.EnrollID = e.EnrollID
JOIN Student s ON e.StudentID = s.StudentID;

Getting Started

Clone the repository:

git clone https://github.com/meet-2621/student-management-dbms


Open in Oracle SQL Developer or any Oracle DB environment.

Execute scripts in order:

Sequences

Tables

Indexes

Views

Triggers

Functions & Procedures

Packages

Sample Data

Run queries to test functionality.

Author

Manmeet Kaur


Passionate about Database Management Systems and PL/SQL Development

License

This project is licensed under the MIT License.
