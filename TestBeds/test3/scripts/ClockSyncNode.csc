// simulation variables
set lowestSensorId 1
set numberOfNodes 35
set numberSlots 5
 
// sensor data
set syncVersion 1
atget id sinkId

loop 
	time T 
	set limitTimeSlot T+numberOfNodes*20
	set slotChosenFloat 1+(syncVersion%numberSlots)
	int slotChosen slotChosenFloat
	// the data sent are: 
	// - syncVersion -> that keeps count the "version" of the pack such that the nodes knows if they are phased into an old scenario.
	// - slotChosen -> the slot that tells what nodes can transmits.
	// - numberSlots -> is a knowledge variabel for letting the nodes the ability to compute their time slot (it could also be hardcoded, but in this way we can also offer the ability to dinmacally change the value ClockSync Node-side).
	// - limitTimeSlot -> is the time until they can transmits the data.
	// - sinkId -> is the id of the sink used by the nodes in order to avoid sending the message and know the ClockSync Node who communicate the informations.
	// - lowestSensorId -> it is a variable used for testing criteria and include the sensor whit the smallest id (watch how the nodes decide the destination).
	// - numberOfNodes -> it indicates the number of nodes available on the net (watch how the nodes decide the destination).
	// moreover the three "@@@" are used in order to identifiy the hop-nodes that resent this message, this let the node filter the pack distribution (avoid unnecessary re-flooding).
	data timeSlotPack "SYN" syncVersion slotChosen numberSlots limitTimeSlot sinkId lowestSensorId numberOfNodes "@@@" "@@@" "@@@"
	send timeSlotPack *
	inc syncVersion
	set delayTime numberOfNodes*100
delay delayTime
