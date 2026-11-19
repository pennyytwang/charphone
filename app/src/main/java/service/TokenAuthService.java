package service;

import dao.AccessTokenDao;
import dao.UserDao;
import model.AccessToken;
import model.User;
import util.TokenUtil;

/**
 * Token 登入的商業邏輯：格式檢查、資料庫驗證、原子消耗。
 * 不負責 HTTP session 或畫面導向。
 */
public class TokenAuthService {

    public static final String REASON_INVALID_FORMAT = "invalid_format";
    public static final String REASON_NOT_FOUND = "not_found";
    public static final String REASON_REVOKED = "revoked";
    public static final String REASON_EXPIRED = "expired";
    public static final String REASON_EXHAUSTED = "exhausted";
    public static final String REASON_USER_NOT_FOUND = "user_not_found";
    public static final String REASON_USER_INACTIVE = "user_inactive";
    public static final String REASON_USER_EXPIRED = "user_expired";
    public static final String REASON_CONSUME_FAILED = "consume_failed";

    private final AccessTokenDao tokenDao = new AccessTokenDao();
    private final UserDao userDao = new UserDao();

    /**
     * 驗證 token 並消耗一次使用次數。
     */
    public Result authenticate(String rawToken, String ip) {
        String trimmed = rawToken == null ? null : rawToken.trim();
        if (!TokenUtil.looksValid(trimmed)) {
            return Result.failure(REASON_INVALID_FORMAT, null, null);
        }

        AccessToken token = tokenDao.findByHash(TokenUtil.hash(trimmed));
        if (token == null) {
            return Result.failure(REASON_NOT_FOUND, null, TokenUtil.hint(trimmed));
        }
        String hint = token.getTokenHint();

        long now = System.currentTimeMillis();
        if (token.isRevoked()) {
            return Result.failure(REASON_REVOKED, token, hint);
        }
        if (token.isExpired(now)) {
            return Result.failure(REASON_EXPIRED, token, hint);
        }
        if (token.isExhausted()) {
            return Result.failure(REASON_EXHAUSTED, token, hint);
        }

        User user = userDao.getUserById(token.getUserId());
        if (user == null) {
            return Result.failure(REASON_USER_NOT_FOUND, token, hint);
        }
        if (!user.isActive()) {
            return Result.failure(REASON_USER_INACTIVE, token, hint);
        }
        if (user.getExpiresAt() != null && user.getExpiresAt().getTime() <= now) {
            return Result.failure(REASON_USER_EXPIRED, token, hint);
        }

        if (!tokenDao.consume(token.getId(), ip)) {
            return Result.failure(REASON_CONSUME_FAILED, token, hint);
        }
        return Result.success(user, token);
    }

    public static final class Result {
        private final boolean success;
        private final String reason;
        private final User user;
        private final AccessToken token;
        private final String tokenHint;

        private Result(boolean success, String reason, User user, AccessToken token, String tokenHint) {
            this.success = success;
            this.reason = reason;
            this.user = user;
            this.token = token;
            this.tokenHint = tokenHint;
        }

        static Result success(User user, AccessToken token) {
            return new Result(true, null, user, token, token.getTokenHint());
        }

        static Result failure(String reason, AccessToken token, String tokenHint) {
            return new Result(false, reason, null, token, tokenHint);
        }

        public boolean isSuccess() { return success; }
        public String getReason() { return reason; }
        public User getUser() { return user; }
        public AccessToken getToken() { return token; }
        public String getTokenHint() { return tokenHint; }
    }
}
