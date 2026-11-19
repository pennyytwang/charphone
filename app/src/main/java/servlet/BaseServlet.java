package servlet;

import jakarta.servlet.http.HttpServlet;

public abstract class BaseServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected String redirect(String path, String message) {
        String ctx = getServletContext().getContextPath();
        return ctx + "/" + path + (message != null ? "?message=" + message : "");
    }

    protected String redirect(String path, String param, String value) {
        String ctx = getServletContext().getContextPath();
        return ctx + "/" + path + "?" + param + "=" + value;
    }

    protected int parseInt(String s) {
        try { return Integer.parseInt(s); } catch (Exception e) { return 0; }
    }

    protected String emptyToNull(String s) {
        return (s == null || s.trim().isEmpty()) ? null : s.trim();
    }
}
