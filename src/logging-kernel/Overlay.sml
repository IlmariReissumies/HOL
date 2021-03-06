(* ----------------------------------------------------------------------
    Provide standard infixes for rest of distribution

    These infix declarations affect the interactive system as well as
    the "compiled" environment, ensuring a degree of consistency
    between the two.
   ---------------------------------------------------------------------- *)

infix ++ && |-> THEN THEN1 THENL THEN_LT THENC ORELSE ORELSE_LT ORELSEC
  THEN_TCL ORELSE_TCL ?> |>
infixr ## $
infixr 3 -->;
infix 8 via by suffices_by

(* infixes for THEN shorthands *)
infix >> >- >| \\ >>>

structure Tag = Tag :> FinalTag where type tag = Tag.tag
structure Type = Type :> FinalType where type hol_type = Type.hol_type
structure Term = Term :> FinalTerm where type term = Term.term
                                         and type hol_type = Type.hol_type

structure Process = OS.Process
structure FileSys = OS.FileSys
structure Path    = OS.Path

structure PP = HOLPP

type 'a quotation = 'a PP.quotation
type ppstream = PP.ppstream
datatype frag = datatype PP.frag
