/*

COS 457                 Database Systems

Prof. Briggs            SQL Selects with nested Selects

A big improvement in SQL was allowing the select statement
to appear nested in other clauses.  It always was allowed
in the where clause, but typically had to be used with

exists
op ANY
op ALL

or return a single, simple value.

We show these first.

*/

/*   29. The corporations and revenue of the
         corporations with greater than average revenue.
         Note the comparison with the result of a subquery.
         The subquery doesn't refer to external variables,
         but it is legal to use them if the query requires
         it.  We show this below.
*/
    select cname, totrev
    from corporations
    where totrev > (select avg(totrev)
                    from  corporations)
    order by cname;


/*  30. States and population of the states
        with the largest population.

    We could use max(population) in the subquery,
    but we show the use of >= all, which is equivalent
    in this context.

*/
   select stname, population 
   from states
   where population >= all (select population
                            from states);




/*   31. Senators who have received a contributions
         after the first time that Mikulski cast a vote.

     Note that if a date d is > any of the dates Mikulski
     voted, then it is > the minimum, the first date that
     Mikulski cast a vote.

     If Mikulski never voted, the query would return no
     values, because the nested query would be empty and]
     the implicit existential quantifier would fail.

*/


    select distinct sname as "HasContribSinceMikulskiVote"
    from contributes
    where cdate > any (select vdate
                       from votes
                       where sname = 'Mikulski')
    order by sname desc;


/*

    32. Senators who changed their vote on a specific
        piece of legislations, along with the legislation

    Note the external reference within the nested query.
*/

select distinct x.sname as "SenatorChangedMind",
   x.legnum as "OnThisBill"
from votes x
where exists (select 1
              from votes y
              where x.sname = y.sname and x.legnum = y.legnum
                    and x.howvoted <> y.howvoted)
order by x.sname, x.legnum;


/*

  Similarly, nested selects can be used in the having clause.

*/

/*

   33. All senators whose total contributions exceed Mitchell's
       total contributions.

   Suppose Mitchell had never received a contribution.  How
   would it affect the result?

*/

select x.sname as "BetterContribsThanMitchell"
from contributes x
group by x.sname
having sum(x.amt) > (select sum(amt)
                     from contributes 
                     where sname = 'Mitchell');




/*   34.  Senators who attended the most votes.  


*/

    select sname as "MostFrequentlyVotingSenators"
    from votes
    group by sname
    having count(*) >=all (select count(*)
                           from votes
                           group by sname);


/*   35. Corporations whose aggregate contribution was more than their
              total revenue.

    Note that the subquery in the having clause has an external reference
    to the corporation.  The reference must be to one of the group by
    columns, or it would be ambiguous.
*/

   select cname 
   from contributes
   group by cname
   having sum(amt) > (select totrev
                      from corporations
                      where corporations.cname = contributes.cname);


/*****

36. 

Early versions of SQL were not fully compositional as are the relational
algebra and the two calculuses.  Once a select statement could be put
in the from clause, however, it became so.

Here we calculate the total counts of each vote (Yea, Nay, Abstain)
for each senator.  We create three tables, one for each of the three
values, and join them up.

Note we wouldn't be able to do this query using aggregate operators
alone.

Also, note the naming of the table results of the nested queries, and
the naming of their columns.

BUG ALERT:
A prior version of this query was erroneous in that the filter on 
howvoted was in the where clause, which would throw out rows where
the senator did not have a vote on that type.  By moving it to the
outer join's ON clause, we preserve the row.

****/

select x.sname, 
   x.yeaCount as Yeas,
   y.nayCount as Nays,
   z.absCount as Abstains
from (select x1.sname, count(y.howvoted)
      from senators x1 left join votes y on x1.sname = y.sname
          and y.howvoted = 'Yea'
      group by x1.sname) as x (sname,yeaCount)
      inner join
     (select x1.sname, count(y1.howvoted)
      from senators x1 left join votes y1 on x1.sname = y1.sname
          and y1.howvoted = 'Nay'
      group by x1.sname) as y (sname,nayCount)
      on x.sname = y.sname
      inner join
      (select x1.sname, count(y1.howvoted)
      from senators x1 left join votes y1 on x1.sname = y1.sname
          and y1.howvoted = 'Abstain'
      group by x1.sname) as z (sname,absCount) on x.sname = z.sname
order by x.sname;

/****

  37. For each senator and legnum pair, the sum of contributions received
      from corporations favorably affected and the sum of contributions
      received from corporations unfavorably affected by the legislation.

BUG ALERT
The prior version of this query was erroneous in the the number of rows
involving contributions could have been multiplied by the join on
sname and legnum.  For example, if senator s and legnum l has 5 contributions
from corporations favorably affected and 6 from corporations unfavorably
affected, then the join would produce 30 rows of combinations.  To fix it
we aggregate before join so each senator and legnum has at most one row in
the subquery results.

****/

select x.sname, x.legnum,
   coalesce(y.FavAmt,0) as MoneyFor,
   coalesce(z.UnfavAmt,0) as MoneyAgainst
from (select sname, legnum
      from senators, legislation) as x (sname,legnum)
      left join
      (select x1.sname, x2.legnum, coalesce(sum(x1.amt),0)
       from contributes x1 inner join affected_by x2 on x1.cname = x2.cname
       where x2.howafctd = 'Favorably'
       group by x1.sname, x2.legnum) as y (sname, legnum, FavAmt)
       on x.sname = y.sname and x.legnum = y.legnum
      left join
      (select x1.sname, x2.legnum,  coalesce(sum(x1.amt),0)
       from contributes x1 inner join affected_by x2 on x1.cname = x2.cname
       where x2.howafctd = 'Unfavorably'
       group by x1.sname, x2.legnum) as z (sname, legnum, UnfavAmt)
       on x.sname = z.sname and x.legnum = z.legnum
-- keep only the rows where at least one of the amounts is positive
where y.FavAmt > 0 or z.UnfavAmt > 0
order by x.sname, x.legnum;

/****

     Another place where nested selects can occur is in the select list
     itself, and in that context, the nested select can have external
     references.

     We answer the last two queries using that technique.
     It seems a little easier to use.

     38.  all senators and their vote totals

****/

select x.sname,  
      (select  count(howvoted)
       from  votes
       where howvoted = 'Yea' and sname = x.sname) as Yeas,
      (select count(howvoted)
       from votes 
       where howvoted = 'Nay' and x.sname = sname) as Nays,
      (select count(howvoted)
       from votes
       where howvoted = 'Abstain' and  x.sname = sname) as Abstains
from  senators x
order by x.sname;



/*****

     39. all senator,legnum pairs and the contribution totals as for 37

In this version, we can't suppress the rows where both contribution
columns are 0.  But we can if we nest it.  See the next query.

We also might use a where clause in the outer query to eliminate
senator/legnum pairs with no relevant contributions.


******/

select x.sname, x.legnum,
       (select coalesce(sum(amt),0)
        from contributes y inner join affected_by z on y.cname = z.cname
        where z.howafctd = 'Favorably' and y.sname = x.sname and z.legnum
              = x.legnum) as MoneyFor,
       (select coalesce(sum(amt),0)
        from contributes y inner join affected_by z on y.cname = z.cname
        where z.howafctd = 'Unfavorably' and y.sname = x.sname and z.legnum
              = x.legnum) as MoneyAgainst
from (select sname, legnum
      from senators cross join legislation) as x(sname,legnum)
order by sname, legnum;

/*

   40. same as last, but nest the query in the from clause so we
       can apply a selection condition to the rows.

*/

select Answer.sname, Answer.legnum, Answer.FavAmt, Answer.UnfavAmt
from

    (select x.sname, x.legnum,
            (select coalesce(sum(amt),0)
             from contributes y inner join affected_by z on y.cname = z.cname
             where z.howafctd = 'Favorably' and y.sname = x.sname and z.legnum
                   = x.legnum) as MoneyFor,
            (select coalesce(sum(amt),0)
             from contributes y inner join affected_by z on y.cname = z.cname
             where z.howafctd = 'Unfavorably' and y.sname = x.sname and z.legnum
                   = x.legnum) as MoneyAgainst
     from (select sname, legnum
           from senators cross join legislation) as x(sname,legnum)
    )
   as Answer(sname,legnum,FavAmt,UnfavAmt)
where FavAmt > 0 or UnfavAmt > 0
order by Answer.sname,Answer.legnum;

