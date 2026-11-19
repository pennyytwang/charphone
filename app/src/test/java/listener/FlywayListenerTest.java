package listener;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

class FlywayListenerTest {

    @Test
    void shouldRecognizeChecksumMismatchMessage() {
        FlywayListener listener = new FlywayListener();
        assertTrue(listener.isChecksumMismatch(new RuntimeException("Checksum mismatch for migration 11")));
    }
}
