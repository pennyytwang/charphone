package util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TokenUtilTest {

    @Test
    void generatedTokenHasPrefixAndEnoughEntropy() {
        String token = TokenUtil.generate();
        assertTrue(token.startsWith("cp_"));
        assertTrue(token.length() >= 40);
        assertTrue(TokenUtil.looksValid(token));
    }

    @Test
    void generatedTokensAreUnique() {
        assertNotEquals(TokenUtil.generate(), TokenUtil.generate());
    }

    @Test
    void hashIsDeterministicAndNotPlaintext() {
        String token = TokenUtil.generate();
        assertEquals(TokenUtil.hash(token), TokenUtil.hash(token));
        assertFalse(TokenUtil.hash(token).contains(token));
        assertEquals(64, TokenUtil.hash(token).length());
    }

    @Test
    void hintKeepsPrefixAndEnds() {
        String token = TokenUtil.generate();
        String hint = TokenUtil.hint(token);
        assertTrue(hint.startsWith("cp_"));
        assertTrue(hint.contains("…"));
        assertTrue(token.endsWith(hint.substring(hint.length() - 4)));
    }

    @Test
    void rejectsMalformedTokens() {
        assertFalse(TokenUtil.looksValid(null));
        assertFalse(TokenUtil.looksValid(""));
        assertFalse(TokenUtil.looksValid("abc"));
        assertFalse(TokenUtil.looksValid("cp_short"));
    }

    @Test
    void constantTimeComparisonWorks() {
        assertTrue(TokenUtil.constantTimeEquals("abc", "abc"));
        assertFalse(TokenUtil.constantTimeEquals("abc", "abd"));
        assertFalse(TokenUtil.constantTimeEquals(null, "abc"));
    }
}
