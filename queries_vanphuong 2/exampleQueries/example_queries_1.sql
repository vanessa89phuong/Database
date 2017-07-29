/*   This file contains a few simple select, project,
     join queries.  They do not involve the aggregate operators,
     nor nested select statements.

     I express the domain calculus version and the SQL realization.

     Generally, the row filtering is accomplished in the where clause.
     Projection is accomplished in the select clause. Joins are
     effected either in the from clause, or in the from clause
     and the where clause.

     In the first version of SQL, the from clause could just have a
     list of tables, and joins were effected by putting the join
     condition in the where clause.  Later versions allow join
     expressions in the from clause.  We show both methods.

     We also show the use of the order by clause to force that the
     rows be given in a particular order.

*/

/* 1. Display all rows in senators

   In the calculus this is just

   answer(sn, p, a, g, st) <=>  senators(sn, p, a, g, st) 

 */

select * 
from senators
order by sname;

-- it's recommended to not use *, in case more  table columns are
-- added to the table at a later date

select sname,party,age,gender,stname
from senators
order by sname desc;

/* 2. Display all ages from rows in senators 

      answer(a) <=>
      Exists sn Exists p Exists g Exists st senators(sn, p, a, g, st) 
*/

select age 
from senators
order by age asc;

/*  3. same as last, except eliminate duplicate ages;
       note there is no difference in the calculus version,
       since the result is a set
*/

select distinct age 
from senators
order by age desc;

/* 4. Display names and states of Republican senators

   answer(sn, st) <=> 
      Exists g Exists a senators(sn, 'Republican', a, g, st) 

   This is s simple single table restriction.
*/

select sname, stname
from senators
where party = 'Republican'
order by sname, stname;

/* 5.  Display ages of senators that are either Democrats
        or women.

   answer(a) <=> 
      Exists sn Exists p Exists g Exists st 
      [senators(sn, p, a, g, st)  and (p = 'Democrat' or
       g = 'Female')]
*/
select age
from senators 
where party = 'Democrat' or gender = 'Female'
order by age;

-- eliminate duplicates

select distinct age
from senators 
where party = 'Democrat' or gender = 'Female'
order by age;

/* 6. All senators from states with more than 5000000 people.

      This is our first join query.  Since senator name is
      in one table and population is in another, we have to
      join the two tables, in this case on the state name.

   answer(sn) <=>
      Exists a Exists pop Exists p Exists g Exists st
      [ senators(sn, p, a, g, st) and states(st, pop) and
        pop > 5000000]

   Note, the older version puts both the join predicate and
   the filtering predicate in the where clause,whereas the
   more recent version distinguishes the two.  For an inner
   join the result will be the same, but for an outer join
   it can make a difference.

   Note the use of the table name to stand for the row/tuple
   from the table.  In the second version we "alias" the
   table names to x and y, for convenience.

*/
select sname
from senators, states
where senators.stname = states.stname
      and states.population > 5000000
order by sname;


-- or

select x.sname 
from senators x inner join states y on x.stname = y.stname
where y.population > 5000000
order by sname;


/* 7. All corporations whose total revenue exceeds population of 
      state of the corporation 

      Again, a query that requires us to join two tables, the
      corporations table and the states table.

     answer(corp) <=> 
     Exists st Exists tot Exists pop 
     [ corporations(corp, st, tot) and states(st,pop) and
       tot > pop]

*/

select cname
from corporations, states
where corporations.stname = states.stname and 
      corporations.totrev > states.population
order by cname;


-- or

select x.cname
from corporations x inner join states y on x.stname = y.stname
where x.totrev > y.population
order by x.cname;

/* 8.  Pairs of corporations from same state 

       For this query, we join a table with itself.
       Note the use of the alias variables x and y
       to distinguish the two occurrences of the table
       in the Cartesian product.  Note also the
       condition x.cname < y.cname in the where clause.
       This is to avoid results such as

       Rinky Dink Inc.   Rinky Dink Inc.

       where a corporation joins with itself and
       also the redundant pairings of 

       corp x     corp y

       corp y     corp x

       answer(corp1, corp2) <=> Exists st1 Exists tot1
       Exists tot2 [ corporations(corp1, st1, tot1) and
       corporations(corp2, st1, tot2) and corp1 < corp2]
       

*/

select x.cname, y.cname
from corporations x, corporations y
where x.stname = y.stname and x.cname < y.cname
order by x.cname, y.cname;

-- or

select x.cname, y.cname
from corporations x inner join corporations y on
     x.stname = y.stname and x.cname < y.cname;


/*  9. All states with 2 Democratic senators 

       Similar to the last query in that we have to
       join senators with itself on the common state
       attribute.  Here we also have an additional 
       selection condition on the party of the two
       tuples.

   answer(st) <=> Exists sn1 Exists sn2 Exists a1 Exists a2 
   Exists g1 Exists g2 
   [senators(sn1, 'Democrat', a1, g1, st) and
    senators(sn2, 'Democrat', a2, g2, st) and sn1 < sn2]
*/

select x.stname
from senators x, senators y
where x.stname = y.stname and x.party = 'Democrat' and
      y.party = 'Democrat' and x.sname < y.sname
order by x.stname;


-- or

select x.stname
from senators x inner join senators y on
      x.stname = y.stname and x.sname < y.sname
where x.party = 'Democrat' and y.party = 'Democrat'
order by x.stname;

-- or, using group by and having, which we will discuss later

select x.stname
from senators x
where x.party = 'Democrat'
group by x.stname
having count(*) = 2
order by x.stname;

/*  10. All senators who sponsored a bill that favorably 
       affects some corporation from the senators state.


   answer(sn) <=> Exists leg Exists corp Exists st Exists tot
       Exists a  Exists p Exists g
       [senators(sn, p, a, g, st) and sponsors(sn, leg) and
        affected_by(corp, leg, 'Favorably') and
        coporations(corp, st, tot)]

       This query requires us to join 4 tables : corporations,
       senators, sponsors, and affected_by.  Let's look at the
       join condition (note the aliases).  Recall that the
       Cartesian product is formed, so a single row of the
       product will have a v from corporations, an x from
       senators, a y from sponsors, and a z from affected_by.
       Our question is does this v, x, y, and z determine
       an answer to the query.

       The condition is a conjunction, and consider each conjunct

      v.stname = x.stname and   - the senator and corporation are
                                  from the same state
      z.cname = v.cname and     - the corporation is affected by
                                  some legislation, the legislation
                                  of z
      y.sname = x.sname and     - the senator sponsors some legislation
                                  the legislation of y
      z.legnum = y.legnum and   - the legislation affecting the 
                                  corporation and the legislation
                                  sponsored by the senator are the
                                  same
      z.howafctd = 'Favorably' - the legislation favorably affects
                                  the corporation.

      With a complicated join condition such as this one, you should
      review each requirement of the query spec to see that you
      have included a condition to enforce it, and review all the
      conditions of your boolean expression to see that they are 
      needed.

      Notice that we do not care which corporation or bill is 
      involved, and their identifying attributes are projected
      out of the query.

*/

select distinct x.sname   -- distinct eliminates duplicates of the sname
from corporations v, senators x, sponsors y, affected_by z
where v.stname = x.stname and
      z.cname = v.cname and
      y.sname = x.sname and
      z.legnum = y.legnum and
      z.howafctd = 'Favorably'
order by x.sname;

-- or

select distinct x.sname
from ((corporations v inner join senators x on v.stname = x.stname)
       inner join sponsors y on y.sname = x.sname)
     inner join affected_by z on z.cname = v.cname and z.legnum = y.legnum
where z.howafctd = 'Favorably';


/*    11.  Senators who voted twice
           against a bill that they sponsored.


      answer(sn) <=> Exists vd1 Exists vd2 Exists leg
           [ votes(sn, leg, vd1, 'Nay') and 
             votes(sn, leg, vd2, 'Nay') and vd1 < vd2
             and sponsors(sn, leg)]

           Again, we have a multi-table join to
           find distinct votes by a given senator
           against a bill sponsored by the senator.

*/

select distinct x.sname
from sponsors, votes x, votes y
where x.legnum = sponsors.legnum and
      y.legnum = x.legnum and
      x.sname = y.sname and
      x.sname = sponsors.sname and
      x.howvoted = 'Nay' and
      y.howvoted = 'Nay' and
      x.vdate < y.vdate
order by x.sname;

-- or

select distinct x.sname
from (sponsors inner join  votes x on x.legnum = sponsors.legnum and
     x.sname = sponsors.sname)
     inner join votes y on  y.legnum = x.legnum and x.sname = y.sname
     and x.vdate < y.vdate
where x.howvoted = 'Nay' and y.howvoted = 'Nay'
order by x.sname;


/*  12. A Roll Call is identified by a legnum and a vdate.
        Find all Roll Calls.

    answer(l,d) <=> exists s exists h votes(s,l,d,h)

*/

select distinct legnum, vdate
from votes
order by legnum,vdate;

-- or, using group by

select vdate,legnum
from votes
group by legnum, vdate
order by vdate,legnum;

/*

    13. Show all (senator,legnum) pairs where the senator voted for legnum once
        and against legnum once, in any order.

    answer(s,l) <=> exists h1 exists h2 exists v1 exists v2 (votes(s,l,v1,h1) and
                    votes(s,l,v2,h2) and h1 <> h2)

    Note, we don't need to explicitly put v1 <> v2 in the query condition because
    if s and l are the same in both rows, and v1 = v2, then the two rows agree on
    the key,  sname, legnum, and vdate, so they would have to agree on the howvoted
    field.  Since v1 = v2 -> h1 = h2, by Modus Tollens we have h1 <> h2 -> v1 <>  v2.

*/


select distinct x.sname,x.legnum
from votes x, votes y
where x.sname = y.sname and x.legnum = y.legnum
     and x.howvoted <> y.howvoted
order by x.sname, x.legnum;

-- or

select distinct x.sname,x.legnum
from votes x inner join votes y on x.sname = y.sname and x.legnum = y.legnum
     and x.howvoted <> y.howvoted
order by x.sname desc, x.legnum desc;
