unit rom;

interface

uses System.Classes;

{

go 的实现
const iNESFileMagic = 0x1a53454e



type iNESFileHeader struct {

	Magic    uint32  // iNES magic number

	NumPRG   byte    // number of PRG-ROM banks (16KB each)

	NumCHR   byte    // number of CHR-ROM banks (8KB each)

	Control1 byte    // control bits

	Control2 byte    // control bits

	NumRAM   byte    // PRG-RAM size (x 8KB)

	_        [7]byte // unused padding

}

const
  NESMAGIC = $1A53454E;
type
  TRomHeader = packed record
    Magic : Cardinal;
    NumPRG:Byte; // PRG-ROM的 bank块数 每块16k大小
    NumChr:Byte; // CHR-ROM的 bank 块数 每块8kb大小
    Control1 : Byte;
    Control2 : Byte;
    NumRAM  : Byte;   //PRG-RAM 的大小 每块8k
    NoneUsed :array[0..6] of Byte; //未使用
  end;

  TPRG_Chunk = array[0..16384 - 1] of Byte;
  TCHR_Chunk = array[0..8192 - 1] of Byte;

  TRom  = class(TObject)
  private
    _Header: TRomHeader;
    _MapperType:Byte; //Mapper类型
    _Mirror : Byte;  //1＝垂直镜像，0＝水平镜像
    _Battery : Byte; // 1＝有电池记忆，SRAM地址$6000-$7FFF
    _Trainer :Boolean; // SRAM在$7000-$71FF有一个512字节的trainer 会将这个512个自己的内容载入内存通常在这里写作弊程序 然后修改正常rom代码跳转到这里
    _PRG_Chunks : array of TPRG_Chunk;
    _CHR_Chunks : array of TCHR_Chunk;
  public
    function LoadFromFile(const FileName:String) : Boolean;

  end;

implementation

{ TRom }

function TRom.LoadFromFile(const FileName: String):Boolean;
var
  Stream : TMemoryStream;
  mirror1,mirror2:Byte;
  i:Integer;
  ChunkSize:Integer;
begin
  Stream := TMemoryStream.Create;
  Try
    Stream.LoadFromFile(FileName);
    Stream.Position := 0;

    if  (Stream.Read(_Header,SizeOf(_Header)) <> SizeOf(_Header)) then
    begin
      Result  := False;
      Exit;
    end;

    if _Header.Magic <> NESMAGIC then
    begin
      Result := False;
      Exit;
    end;

     _MapperType := (_Header.Control1 shr 4) or ((_Header.Control2 shr 4) shl 4); // control 1 2 的高4 位记录着Mapper的类型

    // mirroring type
    mirror1 := _Header.Control1 and 1 ;

    mirror2 := _Header.Control1 shr 3 and 1;

    _Mirror := mirror1 and  mirror2 shl 1 ;

    _Battery := (_Header.Control1 shr 1 ) and 1;

    _Trainer :=  (_Header.Control1 and 4) = 4;

    if _Trainer then
      Stream.Position :=  Stream.Position + 512; //如果有_Trainer  要往后跳 512

    SetLength(_PRG_Chunks,_Header.NumPRG);
    ChunkSize := SizeOf(TPRG_Chunk) * _Header.NumPRG;
    if (Stream.Read(_PRG_Chunks[0],ChunkSize) <> ChunkSize) then
    begin
      Exit;
      Result := False;
    end;


    SetLength(_CHR_Chunks,_Header.NumChr);
    ChunkSize := SizeOf(TCHR_Chunk) * _Header.NumChr;
    if _Header.NumChr > 0 then
    begin
      if (Stream.Read(_CHR_Chunks[0],SizeOf(_CHR_Chunks)) <> SizeOf(_CHR_Chunks)) then
      begin
        Exit;
        Result := False;
      end;
    end;
    Result := True;
  Finally
    Stream.Free;
  End;
end;

end.
