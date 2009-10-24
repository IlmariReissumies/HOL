open HolKernel Parse bossLib boolLib

val _ = new_theory "recsets"

open recfunsTheory reductionEval
open binderLib
open stepsTheory

fun Store_thm(trip as (n,t,tac)) = store_thm trip before export_rewrites [n]

val recursive_def = Define`
  recursive s = ∃M. ∀e. Phi M e = SOME (if e ∈ s then 1 else 0)
`;

val empty_recursive = Store_thm(
  "empty_recursive",
  ``recursive {}``,
  SRW_TAC [][recursive_def, Phi_def] THEN
  Q.EXISTS_TAC `dBnum (fromTerm (LAM v (church 0)))` THEN
  SIMP_TAC (bsrw_ss()) [normal_orderTheory.bnf_bnf_of]);

val univ_recursive = Store_thm(
  "univ_recursive",
  ``recursive UNIV``,
  SRW_TAC [][recursive_def, Phi_def] THEN
  Q.EXISTS_TAC `dBnum (fromTerm (LAM v (church 1)))` THEN
  SIMP_TAC (bsrw_ss()) [normal_orderTheory.bnf_bnf_of]);

val union_recursive_I = Store_thm(
  "union_recursive_I",
  ``recursive s₁ ∧ recursive s₂ ⇒ recursive (s₁ ∪ s₂)``,
  SRW_TAC [][recursive_def] THEN
  SIMP_TAC (srw_ss()) [Phi_def] THEN
  Q.EXISTS_TAC
    `dBnum (fromTerm
      (LAM z (cor @@ (ceqnat @@ (church 1)
                             @@ (UM @@ (cnpair @@ church M @@ VAR z)))
                  @@ (ceqnat @@ (church 1)
                             @@ (UM @@ (cnpair @@ church M' @@ VAR z)))
                  @@ church 1
                  @@ church 0)))` THEN
  Q.X_GEN_TAC `n` THEN
  REPEAT (FIRST_X_ASSUM (Q.SPEC_THEN `n` STRIP_ASSUME_TAC)) THEN
  IMP_RES_TAC PhiSOME_UM_I THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchnumTheory.cnpair_behaviour,
                            churchnumTheory.ceqnat_behaviour] THEN
  Cases_on `n ∈ s₁` THEN Cases_on `n ∈ s₂` THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchboolTheory.cor_behaviour,
                            churchboolTheory.cB_behaviour,
                            normal_orderTheory.bnf_bnf_of]);

val inter_recursive_I = Store_thm(
  "inter_recursive_I",
  ``recursive s₁ ∧ recursive s₂ ⇒ recursive (s₁ ∩ s₂)``,
  SRW_TAC [][recursive_def] THEN
  SIMP_TAC (srw_ss()) [Phi_def] THEN
  Q.EXISTS_TAC `
    dBnum (fromTerm
      (LAM z (cmult @@ (UM @@ (cnpair @@ church M @@ VAR z))
                    @@ (UM @@ (cnpair @@ church M' @@ VAR z)))))` THEN
  Q.X_GEN_TAC `n` THEN
  REPEAT (FIRST_X_ASSUM (Q.SPEC_THEN `n` STRIP_ASSUME_TAC)) THEN
  IMP_RES_TAC PhiSOME_UM_I THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchnumTheory.cnpair_behaviour,
                            churchnumTheory.cmult_behaviour,
                            normal_orderTheory.bnf_bnf_of] THEN
  Cases_on `n ∈ s₁` THEN SRW_TAC [][]);

val compl_recursive_I = store_thm(
  "compl_recursive_I",
  ``recursive s ⇒ recursive (COMPL s)``,
  SRW_TAC [][recursive_def] THEN
  SIMP_TAC (srw_ss()) [Phi_def] THEN
  Q.EXISTS_TAC `
    dBnum (fromTerm
      (LAM z (cminus @@ (church 1)
                     @@ (UM @@ (cnpair @@ church M @@ VAR z)))))` THEN
  Q.X_GEN_TAC `n` THEN
  POP_ASSUM (Q.SPEC_THEN `n` STRIP_ASSUME_TAC) THEN
  IMP_RES_TAC PhiSOME_UM_I THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchnumTheory.cnpair_behaviour,
                            churchnumTheory.cminus_behaviour,
                            normal_orderTheory.bnf_bnf_of] THEN
  Cases_on `n ∈ s` THEN SRW_TAC [][]);

val compl_recursive = Store_thm(
  "compl_recursive",
  ``recursive (COMPL s) ⇔ recursive s``,
  METIS_TAC [pred_setTheory.COMPL_COMPL, compl_recursive_I]);

val finite_recursive = Store_thm(
  "finite_recursive",
  ``∀s. FINITE s ==> recursive s``,
  HO_MATCH_MP_TAC pred_setTheory.FINITE_INDUCT THEN
  SRW_TAC [][] THEN
  FULL_SIMP_TAC (srw_ss()) [recursive_def] THEN
  SIMP_TAC (srw_ss()) [Phi_def] THEN
  Q.EXISTS_TAC `
    dBnum (fromTerm
      (LAM z (cor @@ (ceqnat @@ VAR z @@ church e)
                  @@ (ceqnat @@ church 1
                             @@ (UM @@ (cnpair @@ church M @@ VAR z)))
                  @@ church 1
                  @@ church 0)))` THEN
  Q.X_GEN_TAC `n` THEN FIRST_X_ASSUM (Q.SPEC_THEN `n` STRIP_ASSUME_TAC) THEN
  IMP_RES_TAC PhiSOME_UM_I THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchnumTheory.cnpair_behaviour,
                            churchnumTheory.ceqnat_behaviour,
                            churchboolTheory.cor_behaviour] THEN
  Cases_on `n = e` THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchboolTheory.cB_behaviour,
                            normal_orderTheory.bnf_bnf_of] THEN
  Cases_on `n ∈ s` THEN
  ASM_SIMP_TAC (bsrw_ss()) [churchboolTheory.cB_behaviour,
                            normal_orderTheory.bnf_bnf_of]);

(* an r.e. set is one that can be enumerated.  In this world, I take enumerable
   to mean there exists a function that returns values at successive indices.
*)
val re_def = Define`
  re s = ∃Mi. ∀e. e ∈ s ⇔ ∃j. Phi Mi j = SOME e
`;

(* if a set s is r.e., then there is a machine that terminates on only those
   elements of the set (and fails to terminate on non-members)

   Say the machine we have that enumerates s is Mi.  Then we want one that
   will correctly terminate on element e of s.
   For increasing n, construct the list of n elements corresponding to
   evaluating [Mi 0, Mi 1, Mi 2, ... Mi n] for n steps.  For all the bnfs in
   this list, see if one of them is equal to e.  If so, terminate.


val re_semirecursive1 = prove(
  ``re s ⇒ ∃N. ∀e. e ∈ s ⇔ ∃m. Phi N e = SOME m``,
  SRW_TAC [][re_def] THEN
  Q.EXISTS_TAC
    `dBnum (fromTerm (
       LAM "e" (Y @@
         (LAM "loop" (LAM "n"
            (cmem @@ VAR "e"
                  @@ (cfilter
                        @@ cbnf
                        @@ (cmap
                              @@ (csteps @@ VAR "n")
                              @@ (ctabulate @@ (csuc @@ VAR "n")
                                            @@ (LAM "j"
                                                    (UM
                                                       @@ (cnpair
                                                             @@ (church Mi)
                                                             @@ (VAR "j")))))))
                  @@ church 0
                  @@ (VAR "loop" @@ (csuc @@ VAR "n"))))))))`
*)

(*
val recursive_re = store_thm(
  "recursive_re",
  ``recursive s ⇒ re s``,
  SRW_TAC [][recursive_def, re_def] THEN
  `dBnum (fromTerm

*)




val _ = export_theory ()
