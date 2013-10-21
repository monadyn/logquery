from TagLog import *

"""
A marker is simply a function that returns true based on some values inside the message.
For example if we want the message id to be matched, we can write a function with
	return msg[msg_id] == 'A'
A shortcut for this is to search for the string A in the message
    return msg.has('A')

The function can be an anonymous function created with lambda. Refer python documentation.
	lambda msg : msg.has('MSG_ID_RRCC_CELL_CAMP_REQ')

"""

def A_msg(msg) :	return msg.has('A') 
def B_msg(msg) :	return msg.has('B') 
def C_msg(msg) :	return msg.has('C') 
def D_msg(msg) :	return msg.has('D') and msg['id'] == '4' #note the 4 must be quaoted; all are strings so msg[id] == 4 is wrong


"""
A Query is simply a dictionay with start, end, middle, and not keys.
"""

q1 = {
	'start' : A_msg,
	'end'	: D_msg,
	#'middle': C_msg,
	#'not'   : B_msg
}

log = TagLog( "example_log.tag" )
r = log.find(q1)
print "return(q1) = " , r

"""
The find function returns a list of tuples with start and end values of matching sequences
If no matched sequences empty list is returned []
"""

	
##############################################################
q2 = {
	'start' : A_msg,
	'end'	: D_msg,
	'middle': [ C_msg , B_msg ],
	#'middle': C_msg ,

}

r = log.find(q2)
print "return(q2) = " , r

##############################################################
# The functions can be anonymous lambda funtions

#This query prints all the messages with time == 10
q3 = {
	'start' : lambda msg : msg['time'] == '10'
}
r = log.find(q3)
print "return(q3) = " , r

##############################################################

q4 = {
	'start'  : q2,
	'end'    : [q1, D_msg]  # matches q1 or D
}
r = log.find(q4)
print "return(q4) = " , r

##############################################################

q5 = {
	'start'  : q1,
	'end'    : q1,
	'middle'    : lambda msg : msg['msg_id'] == 'E'
}
r = log.find(q5)
print "return(q5) = " , r


# if you want to print the lines matched

#the return from find a list of tuples.

print "found " , len(r) , "sequences"
for (s,e) in r :
	msgs_list = log[s:e]
	#message list is a slice of the log. It still has the TagMsg objects. 
	for m in msgs_list :
		print "msg_id = ", m['msg_id']


	for m in log[s:e] :
		print m  #just print the strings. Remember, m is an object of TagMsg. But print will convert to string.

