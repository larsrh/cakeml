(*Generated by Lem from toIntLang.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory libTheory compilerLibTheory intLangTheory astTheory miscTheory;

val _ = numLib.prefer_num();



val _ = new_theory "toIntLang"

(* Translation from CakeML to Intermediate Language *)
(*open import Pervasives*)

(*open import Lib*)
(*open import CompilerLib*)
(*open import IntLang*)
(*open import Ast*)
(*import {hol} miscTheory*)

(* TODO: Lem's builtin find index has a different type *)
(*val find_index : forall 'a 'b. 'a -> list 'a -> nat -> 'b*) (* to pick up the definition in miscTheory *)

 val free_vars_defn = Hol_defn "free_vars" `

(free_vars (CRaise e) = (free_vars e))
/\
(free_vars (CHandle e1 e2) = (lunion (free_vars e1) (lshift( 1) (free_vars e2))))
/\
(free_vars (CVar (Short n)) = ([n]))
/\
(free_vars (CVar (Long _ _)) = ([]))
/\
(free_vars (CLit _) = ([]))
/\
(free_vars (CCon _ es) = (free_vars_list es))
/\
(free_vars (CTagEq e _) = (free_vars e))
/\
(free_vars (CProj e _) = (free_vars e))
/\
(free_vars (CLet e eb) = (lunion (free_vars e) (lshift( 1) (free_vars eb))))
/\
(free_vars (CLetrec defs e) =  
(let n = ((LENGTH defs)) in
  lunion (free_vars_defs n defs) (lshift n (free_vars e))))
/\
(free_vars (CCall _ e es) = (lunion (free_vars e) (free_vars_list es)))
/\
(free_vars (CPrim1 _ e) = (free_vars e))
/\
(free_vars (CPrim2 _ e1 e2) = (lunion (free_vars e1) (free_vars e2)))
/\
(free_vars (CUpd e1 e2) = (lunion (free_vars e1) (free_vars e2)))
/\
(free_vars (CIf e1 e2 e3) = (lunion (free_vars e1) (lunion (free_vars e2) (free_vars e3))))
/\
(free_vars_list [] = ([]))
/\
(free_vars_list (e::es) = (lunion (free_vars e) (free_vars_list es)))
/\
(free_vars_defs _ [] = ([]))
/\
(free_vars_defs n (d::ds) = (lunion (free_vars_def n d) (free_vars_defs n ds)))
/\
(free_vars_def n (NONE,(k,e)) = (lshift (n+k) (free_vars e)))
/\
(free_vars_def _ ((SOME _),_) = ([]))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn free_vars_defn;

 val mkshift_defn = Hol_defn "mkshift" `

(mkshift f k (CRaise e) = (CRaise (mkshift f k e)))
/\
(mkshift f k (CHandle e1 e2) = (CHandle (mkshift f k e1) (mkshift f (k+ 1) e2)))
/\
(mkshift f k (CVar (Short v)) = (CVar (Short (if v < k then v else (f (v - k))+k))))
/\
(mkshift _ _ (CVar lid) = (CVar lid))
/\
(mkshift _ _ (CLit l) = (CLit l))
/\
(mkshift f k (CCon cn es) = (CCon cn ((MAP (mkshift f k) es))))
/\
(mkshift f k (CTagEq e m) = (CTagEq (mkshift f k e) m))
/\
(mkshift f k (CProj e m) = (CProj (mkshift f k e) m))
/\
(mkshift f k (CLet e b) = (CLet (mkshift f k e) (mkshift f (k+ 1) b)))
/\
(mkshift f k (CLetrec defs b) =  
(let ns = ((LENGTH defs)) in
  let defs = ((MAP (\ cb .
    (case cb of   ((SOME _),_) => cb | (NONE,(az,b)) => (NONE,(az,mkshift f ((k+ns)+az) b)) ))
    defs)) in
  CLetrec defs (mkshift f (k+ns) b)))
/\
(mkshift f k (CCall ck e es) = (CCall ck (mkshift f k e) ((MAP (mkshift f k) es))))
/\
(mkshift f k (CPrim1 p1 e) = (CPrim1 p1 (mkshift f k e)))
/\
(mkshift f k (CPrim2 p2 e1 e2) = (CPrim2 p2 (mkshift f k e1) (mkshift f k e2)))
/\
(mkshift f k (CUpd e1 e2) = (CUpd (mkshift f k e1) (mkshift f k e2)))
/\
(mkshift f k (CIf e1 e2 e3) = (CIf (mkshift f k e1) (mkshift f k e2) (mkshift f k e3)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn mkshift_defn;

val _ = Define `
 (shift n = (mkshift (\ v . v+n)))`;


(* remove pattern-matching using continuations *)

val _ = Hol_datatype `
 exp_to_Cexp_state =
 <| bvars : string list
  ; mvars : (string, ( string list)) fmap
  ; cnmap : (( ( conN id)option), num) fmap
  |>`;

 val _ = Define `
 (cbv m v = (( m with<| bvars := v::m.bvars |>)))`;


 val pat_to_Cpat_defn = Hol_defn "pat_to_Cpat" `

(pat_to_Cpat m (Pvar vn) = ((m with<| bvars := vn::m.bvars|>), CPvar))
/\
(pat_to_Cpat m (Plit l) = (m, CPlit l))
/\
(pat_to_Cpat m (Pcon cn ps) =  
(let (m,Cps) = (pats_to_Cpats m ps) in
  (m,CPcon (fapply( 0) cn m.cnmap) Cps)))
/\
(pat_to_Cpat m (Pref p) =  
(let (m,Cp) = (pat_to_Cpat m p) in
  (m,CPref Cp)))
/\
(pats_to_Cpats m [] = (m,[]))
/\
(pats_to_Cpats m (p::ps) =  
(let (m,Cp) = (pat_to_Cpat m p) in
  let (m,Cps) = (pats_to_Cpats m ps) in
  (m,(Cp::Cps))))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn pat_to_Cpat_defn;

 val Cpat_vars_defn = Hol_defn "Cpat_vars" `

(Cpat_vars CPvar = (( 1:num)))
/\
(Cpat_vars (CPlit _) =( 0))
/\
(Cpat_vars (CPcon _ ps) = (Cpat_vars_list ps))
/\
(Cpat_vars (CPref p) = (Cpat_vars p))
/\
(Cpat_vars_list [] =( 0))
/\
(Cpat_vars_list (p::ps) = ((Cpat_vars p)+(Cpat_vars_list ps)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn Cpat_vars_defn;

 val remove_mat_vp_defn = Hol_defn "remove_mat_vp" `

(remove_mat_vp _ sk v CPvar =  
(CLet (CVar (Short v)) sk))
/\
(remove_mat_vp fk sk v (CPlit l) =  
(CIf (CPrim2 CEq (CVar (Short v)) (CLit l))
    sk (CCall F (CVar (Short fk)) [])))
/\
(remove_mat_vp fk sk v (CPcon cn ps) =  
(CIf (CTagEq (CVar (Short v)) cn)
    (remove_mat_con fk sk v( 0) ps)
    (CCall F (CVar (Short fk)) [])))
/\
(remove_mat_vp fk sk v (CPref p) =  
(CLet (CPrim1 CDer (CVar (Short v)))
    (remove_mat_vp (fk+ 1) (shift( 1) (Cpat_vars p) sk)( 0) p)))
/\
(remove_mat_con _ sk _ _ [] = sk)
/\
(remove_mat_con fk sk v n (p::ps) =  
(let p1 = (Cpat_vars p) in
  let p2 = (Cpat_vars_list ps) in
  CLet (CProj (CVar (Short v)) n)
    (remove_mat_vp (fk+ 1)
      (remove_mat_con ((fk+ 1)+p1) (shift( 1) (p2+p1) sk) ((v+ 1)+p1) (n+ 1) ps)( 0) p)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn remove_mat_vp_defn;

 val remove_mat_var_defn = Hol_defn "remove_mat_var" `

(remove_mat_var b v [] = (CRaise (if b then CVar (Short v) else CBind_exc)))
/\
(remove_mat_var b v ((p,sk)::pes) =  
(CLetrec [(NONE, ( 0,shift( 1)( 0) (remove_mat_var b v pes)))]
    (remove_mat_vp( 0) (shift( 1) (Cpat_vars p) sk) (v+ 1) p)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn remove_mat_var_defn;

 val _ = Define `

(opn_to_prim2 Plus = ((INL CAdd)))
/\
(opn_to_prim2 Minus = ((INL CSub)))
/\
(opn_to_prim2 Times = ((INL CMul)))
/\
(opn_to_prim2 Divide = ((INR CDiv)))
/\
(opn_to_prim2 Modulo = ((INR CMod)))`;


 val exp_to_Cexp_defn = Hol_defn "exp_to_Cexp" `

(exp_to_Cexp m (Handle e pes) =  
(let Ce = (exp_to_Cexp m e) in
  let Cpes = (pes_to_Cpes m pes) in
  let Cpes = ((MAP (\ (p,e) . (p,shift( 1) (Cpat_vars p) e)) Cpes)) in
  CHandle Ce (remove_mat_var T( 0) Cpes)))
/\
(exp_to_Cexp m (Raise e) = (CRaise (exp_to_Cexp m e)))
/\
(exp_to_Cexp _ (Lit l) = (CLit l))
/\
(exp_to_Cexp m (Con cn es) =  
(CCon (fapply( 0) cn m.cnmap) (exps_to_Cexps m es)))
/\
(exp_to_Cexp m (Var (Short vn)) = (CVar (Short (the( 0) (misc$find_index vn m.bvars( 0))))))
/\
(exp_to_Cexp m (Var (Long mn vn)) = (CVar (Long mn (the( 0) (misc$find_index vn (fapply [] mn m.mvars)( 0))))))
/\
(exp_to_Cexp m (Fun vn e) =  
(CLetrec [(NONE,( 1,shift( 1)( 1) (exp_to_Cexp (cbv m vn) e)))] (CVar (Short( 0)))))
/\
(exp_to_Cexp m (App (Opn opn) e1 e2) =  
(let Ce1 = (exp_to_Cexp m e1) in
  let Ce2 = (exp_to_Cexp m e2) in
  (case opn_to_prim2 opn of
    (INL p2) => CPrim2 p2 Ce1 Ce2
  | (INR p2) =>
    CLet Ce1
      (CLet (shift( 1)( 0) Ce2)
        (CIf (CPrim2 CEq (CVar (Short( 0))) (CLit (IntLit((( 0 : int))))))
             (CRaise CDiv_exc)
             (CPrim2 p2 (CVar (Short( 1))) (CVar (Short( 0))))))
  )))
/\
(exp_to_Cexp m (App (Opb opb) e1 e2) =  
(let Ce1 = (exp_to_Cexp m e1) in
  let Ce2 = (exp_to_Cexp m e2) in
  (case opb of
    Lt => CPrim2 CLt Ce1 Ce2
  | Leq => CPrim2 CLt (CPrim2 CSub Ce1 Ce2) (CLit (IntLit((( 1 : int)))))
  | opb =>
      CLet Ce1 (
        CLet (shift( 1)( 0) Ce2) (
          (case opb of
            Gt =>  CPrim2 CLt (CVar (Short( 0))) (CVar (Short( 1)))
          | Geq => CPrim2 CLt (CPrim2 CSub (CVar (Short( 0))) (CVar (Short( 1)))) (CLit (IntLit((( 1 : int)))))
          | _ => CRaise CBind_exc (* should not happen *)
          )))
  )))
/\
(exp_to_Cexp m (App Equality e1 e2) =  
(let Ce1 = (exp_to_Cexp m e1) in
  let Ce2 = (exp_to_Cexp m e2) in
  CLet (CPrim2 CEq Ce1 Ce2)
    (CIf (CPrim1 CIsBlock (CVar (Short( 0)))) (CVar (Short( 0))) (CRaise CEq_exc))))
/\
(exp_to_Cexp m (App Opapp e1 e2) =  
(let Ce1 = (exp_to_Cexp m e1) in
  let Ce2 = (exp_to_Cexp m e2) in
  CCall T Ce1 [Ce2]))
/\
(exp_to_Cexp m (App Opassign e1 e2) =  
(let Ce1 = (exp_to_Cexp m e1) in
  let Ce2 = (exp_to_Cexp m e2) in
  CUpd Ce1 Ce2))
/\
(exp_to_Cexp m (Uapp uop e) =  
(let Ce = (exp_to_Cexp m e) in
  CPrim1 ((case uop of
            Opref   => CRef
          | Opderef => CDer
          )) Ce))
/\
(exp_to_Cexp m (Log log e1 e2) =  
(let Ce1 = (exp_to_Cexp m e1) in
  let Ce2 = (exp_to_Cexp m e2) in
  ((case log of
     And => CIf Ce1 Ce2 (CLit (Bool F))
   | Or  => CIf Ce1 (CLit (Bool T)) Ce2
   ))))
/\
(exp_to_Cexp m (If e1 e2 e3) =  
(let Ce1 = (exp_to_Cexp m e1) in
  let Ce2 = (exp_to_Cexp m e2) in
  let Ce3 = (exp_to_Cexp m e3) in
  CIf Ce1 Ce2 Ce3))
/\
(exp_to_Cexp m (Mat e pes) =  
(let Ce = (exp_to_Cexp m e) in
  let Cpes = (pes_to_Cpes m pes) in
  let Cpes = ((MAP (\ (p,e) . (p,shift( 1) (Cpat_vars p) e)) Cpes)) in
  CLet Ce (remove_mat_var F( 0) Cpes)))
/\
(exp_to_Cexp m (Let vn e b) =  
(let Ce = (exp_to_Cexp m e) in
  let Cb = (exp_to_Cexp (cbv m vn) b) in
  CLet Ce Cb))
/\
(exp_to_Cexp m (Letrec defs b) =  
(let m = (( m with<| bvars := ((MAP (\p . 
  (case (p ) of ( (n,_,_) ) => n )) defs)) ++ m.bvars |>)) in
  CLetrec (defs_to_Cdefs m defs) (exp_to_Cexp m b)))
/\
(defs_to_Cdefs _ [] = ([]))
/\
(defs_to_Cdefs m ((_,vn,e)::defs) =  
(let Ce = (exp_to_Cexp (cbv m vn) e) in
  let Cdefs = (defs_to_Cdefs m defs) in
  (NONE,( 1,Ce))::Cdefs))
/\
(pes_to_Cpes _ [] = ([]))
/\
(pes_to_Cpes m ((p,e)::pes) =  
(let Cpes = (pes_to_Cpes m pes) in
  let (m,Cp) = (pat_to_Cpat m p) in
  let Ce = (exp_to_Cexp m e) in
  (Cp,Ce)::Cpes))
/\
(exps_to_Cexps _ [] = ([]))
/\
(exps_to_Cexps m (e::es) =  
(exp_to_Cexp m e :: exps_to_Cexps m es))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn exp_to_Cexp_defn;

(* source to intermediate values *)

(*open SemanticPrimitives*)

 val v_to_Cv_defn = Hol_defn "v_to_Cv" `

(v_to_Cv _ _ (Litv l) = (CLitv l))
/\
(v_to_Cv mv m (Conv cn vs) =  
(CConv (fapply( 0) cn m) (vs_to_Cvs mv m vs)))
/\
(v_to_Cv mv m (Closure env vn e) =  
(let Cenv = (env_to_Cenv mv m env) in
  let m = (<| bvars := ((MAP FST env)) ; mvars := mv; cnmap := m |>) in
  let Ce = (exp_to_Cexp (cbv m vn) e) in
  CRecClos Cenv [(NONE, ( 1,shift( 1)( 1) Ce))]( 0)))
/\
(v_to_Cv mv m (Recclosure env defs vn) =  
(let Cenv = (env_to_Cenv mv m env) in
  let m = (<| bvars := ((MAP FST env)) ; mvars := mv; cnmap := m |>) in
  let fns = ((MAP (\p . 
  (case (p ) of ( (n,_,_) ) => n )) defs)) in
  let m = (( m with<| bvars := fns ++ m.bvars |>)) in
  let Cdefs = (defs_to_Cdefs m defs) in
  CRecClos Cenv Cdefs (the( 0) (misc$find_index vn fns( 0)))))
/\
(v_to_Cv _ _ (Loc n) = (CLoc n))
/\
(vs_to_Cvs _ _ [] = ([]))
/\
(vs_to_Cvs mv m (v::vs) = (v_to_Cv mv m v :: vs_to_Cvs mv m vs))
/\
(env_to_Cenv _ _ [] = ([]))
/\
(env_to_Cenv mv m ((_,v)::env) =  
((v_to_Cv mv m v)::(env_to_Cenv mv m env)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn v_to_Cv_defn;
val _ = export_theory()

