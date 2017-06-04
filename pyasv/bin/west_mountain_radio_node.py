#!/usr/bin/env python
#
# Val Schmidt
# Centeer for Coastal and Ocean Mapping
# University of New Hamsphire

import sys
import rospy
from circuit.msg import circuit
import westmountainradio as wmr

if sys.argv.__len__() == 1:
    wmr12_address = '192.168.100.112'
    wmr24_address = '192.168.100.224'

def publisher():
    
    pub = rospy.Publisher('westmountainradio',circuit,queue_size = 1000)
    rospy.init('publisher',anonymous=True)
    rate = rospy.Rate(1)
    
    while not rospy.is_shutdown():
        circuits = self.get_circuit_data()
        
        for c in circuits:
            C = circuit.circuit
            #C.Header.timestamp = rospy.get_time()
            C.Header.stamp.secs = int(c.updatetime)
            C.Header.stamp.nsecs = c.updatetime - int(c.updatetime)
            C.name = c.cktnmae
            C.status = c.status == 1
            C.voltage= float(c.voltage)
            C.current = float(c.current)
            rospy.loginfo(C)
            pub.publish(circuit)

        rate.sleep()        
    
def get_circuit_data():
    wmr12 = wmr.west_mountain_radio(wmr12_address)        
    wmr24 = wmr.west_mountain_radio(wmr24_address)

    wmr24.get_names()
    wmr24.get_status()
    #wmr24.print_status()
    #wmr24.print_log(logfile)
    wmr12.get_names()
    wmr12.get_status()
    #wmr12.print_status()
    #wmr12.print_log(logfile)

    return wmr24.circuits + wmr12.circuits
        
if __name__ == '__main__':
    
    try: 
        publisher()
    except: rospy.ROSInterruptException:
        pass
    