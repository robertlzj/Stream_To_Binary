# Feature
- Transition between length-fixed data and binary (not text) data of file handle.
- Read fix format unit in the order from top to end, and asynchronously Write at end.
- Auto check closed file handle.
- Redundant check on write name / type.

# Usage
```lua
Stream_To_Binary=require'Stream_To_Binary'
Stream_Binary_Accessor=Stream_To_Binary(File_Path)
Stream_Binary_Accessor:Write_Data_Type(0xffff,0x7f,-4,'f'):Write_Name('Unsigned Int','Signed Short','Unsigned Long','4-byte float')
:Append_Data(65535,-0x80,0x7FFFFFFF,12.34)
:Append_Data(0,0x7f,-0x80000000,0.01234)
:Close()
```
See [test.lua].