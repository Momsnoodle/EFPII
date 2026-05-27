# FPGA Memory Game - Issues Preventing Upload

## Critical Issues (Must Fix)

### 1. **MISSING FILE: Display_Score.sv**
** BLOCKING - Compilation failsStatus:** 
**Location:** Main.qsf includes "Display_Score.sv" but file doesn't exist
**Error from Main.map.rpt:**
```
Warning (12019): Can't analyze file -- file Display_Score.sv is missing
```
**Fix:** Either create the file or remove from Main.qsf

### 2. **LFSR_Sequence_Generator - Missing Output Signal**
** CRITICAL - Sequence not being generated correctlyStatus:** 
**File:** LFSR_Sequence_Generator.sv, Line 29
**Problem:** 
- `feedback` signal is calculated but never used
- `sequence_o` is NEVER assigned with the LFSR output bits
- Currently `sequence_o` stays at '0' after reset
- The LFSR generates bits but doesn't shift them into the sequence
**Impact:** Random sequence generation is broken - game receives all zeros

### 3. **LED_Sequence_Display - Incorrect Bit Indexing**
**  MAJOR - Sequence display is reversed or wrongStatus:** 
**File:** LED_Sequence_Display.sv, Line 49
**Problem:** 
- Displays `sequence_i[SEQ_LENGTH-1-index_q]` which might work but...
- No validation that bits are actually captured during display
- With broken LFSR above, always displays 0 anyway

### 4. **Missing Pin Assignments**
**  CRITICAL - Cannot program FPGAStatus:** 
**Warnings from Main.map.rpt:**
```
Warning (10034): Output port "LEDR[9..1]" at Main.sv(12) has no driver
Warning (10034): Output port "HEX5[7]" at Main.sv(14) has no driver
```
**Problem:**
- LEDR pins [9:1] are NOT connected to anything - only LEDR[0] is driven
- HEX5[7] has no driver
- No .qsf file pin assignments found for most outputs
**Impact:** Most LEDs and displays won't work on hardware

### 5. **Output Pins Stuck at GND**
**  OPTIMIZATION - All LEDs not lighting upStatus:** 
**Warnings:** Multiple "Pin stuck at GND" for LEDR[1-9]
**Reason:** These pins have no driver (issue #4)

---

## Design Issues

### 6. **Button Capture State Machine Logic Flaw**
**File:** MemoryGameStateMachine.sv, Line 245
**Problem:**
```verilog
state_in.seq_in = player_sequence; // filled EVERY cycle in PLAYING state
```
- `seq_in` is being assigned continuously in PLAYING state
- Should only latch the final sequence when `player_done` is true
- Currently overwrites sequence_capture output every clock cycle
**Impact:** Player sequence might be overwritten incorrectly

### 7. **Debouncer Counter Width Mismatch**
**File:** Main.sv, Line 74 & Debouncer.sv, Line 20
**Problem:**
```verilog
Debouncer #(.COUNT_LEN(DIVIDER_LEN)) // DIVIDER_LEN = 5000000
// But Debouncer has: logic unsigned [23:0] counter;
```
- Counter is 24-bit max (0-16M)
- DIVIDER_LEN is 5M - fits fine, but truncation warnings
**Impact:** Minor but generates synthesis warnings

### 8. **ResetGenerator Truncation Warning**
**File:** ResetGenerator.sv, Line 16-17
**Problem:**
```verilog
logic unsigned [2:0] counter; // 3-bit counter
// Then: counter <= counter + 1;
```
Should use proper width sizing or initialization
**Impact:** Warning during compilation

### 9. **Unused Signal: feedback in LFSR_Sequence_Generator**
**File:** LFSR_Sequence_Generator.sv, Line 29
**Compiler Warning:**
```
Warning (10036): object "feedback" assigned a value but never read
```
**Impact:** Clutters synthesis output, but not critical

### 10. **Missing Multiplier Parameter in LFSR Instantiation**
**File:** MemoryGameStateMachine.sv, Line 84
**Problem:** Module definition has MULTIPLIER parameter but not passed
```verilog
LFSR_Sequence_Generator #(
    .SEQ_LENGTH(SEQ_W),
    .LFSR_WIDTH(16)
    // Missing: .MULTIPLIER(OVER_SAMPLING)
) lfsr_inst (
```
**Impact:** MULTIPLIER defaults to 10, might cause slow sequence generation

---

## Summary Table

| Issue | Severity | Type | Fix Time |
|-------|----------|------|----------|
| Missing Display_Score.sv | CRITICAL | File | 5 min |
| LFSR no sequence output | CRITICAL | Logic | 10 min |
| Pin assignments missing | CRITICAL | Config | 15 min |
| Button sequence latch wrong | HIGH | Logic | 5 min |
| LED indexing unclear | MEDIUM | Logic | 5 min |
| Debouncer width truncation | LOW | Warnings | 5 min |
| Missing MULTIPLIER param | MEDIUM | Config | 2 min |

**Why Can't It Upload?**
1. Missing Display_Score.sv prevents compilation
2. Even if compiled, pin assignments are incomplete
3. LEDs 1-9 won't work (not assigned)
4. Game logic has bugs that would cause failures at runtime
