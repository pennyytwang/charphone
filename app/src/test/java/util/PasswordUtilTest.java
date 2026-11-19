package util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PasswordUtilTest {

    @Test
    void bcryptRoundTrip() {
        String hash = PasswordUtil.hash("correct horse battery staple");
        assertTrue(hash.startsWith("$2"));
        assertTrue(PasswordUtil.verify("correct horse battery staple", hash));
        assertFalse(PasswordUtil.verify("wrong", hash));
        assertFalse(PasswordUtil.needsRehash(hash));
    }

    @Test
    void verifiesLegacySha256AndRequestsRehash() throws Exception {
        String legacy = legacyHash("legacy-test-password");
        assertTrue(PasswordUtil.verify("legacy-test-password", legacy));
        assertFalse(PasswordUtil.verify("wrong", legacy));
        assertTrue(PasswordUtil.needsRehash(legacy));
    }

    private String legacyHash(String password) throws Exception {
        String salt = "demo_legacy_salt";
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        md.update(salt.getBytes(StandardCharsets.UTF_8));
        byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(salt.getBytes(StandardCharsets.UTF_8))
                + ":" + Base64.getEncoder().encodeToString(hash);
    }
}
