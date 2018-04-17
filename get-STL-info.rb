#####################################################################################################
#	Changes v0.3.12: Modified CardType for cards-ALL.csv to include variations for MC and Discover	#
#																									#
#	Changes v0.3.11: creates a DECLINE folder as well as a SETTLEMENTS folder for each file-type	#
#																									#
#	It still does NOT separate by DOB, but instead by filename (i.e. DECLINES_20161230_STL.csv, 	#
#	stl_20161230_A.csv, etc.)																		#
#																									#
#	I removed some parts where it tells you if a REF is mismatched by card-mask or Check Number 	#
#	This should be used with caution since it will not alert the user of this discrepancy			#
#	NOTE that this is only for Successful authorizations; Declines should function the same			#
#																									#
#	I am still considering adding a “Notes” column at the end where the old check numbers or 		#
#	credit card masks are appended.																	#
######################################################################################################

require 'rubygems'
require 'fileutils'
require 'date'

exit if Object.const_defined?(:Ocra)

dirname = "stl-csv" #File.dirname("stl-csv")
FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
declinesName = "stl-csv\\DECLINES"
FileUtils.mkdir_p(declinesName) unless File.directory?(declinesName)
stlName = "stl-csv\\SETTLEMENTS"
FileUtils.mkdir_p(stlName) unless File.directory?(stlName)

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
	attr_accessor :filename
	attr_accessor :filetype
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
		self.filename = options[:filename]
		self.filetype = options[:filetype]
		self.ref = options[:ref]
		self.txn = ""
		self.info = ""
		self.authNum = 1
	end
	def getTXN()
		self.txn = "#{self.type},#{self.dob},#{self.date},#{self.time},#{self.emp},#{self.table},#{self.check},#{self.amt},#{self.bam},#{self.tip},#{self.card},#{self.mask},#{self.exp},#{self.appr},#{self.auth},#{self.error},#{self.filename},#{self.filetype},#{self.ref},"
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
		self.txn = "#{self.type},#{self.dob},#{self.date},#{self.time},#{self.info},,,,,,,,,#{self.appr},#{self.auth},#{self.error},#{self.filename},#{self.filetype},#{self.ref}"
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
c = Trans.new("NUM", :type => "TYPE", :dob => "DOB", :date => "DATE", :time => "TIME", :emp => "EMPLOYEE", :table => "TABLE", :check => "CHECK", :amt => "AUTHAMT", :bam => "BATCHAMT", :tip => "BATCHTIP", :card => "CARDTYPE", :mask => "CARDMASK", :exp => "EXP", :appr => "APPROVED", :auth => "AUTH", :error => "ERROR", :filename => "FILENAME", :filetype => "FILETYPE", :ref => "REF")
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
header = "TYPE,DOB,DATE,TIME,EMPLOYEE,TABLE,CHECK,AUTHAMT,BATCHAMT,BATCHTIP,CARDTYPE,CARDMASK,EXP,APPROVED,AUTH,ERROR,FILENAME,FILETYPE,REF,"


files = Dir.entries(".")
#crunchAll = File.open("cards-ALL.csv", 'w')
decTransFile = File.open("#{dirname}\\DECLINES-all.csv", 'w')
stlTransFile = File.open("#{dirname}\\SETTLEMENTS-all.csv", 'w')
allTransFile = File.open("#{dirname}\\STL-DEC-all.csv", 'w')
perLineFile = File.open("#{dirname}\\data-all.csv", 'w')
allTransFile.puts "#{header}"
decTransFile.puts "#{header}"
stlTransFile.puts "#{header}"
perLineFile.puts "#{header}"

crunchAll = File.open("#{dirname}\\cards-ALL.csv", 'w')
files.each do |file|
	if ( (!File.directory?(file)) && (file =~ /^((\d{8}\.*\d{0,3})\.(\w+))$/i) )
		fullName, dob, ext = $1, $2, $3
		
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
				someLine = t
				someLine.filename = "#{fullName}"
				if (decl && tran != "")
					someLine.getTXN()
					perLineFile.puts "#{someLine.txn}"
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
						t.info = info
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
					someLine.getTXN()
					perLineFile.puts "#{someLine.txn}"
					if (t.isAdjust())
#					if (tran == "ADJUST")
						b.each do |refr|
							if (refr.ref == ref)
#								if (refr.check == check)
#									if (refr.mask == mask)
										refr.adjustTip(bam, tip)
										refr.getTXN()
										adjust = true
#									else
#										t.type = "MASK-MISMATCH"
#										t.getTXN()
#										b << t
#										adjust = true
#									end
#								else
#									t.type = "CHECK-MISMATCH"
#									t.getTXN()
#									b << t
#									adjust = true
#								end
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
						t.info = info
						t.getSTL()
						s << t
						b << t
					else
						b.each do |refr|
							if (refr.ref == ref)
#								if (refr.check == check)
#									if (refr.mask == mask)
										refr.adjustAuth(bam, tip)
										refr.getTXN()
										adjust = true
#									else
#										t.type = "MASK-MISMATCH"
#										t.getTXN()
#										b << t
#										adjust = true
#									end
#								else
#									t.type = "CHECK-MISMATCH"
#									t.getTXN()
#									b << t
#									adjust = true
#								end
							end
						end
						if (adjust)
							adjust = false
						else
							t.getTXN()
							b << t
						end
					end
#					perLineFile.puts "#{t.txn}"
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
					if table.include? ','
						table.sub!(',','')
					end
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
			entry = File.open("#{declinesName}\\DECLINES-stl_#{dob}_#{ext}.csv", 'w')
			a.each do |ax|
				if ax.txn =~ /^TYPE,DOB,DATE.+/
					entry.puts "#{ax.txn}"
				else
					entry.puts "#{ax.txn}"
					decTransFile.puts "#{ax.txn}"
					allTransFile.puts "#{ax.txn}"
				end
			end
			entry.close()
		end
		if auth > 0
			entry = File.open("#{stlName}\\stl_#{dob}_#{ext}.csv", 'w')
#			crunch = File.open("cards#{dob}.csv", 'w')
			b.each do |bx|
				if bx.txn =~ /^TYPE,DOB,DATE.+/
					entry.puts "#{bx.txn}"
				else
					entry.puts "#{bx.txn}"
					stlTransFile.puts "#{bx.txn}"
					allTransFile.puts "#{bx.txn}"
				end
			end
			entry.close()
			b.each do |cx|
				if cx.card =~ /VISA/i
					if cx.type == "CREDIT"
						refV += cx.bam.to_f + cx.tip.to_f
					elsif cx.type != "ADJUST"
						bamV += cx.bam.to_f
						numV += 1
#						puts "#{cx.card}"
						tipV += cx.tip.to_f
					end
				elsif cx.card =~ /AMEX/i
					if cx.type == "CREDIT"
						refA += cx.bam.to_f + cx.tip.to_f
					elsif cx.type != "ADJUST"
						bamA += cx.bam.to_f
						numA += 1
						tipA += cx.tip.to_f
					end
				elsif cx.card =~ /MASTERCARD|MC|M\/C/i
					if cx.type == "CREDIT"
						refM += cx.bam.to_f + cx.tip.to_f
					elsif cx.type != "ADJUST"
						bamM += cx.bam.to_f
						numM += 1
						tipM += cx.tip.to_f
					end
				elsif cx.card =~ /DISCOVER|DISC/i
					if cx.type == "CREDIT"
						refD += cx.bam.to_f + cx.tip.to_f
					elsif cx.type != "ADJUST"
						bamD += cx.bam.to_f
						numD += 1
						tipD += cx.tip.to_f
					end
				end
			end
			sumV = bamV + tipV - refV
			sumA = bamA + tipA - refA
			sumM = bamM + tipM - refM
			sumD = bamD + tipD - refD
			sumBam = bamV + bamA + bamM + bamD
			sumTip = tipV + tipA + tipM + tipD
			sumRef = refV + refA + refM +refD
			sumTot = sumBam + sumTip - sumRef
			sumNum = numV + numA + numM + numD
						
			bamV = "%04.2f" % bamV
			bamM = "%04.2f" % bamM
			bamD = "%04.2f" % bamD
			bamA = "%04.2f" % bamA
			tipV = "%04.2f" % tipV
			tipM = "%04.2f" % tipM
			tipD = "%04.2f" % tipD
			tipA = "%04.2f" % tipA
			refV = "%04.2f" % refV
			refM = "%04.2f" % refM
			refD = "%04.2f" % refD
			refA = "%04.2f" % refA
			sumV = "%04.2f" % sumV
			sumM = "%04.2f" % sumM
			sumD = "%04.2f" % sumD
			sumA = "%04.2f" % sumA
			sumBam = "%04.2f" % sumBam
			sumTip = "%04.2f" % sumTip
			sumRef = "%04.2f" % sumRef
			sumTot = "%04.2f" % sumTot
						
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
decTransFile.close()
stlTransFile.close()
allTransFile.close()
perLineFile.close()

were = "were"
s = "s"
if (stl === 1)
	were = "was"
	s = ""
end

puts "There #{were} #{stl} STL Marker#{s}\n\n\n"


system('pause')
