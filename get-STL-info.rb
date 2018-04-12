#####################################################################################################
#	This version should run cleaner – closes files after parsing and writing to them				#
#																									#
#	Other changes – creates a DECLINE csv as well as a STL csv for all STL 							#
#	file extensions (i.e. .A, .B, .C, etc.)															#
#	It still does NOT separate by DOB, but instead by filename (i.e. DECLINES_20161230_STL.csv, 	#
#	stl_20161230_A.csv, etc.)																		#
#																									#
#	It should now (somewhat) correctly update an multiple Auths by adding the new amount to the 	#
#`	original transaction (and is noted how many times in first column)								#
#																									#
#	Note that by design, if the check number changes but has the same Reference Number, it 			#
#	creates a new line for that new check.															#
#	I still need to figure out how to deal with that since it is not always an error…				#
#	I am considering putting them in one row and adding a “Notes” column at the end where the 		#
#	old check numbers are appended.																	#
######################################################################################################

require 'rubygems'
require 'fileutils'
require 'date'

exit if Object.const_defined?(:Ocra)

dirname = "stl-csv" #File.dirname("stl-csv")
FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

today = DateTime.now
month = "%02d" % today.month
day = "%02d" % today.day
date = "#{today.year}#{month}#{day}"
output = "stl#{date}.csv"

class Trans
	attr_accessor :num
	attr_accessor :type
	attr_accessor :dob
	attr_accessor :date
	attr_accessor :time
	attr_accessor :emp
	attr_accessor :table
	attr_accessor :check
	attr_accessor :amt
	attr_accessor :bam
	attr_accessor :tip
	attr_accessor :card
	attr_accessor :mask
	attr_accessor :exp
	attr_accessor :appr
	attr_accessor :auth
	attr_accessor :error
	attr_accessor :filetype
	attr_accessor :filename
	attr_accessor :ref
	attr_accessor :txn
	attr_accessor :info
	attr_accessor :authNum
	def initialize(num, options={})
		self.num = num
		self.type = options[:type]
		self.dob = options[:dob]
		self.date = options[:date]
		self.time = options[:time]
		self.emp = options[:emp]
		self.table = options[:table]
		self.check = options[:check]
		self.amt = options[:amt]
		self.bam = options[:bam]
		self.tip = options[:tip]
		self.card = options[:card]
		self.mask = options[:mask]
		self.exp = options[:exp]
		self.appr = options[:appr]
		self.auth = options[:auth]
		self.error = options[:error]
		self.filetype = options[:filetype]
		self.filename = options[:filename]
		self.ref = options[:ref]
		self.txn = ""
		self.info = ""
		self.authNum = 1
	end
	def getTXN()
		self.txn = "#{self.type},#{self.dob},#{self.date},#{self.time},#{self.emp},#{self.table},#{self.check},#{self.amt},#{self.bam},#{self.tip},#{self.card},#{self.mask},#{self.exp},#{self.appr},#{self.auth},#{self.error},#{self.filetype},#{self.filename},#{self.ref},"
	end
	def adjustTip(newBAM, newTIP)
		self.bam = newBAM
		self.tip = newTIP
		if(self.type =~ /AUTH*/)
			self.type = "AUTH-ADJ"
		end
	end
	def adjustAuth(newBAM, newTIP)
		bamFl = self.bam.to_f + newBAM.to_f
		tipFl = self.tip.to_f + newTIP.to_f
		self.bam = sprintf("%.2f", bamFl)
		self.tip = sprintf("%.2f", tipFl)
		self.authNum += 1
		if(self.type =~ /AUTH*/)
			self.type = "AUTH-#{self.authNum}x"
		end
	end
	def getSTL()
		self.txn = "#{self.type},#{self.dob},#{self.date},#{self.time},#{self.info},,,,,,,,,#{self.appr},#{self.auth},#{self.error},#{self.filetype},#{self.filename},#{self.ref}"
	end
#	def checkRef(newRef)
#		if self.ref == newRef
#			return true
#		else
#			return false
#		end
#	end
#	def checkCheck (newCheck)
#		if self.check == newCheck
#			return true
#		else
#			return false
#		end
#	end
#	def checkMask(newMask)
#		if self.mask == newMask
#			return true
#		else
#			return false
#		end
#	end
#	def checkAdj(isAdjust)
#		if isAdjust == "ADJUST"
#			return true
#		else
#			return false
#		end
	def isAdjust()
		if self.type == "ADJUST"
			return true
		else
			return false
		end
	end
end
a=[]
b =[]
s = []
c = Trans.new("NUM", :type => "TYPE", :dob => "DOB", :date => "DATE", :time => "TIME", :emp => "EMPLOYEE", :table => "TABLE", :check => "CHECK", :amt => "AUTHAMT", :bam => "BATCHAMT", :tip => "BATCHTIP", :card => "CARDTYPE", :mask => "CARDMASK", :exp => "EXP", :appr => "APPROVED", :auth => "AUTH", :error => "ERROR", :filename => "FILETYPE", :filetype => "FILENAME", :ref => "REF")
c.getTXN()
a << c
b << c

auth = 0
adj = 0
cred = 0
void = 0
stl = 0
declines = 0

num = 0
tran = ""
dobT = ""
dateT = ""
time = ""
emp = ""
table = ""
check = ""
amt = ""
bam = ""
tip = ""
card = ""
mask = ""
exp = ""
appr = ""
authorize = ""
error = ""
ref = ""
info = ""

sumBam = 0
sumTip = 0
sumRef = 0
sumTot = 0
bamV = 0
tipV = 0
refV = 0
sumV = 0
bamA = 0
tipA = 0
refA = 0
sumA = 0
bamM = 0
tipM = 0
refM = 0
sumM = 0
bamD = 0
tipD = 0
refD = 0
sumD = 0
numV = 0
numA = 0
numM = 0
numD = 0
sumNum = 0

open = false
update = false
txn = []
decl = false
#wr = false
hash = {}
adjust = false



files = Dir.entries(".")
#crunchAll = File.open("cards-ALL.csv", 'w')
crunchAll = File.open("#{dirname}\\cards-ALL.csv", 'w')
files.each do |file|
	if ( (!File.directory?(file)) && (file =~ /^(\d{8}\.*\d{0,3})\.(\w+)$/i) )
		dob, ext = $1, $2
		
		list = File.open(file, 'r')
		list.each do |line|
			
			if line.match(/AUTHORIZE/i)
				auth += 1
			elsif line.match(/ADJUST/i)
				adj += 1
			elsif line.match(/CREDIT/i)
				cred += 1
			elsif line.match(/DELETE/i)
				void += 1
			elsif line.match(/APPROVED\s+NO/i)
				declines += 1
			end
			
			if line.match(/BEGIN/i)
				open = true
			elsif line.match(/APPROVED\s+NO/i)
				decl = true
			elsif line.match(/^END$/)
				t = Trans.new("#{num}", :type => "#{tran}", :dob => "#{dobT}", :date => "#{dateT}", :time => "#{time}", :emp => "#{emp}", :table => "#{table}", :check => "#{check}", :amt => "#{amt}", :bam => "#{bam}", :tip => "#{tip}", :card => "#{card}", :mask => "#{mask}", :exp => "#{exp}", :appr => "#{appr}", :auth => "#{authorize}", :error => "#{error}", :filename => "", :filetype => "", :ref => "#{ref}")
				if (decl && tran != "")
					if (t.isAdjust())
#					if (tran == "ADJUST")
						a.each do |refr|
							if (refr.ref == ref)
								if (refr.check == check)
									if (refr.mask == mask)
										refr.adjustTip(bam, tip)
										refr.getTXN()
										adjust = true
									else
										t.type = "MASK-MISMATCH"
										t.getTXN()
										a << t
										adjust = true
									end
								else
									t.type = "CHECK-MISMATCH"
									t.getTXN()
									a << t
									adjust = true
								end
							end
						end
						if (adjust)
							adjust = false
						else
							t.getTXN()
							a << t
						end
					elsif (tran == "SETTLE")
						t.getSTL()
						s << t
						a << t
					else
						a.each do |refr|
							if (refr.ref == ref)
								if (refr.check == check)
									if (refr.mask == mask)
										refr.adjustAuth(bam, tip)
										refr.getTXN()
										adjust = true
									else
										t.type = "MASK-MISMATCH"
										t.getTXN()
										a << t
										adjust = true
									end
								else
									t.type = "CHECK-MISMATCH"
									t.getTXN()
									a << t
									adjust = true
								end
							end
						end
						if (adjust)
							adjust = false
						else
							t.getTXN()
							a << t
						end
					end
				elsif (tran != "")
					if (t.isAdjust())
#					if (tran == "ADJUST")
						b.each do |refr|
							if (refr.ref == ref)
								if (refr.check == check)
									if (refr.mask == mask)
										refr.adjustTip(bam, tip)
										refr.getTXN()
										adjust = true
									else
										t.type = "MASK-MISMATCH"
										t.getTXN()
										b << t
										adjust = true
									end
								else
									t.type = "CHECK-MISMATCH"
									t.getTXN()
									b << t
									adjust = true
								end
							end
						end
						if (adjust)
							adjust = false
						else
							t.getTXN()
							b << t
						end
					elsif (tran == "VOID")
						b.each do |refr|
							if (refr.ref == ref)
								b.delete(refr)
							end
						end
					elsif (tran == "SETTLE")
						t.getSTL()
						s << t
						b << t
					else
						b.each do |refr|
							if (refr.ref == ref)
								if (refr.check == check)
									if (refr.mask == mask)
										refr.adjustAuth(bam, tip)
										refr.getTXN()
										adjust = true
									else
										t.type = "MASK-MISMATCH"
										t.getTXN()
										b << t
										adjust = true
									end
								else
									t.type = "CHECK-MISMATCH"
									t.getTXN()
									b << t
									adjust = true
								end
							end
						end
						if (adjust)
							adjust = false
						else
							t.getTXN()
							b << t
						end
					end
				end
				tran = ""
				dobT = ""
				dateT = ""
				time = ""
				emp = ""
				table = ""
				check = ""
				amt = ""
				bam = ""
				tip = ""
				card = ""
				mask = ""
				exp = ""
				appr = ""
				authorize = ""
				error = ""
				ref = ""
				info = ""
#				wr = true
				decl = false
				open = false
				adjust = false
			end
			
			if (open)
				if line =~ /^\s+TYPE\s+(.+)$/i
					tran = $1
				elsif line =~ /^\s+DOB\s+(.+)$/i
					dobT = $1
				elsif line =~ /^\s+DATE\s+(.+)$/i
					dateT = $1
				elsif line =~ /^\s+TIME\s+(.+)$/i
					time = $1
				elsif line =~ /^\s+EMPLOYEE\s+(.+)$/i
					emp = $1
				elsif line =~ /^\s+TABLE\s+(.+)$/i
					table = $1
				elsif line =~ /^\s+CHECK\s+(.+)$/i
					check = $1
				elsif line =~ /^\s+AUTHAMT\s+(.+)$/i
					amt = $1
				elsif line =~ /^\s+BATCHAMT\s+(.+)$/i
					bam = $1
				elsif line =~ /^\s+BATCHTIP\s+(.+)$/i
					tip = $1
				elsif line =~ /^\s+CARDTYPE\s+(.+)$/i
					card = $1
				elsif line =~ /^\s+CARDMASK\s+X+(.+)$/i
					mask = $1
				elsif line =~ /^\s+EXP\s+(.+)$/i
					exp = $1
				elsif line =~ /^\s+REF\s+(.+)$/i
					ref = $1
				elsif line =~ /^\s+AUTH\s+(.+)$/i
					authorize = $1
				elsif line =~ /^\s+APPROVED\s+(.+)$/i
					appr = $1
				elsif line =~ /^\s+ERROR\s+(.+)$/i
					error = $1
				elsif line =~ /^\s+INFO\s+(.+)$/i
					info = $1
				end
			end
		end
		if declines > 0
			entry = File.open("#{dirname}\\DECLINES-stl_#{dob}_#{ext}.csv", 'w')
			a.each do |ax|
				entry.puts "#{ax.txn}"
			end
			entry.close()
		end
		if auth > 0
			entry = File.open("#{dirname}\\stl_#{dob}_#{ext}.csv", 'w')
#			crunch = File.open("cards#{dob}.csv", 'w')
			b.each do |bx|
				entry.puts "#{bx.txn}"
			end
			entry.close()
			b.each do |cx|
				if cx.card =~ /VISA/i
					if cx.type == "CREDIT"
						refV += cx.bam.to_f + cx.tip.to_f
					elsif cx.type != "ADJUST"
						bamV += cx.bam.to_f
					end
					numV += 1
#					puts "#{cx.card}"
					tipV += cx.tip.to_f
				elsif cx.card =~ /AMEX/i
					if cx.type == "CREDIT"
						refA += cx.bam.to_f + cx.tip.to_f
					elsif cx.type != "ADJUST"
						bamA += cx.bam.to_f
					end
					numA += 1
					tipA += cx.tip.to_f
				elsif cx.card =~ /MASTERCARD/i
					if cx.type == "CREDIT"
						refM += cx.bam.to_f + cx.tip.to_f
					elsif cx.type != "ADJUST"
						bamM += cx.bam.to_f
					end
					numM += 1
					tipM += cx.tip.to_f
				elsif cx.card =~ /DISCOVER/i
					if cx.type == "CREDIT"
						refD += cx.bam.to_f + cx.tip.to_f
					elsif cx.type != "ADJUST"
						bamD += cx.bam.to_f
					end
					numD += 1
					tipD += cx.tip.to_f
				end
			end
			sumV = bamV + tipV
			sumA = bamA + tipA
			sumM = bamM + tipM
			sumD = bamD + tipD
			sumBam = bamV + bamA + bamM + bamD
			sumTip = tipV + tipA + tipM + tipD
			sumRef = refV + refA + refM +refD
			sumTot = sumBam + sumTip
			sumNum = numV + numA + numM + numD
#			crunch.puts "CardType,Auths,Tips,Refunds,Total"
#			crunch.puts "VISA,#{bamV},#{tipV},#{refV},#{sumV}"
#			crunch.puts "AMEX,#{bamA},#{tipA},#{refA},#{sumA}"
#			crunch.puts "MC,#{bamM},#{tipM},#{refM},#{sumM}"
#			crunch.puts "DISC,#{bamD},#{tipD},#{refD},#{sumD}"
#			crunch.puts "Total,#{sumBam},#{sumTip},#{sumRef},#{sumTot}"
			crunchAll.puts "#{dob}.#{ext}, #{s[0].info},#{s[0].dob},#{s[0].date},#{s[0].time}"
			crunchAll.puts "CardType,Auths,Tips,Refunds,Total,,NumTXNs"
			crunchAll.puts "VISA,#{bamV},#{tipV},#{refV},#{sumV},,#{numV}"
			crunchAll.puts "MC,#{bamM},#{tipM},#{refM},#{sumM},,#{numM}"
			crunchAll.puts "DISC,#{bamD},#{tipD},#{refD},#{sumD},,#{numD}"
			crunchAll.puts "AMEX,#{bamA},#{tipA},#{refA},#{sumA},,#{numA}"
			crunchAll.puts "Total,#{sumBam},#{sumTip},#{sumRef},#{sumTot},,#{sumNum}"
			crunchAll.puts ""
		end
		num = 0
		puts "#{dob}, there were #{auth} Transactions, #{cred} Refunds and #{declines} DECLINES\n"
		stl += 1
		auth = 0
		adj = 0
		cred = 0
		void = 0
		declines = 0
		sumV = 0
		sumA = 0
		sumM = 0
		sumD = 0
		numV = 0
		numA = 0
		numM = 0
		numD = 0
		sumBam = 0
		sumTip = 0
		sumRef = 0
		sumTot = 0
		sumNum = 0
		bamV = 0
		tipV = 0
		refV = 0
		bamA = 0
		tipA = 0
		refA = 0
		bamM = 0
		tipM = 0
		refM = 0
		bamD = 0
		tipD = 0
		refD = 0
		a = []
		a << c
		b = []
		b << c
		s = []
		list.close()
	end
end

crunchAll.close()

were = "were"
s = "s"
if (stl === 1)
	were = "was"
	s = ""
end

puts "There #{were} #{stl} STL Marker#{s}\n\n\n"


system('pause')