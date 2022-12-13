From sflib Require Import sflib.
From Paco Require Import paco.
Require Import Coq.Classes.RelationClasses Lia Program.
Unset Universe Checking.
From Fairness Require Export ITreeLib WFLib FairBeh NatStructs Mod pind Axioms OpenMod WMM Red IRed Wrapper WeakestAdequacy.
From PromisingLib Require Import Loc Event.
From PromisingSEQ Require Import TView.
From Ordinal Require Export ClassicalHessenberg.
Require Import Coq.Numbers.BinNums.


Set Implicit Arguments.


Module TicketLock.
  Definition now_serving: Loc.t := Loc.of_nat 0.
  Definition next_ticket: Loc.t := Loc.of_nat 1.

  Definition const_1: Const.t := Const.of_Z (BinIntDef.Z.of_nat 1).

  Definition lock_loop (myticket: Const.t) (tvw: TView.t):
    itree ((((@eventE void) +' cE) +' (sE unit)) +' OpenMod.callE) TView.t
    :=
    ITree.iter
      (fun (tvw: TView.t) =>
         '(tvw, next) <- (OMod.call "load" (tvw, now_serving, Ordering.acqrel));;
         b <- unwrap (Const.eqb myticket next);;
         if (b: bool) then Ret (inr tvw) else Ret (inl tvw)) tvw.

  Lemma lock_loop_red myticket tvw
    :
    lock_loop myticket tvw
    =
      '(tvw, next) <- (OMod.call "load" (tvw, now_serving, Ordering.acqrel));;
      b <- unwrap (Const.eqb myticket next);;
      if (b: bool)
      then Ret tvw else tau;; lock_loop myticket tvw.
  Proof.
    unfold lock_loop. etransitivity.
    { apply unfold_iter_eq. }
    grind.
  Qed.

  Definition lock_fun:
    ktree ((((@eventE void) +' cE) +' (sE unit)) +' OpenMod.callE) TView.t TView.t :=
    fun tvw =>
      '(tvw, myticket) <- (OMod.call "faa" (tvw, next_ticket, const_1, Ordering.plain, Ordering.acqrel));;
      _ <- lock_loop myticket tvw;;
      _ <- trigger Yield;;
      Ret tvw
  .

  Definition unlock_fun:
    ktree ((((@eventE void) +' cE) +' (sE unit)) +' OpenMod.callE) TView.t TView.t :=
    fun tvw =>
      _ <- trigger Yield;;
      '(tvw, v) <- (OMod.call "load" (tvw, next_ticket, Ordering.relaxed));;
      let v := Const.add v const_1 in
      tvw <- (OMod.call "store" (tvw: TView.t, next_ticket, v, Ordering.acqrel));;
      _ <- trigger Yield;;
      Ret tvw
  .

  Definition omod: OMod.t :=
    OMod.mk
      tt
      (Mod.get_funs [("lock", Mod.wrap_fun lock_fun);
                     ("unlock", Mod.wrap_fun unlock_fun)])
  .

  Definition mod: Mod.t :=
    OMod.close
      (omod)
      (WMem.mod)
  .
End TicketLock.

From Fairness Require Import FairLock ModSim.

Section SIM.
  Lemma ticketlock_fair:
    ModSim.mod_sim FairLockW.mod TicketLock.mod.
  Admitted.
End SIM.