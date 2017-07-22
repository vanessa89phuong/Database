<%@page import="java.text.ParseException"%>
<%@page import="java.text.SimpleDateFormat"%>
<!doctype html public "-//w3c/dtd HTML 4.0//en">
<html>
    <head>
        <title>JDBC Table JSP</title>
        <style type="text/css">
            h2.heading {
                font: bolder 180% georgia, verdana, sans-serif;
                color: #f00;
            }
            table.mytable {
                border: 1px solid #000;
                margin: 0;
                padding: 0;
                width:800px;
            }
            td.header {
                font: bolder 130% georgia, verdana, sans-serif;
                color: white;
                background-color: blue;
                border-bottom: 1px solid #000;
                text-align: center;
            }
            td.cdata {
                font: normal 90% verdana, arial, sans-serif;
                background-color: lightblue;
                padding-left: 10px;
            }
            h2.error {
                font: bolder 120% georgia, verdana, sans-serif;
                color: #15e;
            }
        </style>
    </head>

    <body bgcolor="#FFFFFF">

        <h2 class="heading">Using JSP to retrieve database data with JDBC</font></h2>
            <%@ page import="java.util.*,java.sql.*,org.postgresql.*" %>

        <%
            String dbURL = "jdbc:postgresql://moth.cs.usm.maine.edu/senators"
                    + "?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory";
            String jdbcDriver = "org.postgresql.Driver";
            String sqlQuery = "select * from senators";
            //---------------------------------------------------------------
            // Make credential modifications here
            //---------------------------------------------------------------
            String username = "phuong";
            String passwd = "123456789";
        %>

        <h2>Results from query:</h2>

        <%
            String lowName;
            String highName;
            String lowDateStr;
            String highDateStr;
            java.sql.Date lowDate = null;
            java.sql.Date highDate = null;
            lowName = request.getParameter("lowName");
            highName = request.getParameter("highName");
            lowDateStr = request.getParameter("lowDate");
            highDateStr = request.getParameter("highDate");
            SimpleDateFormat dateformat = new SimpleDateFormat("yyyy-MM-dd");
            boolean valid = true;
            
            if (lowName == null) {
                out.println("<h4> Missing low name</h4>");
                valid = false;
            } else if (lowName.equals("")) {
                out.println("<h4> empty low name</h4>");
                valid = false;
            } else if (lowName.matches(".*[^a-zA-Z].*")) {
                out.println("<h4> there are non-letter characters in low name</h4>");
                valid = false;
            }
            if (highName == null) {
                out.println("<h4> Missing high name</h4>");
                valid = false;
            } else if (highName.equals("")) {
                out.println("<h4> empty high name</h4>");
                valid = false;
            } else if (highName.matches(".*[^a-zA-Z].*")) {
                out.println("<h4> there are non-letter characters in high name</h4>");
                valid = false;
            }

            if (lowName != null && highName != null && (!highName.equals("")) &&(!lowName.equals("")) && highName.compareTo(lowName) < 0) {
                out.println("<h4> empty name range</h4>");
                valid = false;
            }

            java.util.Date lowDateJ = null;
            if (lowDateStr == null) {
                out.println("<h4> Missing low date</h4>");
                valid = false;
                
            } else {
                try {
                    lowDateJ = dateformat.parse(lowDateStr);
                    try {
                        dateformat.setLenient(false);
                        dateformat.parse(lowDateStr);
                        lowDate = new java.sql.Date(lowDateJ.getTime());
                    } catch (ParseException e) {
                        lowDateJ = null;
                        out.println("<h4> low date is not valid date</h4>");
                        valid = false;
                    }
                } catch (ParseException e) {
                    out.println("<h4> low date wrong format</h4>");
                    valid = false;
                }
            }

            java.util.Date highDateJ = null;
            if (highDateStr == null) {
                out.println("<h4> Missing high date</h4>");
                valid = false;
            } else {
                try {
                    highDateJ = dateformat.parse(highDateStr);
                    try {
                        dateformat.setLenient(false);
                        dateformat.parse(highDateStr);
                        highDate = new java.sql.Date(highDateJ.getTime());
                        
                    } catch (ParseException e) {
                        highDateJ = null;
                        out.println("<h4> high date is not valid date</h4>");
                        valid = false;
                    }
                } catch (ParseException e) {
                    out.println("<h4> high date wrong format</h4>");
                    valid = false;
                }
            }

            if (lowDateJ != null && highDateJ != null && highDateJ.before(lowDateJ)) {
                out.println("<h4> empty date range</h4>");
                valid = false;
            }
if(valid){
    String preparedSQL = "select s.sname,min(c.cdate) as minDate,max(c.cdate) as maxDate,count(c.amt) as countC,sum(c.amt) as sumC,avg(c.amt) as averageC "
+"from senators s join contributes c on "
+"s.sname = c.sname "
+"where (? <= s.sname and s.sname <= ?) and "
+      "(? <= c.cdate and c.cdate <= ?) "
+"group by s.sname "
+"order by s.sname asc;";


            Connection conn = null;
            PreparedStatement stmt = null;
            ResultSet rs = null;

            try {

                Class.forName(jdbcDriver).newInstance();
                conn = DriverManager.getConnection(dbURL, username, passwd);
                stmt = conn.prepareStatement(preparedSQL);
                stmt.setString(1,lowName);
                stmt.setString(2,highName);
                stmt.setDate(3, lowDate);
                stmt.setDate(4,highDate);
                
                rs = stmt.executeQuery();

                ResultSetMetaData rsmd = rs.getMetaData();
                int numCols = rsmd.getColumnCount();
                
        %>

        <table class="mytable">
            <tr>

                <%
                    for (int i = 1; i <= numCols; i++) {
                %>

                <td class="header"><%= rsmd.getColumnLabel(i)%></td>

                <%
                    }
                %>

            </tr>

            <%
                while (rs.next()) {
            %>
            <tr>
                <%
                    for (int i = 1; i <= numCols; i++) {
                %>
                <td class="cdata"><%= rs.getString(i)%></td>
                <%
                    }
                %>

            </tr>
            <%
                }
            } catch (Exception ex) {
                out.print(ex.toString());
            %>
            <h2>Sorry could not get information</h2>
            <%
                }
            %>
        </table>
        <%
        }
%>
        <!--- change this too -->
        <a href="/~phuong/entry.html">Go back</a>
    </body>
</html>
