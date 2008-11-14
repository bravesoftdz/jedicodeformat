unit TestDelphi2009Generics;

{ AFS November 2008
 This unit compiles but is not semantically meaningfull
 it is test cases for the code formatting utility

 This code test Delphi 2009 Features  }

interface

uses Generics.Collections;

implementation

function TestList: integer;
var
  liList: TList<integer>;
begin
  liList := TList<integer>.Create();

  liList.Add(12);
  liList.Add(24);
  liList.Add(48);

  result := liList.Count;
end;

type
   TRecordList<T> = class(TEnumerable<T>)
   public
   type
      TEnumerator = class(TEnumerator<T>)
      end;
   end;

end.