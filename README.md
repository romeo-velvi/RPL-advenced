# Advanced IoT Network Custom Protocol Project

## Project Overview
This project focuses on implementing an advanced IoT network custom protocol using the RPL (Routing Protocol for Lossy networks) with a time-window expiration parameter. The primary goals are to handle power consumption and reduce network congestion.

## Project Goals
- Implement the RPL protocol with a time-window expiration parameter.
- Introduce performance and optimization strategies to enhance efficiency.

## Entities at Stake
- **ClockSync Node**: Responsible for marking time-window parameters and deciding which sensors can transmit data. Assumed to have no power limitations.
- **Sensor Node**: Classic sensors that read and transmit data, phased with ClockSync decisions to reduce congestion.

## Messages Protocol
The protocol defines three types of messages:
1. **Sync Message**: Sent by ClockSync Nodes.
2. **Sensor Message**: Sent by Sensor Nodes.
3. **Ack Message**: Sent by Sensor Nodes to acknowledge receipt of messages.

### Message Structure
- **Sync Message**: Includes fields like PackVersion, ChoosenSlot, NumberOfSlots, LimitTime, ClockSyncID, and Hops.
- **Sensor Message**: Includes fields like SendingTime, TimeToLive, SenderID, ReceiverID, Data, and Hops.
- **Ack Message**: Includes fields like SendingTime, TimeToLive, SenderID, ReceiverID, Data, Hops, and ReversedHops.

## Optimization Strategies
Several strategies are implemented to improve the protocol's efficiency:
- **Slot-Based Exclusion Mechanism**
- **HPD (Hops in Pack Data) Method**
- **OTA (One-Time-Ack) Application**
- **Clever Transmissions Mechanism**
- **Buffered Message for Loop Avoidance**
- **Time Relaxation on Receiver**
- **Try-and-Repeat Method**

## Pseudo-Code Idea
The project includes pseudo-code for both Sensor Nodes and ClockSync Nodes to illustrate the logic behind their operations.

## CupCarbon Simulation
Simulations are conducted using CupCarbon to test the protocol in various network topologies:
1. **Snowflake Topology**
2. **Square Topology**
3. **Fisheye Topology**

### Simulation Parameters
- Number of Nodes: 35
- Number of Slots: 2-5
- Buffer Size: 10-20
- Max Loop: 2-3
- Max Retry: 3
- Sync Refresh: 35*100ms to 35*150ms
- Time: 5-27 minutes

## Energy Considerations
Energy consumption is analyzed using specific battery drain criteria:
- Transmission: 0.6
- Reception: 0.1

Simulations show the duration of sensor operation under different scenarios, highlighting the efficiency of the RPL optimized protocol compared to RPL flooding.

## Improvements and Criticalities
### Improvements
- Nodes can decide whether to transmit messages based on remaining energy and buffer saturation.
- Dying sensors can send messages to ClockSync Nodes to influence slot and time-window mechanisms.
- Use HPD for internal routing table population to enhance the clever sending mechanism.

### Criticalities
- The RPL protocol performs better in topologies with stable connections.
- If ClockSync nodes die, only sensors with the last chosen slot can send messages.

## Conclusion
This project demonstrates the implementation and optimization of the RPL protocol for IoT networks, addressing power consumption and congestion issues through various strategies and simulations.

## License
This project is licensed under the MIT License. See the `LICENSE` file for more details.

## Contributions
Contributions are welcome! Please open an issue or submit a pull request for any improvements or new features.
