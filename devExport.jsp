<%@page contentType="text/html"%>
<%@page pageEncoding="UTF-8"%>

<%@ page import="java.io.PrintWriter" %>
<%@ page import="java.io.FileWriter" %>
<%@ page import="java.io.FileInputStream" %>
<%@ page import="java.io.File" %>
<%@ page import="com.foxbright.io.TempFileManager" %>
<%@ page import="com.foxbright.qbbridge.qbxml.QBRequest" %>
<%@ page import="com.foxbright.qbbridge.qbxml.QBXMLGenerator" %>
<%@ page import="com.foxbright.qbbridge.qbobject.*" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.foxbright.db.DbConnection" %>
<%@ page import="com.foxbright.db.DatabaseConfig" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>

<%
   
    try {
        // Create database connection for use on this page.
        DatabaseConfig dbConfig = DatabaseConfig.getInstance();

        DbConnection conn = new DbConnection(dbConfig);
        CallableStatement callStmt = null;
        ResultSet results = null;

        callStmt = conn.getCallableStatement("{ call retrieveCustomersForExport() }");
        results = callStmt.executeQuery();
		FileWriter fw = new FileWriter("cust.csv");
		
        while (results.next()) {
					
			String billingAddr = new StringBuilder(results.getString("Name")).append(",")
            		.append(results.getString("MailAddress1")).append(",")
                    .append(results.getString("MailAddress2")).append(",")
            		.append(results.getString("MailCity")).append(",")
                    .append(results.getString("MailState")).append(",")
            		.append(results.getString("MailZip")).append(",")
                    .append(results.getString("MailCountry")).toString();
            
            String shippingAddr = new StringBuilder(results.getString("Address1")).append(",")
                    .append(results.getString("Address2")).append(",")
					.append(results.getString("City")).append(",")
                    .append(results.getString("State")).append(",")
					.append(results.getString("Zip")).append(",")
                    .append(results.getString("Country")).toString();

            String cust = new StringBuilder(results.getString("Name")).append(",")
                    .append(results.getString("IsActive")).append(",")
                    .append(billingAddr).append(",")
                    .append(shippingAddr).append(",")
                    .append(results.getString("Phone")).append(",")
                    .append(results.getString("Fax")).append(",")
                    .append(new ListRef(results.getString("Terms"))).append(",")
                    .append(new ListRef(results.getString("TaxExempt"))).toString();
            
			
			fw.write("");
        }
		fw.close();
		

        callStmt = conn.getCallableStatement("{ call retrieveNewJobsForExport() }");
        results = callStmt.executeQuery();
        while (results.next()) {
            QBAddress billingAddr = new QBAddress(results.getString("Customer"),
            		results.getString("BillTo_Address1"), results.getString("BillTo_Address2"),
            		results.getString("BillTo_City"), results.getString("BillTo_State"),
            		results.getString("BillTo_Zip"), "");

            QBAddress shippingAddr = new QBAddress(results.getString("Customer"),
            		results.getString("ShipTo_Address1"), results.getString("ShipTo_Address2"),
            		results.getString("ShipTo_City"), results.getString("ShipTo_State"),
            		results.getString("ShipTo_Zip"), "");

            QBCustomerJob job = new QBCustomerJob(results.getString("JobNumber"),
                    new ListRef(results.getString("Customer")), billingAddr, shippingAddr,
                    results.getString("Phone"), results.getString("Fax"),
                    results.getString("JobStatus"), new ListRef(results.getString("JobType")));

            objects.add(job);
        }

        callStmt = conn.getCallableStatement("{ call retrieveVendorsForExport() }");
        results = callStmt.executeQuery();
        while (results.next()) {
            QBAddress addr = new QBAddress(results.getString("Name"),
            		results.getString("Address1"), results.getString("Address2"),
					results.getString("City"), results.getString("State"),
					results.getString("Zip"), results.getString("Country"));

            QBVendor vend = new QBVendor(results.getString("Name"),
                    results.getString("FirstName"), results.getString("MiddleInitial"),
                    results.getString("LastName"), addr, results.getString("Phone"),
                    results.getString("AltPhone"), results.getString("Fax"),
                    results.getString("Email"),
                    new ListRef(results.getString("Terms")),
                    results.getDouble("CreditLimit"), results.getString("TaxId"));

            objects.add(vend);
        }

        callStmt = conn.getCallableStatement("{ call retrieveInventoryForExport() }");
        results = callStmt.executeQuery();
        while (results.next()) {
            QBInventory inv = new QBInventory(results.getString("PartNumber"),
                    results.getString("Description"), results.getDouble("RetailPrice"),
                    results.getString("Description"), results.getDouble("Cost"),
                    results.getInt("ReorderQty"), results.getInt("CountOnHand"));

            objects.add(inv);
        }

        callStmt = conn.getCallableStatement("{ call retrievePurchaseOrdersForExport() }");
        results = callStmt.executeQuery();
        while (results.next()) {
            QBAddress vendorAddr = new QBAddress(results.getString("VendorName"),
            		results.getString("Address1"), results.getString("Address2"),
					results.getString("City"), results.getString("State"),
					results.getString("Zip"), results.getString("Country"));

            QBAddress shippingAddr = new QBAddress(results.getString("ShipToCompanyName"),
                    results.getString("ShipToAddress1"), results.getString("ShipToAddress2"),
                    results.getString("ShipToCity"), results.getString("ShipToState"),
                    results.getString("ShipToZip"), results.getString("ShipToCountry"));

            QBPurchaseOrder po = new QBPurchaseOrder(new ListRef(results.getString("VendorName")),
                    new ListRef(results.getString("ShipToEntityRef")),
                    new java.util.Date(results.getDate("PODate").getTime()),
                    results.getString("PoNumber"),
                    vendorAddr, shippingAddr, new ListRef(results.getString("Terms")),
                    new ListRef(results.getString("ShipVia")),
                    results.getString("FOB"), results.getString("Memo"), results.getString("VendorMsg"));

            CallableStatement callStmt2 = conn.getCallableStatement("{ call retrievePurchaseOrdersLIForExport(?) }");
            callStmt2.setString(1, results.getString("PurchaseOrderID_PK"));
            ResultSet results2 = callStmt2.executeQuery();
            List lineItems = new ArrayList();
            while (results2.next()) {
                QBPurchaseOrderLine line = new QBPurchaseOrderLine(new ListRef(results2.getString("PartNumber")),
                        results2.getString("Description"), results2.getInt("Qty"),
                        results2.getString("UnitPrice"), results2.getString("ExtendedPrice"));

                lineItems.add(line);
            }
            po.setLineItems(lineItems);

            objects.add(po);
        }

        callStmt = conn.getCallableStatement("{ call retrieveInvoicesForExport() }");
        results = callStmt.executeQuery();
        while (results.next()) {
            QBAddress billAddr = new QBAddress(results.getString("BillTo_AddressLine1"),
                    results.getString("BillTo_AddressLine2"), results.getString("BillTo_AddressLine3"),
                    results.getString("BillTo_AddressCity"), results.getString("BillTo_AddressState"),
                    results.getString("BillTo_AddressZip"), "");

            QBAddress shipAddr = new QBAddress(results.getString("Address1"),
                    results.getString("Address2"), results.getString("Address3"),
                    results.getString("City"), results.getString("State"),
                    results.getString("Zip"), results.getString("Country"));

            QBInvoice invoice = new QBInvoice(new ListRef(results.getString("CustomerRef")),
                    new java.util.Date(results.getDate("TxnDate").getTime()), results.getString("ServiceInvoiceID_PK"),
                    billAddr, shipAddr, results.getString("PONumber"),
                    new ListRef(results.getString("Terms")), results.getString("Memo"));

            CallableStatement callStmt2 = conn.getCallableStatement("{ call retrieveInvoicesLIForExport(?) }");
            callStmt2.setString(1, invoice.getRefNumber());
            ResultSet results2 = callStmt2.executeQuery();
            List lineItems = new ArrayList();
            while (results2.next()) {
                QBInvoiceLine line = new QBInvoiceLine(new ListRef(results2.getString("ItemRef")),
                        results2.getString("Description"), results2.getDouble("Quantity"),
                        results2.getDouble("Rate"), results2.getDouble("Amount"),
                        new ListRef(results2.getString("TaxCode")));

                lineItems.add(line);
            }
            invoice.setLineItems(lineItems);

            objects.add(invoice);
        }
		
		
	/*

        // save all the objects for exporting to a temp file.
        PrintWriter pw = new PrintWriter(new FileWriter(myTmp));
         QBXMLGenerator g = new QBXMLGenerator(pw);
         g.generateRequest(QBRequest.ADD, objects);


        // the following prompts the user to save the temp file.
         FileInputStream in = new FileInputStream(myTmp);
        response.setContentType("application/xml");
         response.setHeader("Content-Disposition", "attachment; filename=" + myTmp.getName());

         out.clearBuffer();  // removes the whitespace at the beginning of the file
        int i;
         while ((i=in.read()) != -1) {
             out.write(i);
         }
         in.close();
         out.close();
*/
    }
    catch(Exception e) {
        // an error occured, redirect to error page
        //String redirectURL = "exporterror.jsp";
        //response.sendRedirect(redirectURL);
    }
%>

 