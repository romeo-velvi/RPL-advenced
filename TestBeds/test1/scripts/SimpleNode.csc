
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
			if(numberSlots!=SYNnumberSlots)
				set numberSlots SYNnumberSlots
				randb myTimeSlotTemp 1 numberSlots
				int mySlot myTimeSlotTemp
			end
			if(mySlot==slotAssigned)
				set chosenToSend 1
				cprint "[STATUS]: UNLOCKED -> " mySlot " - " slotAssigned
			else
				set chosenToSend 0
				cprint "[STATUS]: LOCKED -> " mySlot " - " slotAssigned
			end
			data packToSend SYNkindPackReceived SYNpackVersion SYNslotAssigned SYNnumberSlots SYNlimitTimeSlot SYNsinkId SYNlowestSensorId SYNnumberOfNodes SYNhopSensor2 SYNhopSensor3 mySensorId
			send packToSend *
			set messageForwarded messageForwarded+neighborsNumber
			set messageForwardedPerLoop messageForwardedPerLoop+neighborsNumber
		else 
			cprint "[DISCARD]: Old directive discarded"
			inc messagePurged
			buffer bufferSize
			if(bufferSize>0)
				receive nextPackInBuffer
				rdata nextPackInBuffer kindNextPackReceived
				if (kindNextPackReceived=="SYN")
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
				else
					set pack nextPackInBuffer
				end
			end
		end
	end
	
	
	//////////////////////////////////////////////////// CONDITION 1
	if(PACKkindMessage=="MSG")
		rdata pack MSGkindMessage MSGtimeMessage MSGttl MSGsenderId MSGreceiverId MSGdataMessage MSGhopSensor1 MSGhopSensor2 MSGhopSensor3	
		if(MSGreceiverId!=mySensorId)
			if(MSGtimeMessage>=MSGttl)
				cprint "[DISCARD]: message expired"
				inc messagePurged
			else
				data packToSend MSGkindMessage MSGtimeMessage MSGttl MSGsenderId MSGreceiverId MSGdataMessage MSGhopSensor2 MSGhopSensor3 mySensorId
				send packToSend *
				set messageForwarded messageForwarded+neighborsNumber
				set messageForwardedPerLoop messageForwardedPerLoop+neighborsNumber
			end
		else
			cprint "[RECEIVE]: the message has been received"
			set messageToBeAcked pack
			set sendDataType "ACK"
			mark 1
		end
	end
	
	
	//////////////////////////////////////////////////// CONDITION 2
	if(PACKkindMessage=="ACK")
		rdata pack ACKkindMessage ACKtimeMessage ACKttl ACKsenderId ACKreceiverId ACKdataMessage ACKhopSensor1 ACKhopSensor2 ACKhopSensor3	
		if(ACKreceiverId!=mySensorId)
			if(ACKtimeMessage>=ACKttl)
				cprint "[DISCARD]: ack message is expired"
				inc messagePurged
			else			
				data packToSend ACKkindMessage ACKtimeMessage ACKttl ACKsenderId ACKreceiverId ACKdataMessage ACKhopSensor2 ACKhopSensor3 mySensorId
				send packToSend *
				set messageForwarded messageForwarded+neighborsNumber
				set messageForwardedPerLoop messageForwardedPerLoop+neighborsNumber
			end
		else
			cprint "[RECEIVE]: the ack has been received"
		end
	end 
	

	
	//////////// SENDING PERSONAL MESSAGE 1
	if((chosenToSend==1) && (sendDataType=="MSG"))

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
			rgauss MSGdata
			set MSGhopSensor1 "@@@"
			set MSGhopSensor2 "@@@"
			set MSGhopSensor3 mySensorId
			data myMsg "MSG" T limitTimeSlot mySensorId MSGreceiverId MSGdata MSGhopSensor1 MSGhopSensor2 MSGhopSensor3 
			cprint "[CREATE]: a new message has been create for" MSGreceiverId 
			send myMsg *
			set messageForwarded messageForwarded+neighborsNumber
			set messageForwardedPerLoop messageForwardedPerLoop+neighborsNumber
	end


	//////////// SENDING PERSONAL MESSAGE 2
	if((chosenToSend==1) && (sendDataType=="ACK") && (messageToBeAcked!="X"))
		// ###### OneTimeACK
		// if the slot chosen from the ClockSync Node directive is the same of this sensor's slot and the type of data that needs to be sent is the message
		
		// scrape the message to be sent.
		rdata messageToBeAcked TBAkindMessage TBAtimeMessage TBAttl TBAsenderId TBAreceiverId TBAdataMessage TBAhopSensor1 TBAhopSensor2 TBAhopSensor3
		data myAck "ACK" T limitTimeSlot mySensorId TBAsenderId TBAdataMessage TBAhopSensor3 TBAhopSensor2 TBAhopSensor1
		
		send myMsg *
		set messageForwarded messageForwarded+neighborsNumber
		set messageForwardedPerLoop messageForwardedPerLoop+neighborsNumber
		
		set sendDataType "NIL"
		set messageToBeAcked "X"
	end

	
		cprint "I'm: " mySensorId " and I sent: " messageForwarded ". I purged:" messagePurged

	
delay 1500

