
/*
        COS  457            Database Systems

        Professor Briggs    SQL Queries 

        We illustrate SQL select with a number of queries, showing
        the use of the aggregate operators, group by, 
        having, outer joins, and the union operators.


        Aggregate operators reduce a multiset to a single scalar value.
        The standard ones are

        count, min, max, sum, avg

        count can be used on any multiset.  min and max require that the
        set has an ordering. sum and avg require numberic types.

        See the other handout for a more detailed account of their meaning,
        but generally, they can be used with any expression, and if you
        put 'distinct' before the expression, duplicates are eliminated
        before applying the operator, which could affect count, sum, and
        avg, but not min and max.  Generally, null values are eliminated
        before the operator is applied, the exception being count(*),
        which includes nulls.  In some situations, if the aggregate operator
        is applied to an empty result, as in

        select min(age)
        from senators 
        where sname <> sname;

        it will evaluate to null.  The exception is count, which will
        evaluate to 0.

*/

/*   14. Find the number of ages of senators.

    This version will be the same as the number of rows in
    the table because we didn't eliminate duplicates.

*/

select count(age) as "AgeCount"
from senators;

/* 15. Find the number of distinct ages, the average age, the
       oldest age, and the youngest age

*/

select count(distinct age) as "DistinctAgeCount",
       avg(age) as "AverageAge",
       max(age) as "OldestAge",
       min(age) as "YoungestAge"
from senators;

/*  16. The most recent date on which a vote was taken.  */

   select max(vdate) as "MostRecentVoteDate"
   from votes;


/**************************************************************
********
********  Next, aggregates of a single column of the result of
********  a selection against a table.
********
********
********
*/

/*   17.  The number of votes Cohen has attended.


*/

    select count(*)  as "CohenBallotsCast"
    from votes 
    where sname = 'Cohen';


/*   18.  The largest contribution that Sarbanes has
               received.

     We use coalesce in case Sarbanes didn't receive a
     contribution, casting the numeric value to a string
     so that we can print a more indicate message.
*/

    select coalesce(Cast(max(amt) as varchar), 'No contributions')
       as "SarbanesMaxContribution"
    from contributes
    where sname = 'Sarbanes';


/*   19. The first time Kennedy abstained.

     If Kennedy never abstained, null will be returned.
*/

    select min(vdate) as "KennedysFirstAbstention"
    from votes
    where sname = 'Kennedy' and howvoted = 'Abstain';



/*   20.  The number of times Howell Heflin voted no. 

     count  will work even when the query returns no rows.

*/

    select count(*) as "HeflinNayCount"
    from votes
    where sname = 'Heflin' and howvoted = 'Nay';

/***

    group by partitions the result of the row filtering
    into subsets of rows that agree on the group by columns.
    In the select list any references to columns that were 
    not in the group by clause can only occur inside aggregate
    operators, lest the reference be ambiguous.

    Note, w/o  a group by, an aggregate operator in the select
    list is essentially treating all the rows of the result as
    belong to a single group/equivalence class.


***/

/*
   21. for all senators who have received a contribution, give
       the count, sum, and average of the contributions received.

*/

select sname, count(cdate) as "ContribCount" , sum(amt) as "ContribTotal",
       avg(amt) as "ContribAvg"
from contributes
group by sname
order by sname;

/* 

   22. same as last, but include ALL senators, even those who haven't
       received a contribution.  We can do this in several ways.  We show
       an outer join and also a union.

   A senator who had not received a contribution would not have a row
   in contributes, and so would not have a row in the result.  If ALL
   of the entities should  be included, then an outer join with the
   appropriate entity table should be used.

*/

select x.sname, count(y.cdate) as "ContribCount",
       coalesce(sum(y.amt),0) as "ContribTotal",
       coalesce(cast(avg(y.amt) as varchar), 'N/A') as "ContribAvg"
from senators x left join  contributes y on x.sname = y.sname
group by x.sname
order by x.sname;


-- alternatively, and this is what you would have to do in earlier
-- versions of SQL,  we can union the previous version with a query
-- that finds the senators with no contributions, but to make the
-- two queries "union compatible" we have to cast the last column
-- of the first to varchar; Note, when you use order by with union, intersect,
-- or except, you have to specify the columns by their output column
-- name, given in the first subselect, or by that column's number;
-- the leftmost column has number 1; the former method may not be
-- standard SQL


select x.sname as "Senator", count(x.cdate) as "ContribCount",
       sum(x.amt) as "ContribTotal",
       cast(avg(amt) as varchar) as "ContribAvg"
from contributes x
group by x.sname

union

select x.sname, 0, 0, 'N/A'
from senators x
where not exists(select 1
                 from contributes y
                 where x.sname = y.sname)

order by "Senator";


/*
    23.

    We give another example of the use of outer join with group by
    and aggregate operators, coalesce and cast.  Not every senator
    sponsors a bill. This query gives all the senators, the count
    of the bills they sponsor, and the largest bill number of a bill
    they sponsor, or 'N/A' if they sponsor no bills.
    
*/

select x.sname, count(y.legnum) as "SponsoredBillCount",
       coalesce(cast(max(y.legnum) as varchar),'N/A') as "MostRecentSponsoredBill"
from senators x left join sponsors y on x.sname = y.sname
group by x.sname
order by x.sname;


-- or, with a union

select x.sname,
       count(x.legnum) as "SponsoredBillCount",
       cast(max(x.legnum) as varchar) as "MostRecentSponsoredBill"
from sponsors x
group by x.sname

union

-- note the use of not in to identify senators with no sponsored bill;
-- the in operator has the usual set theoretic meaning, and can also
-- be effected by = any
select sname,
       0,
       'N/A'
from senators
where sname not in (select sname
                    from sponsors)

order by 1;

/***

    the having clause is used to filter groups analogous
    to the where clause, which filters rows.  As in the select
    list, the non-group by columns can only appear within
    aggregate operators.

***/

/*

    24.  All senators who have received at least 10 contributions,
         along with the count, total, and average of the contributions.

*/

select sname, count(cdate) as ContribCount , sum(amt) as ContribTotal,
       avg(amt) as ContribAvg
from contributes
group by sname
having count(*) >= 10;


/*  25.   States with two Democratic senators.  */

    select stname
    from senators
    where party = 'Democrat'
    group by stname
    having count(*) > 1;


/*

   26. All Senators whose total received contributions exceeds half
       the population of the senator's state.

   We have to fool the query processor into allowing us to use
   the population column in the filter.  There are two ways to do
   this.

   The first applies aggregate operator min (max would also work)
   to the column.  Since the values are all the same, it gets
   the actual population value.

*/

select x.sname
from senators x inner join  states y on x.stname = y.stname
     left join contributes z on x.sname = z.sname
group by x.sname
having sum(z.amt) > min(y.population)/2;

-- or, since the population is the same in the rows
-- within every group, make it a group by column

select x.sname
from senators x inner join  states y on x.stname = y.stname
     left join contributes z on x.sname = z.sname
group by x.sname, y.population
having sum(z.amt) > y.population/2;

/***

  27. 

  This one is to test how group by deals with nulls.  The
  first column won't have any nulls, but the second two could
  be neither, either one, or both null.

  If you examine the result, it appears that for the purposes
  of group by, nulls are equated and treated like other values.
  If they were not equated, then wherever there is a NULL 
  entry with a SenatorCount > 1, we would see multiple rows.

***/

select count(x.sname) as "SenatorCount",
       coalesce(cast (y.legnum as varchar), 'NULL') as OpposedBill,
       coalesce(cast (z.legnum as varchar), 'NULL') as SponsoredBill
from senators x left join opposes y on x.sname = y.sname
     left join sponsors z on x.sname = z.sname
group by y.legnum, z.legnum
order by y.legnum, z.legnum;
     
/*

  28.

  Finally, we show that the having clause can be  used
  even when group by is not present.  Recall, w/o group by,
  aggregate operators treat the whole table as a single group.

*/

select max(age)
from senators
having max(age) > avg(age);
