<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.Map, dao.OrderDao, util.NumberUtil" %>
<%
    String id = request.getParameter("id");
    if (id == null || id.isEmpty()) {
        out.print("[]");
        return;
    }

    OrderDao dao = new OrderDao();
    StringBuilder json = new StringBuilder("[");
    try {
        boolean first = true;
        for (Map<String, Object> row : dao.getOrderProductionData(Integer.parseInt(id))) {
            if (!first) json.append(",");
            first = false;
            json.append("{");
            json.append("\"product_id\":").append(row.get("product_id")).append(",");
            json.append("\"product_name\":\"").append(row.get("product_name") != null ? ((String)row.get("product_name")).replace("\"", "\\\"") : "").append("\",");
            json.append("\"price_type\":").append(row.get("price_type")).append(",");
            json.append("\"unit_price\":").append(row.get("unit_price") != null ? row.get("unit_price") : "null").append(",");
            json.append("\"unit_weight\":").append(row.get("unit_weight") != null ? row.get("unit_weight") : "null").append(",");
            json.append("\"quantity\":").append(row.get("quantity")).append(",");
            json.append("\"total_manufactured\":").append(row.get("total_manufactured")).append(",");
            json.append("\"production_count\":").append(row.get("production_count")).append(",");
            json.append("\"total_produced_qty\":").append(row.get("total_produced_qty")).append(",");
            json.append("\"expected_delivery_date\":").append(row.get("expected_delivery_date") != null ? "\"" + row.get("expected_delivery_date") + "\"" : "null").append(",");
            json.append("\"actual_amount\":").append(row.get("actual_amount") != null ? "\"" + row.get("actual_amount") + "\"" : "null");
            json.append("}");
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    json.append("]");
    out.print(json.toString());
%>
