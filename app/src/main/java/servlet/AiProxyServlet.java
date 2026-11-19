package servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

@WebServlet("/AiProxyServlet")
public class AiProxyServlet extends HttpServlet {

    private static final String TARGET = "http://ai-gateway:8080/test.html";
    private static final String API_KEY_BOOTSTRAP = "<script>(function(){"
            + "try{localStorage.setItem('gwApiKey','__CHARPHONE_API_PROXY__');}catch(e){}"
            + "document.addEventListener('DOMContentLoaded',function(){"
            + "var input=document.getElementById('apiKey');"
            + "if(!input){return;}"
            + "var card=input.closest('.card');"
            + "if(!card){return;}"
            + "var note=document.createElement('div');"
            + "note.className='card';"
            + "note.style.cssText='padding:10px 16px;font-size:13px;color:#4361ee;';"
            + "note.textContent='API Key 已由 CharPhone 伺服器認證，無需輸入。';"
            + "card.parentNode.insertBefore(note,card);"
            + "card.style.display='none';"
            + "});"
            + "})();</script>";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            HttpClient client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
            HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(TARGET)).timeout(Duration.ofSeconds(20)).GET();
            String apiKey = System.getenv("AI_GATEWAY_API_KEY");
            if (apiKey != null && !apiKey.isBlank()) {
                builder.header("X-API-Key", apiKey.trim());
            }
            HttpRequest request = builder.build();
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            resp.setStatus(response.statusCode());
            resp.setContentType(response.headers().firstValue("Content-Type").orElse("text/html; charset=UTF-8"));
            resp.getWriter().write(injectApiKeyBootstrap(response.body()));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, e.getMessage());
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY, e.getMessage());
        }
    }

    private String injectApiKeyBootstrap(String html) {
        int bodyIndex = html.indexOf("<body");
        if (bodyIndex < 0) {
            return html + API_KEY_BOOTSTRAP;
        }
        int bodyTagEnd = html.indexOf('>', bodyIndex);
        if (bodyTagEnd < 0) {
            return html + API_KEY_BOOTSTRAP;
        }
        return html.substring(0, bodyTagEnd + 1)
                + API_KEY_BOOTSTRAP
                + html.substring(bodyTagEnd + 1);
    }
}
