val _ = PolyML.SaveState.loadState "../../../bin/hol.state";

val _ = load "regexpLib";

open Lib regexpMisc;

val justifyDefault = regexpLib.SML;

fun bool_to_C true = 1
  | bool_to_C false = 0;

fun arrayString intList =
 String.concat
   (("{"::spread "," (map Int.toString intList)) @ ["}"]);

fun array256String intList =
 let val spreadList = spreadln "," 31 31 (map Int.toString intList)
 in
   String.concat ("{":: spreadList @ ["}"])
 end

fun twoDarrayString intLists =
  let val arrays = map array256String intLists
  in String.concat
      (("{"::spread ",\n " arrays) @ ["};"])
  end;

fun Cfile name quote (_,finals,table) =
 let val nstates = List.length finals
     val finals = map bool_to_C finals
 in String.concat
 ["/*---------------------------------------------------------------------------\n",
  " * -- DFA ", name, " is the compiled form of regexp\n",
  " * --\n",
  " * --   ", quote, "\n",
  " *---------------------------------------------------------------------------*/\n",
  "\n",
  "int ACCEPTING_",name," [", Int.toString nstates,"] = ",arrayString finals, ";\n",
  "\n",
  "unsigned long DELTA_",name," [",Int.toString nstates,"] [256] = \n",
  twoDarrayString table,
  "\n\n",
  "int match_",name,"(unsigned char *s, int len) {\n",
  "  int state, i;\n",
  "\n",
  "  state = 0;\n",
  "\n",
  "  for (i = 0; i < len; i++) { \n",
  "    state = DELTA_",name,"[state] [s[i]];\n",
  "   }\n",
  "\n",
  "  return ACCEPTING_",name,"[state];\n",
  "}\n"
 ]
 end;

fun deconstruct {certificate, final, matchfn, start, table} =
 let fun toList V = List.map (curry Vector.sub V) (upto 0 (Vector.length V - 1))
 in (start, toList final, toList (Vector.map toList table))
 end;

(*---------------------------------------------------------------------------*)
(* Map to C and write to stdOut                                              *)
(*---------------------------------------------------------------------------*)

fun quote_to_C justify name q =
 let val regexp = Regexp_Type.fromString q
     val _ = stdErr_print "Parsed regexp, now constructing DFA (can take time) ... "
     val result = regexpLib.matcher justify regexp
     val _ = stdErr_print "done. Generating C file.\n"
     val (start,finals,table) = deconstruct result
     val Cstring = Cfile name q (start,finals,table)
 in
   stdOut_print Cstring
 ; regexpMisc.succeed()
 end

(*---------------------------------------------------------------------------*)
(* Parse, transform, write to C files.                                       *)
(*---------------------------------------------------------------------------*)

fun parse_args () =
 let fun printHelp() = stdErr_print
          ("Usage: regexp2c [-dfagen (HOL | SML)] <name> <quotation>\n")
 in case CommandLine.arguments()
     of ["-dfagen","SML",name,quote] => SOME (regexpLib.SML,name,quote)
      | ["-dfagen","HOL",name,quote] => SOME (regexpLib.HOL,name,quote)
      | [name,quote]               => SOME(justifyDefault, name,quote)
      | otherwise                  => (printHelp(); NONE)
 end

fun main () =
 let val _ = stdErr_print "regexp2c: \n"
 in case parse_args()
    of NONE => regexpMisc.fail()
     | SOME (justify,name,quote) => quote_to_C justify name quote
 end;

