set @row_number=0;

select concat('[',group_concat(tmp.temp order by row desc),']')
from
(
select 
    (@row_number := @row_number +1) as row,
    round(temp,2) as temp

    from tnu 

    order by datetime desc 
    limit  144
) as tmp
