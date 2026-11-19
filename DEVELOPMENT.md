# 開發說明

## 需求

- Docker Desktop / Docker Engine + Compose v2
- 若要在容器外建置：JDK 17、Maven 3.9+

## 啟動

```bash
docker compose up -d --build
docker compose logs -f web
```

- 應用：<http://localhost:8080>
- 資料庫：僅限 Compose 內部網路，不會發布到主機
- 預設登入：`admin` / `demo1234`

## 建置與測試

```bash
cd app
mvn test
mvn clean package -DskipTests
```

WAR 產出於 `app/target/ROOT.war`。`app/Dockerfile` 為 multi-stage build，會自動在容器內完成 Maven 建置。

## 資料庫

- 主機：`db`（Compose 内）
- Port：`3306`
- Database：`mydb`
- 應用帳號與唯讀帳號由 `docker/mysql-init/` 建立
- 遷移腳本：`app/src/main/resources/db/migration/`

Flyway 於 `FlywayListener` 啟動時執行，連線資訊來自環境變數 `DB_URL`、`DB_USER`、`DB_PASS`、`DB_RO_USER`、`DB_RO_PASS`。缺少任一變數會 fail-fast。

### 新增 migration

1. 建立 `V5__描述.sql`。
2. 只新增版本，不修改已套用的 `V1`～`V4`。
3. 重建容器讓 Flyway 套用：

```bash
docker compose restart web
```

若需要在既有 DB 上重跑，請先 `docker compose down -v`。

## 程式分層

```
Request → Servlet（參數驗證/路由）
        → DAO（僅 CRUD）
        → Model（純資料）
```

- Servlet 不直接寫 SQL。
- DAO 不處理業務規則。
- JDBC 資源使用 try-with-resources。
- 例外與關鍵操作使用 `java.util.logging.Logger`。

## 前端

- JSP + JSTL，樣式集中於 `app/src/main/webapp/css/`。
- 共用行為（CSRF header、GET 寫入攔截、badge 樣式）在 `js/common.js`。
- `js/vendor/` 內含第三方函式庫，請保留其授權檔。

## 截圖

`docs/screenshots/` 供 README 或展示使用。新增截圖前請確認：

- 使用示範資料，不可出現真實客戶或員工資訊。
- 瀏覽器網址列、書籤列與通知不要入鏡。
- 建議寬度 1440px，PNG 格式。

## 常見問題

**web 容器一直重啟**
查看 `docker compose logs web`。最常見原因是資料庫尚未 healthy，或 `.env` 中的密碼與既有 `mysql_data` volume 不一致。開發時可直接 `docker compose down -v` 重建。

**Flyway checksum mismatch**
表示已套用的 migration 被修改。請還原該檔案，或重建資料庫。

**連接埠 8080 被占用**
修改 `docker-compose.yaml` 的 `127.0.0.1:8080:8080` 左側連接埠。
