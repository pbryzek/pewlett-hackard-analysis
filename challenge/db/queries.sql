--------
--Drop Table Queries
DROP TABLE emp_history;
DROP TABLE emp_titles;
DROP TABLE emp_eligibility;
--------
--Create emp_history
--------
SELECT 
	emp.emp_no,
	emp.first_name,
	emp.last_name,
	ti.title,
	ti.from_date,
	sa.salary
INTO emp_history
FROM employees AS emp
INNER JOIN titles ti ON emp.emp_no = ti.emp_no
INNER JOIN dept_emp de ON emp.emp_no = de.emp_no
INNER JOIN salaries sa ON emp.emp_no = sa.emp_no
WHERE de.to_date = '9999-01-01';
--------
-- Partition the data to show only most recent title per employee
--------
SELECT emp_no,
 first_name,
 last_name,
 title,
 from_date
INTO emp_titles
FROM
 (SELECT emp_no,
 first_name,
 last_name,
 title,
 from_date, ROW_NUMBER() OVER
 (PARTITION BY (emp_no)
 ORDER BY from_date DESC) rn
 FROM emp_history
 ) tmp WHERE rn = 1
ORDER BY emp_no;
--------
--Create emp_eligibility table
--------
SELECT 
	emp.emp_no,
	emp.first_name,
	emp.last_name,
	emp.birth_date,
	ti.title,
	ti.from_date,
	ti.to_date
INTO emp_eligibility
FROM employees AS emp
INNER JOIN titles ti ON emp.emp_no = ti.emp_no
INNER JOIN dept_emp de ON emp.emp_no = de.emp_no
WHERE de.to_date = '9999-01-01' AND (emp.birth_date BETWEEN '1965-01-01' AND '1965-12-31');
--------
-- Queries to select from to test newly created tables
--------
SELECT * from emp_eligibility LIMIT 20;
SELECT * from emp_titles LIMIT 20;

-- Helper Query to find the emp_nos that have at least 2 titles.
SELECT
  emp_no,
  count(*)
FROM emp_history
GROUP BY
  emp_no
HAVING count(*) > 1;