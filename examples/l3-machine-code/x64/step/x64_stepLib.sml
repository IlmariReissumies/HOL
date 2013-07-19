(* ------------------------------------------------------------------------
   x64 step evaluator
   ------------------------------------------------------------------------ *)

structure x64_stepLib :> x64_stepLib =
struct

open HolKernel boolLib bossLib
open lcsymtacs utilsLib x64Lib x64Theory x64_stepTheory

structure Parse =
struct
   open Parse
   val (Type, Term) = parse_from_grammars x64Theory.x64_grammars
end

open Parse

val ERR = Feedback.mk_HOL_ERR "x64_evalLib"

val () = show_assums := true

(* ========================================================================= *)

(*
val print_thms =
   List.app
     (fn th => (Lib.with_flag (show_assums, false) print_thm th; print "\n\n"))
*)

val st = ``s: x64_state``
val regs = TypeBase.constructors_of ``:Zreg``
fun mapl x = utilsLib.augment x [[]]

local
   val state_fns = utilsLib.accessor_fns ``: x64_state``
   val other_fns =
      [pairSyntax.fst_tm, pairSyntax.snd_tm,
       wordsSyntax.w2w_tm, wordsSyntax.sw2sw_tm,
       ``(h >< l) : 'a word -> 'b word``,
       ``bit_field_insert h l : 'a word -> 'b word -> 'b word``] @
      utilsLib.update_fns ``: x64_state``
   val exc = ``SND (raise'exception e s : 'a # x64_state)``
in
   val cond_rand_thms = utilsLib.mk_cond_rand_thms (other_fns @ state_fns)
   val snd_exception_thms =
      utilsLib.map_conv
         (Drule.GEN_ALL o
          utilsLib.SRW_CONV [cond_rand_thms, x64Theory.raise'exception_def] o
          (fn tm => Term.mk_comb (tm, exc))) state_fns
end

(* x64 datatype theorems/conversions *)

local
   fun datatype_thms thms =
      thms @ [cond_rand_thms, snd_exception_thms] @
      utilsLib.datatype_rewrites "x64"
        ["x64_state", "Zreg", "Zeflags", "Zsize", "Zbase", "Zrm", "Zdest_src",
         "Zimm_rm", "Zmonop_name", "Zbinop_name", "Zcond", "Zea", "Zinst"]
in
   val DATATYPE_CONV = REWRITE_CONV (datatype_thms [])
   val COND_UPDATE_CONV =
      REWRITE_CONV (utilsLib.mk_cond_update_thms [``:x64_state``])
   val EV = utilsLib.STEP (datatype_thms, st)
   val resetEvConv = utilsLib.resetStepConv
   val setEvConv = utilsLib.setStepConv
end

local
   val state_with_pre = (st |-> ``^st with RIP := ^st.RIP + n2w len``)
   fun ADD_PRECOND_RULE thm =
      thm |> Thm.INST [state_with_pre]
          |> utilsLib.ALL_HYP_CONV_RULE DATATYPE_CONV
          |> Conv.CONV_RULE DATATYPE_CONV
   val rwts = ref ([]: thm list)
in
   fun getThms () = List.map ADD_PRECOND_RULE (!rwts)
   fun resetThms () = rwts := []
   fun addThms thms = (rwts := thms @ !rwts; thms)
end

(* ------------------------------------------------------------------------ *)

local
   fun mk_3 w = wordsSyntax.mk_wordii (w, 3)
   fun mk_ibyte w = wordsSyntax.mk_wordii (w, 8)
   val cmp = wordsLib.words_compset ()
   val () = utilsLib.add_theory
              ([], utilsLib.filter_inventory ["readPrefix"] x64Theory.inventory)
              cmp
   val prefix_CONV =
      Conv.REWR_CONV x64Theory.readPrefix_def THENC computeLib.CBV_CONV cmp
   val prefix_rwt =
      utilsLib.map_conv prefix_CONV
         (List.tabulate (256, fn i => ``readPrefix (s, p, ^(mk_ibyte i)::l)``))
   val boolify8_CONV =
      Conv.RAND_CONV (Conv.REWR_CONV boolify8_n2w THENC numLib.REDUCE_CONV)
      THENC PairedLambda.let_CONV
   val x64_decode_rwt =
      Conv.CONV_RULE (Conv.DEPTH_CONV boolify8_CONV THENC REWRITE_CONV [])
        x64_decode_def
   fun RexReg_rwt b =
      utilsLib.map_conv (REWRITE_CONV [RexReg_def]
                         THENC EVAL
                         THENC REWRITE_CONV [num2Zreg_thm])
         (List.tabulate (8, fn i => ``RexReg (^b, ^(mk_3 i))``))
in
   val x64_CONV =
      utilsLib.CHANGE_CBV_CONV
         (x64Lib.x64_compset
            [immediate8_rwt, immediate16_rwt, immediate32_rwt, immediate64_rwt,
             immediate_rwt, prefix_rwt, OpSize_rwt, x64_decode_rwt,
             RexReg_rwt boolSyntax.F, RexReg_rwt boolSyntax.T])
end

(* ------------------------------------------------------------------------ *)

(*
val ADDRESS_CONV =
   Conv.REWR_CONV (GSYM wordsTheory.WORD_ADD_ASSOC)
   THENC Conv.RAND_CONV
           (Conv.REWR_CONV wordsTheory.word_add_n2w
            THENC numLib.REDUCE_CONV)

local
   val lcancel =
      Thm.CONJ wordsTheory.WORD_EQ_ADD_LCANCEL
        (wordsTheory.WORD_EQ_ADD_LCANCEL
         |> Q.SPECL [`v`, `0w`]
         |> REWRITE_RULE [wordsTheory.WORD_ADD_0]
         |> Drule.GEN_ALL)
in
   val ADDR_CONV =
      DATATYPE_CONV THENC REWRITE_CONV [lcancel] THENC utilsLib.SRW_CONV []
end
*)

val mem8_rwt =
   EV [mem8_def] [[``^st.MEM a = SOME v``]] []
      ``mem8 a``
      |> hd

val write'mem8_rwt =
   EV [write'mem8_def] [[``^st.MEM addr = SOME wv``]] []
      ``write'mem8 (d, addr)``
      |> hd

(* ------------------------------------------------------------------------ *)

val sizes = [``Z8 have_rex``, ``Z16``, ``Z32``, ``Z64``]

val Eflag_rwt =
   EV [Eflag_def] [[``^st.EFLAGS (flag) = SOME b``]] []
      ``Eflag (flag)``
   |> hd

val write'Eflag_rwt =
   EV [write'Eflag_def] [] []
      ``write'Eflag (b, flag)``
   |> hd

val FlagUnspecified_rwt =
   EV [FlagUnspecified_def] [] []
      ``FlagUnspecified (flag)``
   |> hd

val write_PF_rwt =
   EV [write_PF_def, write'PF_def, write'Eflag_rwt] [] []
      ``write_PF w``
   |> hd

val () = setEvConv (Conv.DEPTH_CONV (wordsLib.WORD_BIT_INDEX_CONV true))

val write_SF_rwt =
   EV [write_SF_def, write'SF_def, write'Eflag_rwt, word_size_msb_def,
       Zsize_width_def] []
      (mapl (`size`, sizes))
      ``write_SF (size, w)``

val () = resetEvConv ()

val write_ZF_rwt =
   EV [write_ZF_def, write'ZF_def, write'Eflag_rwt] [] (mapl (`size`, sizes))
      ``write_ZF (size, w)``

val erase_eflags =
   erase_eflags_def
   |> Thm.SPEC st
   |> REWRITE_RULE [ISPEC ``^st.EFLAGS`` eflags_none]

(* ------------------------------------------------------------------------ *)

val ea_Zrm_rwt =
   EV [ea_Zrm_def, ea_index_def, ea_base_def, wordsTheory.WORD_ADD_0] []
      [[`rm` |-> ``Zr r``],
       [`rm` |-> ``Zm (NONE, ZnoBase, d)``],
       [`rm` |-> ``Zm (NONE, ZripBase, d)``],
       [`rm` |-> ``Zm (NONE, ZregBase r, d)``],
       [`rm` |-> ``Zm (SOME (scale, inx), ZnoBase, d)``],
       [`rm` |-> ``Zm (SOME (scale, inx), ZripBase, d)``],
       [`rm` |-> ``Zm (SOME (scale, inx), ZregBase r, d)``]]
      ``ea_Zrm (size, rm)``

val ea_Zdest_rwt =
   EV (ea_Zdest_def :: ea_Zrm_rwt) []
      [[`ds` |-> ``Zrm_i (Zr r, x)``],
       [`ds` |-> ``Zrm_i (Zm (NONE, ZnoBase, d), x)``],
       [`ds` |-> ``Zrm_i (Zm (NONE, ZripBase, d), x)``],
       [`ds` |-> ``Zrm_i (Zm (NONE, ZregBase r, d), x)``],
       [`ds` |-> ``Zrm_i (Zm (SOME (scale, inx), ZnoBase, d), x)``],
       [`ds` |-> ``Zrm_i (Zm (SOME (scale, inx), ZripBase, d), x)``],
       [`ds` |-> ``Zrm_i (Zm (SOME (scale, inx), ZregBase r, d), x)``],
       [`ds` |-> ``Zrm_r (Zr r, x)``],
       [`ds` |-> ``Zrm_r (Zm (NONE, ZnoBase, d), x)``],
       [`ds` |-> ``Zrm_r (Zm (NONE, ZripBase, d), x)``],
       [`ds` |-> ``Zrm_r (Zm (NONE, ZregBase r, d), x)``],
       [`ds` |-> ``Zrm_r (Zm (SOME (scale, inx), ZnoBase, d), x)``],
       [`ds` |-> ``Zrm_r (Zm (SOME (scale, inx), ZripBase, d), x)``],
       [`ds` |-> ``Zrm_r (Zm (SOME (scale, inx), ZregBase r, d), x)``],
       [`ds` |-> ``Zr_rm (r, x)``]]
      ``ea_Zdest (size, ds)``

val ea_Zsrc_rwt =
   EV (ea_Zsrc_def :: ea_Zrm_rwt) []
      [[`ds` |-> ``Zrm_i (x, i)``],
       [`ds` |-> ``Zrm_r (x, r)``],
       [`ds` |-> ``Zr_rm (x, Zr r)``],
       [`ds` |-> ``Zr_rm (x, Zm (NONE, ZnoBase, d))``],
       [`ds` |-> ``Zr_rm (x, Zm (NONE, ZripBase, d))``],
       [`ds` |-> ``Zr_rm (x, Zm (NONE, ZregBase r, d))``],
       [`ds` |-> ``Zr_rm (x, Zm (SOME (scale, inx), ZnoBase, d))``],
       [`ds` |-> ``Zr_rm (x, Zm (SOME (scale, inx), ZripBase, d))``],
       [`ds` |-> ``Zr_rm (x, Zm (SOME (scale, inx), ZregBase r, d))``]]
      ``ea_Zsrc (size, ds)``

val ea_Zimm_rm_rwt =
   EV (ea_Zimm_rm_def :: ea_Zrm_rwt) []
      [[`irm` |-> ``Zimm (i)``],
       [`irm` |-> ``Zrm (Zr r)``],
       [`irm` |-> ``Zrm (Zm (NONE, ZnoBase, d))``],
       [`irm` |-> ``Zrm (Zm (NONE, ZripBase, d))``],
       [`irm` |-> ``Zrm (Zm (NONE, ZregBase r, d))``],
       [`irm` |-> ``Zrm (Zm (SOME (scale, inx), ZnoBase, d))``],
       [`irm` |-> ``Zrm (Zm (SOME (scale, inx), ZripBase, d))``],
       [`irm` |-> ``Zrm (Zm (SOME (scale, inx), ZregBase r, d))``]]
      ``ea_Zimm_rm (size, irm)``

(* ------------------------------------------------------------------------ *)

val no_imm_ea =
   [[`ea` |-> ``Zea_r (Z8 have_rex, r)``],
    [`ea` |-> ``Zea_r (Z16, r)``],
    [`ea` |-> ``Zea_r (Z32, r)``],
    [`ea` |-> ``Zea_r (Z64, r)``],
    [`ea` |-> ``Zea_m (Z8 have_rex, a)``],
    [`ea` |-> ``Zea_m (Z16, a)``],
    [`ea` |-> ``Zea_m (Z32, a)``],
    [`ea` |-> ``Zea_m (Z64, a)``]] : utilsLib.cover

val ea =
   [[`ea` |-> ``Zea_i (Z8 have_rex, i)``],
    [`ea` |-> ``Zea_i (Z16, i)``],
    [`ea` |-> ``Zea_i (Z32, i)``],
    [`ea` |-> ``Zea_i (Z64, i)``]] @ no_imm_ea

val () = resetThms()

val highByte =
   [utilsLib.map_conv x64_CONV
     (List.map (fn r => ``num2Zreg (Zreg2num ^r - 4)``)
               [``RSP``, ``RBP``, ``RSI``, ``RDI``])]
   |> addThms

val EA_rwt =
   EV [EA_def, restrictSize_def, id_state_cond, pred_setTheory.IN_INSERT,
       pred_setTheory.NOT_IN_EMPTY, mem8_rwt, mem16_rwt, mem32_rwt, mem64_rwt]
      [] ea
      ``EA ea``

val write'EA_rwt =
   EV [write'EA_def, bitfield_inserts, unit_state_cond,
       pred_setTheory.IN_INSERT, pred_setTheory.NOT_IN_EMPTY,
       write'mem8_rwt, write'mem16_rwt, write'mem32_rwt, write'mem64_rwt] []
      no_imm_ea
      ``write'EA (d, ea)``
   |> List.map (Conv.RIGHT_CONV_RULE
                  (utilsLib.EXTRACT_CONV THENC COND_UPDATE_CONV))

val write'EA_rwt_r = List.map (Q.INST [`wv` |-> `v`]) write'EA_rwt

(* ------------------------------------------------------------------------ *)

val write_logical_eflags_rwt =
   EV ([write_logical_eflags_def, FlagUnspecified_rwt,
        write_PF_rwt, write'CF_def, write'OF_def, write'Eflag_rwt] @
       write_SF_rwt @ write_ZF_rwt) [] (mapl (`size`, sizes))
      ``write_logical_eflags (size, w)``

val write_arith_eflags_except_CF_OF_rwt =
   EV ([write_arith_eflags_except_CF_OF_def, FlagUnspecified_rwt,
        write_PF_rwt] @ write_SF_rwt @ write_ZF_rwt) [] (mapl (`size`, sizes))
      ``write_arith_eflags_except_CF_OF (size, w)``

val write_arith_eflags_rwt =
   EV ([write_arith_eflags_def, write'CF_def, write'OF_def, write'Eflag_rwt] @
       write_arith_eflags_except_CF_OF_rwt) [] (mapl (`size`, sizes))
      ``write_arith_eflags (size, r, carry, overflow)``

val () = setEvConv (Conv.DEPTH_CONV (wordsLib.WORD_BIT_INDEX_CONV true))

val ea_op =
   [[`size1` |-> ``Z8 have_rex``,  `ea` |-> ``Zea_r (Z8 have_rex, r)``],
    [`size1` |-> ``Z16``, `ea` |-> ``Zea_r (Z16, r)``],
    [`size1` |-> ``Z32``, `ea` |-> ``Zea_r (Z32, r)``],
    [`size1` |-> ``Z64``, `ea` |-> ``Zea_r (Z64, r)``],
    [`size1` |-> ``Z8 have_rex``,  `ea` |-> ``Zea_m (Z8 have_rex, a)``],
    [`size1` |-> ``Z16``, `ea` |-> ``Zea_m (Z16, a)``],
    [`size1` |-> ``Z32``, `ea` |-> ``Zea_m (Z32, a)``],
    [`size1` |-> ``Z64``, `ea` |-> ``Zea_m (Z64, a)``]] : utilsLib.cover

val monops = TypeBase.constructors_of ``:Zmonop_name``
val binops = Lib.set_diff (TypeBase.constructors_of ``:Zbinop_name``)
                          [``Zrcl``, ``Zrcr``]

val write_binop_rwt =
   EV ([write_binop_def, write_arith_result_def, write_logical_result_def,
        write_arith_result_no_CF_OF_def, write_result_erase_eflags_def,
        write_arith_eflags_except_CF_OF_def,
        add_with_carry_out_def, sub_with_borrow_def,
        maskShift_def, ROL_def, ROR_def, SAR_def, value_width_def,
        Zsize_width_def, word_size_msb_def,
        word_signed_overflow_add_def, word_signed_overflow_sub_def,
        erase_eflags, write_PF_rwt, write'CF_def, write'OF_def,
        write'Eflag_rwt, CF_def, Eflag_rwt, FlagUnspecified_def] @
       write_arith_eflags_rwt @ write_logical_eflags_rwt @ write_SF_rwt @
       write_ZF_rwt @ write'EA_rwt) []
      (utilsLib.augment (`bop`, binops) ea_op)
      ``write_binop (size1, bop, x, y, ea)``
   |> List.map (utilsLib.ALL_HYP_CONV_RULE DATATYPE_CONV)
   |> addThms

val write_monop_rwt =
   EV ([write_monop_def,
        write_arith_result_no_CF_OF_def,
        write_arith_eflags_except_CF_OF_def,
        write_PF_rwt, write'CF_def, write'OF_def,
        write'Eflag_rwt, CF_def, Eflag_rwt, FlagUnspecified_def] @
       write_SF_rwt @ write_ZF_rwt @ write'EA_rwt) []
      (utilsLib.augment (`mop`, monops) ea_op)
      ``write_monop (size1, mop, x, ea)``
   |> List.map (utilsLib.ALL_HYP_CONV_RULE DATATYPE_CONV)
   |> addThms

(* ------------------------------------------------------------------------ *)

val () = resetEvConv ()

val conds = TypeBase.constructors_of ``:Zcond``

val read_cond_rwts =
   EV [read_cond_def, Eflag_def, CF_def, PF_def, AF_def, ZF_def, SF_def, OF_def,
       id_state_cond, cond_thms]
      [[``^st.EFLAGS (Z_CF) = SOME cflag``,
        ``^st.EFLAGS (Z_PF) = SOME pflag``,
        ``^st.EFLAGS (Z_AF) = SOME aflag``,
        ``^st.EFLAGS (Z_ZF) = SOME zflag``,
        ``^st.EFLAGS (Z_SF) = SOME sflag``,
        ``^st.EFLAGS (Z_OF) = SOME oflag``]]
      (mapl (`c`, conds))
      ``read_cond c``
   |> addThms

val SignExtension_rwt =
   EV [SignExtension_def] []
      [[`s1` |-> ``Z8 (b)``, `s2` |-> ``Z16``],
       [`s1` |-> ``Z8 (b)``, `s2` |-> ``Z32``],
       [`s1` |-> ``Z8 (b)``, `s2` |-> ``Z64``],
       [`s1` |-> ``Z16``, `s2` |-> ``Z32``],
       [`s1` |-> ``Z16``, `s2` |-> ``Z64``],
       [`s1` |-> ``Z32``, `s2` |-> ``Z64``]]
      ``SignExtension (w, s1, s2)``

(* ------------------------------------------------------------------------ *)

val rm =
   [[`rm` |-> ``Zr r``],
    [`rm` |-> ``Zm (NONE, ZnoBase, d)``],
    [`rm` |-> ``Zm (NONE, ZripBase, d)``],
    [`rm` |-> ``Zm (NONE, ZregBase r, d)``],
    [`rm` |-> ``Zm (SOME (scale, ix), ZnoBase, d)``],
    [`rm` |-> ``Zm (SOME (scale, ix), ZripBase, d)``],
    [`rm` |-> ``Zm (SOME (scale, ix), ZregBase r, d)``]]: utilsLib.cover

val r_rm =
   [[`ds` |-> ``Zr_rm (r1, Zr r2)``],
    [`ds` |-> ``Zr_rm (r, Zm (NONE, ZnoBase, d))``],
    [`ds` |-> ``Zr_rm (r, Zm (NONE, ZripBase, d))``],
    [`ds` |-> ``Zr_rm (r1, Zm (NONE, ZregBase r2, d))``],
    [`ds` |-> ``Zr_rm (r, Zm (SOME (scale, ix), ZnoBase, d))``],
    [`ds` |-> ``Zr_rm (r, Zm (SOME (scale, ix), ZripBase, d))``],
    [`ds` |-> ``Zr_rm (r1, Zm (SOME (scale, ix), ZregBase r2, d))``]]
    : utilsLib.cover

val src_dst = utilsLib.augment (`size`, sizes)
  ([[`ds` |-> ``Zrm_i (Zr r, i)``],
    [`ds` |-> ``Zrm_i (Zm (NONE, ZnoBase, d), i)``],
    [`ds` |-> ``Zrm_i (Zm (NONE, ZripBase, d), i)``],
    [`ds` |-> ``Zrm_i (Zm (NONE, ZregBase r, d), i)``],
    [`ds` |-> ``Zrm_i (Zm (SOME (scale, ix), ZnoBase, d), i)``],
    [`ds` |-> ``Zrm_i (Zm (SOME (scale, ix), ZripBase, d), i)``],
    [`ds` |-> ``Zrm_i (Zm (SOME (scale, ix), ZregBase r, d), i)``],
    [`ds` |-> ``Zrm_r (Zr r1, r2)``],
    [`ds` |-> ``Zrm_r (Zm (NONE, ZnoBase, d), r)``],
    [`ds` |-> ``Zrm_r (Zm (NONE, ZripBase, d), r)``],
    [`ds` |-> ``Zrm_r (Zm (NONE, ZregBase r1, d), r2)``],
    [`ds` |-> ``Zrm_r (Zm (SOME (scale, ix), ZnoBase, d), r)``],
    [`ds` |-> ``Zrm_r (Zm (SOME (scale, ix), ZripBase, d), r)``],
    [`ds` |-> ``Zrm_r (Zm (SOME (scale, ix), ZregBase r1, d), r2)``]] @ r_rm)
    : utilsLib.cover

val lea = utilsLib.augment (`size`, sizes) (tl r_rm) : utilsLib.cover

val extends =
 (* 8 -> 16, 32, 64 *)
 utilsLib.augment (`size2`, tl sizes)
    (utilsLib.augment (`size`, [hd sizes]) r_rm) @
 (* 16 -> 32, 64 *)
 utilsLib.augment (`size2`, List.drop (sizes, 2))
    (utilsLib.augment (`size`, [List.nth(sizes, 1)]) r_rm) @
 (* 32 -> 64 *)
 utilsLib.augment (`size2`, List.drop (sizes, 3))
    (utilsLib.augment (`size`, [List.nth(sizes, 2)]) r_rm)

val rm_cases = utilsLib.augment (`size`, sizes) rm

(* ------------------------------------------------------------------------ *)

(* TODO: CMPXCHG, DIV, XADD *)

val data_hyp_rule =
   List.map (utilsLib.ALL_HYP_CONV_RULE
                (INST_REWRITE_CONV EA_rwt THENC DATATYPE_CONV))

(*
val is_some_hyp_rule =
   List.map
      (utilsLib.MATCH_HYP_CONV_RULE (REWRITE_CONV [optionTheory.IS_SOME_DEF])
          ``IS_SOME (x: 'a word option)`` o
       utilsLib.MATCH_HYP_RULE (ASM_REWRITE_RULE [])
          ``IS_SOME (x: 'a word option)``)
*)

val cond_update_rule = List.map (Conv.CONV_RULE COND_UPDATE_CONV)

val _ = addThms [dfn'Znop_def]

val Zbinop_rwts =
   EV ([dfn'Zbinop_def, read_dest_src_ea_def] @
       ea_Zsrc_rwt @ ea_Zdest_rwt @ EA_rwt) [] src_dst
      ``dfn'Zbinop (bop, size, ds)``
   |> data_hyp_rule
   |> addThms

val Zcall_imm_rwts =
   EV ([dfn'Zcall_def, x64_push_rip_def, x64_push_aux_def, jump_to_ea_def,
        call_dest_from_ea_def, write'mem64_rwt] @ ea_Zimm_rm_rwt) [] []
      ``dfn'Zcall (Zimm imm)``
   |> data_hyp_rule
   |> addThms

val Zcall_rm_rwts =
   EV ([dfn'Zcall_def, x64_push_rip_def, x64_push_aux_def, jump_to_ea_def,
        call_dest_from_ea_def, write'mem64_rwt, mem64_rwt] @
       ea_Zimm_rm_rwt) [] rm
      ``dfn'Zcall (Zrm rm)``
   |> data_hyp_rule
   |> addThms

val Zcpuid_rwts =
   EV [dfn'Zcpuid_def] [] []
      ``dfn'Zcpuid``
   |> addThms

val Zjcc_rwts =
   EV ([dfn'Zjcc_def, unit_state_cond] @ read_cond_rwts) []
      (mapl (`c`, conds))
      ``dfn'Zjcc (c, imm)``
   |> cond_update_rule
   |> addThms

val Zjmp_rwts =
   EV ([dfn'Zjmp_def] @ ea_Zrm_rwt @ EA_rwt) [] rm
      ``dfn'Zjmp rm``
   |> addThms

val Zlea_rwts =
   EV ([dfn'Zlea_def, get_ea_address_def] @
       ea_Zsrc_rwt @ ea_Zdest_rwt @ EA_rwt @ write'EA_rwt) [] lea
      ``dfn'Zlea (size, ds)``
   |> addThms

val Zleave_rwts =
   EV ([dfn'Zleave_def, x64_pop_def, x64_pop_aux_def, mem64_rwt,
        combinTheory.UPDATE_EQ] @ ea_Zrm_rwt @ write'EA_rwt)
      [] []
      ``dfn'Zleave``
   |> addThms

val Zloop_rwts =
   EV ([dfn'Zloop_def] @ read_cond_rwts) []
      (mapl (`c`, [``Z_NE``, ``Z_E``, ``Z_ALWAYS``]))
      ``dfn'Zloop (c, imm)``
   |> data_hyp_rule
   |> cond_update_rule
   |> addThms

val Zmonop_rwts =
   EV ([dfn'Zmonop_def] @ ea_Zrm_rwt @ EA_rwt) [] rm_cases
      ``dfn'Zmonop (mop, size, rm)``
   |> data_hyp_rule
   |> addThms

val Zmov_rwts =
   EV ([dfn'Zmov_def, unit_state_cond] @
       ea_Zsrc_rwt @ ea_Zdest_rwt @ read_cond_rwts @ EA_rwt @ write'EA_rwt)
       [] (utilsLib.augment (`c`, conds) src_dst)
      ``dfn'Zmov (c, size, ds)``
   |> data_hyp_rule
   (* |> is_some_hyp_rule *)
   |> cond_update_rule
   |> addThms

val Zmovzx_rwts =
   EV ([dfn'Zmovzx_def, cond_rand_thms, word_thms] @
      ea_Zsrc_rwt @ ea_Zdest_rwt @ EA_rwt @ write'EA_rwt)
       [] extends
      ``dfn'Zmovzx (size, ds, size2)``
   |> data_hyp_rule
   |> addThms

val Zmovsx_rwts =
   EV ([dfn'Zmovsx_def, cond_rand_thms, extension_thms, word_thms] @
       SignExtension_rwt @ ea_Zsrc_rwt @ ea_Zdest_rwt @ EA_rwt @ write'EA_rwt)
      [] extends
      ``dfn'Zmovsx (size, ds, size2)``
   |> data_hyp_rule
   |> addThms

val Zmul_rwts =
   EV ([dfn'Zmul_def, erase_eflags, value_width_def, Zsize_width_def,
        word_mul_thms, word_mul_top] @
       ea_Zrm_rwt @ EA_rwt @ write'EA_rwt) [] rm_cases
      ``dfn'Zmul (size, rm)``
   |> data_hyp_rule
   |> addThms

val Zpop_rwts =
   EV ([dfn'Zpop_def, x64_pop_def, x64_pop_aux_def, mem64_rwt] @
        ea_Zrm_rwt @ write'EA_rwt)
      [] rm
      ``dfn'Zpop rm``
   |> data_hyp_rule
   |> addThms

val Zpush_imm_rwts =
   EV ([dfn'Zpush_def, x64_push_def, x64_push_aux_def, write'mem64_rwt] @
       ea_Zimm_rm_rwt @ EA_rwt) [] []
      ``dfn'Zpush (Zimm imm)``
   |> data_hyp_rule
   |> addThms

val Zpush_rm_rwts =
   EV ([dfn'Zpush_def, x64_push_def, x64_push_aux_def, write'mem64_rwt] @
       ea_Zimm_rm_rwt @ EA_rwt) [] rm
      ``dfn'Zpush (Zrm rm)``
   |> data_hyp_rule
   |> addThms

val Zret_rwts =
   EV [dfn'Zret_def, x64_pop_rip_def, x64_pop_aux_def, x64_drop_def, mem64_rwt,
       combinTheory.UPDATE_EQ]
      [[``(7 >< 0) (imm: word64) = 0w: word8``]] []
      ``dfn'Zret imm``
   |> addThms

val Zxchg_rwts =
   EV ([dfn'Zxchg_def] @
        ea_Zrm_rwt @ EA_rwt @ write'EA_rwt_r)
      [] rm_cases
      ``dfn'Zxchg (size, rm, r2)``
   |> data_hyp_rule
   (* |> is_some_hyp_rule *)
   |> addThms

(* ------------------------------------------------------------------------ *)

local
   fun decode_err s = ERR "x64_decode" s
   fun mk_byte w = wordsSyntax.mk_wordi (w, 8)
   fun toByte (x, y) = mk_byte (Arbnum.fromHexString (String.implode [x, y]))
   val get_bytes =
      let
         fun iter a [] = List.rev a
           | iter a (x::y::t) = iter (toByte (x, y) :: a) t
           | iter a [_] = raise decode_err "not even"
      in
         iter [] o String.explode
      end
   val x64_fetch =
      (x64_CONV THENC REWRITE_CONV [wordsTheory.WORD_ADD_0])``x64_fetch s``
   fun fetch s =
      List.foldl
         (fn (b, (i, thm)) =>
            let
               val rwt = if i = 0
                            then ``^st.MEM (^st.RIP) = SOME ^b``
                         else let
                                 val j = numSyntax.term_of_int i
                              in
                                 ``^st.MEM (^st.RIP + n2w ^j) = SOME ^b``
                              end
            in
               (i + 1, PURE_REWRITE_RULE [ASSUME rwt, optionTheory.THE_DEF] thm)
            end) (0, x64_fetch) (get_bytes s) |> snd
   val decode_tm = ``x64_decode (FST (x64_fetch ^st))``
in
   fun x64_decode s =
      let
         val fetch_rwt = fetch s
         val thm =
            (Conv.RAND_CONV
                (Conv.RAND_CONV (Conv.REWR_CONV fetch_rwt)
                 THENC Conv.REWR_CONV pairTheory.FST)
             THENC x64_CONV) decode_tm
      in
         case boolSyntax.dest_strip_comb (utilsLib.rhsc thm) of
             ("x64$Zfull_inst", [a]) =>
                (case pairSyntax.strip_pair a of
                    [_, _, l] =>
                       (case listSyntax.dest_list l of
                           ([], _) => thm
                         | (h :: _, _) =>
                             (optionSyntax.is_the h
                              orelse raise decode_err "trailing bytes"; thm))
                  | _ => raise decode_err "decode failed")
           | _ => raise decode_err "too few bytes"
      end
end

local
    val Icache_CONV =
       x64_CONV
       THENC REWRITE_CONV
         (wordsTheory.WORD_ADD_0 ::
          List.tabulate
             (20, fn 0 => ASSUME ``^st.ICACHE (^st.RIP) = ^st.MEM (^st.RIP)``
                   | i => let
                             val j = numSyntax.term_of_int i
                          in
                             ASSUME ``^st.ICACHE (^st.RIP + n2w ^j) =
                                      ^st.MEM (^st.RIP + n2w ^j)``
                          end))
in
   val checkIcache_rwts =
      List.tabulate
         (20, fn i => let
                         val j = numSyntax.term_of_int (i + 1)
                      in
                          utilsLib.NCONV (i + 1) Icache_CONV
                             ``checkIcache ^j s``
                      end)
end

(* ------------------------------------------------------------------------ *)

local
   fun is_some_wv tm =
      ((tm |> boolSyntax.dest_eq |> snd
           |> optionSyntax.dest_some
           |> Term.dest_var |> fst) = "wv")
      handle HOL_ERR _ => false
in
   fun FIX_SAME_ADDRESS_RULE thm =
      case List.partition is_some_wv (Thm.hyp thm) of
         ([], _) => thm
       | ([t], rst) =>
           let
              val (l, r) = boolSyntax.dest_eq t
              val wv = optionSyntax.dest_some r
              val v = Term.mk_var ("v", Term.type_of wv)
              val sv = optionSyntax.mk_some v
              val tv = boolSyntax.mk_eq (l, sv)
           in
              if List.exists (Lib.equal tv) rst
                 then Thm.INST [wv |-> v] thm
              else thm
           end
       | _ => raise ERR "FIX_SAME_ADDRESS_RULE" "more than one"
end

local
   val TIDY_UP_CONV =
      REWRITE_CONV
         (List.take
            (List.drop (utilsLib.datatype_rewrites "x64" ["Zreg"], 10), 2))
      THENC utilsLib.WGROUND_CONV
   val rwts = [pairTheory.FST, pairTheory.SND, word_thms]
   val get_strm1 = Term.rand o Term.rand o Term.rand o utilsLib.rhsc
   val get_ast = Term.rand o Term.rator o Term.rand o Term.rand o utilsLib.rhsc
   val get_state = snd o pairSyntax.dest_pair o utilsLib.rhsc
   val state_exception_tm =
      Term.prim_mk_const {Thy = "x64", Name = "x64_state_exception"}
   fun mk_proj_exception r = Term.mk_comb (state_exception_tm, r)
   val twenty = numSyntax.term_of_int 20
   fun mk_len_icache_thms thm1 =
      let
         val strm1 = get_strm1 thm1
         val len_thm =
            (Conv.RAND_CONV listLib.LENGTH_CONV THENC numLib.REDUCE_CONV)
               (numSyntax.mk_minus (twenty, listSyntax.mk_length strm1))
         val len = utilsLib.rhsc len_thm
         val n = numSyntax.int_of_term len
      in
         (len_thm, List.nth (checkIcache_rwts, n - 1), len)
      end
   fun bump_rip len = Term.subst [st |-> ``^st with RIP := ^st.RIP + n2w ^len``]
   val run_CONV = utilsLib.Run_CONV ("x64", st) o get_ast
   val run = utilsLib.ALL_HYP_CONV_RULE utilsLib.WGROUND_CONV o
             FIX_SAME_ADDRESS_RULE o
             (INST_REWRITE_CONV (rwts @ getThms ()) THENC TIDY_UP_CONV)
   val MP_Next  = Drule.MATCH_MP x64_stepTheory.NextStateX64
   val MP_Next0 = Drule.MATCH_MP x64_stepTheory.NextStateX64_0
   val STATE_CONV =
      REWRITE_CONV (utilsLib.datatype_rewrites "x64" ["x64_state"] @
         [combinTheory.K_THM, combinTheory.o_THM,
          boolTheory.COND_ID, cond_rand_thms])
   fun unchanged s = raise ERR "x64_step" ("Failed to evaluate: " ^ s)
   val cache =
      ref (Redblackmap.mkDict String.compare: (string, thm) Redblackmap.dict)
   fun addToCache (s, thm) =
      (cache := Redblackmap.insert (!cache, s, thm); thm)
   fun checkCache s = Redblackmap.peek (!cache, s)
in
   fun x64_step s =
      let
         val s = utilsLib.uppercase s
      in
         case checkCache s of
            SOME thm => thm
          | NONE =>
            let
               val thm1 = x64_decode s
               val (thm2, thm3, len) = mk_len_icache_thms thm1
               val thm4 = run_CONV thm1
               val thm5 = (thm4 |> Drule.SPEC_ALL
                                |> utilsLib.rhsc
                                |> bump_rip len
                                |> run)
                          handle Conv.UNCHANGED => unchanged s
               val r = get_state thm5
                       handle HOL_ERR {origin_function = "dest_pair", ...} =>
                         (Parse.print_thm thm5
                          ; print "\n"
                          ; raise ERR "eval" "failed to fully evaluate")
               val thm6 = STATE_CONV (mk_proj_exception r)
               val thm = Drule.LIST_CONJ [thm1, thm2, thm3, thm4, thm5, thm6]
            in
               addToCache (s,
                  MP_Next thm
                  handle HOL_ERR {message = "different constructors", ...} =>
                     MP_Next0 thm)
            end
      end
end

(*
fun number_of_rewrites () = List.length (getThms ())

number_of_rewrites ()

val s = "418803";
Count.apply x64_step "418803";
Count.apply x64_step "90";
Count.apply x64_step "487207";
Count.apply x64_decode "485A"

Count.apply x64_decode "8345F801"
Count.apply x64_step "8345F801"

Count.apply x64_step "4863D0"
Count.apply x64_step "0FBEC0";
Count.apply x64_step "0FB6C0";

val l = List.map (Count.apply x64_step) hex_list
val l = Count.apply (List.map x64_step) hex_list

val _ = Count.apply (List.map x64_step) hex_list

*)

(* ========================================================================= *)

end
