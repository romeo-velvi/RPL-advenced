
atget id mySensorId
set messagePurged 0
set messageForwarded 0
set messageForwardedPerLoop 0
set messageReceived 0
set sendDataType "MSG"
set messageToBeAcked "X"

set numberOfNodes -1
set lowestSensorId -1
set directiveVersion -1
set limitTimeSlot -1
set slotAssigned -1
set chosenToSend -1
set mySlot -1
set numberSlots -1






loop
	time T
	atnd neighborsNumber neighborsSet	
	
	set messageForwardedPerLoop 0
		
	receive pack
	rdata pack PACKkindMessage
	
	
	if(PACKkindMessage=="SYN")
	
		rdata pack SYNkindPackReceived SYNpackVersion SYNslotAssigned SYNnumberSlots SYNlimitTimeSlot SYNsinkId SYNlowestSensorId SYNnumberOfNodes SYNhopSensor1 SYNhopSensor2 SYNhopSensor3
		
		if(directiveVersion<SYNpackVersion)
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


	if((chosenToSend==1) && (sendDataType=="ACK") && (messageToBeAcked!="X"))

		rdata messageToBeAcked TBAkindMessage TBAtimeMessage TBAttl TBAsenderId TBAreceiverId TBAdataMessage TBAhopSensor1 TBAhopSensor2 TBAhopSensor3
		data myAck "ACK" T limitTimeSlot mySensorId TBAsenderId TBAdataMessage TBAhopSensor3 TBAhopSensor2 TBAhopSensor1
		
		send myMsg *
		set messageForwarded messageForwarded+neighborsNumber
		set messageForwardedPerLoop messageForwardedPerLoop+neighborsNumber
		
		set sendDataType "NIL"
		set messageToBeAcked "X"
	end

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

