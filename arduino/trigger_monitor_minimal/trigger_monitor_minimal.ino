/*
 * Minimal Trigger Monitor (Public Skeleton)
 *
 * Commands over serial:
 * - R: return success_count
 * - RESET: reset all counters
 */

const int TRIGGER_PIN_D2 = 2;
const int TRIGGER_PIN_D3 = 3;
const unsigned long SYNC_TIMEOUT_US = 1000;

volatile unsigned long d2_time = 0;
volatile bool d3_seen = false;
volatile bool pending_event = false;
volatile unsigned int success_count = 0;
volatile unsigned int failure_count = 0;

void isr_d2() {
  d2_time = micros();
  d3_seen = false;
  pending_event = true;
}

void isr_d3() {
  if (d2_time > 0) {
    d3_seen = true;
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(TRIGGER_PIN_D2, INPUT);
  pinMode(TRIGGER_PIN_D3, INPUT);
  attachInterrupt(digitalPinToInterrupt(TRIGGER_PIN_D2), isr_d2, RISING);
  attachInterrupt(digitalPinToInterrupt(TRIGGER_PIN_D3), isr_d3, RISING);
}

void loop() {
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    if (cmd == "R") {
      noInterrupts();
      unsigned int value = success_count;
      interrupts();
      Serial.println(value);
      return;
    }

    if (cmd == "RESET") {
      noInterrupts();
      success_count = 0;
      failure_count = 0;
      d2_time = 0;
      d3_seen = false;
      pending_event = false;
      interrupts();
      Serial.println("RESET_OK");
    }
  }

  if (pending_event) {
    pending_event = false;
    bool event_success = false;
    unsigned long t0 = micros();

    while (micros() - t0 < SYNC_TIMEOUT_US) {
      if (d3_seen) {
        success_count++;
        event_success = true;
        break;
      }
    }

    if (!event_success) {
      failure_count++;
    }

    d2_time = 0;
  }
}
