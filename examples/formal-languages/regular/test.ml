(*---------------------------------------------------------------------------*)
(*    Tests                                                                  *)
(*---------------------------------------------------------------------------*)

load "regexpLib";
open regexpLib;

fun matcher q = #matchfn(regexpLib.matcher SML (Regexp_Type.fromQuote q));
fun dom q = Regexp_Match.domBrz (Regexp_Type.fromQuote q);

val test = matcher `foobar`;
 not (test "fo2b") 
 andalso (test "foobar")
 andalso not(test "foobar1");

val test = matcher `\d*`;
  test"" 
andalso test"1" 
andalso test"11434123412341234235456337467456745675256245"
andalso not(test "a")
andalso not(test "_[");

val test = matcher `\w{1,20}`;
  not(test "")
andalso test "a" 
andalso test "foobar"
andalso test "fo12_obar_567abcdef"
andalso test "fo12_obar_567abcdefg"
andalso not(test "fo12_obar_567abcdefgh");

val test = matcher `.*1`;
test"asdfasdfasd1" 
andalso not(test"")
andalso test"1";

val test = matcher `[0-9]`;
 not(test "")
 andalso test "1"
 andalso test "9"
 andalso test "0"
 andalso not (test "10");

val test = matcher `[0-9]*`;
 test ""
 andalso test "1"
 andalso test "9"
 andalso test "0"
 andalso test "10"
 andalso not(test " a")
 andalso test "1024563735355365673463";

val test = matcher `(.*1)(12)*`;
test "adfasd11212"
andalso not (test"");

val test = matcher `b*|b*(a|ab*a)b*`;
test ""
andalso test "bbbb"
andalso test "bbbbabb"
andalso not (test "apha")
andalso test "a"
andalso test "baa";

val test = matcher `b*ab*ab*`;
test"bbbaa" 
andalso test"aa"
andalso test"bababb";

val test = matcher `[]*|.|..|...`;
test""
andalso test"a"
andalso test"abb"
andalso test"123"
andalso not (test"1234");

val test = matcher `.|(ab)*|(ba)*`;
test""
andalso test"a"
andalso test"7"
andalso not (test"abba")
andalso not (test"abb")
andalso test"ababababab"
andalso not (test"babababab")
andalso test"bababababa";

(* Beware the juxtaposition of * and ) in the quotation for some SML lexers. *)
val test = matcher `~((.*aa.*)|(.*bb.*))`;
             (true  = test ("")) 
   andalso   (true  = test ("a"))
   andalso   (true  = test ("b"))
   andalso   (false = test ("aa")) 
   andalso   (true  = test ("ab")) 
   andalso   (true  = test ("ba")) 
   andalso   (false = test ("bb")) 
   andalso   (true  = test ("ababababababababababababababababababababababababababab"))
   andalso   (false = test ("abababababababababababbababababababababababababababab"));

val test = matcher `(.*00.*)&~(.*01)`;
              (true  = test ("00"))
    andalso  (false = test ("001"))
    andalso  (true  = test ("0111010101010111111000000"))
    andalso  (true  = test ("011101010101011111100000010101000111111111111111111111"))
    andalso  (true  = test ("0011010101010111111000000101010001111111111111111111110"))
    andalso  (false = test ("0011010101010111111000000101010001111111111111111111101"))
   ;

(*---------------------------------------------------------------------------*)
(* All strings with at least three consecutive ones and not ending in 01 or  *)
(*   consisting of all ones.                                                 *)
(*---------------------------------------------------------------------------*)

val test = matcher `(.*111.*)&~((.*01)|1*)`;
             (true = test ("01110"))
    andalso  (false = test ("1"))
    andalso (false = test ("11"))
    andalso (false = test ("111"))
    andalso (false = test ("1111111111111111111111111111111111"))
    andalso (false = test ("11111111111111111111111111111111111111111111111111111111"))
    andalso (false = test ("1111111111111111111111111111111111111111111111111111111111111111"))
    andalso (true = test ("0111010101010111111000000"))
    andalso (true = test ("01101010101011111100000010101000111111111111111111111"))
    andalso (true = test ("10001101010101011000000101010001111111111111111111110"))
    andalso (false = test ("0011010101010111111000000101010001111111111111111111101"))
   ;

(*---------------------------------------------------------------------------*)
(* Testing number specs of chars in charsets. Example from David Hardin      *)
(*---------------------------------------------------------------------------*)

val test = matcher `[\010\016-\235]*`;

val ilist = [0x59, 0x55, 0x56, 0x34, 0x4d, 0x50, 0x45, 0x47, 0x32,
 0x20, 0x57, 0x31, 0x39, 0x32, 0x30, 0x20, 0x48, 0x31, 0x30, 0x38,
 0x30, 0x20, 0x46, 0x35, 0x30, 0x3a, 0x31, 0x20, 0x49, 0x70, 0x20,
 0x41, 0x31, 0x3a, 0x31, 0x0a, 0x46, 0x52, 0x41, 0x4d, 0x45, 0x0a,
 0x22, 0x23, 0x22, 0x23, 0x22, 0x21, 0x20, 0x1e, 0x20, 0x1e, 0x1c,
 0x1e, 0x20, 0x1f, 0x23, 0x23, 0x25, 0x22, 0x21, 0x25, 0x20, 0x20,
 0x22, 0x22, 0x23, 0x1f, 0x21, 0x22, 0x21, 0x27, 0x28, 0x27, 0x29,
 0x2d, 0x34, 0x30, 0x35, 0x33, 0x35, 0x51, 0x87, 0xb9, 0xbc, 0xbf,
 0xbb, 0x9c, 0x87, 0x84, 0x7d, 0x79, 0x7f, 0x8d, 0x94, 0xa4, 0xae,
 0xb0, 0xb3, 0xb3, 0xb2, 0xb1, 0xad, 0xb4, 0xab, 0xb5, 0xb4, 0xaa,
 0xb3, 0xb1, 0xa7, 0xac, 0xb5, 0xb6, 0xb3, 0xa8, 0xac, 0xac, 0xb0,
 0xbe, 0xbc, 0xbb, 0xc9, 0xbe, 0xb3, 0xa3, 0x99, 0x91, 0x8e, 0x82,
 0x8c, 0x85, 0x82, 0x8b, 0x85, 0x87, 0x9c, 0x99, 0xa5, 0xb3, 0xb2,
 0xb4, 0xb9, 0xaf, 0xb7, 0xa8, 0xb0, 0xac, 0xaa, 0xab, 0xb5, 0xb9,
 0xc2, 0xbd, 0xbf, 0xb8, 0xb1, 0xb9, 0xb0, 0xb3, 0xba, 0xbf, 0xc3,
 0xc8, 0xc5, 0xc7, 0xc9, 0xcd, 0xc8, 0xd0, 0xc8, 0xc5, 0xc9, 0xc3,
 0xc8, 0xca, 0xc2, 0xc8, 0xca, 0xcc, 0xcd, 0xc4, 0xc4, 0xc1, 0xb9,
 0xb5, 0xb9, 0xb5, 0xb4, 0xb6, 0xb3, 0xb8, 0xbb, 0xaf, 0xb4, 0xae,
 0xae, 0xb1, 0xb0, 0xae, 0xa8, 0xac, 0xa0, 0x99, 0x9c, 0x90, 0x99,
 0x9c, 0x9c, 0x9d, 0x90, 0x9d, 0x9a, 0x9f, 0x9e, 0x99, 0x96, 0x8f,
 0x95, 0x95, 0x8b, 0x8e, 0x88, 0x90, 0x92, 0x94, 0x95, 0x9a, 0x99,
 0x95, 0x8d, 0x91, 0x9a, 0x97, 0x95, 0xa1, 0xa6, 0x9f, 0xa2, 0xaa,
 0xa2, 0x9f, 0xa2, 0xac, 0xad, 0xa9, 0xa9, 0xab, 0xb1, 0xab, 0x9e,
 0x9f, 0x9d, 0x9d, 0x96, 0xa7, 0x9c, 0x9f, 0x9f, 0x90, 0x99, 0x95,
 0x9c, 0x9f, 0x9e, 0xa9, 0x9e, 0xa4, 0xa6, 0xa4, 0xa8, 0xa6, 0xac,
 0xb0, 0xae, 0xac, 0xb1, 0xb3, 0xbc, 0xb8, 0xb9, 0xbb, 0xb9, 0xb6,
 0xbc, 0xc2, 0xc4, 0xc3, 0xcc, 0xcd, 0xcd, 0xd2, 0xd3, 0xc9, 0xc6,
 0xd1, 0xd3, 0xd1, 0xd4, 0xca, 0xc8, 0xc5, 0xbb, 0xbc, 0xba, 0xc0,
 0xc2, 0xbd, 0xac, 0xa9, 0xb9, 0xb4, 0xac, 0xa5, 0xa7, 0x9d, 0xa3,
 0xa8, 0xa1, 0xa5, 0xa1, 0x9b, 0xa1, 0x9a, 0x9f, 0x8e, 0x95, 0xa3,
 0x93, 0xa1, 0xa6, 0x9c, 0xae, 0xaa, 0xa4, 0xa4, 0xab, 0xab, 0xa4,
 0xa2, 0xa7, 0xa5, 0x9e, 0xa8, 0xa2, 0xa9, 0xb4, 0xb1, 0xab, 0xa8,
 0xa6, 0xa5, 0xa6, 0xac, 0xaa, 0xb3, 0xbc, 0xb8, 0xb9, 0xb1, 0xbf,
 0xc4, 0xc5, 0xc7, 0xca, 0xcc, 0xd1, 0xd3, 0xcd, 0xca, 0xcd, 0xcc,
 0xca, 0xca, 0xc7, 0xcd, 0xd3, 0xcf, 0xd5, 0xdb, 0xd0, 0xd3, 0xd6,
 0xd2, 0xd3, 0xcb, 0xcb, 0xca, 0xc6, 0xbf, 0xbb, 0xc0, 0xbe, 0xba,
 0xb8, 0xb0, 0xb2, 0xb6, 0xb4, 0xb4, 0xb6, 0xbb, 0xb8, 0xb7, 0xba,
 0xc1, 0xba, 0xbc, 0xb0, 0xae, 0xb0, 0xb2, 0xb2, 0xb3, 0xba, 0xaa,
 0xa2, 0x92, 0x92, 0x91, 0x88, 0x80, 0x7b, 0x8e, 0x88, 0x86, 0x8c,
 0x8b, 0x92, 0x91, 0x8d, 0x89, 0x86, 0x84, 0x78, 0x77, 0x80, 0x75,
 0x76, 0x78, 0x72, 0x6e, 0x6b, 0x7c, 0x85, 0x8f, 0x86, 0x94, 0x9c,
 0xa4, 0xa4, 0xa8, 0xa8, 0xab, 0xad, 0xb7, 0xb4, 0xb1, 0xb7, 0xbb,
 0xbe, 0xba, 0xb9, 0xaf, 0xa6, 0x99, 0x96, 0x83, 0x81, 0x7b, 0x77,
 0x7a, 0x86, 0x88, 0x91, 0x9a, 0x9e, 0xa3, 0xa5, 0xb5, 0xb8, 0xb9,
 0xb9, 0xbc, 0xc5, 0xc3, 0xc6, 0xc9, 0xc8, 0xcd, 0xcf, 0xd1, 0xd1,
 0xd3, 0xd1, 0xd4, 0xce, 0xcf, 0xcf, 0xc9, 0xc5, 0xc7, 0xca, 0xc3,
 0xca, 0xce, 0xce, 0xd4, 0xcf, 0xca, 0xd1, 0xd5];

test (String.implode (map Char.chr ilist));

val date_matcher = time matcher 
   `(201\d|202[0-5])-([1-9]|1[0-2])-([1-9]|[1-2]\d|3[0-1]) (1?\d|2[0-3]):(\d|[1-5]\d):(\d|[1-5]\d)`;

  date_matcher "2016-5-21 20:23:24"
  andalso 
  date_matcher "2010-12-1 0:0:0"
  andalso 
  date_matcher "2019-1-22 11:11:11"
  andalso 
  date_matcher "2016-5-21 20:23:24"
  andalso 
  not (date_matcher "20162107-501-2100 20000:23000:")
  andalso 
  not (date_matcher "foo-bar-baz")
; 

(*---------------------------------------------------------------------------*)
(* Numeric intervals are introduced with \i{lo,hi}                           *)
(*---------------------------------------------------------------------------*)

fun unsigned_width_256 (n:IntInf.int) = 
 if n < 0 then raise ERR "unsigned_width_256" "negative number" else
 if n < 256 then 1
 else 1 + unsigned_width_256 (n div 256);

fun signed_width_256 (n:IntInf.int) = 
  let fun fus k acc = 
       let val lo = ~(IntInf.pow(2,k-1))
           val hi = IntInf.pow(2,k-1) - 1
       in if lo <= n andalso n <= hi
            then acc
            else fus (k+8) (acc+1)
       end
 in fus 8 1
 end;

(*---------------------------------------------------------------------------*)
(* bytes_of i w lays out i into w bytes                                      *)
(*---------------------------------------------------------------------------*)

fun byte_me i = Word8.fromInt (IntInf.toInt i);
fun inf_byte w = IntInf.fromInt(Word8.toInt w);

val bytes_of = 
 let val eight = Word.fromInt 8
     val mask = 0xFF:IntInf.int
     fun step i n =
      if n=1 then [byte_me i]
      else
        let val a = IntInf.andb(i,mask)
            val j = IntInf.~>>(i,eight)
       in byte_me a::step j (n-1)
       end
  in
   step
 end

fun lsb_signed i   = bytes_of i (signed_width_256 i);
fun msb_signed i   = rev (lsb_signed i);
fun lsb_unsigned i = bytes_of i (unsigned_width_256 i);
fun msb_unsigned i = rev (lsb_unsigned i);

fun lsb_num_of wlist : IntInf.int = 
 let fun value [] = 0
      | value (h::t) = h + 256 * value t
 in value (map inf_byte wlist)
 end;

fun lsb_int_of wlist = 
 let fun value [] = 0
       | value (h::t) = h + 256 * value t
     val (A,a) = Lib.front_last wlist
     val wlist' = map inf_byte A @ [IntInf.fromInt(Word8.toIntX a)]
 in value wlist'
 end;

fun msb_num_of wlist = lsb_num_of (rev wlist);
fun msb_int_of wlist = lsb_int_of (rev wlist);

val byte2char = Char.chr o Word8.toInt;
val char2byte = Word8.fromInt o Char.ord;

val string2num = lsb_num_of o map char2byte o String.explode;
val string2int = lsb_int_of o map char2byte o String.explode;

(*---------------------------------------------------------------------------*)
(* Puts int out in LSB                                                       *)
(*---------------------------------------------------------------------------*)

fun int2string w n =
 let val blist = bytes_of (IntInf.fromInt n) w
 in String.implode (map byte2char blist)
 end;

fun int2string_msb w n =
 let val blist = bytes_of (IntInf.fromInt n) w
 in String.implode (map byte2char (rev blist))
 end;

(*---------------------------------------------------------------------------*)
(* Test ranges over natural numbers                                          *)
(*---------------------------------------------------------------------------*)

val test = matcher `\i{0,17999}`;
val nlist = map (int2string 2) (upto 0 17999);
Lib.all (equal true) (map test nlist);
Lib.all (equal false) (map (test o int2string 2) (upto 18000 21212));

val test = matcher `\i{1,17999}`;
val nlist = map (int2string 2) (upto 1 17999);
Lib.all (equal true) (map test nlist);
Lib.all (equal false) (map (test o int2string 2) [~1,0,18000]);

val test = matcher `\i{0,2500000}`;
Lib.all (equal true) (map (test o int2string 3) (upto 0 2500000));
Lib.all (equal false) (map (test o int2string 3) (upto 2500001 2502999));

val test = matcher `\i{17999,2500000}`;
val nlist = map (int2string 3) (upto 17999 2500000);
Lib.all (equal true) (map test nlist);
Lib.all (equal false) (map (test o int2string 3) (upto 0 17998));
Lib.all (equal false) (map (test o int2string 3) (upto 2500001 2502999));

(*---------------------------------------------------------------------------*)
(* Test ranges over integers                                                 *)
(*---------------------------------------------------------------------------*)

val test = matcher `\i{~4,0}`;
signed_width_256 ~4 = 1;
Lib.all (equal true) (map (test o int2string 1) (upto ~4 0));
Lib.all (equal false) (map (test o int2string 1) [~5, ~6, ~64, 1, 2, 3, 4]);

val test = matcher `\i{~90,0}`;
signed_width_256 ~90 = 1;
Lib.all (equal true) (map (test o int2string 1) (upto ~90 0));
Lib.all (equal false) (map (test o int2string 1) (upto ~128 ~91));
Lib.all (equal false) (map (test o int2string 1) (upto 1 127));

val test = matcher `\i{~90,90}`;
signed_width_256 ~90 = 1;
Lib.all (equal true) (map (test o int2string 1) (upto ~90 90));
Lib.all (equal false) (map (test o int2string 1) (upto ~128 ~91));
Lib.all (equal false) (map (test o int2string 1) (upto 91 127));

val test = matcher `\i{~180,0}`;
signed_width_256 ~180 = 2;
Lib.all (equal true) (map (test o int2string 2) (upto ~180 0));
Lib.all (equal false) (map (test o int2string 2) (upto ~32768 ~181));
Lib.all (equal false) (map (test o int2string 2) (upto 181 1027));

val test = matcher `\i{~180,180}`;
signed_width_256 ~180 = 2;
Lib.all (equal true) (map (test o int2string 2) (upto ~180 180));
Lib.all (equal false) (map (test o int2string 2) [~181,181,192,18000,~1888]);

val test = matcher `\i{~2500000,2500000}`;
signed_width_256 ~2500000 = 3;
Lib.all (equal true) (map (test o int2string 3) (upto ~2500000 2500000));
Lib.all (equal false) (map (test o int2string 3) 
                      [~2500001,~2500001, 2500001,2500002,2599999]);

val test = matcher `\i{~3,300}`;
signed_width_256 300 = 2;
Lib.all (equal true) (map (test o int2string 2) (upto ~3 300));
Lib.all (equal false) (map (test o int2string 2) (upto ~300 ~4));
Lib.all (equal false) (map (test o int2string 2) (upto 301 16534));

val test = matcher `\i{~3,800}`;
signed_width_256 800 = 2;
Lib.all (equal true) (map (test o int2string 2) (upto ~3 800));
Lib.all (equal false) (map (test o int2string 2) (upto ~12000 ~4));
Lib.all (equal false) (map (test o int2string 2) (upto 801 16534));

val test = matcher `\i{~17999,0}`;
signed_width_256 ~17999 = 2;
Lib.all (equal true) (map (test o int2string 2) (upto ~17999 0));
Lib.all (equal false) (map (test o int2string 2) (upto ~34000 ~18000));
Lib.all (equal false) (map (test o int2string 2) (upto 1 18000));

val test = matcher `\i{~17999,~123}`;
signed_width_256 ~17999 = 2;
Lib.all (equal true) (map (test o int2string 2) (upto ~17999 ~123));
Lib.all (equal false) (map (test o int2string 2) (upto ~34000 ~18000));
Lib.all (equal false) (map (test o int2string 2) (upto ~122 ~1));
Lib.all (equal false) (map (test o int2string 2) (upto ~122 1000));

val test = matcher `\i{~116535,~23}`;
signed_width_256 ~116535 = 3;
Lib.all (equal true) (map (test o int2string 3) (upto ~116535 ~23));
Lib.all (equal false) (map (test o int2string 3) (upto ~119999 ~116536));
Lib.all (equal false) (map (test o int2string 3) (upto ~122 ~1));
Lib.all (equal false) (map (test o int2string 3) (upto ~122 1000));

(*---------------------------------------------------------------------------*)
(* Test numeric constants                                                    *)
(*---------------------------------------------------------------------------*)

val test = matcher `\k{23}`;
true = test (int2string 1 23);
equal false (test (int2string 1 22));
Lib.all (equal false) (map (test o int2string 1) (upto 0 22));
Lib.all (equal false) (map (test o int2string 1) (upto 24 255));


val test = matcher `\k{~23}`;
test (int2string 1 ~23);
false = test (int2string 1 ~22);
Lib.all (equal false) (map (test o int2string 1) (upto ~22 0));
Lib.all (equal false) (map (test o int2string 1) (upto 1 127));
Lib.all (equal false) (map (test o int2string 1) (upto ~128 ~24));

val test = matcher `\k{~128}`;
signed_width_256 ~128;
test (int2string 1 ~128);
equal false (test (int2string 1 ~22));
equal false (test (int2string 1 22));;
Lib.all (equal false) (map (test o int2string 1) (upto ~22 127));
Lib.all (equal false) (map (test o int2string 1) (upto ~127 ~24));

val test = matcher `\k{116535}`;
3 = signed_width_256 116535;
equal true (test (int2string 3 116535));
equal false (test (int2string 3 ~22));
equal false (test (int2string 3 22));;
Lib.all (equal false) (map (test o int2string 3) (upto ~22 116535));
Lib.all (equal false) (map (test o int2string 3) (upto ~127 ~24));

val test = matcher `\k{~116535}`;
signed_width_256 ~116535;
equal true (test (int2string 3 ~116535));
equal false (test (int2string 3 ~22));
equal false (test (int2string 3 22));;
equal false (test (int2string 3 ~116536));
equal false (test (int2string 3 ~116537));
equal false (test (int2string 3 ~116538));
Lib.all (equal false) (map (test o int2string 3) (upto ~22 127));
Lib.all (equal false) (map (test o int2string 3) (upto ~127 ~24));

val test = matcher `\k{~116535,MSB}`;
3 = signed_width_256 ~116535;
equal true (test (int2string_msb 3 ~116535));
equal false (test (int2string_msb 3 ~22));
equal false (test (int2string_msb 3 22));;
equal false (test (int2string_msb 3 ~116536));
equal false (test (int2string 3 ~116537));
equal false (test (int2string 3 ~116538));
Lib.all (equal false) (map (test o int2string 3) (upto ~22 127));
Lib.all (equal false) (map (test o int2string 3) (upto ~127 ~24));

(*---------------------------------------------------------------------------*)
(* CANBUS GPS message format. Taken from                                     *)
(*                                                                           *)
(* http://www.caemax.de/Downloads/QIC/QIC_GPS_DE.pdf                         *)
(*                                                                           *)
(* NB: The regexp we have written here to recognize the contents of message  *)
(* 1801 is wrong, since it needs data packing to handle bytes 4 and 5        *)
(* properly.                                                                 *)
(*---------------------------------------------------------------------------*)

(*
 * CAN ID Name Position (Format) Range of Values Units (Result)
 * Identifier 1800 
 * Time Day Byte 0 (unsigned char) 1 ... 31 
 * Time Month Byte 1 (unsigned char) 1 ... 12 
 * Time Year Byte 2 (unsigned char) 0 ... 99 
 * Time Hour Byte 3 (unsigned char) 0 … 23 
 * Time Minute Byte 4 (unsigned char) 0 … 59 
 * Time Second Byte 5 (unsigned char) 0 … 59 
 * Altitude Byte 6, 7 (LSB, MSB) 0 … 17999 "m" (1 m)
 *
 * Identifier 1801 
 * Latitude Degrees Byte 0 (Bit 0 ...7) -90 ... +90 "Deg" (1°)
 * Latitude Minutes Byte 1 (Bit 8 ... 13) 0 ... 59 "Min" (1’)
 * Latitude Seconds Byte 2, 3 (Bit 16 ... 28) 0 ... 5999 "Sec" (0.01“)
 * Longitude Degrees Byte 4 (Bit 32 ... 40) -180 ... +180 "Deg" (1°)
 * Longitude Minutes Byte 5 (Bit 41 ... 46) 0 ... 59 "Min" (1’)
 * Longitude Seconds Byte 6, 7 (Bit 48 ... 60) 0 ... 5999 "Sec" (0.01“)
 * 
 * Identifier 1802 
 * Speed Byte 0, 1 (LSB, MSB) 0 ... 9999 "km/h" (0.1 km/h)
 * Heading Byte 2, 3 (LSB, MSB) 0 ... 3599 "Deg" (0.1°)
 * 
 * Identifier 1803 
 * Number of Active Satellites Byte 0 (Bit 0 ... 3) 0 ... 12 
 *                             Byte 0 (Bit 4 ... 7) 0 
 * Number of Visible Satellites Byte 1 (unsigned char) 0 ... 16 
 * PDOP (vertical accuracy) Byte 2, 3 (LSB, MSB) 0 ... 999 "m" (0.1 m)
 * HDOP (horizontal accuracy) Byte 4, 5 (LSB,MSB) 0 ... 999 "m" (0.1 m)
 * VDOP (positional accuracy) Byte 6, 7 (LSB, MSB) 0 ... 999 "m" (0.1 m)
 *)
 
val match_1800        = matcher `\i{1,31}\i{1,12}\i{0,99}\i{0,23}\i{0,59}\i{0,59}\i{0,17999,LSB}`;
val match_1801        = matcher `\i{~90,90}\i{0,59}\i{0,5999}\i{~180,180}\i{0,59}\i{0,5999}`;
val match_1801_packed = matcher `\i{~90,90}\i{0,59}\i{0,5999}\p{(~180,180),(0,59)}\i{0,5999}`;
val match_1802        = matcher `\i{0,9999,LSB}\i{0,3599,LSB}`;
val match_1803        = matcher `\i{0,12}\i{0,16}\i{0,999,LSB}\i{0,999,LSB}\i{0,999,LSB}`;

fun prod [] l2 = []
  | prod (h::t) l2 = map (strcat h) l2 @ prod t l2;

fun PROD [] = []
  | PROD [list] = list
  | PROD (h::t) = prod h (PROD t);

(*---------------------------------------------------------------------------*)
(* 58 trillion strings to match exhaustively. Slightly unfeasible as written. *)
(* Could be done one-at-a-time, I suppose.                                   *)
(*---------------------------------------------------------------------------*)
(*
Lib.all (equal true)
 (map match_1800 
   (PROD 
     [map (int2string 1) (upto 1 31),
      map (int2string 1) (upto 1 12),
      map (int2string 1) (upto 0 99),
      map (int2string 1) (upto 0 23),
      map (int2string 1) (upto 0 59),
      map (int2string 1) (upto 0 59),
      map (int2string 2) (upto 0 17999)]));
*)

Lib.all (equal true)
 (map match_1800 
   (PROD 
     [map (int2string 1) (upto 1 10),
      map (int2string 1) (upto 1 10),
      map (int2string 1) (upto 0 9),
      map (int2string 1) (upto 0 9),
      map (int2string 1) (upto 0 9),
      map (int2string 1) (upto 0 9),
      map (int2string 2) (upto 0 9)]));

val match_18xx_disjunctive = matcher 
 `\i{1,31}\i{1,12}\i{0,99}\i{0,23}\i{0,59}\i{0,59}\i{0,17999,LSB}|\i{~90,90}\i{0,59}\i{0,5999}\i{~180,180}\i{0,59}\i{0,5999}|\i{0,9999,LSB}\i{0,3599,LSB}|\i{0,12}\i{0,16}\i{0,999,LSB}\i{0,999,LSB}\i{0,999,LSB}`;

val match_18xx_concat = matcher 
 `\i{1,31}\i{1,12}\i{0,99}\i{0,23}\i{0,59}\i{0,59}\i{0,17999,LSB}\i{~90,90}\i{0,59}\i{0,5999}\i{~180,180}\i{0,59}\i{0,5999}\i{0,9999,LSB}\i{0,3599,LSB}\i{0,12}\i{0,16}\i{0,999,LSB}\i{0,999,LSB}\i{0,999,LSB}`;

fun unsigned_width_bits (n:IntInf.int) = 
 if n < 0 then raise ERR "unsigned_width_bits" "negative number" else
 if n < 2 then 1
 else 1 + unsigned_width_bits (n div 2);

fun signed_width_bits (n:IntInf.int) = 
  let fun fus bits = 
       let val N = IntInf.pow(2,bits-1)
       in if ~N <= n andalso n <= N-1 then bits else fus (bits+1)
       end
 in fus 0
 end;

fun find_width (lo,hi) = 
 if lo > hi 
  then raise ERR "find_width" "malformed interval (lo > hi)"
 else
 if lo < 0 andalso hi < 0 
    then signed_width_bits lo else
 if lo < 0 andalso hi >= 0 
    then Int.max(signed_width_bits lo, signed_width_bits hi)
 else  (* lo and hi both non-negative *)
   unsigned_width_bits hi;

map find_width [(0,63),(~32,31),(35,60),(~12,27)];

val allones = IntInf.notb(IntInf.fromInt 0);

(*---------------------------------------------------------------------------*)
(* Clear top (all but rightmost width) bits in w                             *)
(*---------------------------------------------------------------------------*)

fun clear_top_bits width w = 
 let open IntInf
     val mask = notb(<<(allones,Word.fromInt(width)))
 in andb(w,mask)
 end

fun clear_bot_bits width w = 
 let open IntInf
 in ~>>(w,Word.fromInt width)
 end

fun sign_extend w width = 
 let open IntInf
 in if ~>>(w,Word.fromInt (width - 1)) = 1
  then (* signed *)
     orb(w,IntInf.<<(allones,Word.fromInt width))
  else w
 end

fun icat w shift i = 
 let val shiftw = Word.fromInt shift
     val shifted = IntInf.<<(w,shiftw)
     val x = clear_top_bits shift (IntInf.fromInt i)
 in 
   IntInf.orb(shifted,x)
 end

val test = icat (icat (icat 63 6 31) 6 45) 6 ~1;

matcher `\p{(~180,180),(0,59)}`;

matcher `\p{(0,63),(~32,31),(35,60),(~12,27)}`;

matcher `\p{(0,1),(0,2),(0,3),(~1,1)}`

map find_width [(0,1),(0,2),(0,3),(~1,1)];

matcher `\p{(0,7),(0,1),(0,15)}`
matcher `\p{(1,5),(0,1),(0,15)}`
matcher `\p{(1,5),(0,1),(0,15)}\i{0,999}`;

(*---------------------------------------------------------------------------*)
(* Hard cases for Brzozowski? These seem to take exponential time.           *)
(*---------------------------------------------------------------------------*)
(*
time matcher `\w{1,20}`; 
time matcher `\w{1,50}`; 
time matcher `\w{1,75}`; 
time matcher `\w{1,100}`;
time matcher `\w{1,200}`;

set_trace "regexp-compiler" 0;;

dom `\w{20}`;
dom `\w{50}`;
dom `\w{75}`;
dom `\w{100}`;
dom `\w{200}`;

dom `\w{1,20}`;       (* 256: 0.02s ; 0.12s ; 128: 0.052s *)
time dom `\w{1,50}`;  (* 256: 0.16s ; 1.8s  ; 128: 0.73600s *)
time dom `\w{1,75}`;  (* 256: 0.38s ; 6.2s  ; 128: 2.784s *)
time dom `\w{1,100}`; (* 256: 0.78s ; 13.6s ; 128: 6.912s *)
time dom `\w{1,200}`; (* 256: 4.5s  ; 123s  ; 128: 62 s *)
time dom `\w{1,300}`; (* 256: 13.1s *)
time dom `\w{1,400}`; (* 256: 29.9s *)
time dom `\w{1,500}`; (* 256: 57.4ss *)

(*---------------------------------------------------------------------------*)
(* packed intervals                                                          *)
(*---------------------------------------------------------------------------*)

dom `\p{(0,5),(0,3),(3,5)}`;
(* 0.002s. 1 byte needed *)

dom `\p{(0,5),(0,63),(0,127)}`;
(* 7.5s. 2 bytes needed. 1 interval *)
(* 8.5s. 2 bytes needed. 1 interval *)
(* 8.7s. 2 bytes needed. 442371 intervals  (smallest total size) *)
(* 0.52s. 2 bytes needed. 49152 elements; 3911 nodes in regexp *)

dom `\p{(0,127),(0,63),(0,5)}`;
(* 1.3s. 2 bytes. 8192 intervals *)
(* 0.17s. 2 bytes. 192 intervals *)
(* 0.29s. 2 bytes. 442944 intervals (smallest total size) *)
(* 0.384s. 2 bytes needed. 49152 elements; 4035 nodes in regexp *)

dom `\p{(~180,180),(0,59)}`;
(* 0.12s. 2 bytes needed. 361 intervals *)
(* 0.08s. 2 bytes needed. 120 intervals *)
(* 0.15s. 2 bytes needed. 195300 intervals (smallest total size) *)
(* 0.039s. 2 bytes needed. 21660 elements; 2403 nodes in regexp *)

dom `\p{(0,59),(~180,180)}`;
(* 3.4s. 2 bytes needed. 61 intervals *)
(* 4.9s. 2 bytes needed. 61 intervals *)
(* 3.5s. 2 bytes needed. 195,123 intervals (smallest total size) *)
(* 0.012s. 2 bytes needed. 21660 elements;  2449 nodes in regexp *)

dom `\p{(0,41),(0,127),(0,255)}`;
(* 12.2s. 3 bytes. 79464 intervals generated *)
(* 11.5s. 5376 intervals *)
(* 263s. 168 intervals *)
(* 228s. 16,515,576 intervals (smallest total size) *)
(* 7.4s. 1,376,256 elements; 161923 nodes in regexp *)

dom `\p{(0,41),(0,42),(0,43),(0,48)}`;
(* 56s. 3 bytes. 79464 intervals generated *)
(* 113s 3 bytes. 26,080,059 intervals generated *)
(* 38.9s. 3 bytes. 3,893,736 elements ;  2,216,899 nodes in regexp *)

dom `\p{(0,63),(0,42),(0,63),(0,63)}`;
(* 261s. 3 bytes, 11,272,192 elements in set, 33,993,813 nodes in regexp *)

dom `(201\d|202[0-5])-([1-9]|1[0-2])-([1-9]|[1-2]\d|3[0-1]) (1?\d|2[0-3]):(\d|[1-5]\d):(\d|[1-5]\d)`;
(* 0.25s; 24 states *)

dom `\[\{"time":"\d{13}(:\d{3})?","\w{1,20}":\{("\w{1,25}":"\w{1,30}",?)+\}\}\]`;
(* 119 states; 0.68s *)

dom `\i{~90,90}\i{0,59}\i{0,5999}\p{(~180,180),(0,59)}\i{0,5999}`;
(* 14 states ; 0.46s *)
(* 13 states ; 0.54s *)
(* 0.27s. 195,300 intervals *)
(* 0.17s. 21660 elements; 2403 nodes in regexp *)

*)
