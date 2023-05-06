select * from dbo.Country
select * from dbo.Genre
select * from dbo.Language
select * from dbo.Location
select * from dbo.M_Cast
select * from dbo.M_Country
select * from dbo.M_Director
select * from dbo.M_Genre
select * from dbo.M_Language
select * from dbo.M_Location
select * from dbo.M_Producer
select * from dbo.Movie
select * from dbo.Person

-- 1. List all the directors who directed a 'Comedy' movie in a leap year. 
--(You need to check that the genre is 'Comedy’ and year is a leap year) Your query should return director name, the movie name, and the year. 

select p.Name,m.title,Right(year,4) as yr 
from dbo.Person p
join dbo.M_Director md on p.PID = md.PID
join dbo.Movie m on md.MID = m.MID
join dbo.M_Genre mg on mg.MID = m.MID
join dbo.Genre g on mg.GID = g.GID
where g.name like ('%Comedy%') and (cast(Right(m.year,4) as int)%4) =0;



--2. List the names of all the actors who played in the movie 'Anand' (1971) 

select p.Name,m.title
from dbo.Person p
join dbo.M_Cast mc on trim(p.PID) = trim(mc.PID)
join dbo.Movie m on trim(mc.MID) = trim(m.MID)
where m.title = 'Anand';

--3. List all the actors who acted in a film before 1970 and in a film after 1990. (That is: < 1970 and > 1990.)

select p.Name, Right(m.year,4) as yr
from dbo.Person p
join dbo.M_Cast mc on trim(p.PID) = trim(mc.PID)
join dbo.Movie m on trim(mc.MID) = trim(m.MID)
where cast(Right(m.year,4) as int) < 1970 or  cast(Right(m.year,4) as int) > 1990;


--4.List all directors who directed 10 movies or more, in descending order of the number of movies they directed. 
-- Return the directors' names and the number of movies each of them directed. 

select p.Name, count(m.title) as movie_name
from Person p
join M_Director md on p.PID =md.PID
join Movie m on md.MID = m.MID
group by md.PID,p.Name
having count(m.title) >= 10
order by movie_name desc

/*5. 
a. For each year, count the number of movies in that year that had only female actors. 
b. Now, include a small change: report for each year the percentage of movies in that 
year with only female actors, and the total number of movies made that year. 
For example, one answer will be: 1990 31.81 13522 meaning that in 1990 there were 13,522 movies, 
and 31.81% had only female actors. You do not need to round your answer. */

select right(year,4), count(m.title) as movie_count
from dbo.Movie m
join dbo.M_Cast mc on trim(m.MID) = trim(mc.MID)
join dbo.Person p on trim(mc.PID) = trim(p.PID)
where p.gender = 'Female'
group by right(year,4);

with movies as 
(select cast(right(m.year,4) as int ) as yr, m.title as title,p.Gender as gen
from dbo.Movie m
join dbo.M_Cast mc on trim(m.MID) = trim(mc.MID)
join dbo.Person p on trim(mc.PID) = trim(p.PID)
group by cast(right(m.year,4) as int ),m.title, p.Gender
)

select *, count(title)
from movies
group by yr,title, gen
order by yr


with summ_table as
(select Right(m.year,4) as year, m.title as title, p.gender as gender,
count(p.gender) over(partition by m.title) as gen_count
from person p 
inner join m_cast mc on trim(p.pid)=trim(mc.pid)
inner join movie m on trim(mc.mid) = trim(m.mid)
where p.gender != '' 
group by Right(m.year,4), m.title, p.gender)


select year,  title, count(title)
from summ_table
where gen_count = 1 and gender ='Female'
group by year,  title
order by year



-- 6. Find the film(s) with the largest cast. Return the movie title and the size of the cast. 
-- By "cast size" we mean the number of distinct actors that played in that movie: if an actor played multiple roles, or if it simply occurs multiple times in casts, we still count her/him only once. 



select m.title,p.name,
COUNT(p.name) over(partition by m.title ) as cast_size
from Person p
join M_Cast mc on trim(p.PID) = trim(mc.PID)
join Movie m on mc.MID = m.MID
group by m.title,p.name
order by cast_size desc

select m.title,count(p.name), count(distinct p.name)
--COUNT(p.name) over(partition by m.title ) as cast_size
from Person p
join M_Cast mc on trim(p.PID) = trim(mc.PID)
join Movie m on mc.MID = m.MID
Where m.title = 'Ocean''s Eight'
group by m.title

-- 7. A decade is a sequence of 10 consecutive years. 
--For example, say in your database you have movie information starting from 1965. 
--Then the first decade is 1965, 1966, ..., 1974; the second one is 1967, 1968, ..., 1976 and so on. 
--Find the decade D with the largest number of films and the total number of films in D. 

select cast(right(year,4) as int) as yr,(cast(right(year,4) as int)+9) as dyr,
CONCAT(cast(right(year,4) as int),' - ',(cast(right(year,4) as int)+9)) as D, 
ROW_NUMBER() over(order by cast(right(year,4) as int) ) as Dnum,
count(m.MID) as num_of_movies,
sum(count(m.MID)) over() as total_movies
from Movie m
group by cast(right(year,4) as int)
order by num_of_movies desc



-- 8. Find the actors that were never unemployed for more than 3 years at a stretch. (Assume that the actors remain unemployed between two consecutive movies). 

with yrs as 
(select p.Name, cast(right(m.year,4) as int) yr,
lead(cast(right(m.year,4) as int)) over(partition by  p.Name order by cast(right(m.year,4) as int) ) as lead_yr
from person p 
inner join m_cast mc on trim(p.pid)=trim(mc.pid)
inner join movie m on trim(mc.mid) = trim(m.mid))

select distinct Name
from yrs
where lead_yr is not null and (lead_yr - yr) <= 3
order by Name




-- 9. Find all the actors that made more movies with Yash Chopra than any other director. 

with cte1 as
(select  m.title as movie, p.Name as actor, p_d.name as director
from Movie m
inner join m_cast mc on trim(m.mid)=trim(mc.mid)
inner join person p on trim(mc.pid)=trim(p.pid)
inner join M_Director m_d on trim(m.mid)=trim(m_d.mid)
inner join person p_d on trim(m_d.pid)=trim(p_d.pid)),

cte2 as
(select actor, director,
count(case when trim(director) !='Yash Chopra' then movie end) as other_dir,
count(case when trim(director) ='Yash Chopra' then movie else null end) as yc_dir
from cte1 
group by actor, director),

cte3 as 
(select *,
max(other_dir) over(partition by actor) as maxc
from cte2)

select distinct actor ,yc_dir from cte3
where yc_dir > maxc
order by yc_dir desc


-- 10. The Shahrukh number of an actor is the length of the shortest path between the actor and Shahrukh Khan in the "co-acting" graph.
-- That is, Shahrukh Khan has Shahrukh number 0; all actors who acted in the same film as Shahrukh have Shahrukh number 1; 
--all actors who acted in the same film as some actor with Shahrukh number 1 have Shahrukh number 2, etc. 
--Return all actors whose Shahrukh number is 2. 
select * from dbo.Country
select * from dbo.Genre
select * from dbo.Language
select * from dbo.Location
select * from dbo.M_Cast
select * from dbo.M_Country
select * from dbo.M_Director
select * from dbo.M_Genre
select * from dbo.M_Language
select * from dbo.M_Location
select * from dbo.M_Producer
select * from dbo.Movie
select * from dbo.Person


with joined_table as 
(select p.pid as actor_id, p.Name as actor, m.MID as movie_id, m.title as movie 
from dbo.Person p
join dbo.M_Cast mc on trim(p.PID) = trim(mc.PID)
join dbo.Movie m on trim(mc.MID) = trim(m.MID)),
srk as 
(select * 
from 
joined_table
where actor like '%Shah Rukh%'),

othr_actrs as 
(select * 
from 
joined_table
where actor not like '%Shah Rukh%'),

 srk1 as
(Select distinct s.actor_id as srkid,s.actor as srk0,s.movie_id as srkmid,oa.actor_id as oaid, oa.actor as srk1,oa.movie_id as oamid
from srk s
join othr_actrs oa on s.movie_id = oa.movie_id)



select * from srk1
where oamid in (select movie_id from othr_actrs
				 where oamid = movie_id) and oamid not in (select movie_id from srk
				 where oamid = movie_id)










