# This is the python 2.7 implementation of log_analyze


"""
   TagMsg is the class that abstract a single message in the log. 
   It is simply a collection of name, value pairs stored as a dictionary.

   You can access the values like this:
		value = msg[ 'name' ]
	to set the value
   		msg[ 'name' ] = value

   	To check if the message has certain name OR value you can use the 'has'
   	    msg.has('name')

   	All other functions are internal functions and is not useful to the end user

"""
class TagMsg:

	def __init__(self, tags = None ) :
		if tags :
			self.tags = tags
		else :
			self.tags = {}

	def add(self, tags ) :
		for i in tags.keys():
			self.tags[i] =tags[i]
		
	def has(self, i) :
		if i in self.tags.keys() + self.tags.values() :
			return True
		return False

	def string(self) :
		#return join "\t" , map "$_\t$self->{$_}", sort keys %$self;
		return "\t".join( [ n + "\t" + v for (n,v) in self.tags.items() ] )

	def __str__(self) :
		return self.string()

	def __getitem__(self,key) :
		if key in self.tags.keys() :
			return self.tags[key]
		else :
			return None
	def __setitem__(self,key,value) :
			self.tags[key] = value


"""
	This is the class that abstract a whole log. it is simply a list of TagMsg objects
	You can access an individual line by:
	    log[i]
	where i is the index of the message.
	For a list of lines use just like python array slices
		log[i:j] 

	To open a tag file:
		log = TagLog( filename ) 

	To run a query
		result = log.find( query )
		result will be a list of tuples with start snd end values
		eg: [(1,2), (3,4)] or []

	Only the above mechanisms are exposed to the user. All other functions in this calss are
	internal and may change in future.

"""
class TagLog:

	def __init__(self, filename = None, lines = None , msgs = None) :
		self.log = []
		self.index = 0
		if filename :
			self.load(filename)
		if lines :
			self.load_lines(lines)
		if msgs :
			for i in msgs :
				self.log.append( i )


	
	#def __iter__(self) :
	#	return self
	#def next(self) :
	#	if self.index == len(self.log):
	#		raise StopIteration
	#	self.index = self.index + 1
	#	return self.log[self.index - 1]

	

	def end(self) :
		return len( self.log ) -1
	
	def add(self, msg) :
		self.log.append(msg)

	def load(self, filename) :
		"""
		Open the file 
		Read contents into an array and call load_lines
		"""
		with open( filename ) as f :
			log = f.read().splitlines() #remove \n
		return self.load_lines(log)
	
	def load_lines(self, log) : #lines from the tag file as a list
		for line in log :
			i = iter( line.split("\t") ) #creating an iterator after splitting on \t
			d = dict(zip(i,i)) #convert to a dict
			self.log.append( TagMsg(d) )



	"""
	The find function returns a list of tuples with start and end values of matching sequences
	If no matched sequences empty list is returned []
	"""
	def find(self, query, start=0, end=None ) :
		if not end :
			end = self.end() #last index

		#to handle recursion we need these checks
		if start > end or end > self.end() :
			return []

		starts = self.find_pattern(query['start'], start, end )
		if not starts : 
			return [] 

		if 'end' not in query.keys() :
			return starts

		#we have an end pattern as well
		ends = self.find_pattern( query['end'], starts[0][1], end ) #starts[0][1] is end of first match of the sequence.
		

		if 'middle' in query.keys() :
			middles = self.find_pattern( query['middle'], starts[0][1], end )
			#if middle is empty we can simply fail the query.
			if not middles : return []

		if 'not' in query.keys() :
			nots = self.find_pattern( query['not'], starts[0][1], end )

		#print starts
		#print ends

		results = []
		s = 0
		while True:
			sv = self.get_after(starts,s)
			if not sv: break

			(s_start, s_end) = sv

			e = s_end + 1
			while True:
				ev = self.get_after(ends,e)
				if not ev: break

				(e_start, e_end) = ev
				ok = True

				#check the middle now
				if 'middle' in query.keys() and not self.is_present( middles, s_end+1, e_start-1 ) :
					s_end = e_end
					ok = False #we need to continuw the loop of ends.


				if 'not' in query.keys() :
					n = self.is_present(nots, s_end+1, e_start-1)
					if n : #not is present we can skip some
						s_end = n[0] -1 #this is the start of not. #-1 is to offset the +1 at the end of the loop.
						break;


				if ok :
					results.append( (s_start, e_end) )
					s_end = e_end
					break  #from the inner loop
				e = e_end + 1
				#print "e =", e

			s = s_end + 1
			#print "s = ", s


		return results

	def find_pattern(self, pattern, start, end) :
		import types
		if type(pattern) == types.DictType :
			return self.find(pattern, start, end)
		if type(pattern) == types.ListType :
			return self.find_multi_pattern(pattern, start, end)
		if type(pattern) == types.FunctionType : 
			return self.find_single_pattern( pattern, start, end )
		#Some error
		print( "Invalid Query: " + str(pattern) )
		import sys
		sys.exit()

	def find_single_pattern(self, pattern_function, start, end) :
		#print "in find single pattern"
		result = []
		for i in range(start, end+1) : #range is one less than the second parameter.
			if pattern_function( self.log[i] ) :
				result.append( (i,i) )
		return result

	def find_multi_pattern(self, pattern_list, start, end) :
		#print "in multi pattern"
		result = []
		for pattern in pattern_list :
			result += self.find_pattern(pattern, start, end) 
		return result

	def get_after(self, l, value) :
		#print "val = ", value
		for t in l :
			if t[0] >= value :
				return t
		return () #null tuple
		#return [ t for t in l if t[0] >= value ]
		
		

	def is_present(self, l, s, e ) :
		for t in l :
			if t[0] >= s and t[1] <= e :
				return t
		return False

	def __getitem__(self,key) :
		if isinstance( key, slice ) :
			return [self.log[i] for i in xrange(*key.indices(len(self.log)))]
		elif isinstance( key, int ) :
			return self.log[key]
		else:
			raise TypeError, "Invalid argument type."
	def __len__(self) :
		return len(self.log)