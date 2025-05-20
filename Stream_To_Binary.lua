--https://github.com/robertlzj/Stream_To_Binary

local Value_To_Format_String={
	--Unsigned, Signed
	[0xFF]='B',[0x7F]='b',[1]='B',[-1]='b',
	[0xFFFF]='H',[0x7FFF]='h',[2]='H',[-2]='h',
	[0xFFFFFFFF]='L',[0x7FFFFFFF]='l',[4]='L',[-4]='l',
	[1.0]='f',--4-byte
	[2.0]='d',--8-byte
}
assert(string.packsize'B'==1 and string.packsize'H'==2 and string.packsize'L'==4 and string.packsize'f'==4 and string.packsize'd'==8,"Stream_To_Binary: data native size inconsistency")
local Stream_Binary_Accessor_Meta={
	--[[instance only
		--instance on `Stream_Binary_Accessor`.
		File_Handle=nil,
		Data_Type_List=nil,
		[-n]..[-1]=Name_n,..Name_1,
		Previous_Seek_Position_For_Read=1,
	]]
	__index={
		Write_Data_Type=function (self,...)
			local File_Handle=assert(self.File_Handle)
			local Data_Type_List_Item_List={}
			for Index=1,select('#',...) do
				local Value=select(Index,...)
				if type(Value)=='string' then
					assert(string.find(Value,'[bBhHlLfd]'))
					table.insert(Data_Type_List_Item_List,Value)
				elseif math.type(Value)=='float' then
					table.insert(Data_Type_List_Item_List,'f')
				else assert(math.type(Value)=='integer')
					table.insert(Data_Type_List_Item_List,Value_To_Format_String[Value])
				end
			end
			local Data_Type_List=table.concat(Data_Type_List_Item_List)
			if self.Data_Type_List~=Data_Type_List then
				assert(not self.Data_Type_List and File_Handle:seek()==0)
				self.Data_Type_List=Data_Type_List
				File_Handle:write(Data_Type_List,'\n')
				self.Previous_Seek_Position_For_Read=File_Handle:seek()
			end
			return self
		end,
		Write_Name=function(self,...)
			local File_Handle=assert(self.File_Handle)
			local Data_Type_List=assert(self.Data_Type_List)
			local Data_Type_List_Length=#Data_Type_List
			local Count=select('#',...)
			;	assert(Count==Data_Type_List_Length)
			for Index=1,Data_Type_List_Length do
				local Name=select(Index,...) or ''
				assert(not string.find(Name,'\n'))
				if self[-Count+Index-1] then
					assert(self[-Count+Index-1]==Name)
				else
					File_Handle:write(Name,'\n')
					self[-Count+Index-1]=Name
				end
			end
			self.Previous_Seek_Position_For_Read=File_Handle:seek()
			return self
		end,
		Append_Data=function(self,...)
			local File_Handle=assert(self.File_Handle)
			local Data_Type_List=assert(self.Data_Type_List)
			File_Handle:seek('end')
			File_Handle:write(string.pack(Data_Type_List,...))
			return self
		end,
		Read_Name=function(self)
			assert(self.File_Handle)
			if self.Data_Type_List then
				return table.unpack(self,-#self.Data_Type_List,-1)
			end
		end,
		Iter_Data=function(self,Data_Number)
			local File_Handle=assert(self.File_Handle)
			local Data_Type_List=assert(self.Data_Type_List)
			local Byte_Counts=string.packsize(Data_Type_List)
			return function()
				File_Handle:seek('set',self.Previous_Seek_Position_For_Read)
				local Bytes_String=File_Handle:read(Byte_Counts)
				if Bytes_String then
					assert(#Bytes_String==Byte_Counts)
					self.Previous_Seek_Position_For_Read=self.Previous_Seek_Position_For_Read+Byte_Counts
					return string.unpack(Data_Type_List,Bytes_String)
					--	at end there will be an additional value- "the index of the first unread byte"
				end
			end
		end,
		Close=function(self)
			local File_Handle=assert(self.File_Handle)
			File_Handle:close()
			self.File_Handle=nil
		end,
	},
	__gc=function(self)
		local File_Handle=self.File_Handle
		if File_Handle and io.type(File_Handle)=='file' then
			File_Handle:flush()
			self.File_Handle=nil
		end
	end,
}
local function Stream_To_Binary(File_Handle)
	assert(io.type(File_Handle)=='file')
	local Data_Type_List=File_Handle:read'l'
	local Stream_Binary_Accessor=setmetatable({
		Data_Type_List=Data_Type_List,
		File_Handle=File_Handle,
	},Stream_Binary_Accessor_Meta)
	if Data_Type_List then
		for Index=-#Data_Type_List,-1 do
			local Name=File_Handle:read'l'
			Stream_Binary_Accessor[Index]=Name
		end
		Stream_Binary_Accessor.Previous_Seek_Position_For_Read=File_Handle:seek()
	end
	return Stream_Binary_Accessor
end

return Stream_To_Binary