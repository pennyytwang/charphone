# CharPhone 訂單管理系統

以翻砂工廠（金屬鑄造）為情境的訂單管理示範系統。涵蓋接單、生產工單、出貨、應收帳款、庫存與客戶/產品管理，適用人數精簡的行政團隊。

> 這是一個公開展示版。所有客戶、產品、人員、統編、電話、地址與金額皆為虛構資料，不含任何真實營運資訊。

## 功能

- 訂單管理：建立/編輯訂單、查詢、結案、批次匯入
- 生產管理：工單排程、生產進度、完工與暫停
- 出貨管理：部分出貨/取消出貨、出貨明細
- 應收帳款：開帳、收款狀態、帳齡查詢
- 庫存管理：原料/半成品/成品、入出庫、調撥、盤盈盤虧
- 客戶 / 產品 / 倉庫基本資料
- 使用者管理、存取碼（Magic Link）與唯讀展示模式
- AI 專區：可選擇串接 [enterprise-ai-gateway](https://github.com/pennyytwang/enterprise-ai-gateway)（需另外啟動）

## 技術棧

- Java 17、Maven、WAR
- Jakarta Servlet 6.0、JSP 3.1、JSTL
- MySQL 8.0、Flyway、HikariCP
- Docker Compose（Tomcat 10 + MySQL 8）

## 快速開始

需求：Docker Desktop（或 Docker Engine + Compose v2）。

```bash
docker compose up -d --build
```

開啟 <http://localhost:8080>，使用示範帳號登入：

| 帳號 | 密碼 |
|------|------|
| `admin` | `demo1234` |

首次啟動會由 Flyway 建立資料表並載入虛構示範資料。若 8080 已被占用，可修改 `docker-compose.yaml` 的連接埠。

### 重置資料庫

```bash
docker compose down -v
docker compose up -d --build
```

### 自訂環境變數

```bash
cp .env.example .env
```

`docker-compose.yaml` 已提供可直接啟動的示範預設值；正式環境請務必覆寫所有密碼，並使用高強度隨機值。

## 目錄結構

```
app/
  src/main/java/servlet/      Servlet 控制層
  src/main/java/dao/          JDBC 資料存取層
  src/main/java/model/        資料模型
  src/main/java/filter/       AuthFilter、CsrfFilter 等
  src/main/java/listener/     Flyway 啟動遷移
  src/main/webapp/            JSP 頁面與前端資源
  src/main/resources/db/migration/  Flyway 遷移腳本
docker/mysql-init/            建立 app / 唯讀 DB 帳號
docs/                         補充文件與截圖
```

## 資料庫遷移

| 版本 | 內容 |
|------|------|
| `V1__schema.sql` | 資料表結構與第一位 admin |
| `V2__demo_access_tokens.sql` | 存取碼資料表 |
| `V3__ai_ui_settings.sql` | AI 頁面設定資料表 |
| `V4__demo_seed.sql` | 虛構示範資料 |

新增變更請建立 `V5__xxx.sql`，不要修改已套用的 migration。

## AI 專區（選用）

CharPhone 的 AI 頁面會將請求代理到容器內主機 `ai-gateway:8080`。若要啟用：

1. 啟動 [enterprise-ai-gateway](https://github.com/pennyytwang/enterprise-ai-gateway) 的 demo 環境：

   ```bash
   cd enterprise-ai-gateway/ops/deploy
   cp .env.example .env   # 填入 GEMINI_API_KEY
   docker compose up -d
   ```

2. 兩個 Compose 專案預設都使用 `charphone_demo` network，Gateway 服務名稱為 `ai-gateway`，CharPhone 可直接連線。
3. CharPhone 的 web 容器已預設注入示範金鑰 `demo-api-key-charphone`。

未串接 Gateway 或未設定 LLM 金鑰時，其餘訂單/生產/庫存功能均可正常使用，只有 AI 問答會失敗。

## 開發

```bash
cd app
mvn test
mvn clean package -DskipTests
```

詳細開發說明未隨公開版發布。

## 安全說明

- 所有頁面皆需登入，密碼使用 BCrypt。
- POST 請求具 CSRF 驗證；登入成功後會更換 session。
- 唯讀帳號在資料庫層使用獨立唯讀連線，並在應用層限制寫入路徑。
- 客戶 PII 在唯讀 session 中會遮罩。
- 示範用的預設密碼僅供本機測試，請勿沿用。

## 授權

[MIT](LICENSE)
