//------------------------------------------------------------------------------
//GEOSBuild
//=========
//Command-line tool that builds a GEOS file on a Commodore 64/128 disk image
//from its constituent parts.
//
//Exit codes:
//-----------
// 0    - Success
//-1    - Help requested
//-2    - Invalid option specified
//-3    - Processing error
//-4    - Unexpected error
//
//Please note:
//------------
//Presently, only FPC/Lazarus is supported.
//
//Copyright (C) 2016, Daniel England.
//All Rights Reserved.  Released under the GPL.
//
//This program is free software: you can redistribute it and/or modify it under
//the terms of the GNU General Public License as published by the Free Software
//Foundation, either version 3 of the License, or (at your option) any later
//version.
//
//This program is distributed in the hope that it will be useful, but WITHOUT
//ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
//FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
//details.
//
//You should have received a copy of the GNU General Public License along with
//this program.  If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------
program GEOSBuild;

{$IFDEF FPC}
    {$MODE OBJFPC}
{$ENDIF}
{$H+}

uses
{$IFDEF FPC}
    {$IFDEF UNIX}{$IFDEF UseCThreads}
    cthreads,
    {$ENDIF}{$ENDIF}
{$ENDIF}
    Classes, SysUtils, IniFiles, CustApp, C64D64Image;

const
    LIT_TOK_GEOSVLIREND = '__VLIR_END';
    LIT_TOK_GEOSVLIREMY = '__VLIR_EMPTY';

type
{ TGEOSBuild }

    TGEOSBuild = class(TCustomApplication)
    private
        FDiskImage: TD64Image;
        FFileName: string;
        FHeaderFile: TMemoryStream;
        FDirEntry: TD64DirEntry;

        procedure DoWriteBanner(const AInit: Boolean);
        procedure DoGEOSSequentialFile(const AIniFile: TIniFile);
        procedure DoGEOSVLIRFile(const AIniFile: TIniFile);

    protected
        procedure DoRun; override;

        procedure DoProcessBuildFile(const AFileName: string);
        procedure Trace(const AType: TEventType; const AMessage: string);

    public
        constructor Create(TheOwner: TComponent); override;
        destructor Destroy; override;

        procedure WriteHelp; virtual;
    end;

//dengland To signal processing errors
    EGEOSBuildError = class(Exception);

{ TGEOSBuild }

procedure TGEOSBuild.DoWriteBanner(const AInit: Boolean);
    begin
    if  AInit then
        begin
        Writeln('GEOS Build.');
        Writeln(EmptyStr);
        end
    else
        begin
        Writeln('GEOS file build tool.');
        Writeln('Copyright (c) 2016, Daniel England.');
        Writeln('All Rights Reserved.  Released under the GPL.');
        Writeln(EmptyStr);
        Writeln('This program comes with ABSOLUTELY NO WARRANTY; without even' +
                ' the implied');
        Writeln('warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR'+
                ' PURPOSE.  This is free');
        Writeln('software and you are welcome to redistribute it under'+
                ' certain conditions.');
        Writeln(EmptyStr);
        Writeln('See accompanying documentation for further details.');
        Writeln(EmptyStr);
        Writeln(EmptyStr);
        Writeln(EmptyStr);
        end;
    end;

procedure TGEOSBuild.DoGEOSSequentialFile(const AIniFile: TIniFile);
    var
    s: string;
    m: TMemoryStream;
    sz: Int64;
    datt: TD64TrackNum;
    dats: TD64SectorNum;
    datb: Word;

    begin
    s:= AIniFile.ReadString('sequential', 'Data', '');
    if  not FileExists(s) then
        raise Exception.Create(
                'Error: Data file for Sequential file structure must exist.');

    m:= TMemoryStream.Create;
    try
        m.LoadFromFile(s);

//dengland If the file is a .prg file, then we assume it has the two byte load
//      address at the beginning.
        if  CompareText(ExtractFileExt(s), '.PRG') = 0 then
            m.Position:= 2
        else
            m.Position:= 0;

        sz:= m.Size - m.Position;

        FDiskImage.AllocateDiskSectors(m, datt, dats, datb);

        Trace(etInfo, 'Allocated file data fork of size: ' + IntToStr(sz) +
                ' (' + IntToStr(datb) + ' blocks)');

        FDirEntry.SetDataTS(datt, dats);
        FDirEntry.SetFileSize(datb);

        finally
        m.Free;
        end;
    end;

procedure TGEOSBuild.DoGEOSVLIRFile(const AIniFile: TIniFile);
    var
    i: Integer;
    m,
    f: TMemoryStream;
    d: PByte;
    rect,
    datt: TD64TrackNum;
    recs,
    dats: TD64SectorNum;
    recb,
    datb: Word;
    s: string;
    sz: Int64;

    begin
    m:= TMemoryStream.Create;
    f:= TMemoryStream.Create;
    try
        m.SetSize(VAL_SIZ_D64SECTRSIZE - 2);
        m.Position:= 0;
        d:= PByte(m.Memory);

        for i:= 0 to 126 do
            begin
            s:= AIniFile.ReadString('VLIR', IntToStr(i), LIT_TOK_GEOSVLIREMY);

            if  CompareText(s, LIT_TOK_GEOSVLIREMY) = 0 then
                begin
                d^:= $00;
                Inc(d);
                d^:= $FF;
                Inc(d);
                end
            else if CompareText(s, LIT_TOK_GEOSVLIREND) = 0 then
                begin
                d^:= $00;
                Inc(d);
                d^:= $00;
                Inc(d);
                end
            else
                begin
                if  not FileExists(s) then
                    raise EGEOSBuildError.Create('Error: VLIR Record #' +
                            IntToStr(i)+ ' File Name does not exist.');

                f.LoadFromFile(s);
//dengland      If the file is a .prg file, then we assume it has the two byte
//              load address at the beginning.
                if  CompareText(ExtractFileExt(s), '.PRG') = 0 then
                    f.Position:= 2
                else
                    f.Position:= 0;

                sz:= f.Size - f.Position;

                FDiskImage.AllocateDiskSectors(f, rect, recs, recb);

                Trace(etInfo, 'Allocated file VLIR record fork of size: ' +
                        IntToStr(sz) + ' (' + IntToStr(recb) + ' blocks)');

                d^:= rect;
                Inc(d);
                d^:= recs;
                Inc(d);
                end;
            end;

        FDiskImage.AllocateDiskSectors(m, datt, dats, datb);

        Trace(etInfo, 'Allocated file data fork of size: ' + IntToStr(m.Size) +
                ' (' + IntToStr(datb) + ' blocks)');

        FDirEntry.SetDataTS(datt, dats);
        FDirEntry.SetFileSize(datb);

        finally
        f.Free;
        m.Free;
        end;
    end;

procedure TGEOSBuild.DoRun;
    var
    ErrorMsg: string;
    p: string;
    i: Integer;
    o: Boolean;

    begin
    DoWriteBanner(True);

//  quick check parameters
//dengland This doesn't check if the short and long versions have been specified
//  at the same time, which I think it should.  We will still get an error but
//  its unintelligent.
    ErrorMsg:= CheckOptions('hsv', ['help', 'silent', 'verbose']);
    if  ErrorMsg <> EmptyStr then
        begin
//dengland This is probably a little extreme
//      ShowException(Exception.Create(ErrorMsg));
        Trace(etError, 'Error: ' + ErrorMsg);
        ExitCode:= -2;
        Terminate;
        Exit;
        end;

//  parse parameters
    if  HasOption('h', 'help') then
        begin
        WriteHelp;
        ExitCode:= -1;
        Terminate;
        Exit;
        end;

//dengland Lets try to make sure only the short or long versions of the params
//  are specified.
    if  ((FindOptionIndex('s', o) > -1)
    and  (FindOptionIndex('silent', o) > -1))
    or  ((FindOptionIndex('v', o) > -1)
    and  (FindOptionIndex('verbose', o) > -1)) then
        begin
        Trace(etError, 'Error: Only the short or long option versions should '+
                'be specified.');
        ExitCode:= -2;
        Terminate;
        Exit;
        end;

    i:= 0;
    EventLogFilter:= [etDebug];

    if  HasOption('s', 'silent') then
        begin
        EventLogFilter:= EventLogFilter + [etInfo];
        Inc(i);
        end;

    if  HasOption('v', 'verbose') then
        begin
        EventLogFilter:= [];
        Inc(i);
        end;

     try
        if  ParamCount = i then
            raise EGEOSBuildError.Create(
                    'Error:  A build file must be specified.');

        if  not FileExists(Params[i + 1]) then
            raise EGEOSBuildError.Create('Error:  Build file does not exist.');

        p:= ExtractFilePath(Params[i + 1]);
        if  Length(p) > 0  then
            begin
            Trace(etInfo, 'Setting path to: ' + p);
            SetCurrentDir(p);
            end;

//dengland Must use ExtractFileName because we've changed the path if necessary.
        DoProcessBuildFile(ExtractFileName(Params[i + 1]));

        Trace(etCustom, 'Done.');

        except
        on E: EGEOSBuildError do
            begin
            Trace(etError, e.Message);
            ExitCode:= -3;
            end;

        on E: Exception do
//dengland  This won't go to ErrOutput which I'm unhappy about.
            begin
            ShowException(e);
            ExitCode:= -4;
            end;
        end;

//  stop program loop
    Terminate;
    end;

procedure TGEOSBuild.DoProcessBuildFile(const AFileName: string);
    var
    f: TIniFile;
    s,
    e: string;
    b: Byte;
    info: Integer;
    inft: TD64TrackNum;
    infs: TD64SectorNum;
    infb: Word;

    procedure DoOpenDiskImage;
        var
        d: TD64DiskType;

        begin
        s:= f.ReadString('build', 'Disk', '');
        if  Length(s) = 0 then
            raise EGEOSBuildError.Create(
                    'Error: Disk Image FileName must be specified.');

        FDiskImage:= TD64Image.Create;

        if  FileExists(s) then
            begin
            Trace(etInfo, 'Opening existing disk image: ' + s);
            FDiskImage.LoadFromFile(s);
            end
        else
            begin
            Trace(etInfo, 'Creating new disk image: ' + s);

            e:= ExtractFileExt(s);

            if  CompareText(e, '.D64') = 0 then
                d:= ddt1541
            else if CompareText(e, '.D71') = 0 then
                d:= ddt1571
            else if CompareText(e, '.D81') = 0 then
                d:= ddt1581
            else
                raise EGEOSBuildError.Create(
                        'Error:  Unknown Disk Image format specified.');

            s:= ExtractFileName(s);
            s:= Copy(s, 1, Length(s) - Length(e));

            FDiskImage.FormatImage(s, '1a', d, True);

//dengland  For testing purposes - to check new disk images
//          FDiskImage.SaveToFile('test'+e);
            end;
        end;

    procedure DoOpenInfoHeader;
        begin
        s:= f.ReadString('build', 'Header', '');
        if  not FileExists(s) then
            raise EGEOSBuildError.Create(
                    'Error: Header/Info file does not exist or was not specified.');

        FHeaderFile:= TMemoryStream.Create;
        FHeaderFile.LoadFromFile(s);

//dengland We are supporting info/header blocks of 256 or 254 bytes in size.
//      The info block is actually only 254 bytes but there must be some
//      historical reason for geoLinker to require 256 bytes.  If the size is
//      256, then the first two bytes are ignored (they will be "replaced" with
//      the track and sector linkage information: $00, $FF).
        info:= 0;
        if  FHeaderFile.Size = 256 then
            info:= 2
        else if FHeaderFile.Size <> 254 then
            raise EGEOSBuildError.Create(
                    'Error: Header/Info size invalid.  Must be 256 or 254 bytes.');

        Trace(etInfo, 'Opened info/header file: ' + s);
        Trace(etInfo, 'Info/header file size: ' + IntToStr(FHeaderFile.Size));
        end;

    procedure DoGetFileName;
        var
        i: Integer;

        begin
        FFileName:= f.ReadString('build', 'File', '');
        if  Length(FFileName) = 0 then
//dengland  Try getting it from the header.  This is important for applications
//          on the C64 GEOS.  C64 GEOS won't execute a file if the "permanent
//          filename" (or class as I call it) is different from the directory
//          entry filename.
            begin
            FHeaderFile.Position:= info + $4B;
            s:= EmptyStr;
            for i:= 0 to 11 do
                begin
                b:= FHeaderFile.ReadByte;
                if  b in [$20..$7E] then
                    s:= s + string(AnsiChar(b))
                else
                    s:= s + ' ';
                end;

            FFileName:= TrimRight(s);
            end;

        if  Length(FFileName) = 0 then
            raise EGEOSBuildError.Create('Error: Output FileName must be specified.');

        Trace(etInfo, 'Using destination file name: ' + FFileName);
        end;

    procedure DoAllocateInfoHeader;
        begin
        FHeaderFile.Position:= info;
        FDiskImage.AllocateDiskSectors(FHeaderFile, inft, infs, infb);

        Trace(etInfo, 'Allocated info/header sector.');
        end;

    procedure DoInitFileEntry;
        var
        e: TD64DirEntries;
        i: Integer;

        begin
        FillChar(FDirEntry.EntryData[0], SizeOf(TD64EntryData), $00);

        FDirEntry.SetFileName(FFileName);
        FDirEntry.SetGEOSInfoTS(inft, infs);   //SetRelTS

        FHeaderFile.Position:= $42 + info;
        FDirEntry.SetFileType(FHeaderFile.ReadByte);
        FDirEntry.SetGEOSFileType(FHeaderFile.ReadByte);
        b:= FHeaderFile.ReadByte;
        FDirEntry.SetGEOSStructure(b);

//      Check for an existing file entry with the same name.  We don't want that.
        FDiskImage.GetFileEntries(e);
        for i:= 0 to High(e) do
            if  (e[i].FileType <> 0)
            and (CompareText(TrimRight(e[i].FileName), FFileName) = 0) then
                begin
                Trace(etInfo, 'Scratching existing file.');
                FDiskImage.ScratchFileEntry(e[i].Track, e[i].Sector,
                        e[i].EntryNum);
                Break;
                end;
        end;

    begin
    Trace(etInfo, 'Processing:  ' + AFileName);

    f:= TIniFile.Create(AFileName);
    try
        DoOpenDiskImage;

        DoOpenInfoHeader;

        DoGetFileName;

        DoAllocateInfoHeader;

        DoInitFileEntry;

        if  b = $00 then
            DoGEOSSequentialFile(f)
        else
            DoGEOSVLIRFile(f);

        FDirEntry.SetGEOSDateTime(Now);
        FDiskImage.AllocateFileEntry(FDirEntry.EntryData);

        Trace(etInfo, 'Allocated file entry.');

        FDiskImage.SaveToFile(f.ReadString('build', 'Disk', ''));

        Trace(etInfo, 'Wrote disk image.');

        finally
        f.Free;
        end;
    end;

procedure TGEOSBuild.Trace(const AType: TEventType; const AMessage: string);
    begin
    if  not (AType in EventLogFilter) then
        if  AType = etError then
            Writeln(ErrOutput, AMessage)
        else
            Writeln(AMessage);
    end;

constructor TGEOSBuild.Create(TheOwner: TComponent);
    begin
    inherited Create(TheOwner);
    StopOnException:= True;
    end;

destructor TGEOSBuild.Destroy;
    begin
    if  Assigned(FHeaderFile) then
        FreeAndNil(FHeaderFile);

    if  Assigned(FDiskImage) then
        FreeAndNil(FDiskImage);

    inherited Destroy;
    end;

procedure TGEOSBuild.WriteHelp;
    begin
    DoWriteBanner(False);

    Writeln('Usage: ', ExtractFileName(ExeName),
            ' [-h | --help] | [-s | --silent] <build file.gbuild>');
    Writeln(EmptyStr);
    Writeln(EmptyStr);
    Writeln('GEOS Build links together the various files required for a GEOS' +
            ' application');
    Writeln('or document into a D64/D71/D81 disk image in the correct format ' +
            'for a GEOS file.');
    Writeln(EmptyStr);
    Writeln('A build file containing the instructions for building the file is'+
            ' required.');
    Writeln(EmptyStr);
    Writeln('The build file must contain information about the header (or' +
            ' info. block) in');
    Writeln('order to build the file.  It must also contain other information,'+
            ' depending');
    Writeln('upon the file type detected in the header.');
    Writeln(EmptyStr);
    end;

var
    Application: TGEOSBuild;

begin
    Application:= TGEOSBuild.Create(nil);
    Application.Title:= 'GEOS Build';
    Application.Run;
    Application.Free;
end.

