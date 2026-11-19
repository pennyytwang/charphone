package util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class MaskingUtilTest {

    @Test
    void masksTaxId() {
        assertEquals("000*****", MaskingUtil.maskTaxId("00000002"));
        assertEquals("***", MaskingUtil.maskTaxId("12"));
        assertNull(MaskingUtil.maskTaxId(null));
    }

    @Test
    void masksPhoneKeepingAreaCode() {
        assertEquals("04-******", MaskingUtil.maskPhone("04-0000-0002"));
        assertEquals("0912****", MaskingUtil.maskPhone("0912345678"));
    }

    @Test
    void masksPersonName() {
        assertEquals("王**", MaskingUtil.maskPersonName("王大明"));
    }

    @Test
    void masksAddress() {
        assertEquals("彰化縣***", MaskingUtil.maskAddress("彰化縣鹿港鎮中正路1號"));
    }
}
