# Bootcamp: UCB-VIRT-DATA-PT-03-2020-U-B-TTH
## Bootcamp Challenge #7 - 4/26/2020
Bootcamp Challenge 7: Module pewlett-hackard-analysis

### Dataset Used
- [departments.csv](https://courses.bootcampspot.com/courses/140/files/35977)
- [dept_emp.csv](https://courses.bootcampspot.com/courses/140/files/35983)
- [dept_manager.csv](https://courses.bootcampspot.com/courses/140/files/35979)
- [employees.csv](https://courses.bootcampspot.com/courses/140/files/36133)
- [salaries.csv](https://courses.bootcampspot.com/courses/140/files/36560)
- [titles.csv](https://courses.bootcampspot.com/courses/140/files/36723)

### Challenge Description
Bobby’s new assignment consists of three parts: two additional analyses and a technical report to deliver the results to his manager. To help him complete these tasks, you will submit the following deliverables:

- Delivering Results: A README.md in the form of a technical report that details your analysis and findings
- Technical Analysis Deliverable 1: Number of Retiring Employees by Title. A table containing the number of employees who are about to retire, grouped by job title (and the CSV containing the data)
- Technical Analysis Deliverable 2: Mentorship Eligibility. A table containing employees who are eligible for the mentorship program (and the CSV containing the data)
- Table 1 will contain the number of current employees who are about to retire, grouped by job title.
- Table 2 will list those employees from Table 1 who are eligible for the mentorship program.

### Challenge Findings
#### EmployeeDB ERD
![EmployeeDB](./analysis/EmployeeDB.png)
#### .CSVs Generated
[emp_eligibility](./analysis/emp_eligibility.csv)
</br>
[emp_history](./analysis/emp_history.csv)
</br>
[emp_titles](./analysis/emp_titles.csv)
</br>

### Pewlett Hackard Raw Data Table Name: Description
These tables were created to support the raw data import .CSV files. These are the raw data files obtained from the enterprise 
- employees: Information on each employee of Pewlett Hackard including full name, birth date, an unique employee number, gender, and his corresponding hire date. This table is where the unique employer number originates from.
- titles: The primary key is formed from a composite of the emp_no, title, and from_date because the same employee could have had different titles, or same title at different times; consequently, all three are required for an unique title entry. This table also provides the corresponding ending date of that title. If the title is the current title for that employee, the end_date is set to a future date of '9999-01-01'.
- salaries: This table holds all the salaries for the employees of Pewlett Hackard. In this table the primary key is emp_no, unlike the titles table that used three columns for a composite key. This implies that the company never gives out salary increases, instead only offering title changes. This table holds the dates that salary for that employee was valid for.
- departments: Simple table that maps the company's nine departments to a unique department number.
- dept_emp: Primary key is a composite of the unique employer number (foreign key to the Employers table) and the unique deptartment number (foreign key to departments table). This table holds the employees for the different departments.
- dept_manager: Primary key is a composite of the unique employer number (foreign key to the Employers table) and the unique deptartment number (foreign key to departments table). This table holds the managers for the different departments.

### PostGres Queries: Dynamic Tables generated:
#### Table: emp_history
**Description**
This purpose of the emp_history query is to combine various fields regarding the same employee into a new table. It uses three inner joins to get data from employees, titles, dept_emp, and salaries tables - all joined on the unique emp_no. This table holds the relevant info for employees accounting for all their various titles held within the company. The de.to_date where clause is the bit in the query that results only in current employees in the company i.e. those that do not have an end_date set.
</br>
**Query**
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
</br>
#### Table: emp_titles
</br>
**Description**
</br>
The emp_titles table is a partition table from emp_history, accounting only for the most recent (current) employee title. This is relevant as the same employee (emp_no) may have had multiple titles over time at this company.
</br>
**Query**
</br>
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
</br>
#### Table: emp_eligibility
**Description**
The emp_eligibility holds rows for all the employees taking into account their current title info as held in emp_titles table. There is a layer of filtering applied to the employee's birth dates to take into account only those emplloyees born in 1965.
</br>

**Query**
SELECT 
	emp_title.emp_no,
	emp_title.first_name,
	emp_title.last_name,
	emp.birth_date,
	emp_title.title,
	emp_title.from_date,
	de.to_date
INTO emp_eligibility
FROM emp_titles AS emp_title
INNER JOIN dept_emp de ON emp_title.emp_no = de.emp_no
INNER JOIN employees emp ON emp.emp_no = emp_title.emp_no
WHERE de.to_date = '9999-01-01' AND (emp.birth_date BETWEEN '1965-01-01' AND '1965-12-31');
</br>

### Challenge Analysis
For the week 7 challenge, we were instructed to assist Bobby's manager to determine how many roles will soon need to be filled as the "silver tsunami" begins to make an impact at his enterprise employer: Pewlett Hackard. The silver tsunami refers to the phenomenon they are experiencing as a significant proportion of their employees are set to retire, leaving major gaps to fill littered across the enterprise. Bobby's manager is interested in getting the full list of current employees born in 1965, making them eligible for retirement. 

To analytically answer this request, I started with the datasets obtained in .CSV form for the tables as described above in the Table Names: Description section. Based on the CSVs provided, I created schema tables in PostGres that correspond to the dataset received. After inspecting the various tables imported via pgAdmin tool, it was important to get an understanding for how the various tables are connected via foreign keys. After inspecting the data imported to the 6 original tables, I ran the emp_history query as provided above. This query created a new table emp_history which provides a row for every single title that any employee held over time at Pewlett Hackard. The next query run was the emp_titles query as provided above. This query creates a new partition table by filtering out the most recent entry for each emp_no in the emp_history table. The emp_titles table thus holds the most recent (current) title for each employee along with other pertinent employee data points. This table resolved the issue of duplicates in the emp_history table. Finally, one more table partition was needed to filter out those employees with birth dates in 1965 i.e. those that will become eligible to retire. The emp_eligibility table was created by taking the rows in the emp_titles tables, joining it to the employees table, and filtering out those employees who had birth dates in 1965, since the birth_date info was stored in the original employees table, that is where the birth_date filtering occurred. 

**Analytics Queries**
<br/>
q: SELECT count(1) FROM employees;
<br/>
d: Running an inital query on the employees table shows that this table holds a set of 300,024 employee rows.
<br/>
<br/>
q: SELECT count(1) FROM emp_titles;
<br/>
d: Running a query on the employee title table shows there are 240,142 employees with a current title.
<br/>
<br/>
q: SELECT count(1) FROM emp_eligibility;
<br/>
d: Inital query on the emp_eligibility table shows a set of 1,549 active employees who have a birth_date in 1965.
<br/>
<br/>
q: SELECT title, count(*) from emp_eligibility GROUP BY title;
<br/>
<br/>
"Assistant Engineer" 29
"Staff"	155
"Senior Staff"	569
"Technique Leader" 77
"Engineer" 190
"Senior Engineer" 529
<br/>
<br/>
q: SELECT title, count(*) from emp_titles GROUP BY title;
<br/>
d: This query results in the number of titles currently employed by PH.
<br/>

One immediate limitation of the analysis of this challenge is that when analyzing the impact of the silver tsunami, we only took into account those employees turning 65 this year. This segment of 1,549 represents only those currently employed and turning 65 this year - it fails to account for any current employee over the age of 65. At a macro level, we can see that there are 1,549 eligibile employees for retirement out of 240,142 employees with a current job title. 
<br/>
<br/>
At a macro level this shows that 1,549 / 240,142 or .645% of the employee population, less than 1% of the employees. From the group by title query on the emp_eligibility table, it provides a breakdown of the different job titles that have current employees eligible to retire. We can see the following distributions, when taking into each job title's eligibility divided by the total eligible (1,549). 
<br/>
<br/>
**(job title eligibility)/(total eligibility)**
- Assistant Engineer: 29; 1.87% 
- Staff: 155; 10.01%
- Senior Staff: 569; 36.73%
- Technique Leader: 77; 4.97%
- Engineer: 190; 12.27%
- Senior Engineer 529; 34.15%
<br/>
The previous query shows that Senior Staff is the title type that has the largest percentage (36.7%) of employees that is set to become retirement eligible. Senior Engineer shows the 2nd highest percentage (34.15%) of all employees that are becoming retirement eligible.
<br/>

**Total job titles employed by PH**
*SELECT title, count(*) from emp_titles GROUP BY title;*
- Assistant Engineer: 3,588
- Engineer: 30,983
- Manager: 9 
- Senior Engineer: 85,939
- Senior Staff: 82,024
- Staff: 25,526
- Technique Leader: 12,055

**Percentage of job title that will become retirement eligible**
- Assistant Engineer: 29/3,588 = .81%
- Engineer: 190/30,983 = .61%
- Manager: 0/9 = 0%
- Senior Engineer: 529/85,939 = .62%
- Senior Staff: 569/82,024 = .69%
- Staff: 155/25,526 = .61%
- Technique Leader: 77/12,055 = .64%

When evaluating the percentage from each job title that will be eligible for retirement, we can see that the range is from (.61%-.81%) when we except Manager title which had 0 employees reaching retirement age. Thus we can conclude that across Assitant Engineer, Engineer, Sr. Engineer, Sr. Staff, Staff, and Technique Leader all will experience a comparable impact to their respective workforces as a result of the upcoming silver tsunami. When observing at a macro level, we can see that about 71% of the upcoming retirement class consists of Sr. Engineers and Sr. Staff. 
