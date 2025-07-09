
--Easy Questions:

--1.	Write a SQL query to find those employees whose salaries are less than 6000. Return full name (first and last name) and salary.
select e.first_name||' '||e.last_name full_name, e.salary 
from employees e
where e.salary < 6000;


--2.	Write a SQL query to find those employees whose last name ends with "a". Return first name, last name, and department ID.
select e.first_name, e.last_name, e.department_ID 
from employees e
where e.last_name ilike '%a';


--3.	Write a SQL query to find the details of the ‘IT’ department. Return all fields.
select *
from employees e
join departments d on d.department_id = e.department_id 
where d.department_name like 'IT';


--4.	Write a SQL query to count the number of employees working in each location. Return the location city and the number of employees.
select l.city, count(e.employee_id) number_of_employees
from employees e
join departments d on e.department_id = d.department_id
join locations l on d.location_id = l.location_id
group by city
order by number_of_employees desc, l.city;


--5.	Write a SQL query to find all employees who were hired after January 1st, 1995. Return their first name, last name, hire date, and job title.
select e.first_name, e.last_name, e.hire_date, j.job_title
from employees e
join jobs j  on e.job_id = j.job_id
where e.hire_date > '01/01/1995';












--Intermediate Questions:

--6.	Write a SQL query to find those employees who work under a manager. Return full name (first and last name), salary, and manager ID.
select concat(e.first_name, e.last_name) full_name, e.salary, e.manager_id 
from employees e
where e.manager_id IS NOT NULL;


--7.	Write a SQL query to calculate the average salary for each department. Return the department name and the average salary.
select d.department_name, round(AVG(e.salary)) average_salary
from employees e
join departments d on e.department_id = d.department_id
group by department_name
order by average_salary desc, d.department_name;


--8.	Write a SQL query to find all jobs that currently have no employees assigned to them. Display the job title and the minimum and maximum salary for each job.
select j.job_title, j.min_salary, j.max_salary
from employees e
right join jobs j on e.job_id = j.job_id
where e.job_id is null;



--9.	Write a SQL query to rank employees within each department by their salary. Return the department name, employee's full name, and their rank.
select d.department_name, e.first_name || ' ' || e.last_name as full_name, 
	dense_rank() over (partition by d.department_id order by e.salary desc) rank
from employees e
join departments d on e.department_id = d.department_id
order by rank;



--10.	Write a SQL query to find the 2nd highest salary from each city. Return the city name, employee's full name, and salary.
select e2.city, e2.full_name, e2.salary as second_highst_salarys from (select l.city, concat(e.first_name, ' ', e.last_name) full_name, e.salary, dense_rank() over (partition by l.city order by e.salary desc) rank_salarys 
	from employees e 
	join departments d on d.department_id = e.department_id
	join locations l on l.location_id = d.location_id) e2
where e2.rank_salarys = 2
order by second_highst_salarys desc;












--Difficult Questions:

--11.	Write a SQL query to find the top 3 highest salaries in each department. Return the department name, employee's full name, and salary.
create or replace view temp_table as
	select d.department_name, concat(e.first_name, ' ', e.last_name) full_name, e.salary, 
		dense_rank() over (partition by d.department_id order by e.salary desc) salaries_rank
	from employees e
	join departments d on e.department_id = d.department_id;


select e2.department_name, e2.full_name, e2.salary from temp_table e2
where e2.salaries_rank >= 3
order by department_name, salary desc;



--12.	Write a SQL query to calculate the year-over-year salary growth for each employee based on their hire date. Return the employee's full name, hire date, salary, next year's salary, and the growth percentage.
(select concat(e.first_name, ' ', e.last_name) full_name, e.hire_date, e.salary, round((((e.salary - pvs.salary) / pvs.salary)*e.salary)+e.salary, 0) next_year_salary, round(((e.salary-pvs.salary)*100)/e.salary, 2) growth_percentage
from employees e
join prev_salaries pvs on e.employee_id  = pvs.employee_id
where pvs.salary is not null 
order by full_name);

--OR

with SalaryData as (
    select e.employee_id, e.first_name || ' ' || e.last_name AS full_name, e.hire_date, ps.salary as prev_salary, e.salary as current_salary
    from employees e
    join prev_salaries ps on e.employee_id = ps.employee_id
)
select full_name, hire_date, current_salary, 
	ROUND(
        case 
            when prev_salary is null then null
            else (((current_salary - prev_salary) / prev_salary)*current_salary)+current_salary   --OR  current_salary * (1 + ((current_salary - prev_salary) / prev_salary))
        end, 0) as next_year_salary,
    ROUND(
        case 
            when prev_salary is null then null
            else ((current_salary - prev_salary) / prev_salary) * 100
        end, 2) as growth_percentage
from SalaryData
where prev_salary is not null 
order by full_name;




--13.	Write a SQL query to find employees whose salary is less than the average salary of their respective department. Return the employee's full name, department name, and their salary.
select e2.department_name, e2.full_name, e2.salary
from
	(select d.department_name, concat(first_name,' ', last_name) full_name, e.salary,
		avg(e.salary) over (partition by d.department_name) avg_salary
	from employees e 
	left join departments d on e.department_id = d.department_id) e2
where e2.salary < e2.avg_salary
order by e2.department_name;
	


--14.	Write a SQL query to generate a report that lists employees who have a salary higher than the previous employee's salary when ordered by department and salary. Return the employee's full name, their department, and the salary difference.
select e2.full_name, e2.department_name, e2.salary - e2.prev_salary as salary_difference 
from (
	select concat(e.first_name, ' ', e.last_name) full_name, d.department_name, e.salary, 
		lag(e.salary,1,0) over (partition by department_name order by e.salary) as prev_salary
	from employees e
	join departments d on e.department_id = d.department_id) e2
where e2.salary > e2.prev_salary;



--15.	Write a SQL query to calculate the overall company average salary and then find departments where the average salary is above this overall average. Return the department name and the average salary.
select * from
	(select distinct(d.department_name),
		round(avg(e.salary) over (partition by d.department_name), 1) avg_salary_of_dept
	from employees e 
	left join departments d on e.department_id = d.department_id) e2
where avg_salary_of_dept > (select avg(e.salary) overall_avg_salary from employees e);
	


--16.	Write a SQL query to identify employees who have the same salary as another employee in a different department. Return the names of both employees, their respective departments, and their salary.
select concat(e1.first_name,' ', e1.first_name) as emp1_full_name,  d1.department_name, 
	concat(e2.first_name,' ', e2.first_name) as emp2_full_name, d2.department_name, e1.salary
from employees e1
left join departments d1 on e1.department_id = d1.department_id
join employees e2 on e1.salary = e2.salary and e1.department_id != e2.department_id
left join departments d2 on e2.department_id = d2.department_id;



--17.	Write a SQL query to analyze employee promotion patterns. Identify employees who have moved to a job with a higher average salary. Return the employee's full name, their original job title, new job title, and the salary increase.
select e.employee_id, e.first_name || ' ' || e.last_name as full_name, j_old.job_title as original_job_title, 
    j_new.job_title as new_job_title, (e.salary - ps.salary) as salary_increase
from employees e
join prev_salaries ps on e.employee_id = ps.employee_id
join jobs j_old on e.job_id = j_old.job_id
join jobs j_new on e.job_id = j_new.job_id
where e.salary > ps.salary
order by salary_increase desc;



--18.	Write a SQL query to calculate the running total of salaries within each department. Return the department name, employee's full name, salary, and the running total.
select department_name, concat(first_name,' ',last_name) emp_full_name, salary,
	sum(e.salary) over (partition by d.department_name order by e.salary) as running_total
from employees e 
left join departments d on e.department_id = d.department_id
order by d.department_name, salary;



--19.	Write a SQL query to find employees who have dependents with the same first name as the employee. Return the employee's full name and the dependent's full name.
select concat(e.first_name,' ', e.first_name) as employees_full_name, concat(d.first_name,' ', d.first_name) as dependents_full_name
from employees e
join dependents d on e.first_name = d.first_name



--20.	Write a SQL query to find the department with the maximum total salary. Return the department name and total salary.
--FRIST APPROACH
create or replace view dep_total_salary as 
	(select d.department_name, sum(e.salary) total_salary_by_department from employees e
	left join departments d on e.department_id = d.department_id
	group by d.department_name);
	
select department_name, total_salary_by_department as max_salary
from dep_total_salary
where total_salary_by_department = (select max(total_salary_by_department) from dep_total_salary);


--SECOND OPPROACH
select d.department_name, sum(e.salary) total_salary_by_department from employees e
left join departments d on e.department_id = d.department_id
group by d.department_name
order by total_salary_by_department desc
limit 1;












--Most Difficult Questions:

--21.	Write a SQL query to create an organizational hierarchy that shows the management chain for each employee. Display the employee's full name, their manager's full name, and the level of hierarchy.
-- FIRST BUT NOT PREFERABLE APPROACH
select concat(e.first_name,' ',e.last_name) as emp_full_name, 
	concat(m.first_name,' ',m.last_name) as their_manager_full_name, 
	case
		when e.manager_id is null then 1
		when m.manager_id is null then 2
		when m1.manager_id is null then 3
		when m2.manager_id is null then 4
		when m3.manager_id is null then 5
	end as level_of_hierarchy
from employees e 
left join employees m on e.manager_id = m.employee_id  
left join employees m1 on m.manager_id = m1.employee_id  
left join employees m2 on m1.manager_id = m2.employee_id  
left join employees m3 on m2.manager_id = m3.employee_id 
order by level_of_hierarchy;


-- SECOND AND PREFERABLE APPROACH
with recursive organizational_hierarchy as (
		select e.employee_id, e.first_name||' '||e.last_name as full_name, e.manager_id, 1 as level_of_hierarchy
		from employees e  
		where e.manager_id is null
	union all 
		select e.employee_id, e.first_name||' '||e.last_name as full_name, e.manager_id, 1 + Oh.level_of_hierarchy
		from employees e 
		join organizational_hierarchy Oh on  e.manager_id = Oh.employee_id
		
)
--select * from organizational_hierarchy;
select e.full_name as emp_full_name, m.full_name as their_manager_full_name, e.level_of_hierarchy
from organizational_hierarchy e 
left join organizational_hierarchy m on  e.manager_id = m.employee_id;



--22.	Write a SQL query to divide the employees into 4 salary quartiles. Return the quartile number, employee's full name, and salary.
create or replace view emp_detail as
	select e.first_name||' '||e.last_name as full_name, 
		e.salary,
		row_number() over (order by e.salary) as n,
		count(*) over () as total_count
	from employees e 
	order by e.salary;

select case
    when n <= total_count / 4 then '1st Quartile'
	when n <= total_count / 2 then '2nd Quartile'
    when n <= (total_count * 3) / 4 then '3rd Quartile'
    else '4th Quartile'
end
as quartile_number, ed.full_name, ed.salary from emp_detail ed;



--23.	Write a SQL query to list all employees and their direct and indirect reports. Return the employee’s full name, their report’s full name, and the level of reporting.
with recursive EmployeeHierarchy as (
    select   
        e.employee_id,
        e.first_name||' '||e.last_name AS employee_name,
        null as manager_name,
        1 as levels
    from employees e
    where e.manager_id is null 

    union all 

    select  
        e.employee_id,
        e.first_name||' '||e.last_name AS employee_name,
        eh.employee_name as manager_name,
        eh.levels + 1 as levels
    from employees e
    join EmployeeHierarchy eh on e.manager_id = eh.employee_id
)
select employee_name, manager_name, levels
from EmployeeHierarchy
order by levels, employee_name;



--24.	Write a SQL query that calculates the average salary for each department and job title combination. Return the department name, job title, and average salary.
select 
	d.department_name, 
	j.job_title, 
	avg(e.salary) as average_salary
from employees e 
left join departments d on d.department_id = e.department_id
left join jobs j on e.job_id = j.job_id 
group by d.department_id , j.job_title
order by d.department_id , j.job_title, average_salary;
	


--25.	Write a SQL query to generate a report showing the year-over-year change in the number of employees by department. Return the department name, year, number of employees, and the change from the previous year.
with EmployeeCounts as( 
	select  
		d.department_name, 
        extract(year from e.hire_date) AS hire_year,
        count(e.employee_id) as number_of_employees
    from employees e 
    left join departments d on e.department_id = d.department_id 
    group by d.department_name, extract(year from e.hire_date)
    order by d.department_name, extract(year from e.hire_date)
),
YearOverYearChange AS (
    select 
    	department_name, 
        hire_year,
        number_of_employees,
        lag(number_of_employees,1,0) over (partition by department_name order by number_of_employees) as num_previous_year
    from EmployeeCounts ec
)
select 
    department_name, 
    hire_year, 
    number_of_employees,
    (number_of_employees - num_previous_year) AS change_from_previous_year
from YearOverYearChange
order by department_name, hire_year;


