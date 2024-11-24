///////////////////////////////////// HW simulation variables

// maxNumberCronology stored the maximim number of message that the node can store into its buffer.
set maxNumberCronology 10
// maxNumberLoop stores the number of time a buffered message can be sent.
set maxNumberLoop 2
// maxRetry stores the number of maximim time we can retry to re-send a message without ACK.
set maxRetry 3
// packCronology is the buffer which stores log about the data that has been sent multiple times. 
// if the data was spread many times it wants to intend that the receiver may not be reachable.
// this is done in order to reduce the number of "orphan" package in the network.
vec packCronology maxNumberCronology
// initialize all the entries of the buffer at "empty" i.e. "X".
for iter 0 maxNumberCronology
	int i iter
	vset "X" packCronology i
	delay 50
end


//////////////////////////////////// Node variable
// mySensorId stores the id of this node.
atget id mySensorId
// messagePurged, messageForwarded, messageReceived is the number of time a message has been rispectively: purged, forwarded and received
set messagePurged 0
set messageForwarded 0
set messageForwardedPerLoop 0
set messageReceived 0
// sendDataType is used in order to decide what kind of data must be sent. It can assume 3 values:
// - "MSG"
// - "ACK"
// - "NIL"
// of course, the first kind of data that a node whats to send is a "MSG"
set sendDataType "MSG"
// tryCounter tells how many times a message "MSG" has been re-sent from this sensor to another sensor 
set tryCounter 0
// messageToBeAcked will store temporarily the "MSG" received that needs to be acked from this sensor (this sensor will be the Hop for the next one)-
set messageToBeAcked "X"

//////////////////////////////////// Directive variables -> updated when the ClockSync Node send the directive.
// numberOfNodes stores information about how many nodes are available on the net.
set numberOfNodes -1
// lowestSensorId stores the sensor id which value is the lowest (used as simulation test in order to get the destination node).
set lowestSensorId -1
// directiveVersion is the "SYN" version this sensor is phased
set directiveVersion -1
// limitTimeSlot is the time-limit where this sensor must send the data. 
set limitTimeSlot -1
// slotAssigned stores what kind of slot this node has in order to check if it can send or receive. 
set slotAssigned -1
// chosenToSend is the variable that can assume 2 possible values: 
// - 0 if the slot decided by the ClockSync Node is not the one assigned to this sensor. We can only receive.
// - 1 if the slot decided by the ClockSync Node is the one assigned to this sensor. We are able to send data.
set chosenToSend -1
// mySlot stores this sensor slot
set mySlot -1
// numberSlots stores the number of slot division
set numberSlots -1




///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// SENSOR BEHAVIOUR /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////


loop
	// get the (simulation time)
	time T
	// get the number of the next neighbors.
	atnd neighborsNumber neighborsSet	
	
	// set to zero the message forwarded per loop
	set messageForwardedPerLoop 0
		
	// pack stores information about the any kind of data received ("MSG", "ACK", "SYN").
	receive pack
	// Since every "MSG", "ACK" or "SYN" stores, at first place the kind of message sent.
	// This imples that the first argument of "pack" variable will be "MSG", "ACK" or "SYN".
	rdata pack PACKkindMessage
	
	
	if(PACKkindMessage=="SYN")
	
		rdata pack SYNkindPackReceived SYNpackVersion SYNslotAssigned SYNnumberSlots SYNlimitTimeSlot SYNsinkId SYNlowestSensorId SYNnumberOfNodes SYNhopSensor1 SYNhopSensor2 SYNhopSensor3
		
		// when a new SYN directive is sent
		if(directiveVersion<SYNpackVersion)
			// save the new parameters
			set sinkId SYNsinkId
			set lowestSensorId SYNlowestSensorId
			set numberOfNodes SYNnumberOfNodes
			set slotAssigned SYNslotAssigned
			set limitTimeSlot SYNlimitTimeSlot
			set directiveVersion SYNpackVersion
			// ###### SlotBasedExecutionMechanism
			// check if the slots are changed, in this case, we must update out slot reference.
			if(numberSlots!=SYNnumberSlots)
				set numberSlots SYNnumberSlots
				randb myTimeSlotTemp 1 numberSlots
				int mySlot myTimeSlotTemp
			end
			// check if the sensor's slot is the one chosen from the ClockSync Node
			if(mySlot==slotAssigned)
				set chosenToSend 1
				cprint "[STATUS]: UNLOCKED -> " mySlot " - " slotAssigned
			else
				set chosenToSend 0
				cprint "[STATUS]: LOCKED -> " mySlot " - " slotAssigned
			end
			
			// ###### HopChronologyPockedData
			// reorganize the "pack" in order to insert this sensor as Hop. 
			data packToSend SYNkindPackReceived SYNpackVersion SYNslotAssigned SYNnumberSlots SYNlimitTimeSlot SYNsinkId SYNlowestSensorId SYNnumberOfNodes SYNhopSensor2 SYNhopSensor3 mySensorId

			// ###### CleverSendingMechanism
			for iter 0 neighborsNumber
				int i iter
				vget neighborId neighborsSet i
				// this condition avoid resending the message to the nodes who gave me the data.
				if ((neighborId!=sinkId) && (neighborId!=SYNhopSensor1) && (neighborId!=SYNhopSensor2) && (neighborId!=SYNhopSensor3)) 
					send packToSend neighborId
					inc messageForwarded
					inc messageForwardedPerLoop
				end
				delay 50
			end
		else 
			// when an old SYN directive is sent
			cprint "[DISCARD]: Old directive discarded"
			inc messagePurged
			// Check if there are some other message into the buffer that can be read
			// This operation is done in order to optimize the data acquirence.
			buffer bufferSize
			if(bufferSize>0)
				receive nextPackInBuffer
				rdata nextPackInBuffer kindNextPackReceived
				// if the data into the buffer is another SYN directive
				if (kindNextPackReceived=="SYN")
					// read the pack and execute the process done before
					rdata pack SYNkindPackReceived SYNpackVersion SYNslotAssigned SYNnumberSlots SYNlimitTimeSlot SYNsinkId SYNlowestSensorId SYNnumberOfNodes SYNhopSensor1 SYNhopSensor2 SYNhopSensor3
					if(directiveVersion<SYNpackVersion)
						randb mySlot 1 SYNnumberSlots
						set sinkId SYNsinkId
						set lowestSensorId SYNlowestSensorId
						set numberOfNodes SYNnumberOfNodes
						set slotAssigned SYNslotAssigned
						set limitTimeSlot SYNlimitTimeSlot
						set directiveVersion SYNpackVersion
						if(mySlot==SYSslotAssigned)
							set chosenToSend 1
							cprint "[STATUS]: UNLOCKED1 -> " mySlot " - " slotAssigned
						else
							set chosenToSend 0
							cprint "[STATUS]: LOCKED1 -> " mySlot " - " slotAssigned
						end
					end
					// since it is a very particular case analyzed where more SYN are spread, the last SYN got will be no not shared to others.
				else
					// update the "pack" variable in order to be further processed in the next controls that handle the data different from "SYN"
					set pack nextPackInBuffer
				end
			end
		end
	end
	
	// this secton is resereved to the pack check in order to tell if it is a message which has been spread too many times or it is in a loop 
	if((PACKkindMessage=="MSG")||(PACKkindMessage=="ACK"))
		rdata pack PACKkindMessage PACKtimeMessage PACKsenderId PACKreceiverId PACKdataMessage PACKhopSensor1 PACKhopSensor2 PACKhopSensor3
		// if the sensor is not the receiver.
		if (PACKreceiverId != mySensorId)
			// ###### Buffer Loop checker
			if (PACKsenderId==mySensorId)
				set PACKkindMessage "NIL"
				cprint "[DISCARD]: message reached a looped"
				inc messagePurged
			end
			// ####### BufferReapetedMessages
			set isPackNew 1
			for iter 0 maxNumberCronology
				int i iter
				vget oldPack packCronology i
				if(oldPack!="X")
					rdata oldPack sender receiver datamessage counter
					if((PACKsenderId==sender) && (PACKreceiverId==receiver) && (PACKdataMessage==datamessage))
						set newCounter counter+1
						set isPackNew -1
						if(newCounter>=maxNumberLoop)
							// if we check that the message was spread multiple times, it will be not transmitted anymore.
							set PACKkindMessage "NIL"
							cprint "[DISCARD]: message spread too many times"
							inc messagePurged
						else 
							// update the bufferent element with the new counter.
							data newOldPack sender receiver datamessage newCounter
							vset newOldPack packCronology i
						end
					end
				end
			end
			
			if(isPackNew>0)
				// add the unseen "pack" into the buffer (classical 1-shifting-method).
				data newPack PACKsenderId PACKreceiverId PACKdataMessage 0
				for iter 1 maxNumberCronology
					set j1 maxNumberCronology-i
					set j2 j1-1
					int i1 j1
					int i2 j2
					vget temp packCronology i2
					vset temp packCronology i1
				end
				vset newPack packCronology 0
			end
		end
	end
	
	//////////////////////////////////////////////////// CONDITION 1
	if(PACKkindMessage=="MSG")
		rdata pack MSGkindMessage MSGtimeMessage MSGttl MSGsenderId MSGreceiverId MSGdataMessage MSGhopSensor1 MSGhopSensor2 MSGhopSensor3	
		if(MSGreceiverId!=mySensorId)
			// if i'm not the receiver, i.e. i'm a hop node that bring the package to the destination.
			if(MSGtimeMessage>=MSGttl)
				// if the message is expired
				cprint "[DISCARD]: message expired"
				inc messagePurged
			else
				// ###### HopChronologyPockedData
				// reorganize the "pack" in order to insert this sensor as Hop. 
				// if the message is not expired we read the message, we must updated the pack with the new hop-stack
				data packToSend MSGkindMessage MSGtimeMessage MSGttl MSGsenderId MSGreceiverId MSGdataMessage MSGhopSensor2 MSGhopSensor3 mySensorId
				// ###### CleverSendingMechanism
				set isNeighborTheReceiver -1
				for iter 0 neighborsNumber
					int i iter
					vget neighborId neighborsSet i
					if(MSGreceiverId==neighborId)
						set isNeighborTheReceiver 1 
						send packToSend neighborId
						inc messageForwarded
						inc messageForwardedPerLoop
					end
					delay 50
				end
				if (isNeighborTheReceiver<0)
					for iter 0 neighborsNumber
						int i iter
						vget neighborId neighborsSet i
						// this condition avoid resending the message to other nodes
						if((neighborId!=sinkId) && (neighborId!=MSGsenderId) && (neighborId!=MSGhopSensor1) && (neighborId!=MSGhopSensor2) && (neighborId!=MSGhopSensor3))
							send packToSend neighborId
							inc messageForwarded
							inc messageForwardedPerLoop							
						end
						delay 50
					end				
				end
			end
		else
			// ####### OneTimeACK
			// if i'm destination node
			// here is relaxed the expired time
			cprint "[RECEIVE]: the message has been received"
			// set the message that needs to be acknowledged
			set messageToBeAcked pack
			// set the intention to send the ack 
			set sendDataType "ACK"
			// highlight the node (in order to tell that the communication has been succesfully)
			mark 1
		end
	end
	
	
	//////////////////////////////////////////////////// CONDITION 2
	if(PACKkindMessage=="ACK")
		rdata pack ACKkindMessage ACKtimeMessage ACKttl ACKsenderId ACKreceiverId ACKdataMessage ACKhopSensor1 ACKhopSensor2 ACKhopSensor3	
		if(ACKreceiverId!=mySensorId)
			//i'm trasversal node
			if(ACKtimeMessage>=ACKttl)
				cprint "[DISCARD]: ack message is expired"
				inc messagePurged
			else			
				if((ACKhopSensor1!=mySensorId) && (ACKhopSensor2!=mySensorId))
					// ###### HopChronologyPockedData
					// reorganize the "pack" in order to insert this sensor as Hop. 
					// if the ack needs to be sent but this sensor never reads it, the new pack needs to be updated with the new hop-stack
					data packToSend ACKkindMessage ACKtimeMessage ACKttl ACKsenderId ACKreceiverId ACKdataMessage ACKhopSensor2 ACKhopSensor3 mySensorId
					// ###### CleverSendingMechanism
					set isNeighborTheReceiver -1
					for iter 0 neighborsNumber
						int i iter
						vget neighborId neighborsSet i
						if(MSGreceiverId==neighborId)
							set isNeighborTheReceiver 1 
							send packToSend neighborId
							inc messageForwarded
							inc messageForwardedPerLoop
						end
						delay 50
					end
					if (isNeighborTheReceiver<0)
						for iter 0 neighborsNumber
							int i iter
							vget neighborId neighborsSet i
							// this condition avoid resending the message to other nodes
							if((neighborId!=sinkId) && (neighborId!=ACKsenderId) && (neighborId!=ACKhopSensor1) && (neighborId!=ACKhopSensor2) && (neighborId!=ACKhopSensor3))
								send packToSend neighborId
								inc messageForwarded
								inc messageForwardedPerLoop
							end
							delay 50
						end				
					end
				else
					if((ACKhopSensor1==mySensorId) && (ACKhopSensor2!="@@@"))
						send pack ACKhopSensor2
						inc messageForwarded
						inc messageForwardedPerLoop
					end
					if((ACKhopSensor2==mySensorId) && (ACKhopSensor3!="@@@"))
						send pack ACKhopSensor3
						inc messageForwarded
						inc messageForwardedPerLoop
					end
					if(ACKhopSensor3==mySensorId)
						// ###### CleverSendingMechanism
						set isNeighborTheReceiver -1
						for iter 0 neighborsNumber
							int i iter
							vget neighborId neighborsSet i
							if(ACKreceiverId==neighborId)
								set isNeighborTheReceiver 1 
								send packToSend neighborId
								inc messageForwarded
								inc messageForwardedPerLoop
							end
							delay 50
						end
						if (isNeighborTheReceiver<0)
							for iter 0 neighborsNumber
								int i iter
								vget neighborId neighborsSet i
								// this condition avoid resending the message to other nodes
								if((neighborId!=sinkId) && (neighborId!=ACKsenderId) && (neighborId!=ACKhopSensor1) && (neighborId!=ACKhopSensor2) && (neighborId!=ACKhopSensor3))
									send packToSend neighborId
									inc messageForwarded
									inc messageForwardedPerLoop
								end
								delay 50
							end				
						end
					end
				end
			end
		else
			// ##### PackTimeRelaxationTecnique
			// i'm destination node
			// here we relax also the expired time
			cprint "[RECEIVE]: the ack has been received"
			set tryCounter 0
		end
	end 
	

	
	//////////// SENDING PERSONAL MESSAGE 1
	if((chosenToSend==1) && (sendDataType=="MSG"))
	// if the slot chosen from the ClockSync Node directive is the same of this sensor's slot and the type of data that needs to be sent is the message
		
		if(tryCounter==0)
			// if the sensor tries to send the message for the first time
			
			// ##### discern the destination
			set halfGroup numberOfNodes/2
			set groupIdDividerFloat (lowestSensorId+halfGroup)-1
			int groupIdDivider groupIdDividerFloat
			if(mySensorId<groupIdDivider)
				set receiverSensorId mySensorId+halfGroup
			else
				if(mySensorId>groupIdDivider)
					set receiverSensorId mySensorId-halfGroup
				else
					set receiverSensorId mySensorId+1
				end
			end
			int MSGreceiverId receiverSensorId
			cprint "[INFO]: " MSGreceiverId numberOfNodes lowestSensorId
			
			// in order to simulate the sending of information, a new random number is supposed to be the subject of the message
			rgauss MSGdata
			
			// set the trasversal nodes to null (of course, the 3rd is the id of this note that send the message)
			set MSGhopSensor1 "@@@"
			set MSGhopSensor2 "@@@"
			set MSGhopSensor3 mySensorId
			
			// build the package
			data myMsg "MSG" T limitTimeSlot mySensorId MSGreceiverId MSGdata MSGhopSensor1 MSGhopSensor2 MSGhopSensor3 
		
			cprint "[CREATE]: a new message has been create for" MSGreceiverId 
			
			// ###### CleverSendingMechanism for sending a new MSG
			set isNeighborTheReceiver -1
			for iter 0 neighborsNumber
				int i iter
				vget neighborId neighborsSet i
				if(MSGreceiverId==neighborId)
					set isNeighborTheReceiver 1 
					send myMsg neighborId
					inc messageForwarded
					inc messageForwardedPerLoop
				end
				delay 50
			end
			if (isNeighborTheReceiver<0)
				for iter 0 neighborsNumber
					int i iter
					vget neighborId neighborsSet i
					// this condition avoid resending the message to other nodes
					if(neighborId!=sinkId)
						send myMsg neighborId
						inc messageForwarded
						inc messageForwardedPerLoop
					end
					delay 50
				end				
			end
			inc tryCounter
		else 
			// ###### TryRepeatMethod w/t TimeRelaxation
			set newLimitTimeMessage limitTimeSlot+(limitTimeSlot*tryCounter*10)/100
			// if we can send a message, but the we have to retry to re-send the message just in case the message is not arrived
			data myMsg "MSG" T newLimitTimeMessage mySensorId MSGreceiverId MSGdata MSGhopSensor1 MSGhopSensor2 MSGhopSensor3 
			cprint "[RESEND]: my old message needs to be resent for the: " tryCounter "-th time" " -> increased time from " limitTimeSlot " to " newLimitTimeMessage
			
			// ###### CleverSendingMechanism for sending a new MSG
			set isNeighborTheReceiver -1
			for iter 0 neighborsNumber
				int i iter
				vget neighborId neighborsSet i
				if(MSGreceiverId==neighborId)
					set isNeighborTheReceiver 1 
					send myMsg neighborId
					inc messageForwarded
					inc messageForwardedPerLoop
				end
				delay 50
			end
			if (isNeighborTheReceiver<0)
				for iter 0 neighborsNumber
					int i iter
					vget neighborId neighborsSet i
					// this condition avoid resending the message to other nodes
					if(neighborId!=sinkId)
						send myMsg neighborId
						inc messageForwarded
						inc messageForwardedPerLoop
					end
					delay 50
				end
			end
			
			// since the message has been re-sent, we must increase the tryCounter
			// and if it exceeds the limits, we can discard the message and generate the new one. 
			inc tryCounter
			if(tryCounter>=maxRetry)
				set sendDataType "MSG"
				set tryCounter 0
			end
		end
	end


	//////////// SENDING PERSONAL MESSAGE 2
	if((chosenToSend==1) && (sendDataType=="ACK") && (messageToBeAcked!="X"))
		// ###### OneTimeACK
		// if the slot chosen from the ClockSync Node directive is the same of this sensor's slot and the type of data that needs to be sent is the message
		
		// scrape the message to be sent.
		rdata messageToBeAcked TBAkindMessage TBAtimeMessage TBAttl TBAsenderId TBAreceiverId TBAdataMessage TBAhopSensor1 TBAhopSensor2 TBAhopSensor3
		data myAck "ACK" T limitTimeSlot mySensorId TBAsenderId TBAdataMessage TBAhopSensor3 TBAhopSensor2 TBAhopSensor1
		
		cprint "[CREATE]: a new ACK has been created for: " TBAsenderId 
		// ###### CleverSendingMechanism for sending a new MSG
		set isNeighborTheReceiver -1
		for iter 0 neighborsNumber
			int i iter
			vget neighborId neighborsSet i
			if(MSGreceiverId==neighborId)
				set isNeighborTheReceiver 1 
				send myAck neighborId
				inc messageForwarded
				inc messageForwardedPerLoop
			end
			delay 50
		end
		if ((isNeighborTheReceiver<0) && (TBAhopSensor3!="@@@"))
			send myAck TBAhopSensor3
			inc messageForwarded
			inc messageForwardedPerLoop			
		end
		
		// POSE IT = "MSG" TO REPEAT THE CYCLE
		set sendDataType "NIL"
		set messageToBeAcked "X"
		set tryCounter 0
		
	end

	// decrease power
	battery currentPower
	set b currentPower-(currentPower*messageForwardedPerLoop/100)
	battery set b
	if(b<=200)
		battery set 0
		cprint "[STOP] I'm: " mySensorId " and I sent: " messageForwarded ". I purged:" messagePurged
		stop
	end 
	
	cprint "I'm: " mySensorId " and I sent: " messageForwarded ". I purged:" messagePurged
	
	
delay 1500

