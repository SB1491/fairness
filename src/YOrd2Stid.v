From sflib Require Import sflib.
From ITree Require Export ITree.
From Paco Require Import paco.

Require Import Coq.Classes.RelationClasses.
Require Import Program.

Export ITreeNotations.

From Fairness Require Import Axioms.
From Fairness Require Export ITreeLib FairBeh FairSim NatStructs.
From Fairness Require Import pind PCM World WFLib ThreadsURA.
From Fairness Require Import Mod ModSimYOrd ModSimStid.

Set Implicit Arguments.

Section IMAPAUX1.

  Variable wf: WF.

  Definition imap_proj_id1 {id1 id2: ID} (im: @imap (id_sum id1 id2) wf): @imap id1 wf := fun i => im (inl i).
  Definition imap_proj_id2 {id1 id2: ID} (im: @imap (id_sum id1 id2) wf): @imap id2 wf := fun i => im (inr i).
  Definition imap_proj_id {id1 id2: ID} (im: @imap (id_sum id1 id2) wf): prod (@imap id1 wf) (@imap id2 wf) :=
    (imap_proj_id1 im, imap_proj_id2 im).

  Definition imap_sum_id {id1 id2: ID} (im: prod (@imap id1 wf) (@imap id2 wf)): @imap (id_sum id1 id2) wf :=
    fun i => match i with | inl il => (fst im) il | inr ir => (snd im) ir end.

  Lemma imap_sum_proj_id_inv1
        id1 id2
        (im1: @imap id1 wf)
        (im2: @imap id2 wf)
    :
    imap_proj_id (imap_sum_id (im1, im2)) = (im1, im2).
  Proof. reflexivity. Qed.

  Lemma imap_sum_proj_id_inv2
        id1 id2
        (im: @imap (id_sum id1 id2) wf)
    :
    imap_sum_id (imap_proj_id im) = im.
  Proof. extensionality i. unfold imap_sum_id. des_ifs. Qed.

End IMAPAUX1.
Global Opaque imap_proj_id1.
Global Opaque imap_proj_id2.
Global Opaque imap_sum_id.


Section IMAPAUX2.

  Variable id: ID.

  Definition imap_proj_wf1 {wf1 wf2: WF} (im: @imap id (double_rel_WF wf1 wf2)): @imap id wf1 := fun i => fst (im i).
  Definition imap_proj_wf2 {wf1 wf2: WF} (im: @imap id (double_rel_WF wf1 wf2)): @imap id wf2 := fun i => snd (im i).
  Definition imap_proj_wf {wf1 wf2: WF} (im: @imap id (double_rel_WF wf1 wf2)): prod (@imap id wf1) (@imap id wf2) :=
    (imap_proj_wf1 im, imap_proj_wf2 im).

  Definition imap_sum_wf {wf1 wf2: WF} (im: prod (@imap id wf1) (@imap id wf2)): @imap id (double_rel_WF wf1 wf2) :=
    fun i => (fst im i, snd im i).

  Lemma imap_sum_proj_wf_inv1
        wf1 wf2
        (im1: @imap id wf1)
        (im2: @imap id wf2)
    :
    imap_proj_wf (imap_sum_wf (im1, im2)) = (im1, im2).
  Proof. reflexivity. Qed.

  Lemma imap_sum_proj_wf_inv2
        wf1 wf2
        (im: @imap id (double_rel_WF wf1 wf2))
    :
    imap_sum_wf (imap_proj_wf im) = im.
  Proof.
    extensionality i. unfold imap_sum_wf, imap_proj_wf, imap_proj_wf1, imap_proj_wf2. ss. destruct (im i); ss.
  Qed.

End IMAPAUX2.
Global Opaque imap_proj_wf1.
Global Opaque imap_proj_wf2.
Global Opaque imap_sum_wf.



Section PROOF.

  Context `{M: URA.t}.

  Variable state_src: Type.
  Variable state_tgt: Type.

  Variable ident_src: ID.
  Variable _ident_tgt: ID.
  Let ident_tgt := sum_tid _ident_tgt.

  Variable wf_src: WF.
  Variable wf_tgt: WF.

  Let srcE := ((@eventE ident_src +' cE) +' sE state_src).
  Let tgtE := ((@eventE _ident_tgt +' cE) +' sE state_tgt).

  Let shared :=
        (TIdSet.t *
           (@imap ident_src wf_src) *
           (@imap ident_tgt wf_tgt) *
           state_src *
           state_tgt)%type.
  Let shared_rel: Type := shared -> Prop.
  Variable I: shared -> URA.car -> Prop.

  Variable wf_stt: Type -> Type -> WF.
  Variable wf_stt0: forall R0 R1, (wf_stt R0 R1).(T).


  Let ident_src2 := sum_tid ident_src.

  Let wf_src_th {R0 R1}: WF := clos_trans_WF (prod_WF (prod_WF (wf_stt R0 R1) wf_tgt) (nm_wf (wf_stt R0 R1))).
  Let wf_src2 {R0 R1}: WF := double_rel_WF (@wf_src_th R0 R1) wf_src.

  Let srcE2 := ((@eventE ident_src2 +' cE) +' sE state_src).
  Let shared2 {R0 R1} :=
        (TIdSet.t *
           (@imap ident_src2 (@wf_src2 R0 R1)) *
           (@imap ident_tgt wf_tgt) *
           state_src *
           state_tgt)%type.
  Let shared2_rel {R0 R1}: Type := (@shared2 R0 R1) -> Prop.

  Let M2 {R0 R1}: URA.t := URA.prod (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)) M.

  (* Definition shared_thsRA_white {R0 R1} *)
  (*            (ost: NatMap.t (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)): @_thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T) := *)
  (*   fun tid => match NatMap.find tid ost with *)
  (*           | Some osot => Some osot *)
  (*           | None => Some (wf_stt0 R0 R1, wf_stt0 R0 R1) *)
  (*           end. *)

  (* Definition shared_thsRA_black {R0 R1} *)
  (*            (ost: NatMap.t (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)): @_thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T) := *)
  (*   fun tid => match NatMap.find tid ost with *)
  (*           | Some osot => ε *)
  (*           | None => Some (wf_stt0 R0 R1, wf_stt0 R0 R1) *)
  (*           end. *)

  Definition shared_thsRA {R0 R1}
             (ost: NatMap.t (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T))
    : @thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T) :=
    (fun tid => match NatMap.find tid ost with
             | Some osot => ae_black osot
             | None => ae_black (wf_stt0 R0 R1, wf_stt0 R0 R1) ⋅ ae_white (wf_stt0 R0 R1, wf_stt0 R0 R1)
             end).

  (* Definition shared_thsRA {R0 R1} *)
  (*            (ths_r: (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T))) *)
  (*            (ost: NatMap.t (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)) *)
  (*   := *)
  (*   ths_r = (fun tid => match NatMap.find tid ost with *)
  (*                    | Some osot => ae_black osot *)
  (*                    | None => ae_black (wf_stt0 R0 R1, wf_stt0 R0 R1) ⋅ ae_white (wf_stt0 R0 R1, wf_stt0 R0 R1) *)
  (*                    end). *)

  Definition Is {R0 R1}:
    (TIdSet.t * (@imap thread_id (@wf_src_th R0 R1)) * (@imap ident_tgt wf_tgt))%type ->
    (@URA.car (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T))) -> Prop :=
    fun '(ths, im_src, im_tgt) ths_r =>
      exists (ost: NatMap.t (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)),
        (<<WFOST: nm_wf_pair ths ost>>) /\
          (<<TRES: ths_r = shared_thsRA ost>>) /\
          (<<IMSRC: forall tid (IN: NatMap.In tid ths)
                      os ot (FIND: NatMap.find tid ost = Some (os, ot)),
              wf_src_th.(lt) ((ot, im_tgt (inl tid)), nm_proj_v1 ost) (im_src tid)>>).

  Definition I2 {R0 R1}: (@shared2 R0 R1) -> (@URA.car (@M2 R0 R1)) -> Prop :=
    fun '(ths, im_src, im_tgt, st_src, st_tgt) '(ths_r, r) =>
      (<<INV: I (ths, imap_proj_wf2 (imap_proj_id2 im_src), im_tgt, st_src, st_tgt) r>>) /\
        (<<INVS: Is (ths, (imap_proj_wf1 (imap_proj_id1 im_src)), im_tgt) ths_r>>).

  Definition lift_LRR {R0 R1} (LRR: R0 -> R1 -> (@URA.car M) -> shared_rel):
    R0 -> R1 -> (@URA.car (@M2 R0 R1)) -> (@shared2_rel R0 R1) :=
    fun r0 r1 r_ctx '(ths, im_src, im_tgt, st_src, st_tgt) =>
      LRR r0 r1 (snd r_ctx) (ths, imap_proj_wf2 (imap_proj_id2 im_src), im_tgt, st_src, st_tgt).

  Lemma yord_implies_stid
        tid
        R0 R1 (LRR: R0 -> R1 -> (@URA.car M) -> shared_rel)
        ths
        (im_src: @imap ident_src2 (@wf_src2 R0 R1))
        (im_tgt: @imap ident_tgt wf_tgt)
        st_src st_tgt
        ps pt r_ctx src tgt
        os ot
        (LSIM: ModSimYOrd.lsim I wf_stt tid LRR ps pt r_ctx (os, src) (ot, tgt)
                               (ths, imap_proj_wf2 (imap_proj_id2 im_src), im_tgt, st_src, st_tgt))
        (ths_r ctx_r: (@thsRA (prod_WF (wf_stt R0 R1) (wf_stt R0 R1)).(T)))
        (INVS: Is (ths, (imap_proj_wf1 (imap_proj_id1 im_src)), im_tgt) ths_r)
        (VALS: URA.wf (ths_r ⋅ (th_has tid (os, ot)) ⋅ ctx_r))
    :
    ModSimStid.lsim I2 tid (lift_LRR LRR) ps pt (ctx_r, r_ctx) src tgt
                    (ths, im_src, im_tgt, st_src, st_tgt).
  Proof.
    revert_until tid. pcofix CIH; i.
    remember (os, src) as osrc. remember (ot, tgt) as otgt.
    move LSIM before CIH. revert_until LSIM.
    pattern R0, R1, LRR, ps, pt, r_ctx, osrc, otgt, shr.
    revert R0 R1 LRR ps pt r_ctx osrc otgt shr LSIM. apply pind9_acc.
    intros rr DEC IH. clear DEC. intros R0 R1 LRR ps pt r_ctx osrc otgt shr LSIM.
    i; clarify.
    eapply pind9_unfold in LSIM; eauto with paco.
    inv LSIM.

End PROOF.
