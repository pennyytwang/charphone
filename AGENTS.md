# AGENTS.md — CharPhone 公開展示版開發指引

> 這是公開展示版（demo），不是正式營運版。任何 AI 助手或開發者動手前先讀本文件。
> 正式營運版在私有 repo `pennyytwang/charphone-ops`；本 repo 不可用於正式部署。

## 1. Repo 分工

| 角色 | 本機路徑 | GitHub | 用途 |
|---|---|---|---|
| 公開展示版 | `C:\project\public\charphone` | `pennyytwang/charphone` | 虛構 demo 資料、可公開的程式與設定 |
| 私有正式版 | `C:\project\charphone` | `pennyytwang/charphone-ops` | 正式客戶資料、正式 `.env`、nginx、部署腳本、handover 文件 |

- 兩者是**獨立 git history**，沒有共同祖先。
- 禁止 merge、cherry-pick、`git push --mirror`，或把私有 repo 的 `.git` 複製到本 repo。
- 正式功能先在私有版完成，再手動同步去識別化後的程式碼到本 repo。
- 本 repo 的 `AGENTS.md` 是公開文件，不可寫入私有 IP、SSH 路徑、真實客戶名或任何金鑰。

## 2. 絕對禁止

不可加入或追蹤：

- `.env`、`cookies.txt`
- `backup_*.sql`、`migration_backup_*`
- `nginx/`、`deploy_gcp.sh`、`setup-nginx-ssl.sh`
- `docs/HANDOVER-*`、`docs/*.pptx`
- `app/src/main/resources/init.sql`（正式版專用）
- 真實客戶名、統編、電話、地址、聯絡人、員工資料
- 真實 API Key、資料庫密碼、雲端憑證、SSH private key
- 任何 production DB dump

若不確定某檔案能不能公開，先不要加；問維護者。

## 3. Demo 資料與資料庫

- `V1__schema.sql`：只建 schema 與第一位 admin，不含真實 seed。
- `V4__demo_seed.sql`：虛構客戶、產品、訂單、生產、出貨、應收、庫存。
- `V2__demo_access_tokens.sql`、`V3__ai_ui_settings.sql`：demo 功能資料。
- 已套用的 migration 不可修改；新增變更請建 `V5__xxx.sql`。
- 公開版與正式版資料庫完全分離，Flyway checksum 不通用；不可把本 repo 指向正式 DB。

## 4. Demo 登入與 AI Gateway

- CharPhone 登入：`admin` / `demo1234`
- AI Gateway demo API Key：`demo-api-key-charphone`
- 兩個公開 repo 的 Compose 預設使用 `charphone_demo` network。
- Gateway 服務名稱固定為 `ai-gateway`；CharPhone 以 `http://ai-gateway:8080` 連線。
- 未設定 LLM 金鑰時，AI 問答會失敗，但其他 ERP 功能仍可使用。

## 5. 日常開發與 Push

```powershell
cd C:\project\public\charphone
cd app
mvn test
cd ..
git status
git diff
powershell -ExecutionPolicy Bypass -File scripts/check-public-safety.ps1
git add -A
git commit -m "feat: 說明這次改了什麼"
git push origin main
```

Docker 驗證：

```powershell
docker compose config
docker compose up -d --build
```

若 Docker build 因 DNS 無法解析 Maven Central，先確認 Docker Desktop 網路；不要因此改壞 Dockerfile。Maven 測試是主要建置驗證。

## 6. 從私有版同步 SOP

1. 在 `C:\project\charphone` 完成正式版修改與測試。
2. 只把程式碼與必要設定複製到 `C:\project\public\charphone`。
3. 對照第 2 節禁止清單，刪除不該公開的內容。
4. 在公開版重新跑 `mvn test` 與安全檢查腳本。
5. `git diff --cached` 人工複查，確認沒有真實 IP、公司名、統編、金鑰。
6. 分開 commit/push；不要合併 private history。

## 7. 驗證清單

- [ ] `cd app; mvn test` 通過
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/check-public-safety.ps1` 通過
- [ ] `docker compose config` 通過
- [ ] `git status` 沒有未預期檔案
- [ ] `git diff --cached` 沒有敏感資料
- [ ] 截圖只使用虛構資料，且未拍到網址列、書籤、通知

## 8. 常見陷阱

- `.env` 必須是 LF；Windows CRLF 會讓值尾帶 `\r`。
- 公開版不要使用正式版 `.env` 或正式 DB。
- `V1__schema.sql` 與正式版 `V1__init.sql` 不同，不可互換。
- 公開 repo 的 commit 會永久留在 GitHub；發現敏感資料要立即輪換金鑰並清理，不是只刪檔。
- Docker Desktop 的 DNS/exec 可能不穩；先用本機 Maven 測試，再處理 Docker。
