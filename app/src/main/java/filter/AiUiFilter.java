package filter;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import dao.AiUiDao;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import model.AiUiConfig;

/**
 * 在企業AI 頁面載入資料庫設定，供 JSP 顯示。
 */
public class AiUiFilter implements Filter {

    private static final Logger LOGGER = Logger.getLogger(AiUiFilter.class.getName());

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        try {
            request.setAttribute("aiUi", new AiUiDao().load());
        } catch (RuntimeException e) {
            LOGGER.log(Level.WARNING, "載入 AI 頁面設定失敗，使用預設值", e);
            request.setAttribute("aiUi", AiUiConfig.defaults());
        }
        chain.doFilter(request, response);
    }

    @Override
    public void init(FilterConfig filterConfig) {
    }

    @Override
    public void destroy() {
    }
}
