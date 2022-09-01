From sflib Require Import sflib.
From ITree Require Export ITree.
From Paco Require Import paco.

Require Export Coq.Strings.String.
Require Import Coq.Classes.RelationClasses.
Require Import Program.
Require Import Permutation.

Export ITreeNotations.

From Fairness Require Import Axioms.
From Fairness Require Export ITreeLib FairBeh FairSim NatStructs.
From Fairness Require Export Mod ModSimStutter Concurrency.
From Fairness Require Import pind.
From Fairness Require Import PCM.

Set Implicit Arguments.



Section ADEQ.

  Ltac gfold := gfinal; right; pfold.

  Context `{M: URA.t}.

  Variable state_src: Type.
  Variable state_tgt: Type.

  Variable _ident_src: ID.
  Let ident_src := sum_tid _ident_src.
  Variable _ident_tgt: ID.
  Let ident_tgt := sum_tid _ident_tgt.

  Variable wf_src: WF.
  Variable wf_tgt: WF.

  Notation srcE := ((@eventE _ident_src +' cE) +' sE state_src).
  Notation tgtE := ((@eventE _ident_tgt +' cE) +' sE state_tgt).

  Let shared := shared state_src state_tgt _ident_src _ident_tgt wf_src wf_tgt.

  Definition threads2 _id ev R := Th.t (prod bool (@thread _id ev R)).
  Notation threads_src1 R0 := (threads _ident_src (sE state_src) R0).
  Notation threads_src2 R0 := (threads2 _ident_src (sE state_src) R0).
  Notation threads_tgt R1 := (threads _ident_tgt (sE state_tgt) R1).

  Variant __sim_knot R0 R1 (RR: R0 -> R1 -> Prop)
          (sim_knot: threads_src2 R0 -> threads_tgt R1 -> thread_id -> URA.car -> URA.car -> bool -> bool -> (prod bool (itree srcE R0)) -> (itree tgtE R1) -> shared -> Prop)
          (_sim_knot: threads_src2 R0 -> threads_tgt R1 -> thread_id -> URA.car -> URA.car -> bool -> bool -> (prod bool (itree srcE R0)) -> (itree tgtE R1) -> shared -> Prop)
          (thsl: threads_src2 R0) (thsr: threads_tgt R1)
    :
    thread_id -> URA.car -> URA.car -> bool -> bool -> (prod bool (itree srcE R0)) -> itree tgtE R1 -> shared -> Prop :=
    | ksim_ret_term
        tid f_src f_tgt
        sf r_src r_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        ths0 tht0 r_own0 r_shared0
        (THSR: NatSet.remove tid ths = ths0)
        (THTR: NatSet.remove tid tht = tht0)
        (VALID: URA.wf (r_shared0 ⋅ r_own0 ⋅ r_ctx))
        (RET: RR r_src r_tgt)
        (NILS: Th.is_empty thsl = true)
        (NILT: Th.is_empty thsr = true)
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Ret r_src)
                 (Ret r_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_ret_cont
        tid f_src f_tgt
        sf r_src r_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        ths0 tht0 o0 r_own0 r_shared0
        (THSR: NatSet.remove tid ths = ths0)
        (THTR: NatSet.remove tid tht = tht0)
        (VALID: URA.wf (r_shared0 ⋅ r_own0 ⋅ r_ctx))
        (STUTTER: wf_src.(lt) o0 o)
        (RET: RR r_src r_tgt)
        (NNILS: Th.is_empty thsl = false)
        (NNILT: Th.is_empty thsr = false)
        (KSIM: forall tid0,
            ((nm_pop tid0 thsl = None) /\ (nm_pop tid0 thsr = None)) \/
              (exists b th_src thsl0 th_tgt thsr0,
                  (nm_pop tid0 thsl = Some ((b, th_src), thsl0)) /\
                    (nm_pop tid0 thsr = Some (th_tgt, thsr0)) /\
                    ((b = true) ->
                     (forall im_tgt0
                        (FAIR: fair_update im_tgt im_tgt0 (sum_fmap_l (tids_fmap tid0 tht0))),
                       exists r_own1 r_ctx1,
                         (URA.wf (r_shared0 ⋅ r_own1 ⋅ r_ctx1)) /\
                           (forall ps pt, sim_knot thsl0 thsr0 tid0 r_own1 r_ctx1 ps pt
                                              (b, Vis (inl1 (inr1 Yield)) (fun _ => th_src))
                                              (th_tgt)
                                              (ths0, tht0, im_src, im_tgt0, st_src, st_tgt, o0, r_shared0)))) /\
                    ((b = false) ->
                     (forall im_tgt0
                        (FAIR: fair_update im_tgt im_tgt0 (sum_fmap_l (tids_fmap tid0 tht0))),
                       exists im_src0 r_own1 r_ctx1,
                         (fair_update im_src im_src0 (sum_fmap_l (tids_fmap tid0 ths0))) /\
                           (URA.wf (r_shared0 ⋅ r_own1 ⋅ r_ctx1)) /\
                           (forall ps pt, sim_knot thsl0 thsr0 tid0 r_own1 r_ctx1 ps pt
                                              (b, th_src)
                                              th_tgt
                                              (ths0, tht0, im_src0, im_tgt0, st_src, st_tgt, o0, r_shared0))))))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Ret r_src)
                 (Ret r_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)

    | ksim_sync
        tid f_src f_tgt
        sf ktr_src ktr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        thsl0 thsr0
        (THSL: thsl0 = Th.add tid (true, ktr_src tt) thsl)
        (THSR: thsr0 = Th.add tid (ktr_tgt tt) thsr)
        (KSIM: forall tid0,
            ((nm_pop tid0 thsl0 = None) /\ (nm_pop tid0 thsr0 = None)) \/
              (exists b th_src thsl1 th_tgt thsr1,
                  (nm_pop tid0 thsl0 = Some ((b, th_src), thsl1)) /\
                    (nm_pop tid0 thsr0 = Some (th_tgt, thsr1)) /\
                    ((b = true) ->
                     exists o0 r_own0 r_ctx0 r_shared0,
                       (wf_src.(lt) o0 o) /\ (URA.wf (r_shared0 ⋅ r_own0 ⋅ r_ctx0)) /\
                         (forall im_tgt0
                            (FAIR: fair_update im_tgt im_tgt0 (sum_fmap_l (tids_fmap tid0 tht))),
                           forall ps pt, sim_knot thsl1 thsr1 tid0 r_own0 r_ctx0 ps pt
                                             (b, Vis (inl1 (inr1 Yield)) (fun _ => th_src))
                                             (th_tgt)
                                             (ths, tht, im_src, im_tgt0, st_src, st_tgt, o0, r_shared0))) /\
                    ((b = false) ->
                     exists o0 r_own0 r_ctx0 r_shared0,
                       (wf_src.(lt) o0 o) /\ (URA.wf (r_shared0 ⋅ r_own0 ⋅ r_ctx0)) /\
                         (forall im_tgt0
                            (FAIR: fair_update im_tgt im_tgt0 (sum_fmap_l (tids_fmap tid0 tht))),
                           exists im_src0,
                             (fair_update im_src im_src0 (sum_fmap_l (tids_fmap tid0 ths))) /\
                               (forall ps pt, sim_knot thsl1 thsr1 tid0 r_own0 r_ctx0 ps pt
                                                  (b, th_src)
                                                  th_tgt
                                                  (ths, tht, im_src0, im_tgt0, st_src, st_tgt, o0, r_shared0))))))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Vis (inl1 (inr1 Yield)) ktr_src)
                 (Vis (inl1 (inr1 Yield)) ktr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)

    | ksim_yieldL
        tid f_src f_tgt
        sf ktr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: exists im_src0 o0,
            (fair_update im_src im_src0 (sum_fmap_l (tids_fmap tid ths))) /\
              (_sim_knot thsl thsr tid r_own r_ctx true f_tgt
                         (false, ktr_src tt)
                         itr_tgt
                         (ths, tht, im_src0, im_tgt, st_src, st_tgt, o0, r_shared)))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Vis (inl1 (inr1 Yield)) ktr_src)
                 (itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)

    | ksim_tauL
        tid f_src f_tgt
        sf itr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: _sim_knot thsl thsr tid r_own r_ctx true f_tgt
                         (sf, itr_src)
                         itr_tgt
                         (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Tau itr_src)
                 (itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_chooseL
        tid f_src f_tgt
        sf X ktr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: exists x, _sim_knot thsl thsr tid r_own r_ctx true f_tgt
                              (sf, ktr_src x)
                              itr_tgt
                              (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Vis (inl1 (inl1 (Choose X))) ktr_src)
                 (itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_putL
        tid f_src f_tgt
        sf st_src0 ktr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: _sim_knot thsl thsr tid r_own r_ctx true f_tgt
                         (sf, ktr_src tt)
                         itr_tgt
                         (ths, tht, im_src, im_tgt, st_src0, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Vis (inr1 (Mod.Put st_src0)) ktr_src)
                 (itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_getL
        tid f_src f_tgt
        sf ktr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: _sim_knot thsl thsr tid r_own r_ctx true f_tgt
                         (sf, ktr_src st_src)
                         itr_tgt
                         (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Vis (inr1 (@Mod.Get _)) ktr_src)
                 (itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_tidL
        tid f_src f_tgt
        sf ktr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: _sim_knot thsl thsr tid r_own r_ctx true f_tgt
                         (sf, ktr_src tid)
                         itr_tgt
                         (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Vis (inl1 (inr1 GetTid)) ktr_src)
                 (itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_UB
        tid f_src f_tgt
        sf ktr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Vis (inl1 (inl1 Undefined)) ktr_src)
                 (itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_fairL
        tid f_src f_tgt
        sf fm ktr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: exists im_src0,
            (<<FAIR: fair_update im_src im_src0 (sum_fmap_r fm)>>) /\
              (_sim_knot thsl thsr tid r_own r_ctx true f_tgt
                         (sf, ktr_src tt)
                         itr_tgt
                         (ths, tht, im_src0, im_tgt, st_src, st_tgt, o, r_shared)))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Vis (inl1 (inl1 (Fair fm))) ktr_src)
                 (itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)

    | ksim_tauR
        tid f_src f_tgt
        sf itr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: _sim_knot thsl thsr tid r_own r_ctx f_src true
                         (sf, itr_src)
                         itr_tgt
                         (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, itr_src)
                 (Tau itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_chooseR
        tid f_src f_tgt
        sf itr_src X ktr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: forall x, _sim_knot thsl thsr tid r_own r_ctx f_src true
                              (sf, itr_src)
                              (ktr_tgt x)
                              (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, itr_src)
                 (Vis (inl1 (inl1 (Choose X))) ktr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_putR
        tid f_src f_tgt
        sf itr_src st_tgt0 ktr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: _sim_knot thsl thsr tid r_own r_ctx f_src true
                         (sf, itr_src)
                         (ktr_tgt tt)
                         (ths, tht, im_src, im_tgt, st_src, st_tgt0, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, itr_src)
                 (Vis (inr1 (Mod.Put st_tgt0)) ktr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_getR
        tid f_src f_tgt
        sf itr_src ktr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: _sim_knot thsl thsr tid r_own r_ctx f_src true
                         (sf, itr_src)
                         (ktr_tgt st_tgt)
                         (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, itr_src)
                 (Vis (inr1 (@Mod.Get _)) ktr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_tidR
        tid f_src f_tgt
        sf itr_src ktr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: _sim_knot thsl thsr tid r_own r_ctx f_src true
                         (sf, itr_src)
                         (ktr_tgt tid)
                         (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, itr_src)
                 (Vis (inl1 (inr1 GetTid)) ktr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
    | ksim_fairR
        tid f_src f_tgt
        sf itr_src fm ktr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: forall im_tgt0 (FAIR: fair_update im_tgt im_tgt0 (sum_fmap_r fm)),
            (_sim_knot thsl thsr tid r_own r_ctx f_src true
                       (sf, itr_src)
                       (ktr_tgt tt)
                       (ths, tht, im_src, im_tgt0, st_src, st_tgt, o, r_shared)))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, itr_src)
                 (Vis (inl1 (inl1 (Fair fm))) ktr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)

    | ksim_observe
        tid f_src f_tgt
        sf fn args ktr_src ktr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: forall ret, sim_knot thsl thsr tid r_own r_ctx true true
                               (sf, ktr_src ret)
                               (ktr_tgt ret)
                               (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx f_src f_tgt
                 (sf, Vis (inl1 (inl1 (Observe fn args))) ktr_src)
                 (Vis (inl1 (inl1 (Observe fn args))) ktr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)

    | ksim_progress
        tid
        sf itr_src itr_tgt
        r_own r_ctx r_shared
        ths tht im_src im_tgt st_src st_tgt o
        (KSIM: sim_knot thsl thsr tid r_own r_ctx false false
                        (sf, itr_src)
                        itr_tgt
                        (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared))
      :
      __sim_knot RR sim_knot _sim_knot thsl thsr tid r_own r_ctx true true
                 (sf, itr_src)
                 (itr_tgt)
                 (ths, tht, im_src, im_tgt, st_src, st_tgt, o, r_shared)
  .

  Definition sim_knot R0 R1 (RR: R0 -> R1 -> Prop):
    threads_src2 R0 -> threads_tgt R1 -> thread_id -> URA.car -> URA.car ->
    bool -> bool -> (prod bool (itree srcE R0)) -> (itree tgtE R1) -> shared -> Prop :=
    paco10 (fun r => pind10 (__sim_knot RR r) top10) bot10.

  Lemma __ksim_mon R0 R1 (RR: R0 -> R1 -> Prop):
    forall r r' (LE: r <10= r'), (__sim_knot RR r) <11= (__sim_knot RR r').
  Proof.
    ii. inv PR; try (econs; eauto; fail).
    { econs 2; eauto. i. specialize (KSIM tid0). des; eauto. right.
      esplits; eauto.
      i. specialize (KSIM1 H _ FAIR). des. esplits; eauto.
      i. specialize (KSIM2 H _ FAIR). des. esplits; eauto.
    }
    { econs 3; eauto. i. specialize (KSIM tid0). des; eauto. right.
      esplits; eauto.
      i. specialize (KSIM1 H). des. esplits; eauto.
      i. specialize (KSIM2 H). des. esplits; eauto. i. specialize (KSIM4 _ FAIR).
      des. esplits; eauto.
    }
  Qed.

  Lemma _ksim_mon R0 R1 (RR: R0 -> R1 -> Prop): forall r, monotone10 (__sim_knot RR r).
  Proof.
    ii. inv IN; try (econs; eauto; fail).
    { des. econs; eauto. }
    { des. econs; eauto. }
    { des. econs; eauto. }
  Qed.

  Lemma ksim_mon R0 R1 (RR: R0 -> R1 -> Prop): forall q, monotone10 (fun r => pind10 (__sim_knot RR r) q).
  Proof.
    ii. eapply pind10_mon_gen; eauto.
    ii. eapply __ksim_mon; eauto.
  Qed.

  Local Hint Constructors __sim_knot: core.
  Local Hint Unfold sim_knot: core.
  Local Hint Resolve __ksim_mon: paco.
  Local Hint Resolve _ksim_mon: paco.
  Local Hint Resolve ksim_mon: paco.

  Lemma ksim_reset_prog
        R0 R1 (RR: R0 -> R1 -> Prop)
        ths_src ths_tgt tid r_own r_ctx
        ssrc tgt shr
        ps0 pt0 ps1 pt1
        (KSIM: sim_knot RR ths_src ths_tgt tid r_own r_ctx ps1 pt1 ssrc tgt shr)
        (SRC: ps1 = true -> ps0 = true)
        (TGT: pt1 = true -> pt0 = true)
    :
    sim_knot RR ths_src ths_tgt tid r_own r_ctx ps0 pt0 ssrc tgt shr.
  Proof.
    revert_until RR. pcofix CIH. i.
    move KSIM before CIH. revert_until KSIM. punfold KSIM.
    pattern ths_src, ths_tgt, tid, r_own, r_ctx, ps1, pt1, ssrc, tgt, shr.
    revert ths_src ths_tgt tid r_own r_ctx ps1 pt1 ssrc tgt shr KSIM.
    eapply pind10_acc.
    intros rr DEC IH ths_src ths_tgt tid r_own r_ctx ps1 pt1 ssrc tgt shr KSIM. clear DEC.
    intros ps0 pt0 SRC TGT.
    eapply pind10_unfold in KSIM.
    2:{ eapply _ksim_mon. }
    inv KSIM.

    { pfold. eapply pind10_fold. econs; eauto. }

    { clear rr IH. pfold. eapply pind10_fold. eapply ksim_ret_cont; eauto. i.
      specialize (KSIM0 tid0). des; eauto. right.
      esplits; eauto.
      - i; hexploit KSIM2; clear KSIM2 KSIM3; eauto. i. des. esplits; eauto. i. eapply upaco10_mon_bot; eauto.
      - i; hexploit KSIM3; clear KSIM2 KSIM3; eauto. i. des. esplits; eauto.
        i. eapply upaco10_mon_bot; eauto.
    }

    { clear rr IH. pfold. eapply pind10_fold. eapply ksim_sync; eauto. i.
      specialize (KSIM0 tid0). des; eauto. right.
      esplits; eauto.
      - i; hexploit KSIM2; clear KSIM2 KSIM3; eauto. i. des. esplits; eauto. i. eapply upaco10_mon_bot; eauto.
      - i; hexploit KSIM3; clear KSIM2 KSIM3; eauto. i. des. esplits; eauto. i. specialize (H2 _ FAIR); des.
        esplits; eauto. i. eapply upaco10_mon_bot; eauto.
    }

    { des. pfold. eapply pind10_fold. eapply ksim_yieldL. esplits; eauto. split; ss.
      destruct KSIM1 as [KSIM1 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_tauL. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { des. pfold. eapply pind10_fold. eapply ksim_chooseL. esplits. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_putL. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_getL. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_tidL. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_UB. }

    { des. pfold. eapply pind10_fold. eapply ksim_fairL. esplits; eauto. split; ss.
      destruct KSIM1 as [KSIM1 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_tauR. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_chooseR. i. split; ss. specialize (KSIM0 x).
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_putR. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_getR. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_tidR. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_fairR. i. split; ss. specialize (KSIM0 _ FAIR).
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_observe. i. specialize (KSIM0 ret). pclearbot.
      right; eapply CIH; eauto.
    }

    { hexploit SRC; ss; i; clarify. hexploit TGT; ss; i; clarify.
      pfold. eapply pind10_fold. eapply ksim_progress. pclearbot.
      right; eapply CIH; eauto.
    }

  Qed.

  Lemma ksim_set_prog
        R0 R1 (RR: R0 -> R1 -> Prop)
        ths_src ths_tgt tid
        ssrc tgt shr
        (KSIM: sim_knot RR ths_src ths_tgt tid true true ssrc tgt shr)
    :
    forall ps pt, sim_knot RR ths_src ths_tgt tid ps pt ssrc tgt shr.
  Proof.
    revert_until RR. pcofix CIH. i.
    remember true as ps1 in KSIM at 1. remember true as pt1 in KSIM at 1.
    move KSIM before CIH. revert_until KSIM. punfold KSIM.
    eapply pind10_acc in KSIM.

    { instantiate (1:= (fun ths_src ths_tgt tid ps1 pt1 ssrc tgt shr =>
                          ps1 = true ->
                          pt1 = true ->
                          forall ps pt : bool,
                            paco10
                              (fun r0 => pind10 (__sim_knot RR r0) top8) r ths_src ths_tgt tid ps pt
                              ssrc tgt shr)) in KSIM; auto. }

    ss. clear ths_src ths_tgt tid ps1 pt1 ssrc tgt shr KSIM.
    intros rr DEC IH ths_src ths_tgt tid ps1 pt1 ssrc tgt shr KSIM. clear DEC.
    intros Eps1 Ept1 ps pt. clarify.
    eapply pind10_unfold in KSIM.
    2:{ eapply _ksim_mon. }
    inv KSIM.

    { pfold. eapply pind10_fold. econs; eauto. }

    { clear rr IH. pfold. eapply pind10_fold. eapply ksim_ret_cont; eauto. i.
      specialize (KSIM0 tid0). des; eauto. right.
      esplits; eauto.
      - i; hexploit KSIM2; clear KSIM2 KSIM3; eauto. i. eapply upaco10_mon_bot; eauto.
      - i; hexploit KSIM3; clear KSIM2 KSIM3; eauto. i. des. esplits; eauto.
        i. eapply upaco10_mon_bot; eauto.
    }

    { clear rr IH. pfold. eapply pind10_fold. eapply ksim_sync; eauto. i.
      specialize (KSIM0 tid0). des; eauto. right.
      esplits; eauto.
      - i; hexploit KSIM2; clear KSIM2 KSIM3; eauto. i. des. esplits; eauto. i. eapply upaco10_mon_bot; eauto.
      - i; hexploit KSIM3; clear KSIM2 KSIM3; eauto. i. des. esplits; eauto. i. specialize (H2 _ FAIR); des.
        esplits; eauto. i. eapply upaco10_mon_bot; eauto.
    }

    { des. pfold. eapply pind10_fold. eapply ksim_yieldL. esplits; eauto. split; ss.
      destruct KSIM1 as [KSIM1 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_tauL. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { des. pfold. eapply pind10_fold. eapply ksim_chooseL. esplits. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_putL. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_getL. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_tidL. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_UB. }

    { des. pfold. eapply pind10_fold. eapply ksim_fairL. esplits; eauto. split; ss.
      destruct KSIM1 as [KSIM1 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_tauR. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_chooseR. i. split; ss. specialize (KSIM0 x).
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_putR. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_getR. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_tidR. split; ss.
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_fairR. i. split; ss. specialize (KSIM0 _ FAIR).
      destruct KSIM0 as [KSIM0 IND]. hexploit IH; eauto. i. punfold H.
    }

    { pfold. eapply pind10_fold. eapply ksim_observe. i. specialize (KSIM0 ret). pclearbot.
      right; eapply CIH; eauto.
    }

    { pclearbot. eapply paco10_mon_bot; eauto. eapply ksim_reset_prog. eauto. all: auto. }

  Qed.



  Variable I: shared -> Prop.

  Definition local_sim_pick {R0 R1} (RR: R0 -> R1 -> Prop) src tgt tid w :=
    forall ths0 tht0 im_src0 im_tgt0 st_src0 st_tgt0 o0 w0
      (INV: I (ths0, tht0, im_src0, im_tgt0, st_src0, st_tgt0, o0, w0))
      (WORLD: world_le w w0)
      fs ft,
    forall im_tgt1 (FAIR: fair_update im_tgt0 im_tgt1 (sum_fmap_l (tids_fmap tid tht0))),
    exists im_src1 w1, (fair_update im_src0 im_src1 (sum_fmap_l (tids_fmap tid ths0))) /\
                    (world_le w0 w1) /\
                    (lsim
                       world_le
                       I
                       (local_RR world_le I RR tid)
                       tid
                       fs ft
                       src tgt
                       (ths0, tht0, im_src1, im_tgt1, st_src0, st_tgt0, o0, w1)).

  Definition local_sim_sync {R0 R1} (RR: R0 -> R1 -> Prop) src tgt tid w :=
    forall ths0 tht0 im_src0 im_tgt0 st_src0 st_tgt0 w0 o0
      (INV: I (ths0, tht0, im_src0, im_tgt0, st_src0, st_tgt0, o0, w0))
      (WORLD: world_le w w0)
      fs ft,
    forall im_tgt1 (FAIR: fair_update im_tgt0 im_tgt1 (sum_fmap_l (tids_fmap tid tht0))),
      (lsim
         world_le
         I
         (local_RR world_le I RR tid)
         tid
         fs ft
         (Vis (inl1 (inr1 Yield)) (fun _ => src))
         tgt
         (ths0, tht0, im_src0, im_tgt1, st_src0, st_tgt0, o0, w0)).

  Definition th_wf_pair {elt1 elt2} := @nm_wf_pair elt1 elt2.

  Lemma local_sim_pick_mon_world
        R0 R1 (RR: R0 -> R1 -> Prop) src tgt tid w0 w1
        (WORLD: world_le w0 w1)
        (LSIMP: local_sim_pick RR src tgt tid w0)
    :
    local_sim_pick RR src tgt tid w1.
  Proof.
    unfold local_sim_pick in *. i. hexploit LSIMP; eauto. etransitivity; eauto.
  Qed.

  Lemma th_wf_pair_pop_cases
        R0 R1
        (ths_src: threads_src2 R0)
        (ths_tgt: threads_tgt R1)
        (WF: th_wf_pair ths_src ths_tgt)
    :
    forall x, ((nm_pop x ths_src = None) /\ (nm_pop x ths_tgt = None)) \/
           (exists th_src th_tgt ths_src0 ths_tgt0,
               (nm_pop x ths_src = Some (th_src, ths_src0)) /\
                 (nm_pop x ths_tgt = Some (th_tgt, ths_tgt0)) /\
                 (th_wf_pair ths_src0 ths_tgt0)).
  Proof.
    eapply nm_wf_pair_pop_cases. eauto.
  Qed.


  Lemma proj_aux
        e tid tid0 elem
        (ths ths0 : NatMap.t e)
        (TH : Th.find (elt:=e) tid ths = None)
        (H : nm_pop tid0 ths = Some (elem, ths0))
    :
    NatSet.remove tid (NatSet.add tid (key_set ths)) = NatSet.add tid0 (key_set ths0).
  Proof.
    unfold NatSet.add, NatSet.remove in *. erewrite nm_rm_add_rm_eq. rewrite nm_find_none_rm_eq.
    2:{ eapply key_set_find_none1. auto. }
    erewrite <- key_set_pull_add_eq. erewrite <- nm_pop_res_is_add_eq; eauto.
  Qed.

  Lemma find_some_aux
        e tid0 tid1 elem0 elem1
        (ths ths0: NatMap.t e)
        (H : nm_pop tid0 ths = Some (elem0, ths0))
        (LSRC : Th.find (elt:=e) tid1 ths0 = Some elem1)
    :
    Th.find (elt:=e) tid1 ths = Some elem1.
  Proof.
    eapply nm_pop_res_is_rm_eq in H. rewrite <- H in LSRC. rewrite NatMapP.F.remove_o in LSRC. des_ifs.
  Qed.

  Lemma find_none_aux
        e tid0 elem0
        (ths ths0: NatMap.t e)
        (H : nm_pop tid0 ths = Some (elem0, ths0))
    :
    Th.find (elt:=e) tid0 ths0 = None.
  Proof.
    eapply nm_pop_res_is_rm_eq in H. rewrite <- H. apply nm_find_rm_eq.
  Qed.

  Lemma in_aux
        e tid tid0 elem0
        (ths ths0: NatMap.t e)
        (H : nm_pop tid0 ths = Some (elem0, ths0))
        (THSRC : Th.find (elt:=e) tid ths = None)
    :
    NatMap.In (elt:=()) tid0 (NatSet.remove tid (NatSet.add tid (key_set ths))).
  Proof.
    unfold NatSet.remove, NatSet.add in *. rewrite nm_find_none_rm_add_eq.
    eapply nm_pop_find_some in H. eapply key_set_find_some1 in H. rewrite NatMapP.F.in_find_iff. ii; clarify.
    eapply key_set_find_none1 in THSRC. auto.
  Qed.

  Lemma in_add_aux
        e tid tid0 elem elem0
        (ths ths0: NatMap.t e)
        (H : nm_pop tid0 (Th.add tid elem ths) = Some (elem0, ths0))
    :
    NatMap.In tid0 (NatSet.add tid (key_set ths)).
  Proof.
    eapply nm_pop_find_some in H. eapply NatMapP.F.in_find_iff. eapply key_set_find_some1 in H.
    rewrite key_set_pull_add_eq in H. unfold NatSet.add. rewrite H. ss.
  Qed.

  Lemma proj_add_aux
        e tid tid0 elem elem0
        (ths ths0 : NatMap.t e)
        (H : nm_pop tid0 (Th.add tid elem ths) = Some (elem0, ths0))
    :
    NatSet.add tid (key_set ths) = NatSet.add tid0 (key_set ths0).
  Proof.
    eapply nm_pop_res_is_add_eq in H. unfold NatSet.add in *. erewrite <- ! key_set_pull_add_eq. erewrite H. eauto.
  Qed.

  Lemma find_some_neq_aux
        e tid tid0 tid1 elem0 elem1 elem2
        (ths ths0: NatMap.t e)
        (H : nm_pop tid0 (Th.add tid elem0 ths) = Some (elem1, ths0))
        (n0 : tid <> tid1)
        (LSRC : Th.find (elt:=e) tid1 ths0 = Some elem2)
    :
    Th.find (elt:=e) tid1 ths = Some elem2.
  Proof.
    eapply nm_pop_res_is_rm_eq in H. rewrite <- H in LSRC. rewrite NatMapP.F.remove_o in LSRC. des_ifs.
    rewrite nm_find_add_neq in LSRC; auto.
  Qed.

  Lemma find_some_neq_simpl_aux
        e tid tid0 elem elem0
        (ths ths0 : NatMap.t e)
        (H : nm_pop tid0 (Th.add tid elem ths) = Some (elem0, ths0))
        (n : tid <> tid0)
    :
    Th.find (elt:=e) tid0 ths = Some elem0.
  Proof.
    eapply nm_pop_find_some in H. rewrite nm_find_add_neq in H; auto.
  Qed.


  Variable St: wf_tgt.(T) -> wf_tgt.(T).
  Hypothesis lt_succ_diag_r_t: forall (t: wf_tgt.(T)), wf_tgt.(lt) t (St t).

  Lemma lsim_implies_ksim
        R0 R1 (RR: R0 -> R1 -> Prop)
        (ths_src: threads_src2 R0)
        (ths_tgt: threads_tgt R1)
        tid
        (THSRC: Th.find tid ths_src = None)
        (THTGT: Th.find tid ths_tgt = None)
        (WF: th_wf_pair ths_src ths_tgt)
        sf src tgt
        (st_src: state_src) (st_tgt: state_tgt)
        gps gpt
        (LSIM: forall im_tgt, exists im_src o w,
            (<<LSIM:
              forall im_tgt0
                (FAIR: fair_update im_tgt im_tgt0 (sum_fmap_l (tids_fmap tid (NatSet.add tid (key_set ths_tgt))))),
              exists im_src0 w0,
                (fair_update im_src im_src0 (sum_fmap_l (tids_fmap tid (NatSet.add tid (key_set ths_src))))) /\
                  (world_le w w0) /\
                  (lsim world_le I (local_RR world_le I RR tid) tid gps gpt src tgt
                        (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt),
                          im_src0, im_tgt0, st_src, st_tgt, o, w0))>>) /\
              (<<LOCAL: forall tid sf (src: itree srcE R0) (tgt: itree tgtE R1)
                          (LSRC: Th.find tid ths_src = Some (sf, src))
                          (LTGT: Th.find tid ths_tgt = Some tgt),
                  ((sf = true) -> (local_sim_sync RR src tgt tid w)) /\
                    ((sf = false) -> (local_sim_pick RR src tgt tid w))>>))
    :
    forall im_tgt, exists im_src o w,
      sim_knot RR ths_src ths_tgt tid gps gpt (sf, src) tgt
               (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt),
                 im_src, im_tgt, st_src, st_tgt, o, w).
  Proof.
    ii. remember (fun i => St (im_tgt i)) as im_tgt1. specialize (LSIM im_tgt1). des.
    assert (FAIR: fair_update im_tgt1 im_tgt (sum_fmap_l (tids_fmap tid (NatSet.add tid (key_set ths_tgt))))).
    { rewrite Heqim_tgt1. unfold fair_update. i. des_ifs. right; auto. }
    specialize (LSIM0 im_tgt FAIR). des. clear LSIM0 Heqim_tgt1 FAIR im_tgt1.
    clear im_src; rename im_src0 into im_src.
    rename LOCAL into LOCAL0.
    assert (LOCAL: forall tid sf (src: itree srcE R0) (tgt: itree tgtE R1)
                     (LSRC: Th.find tid ths_src = Some (sf, src))
                     (LTGT: Th.find tid ths_tgt = Some tgt),
               ((sf = true) -> (local_sim_sync RR src tgt tid w0)) /\
                 ((sf = false) -> (local_sim_pick RR src tgt tid w0))).
    { i. specialize (LOCAL0 tid0 sf0 src0 tgt0 LSRC LTGT). des. split; i.
      - apply LOCAL0 in H; clear LOCAL0 LOCAL1. unfold local_sim_sync in *.
        i. eapply H; eauto. etransitivity; eauto.
      - apply LOCAL1 in H; clear LOCAL0 LOCAL1. unfold local_sim_pick in *.
        i. eapply H; eauto. etransitivity; eauto.
    }
    clear LSIM1 LOCAL0. clear w; rename w0 into w. rename LSIM2 into LSIM. move LOCAL before RR.
    exists im_src, o, w.

    revert_until RR. pcofix CIH. i.
    match goal with
    | LSIM: lsim _ _ ?_LRR tid _ _ _ _ ?_shr |- _ => remember _LRR as LRR; remember _shr as shr
    end.
    setoid_rewrite <- Heqshr.
    punfold LSIM.
    move LSIM before LOCAL. revert_until LSIM.
    eapply pind5_acc in LSIM.

    { instantiate (1:= (fun gps gpt src tgt shr =>
                          Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None ->
                          Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None ->
                          th_wf_pair ths_src ths_tgt ->
                          forall (sf : bool) (st_src : state_src) (st_tgt : state_tgt) (o : T wf_src)
                            (im_tgt : imap (ModSimStutter.ident_tgt _ident_tgt) wf_tgt) (im_src : imap (id_sum thread_id _ident_src) wf_src),
                            LRR = local_RR world_le I RR tid ->
                            shr = (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), im_src, im_tgt, st_src, st_tgt, o, w) ->
                            paco10 (fun r0 => pind10 (__sim_knot RR r0) top8) r ths_src ths_tgt tid gps gpt (sf, src) tgt shr)) in LSIM; auto. }

    ss. clear gps gpt src tgt shr LSIM.
    intros rr DEC IH gps gpt src tgt shr LSIM. clear DEC.
    intros THSRC THTGT WF sf st_src st_tgt o im_tgt im_src ELRR Eshr.
    eapply pind5_unfold in LSIM.
    2:{ eapply _lsim_mon. }
    inv LSIM.

    { clear IH rr. unfold local_RR in LSIM0. des. clarify.
      destruct (Th.is_empty ths_src) eqn:EMPS.
      { destruct (Th.is_empty ths_tgt) eqn:EMPT.
        { pfold. eapply pind10_fold. econs 1; eauto. }
        { exfalso. erewrite nm_wf_pair_is_empty in EMPS; eauto. rewrite EMPT in EMPS. ss. }
      }
      { destruct (Th.is_empty ths_tgt) eqn:EMPT.
        { exfalso. erewrite nm_wf_pair_is_empty in EMPS; eauto. rewrite EMPT in EMPS. ss. }
        { pfold. eapply pind10_fold. econs 2; eauto. i.
          hexploit th_wf_pair_pop_cases.
          { eapply WF. }
          i. instantiate (1:=tid0) in H. des; auto.
          right. destruct th_src as [sf0 th_src].
          assert (FINDS: Th.find tid0 ths_src = Some (sf0, th_src)).
          { eapply nm_pop_find_some; eauto. }
          assert (FINDT: Th.find tid0 ths_tgt = Some (th_tgt)).
          { eapply nm_pop_find_some; eauto. }
          exists sf0, th_src, ths_src0, th_tgt, ths_tgt0.
          splits; auto.
          - i; clarify.
            hexploit LOCAL. eapply FINDS. eapply FINDT. i; des.
            hexploit H2; clear H2 H3; ss. i. unfold local_sim_sync in H2.
            assert (PROJS: NatSet.remove tid (NatSet.add tid (key_set ths_src)) = NatSet.add tid0 (key_set ths_src0)).
            { eapply proj_aux; eauto. }
            assert (PROJT: NatSet.remove tid (NatSet.add tid (key_set ths_tgt)) = NatSet.add tid0 (key_set ths_tgt0)).
            { eapply proj_aux; eauto. }
            ss. rewrite PROJS, PROJT. right. eapply CIH.
            { i. hexploit LOCAL.
              eapply find_some_aux; eauto. eapply find_some_aux; eauto.
              i; des. split.
              - intro SYNC. eapply H3 in SYNC. ii. unfold local_sim_sync in SYNC.
                assert (WORLD1: world_le w w0).
                { etransitivity; eauto. }
                specialize (SYNC _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
              - intro PICK. eapply H4 in PICK. ii. unfold local_sim_pick in PICK.
                assert (WORLD1: world_le w w0).
                { etransitivity; eauto. }
                specialize (PICK _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
            }
            eapply find_none_aux; eauto. eapply find_none_aux; eauto.
            auto.
            rewrite <- PROJS, <- PROJT. eapply H2; eauto.

          - i. clarify.
            hexploit LOCAL. eapply FINDS. eapply FINDT. i; des.
            hexploit H3; clear H2 H3; ss. i. unfold local_sim_pick in H2.
            assert (PROJS: NatSet.remove tid (NatSet.add tid (key_set ths_src)) = NatSet.add tid0 (key_set ths_src0)).
            { eapply proj_aux; eauto. }
            assert (PROJT: NatSet.remove tid (NatSet.add tid (key_set ths_tgt)) = NatSet.add tid0 (key_set ths_tgt0)).
            { eapply proj_aux; eauto. }
            hexploit H2; eauto.
            i; des. esplits; eauto. i.
            rewrite PROJS, PROJT. right. eapply CIH.
            { i. hexploit LOCAL.
              eapply find_some_aux; eauto. eapply find_some_aux; eauto.
              i; des. split.
              - intro SYNC. eapply H6 in SYNC. ii. unfold local_sim_sync in SYNC.
                assert (WORLD1: world_le w w0).
                { do 2 (etransitivity; eauto). }
                specialize (SYNC _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
              - intro PICK. eapply H7 in PICK. ii. unfold local_sim_pick in PICK.
                assert (WORLD1: world_le w w0).
                { do 2 (etransitivity; eauto). }
                specialize (PICK _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
            }
            eapply find_none_aux; eauto. eapply find_none_aux; eauto.
            auto.
            rewrite <- PROJS, <- PROJT. eapply lsim_set_prog. eauto.
        }
      }
    }

    { clarify. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. eapply ksim_tauL. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { des. clarify. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_chooseL. exists x. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_putL. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_getL. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_tidL. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify. pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_UB. }

    { des. clarify. destruct LSIM as [LSIM IND]. clear LSIM.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_fairL.
      exists im_src1. splits; eauto. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. eapply ksim_tauR. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_chooseR. split; ss.
      specialize (LSIM0 x). destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_putR. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_getR. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_tidR. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_fairR. split; ss.
      specialize (LSIM0 im_tgt0 FAIR). des. destruct LSIM0 as [LSIM0 IND]. clear LSIM0.
      hexploit IH; eauto. i. punfold H.
    }

    { clear IH rr. clarify. rewrite ! bind_trigger.
      pfold. eapply pind10_fold. eapply ksim_observe. i.
      specialize (LSIM0 ret). pclearbot. right. eapply CIH; auto.
    }

    { clear IH rr. clarify. rewrite ! bind_trigger.
      pfold. eapply pind10_fold. eapply ksim_sync; eauto. i.
      assert (WF0: th_wf_pair (Th.add tid (true, ktr_src ()) ths_src) (Th.add tid (ktr_tgt ()) ths_tgt)).
      { unfold th_wf_pair, nm_wf_pair in *. rewrite ! key_set_pull_add_eq. rewrite WF. reflexivity. }
      hexploit th_wf_pair_pop_cases.
      { eapply WF0. }
      i. instantiate (1:=tid0) in H. des; auto.
      right. destruct th_src as [sf0 th_src].
      exists sf0, th_src, ths_src0, th_tgt, ths_tgt0.
      splits; auto.
      - i; clarify. esplits; eauto. i.
        assert (PROJS: (NatSet.add tid (key_set ths_src)) = (NatSet.add tid0 (key_set ths_src0))).
        { eapply proj_add_aux; eauto. }
        assert (PROJT: (NatSet.add tid (key_set ths_tgt)) = (NatSet.add tid0 (key_set ths_tgt0))).
        { eapply proj_add_aux; eauto. }
        rewrite PROJS, PROJT.
        destruct (tid_dec tid tid0) eqn:TID; subst.
        { rename tid0 into tid.
          assert (ths_tgt0 = ths_tgt /\ th_tgt = (ktr_tgt ())).
          { hexploit nm_pop_find_none_add_same_eq. eapply THTGT. eauto. i; des; clarify. }
          assert (ths_src0 = ths_src /\ th_src = (ktr_src ())).
          { hexploit nm_pop_find_none_add_same_eq. eapply THSRC. eauto. i; des; clarify. }
          des; clarify. right. eapply CIH; eauto.
          { i. hexploit LOCAL. 1,2: eauto. i; des. split.
            - intro SYNC. eapply H2 in SYNC. ii. unfold local_sim_sync in SYNC.
              assert (WORLD1: world_le w w0).
              { etransitivity; eauto. }
              specialize (SYNC _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
            - intro PICK. eapply H3 in PICK. ii. unfold local_sim_pick in PICK.
              assert (WORLD1: world_le w w0).
              { etransitivity; eauto. }
              specialize (PICK _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
          }
          hexploit LSIM0; eauto. reflexivity.
          i. pclearbot.
          match goal with
          | |- lsim _ _ _ tid _ _ ?_itr _ _ => assert (_itr = (x <- trigger Yield;; ktr_src x))
          end.
          { rewrite bind_trigger. f_equal. f_equal. extensionality x. destruct x. ss. }
          rewrite H3. eapply lsim_set_prog. auto.
        }
        right. eapply CIH.
        { i. destruct (tid_dec tid tid1) eqn:TID2; subst.
          { rename tid1 into tid.
            pose nm_pop_neq_find_some_eq. dup H. eapply e in H2; eauto. dup H0. eapply e in H3; eauto.
            inv H2. split; i; ss. clear H2.
            ii. hexploit LSIM0. eapply INV0. auto. eauto.
            i. pclearbot.
            match goal with
            | |- lsim _ _ _ tid _ _ ?_itr _ _ => assert (_itr = (x <- trigger Yield;; ktr_src x))
            end.
            { rewrite bind_trigger. f_equal. f_equal. extensionality x. destruct x. ss. }
            rewrite H3. eapply lsim_set_prog. auto.
          }
          { hexploit LOCAL.
            eapply find_some_neq_aux; eauto. eapply find_some_neq_aux; eauto.
            i; des. split.
            - intro SYNC. eapply H2 in SYNC. ii. unfold local_sim_sync in SYNC.
              assert (WORLD1: world_le w w0).
              { etransitivity; eauto. }
              specialize (SYNC _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
            - intro PICK. eapply H3 in PICK. ii. unfold local_sim_pick in PICK.
              assert (WORLD1: world_le w w0).
              { etransitivity; eauto. }
              specialize (PICK _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
          }
        }
        eapply find_none_aux; eauto. eapply find_none_aux; eauto.
        auto.
        hexploit LOCAL.
        eapply find_some_neq_simpl_aux; eauto. eapply find_some_neq_simpl_aux; eauto.
        i; des. hexploit H2; ss.
        intro SYNC. unfold local_sim_sync in SYNC.
        hexploit SYNC.
        1,2,3: eauto.
        i. rewrite <- PROJS, <- PROJT. eauto.

      - i; clarify. destruct (tid_dec tid tid0) eqn:TID1.
        { clarify. exfalso. hexploit nm_pop_find_none_add_same_equal. eapply THSRC. eauto. i; des; clarify. }
        esplits; eauto. i.
        hexploit LOCAL.
        eapply find_some_neq_simpl_aux; eauto. eapply find_some_neq_simpl_aux; eauto.
        i; des. hexploit H3; ss. intro PICK. unfold local_sim_pick in PICK. hexploit PICK.
        1,3: eauto. auto.
        i; des. esplits; eauto.
        assert (PROJS: (NatSet.add tid (key_set ths_src)) = (NatSet.add tid0 (key_set ths_src0))).
        { eapply proj_add_aux; eauto. }
        assert (PROJT: (NatSet.add tid (key_set ths_tgt)) = (NatSet.add tid0 (key_set ths_tgt0))).
        { eapply proj_add_aux; eauto. }
        rewrite PROJS, PROJT. right. eapply CIH.
        { i. destruct (tid_dec tid tid1) eqn:TID2; subst.
          { rename tid1 into tid.
            pose nm_pop_neq_find_some_eq. dup H. eapply e in H7; eauto. dup H0. eapply e in H8; eauto.
            inv H7. split; i; ss. clear H2.
            ii. hexploit LSIM0. eapply INV0.
            { etransitivity; eauto. }
            eauto.
            i. pclearbot.
            match goal with
            | |- lsim _ _ _ tid _ _ ?_itr _ _ => assert (_itr = (x <- trigger Yield;; ktr_src x))
            end.
            { rewrite bind_trigger. f_equal. f_equal. extensionality x. destruct x. ss. }
            rewrite H8. eapply lsim_set_prog. auto.
          }
          { hexploit LOCAL.
            eapply find_some_neq_aux; eauto. eapply find_some_neq_aux; eauto.
            i; des. split.
            - intro SYNC. eapply H7 in SYNC. ii. unfold local_sim_sync in SYNC.
              assert (WORLD1: world_le w w2).
              { etransitivity. 2:eauto. etransitivity; eauto. }
              specialize (SYNC _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
            - clear PICK; intro PICK. eapply H8 in PICK. ii. unfold local_sim_pick in PICK.
              assert (WORLD1: world_le w w2).
              { etransitivity. 2:eauto. etransitivity; eauto. }
              specialize (PICK _ _ _ _ _ _ _ _ INV0 WORLD1 fs ft _ FAIR0). auto.
          }
        }
        eapply find_none_aux; eauto. eapply find_none_aux; eauto.
        auto.
        rewrite <- PROJS, <- PROJT. eapply lsim_set_prog. eauto.
    }

    { des. clarify. destruct LSIM as [LSIM0 IND]. clear LSIM0.
      pfold. eapply pind10_fold. rewrite bind_trigger. eapply ksim_yieldL.
      esplits; eauto. split; ss.
      hexploit IH; eauto. i. punfold H.
    }

    { clarify. pclearbot. pfold. eapply pind10_fold. eapply ksim_progress. right. eapply CIH; eauto. }

  Qed.


  (* Local Opaque Th.add Th.remove nm_pop. *)

  Lemma gsim_ret_emp
        R0 R1 (RR: R0 -> R1 -> Prop)
        (r : forall x x0 : Type,
            (x -> x0 -> Prop) -> bool -> (@imap ident_src wf_src) -> bool -> (@imap ident_tgt wf_tgt) -> _ -> _ -> Prop)
        (ths_src : threads_src2 R0) (ths_tgt : threads_tgt R1)
        tid ps pt
        (THSRC : Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None)
        (THTGT : Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None)
        (WF : th_wf_pair ths_src ths_tgt)
        (st_src : state_src) (st_tgt : state_tgt)
        (mt : @imap ident_tgt wf_tgt)
        (ms : @imap ident_src wf_src)
        (r_src : R0)
        (r_tgt : R1)
        (RET : RR r_src r_tgt)
        (NILS : Th.is_empty (elt:=bool * thread _ident_src (sE state_src) R0) ths_src = true)
        (NILT : Th.is_empty (elt:=thread _ident_tgt (sE state_tgt) R1) ths_tgt = true)
    :
    gpaco9 (_sim (wft:=wf_tgt)) (cpn9 (_sim (wft:=wf_tgt))) bot9 r R0 R1 RR ps ms pt mt
           (interp_all st_src (Th.add tid (Ret r_src) (nm_proj_v2 ths_src)) tid)
           (interp_all st_tgt (Th.add tid (Ret r_tgt) ths_tgt) tid).
  Proof.
    unfold interp_all. erewrite ! unfold_interp_sched_nondet_Some.
    2:{ instantiate (1:= Ret r_tgt). rewrite nm_find_add_eq; auto. }
    2:{ instantiate (1:= Ret r_src). rewrite nm_find_add_eq; auto. }
    rewrite ! interp_thread_ret. rewrite ! bind_ret_l.
    assert (EMPS: NatMap.is_empty (NatSet.remove tid (key_set (Th.add tid (Ret r_src) (nm_proj_v2 ths_src)))) = true).
    { apply NatMap.is_empty_2 in NILS. apply NatMap.is_empty_1. rewrite key_set_pull_add_eq. unfold NatSet.remove.
      rewrite nm_find_none_rm_add_eq; auto. do 2 apply nm_map_empty1. auto.
      unfold key_set, nm_proj_v2. rewrite 2 NatMapP.F.map_o. rewrite THSRC. ss. }
    assert (EMPT: NatMap.is_empty (NatSet.remove tid (key_set (Th.add tid (Ret r_tgt) ths_tgt))) = true).
    { apply NatMap.is_empty_2 in NILT. apply NatMap.is_empty_1. rewrite key_set_pull_add_eq. unfold NatSet.remove.
      rewrite nm_find_none_rm_add_eq; auto. do 1 apply nm_map_empty1. auto.
      unfold key_set. rewrite 1 NatMapP.F.map_o. rewrite THTGT. ss. }
    rewrite EMPS, EMPT. rewrite ! interp_sched_ret. rewrite ! interp_state_tau. rewrite ! interp_state_ret.
    guclo sim_indC_spec. eapply sim_indC_tauL. guclo sim_indC_spec. eapply sim_indC_tauR.
    guclo sim_indC_spec. eapply sim_indC_ret. auto.
  Qed.

  Lemma proj_aux2
        e tid tid0 elem elem0
        (ths ths0 : NatMap.t e)
        (TH : Th.find (elt:=e) tid ths = None)
        (H : nm_pop tid0 ths = Some (elem, ths0))
    :
    Th.remove tid (Th.add tid elem0 ths) = Th.add tid0 elem ths0.
  Proof.
    rewrite nm_rm_add_rm_eq. rewrite nm_find_none_rm_eq; auto. apply nm_pop_res_is_add_eq in H. auto.
  Qed.

  Lemma kgsim_ret_cont
        R0 R1 (RR : R0 -> R1 -> Prop)
        (r : forall x x0 : Type,
            (x -> x0 -> Prop) -> bool -> (@imap ident_src wf_src) -> bool -> (@imap ident_tgt wf_tgt) -> _ -> _ -> Prop)
        (CIH : forall (ths_src : threads_src2 R0) (ths_tgt : threads_tgt R1) (tid : Th.key),
            Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None ->
            Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None ->
            th_wf_pair ths_src ths_tgt ->
            forall (sf : bool) (src : thread _ident_src (sE state_src) R0)
              (tgt : thread _ident_tgt (sE state_tgt) R1) (st_src : state_src)
              (st_tgt : state_tgt) (ps pt : bool) (o : T wf_src) (w : world)
              (mt : imap ident_tgt wf_tgt) (ms : imap ident_src wf_src),
              sim_knot RR ths_src ths_tgt tid ps pt (sf, src) tgt
                       (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), ms, mt, st_src,
                         st_tgt, o, w) ->
              r R0 R1 RR ps ms pt mt (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid)
                (interp_all st_tgt (Th.add tid tgt ths_tgt) tid))
        (o : T wf_src) ps
        (IHo : (ps = true) \/
                 (forall y : T wf_src,
                     lt wf_src y o ->
                     forall (ths_src : threads_src2 R0) (ths_tgt : threads_tgt R1) (tid : Th.key),
                       Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None ->
                       Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None ->
                       th_wf_pair ths_src ths_tgt ->
                       forall (sf : bool) (src : thread _ident_src (sE state_src) R0)
                         (tgt : thread _ident_tgt (sE state_tgt) R1) (st_src : state_src)
                         (st_tgt : state_tgt) (ps pt : bool) (w : world) (mt : imap ident_tgt wf_tgt)
                         (ms : imap ident_src wf_src),
                         sim_knot RR ths_src ths_tgt tid ps pt (sf, src) tgt
                                  (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), ms, mt, st_src,
                                    st_tgt, y, w) ->
                         gpaco9 (_sim (wft:=wf_tgt)) (cpn9 (_sim (wft:=wf_tgt))) bot9 r R0 R1 RR ps ms pt mt
                                (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid)
                                (interp_all st_tgt (Th.add tid tgt ths_tgt) tid)))
        (ths_src : threads_src2 R0) (ths_tgt : threads_tgt R1)
        tid pt
        (THSRC : Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None)
        (THTGT : Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None)
        (WF : th_wf_pair ths_src ths_tgt)
        (st_src : state_src) (st_tgt : state_tgt)
        w mt ms (r_src : R0) (r_tgt : R1) o1 w1
        (WORLD : world_le w w1)
        (STUTTER : lt wf_src o1 o)
        (RET : RR r_src r_tgt)
        (NNILS : Th.is_empty (elt:=bool * thread _ident_src (sE state_src) R0) ths_src = false)
        (NNILT : Th.is_empty (elt:=thread _ident_tgt (sE state_tgt) R1) ths_tgt = false)
        (KSIM0 : forall tid0 : NatMap.key,
            nm_pop tid0 ths_src = None /\ nm_pop tid0 ths_tgt = None \/
              (exists
                  (b : bool) (th_src : thread _ident_src (sE state_src) R0)
                  (thsl0 : NatMap.t (bool * thread _ident_src (sE state_src) R0))
                  (th_tgt : thread _ident_tgt (sE state_tgt) R1) (thsr0 : threads_tgt R1),
                  nm_pop tid0 ths_src = Some (b, th_src, thsl0) /\
                    nm_pop tid0 ths_tgt = Some (th_tgt, thsr0) /\
                    (b = true ->
                     forall im_tgt0 : imap ident_tgt wf_tgt,
                       fair_update mt im_tgt0
                                   (sum_fmap_l
                                      (tids_fmap tid0 (NatSet.remove tid (NatSet.add tid (key_set ths_tgt))))) ->
                       forall ps pt : bool,
                         upaco10 (fun r => pind10 (__sim_knot RR r) top8) bot8 thsl0 thsr0 tid0 ps pt
                                (b, Vis ((|Yield)|)%sum (fun _ : () => th_src)) th_tgt
                                (NatSet.remove tid (NatSet.add tid (key_set ths_src)),
                                  NatSet.remove tid (NatSet.add tid (key_set ths_tgt)), ms, im_tgt0, st_src,
                                  st_tgt, o1, w1)) /\
                    (b = false ->
                     forall im_tgt0 : imap ident_tgt wf_tgt,
                       fair_update mt im_tgt0
                                   (sum_fmap_l
                                      (tids_fmap tid0 (NatSet.remove tid (NatSet.add tid (key_set ths_tgt))))) ->
                       exists (im_src0 : imap ident_src wf_src) w2,
                         fair_update ms im_src0
                                     (sum_fmap_l
                                        (tids_fmap tid0 (NatSet.remove tid (NatSet.add tid (key_set ths_src))))) /\
                           (world_le w1 w2) /\
                           (forall ps pt : bool,
                               upaco10 (fun r => pind10 (__sim_knot RR r) top8) bot8 thsl0 thsr0 tid0 ps pt
                                      (b, th_src) th_tgt
                                      (NatSet.remove tid (NatSet.add tid (key_set ths_src)),
                                        NatSet.remove tid (NatSet.add tid (key_set ths_tgt)), im_src0, im_tgt0,
                                        st_src, st_tgt, o1, w2)))))
    :
    gpaco9 (_sim (wft:=wf_tgt)) (cpn9 (_sim (wft:=wf_tgt))) bot9 r R0 R1 RR ps ms pt mt
           (interp_all st_src (Th.add tid (Ret r_src) (nm_proj_v2 ths_src)) tid)
           (interp_all st_tgt (Th.add tid (Ret r_tgt) ths_tgt) tid).
  Proof.
    unfold interp_all. erewrite ! unfold_interp_sched_nondet_Some; eauto using nm_find_add_eq.
    rewrite ! interp_thread_ret. rewrite ! bind_ret_l.
    assert (EMPS: NatMap.is_empty (NatSet.remove tid (key_set (Th.add tid (Ret r_src) (nm_proj_v2 ths_src)))) = false).
    { clear KSIM0.
      rewrite key_set_pull_add_eq. unfold NatSet.remove.
      rewrite nm_find_none_rm_add_eq; auto.
      2:{ unfold key_set, nm_proj_v2. rewrite 2 NatMapP.F.map_o. rewrite THSRC. ss. }
      match goal with | |- ?lhs = _ => destruct lhs eqn:CASE; ss end.
      apply NatMap.is_empty_2 in CASE. do 2 apply nm_map_empty2 in CASE.
      apply NatMap.is_empty_1 in CASE. clarify. }
    assert (EMPT: NatMap.is_empty (NatSet.remove tid (key_set (Th.add tid (Ret r_tgt) ths_tgt))) = false).
    { clear KSIM0.
      rewrite key_set_pull_add_eq. unfold NatSet.remove.
      rewrite nm_find_none_rm_add_eq; auto.
      2:{ unfold key_set. rewrite 1 NatMapP.F.map_o. rewrite THTGT. ss. }
      match goal with | |- ?lhs = _ => destruct lhs eqn:CASE; ss end.
      apply NatMap.is_empty_2 in CASE. do 1 apply nm_map_empty2 in CASE.
      apply NatMap.is_empty_1 in CASE. clarify. }
    rewrite EMPS, EMPT; clear EMPS EMPT.
    match goal with
    | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ ?_src_temp _ => remember _src_temp as src_temp eqn:TEMP
    end.
    rewrite ! interp_state_tau. guclo sim_indC_spec. eapply sim_indC_tauR.
    rewrite bind_trigger. rewrite interp_sched_vis. ss.
    rewrite interp_state_vis. rewrite <- ! bind_trigger.
    guclo sim_indC_spec. eapply sim_indC_chooseR. intro tid0.
    rewrite interp_state_tau.
    do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
    specialize (KSIM0 tid0). revert IHo. des; i.
    { assert (POPT: nm_pop tid0 (NatSet.remove tid (key_set (Th.add tid (Ret r_tgt) ths_tgt))) = None).
      { rewrite key_set_pull_add_eq. unfold NatSet.remove. rewrite nm_find_none_rm_add_eq.
        eapply nm_pop_none_map1; auto. unfold key_set. rewrite NatMapP.F.map_o. rewrite THTGT. ss. }
      rewrite POPT; clear POPT.
      rewrite bind_trigger. rewrite interp_sched_vis. ss. rewrite interp_state_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_chooseR. intro x; destruct x. }
    assert (POPT: nm_pop tid0 (NatSet.remove tid (key_set (Th.add tid (Ret r_tgt) ths_tgt))) = Some (tt, key_set thsr0)).
    { rewrite key_set_pull_add_eq. unfold key_set. unfold NatSet.remove. rewrite nm_find_none_rm_add_eq.
      eapply nm_pop_some_map1 in KSIM1. erewrite KSIM1. ss. rewrite NatMapP.F.map_o. rewrite THTGT. ss. }
    rewrite POPT; clear POPT.
    rewrite bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis. rewrite <- bind_trigger. ss.
    guclo sim_indC_spec. eapply sim_indC_fairR. i. rewrite interp_sched_tau. rewrite 2 interp_state_tau.
    do 3 (guclo sim_indC_spec; eapply sim_indC_tauR).
    destruct b.

    - hexploit KSIM2; clear KSIM2 KSIM3; ss.
      assert (FMT: tids_fmap tid0 (NatSet.remove tid (NatSet.add tid (key_set ths_tgt))) = tids_fmap tid0 (key_set thsr0)).
      { unfold NatSet.remove, NatSet.add. rewrite nm_find_none_rm_add_eq.
        2:{ unfold key_set. rewrite NatMapP.F.map_o. rewrite THTGT. ss. }
        apply nm_pop_res_is_rm_eq in KSIM1. rewrite <- KSIM1.
        rewrite key_set_pull_rm_eq. eapply tids_fmap_rm_same_eq.
      }
      rewrite FMT. eauto. i; pclearbot.
      assert (CHANGE: src_temp = interp_all st_src (Th.add tid0 (Vis ((|Yield)|)%sum (fun _ : () => th_src)) (nm_proj_v2 thsl0)) tid0).
      { unfold interp_all. erewrite unfold_interp_sched_nondet_Some; eauto using nm_find_add_eq.
        rewrite interp_thread_vis_yield. ired. rewrite TEMP.
        assert (RA: Th.remove tid (Th.add tid (Ret r_src) (nm_proj_v2 ths_src)) = nm_proj_v2 ths_src).
        { rewrite nm_find_none_rm_add_eq; auto. unfold nm_proj_v2. rewrite NatMapP.F.map_o. rewrite THSRC. ss. }
        rewrite ! RA.
        assert (RA1: Th.add tid0 th_src (Th.add tid0 (Vis ((|Yield)|)%sum (fun _ : () => th_src)) (nm_proj_v2 thsl0)) = nm_proj_v2 ths_src).
        { rewrite nm_add_add_eq. unfold nm_proj_v2. replace th_src with (snd (true, th_src)); auto.
          rewrite nm_map_add_comm_eq. f_equal. apply nm_pop_res_is_add_eq in KSIM0. auto. }
        rewrite ! RA1.
        assert (RA2: NatSet.remove tid (key_set (Th.add tid (Ret r_src) (nm_proj_v2 ths_src))) = key_set (nm_proj_v2 ths_src)).
        { rewrite key_set_pull_add_eq. unfold NatSet.remove, nm_proj_v2, key_set. rewrite nm_find_none_rm_add_eq; auto.
          rewrite 2 NatMapP.F.map_o. rewrite THSRC. ss. }
        rewrite RA2.
        assert (RA3: (NatSet.add tid0 (NatSet.remove tid0 (key_set (Th.add tid0 (Vis ((|Yield)|)%sum (fun _ : () => th_src)) (nm_proj_v2 thsl0))))) = key_set (nm_proj_v2 ths_src)).
        { rewrite key_set_pull_add_eq. unfold NatSet.add, NatSet.remove, nm_proj_v2, key_set.
          rewrite nm_add_rm_eq. rewrite nm_add_add_eq. apply nm_pop_res_is_add_eq in KSIM0. rewrite KSIM0.
          rewrite <- 2 nm_map_add_comm_eq. ss. }
        rewrite RA3. ss.
      }
      rewrite CHANGE; clear CHANGE.
      match goal with
      | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ _ ?_tgt => replace _tgt with (interp_all st_tgt (Th.add tid0 th_tgt thsr0) tid0)
      end.
      2:{ assert (PROJT: Th.remove tid (Th.add tid (Ret r_tgt) ths_tgt) = Th.add tid0 th_tgt thsr0).
          { eapply proj_aux2; eauto. }
          rewrite PROJT. unfold interp_all.
          replace (NatSet.remove tid0 (key_set (Th.add tid0 th_tgt thsr0))) with (key_set thsr0); auto.
          rewrite key_set_pull_add_eq. unfold NatSet.remove. rewrite nm_find_none_rm_add_eq; auto.
          apply key_set_find_none1. eapply nm_pop_res_find_none; eauto.
      }
      assert (PROJS: NatSet.remove tid (NatSet.add tid (key_set ths_src)) = NatSet.add tid0 (key_set thsl0)).
      { eapply proj_aux; eauto. }
      assert (PROJT: NatSet.remove tid (NatSet.add tid (key_set ths_tgt)) = NatSet.add tid0 (key_set thsr0)).
      { eapply proj_aux; eauto. }
      des.
      + subst. gfold. eapply sim_progress; auto. right. eapply CIH.
        eapply find_none_aux; eauto. eapply find_none_aux; eauto.
        { hexploit nm_wf_pair_pop_cases; eauto. instantiate (1:=tid0). i; des; clarify. }
        rewrite <- PROJS, <- PROJT. punfold H.
      + eapply IHo. eauto.
        eapply find_none_aux; eauto. eapply find_none_aux; eauto.
        { hexploit nm_wf_pair_pop_cases; eauto. instantiate (1:=tid0). i; des; clarify. }
        rewrite <- PROJS, <- PROJT. eapply ksim_reset_prog. punfold H. all: ss.

    - hexploit KSIM3; clear KSIM2 KSIM3; ss.
      assert (RA: (NatSet.remove tid (NatSet.add tid (key_set ths_tgt))) = (key_set ths_tgt)).
      { unfold NatSet.remove, NatSet.add. rewrite nm_find_none_rm_add_eq; auto.
        unfold key_set. rewrite NatMapP.F.map_o. rewrite THTGT. ss. }
      assert (FMT: tids_fmap tid0 (NatSet.remove tid (NatSet.add tid (key_set ths_tgt))) = tids_fmap tid0 (key_set thsr0)).
      { rewrite RA. eapply nm_pop_res_is_rm_eq in KSIM1. rewrite <- KSIM1. rewrite key_set_pull_rm_eq. eapply tids_fmap_rm_same_eq. }
      rewrite FMT. eauto. i. revert IHo. des; i. clarify.
      rewrite interp_state_tau. guclo sim_indC_spec; eapply sim_indC_tauL.
      rewrite bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_chooseL. exists tid0.
      assert (POPS: nm_pop tid0 (NatSet.remove tid (key_set (Th.add tid (Ret r_src) (nm_proj_v2 ths_src)))) = Some (tt, key_set thsl0)).
      { rewrite key_set_pull_add_eq. unfold NatSet.remove, key_set, nm_proj_v2. rewrite nm_find_none_rm_add_eq.
        do 2 eapply nm_pop_some_map1 in KSIM0. erewrite KSIM0. ss. do 2 f_equal. rewrite nm_map_unit1_map_eq. auto.
        rewrite nm_map_map_eq. rewrite NatMapP.F.map_o. rewrite THSRC. ss. }
      rewrite POPS; clear POPS.
      rewrite interp_state_tau. do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      rewrite bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_fairL.
      assert (FMS: tids_fmap tid0 (NatSet.remove tid (NatSet.add tid (key_set ths_src))) = tids_fmap tid0 (key_set thsl0)).
      { unfold NatSet.remove, NatSet.add. rewrite nm_find_none_rm_add_eq.
        2:{ unfold key_set. rewrite NatMapP.F.map_o. rewrite THSRC. ss. }
        apply nm_pop_res_is_rm_eq in KSIM0. rewrite <- KSIM0.
        rewrite key_set_pull_rm_eq. eapply tids_fmap_rm_same_eq.
      }
      esplits; eauto. rewrite <- FMS; eauto.
      rewrite interp_sched_tau. rewrite 2 interp_state_tau. do 3 (guclo sim_indC_spec; eapply sim_indC_tauL).
      specialize (H1 false false). pclearbot.
      match goal with
      | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ _ ?_tgt => replace _tgt with (interp_all st_tgt (Th.add tid0 th_tgt thsr0) tid0)
      end.
      2:{ assert (PROJT: Th.remove tid (Th.add tid (Ret r_tgt) ths_tgt) = Th.add tid0 th_tgt thsr0).
          { eapply proj_aux2; eauto. }
          rewrite PROJT. unfold interp_all.
          replace (NatSet.remove tid0 (key_set (Th.add tid0 th_tgt thsr0))) with (key_set thsr0); auto.
          rewrite key_set_pull_add_eq. unfold NatSet.remove. rewrite nm_find_none_rm_add_eq; auto.
          apply key_set_find_none1. eapply nm_pop_res_find_none; eauto.
      }
      match goal with
      | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ ?_src _ => replace _src with (interp_all st_src (Th.add tid0 th_src (nm_proj_v2 thsl0)) tid0)
      end.
      2:{ assert (PROJS: Th.remove tid (Th.add tid (Ret r_src) (nm_proj_v2 ths_src)) = Th.add tid0 th_src (nm_proj_v2 thsl0)).
          { unfold nm_proj_v2. rewrite nm_find_none_rm_add_eq. apply nm_pop_res_is_add_eq in KSIM0. rewrite KSIM0.
            rewrite <- nm_map_add_comm_eq. ss. rewrite NatMapP.F.map_o. rewrite THSRC. ss. }
          rewrite PROJS. unfold interp_all.
          replace (NatSet.remove tid0 (key_set (Th.add tid0 th_src (nm_proj_v2 thsl0)))) with (key_set thsl0); auto.
          rewrite key_set_pull_add_eq. unfold NatSet.remove. rewrite nm_find_none_rm_add_eq; auto.
          2:{ unfold key_set, nm_proj_v2. rewrite nm_map_map_eq. rewrite NatMapP.F.map_o.
              apply nm_pop_res_find_none in KSIM0. rewrite KSIM0. ss. }
          unfold key_set, nm_proj_v2. rewrite nm_map_unit1_map_eq. auto.
      }
      gfold. eapply sim_progress. right. eapply CIH.
      eapply find_none_aux; eauto. eapply find_none_aux; eauto.
      { hexploit nm_wf_pair_pop_cases; eauto. instantiate (1:=tid0). i; des; clarify. }
      assert (PROJS: NatSet.add tid0 (key_set thsl0) = NatSet.remove tid (NatSet.add tid (key_set ths_src))).
      { symmetry; eapply proj_aux; eauto. }
      assert (PROJT: NatSet.add tid0 (key_set thsr0) = NatSet.remove tid (NatSet.add tid (key_set ths_tgt))).
      { symmetry; eapply proj_aux; eauto. }
      rewrite PROJS, PROJT. eauto.
      all: auto.
  Qed.

  Lemma kgsim_sync
        R0 R1 (RR : R0 -> R1 -> Prop)
        (r : forall x x0 : Type,
            (x -> x0 -> Prop) -> bool -> (@imap ident_src wf_src) -> bool -> (@imap ident_tgt wf_tgt) -> _ -> _ -> Prop)
        (CIH : forall (ths_src : threads_src2 R0) (ths_tgt : threads_tgt R1) (tid : Th.key),
            Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None ->
            Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None ->
            th_wf_pair ths_src ths_tgt ->
            forall (sf : bool) (src : thread _ident_src (sE state_src) R0)
              (tgt : thread _ident_tgt (sE state_tgt) R1) (st_src : state_src)
              (st_tgt : state_tgt) (ps pt : bool) (o : T wf_src) (w : world)
              (mt : imap ident_tgt wf_tgt) (ms : imap ident_src wf_src),
              sim_knot RR ths_src ths_tgt tid ps pt (sf, src) tgt
                       (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), ms, mt, st_src,
                         st_tgt, o, w) ->
              r R0 R1 RR ps ms pt mt (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid)
                (interp_all st_tgt (Th.add tid tgt ths_tgt) tid))
        (o : T wf_src) ps
        (IHo : (ps = true) \/
                 (forall y : T wf_src,
                     lt wf_src y o ->
                     forall (ths_src : threads_src2 R0) (ths_tgt : threads_tgt R1) (tid : Th.key),
                       Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None ->
                       Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None ->
                       th_wf_pair ths_src ths_tgt ->
                       forall (sf : bool) (src : thread _ident_src (sE state_src) R0)
                         (tgt : thread _ident_tgt (sE state_tgt) R1) (st_src : state_src)
                         (st_tgt : state_tgt) (ps pt : bool) (w : world) (mt : imap ident_tgt wf_tgt)
                         (ms : imap ident_src wf_src),
                         sim_knot RR ths_src ths_tgt tid ps pt (sf, src) tgt
                                  (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), ms, mt, st_src,
                                    st_tgt, y, w) ->
                         gpaco9 (_sim (wft:=wf_tgt)) (cpn9 (_sim (wft:=wf_tgt))) bot9 r R0 R1 RR ps ms pt mt
                                (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid)
                                (interp_all st_tgt (Th.add tid tgt ths_tgt) tid)))
        (ths_src : threads_src2 R0) (ths_tgt : threads_tgt R1) tid pt
        (THSRC : Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None)
        (THTGT : Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None)
        (WF : th_wf_pair ths_src ths_tgt)
        (st_src : state_src) (st_tgt : state_tgt) w mt ms
        (ktr_src : () -> thread _ident_src (sE state_src) R0)
        (ktr_tgt : () -> thread _ident_tgt (sE state_tgt) R1)
        (KSIM0 : forall tid0 : NatMap.key,
            nm_pop tid0 (Th.add tid (true, ktr_src ()) ths_src) = None /\
              nm_pop tid0 (Th.add tid (ktr_tgt ()) ths_tgt) = None \/
              (exists
                  (b : bool) (th_src : thread _ident_src (sE state_src) R0)
                  (thsl1 : NatMap.t (bool * thread _ident_src (sE state_src) R0))
                  (th_tgt : thread _ident_tgt (sE state_tgt) R1) (thsr1 : threads_tgt R1),
                  nm_pop tid0 (Th.add tid (true, ktr_src ()) ths_src) = Some (b, th_src, thsl1) /\
                    nm_pop tid0 (Th.add tid (ktr_tgt ()) ths_tgt) = Some (th_tgt, thsr1) /\
                    (b = true ->
                     exists (o0 : T wf_src) (w0 : world),
                       lt wf_src o0 o /\
                         world_le w w0 /\
                         (forall im_tgt0 : imap ident_tgt wf_tgt,
                             fair_update mt im_tgt0
                                         (sum_fmap_l (tids_fmap tid0 (NatSet.add tid (key_set ths_tgt)))) ->
                             forall ps pt : bool,
                               upaco10
                                 (fun r => pind10 (__sim_knot RR r) top8) bot8 thsl1 thsr1 tid0 ps pt
                                 (b, Vis ((|Yield)|)%sum (fun _ : () => th_src)) th_tgt
                                 (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), ms,
                                   im_tgt0, st_src, st_tgt, o0, w0))) /\
                    (b = false ->
                     exists (o0 : T wf_src) (w0 : world),
                       lt wf_src o0 o /\
                         world_le w w0 /\
                         (forall im_tgt0 : imap ident_tgt wf_tgt,
                             fair_update mt im_tgt0
                                         (sum_fmap_l (tids_fmap tid0 (NatSet.add tid (key_set ths_tgt)))) ->
                             exists (im_src0 : imap ident_src wf_src) w1,
                               fair_update ms im_src0
                                           (sum_fmap_l (tids_fmap tid0 (NatSet.add tid (key_set ths_src)))) /\
                                 (world_le w0 w1) /\
                                 (forall ps pt : bool,
                                     upaco10
                                       (fun r => pind10 (__sim_knot RR r) top8) bot8 thsl1 thsr1 tid0 ps pt
                                       (b, th_src) th_tgt
                                       (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt),
                                         im_src0, im_tgt0, st_src, st_tgt, o0, w1))))))
    :
    gpaco9 (_sim (wft:=wf_tgt)) (cpn9 (_sim (wft:=wf_tgt))) bot9 r R0 R1 RR ps ms pt mt
           (interp_all st_src (Th.add tid (Vis ((|Yield)|)%sum ktr_src) (nm_proj_v2 ths_src)) tid)
           (interp_all st_tgt (Th.add tid (Vis ((|Yield)|)%sum ktr_tgt) ths_tgt) tid).
  Proof.
    match goal with
    | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ ?_src_temp _ => remember _src_temp as src_temp eqn:TEMP
    end.
    unfold interp_all. erewrite ! unfold_interp_sched_nondet_Some; auto using nm_find_add_eq.
    rewrite interp_thread_vis_yield. ired.
    rewrite interp_state_tau. guclo sim_indC_spec; eapply sim_indC_tauR.
    rewrite bind_trigger. rewrite interp_sched_vis. ss.
    rewrite interp_state_vis. rewrite <- ! bind_trigger.
    guclo sim_indC_spec. eapply sim_indC_chooseR. intro tid0.
    rewrite interp_state_tau.
    do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
    specialize (KSIM0 tid0). revert IHo; des; i.
    { assert (POPT: nm_pop tid0 (NatSet.add tid (NatSet.remove tid (key_set (Th.add tid (x <- ITree.trigger ((|Yield)|)%sum;; ktr_tgt x) ths_tgt)))) = None).
      { rewrite key_set_pull_add_eq. unfold NatSet.remove, NatSet.add. rewrite nm_find_none_rm_add_eq.
        erewrite <- key_set_pull_add_eq. unfold key_set. eapply nm_pop_none_map1; eauto.
        unfold key_set. rewrite NatMapP.F.map_o. rewrite THTGT. ss. }
      rewrite POPT; clear POPT.
      rewrite ! bind_trigger. rewrite interp_sched_vis. ss. rewrite interp_state_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_chooseR. intro x; destruct x. }
    assert (POPT: nm_pop tid0 (NatSet.add tid (NatSet.remove tid (key_set (Th.add tid (x <- ITree.trigger ((|Yield)|)%sum;; ktr_tgt x) ths_tgt)))) = Some (tt, key_set thsr1)).
    { rewrite key_set_pull_add_eq. unfold NatSet.remove, NatSet.add. rewrite nm_find_none_rm_add_eq.
      erewrite <- key_set_pull_add_eq. unfold key_set. eapply nm_pop_some_map1 in KSIM1. erewrite KSIM1. ss.
      unfold key_set. rewrite NatMapP.F.map_o. rewrite THTGT. ss.
    }
    rewrite POPT; clear POPT.
    rewrite ! bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis. rewrite <- bind_trigger. ss.
    guclo sim_indC_spec. eapply sim_indC_fairR. i. rewrite interp_sched_tau. rewrite 2 interp_state_tau.
    do 3 (guclo sim_indC_spec; eapply sim_indC_tauR).
    destruct b.

    - hexploit KSIM2; clear KSIM2 KSIM3; ss.
      i. revert IHo; des; i.
      assert (CHANGE: src_temp = interp_all st_src (Th.add tid0 (Vis ((|Yield)|)%sum (fun _ : () => th_src)) (nm_proj_v2 thsl1)) tid0).
      { rewrite TEMP. unfold interp_all. erewrite ! unfold_interp_sched_nondet_Some; auto using nm_find_add_eq.
        rewrite ! interp_thread_vis_yield. ired.
        assert (RA: Th.add tid (ktr_src ()) (Th.add tid (Vis ((|Yield)|)%sum ktr_src) (nm_proj_v2 ths_src)) = Th.add tid0 th_src (Th.add tid0 (Vis ((|Yield)|)%sum (fun _ : () => th_src)) (nm_proj_v2 thsl1))).
        { rewrite ! nm_add_add_eq. unfold nm_proj_v2. apply nm_pop_res_is_add_eq in KSIM0.
          replace (ktr_src ()) with (snd (true, ktr_src ())); auto. replace th_src with (snd (true, th_src)); auto.
          rewrite ! nm_map_add_comm_eq. rewrite KSIM0. ss.
        }
        rewrite ! RA.
        assert (RA1: (NatSet.add tid (NatSet.remove tid (key_set (Th.add tid (Vis ((|Yield)|)%sum ktr_src) (nm_proj_v2 ths_src))))) = (NatSet.add tid0 (NatSet.remove tid0 (key_set (Th.add tid0 (Vis ((|Yield)|)%sum (fun _ : () => th_src)) (nm_proj_v2 thsl1)))))).
        { unfold NatSet.add, NatSet.remove. rewrite <- !key_set_pull_rm_eq. erewrite <- !key_set_pull_add_eq. f_equal.
          rewrite ! nm_add_rm_eq. rewrite ! nm_add_add_eq. unfold nm_proj_v2. apply nm_pop_res_is_add_eq in KSIM0.
          rewrite ! nm_map_add_comm_eq. rewrite KSIM0. ss.
        }
        rewrite ! RA1. auto.
      }
      rewrite CHANGE; clear CHANGE.
      assert (FMT: tids_fmap tid0 (NatSet.add tid (key_set ths_tgt)) = tids_fmap tid0 (key_set thsr1)).
      { apply nm_pop_res_is_add_eq in KSIM1. unfold NatSet.add. erewrite <- key_set_pull_add_eq. erewrite KSIM1.
        rewrite key_set_pull_add_eq. symmetry; apply tids_fmap_add_same_eq.
      }
      hexploit H1; clear H1. rewrite FMT; eauto. i; pclearbot.
      match goal with
      | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ _ ?_tgt => replace _tgt with (interp_all st_tgt (Th.add tid0 th_tgt thsr1) tid0)
      end.
      2:{ unfold interp_all.
          replace (Th.add tid (ktr_tgt ()) (Th.add tid (Vis ((|Yield)|)%sum (fun x : () => ktr_tgt x)) ths_tgt)) with (Th.add tid0 th_tgt thsr1).
          2:{ rewrite nm_add_add_eq. apply nm_pop_res_is_add_eq in KSIM1. auto. }
          replace (NatSet.remove tid0 (key_set (Th.add tid0 th_tgt thsr1))) with (key_set thsr1).
          2:{ rewrite key_set_pull_add_eq. unfold NatSet.remove. rewrite nm_find_none_rm_add_eq. auto.
              unfold key_set. rewrite NatMapP.F.map_o. eapply find_none_aux in KSIM1. rewrite KSIM1; eauto.
          }
          auto.
      }
      des.
      + subst.
        gfold. eapply sim_progress; auto. right; eapply CIH.
        eapply find_none_aux; eauto. eapply find_none_aux; eauto.
        { apply nm_pop_res_is_rm_eq in KSIM0, KSIM1. rewrite <- KSIM0, <- KSIM1. eapply nm_wf_pair_rm. eapply nm_wf_pair_add. auto. }
        replace (NatSet.add tid0 (key_set thsl1)) with (NatSet.add tid (key_set ths_src)).
        2:{ unfold NatSet.add. apply nm_pop_res_is_add_eq in KSIM0. erewrite <- !key_set_pull_add_eq. rewrite KSIM0. eauto. }
        replace (NatSet.add tid0 (key_set thsr1)) with (NatSet.add tid (key_set ths_tgt)).
        2:{ unfold NatSet.add. apply nm_pop_res_is_add_eq in KSIM1. erewrite <- !key_set_pull_add_eq. rewrite KSIM1. eauto. }
        eauto.
      + eapply IHo; eauto.
        eapply find_none_aux; eauto. eapply find_none_aux; eauto.
        { apply nm_pop_res_is_rm_eq in KSIM0, KSIM1. rewrite <- KSIM0, <- KSIM1. eapply nm_wf_pair_rm. eapply nm_wf_pair_add. auto. }
        replace (NatSet.add tid0 (key_set thsl1)) with (NatSet.add tid (key_set ths_src)).
        2:{ unfold NatSet.add. apply nm_pop_res_is_add_eq in KSIM0. erewrite <- !key_set_pull_add_eq. rewrite KSIM0. eauto. }
        replace (NatSet.add tid0 (key_set thsr1)) with (NatSet.add tid (key_set ths_tgt)).
        2:{ unfold NatSet.add. apply nm_pop_res_is_add_eq in KSIM1. erewrite <- !key_set_pull_add_eq. rewrite KSIM1. eauto. }
        eapply ksim_reset_prog; eauto.

    - hexploit KSIM3; clear KSIM2 KSIM3; ss.
      i. revert IHo; des; i. clarify. unfold interp_all.
      erewrite unfold_interp_sched_nondet_Some; auto using nm_find_add_eq.
      rewrite interp_thread_vis_yield. ired. rewrite interp_state_tau. guclo sim_indC_spec; eapply sim_indC_tauL.
      rewrite bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis.
      rewrite <- bind_trigger. guclo sim_indC_spec. eapply sim_indC_chooseL. exists tid0.
      assert (POPS: nm_pop tid0 (NatSet.add tid (NatSet.remove tid (key_set (Th.add tid (Vis ((|Yield)|)%sum ktr_src) (nm_proj_v2 ths_src))))) = Some (tt, key_set thsl1)).
      { rewrite key_set_pull_add_eq. unfold NatSet.remove, NatSet.add. rewrite nm_find_none_rm_add_eq.
        erewrite <- key_set_pull_add_eq. unfold key_set, nm_proj_v2. rewrite nm_map_add_comm_eq.
        rewrite nm_map_map_eq. erewrite nm_pop_some_map1; eauto.
        unfold key_set, nm_proj_v2. rewrite nm_map_map_eq. rewrite NatMapP.F.map_o. rewrite THSRC. ss.
      }
      rewrite POPS; clear POPS. rewrite interp_state_tau. do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      rewrite bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_fairL.
      assert (FMT: tids_fmap tid0 (NatSet.add tid (key_set ths_tgt)) = tids_fmap tid0 (key_set thsr1)).
      { apply nm_pop_res_is_add_eq in KSIM1. unfold NatSet.add. erewrite <- key_set_pull_add_eq. erewrite KSIM1.
        rewrite key_set_pull_add_eq. symmetry; apply tids_fmap_add_same_eq.
      }
      hexploit H1; clear H1. rewrite FMT; eauto. i. revert IHo; des; i; pclearbot.
      assert (FMS: tids_fmap tid0 (key_set thsl1) = tids_fmap tid0 (NatSet.add tid (key_set ths_src))).
      { apply nm_pop_res_is_add_eq in KSIM0. unfold NatSet.add. erewrite <- key_set_pull_add_eq. erewrite KSIM0.
        rewrite key_set_pull_add_eq. apply tids_fmap_add_same_eq.
      }
      esplits; eauto. rewrite FMS; eauto.
      rewrite interp_sched_tau. rewrite 2 interp_state_tau. do 3 (guclo sim_indC_spec; eapply sim_indC_tauL).
      specialize (H3 false false).
      match goal with
      | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ _ ?_tgt => replace _tgt with (interp_all st_tgt (Th.add tid0 th_tgt thsr1) tid0)
      end.
      2:{ unfold interp_all.
          replace (Th.add tid (ktr_tgt ()) (Th.add tid (Vis ((|Yield)|)%sum (fun x : () => ktr_tgt x)) ths_tgt)) with (Th.add tid0 th_tgt thsr1).
          2:{ rewrite nm_add_add_eq. apply nm_pop_res_is_add_eq in KSIM1. auto. }
          replace (NatSet.remove tid0 (key_set (Th.add tid0 th_tgt thsr1))) with (key_set thsr1).
          2:{ rewrite key_set_pull_add_eq. unfold NatSet.remove. rewrite nm_find_none_rm_add_eq. auto.
              unfold key_set. rewrite NatMapP.F.map_o. eapply find_none_aux in KSIM1. rewrite KSIM1; eauto.
          }
          auto.
      }
      match goal with
      | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ ?_src _ => replace _src with (interp_all st_src (Th.add tid0 th_src (nm_proj_v2 thsl1)) tid0)
      end.
      2:{ unfold interp_all.
          replace (Th.add tid (ktr_src ()) (Th.add tid (Vis ((|Yield)|)%sum ktr_src) (nm_proj_v2 ths_src))) with (Th.add tid0 th_src (nm_proj_v2 thsl1)).
          2:{ rewrite nm_add_add_eq. apply nm_pop_res_is_add_eq in KSIM0. unfold nm_proj_v2.
              replace (ktr_src ()) with (snd (true, ktr_src ())); auto. replace th_src with (snd (false, th_src)); auto.
              rewrite ! nm_map_add_comm_eq. rewrite KSIM0. ss.
          }
          replace (NatSet.remove tid0 (key_set (Th.add tid0 th_src (nm_proj_v2 thsl1)))) with (key_set thsl1).
          2:{ rewrite key_set_pull_add_eq. unfold NatSet.remove. rewrite nm_find_none_rm_add_eq.
              unfold key_set, nm_proj_v2. rewrite nm_map_unit1_map_eq. ss.
              unfold key_set, nm_proj_v2. rewrite nm_map_map_eq.
              rewrite NatMapP.F.map_o. eapply find_none_aux in KSIM0. rewrite KSIM0; eauto.
          }
          auto.
      }
      des.
      + subst.
        gfold. eapply sim_progress; auto. right; eapply CIH.
        eapply find_none_aux; eauto. eapply find_none_aux; eauto.
        { apply nm_pop_res_is_rm_eq in KSIM0, KSIM1. rewrite <- KSIM0, <- KSIM1. eapply nm_wf_pair_rm. eapply nm_wf_pair_add. auto. }
        replace (NatSet.add tid0 (key_set thsl1)) with (NatSet.add tid (key_set ths_src)).
        2:{ unfold NatSet.add. apply nm_pop_res_is_add_eq in KSIM0. erewrite <- !key_set_pull_add_eq. rewrite KSIM0. eauto. }
        replace (NatSet.add tid0 (key_set thsr1)) with (NatSet.add tid (key_set ths_tgt)).
        2:{ unfold NatSet.add. apply nm_pop_res_is_add_eq in KSIM1. erewrite <- !key_set_pull_add_eq. rewrite KSIM1. eauto. }
        eapply ksim_reset_prog; eauto.
      + eapply IHo; eauto.
        eapply find_none_aux; eauto. eapply find_none_aux; eauto.
        { apply nm_pop_res_is_rm_eq in KSIM0, KSIM1. rewrite <- KSIM0, <- KSIM1. eapply nm_wf_pair_rm. eapply nm_wf_pair_add. auto. }
        replace (NatSet.add tid0 (key_set thsl1)) with (NatSet.add tid (key_set ths_src)).
        2:{ unfold NatSet.add. apply nm_pop_res_is_add_eq in KSIM0. erewrite <- !key_set_pull_add_eq. rewrite KSIM0. eauto. }
        replace (NatSet.add tid0 (key_set thsr1)) with (NatSet.add tid (key_set ths_tgt)).
        2:{ unfold NatSet.add. apply nm_pop_res_is_add_eq in KSIM1. erewrite <- !key_set_pull_add_eq. rewrite KSIM1. eauto. }
        eapply ksim_reset_prog; eauto.
  Qed.

  Lemma kgsim_true
        R0 R1 (RR : R0 -> R1 -> Prop)
        (r : forall x x0 : Type,
            (x -> x0 -> Prop) -> bool -> @imap ident_src wf_src -> bool -> @imap ident_tgt wf_tgt -> _ -> _ -> Prop)
        (CIH : forall (ths_src : threads_src2 R0) (ths_tgt : threads_tgt R1) (tid : Th.key),
            Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None ->
            Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None ->
            th_wf_pair ths_src ths_tgt ->
            forall (sf : bool) (src : thread _ident_src (sE state_src) R0)
              (tgt : thread _ident_tgt (sE state_tgt) R1) (st_src : state_src)
              (st_tgt : state_tgt) (ps pt : bool) (o : T wf_src) (w : world)
              (mt : imap ident_tgt wf_tgt) (ms : imap ident_src wf_src),
              sim_knot RR ths_src ths_tgt tid ps pt (sf, src) tgt
                       (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), ms, mt, st_src,
                         st_tgt, o, w) ->
              r R0 R1 RR ps ms pt mt (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid)
                (interp_all st_tgt (Th.add tid tgt ths_tgt) tid))
        (ths_src : threads_src2 R0) (ths_tgt : threads_tgt R1) tid pt
        (tgt : thread _ident_tgt (sE state_tgt) R1)
        (THSRC : Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None)
        (THTGT : Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None)
        (WF : th_wf_pair ths_src ths_tgt)
        (st_src : state_src) (st_tgt : state_tgt) w mt ms o
        (src : thread _ident_src (sE state_src) R0)
        (KSIM : sim_knot RR ths_src ths_tgt tid true pt (false, src) tgt
                         (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), ms, mt, st_src,
                           st_tgt, o, w))
    :
    gpaco9 (_sim (wft:=wf_tgt)) (cpn9 (_sim (wft:=wf_tgt))) bot9 r R0 R1 RR true ms pt mt
           (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid)
           (interp_all st_tgt (Th.add tid tgt ths_tgt) tid).
  Proof.
    match goal with
    | KSIM: sim_knot _ _ _ _ _ _ ?_src _ ?_shr |- _ => remember _src as ssrc; remember _shr as shr
    end.
    remember true as ps in KSIM.
    punfold KSIM.
    move KSIM before CIH. revert_until KSIM.
    eapply pind10_acc in KSIM.

    { instantiate (1:= (fun ths_src ths_tgt tid ps pt ssrc tgt shr =>
                          Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None ->
                          Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None ->
                          th_wf_pair ths_src ths_tgt ->
                          forall (st_src : state_src) (st_tgt : state_tgt) (w : world) (mt : imap ident_tgt wf_tgt) (ms : imap ident_src wf_src) (o : T wf_src)
                            (src : thread _ident_src (sE state_src) R0),
                            ssrc = (false, src) ->
                            shr = (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), ms, mt, st_src, st_tgt, o, w) ->
                            ps = true ->
                            gpaco9 (_sim (wft:=wf_tgt)) (cpn9 (_sim (wft:=wf_tgt))) bot9 r R0 R1 RR true ms pt mt
                                   (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid) (interp_all st_tgt (Th.add tid tgt ths_tgt) tid))) in KSIM; auto. }

    ss. clear ths_src ths_tgt tid ps pt ssrc tgt shr KSIM.
    intros rr DEC IH ths_src ths_tgt tid ps pt ssrc tgt shr KSIM. clear DEC.
    intros THSRC THTGT WF st_src st_tgt w mt ms o src Essrc Eshr Eps.
    clarify.
    eapply pind10_unfold in KSIM.
    2:{ eapply _ksim_mon. }
    inv KSIM.

    { clear rr IH. eapply gsim_ret_emp; eauto. }

    { clear rr IH. eapply kgsim_ret_cont; eauto. }

    { clarify. clear rr IH. eapply kgsim_sync; eauto. }

    { des. destruct KSIM1 as [KSIM1 IND].
      unfold interp_all at 1. erewrite unfold_interp_sched_nondet_Some; eauto using nm_find_add_eq.
      rewrite interp_thread_vis_yield. ired. rewrite interp_state_tau. guclo sim_indC_spec; eapply sim_indC_tauL.
      rewrite bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_chooseL. exists tid.
      replace (nm_pop tid (NatSet.add tid (NatSet.remove tid (key_set (Th.add tid (Vis ((|Yield)|)%sum ktr_src) (nm_proj_v2 ths_src)))))) with (Some (tt, NatSet.remove tid (key_set ths_src))).
      2:{ rewrite key_set_pull_add_eq. unfold NatSet.add, NatSet.remove. rewrite nm_add_rm_eq. rewrite nm_add_add_eq.
          rewrite nm_pop_add_eq. unfold key_set, nm_proj_v2. rewrite nm_map_unit1_map_eq. auto. }
      rewrite interp_state_tau. do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      rewrite bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_fairL.
      replace (tids_fmap tid (NatSet.remove tid (key_set ths_src))) with (tids_fmap tid (NatSet.add tid (key_set ths_src))).
      2:{ rewrite <- tids_fmap_rm_same_eq. unfold NatSet.add. rewrite <- tids_fmap_add_same_eq. auto. }
      esplits; eauto. rewrite interp_sched_tau. rewrite 2 interp_state_tau.
      do 3 (guclo sim_indC_spec; eapply sim_indC_tauL).
      match goal with
      | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ ?_src _ => replace _src with (interp_all st_src (Th.add tid (ktr_src ()) (nm_proj_v2 ths_src)) tid)
      end.
      2:{ unfold interp_all.
          replace (Th.add tid (ktr_src ()) (Th.add tid (Vis ((|Yield)|)%sum ktr_src) (nm_proj_v2 ths_src))) with (Th.add tid (ktr_src ()) (nm_proj_v2 ths_src)).
          2:{ rewrite nm_add_add_eq. auto. }
          replace (NatSet.remove tid (key_set (Th.add tid (ktr_src ()) (nm_proj_v2 ths_src)))) with (NatSet.remove tid (key_set ths_src)).
          2:{ rewrite key_set_pull_add_eq. unfold NatSet.remove. rewrite nm_rm_add_rm_eq.
              unfold key_set, nm_proj_v2. rewrite nm_map_unit1_map_eq. auto. }
          auto.
      }
      eapply IH. eauto. all: auto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_tau.
      guclo sim_indC_spec. eapply sim_indC_tauL.
      eapply IH; eauto.
    }

    { des. destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_chooseL. eexists.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_put.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_get.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_tid.
      do 1 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { rewrite interp_all_vis.
      rewrite <- bind_trigger. guclo sim_indC_spec. eapply sim_indC_ub.
    }

    { des. destruct KSIM1 as [KSIM1 IND]. rewrite interp_all_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_fairL. esplits; eauto.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_tau.
      guclo sim_indC_spec. eapply sim_indC_tauR.
      eapply IH; eauto.
    }

    { rewrite interp_all_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_chooseR. i.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
      specialize (KSIM0 x). destruct KSIM0 as [KSIM0 IND].
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_put.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_get.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_tid.
      do 1 (guclo sim_indC_spec; eapply sim_indC_tauR).
      eapply IH; eauto.
    }

    { rewrite interp_all_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_fairR. i.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
      specialize (KSIM0 _ FAIR). destruct KSIM0 as [KSIM0 IND].
      eapply IH; eauto.
    }

    { rewrite ! interp_all_vis. ss.
      rewrite <- ! bind_trigger. guclo sim_indC_spec. eapply sim_indC_obs. i; clarify.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL; guclo sim_indC_spec; eapply sim_indC_tauR).
      gfold. eapply sim_progress; auto. right. eapply CIH; eauto.
      specialize (KSIM0 r_tgt). pclearbot. eapply ksim_set_prog. eauto.
    }

    { clear rr IH. gfold. eapply sim_progress. right; eapply CIH; eauto. pclearbot. eapply KSIM0. all: auto. }

  Qed.

  Lemma ksim_implies_gsim
        R0 R1 (RR: R0 -> R1 -> Prop)
        (ths_src: threads_src2 R0)
        (ths_tgt: threads_tgt R1)
        tid
        (THSRC: Th.find tid ths_src = None)
        (THTGT: Th.find tid ths_tgt = None)
        (WF: th_wf_pair ths_src ths_tgt)
        sf src tgt
        (st_src: state_src) (st_tgt: state_tgt)
        ps pt
        (KSIM: forall im_tgt, exists im_src o w,
            sim_knot RR ths_src ths_tgt tid ps pt (sf, src) tgt
                     (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt),
                       im_src, im_tgt, st_src, st_tgt, o, w))
    :
    gsim wf_src wf_tgt RR
         (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid)
         (interp_all st_tgt (Th.add tid tgt ths_tgt) tid).
  Proof.
    ii. specialize (KSIM mt). des. rename im_src into ms. exists ms, ps, pt.
    revert_until RR. ginit. gcofix CIH. i.
    move o before CIH. revert_until o. induction (wf_src.(wf) o).
    clear H; rename x into o, H0 into IHo. i.
    match goal with
    | KSIM: sim_knot _ _ _ _ _ _ ?_src _ ?_shr |- _ => remember _src as ssrc; remember _shr as shr
    end.
    punfold KSIM.
    move KSIM before IHo. revert_until KSIM.
    eapply pind10_acc in KSIM.

    { instantiate (1:= (fun ths_src ths_tgt tid ps pt ssrc tgt shr =>
                          Th.find (elt:=bool * thread _ident_src (sE state_src) R0) tid ths_src = None ->
                          Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid ths_tgt = None ->
                          th_wf_pair ths_src ths_tgt ->
                          forall (sf : bool) (src : thread _ident_src (sE state_src) R0) (st_src : state_src) (st_tgt : state_tgt)
                            (mt : imap ident_tgt wf_tgt) (ms : imap ident_src wf_src) w,
                            ssrc = (sf, src) ->
                            shr = (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt), ms, mt, st_src, st_tgt, o, w) ->
                            gpaco9 (_sim (wft:=wf_tgt)) (cpn9 (_sim (wft:=wf_tgt))) bot9 r R0 R1 RR ps ms pt mt
                                   (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid) (interp_all st_tgt (Th.add tid tgt ths_tgt) tid))) in KSIM; auto. }

    ss. clear ths_src ths_tgt tid ps pt ssrc tgt shr KSIM.
    intros rr DEC IH ths_src ths_tgt tid ps pt ssrc tgt shr KSIM. clear DEC.
    intros THSRC THTGT WF sf src st_src st_tgt mt ms w Essrc Eshr.
    eapply pind10_unfold in KSIM.
    2:{ eapply _ksim_mon. }
    clarify.
    inv KSIM.

    { clear rr IH IHo. eapply gsim_ret_emp; eauto. }

    { clear rr IH. eapply kgsim_ret_cont; eauto. }

    { clear rr IH. eapply kgsim_sync; eauto. }

    { des; clarify. destruct KSIM1 as [KSIM1 IND].
      assert (KSIM: sim_knot RR ths_src ths_tgt tid true pt
                             (false, ktr_src ()) tgt
                             (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt),
                               im_src0, mt, st_src, st_tgt, o0, w)).
      { pfold. eapply pind10_mon_top; eauto. }
      unfold interp_all. erewrite unfold_interp_sched_nondet_Some; auto using nm_find_add_eq.
      rewrite interp_thread_vis_yield. ired. rewrite interp_state_tau. guclo sim_indC_spec; eapply sim_indC_tauL.
      rewrite bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_chooseL. exists tid.
      replace (nm_pop tid (NatSet.add tid (NatSet.remove tid (key_set (Th.add tid (Vis ((|Yield)|)%sum ktr_src) (nm_proj_v2 ths_src)))))) with (Some (tt, key_set ths_src)).
      2:{ rewrite key_set_pull_add_eq. unfold NatSet.add, NatSet.remove. rewrite nm_add_rm_eq. rewrite nm_add_add_eq.
          rewrite nm_pop_add_eq. unfold key_set, nm_proj_v2. rewrite nm_map_unit1_map_eq.
          rewrite nm_map_rm_comm_eq. rewrite nm_find_none_rm_eq; auto. }
      rewrite interp_state_tau. do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      rewrite bind_trigger. rewrite interp_sched_vis. rewrite interp_state_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_fairL.
      assert (FMS: tids_fmap tid (key_set ths_src) = tids_fmap tid (NatSet.add tid (key_set ths_src))).
      { apply tids_fmap_add_same_eq. }
      rewrite FMS; clear FMS. esplits; eauto.
      rewrite interp_sched_tau. rewrite 2 interp_state_tau. do 3 (guclo sim_indC_spec; eapply sim_indC_tauL).

      clear - ident_src ident_tgt world_le_PreOrder I CIH THSRC THTGT WF KSIM.
      rename o0 into o.
      remember (ktr_src ()) as src. rename im_src0 into ms.
      match goal with
      | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ _ ?_tgt => replace _tgt with (interp_all st_tgt (Th.add tid tgt ths_tgt) tid)
      end.
      2:{ ss. }
      match goal with
      | |- gpaco9 _ _ _ _ _ _ _ _ _ _ _ ?_src _ => replace _src with (interp_all st_src (Th.add tid src (nm_proj_v2 ths_src)) tid)
      end.
      2:{ unfold interp_all.
          replace (Th.add tid src (Th.add tid (Vis ((|Yield)|)%sum ktr_src) (nm_proj_v2 ths_src))) with (Th.add tid src (nm_proj_v2 ths_src)).
          2:{ rewrite nm_add_add_eq. auto. }
          replace (NatSet.remove tid (key_set (Th.add tid src (nm_proj_v2 ths_src)))) with (key_set ths_src).
          2:{ rewrite key_set_pull_add_eq. unfold NatSet.remove. rewrite nm_rm_add_rm_eq.
              unfold key_set, nm_proj_v2. rewrite nm_map_unit1_map_eq.
              rewrite nm_map_rm_comm_eq. rewrite nm_find_none_rm_eq; auto. }
          auto.
      }
      clear Heqsrc ktr_src.
      eapply kgsim_true; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_tau.
      guclo sim_indC_spec. eapply sim_indC_tauL.
      eapply IH; eauto.
    }

    { des. destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_chooseL. eexists.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_put.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_get.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_tid.
      do 1 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { rewrite interp_all_vis.
      rewrite <- bind_trigger. guclo sim_indC_spec. eapply sim_indC_ub.
    }

    { des. destruct KSIM1 as [KSIM1 IND]. rewrite interp_all_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_fairL. esplits; eauto.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_tau.
      guclo sim_indC_spec. eapply sim_indC_tauR.
      eapply IH; eauto.
    }

    { rewrite interp_all_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_chooseR. i.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
      specialize (KSIM0 x). destruct KSIM0 as [KSIM0 IND].
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_put.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_get.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
      eapply IH; eauto.
    }

    { destruct KSIM0 as [KSIM0 IND]. rewrite interp_all_tid.
      do 1 (guclo sim_indC_spec; eapply sim_indC_tauR).
      eapply IH; eauto.
    }

    { rewrite interp_all_vis. rewrite <- bind_trigger.
      guclo sim_indC_spec. eapply sim_indC_fairR. i.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauR).
      specialize (KSIM0 _ FAIR). destruct KSIM0 as [KSIM0 IND].
      eapply IH; eauto.
    }

    { rewrite ! interp_all_vis. ss.
      rewrite <- ! bind_trigger. guclo sim_indC_spec. eapply sim_indC_obs. i; clarify.
      do 2 (guclo sim_indC_spec; eapply sim_indC_tauL; guclo sim_indC_spec; eapply sim_indC_tauR).
      gfold. eapply sim_progress; auto. right. eapply CIH; eauto.
      specialize (KSIM0 r_tgt). pclearbot. eapply ksim_set_prog. eauto.
    }

    { clear rr IH. gfold. eapply sim_progress. right; eapply CIH; eauto. pclearbot. eapply KSIM0. all: auto. }

  Qed.

  Theorem lsim_implies_gsim
          R0 R1 (RR: R0 -> R1 -> Prop)
          (ths_src: threads_src1 R0)
          (ths_tgt: threads_tgt R1)
          (WF: th_wf_pair ths_src ths_tgt)
          tid
          (FINDS: Th.find tid ths_src = None)
          (FINDT: Th.find tid ths_tgt = None)
          src tgt
          (st_src: state_src) (st_tgt: state_tgt)
          ps pt
          (LSIM: forall im_tgt, exists im_src o w,
              (<<LSIM:
                forall im_tgt0
                  (FAIR: fair_update im_tgt im_tgt0 (sum_fmap_l (tids_fmap tid (NatSet.add tid (key_set ths_tgt))))),
                exists im_src0 w0,
                  (fair_update im_src im_src0 (sum_fmap_l (tids_fmap tid (NatSet.add tid (key_set ths_src))))) /\
                    (world_le w w0) /\
                    (lsim world_le I (local_RR world_le I RR tid) tid ps pt src tgt
                          (NatSet.add tid (key_set ths_src), NatSet.add tid (key_set ths_tgt),
                            im_src0, im_tgt0, st_src, st_tgt, o, w0))>>) /\
                (<<LOCAL: forall tid (src: itree srcE R0) (tgt: itree tgtE R1)
                            (LSRC: Th.find tid ths_src = Some src)
                            (LTGT: Th.find tid ths_tgt = Some tgt),
                    (local_sim_pick RR src tgt tid w)>>))
    :
    gsim wf_src wf_tgt RR
         (interp_all st_src (Th.add tid src ths_src) tid)
         (interp_all st_tgt (Th.add tid tgt ths_tgt) tid).
  Proof.
    remember (Th.map (fun th => (false, th)) ths_src) as ths_src2.
    assert (FINDS2: Th.find tid ths_src2 = None).
    { subst. rewrite NatMapP.F.map_o. rewrite FINDS. ss. }
    assert (WF0: th_wf_pair ths_src2 ths_tgt).
    { subst. unfold th_wf_pair, nm_wf_pair in *. rewrite <- WF. unfold key_set. rewrite nm_map_unit1_map_eq. auto. }
    replace ths_src with (nm_proj_v2 ths_src2).
    2:{ subst. unfold nm_proj_v2. rewrite nm_map_map_eq. ss. apply nm_map_self_eq. }
    eapply ksim_implies_gsim; auto.
    eapply lsim_implies_ksim; auto.
    i. specialize (LSIM im_tgt). des.
    replace (NatSet.add tid (key_set ths_src2)) with (NatSet.add tid (key_set ths_src)).
    2:{ unfold key_set. clarify. rewrite nm_map_unit1_map_eq. auto. }
    esplits; eauto.
    i. assert (SF: sf = false).
    { clarify. rewrite NatMapP.F.map_o in LSRC.
      destruct (NatMap.find (elt:=thread _ident_src (sE state_src) R0) tid0 ths_src); ss. clarify. }
    subst sf. split; i; ss. eapply LOCAL; auto.
    clarify. rewrite NatMapP.F.map_o in LSRC.
    destruct (NatMap.find (elt:=thread _ident_src (sE state_src) R0) tid0 ths_src); ss. clarify.
    Unshelve. exact true.
  Qed.


  Lemma list_forall2_implies
        A B (f1 f2: A -> B -> Prop) la lb
        (FA: List.Forall2 f1 la lb)
        (IMP: forall a b, (f1 a b) -> (f2 a b))
    :
    List.Forall2 f2 la lb.
  Proof.
    depgen f1. clear. i. move FA before B. revert_until FA. induction FA; i; ss.
    econs; eauto.
  Qed.

  Definition local_sim_threads
             R0 R1 (RR: R0 -> R1 -> Prop)
             (ths_src: threads_src1 R0)
             (ths_tgt: threads_tgt R1)
    :=
    List.Forall2
      (fun '(t1, src) '(t2, tgt) => (t1 = t2) /\ (local_sim world_le I RR src tgt))
      (Th.elements ths_src) (Th.elements ths_tgt).

  Theorem local_sim_implies_gsim
          R0 R1 (RR: R0 -> R1 -> Prop)
          (ths_src: threads_src1 R0)
          (ths_tgt: threads_tgt R1)
          (LOCAL: local_sim_threads RR ths_src ths_tgt)
          (st_src: state_src) (st_tgt: state_tgt)
          (INV: forall im_tgt, exists im_src o w,
              I (NatSet.empty, NatSet.empty, im_src, im_tgt, st_src, st_tgt, o, w))
          tid
          (INS: Th.In tid ths_src)
          (INT: Th.In tid ths_tgt)
    :
    gsim wf_src wf_tgt RR
         (interp_all st_src ths_src tid)
         (interp_all st_tgt ths_tgt tid).
  Proof.
    unfold local_sim_threads in LOCAL.
    eapply NatMapP.F.in_find_iff in INS, INT.
    destruct (Th.find tid ths_src) eqn:FINDS.
    2:{ clarify. }
    destruct (Th.find tid ths_tgt) eqn:FINDT.
    2:{ clarify. }
    clear INS INT. rename i into src0, i0 into tgt0.
    remember (Th.remove tid ths_src) as ths_src0.
    remember (Th.remove tid ths_tgt) as ths_tgt0.
    assert (POPS: nm_pop tid ths_src = Some (src0, ths_src0)).
    { unfold nm_pop. rewrite FINDS. rewrite Heqths_src0. auto. }
    assert (POPT: nm_pop tid ths_tgt = Some (tgt0, ths_tgt0)).
    { unfold nm_pop. rewrite FINDT. rewrite Heqths_tgt0. auto. }
    i. replace ths_src with (Th.add tid src0 ths_src0).
    2:{ symmetry; eapply nm_pop_res_is_add_eq; eauto. }
    replace ths_tgt with (Th.add tid tgt0 ths_tgt0).
    2:{ symmetry; eapply nm_pop_res_is_add_eq; eauto. }
    eapply lsim_implies_gsim; auto.
    { subst. eapply nm_wf_pair_rm. eapply nm_forall2_wf_pair.
      eapply list_forall2_implies; eauto. i. des_ifs. des; auto.
    }
    { eapply nm_pop_res_find_none; eauto. }
    { eapply nm_pop_res_find_none; eauto. }

    cut (forall im_tgt, exists im_src0 o0 w0,
            (I (key_set ths_src, key_set ths_tgt, im_src0, im_tgt, st_src, st_tgt, o0, w0)) /\
              (forall (tid0 : Th.key) (src : thread _ident_src (sE state_src) R0)
                 (tgt : thread _ident_tgt (sE state_tgt) R1),
                  Th.find (elt:=thread _ident_src (sE state_src) R0) tid0 ths_src = Some src ->
                  Th.find (elt:=thread _ident_tgt (sE state_tgt) R1) tid0 ths_tgt = Some tgt ->
                  local_sim_pick RR src tgt tid0 w0)).
    { i. specialize (H im_tgt). des. exists im_src0, o0, w0. split.
      - ii. specialize (H0 tid src0 tgt0). hexploit H0; clear H0.
        { eapply nm_pop_find_some; eauto. }
        { eapply nm_pop_find_some; eauto. }
        i. unfold local_sim_pick in H0.
        assert (SETS: NatSet.add tid (key_set ths_src0) = key_set ths_src).
        { subst. rewrite key_set_pull_rm_eq. unfold NatSet.add.
          rewrite <- nm_find_some_rm_add_eq; auto. eapply key_set_find_some1; eauto.
        }
        assert (SETT: NatSet.add tid (key_set ths_tgt0) = key_set ths_tgt).
        { subst. rewrite key_set_pull_rm_eq. unfold NatSet.add.
          rewrite <- nm_find_some_rm_add_eq; auto. eapply key_set_find_some1; eauto.
        }
        hexploit H0; clear H0.
        eapply H. reflexivity.
        rewrite <- SETT; eauto.
        rewrite !SETS, !SETT. eauto.
      - red. intros. eapply H0.
        eapply find_some_aux; eauto. eapply find_some_aux; eauto.
    }

    cut (forall im_tgt, exists (im_src0 : imap ident_src wf_src) (o0 : T wf_src) (w0 : world),
            I (key_set ths_src, key_set ths_tgt, im_src0, im_tgt, st_src, st_tgt, o0, w0) /\
              (List.Forall2 (fun '(t1, src) '(t2, tgt) => t1 = t2 /\ local_sim_pick RR src tgt t1 w0)
                            (Th.elements (elt:=thread _ident_src (sE state_src) R0) ths_src)
                            (Th.elements (elt:=thread _ident_tgt (sE state_tgt) R1) ths_tgt))).
    { intro FA. i. specialize (FA im_tgt). des. esplits; eauto.
      i. eapply nm_forall2_implies_find_some in FA0; eauto.
    }

    clear tid src0 ths_src0 tgt0 ths_tgt0 FINDS FINDT Heqths_src0 Heqths_tgt0 POPS POPT .
    match goal with
    | FA: List.Forall2 _ ?_ml1 ?_ml2 |- _ => remember _ml1 as tl_src; remember _ml2 as tl_tgt
    end.
    move LOCAL before RR. revert_until LOCAL. induction LOCAL; i.
    { specialize (INV im_tgt). des.
      symmetry in Heqtl_src; apply NatMapP.elements_Empty in Heqtl_src.
      symmetry in Heqtl_tgt; apply NatMapP.elements_Empty in Heqtl_tgt.
      apply nm_empty_eq in Heqtl_src, Heqtl_tgt. subst. esplits; ss.
      unfold NatSet.empty in *. rewrite !key_set_empty_empty_eq. eauto.
    }

    des_ifs. des; clarify. rename k0 into tid1, i into src1, i0 into tgt1.
    hexploit nm_elements_cons_rm. eapply Heqtl_src. intro RESS.
    hexploit nm_elements_cons_rm. eapply Heqtl_tgt. intro REST.
    hexploit IHLOCAL; clear IHLOCAL; eauto. intro IND.
    des.
    unfold local_sim in H0.
    specialize (H0 _ _ _ _ _ _ _ _ IND tid1 (key_set ths_src) (key_set ths_tgt)).
    hexploit H0.
    { econs. rewrite key_set_pull_rm_eq. eapply nm_find_rm_eq.
      erewrite <- key_set_pull_add_eq. instantiate (1:=src1).
      rewrite <- nm_find_some_rm_add_eq; auto. eapply nm_elements_cons_find_some; eauto.
    }
    { econs. rewrite key_set_pull_rm_eq. eapply nm_find_rm_eq.
      erewrite <- key_set_pull_add_eq. instantiate (1:=tgt1).
      rewrite <- nm_find_some_rm_add_eq; auto. eapply nm_elements_cons_find_some; eauto.
    }
    instantiate (1:=im_tgt). i; des. esplits; eauto.
    econs; auto.
    { split; ss. ii.
      specialize (H2 _ _ _ _ _ _ _ _ INV1 WORLD0 im_tgt1 FAIR). des. esplits; eauto.
    }
    eapply list_forall2_implies; eauto. i. des_ifs. des; clarify. split; auto.
    eapply local_sim_pick_mon_world; eauto.
    Unshelve. all: exact true.
  Qed.

End ADEQ.