# FPGA-Based Car Anti-Theft System

An FPGA-based vehicle anti-theft system implemented in **VHDL**, designed using a **finite state machine (FSM)** to provide secure, real-time access control through PIN-based authentication.

This project was developed as part of an **FPGA / Digital Design course** and demonstrates how hardware-level security can be implemented using parallel logic on an FPGA platform.

---

## 🔐 System Description

The system controls vehicle access using a **4-digit PIN** entered via digital inputs.  
Based on user input and system state, the FSM transitions through the following modes:

- **IDLE (Locked)**
- **DIGIT_ENTRY**
- **VERIFY**
- **UNLOCKED**
- **ALARM**
- **UNLOCK_DELAY**

After **three consecutive incorrect PIN attempts**, the system:
- Activates an **alarm**
- Enables a **lockout timeout**
- Disables further input until reset

System status is communicated using **LED indicators, a buzzer, and a 7-segment display**.

---

## 🧠 Key Features

- Finite State Machine (FSM)–based control logic
- Hardware-level PIN authentication
- Alarm and timeout protection against brute-force attempts
- Separate **design** and **testbench** VHDL implementations
- Deterministic, real-time behavior using FPGA parallelism

---

## 🛠 Tools & Technologies

- **HDL:** VHDL  
- **Simulation:** EDA Playground  
- **FPGA Software:** Intel Quartus II  
- **Hardware Platform:** Altera DE2 FPGA Board  

---

## 📁 Repository Structure

FPGA_Project/
├── VHDL/
│ ├── top_module.vhd # Main FSM and system logic
│ └── testbench.vhd # VHDL testbench for simulation
├── Pictures/ # System states and hardware output images
└── FPGA_Based_Anti_Theft_System_for_Vehicles.pdf



---

## 🧪 Verification & Testing

The system was verified using a dedicated VHDL testbench that simulates:
- Correct PIN entry
- Incorrect PIN attempts
- Alarm activation after three failures
- Timeout behavior and system reset

Simulation was performed using **EDA Playground**, followed by successful deployment and testing on physical FPGA hardware.

---

## 🚗 Why FPGA?

Compared to microcontroller-based solutions, FPGA implementation provides:
- Parallel execution
- Faster response to security events
- Deterministic timing
- Higher resistance to software-level attacks

This makes FPGA-based systems well-suited for **real-time security applications**.

---


## 📌 Notes

This repository is intended for **academic documentation and portfolio demonstration** purposes.
