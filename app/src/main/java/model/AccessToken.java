package model;

import java.sql.Timestamp;

public class AccessToken {
    private int id;
    private int userId;
    private String tokenHint;
    private String label;
    private String scopes;
    private Timestamp expiresAt;
    private Integer maxUses;
    private int usedCount;
    private Timestamp lastUsedAt;
    private String lastUsedIp;
    private Timestamp revokedAt;
    private Integer createdBy;
    private Timestamp createdAt;

    public AccessToken() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getTokenHint() { return tokenHint; }
    public void setTokenHint(String tokenHint) { this.tokenHint = tokenHint; }

    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }

    public String getScopes() { return scopes; }
    public void setScopes(String scopes) { this.scopes = scopes; }

    public Timestamp getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Timestamp expiresAt) { this.expiresAt = expiresAt; }

    public Integer getMaxUses() { return maxUses; }
    public void setMaxUses(Integer maxUses) { this.maxUses = maxUses; }

    public int getUsedCount() { return usedCount; }
    public void setUsedCount(int usedCount) { this.usedCount = usedCount; }

    public Timestamp getLastUsedAt() { return lastUsedAt; }
    public void setLastUsedAt(Timestamp lastUsedAt) { this.lastUsedAt = lastUsedAt; }

    public String getLastUsedIp() { return lastUsedIp; }
    public void setLastUsedIp(String lastUsedIp) { this.lastUsedIp = lastUsedIp; }

    public Timestamp getRevokedAt() { return revokedAt; }
    public void setRevokedAt(Timestamp revokedAt) { this.revokedAt = revokedAt; }

    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public boolean isRevoked() { return revokedAt != null; }

    public boolean isExpired(long nowMillis) {
        return expiresAt == null || expiresAt.getTime() <= nowMillis;
    }

    public boolean isExhausted() {
        return maxUses != null && usedCount >= maxUses;
    }
}
