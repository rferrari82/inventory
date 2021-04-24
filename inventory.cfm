<!--- Start Content Template --->

<!--- This page calls itself using CFCASE / CFSWITCH. g Each CFCASE value can be
found by searching for 3 astericks [***].  This indicates the start of a CFCASE value --->

<cfif IsDefined("url.act")>
<cfset TemplateSwitch=url.act>
<cfswitch expression="#TemplateSwitch#">

<!--- *** Synopsis of Orders --->
<cfcase value="view">


<form method="post" action="index.cfm?page=inventory&act=showme">
<table width="46%" border="0" align="center">
  <tr>
    <td width="235"><div align="center"><strong>Inventory Statistics For the Last:</strong></div></td>
    <td width="170">
      <div align="center"><strong>
        <input name="daysgoback" type="text" id="textfield" size="5" maxlength="5" />
      Days</strong>        </div></td>
    <td width="147"><div align="center">
      <input type="submit" name="button" id="button" value="Show Me!" />
    </div></td>
  </tr>
</table>
</form>

<form method="post" action="index.cfm?page=inventory&act=showmegfs">
<table width="46%" border="0" align="center">
  <tr>
    <td width="235"><div align="center"><strong>Inventory Statistics (GFS) For the Last:</strong></div></td>
    <td width="170">
      <div align="center"><strong>
        <input name="daysgoback" type="text" id="textfield" size="5" maxlength="5" />
      Days</strong>        </div></td>
    <td width="147"><div align="center">
      <input type="submit" name="button" id="button" value="Show Me!" />
    </div></td>
  </tr>
</table>
</form>

<form method="post" action="index.cfm?page=inventory&act=getvalue">
<table width="46%" border="0" align="center">
  <tr>
    <td width="147"><div align="center">
      <input type="submit" name="button" id="button" value="Get Inventory Value" />
    </div></td>
  </tr>
</table>
</form>

<form method="post" action="index.cfm?page=inventory&act=showme2">
<table width="46%" border="0" align="center">
  <tr>
    <td width="235"><div align="center"><strong>Sales Units For the Last:</strong></div></td>
    <td width="170">
      <div align="center"><strong>
        <input name="daysgoback" type="text" id="textfield" size="5" maxlength="5" />
      Days</strong>        </div></td>
    <td width="147"><div align="center">
      <input type="submit" name="button" id="button" value="Show Me!" />
    </div></td>
  </tr>
</table>
</form>

<form method="post" action="index.cfm?page=inventory&act=sync">
<table width="46%" border="0" align="center">
  <tr>
    <td width="235"><div align="center"><strong>Synchronize Inventory:</strong></div></td>
    <td width="147"><div align="center">
      <input type="submit" name="button" id="button" value="Synch!" />
    </div></td>
  </tr>
</table>
</form>



</cfcase>

<!--- *** Show last X Days --->
<cfcase value="showme">

<cfset DATEMINUS=DateFormat(DateAdd("d", -#Val(form.daysgoback)#, DateFormat(Now(),"yyyy-mm-dd")),"yyyy-mm-dd")>
<cfset TODAY="#DateFormat(Now(),"yyyy-mm-dd")#">

<!--- Get All Active Products --->
<cfquery name="myQuery" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
	SELECT PID, SKUName, Package, UseMQ, MasterQuantity
	FROM #APPLICATION.DBPRE#ProductList
	WHERE Status = 1
ORDER BY SKUName
</CFQUERY>

<table width="75%" border="1" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td colspan="3"><div align="center"><strong><font size="+2">PRODUCT TRENDS FOR THE LAST <cfoutput>#form.daysgoback#</cfoutput> DAYS</font></strong></div></td>
  </tr>
  <tr>
    <td><div align="center"><strong>PRODUCT NAME</strong></div></td>
    <td><div align="center"><strong>TOTAL SOLD</strong></div></td>
    <td><div align="center"><strong>WHAT WE HAVE ON HAND</strong></div></td>
  </tr>


<!--Loop through all the products -->
<cfloop query="myquery">

<!-- Item does NOT have packages -->
<cfif myquery.Package IS 0>

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PID = #Val(myquery.pid)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfif GetBasicStats.MyQuantitySold GT myquery.MasterQuantity>
<cfoutput>
  <tr>
    <td><div align="center">#myQuery.SKUName#</div></td>
    <td><div align="center">#GetBasicStats.MyQuantitySold#</div></td>
    <td><div align="center">#myQuery.MasterQuantity#</div></td>
  </tr>
</cfoutput>
</cfif>

<!-- Item does have Packages -->
<cfelse>

<!-- Item has packages but uses Master Quantity -->
<cfif myquery.UseMQ is 1>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT ID, NuminPackage
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>


<cfset totalofthatpid = 0>
<cfloop query="GetPackageIDS">

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PackageID = #Val(GetPackageIDS.ID)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset totalofthatpid = totalofthatpid + Val(GetBasicStats.MyQuantitySold) * Val(GetPackageIDS.NuminPackage)>

</cfloop>

<cfif totalofthatpid GT myquery.MasterQuantity>
<cfoutput>
  <tr>
    <td><div align="center">#myQuery.SKUName#</div></td>
    <td><div align="center">#totalofthatpid#</div></td>
    <td><div align="center">#myQuery.MasterQuantity#</div></td>
  </tr>
</cfoutput>
</cfif>


<!-- Item has packages but does not use Master Quantity -->
<cfelse>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT ID, Title, NuminPackage, QQ
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>

<cfloop query="GetPackageIDS">
<cfset totalofthatpid = 0>

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PackageID = #Val(GetPackageIDS.ID)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset totalofthatpid = totalofthatpid + Val(GetBasicStats.MyQuantitySold) * Val(GetPackageIDS.NuminPackage)>

<cfif totalofthatpid GT GetPackageIDS.QQ>
<cfoutput>
  <TR BGCOLOR="#APPLICATION.SILVERTABLE2#">
    <td><div align="center">#GetPackageIDS.Title#*</div></td>
    <td><div align="center">#totalofthatpid#</div></td>
    <td><div align="center">#GetPackageIDS.QQ#</div></td>
  </tr>
</cfoutput>
</cfif>

</cfloop>

<!-- End of Item using Master Quantity -->
</cfif>


<!-- End if item has packages -->
</cfif>

<!-- End loop through products -->
</cfloop>
</table>

*Item does not Use Master Quantity and Inventory May be Off.

</cfcase>

<!--- *** Show last X Days --->
<cfcase value="showmegfs">

<cfset DATEMINUS=DateFormat(DateAdd("d", -#Val(form.daysgoback)#, DateFormat(Now(),"yyyy-mm-dd")),"yyyy-mm-dd")>
<cfset TODAY="#DateFormat(Now(),"yyyy-mm-dd")#">

<!--- Get All Active Products --->
<cfquery name="myQuery" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
	SELECT PID, SKUName, Package, UseMQ, MasterQuantity
	FROM #APPLICATION.DBPRE#ProductList
	WHERE Status = 1
ORDER BY SKUName
</CFQUERY>

<table width="75%" border="1" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td colspan="3"><div align="center"><strong><font size="+2">PRODUCT TRENDS FOR THE LAST <cfoutput>#form.daysgoback#</cfoutput> DAYS</font></strong></div></td>
  </tr>
  <tr>
    <td><div align="center"><strong>PRODUCT NAME</strong></div></td>
    <td><div align="center"><strong>TOTAL SOLD</strong></div></td>
    <td><div align="center"><strong>WHAT WE HAVE ON HAND</strong></div></td>
  </tr>


<!--Loop through all the products -->
<cfloop query="myquery">

<!-- Item does NOT have packages -->
<cfif myquery.Package IS 0>

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PID = #Val(myquery.pid)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset gfsq = 0>

<cftry>
<cfhttp url="http://www.getfastshipping.com/ws/inventoryws.cfm?qpid=#myquery.pid#&daysgoback=#form.daysgoback#&act=goback" timeout="2" throwOnError="yes">
<cfset gfsq = #trim(listGetAt(CFHTTP.FileContent, 2, "|"))#>
<cfcatch>
<cfset gfsq = 0>
</cfcatch>

</cftry>

<cfif GetBasicStats.MyQuantitySold GT 0>
<cfset grandtotal = GetBasicStats.MyQuantitySold + LSParseNumber(gfsq)>
<cfelse>
<cfset grandtotal = LSParseNumber(gfsq)>
</cfif>

<cfif grandtotal GT myquery.MasterQuantity>
<cfoutput>
  <tr>
    <td><div align="center">#myQuery.SKUName#</div></td>
    <td><div align="center">Q: #GetBasicStats.MyQuantitySold# Q&G: #grandtotal# G: #gfsq#</div></td>
    <td><div align="center">#myQuery.MasterQuantity#</div></td>
  </tr>
</cfoutput>
</cfif>

<!-- Item does have Packages -->
<cfelse>

<!-- Item has packages but uses Master Quantity -->
<cfif myquery.UseMQ is 1>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT ID, NuminPackage
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>


<cfset totalofthatpid = 0>
<cfloop query="GetPackageIDS">

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PackageID = #Val(GetPackageIDS.ID)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset totalofthatpid = totalofthatpid + Val(GetBasicStats.MyQuantitySold) * Val(GetPackageIDS.NuminPackage)>

</cfloop>

<cfset gfsq = 0>

<cftry>
<cfhttp url="http://www.getfastshipping.com/ws/inventoryws.cfm?qpid=#myquery.pid#&daysgoback=#form.daysgoback#&act=goback" timeout="2" throwOnError="yes">
<cfset gfsq = trim(listGetAt(CFHTTP.FileContent, 2, "|"))>
<cfcatch>
<cfset gfsq = 0>
</cfcatch>

</cftry>

<cfif totalofthatpid GT 0>
<cfset grandtotal = totalofthatpid + LSParseNumber(gfsq)>
<cfelse>
<cfset grandtotal = LSParseNumber(gfsq)>
</cfif>

<cfif grandtotal GT myquery.MasterQuantity>
<cfoutput>
  <tr>
    <td><div align="center">#myQuery.SKUName#</div></td>
    <td><div align="center">Q: #totalofthatpid# Q&G: #grandtotal# G: #gfsq#</div></td>
    <td><div align="center">#myQuery.MasterQuantity#</div></td>
  </tr>
</cfoutput>
</cfif>



<!-- Item has packages but does not use Master Quantity -->
<cfelse>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT ID, Title, NuminPackage, QQ
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>

<cfloop query="GetPackageIDS">
<cfset totalofthatpid = 0>

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PackageID = #Val(GetPackageIDS.ID)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset totalofthatpid = totalofthatpid + Val(GetBasicStats.MyQuantitySold) * Val(GetPackageIDS.NuminPackage)>

<cfset gfsq = 0>

<cftry>
<cfhttp url="http://www.getfastshipping.com/ws/inventoryws.cfm?qpid=#myquery.pid#&daysgoback=#form.daysgoback#&act=goback&qid=#GetPackageIDS.ID#" timeout="2" throwOnError="yes">
<cfset gfsq = trim(listGetAt(CFHTTP.FileContent, 2, "|"))>
<cfcatch>
<cfset gfsq = 0>
</cfcatch>

</cftry>

<cfset grandtotal = totalofthatpid + LSParseNumber(gfsq)>

<cfif grandtotal GT GetPackageIDS.QQ>
<cfoutput>
  <TR BGCOLOR="#APPLICATION.SILVERTABLE2#">
    <td><div align="center">#GetPackageIDS.Title#*</div></td>
    <td><div align="center">Q: #totalofthatpid# Q&G: #grandtotal# G: #gfsq#</div></td>
    <td><div align="center">#GetPackageIDS.QQ#</div></td>
  </tr>
</cfoutput>
</cfif>


</cfloop>

<!-- End of Item using Master Quantity -->
</cfif>


<!-- End if item has packages -->
</cfif>

<!-- End loop through products -->
</cfloop>
</table>

*Item does not Use Master Quantity and Inventory May be Off.

</cfcase>

<!--- *** Show last X Days --->
<cfcase value="sync">

<!--- Get All Active Products --->
<cfquery name="myQuery" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
	SELECT PID, SKUName, Package, UseMQ, MasterQuantity
	FROM #APPLICATION.DBPRE#ProductList
	WHERE Status = 1
ORDER BY SKUName
</CFQUERY>

<table width="75%" border="1" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td><div align="center"><strong>PRODUCT NAME</strong></div></td>
    <td><div align="center"><strong>OUR INVENTORY</strong></div></td>
    <td><div align="center"><strong>GFS INVENTORY</strong></div></td>
    <td><div align="center"><strong>UPDATED INVENTORY</strong></div></td>
  </tr>


<!--Loop through all the products -->
<cfloop query="myquery">

<!--- Item uses Master Quantity --->
<cfif myquery.UseMQ IS 1>

<cfset gfsq = 0>

<cftry>
<cfhttp url="http://www.getfastshipping.com/ws/inventoryws.cfm?qpid=#myquery.pid#&act=ci&qid=0&comp=q" timeout="2" throwOnError="yes">
<cfset gfsq = #trim(listGetAt(CFHTTP.FileContent, 2, "|"))#>
<cfcatch>
<cfset gfsq = 0>
</cfcatch>

</cftry>

<cfif LSParseNumber(gfsq) LT 0>
<cfset grandtotal = myquery.MasterQuantity + LSParseNumber(gfsq)>
<cfelse>
<cfset grandtotal = 0>
</cfif>

<cfif LSParseNumber(gfsq) LT 0>
<cfoutput>
  <tr>
    <td><div align="center">#myQuery.SKUName#</div></td>
    <td><div align="center">#myquery.MasterQuantity#</div></td>
    <td><div align="center">#LSParseNumber(gfsq)#</div></td>
    <td><div align="center">#grandtotal#</div></td>
  </tr>
</cfoutput>

<!--- Update the Product --->
<cfquery name="UpdateProduct" datasource="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
UPDATE #APPLICATION.DBPRE#ProductList
SET MasterQuantity = #Val(grandtotal)#
WHERE PID = #Val(myQuery.PID)#
</cfquery>

</cfif>

<!--- Item does not use Master Quantity --->


<cfelse>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT ID, NuminPackage, QQ, Title
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>

<!--Loop through all the packages for that product -->
<cfloop query="GetPackageIDS">

<cfset gfsq = 0>

<cftry>
<cfhttp url="http://www.getfastshipping.com/ws/inventoryws.cfm?qpid=#myquery.pid#&act=ci&qid=#GetPackageIDS.ID#&comp=q" timeout="2" throwOnError="yes">
<cfset gfsq = #trim(listGetAt(CFHTTP.FileContent, 2, "|"))#>
<cfcatch>
<cfset gfsq = 0>
</cfcatch>

</cftry>

<cfif LSParseNumber(gfsq) LT 0>
<cfset grandtotal = GetPackageIDS.QQ + LSParseNumber(gfsq)>
<cfelse>
<cfset grandtotal = 0>
</cfif>

<cfif LSParseNumber(gfsq) LT 0>
<cfoutput>
  <tr>
    <td><div align="center">#GetPackageIDS.Title#</div></td>
    <td><div align="center">#GetPackageIDS.QQ#</div></td>
    <td><div align="center">#LSParseNumber(gfsq)#</div></td>
    <td><div align="center">#grandtotal#</div></td>
  </tr>
</cfoutput>

<!--- Update the Product --->
<cfquery name="UpdateProduct" datasource="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
UPDATE ProductPackages
SET QQ = #Val(grandtotal)#
WHERE ID = #Val(GetPackageIDS.ID)#
</cfquery>

</cfif>

</cfloop>



<!-- End if item has packages -->
</cfif>

<!-- End loop through products -->
</cfloop>
</table>

</cfcase>

<!--- *** Generate File with PID, SKUName/Package Name, Quantity Sold --->
<cfcase value="genFile">

<cfset tab = chr(9)>
<cfset NewLine = Chr(13) & Chr(10)>

<cfset Str = "">
<cfset StrP = "">

<cfset DATEMINUS=DateFormat(DateAdd("d", -#Val(form.daysgoback)#, DateFormat(Now(),"yyyy-mm-dd")),"yyyy-mm-dd")>
<cfset TODAY="#DateFormat(Now(),"yyyy-mm-dd")#">

<!--- Get All Active Products --->
<cfquery name="myQuery" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
	SELECT PID, SKUName, Package, UseMQ, MasterQuantity
	FROM #APPLICATION.DBPRE#ProductList
	WHERE Status = 1 AND PID < 300
ORDER BY SKUName
</CFQUERY>

<!--Loop through all the products -->
<cfloop query="myquery">

<!-- Item does NOT have packages -->
<cfif myquery.Package IS 0>

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PID = #Val(myquery.pid)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset StrP = "">
<cfif GetBasicStats.MyQuantitySold GT 0>
<cfset Str = Str & myQuery.PID & tab & myQuery.SKUName & tab & GetBasicStats.MyQuantitySold & tab>
<cfelse>
<cfset Str = Str & myQuery.PID & tab & myQuery.SKUName & tab & "0" & tab>
</cfif>

<cfset Str = Str & StrP & NewLine>
<cfoutput>
#GetBasicStats.MyQuantitySold#
</cfoutput>


<!-- Item does have Packages -->
<cfelse>

<!-- Item has packages but uses Master Quantity -->
<cfif myquery.UseMQ is 1>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT ID, NuminPackage
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>


<cfset totalofthatpid = 0>
<cfloop query="GetPackageIDS">

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PackageID = #Val(GetPackageIDS.ID)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset totalofthatpid = totalofthatpid + Val(GetBasicStats.MyQuantitySold) * Val(GetPackageIDS.NuminPackage)>

</cfloop>

<cfset StrP = "">
<cfif totalofthatpid GT 0>
<cfset Str = Str & myQuery.PID & tab & myQuery.SKUName & tab & totalofthatpid & tab>
<cfelse>
<cfset Str = Str & myQuery.PID & tab & myQuery.SKUName & tab & "0" & tab>
</cfif>
<cfset Str = Str & StrP & NewLine>


<!-- Item has packages but does not use Master Quantity -->
<cfelse>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT ID, Title, NuminPackage, QQ
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>

<cfloop query="GetPackageIDS">
<cfset totalofthatpid = 0>

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PackageID = #Val(GetPackageIDS.ID)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset totalofthatpid = totalofthatpid + Val(GetBasicStats.MyQuantitySold) * Val(GetPackageIDS.NuminPackage)>

<cfset StrP = "">
<cfif totalofthatpid GT 0>
<cfset Str = Str & myQuery.PID & tab & GetPackageIDS.Title & tab & totalofthatpid & tab>
<cfelse>
<cfset Str = Str & myQuery.PID & tab & GetPackageIDS.Title & tab & "0" & tab>
</cfif>
<cfset Str = Str & StrP & NewLine>


</cfloop>

<!-- End of Item using Master Quantity -->
</cfif>


<!-- End if item has packages -->
</cfif>

<!-- End loop through products -->
</cfloop>
<cfoutput>
#Str#
 <cffile action="write" nameConflict="overwrite" output="#Str#" file="D:\Websites\GetFastShipping\quick2you\store\kj7sh892\scart\test.txt" addnewline="no">
</cfoutput>
</cfcase>

<!--- *** Get Total Value Inventory --->
<cfcase value="getvalue">

<!--- Get All Active Products --->
<cfquery name="myQuery" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
	SELECT PID, Cost, Package, MasterQuantity, UseMQ
	FROM #APPLICATION.DBPRE#ProductList
ORDER BY SKUName
</CFQUERY>

<cfset totalinventory = 0>

<!--Loop through all the products -->
<cfloop query="myquery">

<!-- Item does NOT have packages -->
<cfif myquery.Package IS 0>


<cfif myQuery.MasterQuantity GT 0>
<cfset totalinventory = totalinventory + Val(myQuery.MasterQuantity) * Val(myQuery.Cost)>
</cfif>

<!-- Item does have Packages -->
<cfelse>

<!-- Item has packages but uses Master Quantity -->
<cfif myquery.UseMQ is 1>

<cfif myQuery.MasterQuantity GT 0>
<cfset totalinventory = totalinventory + Val(myQuery.MasterQuantity) * Val(myQuery.Cost)>
</cfif>

<!-- Item has packages but does not use Master Quantity -->
<cfelse>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Cost, QQ
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>

<cfloop query="GetPackageIDS">

<cfif GetPackageIDS.QQ GT 0>
<cfset totalinventory = totalinventory + Val(GetPackageIDS.QQ) * Val(GetPackageIDS.Cost)>
</cfif>

</cfloop>

<!-- End of Item using Master Quantity -->
</cfif>


<!-- End if item has packages -->
</cfif>

<!-- End loop through products -->
</cfloop>

Total Inventory: <cfoutput>#DollarFormat(totalinventory)#</cfoutput>

</cfcase>

<!--- *** 30 Day Supply --->
<cfcase value="showme2">

<cfif NOT IsDefined("form.daysgoback")>
<cfset form.daysgoback = 90>
</cfif>

<cfset DATEMINUS=DateFormat(DateAdd("d", -#Val(form.daysgoback)#, DateFormat(Now(),"yyyy-mm-dd")),"yyyy-mm-dd")>
<cfset TODAY="#DateFormat(Now(),"yyyy-mm-dd")#">

<!--- Get All Active Products --->
<cfquery name="myQuery" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
	SELECT PID, SKUName, Package, UseMQ, MasterQuantity, Cost
	FROM #APPLICATION.DBPRE#ProductList
	WHERE Status = 1
ORDER BY SKUName
</CFQUERY>

<table width="75%" border="1" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td colspan="5"><div align="center"><strong><font size="+2">SUPPLY FORCAST FOR THE PAST <cfoutput>#form.daysgoback#</cfoutput> DAYS</font></strong></div></td>
  </tr>
  <tr>
    <td><div align="center"><strong>PRODUCT NAME</strong></div></td>
    <td><div align="center"><strong>SALES</strong></div></td>
    <td><div align="center"><strong>WHAT WE HAVE ON HAND</strong></div></td>
    <td><div align="center"><strong>DAY SUPPLY</strong></div></td>.
    <td><div align="center"><strong>COST</strong></div></td>
  </tr>


<!--Loop through all the products -->
<cfloop query="myquery">

<!-- Item does NOT have packages -->
<cfif myquery.Package IS 0>

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PID = #Val(myquery.pid)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfif IsDefined("url.zero")>
<cfif myQuery.MasterQuantity GT 0>
<cfoutput>
  <tr>
    <td><div align="center">#myQuery.SKUName#</div></td>
    <td><div align="center"><cfif GetBasicStats.MyQuantitySold GT 0>#GetBasicStats.MyQuantitySold#<cfelse>0</cfif></div></td>
    <td><div align="center">#myQuery.MasterQuantity#</div></td>
    <td><div align="center"><cfif GetBasicStats.MyQuantitySold GT 0>#Trim(NumberFormat(myQuery.MasterQuantity*form.daysgoback/GetBasicStats.MyQuantitySold, "(999999.99)"))#<cfelseif myQuery.MasterQuantity is 0>NONE<cfelse>++++</cfif></div></td>
    <td><div align="center">#myQuery.Cost#</div></td>
  </tr>
</cfoutput>
</cfif>
<cfelse>
<cfoutput>
  <tr>
    <td><div align="center">#myQuery.SKUName#</div></td>
    <td><div align="center"><cfif GetBasicStats.MyQuantitySold GT 0>#GetBasicStats.MyQuantitySold#<cfelse>0</cfif></div></td>
    <td><div align="center">#myQuery.MasterQuantity#</div></td>
    <td><div align="center"><cfif GetBasicStats.MyQuantitySold GT 0>#Trim(NumberFormat(myQuery.MasterQuantity*form.daysgoback/GetBasicStats.MyQuantitySold, "(999999.99)"))#<cfelseif myQuery.MasterQuantity is 0>NONE<cfelse>++++</cfif></div></td>
    <td><div align="center">#myQuery.Cost#</div></td>
  </tr>
</cfoutput>
</cfif>

<!-- Item does have Packages -->
<cfelse>

<!-- Item has packages but uses Master Quantity -->
<cfif myquery.UseMQ is 1>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT ID, NuminPackage
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>


<cfset totalofthatpid = 0>
<cfloop query="GetPackageIDS">

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PackageID = #Val(GetPackageIDS.ID)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset totalofthatpid = totalofthatpid + Val(GetBasicStats.MyQuantitySold) * Val(GetPackageIDS.NuminPackage)>

</cfloop>

<cfif IsDefined("url.zero")>
<cfif myQuery.MasterQuantity GT 0>
<cfoutput>
  <tr>
    <td><div align="center">#myQuery.SKUName#</div></td>
    <td><div align="center">#totalofthatpid#</div></td>
    <td><div align="center">#myQuery.MasterQuantity#</div></td>
    <td><div align="center"><cfif totalofthatpid GT 0>#Trim(NumberFormat(myQuery.MasterQuantity*form.daysgoback/totalofthatpid, "(999999.99)"))#<cfelseif myQuery.MasterQuantity is 0>NONE<cfelse>++++</cfif></div></td>
    <td><div align="center">#myQuery.Cost#</div></td>
  </tr>
</cfoutput>
</cfif>
<cfelse>
<cfoutput>
  <tr>
    <td><div align="center">#myQuery.SKUName#</div></td>
    <td><div align="center">#totalofthatpid#</div></td>
    <td><div align="center">#myQuery.MasterQuantity#</div></td>
    <td><div align="center"><cfif totalofthatpid GT 0>#Trim(NumberFormat(myQuery.MasterQuantity*form.daysgoback/totalofthatpid, "(999999.99)"))#<cfelseif myQuery.MasterQuantity is 0>NONE<cfelse>++++</cfif></div></td>
    <td><div align="center">#myQuery.Cost#</div></td>
  </tr>
</cfoutput>
</cfif>


<!-- Item has packages but does not use Master Quantity -->
<cfelse>

<!--- Get Package IDS of PIDS --->
<cfquery name="GetPackageIDS" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT ID, Title, NuminPackage, QQ
FROM ProductPackages
WHERE PID = #Val(myquery.pid)#
</cfquery>

<cfloop query="GetPackageIDS">
<cfset totalofthatpid = 0>

<!--- Get Total Quantity Sold in that time period --->
<cfquery name="GetBasicStats" DATASOURCE="#APPLICATION.DB#" USERNAME="#APPLICATION.UN#" PASSWORD="#APPLICATION.PW#">
SELECT Sum(Quantity) as MyQuantitySold
FROM OCOrderCart
WHERE PackageID = #Val(GetPackageIDS.ID)# and CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#'
AND CustomerID IN (SELECT CustomerID FROM OCOrders WHERE CreatedDate >= '#DATEMINUS#' AND CreatedDate <= '#TODAY#' AND Status = 3)
</cfquery>

<cfset totalofthatpid = totalofthatpid + Val(GetBasicStats.MyQuantitySold) * Val(GetPackageIDS.NuminPackage)>

<cfif IsDefined("url.zero")>
<cfif GetPackageIDS.QQ GT 0>
<cfoutput>
  <tr>
    <td><div align="center">#GetPackageIDS.Title#*</div></td>
    <td><div align="center">#totalofthatpid#</div></td>
    <td><div align="center">#GetPackageIDS.QQ#</div></td>
    <td><div align="center"><cfif totalofthatpid GT 0>#Trim(NumberFormat(GetPackageIDS.QQ*form.daysgoback/totalofthatpid, "(999999.99)"))#<cfelseif GetPackageIDS.QQ is 0>NONE<cfelse>++++</cfif></div></td>
    <td><div align="center">#myQuery.Cost#</div></td>
  </tr>
</cfoutput>
</cfif>
<cfelse>
<cfoutput>
  <tr>
    <td><div align="center">#GetPackageIDS.Title#*</div></td>
    <td><div align="center">#totalofthatpid#</div></td>
    <td><div align="center">#GetPackageIDS.QQ#</div></td>
    <td><div align="center"><cfif totalofthatpid GT 0>#Trim(NumberFormat(GetPackageIDS.QQ*form.daysgoback/totalofthatpid, "(999999.99)"))#<cfelseif GetPackageIDS.QQ is 0>NONE<cfelse>++++</cfif></div></td>
    <td><div align="center">#myQuery.Cost#</div></td>
  </tr>
</cfoutput>
</cfif>

</cfloop>

<!-- End of Item using Master Quantity -->
</cfif>


<!-- End if item has packages -->
</cfif>

<!-- End loop through products -->
</cfloop>
</table>

*Item does not Use Master Quantity and Inventory May be Off.

</cfcase>


</cfswitch>

<cfelse>
	<cflocation url="index.cfm?page=orders&act=view&missing=y" ADDTOKEN="No">
</cfif>